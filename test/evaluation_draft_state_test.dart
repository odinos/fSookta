import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

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
    expect(restored.profile.profileId, isNotEmpty);
    expect(
      restored.evaluationDraftForProfile(
        restored.profile.profileId,
        activity: SooktaActivity.fertilizing,
      ),
      isNotNull,
    );
    expect(draft!.activity, SooktaActivity.fertilizing);
    expect(draft.jobType, JobType.lifting);
    expect(draft.selectedImagePaths, ['photo-a.jpg', 'photo-b.jpg']);
    expect(draft.selectedToolId, 'fertilizer_15_20kg');
    expect(draft.loadWeight, 17.5);
    expect(draft.horizontalDistanceText, '35');
    expect(draft.rebaInput.trunkScore, 4);
    expect(draft.rebaInput.couplingScore, 1);
  });

  test('copies existing draft media into app storage before persisting',
      () async {
    SharedPreferences.setMockInitialValues({});
    final tempRoot = await Directory.systemTemp.createTemp('sookta_draft_');
    addTearDown(() async {
      if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
    });
    final appDocuments = Directory('${tempRoot.path}/documents')
      ..createSync(recursive: true);
    final source = File('${tempRoot.path}/camera_capture.jpg')
      ..writeAsStringSync('fake image bytes');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return appDocuments.path;
      }
      return null;
    });

    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      EvaluationDraft(
        activity: SooktaActivity.fertilizing,
        jobType: JobType.lifting,
        selectedImagePaths: [source.path],
        selectedToolId: 'fertilizer_15_20kg',
      ),
    );

    final restored = SooktaAppState();
    addTearDown(restored.dispose);
    await restored.restore();

    final savedPath = restored.evaluationDraft!.selectedImagePaths.single;
    expect(savedPath, isNot(source.path));
    expect(savedPath, startsWith(appDocuments.path));
    expect(File(savedPath).existsSync(), isTrue);
  });

  test('keeps separate drafts by farmer activity and assessment date',
      () async {
    SharedPreferences.setMockInitialValues({});

    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    state.saveProfile(const UserProfile(
      profileId: 'farmer-a',
      farmerId: 'FARM-A',
      name: 'Farmer A',
    ));
    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedToolId: 'basket_mid_10_15kg',
      ),
    );

    state.saveProfile(const UserProfile(
      profileId: 'farmer-b',
      farmerId: 'FARM-B',
      name: 'Farmer B',
    ));
    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.fertilizing,
        jobType: JobType.lifting,
        selectedToolId: 'fertilizer_15_20kg',
      ),
    );

    final restored = SooktaAppState();
    addTearDown(restored.dispose);
    await restored.restore();

    expect(restored.evaluationDrafts, hasLength(2));
    expect(
      restored
          .evaluationDraftForProfile(
            'farmer-a',
            activity: SooktaActivity.harvesting,
          )
          ?.farmerId,
      'FARM-A',
    );
    expect(
      restored
          .evaluationDraftForProfile(
            'farmer-b',
            activity: SooktaActivity.fertilizing,
          )
          ?.farmerId,
      'FARM-B',
    );
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
