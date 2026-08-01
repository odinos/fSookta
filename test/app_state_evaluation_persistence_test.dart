import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';

void main() {
  test('saveEvaluation persists a complete history record for restore',
      () async {
    SharedPreferences.setMockInitialValues({});

    final state = SooktaAppState()
      ..setLanguage(AppLanguage.th)
      ..saveProfile(
        const UserProfile(
          profileId: 'profile-save',
          farmerId: 'FARM-SAVE',
          name: 'ชาวสวนทดสอบ',
          role: 'ชาวสวน',
          age: '45',
          gender: 'Female',
          weight: '55',
          height: '158',
        ),
      );
    addTearDown(state.dispose);

    final saved = await state.saveEvaluation(
      activityName: 'การใส่ปุ๋ย',
      activity: SooktaActivity.fertilizing,
      before: const ErgoResult(
        riskLevel: RiskLevel.high,
        techScore: 8,
        userScore: 8,
        userScoreColor: 0xFFFF5252,
        limitValue: 9,
        suggestionKey: 'sugg_reba_high',
        economicLoss: 12000,
        bodyPartRisks: {BodyPart.trunk: RiskLevel.high},
      ),
      after: const ErgoResult(
        riskLevel: RiskLevel.medium,
        techScore: 4,
        userScore: 4,
        userScoreColor: 0xFFFFF176,
        limitValue: 9,
        suggestionKey: 'sugg_reba_med',
        economicLoss: 6000,
        bodyPartRisks: {BodyPart.trunk: RiskLevel.medium},
      ),
      selectedSuggestionKeys: const ['act_fert_split_load'],
      selectedSuggestions: const ['แบ่งน้ำหนักปุ๋ยต่อรอบให้น้อยลง'],
      assessmentBreakdown: const AssessmentBreakdown(
        primaryMethod: AssessmentMethod.rebaIsoCombined,
        rebaInput: RebaInputData(trunkScore: 4, neckScore: 2),
        rebaResult: ErgoResult(
          riskLevel: RiskLevel.high,
          techScore: 8,
          userScore: 8,
          userScoreColor: 0xFFFF5252,
          limitValue: 9,
          suggestionKey: 'sugg_reba_high',
        ),
        ergoInput: ErgoInputData(
          jobType: JobType.lifting,
          loadWeight: 15,
          horizontalDist: 40,
          verticalHeight: 60,
          liftFrequency: 0.4,
          durationHours: 2,
        ),
      ),
    );

    final restored = SooktaAppState();
    addTearDown(restored.dispose);
    await restored.restore();

    expect(restored.history, hasLength(1));
    final record = restored.history.single;
    expect(record.id, saved.id);
    expect(record.farmerProfileId, 'profile-save');
    expect(record.activity, SooktaActivity.fertilizing);
    expect(record.scoreBefore, 8);
    expect(record.scoreAfter, 4);
    expect(record.assessmentBreakdown?.ergoInput.loadWeight, 15);
    expect(record.selectedSuggestionKeys, ['act_fert_split_load']);
    expect(record.selectedSuggestions, ['แบ่งน้ำหนักปุ๋ยต่อรอบให้น้อยลง']);
  });

  test('one malformed history row does not clear valid restored state',
      () async {
    const profile = UserProfile(
      profileId: 'profile-isolation',
      farmerId: 'FARM-ISO',
      name: 'Valid farmer',
    );
    final validRecord = EvaluationHistoryRecord(
      id: 11,
      farmerProfileId: profile.profileId,
      activity: SooktaActivity.fertilizing,
      activityName: 'การใส่ปุ๋ย',
      dateTime: DateTime(2026, 7, 29, 10),
      scoreBefore: 8,
      scoreAfter: 6,
      riskBefore: RiskLevel.high,
      riskAfter: RiskLevel.medium,
      economicLoss: 1000,
      moneySaved: 280,
      selectedSuggestions: const [],
      bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
    );
    final draft = EvaluationDraft(
      activity: SooktaActivity.fertilizing,
      jobType: JobType.lifting,
      farmerProfileId: profile.profileId,
      farmerId: profile.farmerId,
      assessmentDateKey: '2026-07-29',
    );
    SharedPreferences.setMockInitialValues({
      'sookta.language': 'en',
      'sookta.farmers': jsonEncode([profile.toJson()]),
      'sookta.activeProfileId': profile.profileId,
      'sookta.history': jsonEncode([
        validRecord.toJson(),
        <String, Object?>{
          ...validRecord.toJson(),
          'id': <String, String>{'malformed': 'id'},
        },
      ]),
      'sookta.evaluationDrafts': jsonEncode([draft.toJson()]),
    });

    final state = SooktaAppState();
    addTearDown(state.dispose);
    await state.restore();

    expect(state.profile.profileId, profile.profileId);
    expect(
        state.farmers.map((farmer) => farmer.profileId), [profile.profileId]);
    expect(state.history.map((record) => record.id), [validRecord.id]);
    expect(
      state.evaluationDraftForProfile(
        profile.profileId,
        activity: SooktaActivity.fertilizing,
      ),
      isNotNull,
    );
  });
}
