import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';

void main() {
  test('persists and restores the current evaluation draft', () async {
    SharedPreferences.setMockInitialValues({});

    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.fertilizing,
        jobType: JobType.lifting,
        selectedImagePaths: ['photo-a.jpg', 'photo-b.jpg'],
        selectedToolId: 'fertilizer_15_20kg',
        durationHours: 2,
        frequency: 2,
        staticHoldLevel: 1,
        workDaysPerWeek: 3,
        loadWeight: 17.5,
        pushPullDistance: 20,
        initialForce: 18,
        sustainForce: 10,
        horizontalDistanceText: '35',
        verticalHeightText: '65',
        transportDistanceText: '6',
        showAdvancedDetails: true,
        rebaInput: RebaInputData(
          trunkScore: 4,
          neckScore: 2,
          couplingScore: 1,
        ),
      ),
    );

    final restored = SooktaAppState();
    addTearDown(restored.dispose);
    await restored.restore();

    final draft = restored.evaluationDraft;
    expect(draft, isNotNull);
    expect(draft!.activity, SooktaActivity.fertilizing);
    expect(draft.jobType, JobType.lifting);
    expect(draft.selectedImagePaths, ['photo-a.jpg', 'photo-b.jpg']);
    expect(draft.selectedToolId, 'fertilizer_15_20kg');
    expect(draft.loadWeight, 17.5);
    expect(draft.horizontalDistanceText, '35');
    expect(draft.rebaInput.trunkScore, 4);
    expect(draft.rebaInput.couplingScore, 1);
  });

  test('clears the draft after a successful evaluation save', () async {
    SharedPreferences.setMockInitialValues({});

    final state = SooktaAppState()
      ..setLanguage(AppLanguage.th)
      ..saveProfile(const UserProfile(profileId: 'profile-draft'));
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedToolId: 'basket_mid_10_15kg',
        rebaInput: RebaInputData(trunkScore: 3),
      ),
    );

    await state.saveEvaluation(
      activityName: 'การเก็บเกี่ยว',
      activity: SooktaActivity.harvesting,
      before: const ErgoResult(
        riskLevel: RiskLevel.high,
        techScore: 8,
        userScore: 8,
        userScoreColor: 0xFFFF5252,
        limitValue: 9,
        suggestionKey: 'sugg_reba_high',
      ),
      after: const ErgoResult(
        riskLevel: RiskLevel.medium,
        techScore: 4,
        userScore: 4,
        userScoreColor: 0xFFFFF176,
        limitValue: 9,
        suggestionKey: 'sugg_reba_med',
      ),
      selectedSuggestions: const ['ปรับระดับโต๊ะทำงาน'],
    );

    expect(state.evaluationDraft, isNull);

    final restored = SooktaAppState();
    addTearDown(restored.dispose);
    await restored.restore();
    expect(restored.evaluationDraft, isNull);
  });
}
