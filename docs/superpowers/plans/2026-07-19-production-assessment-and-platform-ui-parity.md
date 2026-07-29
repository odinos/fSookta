# Production Assessment and Platform UI Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every assessment-validation bypass, enforce one production readiness policy in both the button and handler, and produce automated plus device-level evidence that the shared Android and iOS workflow has equivalent UI.

**Architecture:** Introduce a small immutable `AssessmentReadiness` policy as the single source of truth for the five production gate conditions, then consume it twice from `EvaluationFormScreen`: once while rendering the action and again immediately before calculation. Extend the existing widget and screenshot harnesses instead of creating parallel UI implementations; platform builds and screenshots use the same Flutter screens and record system-owned differences separately.

**Tech Stack:** Flutter 3 / Dart 3.4+, `flutter_test`, `integration_test`, MoveNet TFLite, Android SDK/ADB/AVD, Xcode/CoreSimulator, existing screenshot harness, local visual companion.

## Global Constraints

- The application must not contain a runtime or compile-time path that bypasses assessment validation.
- View Assessment is enabled only when media exists, image-quality issues are empty, pose assessment is ready, pose analysis is idle, and all required activity/ergonomic inputs are valid.
- The handler must repeat the same production validation immediately before calculation and navigation.
- Uploaded-video frames are valid only when they pass the same image-quality and pose-readiness checks as photos.
- Preserve image-quality validation, multiple-person rejection, pose checks, required-data validation, existing production guidance, ergonomic formulas, saved schemas, and research exports.
- Keep Android and iOS portrait-only.
- Shared Flutter screens must retain the same order, copy, cards, colors, icons, spacing, labels, states, and four recommendation categories.
- Platform differences are allowed only for system bars/safe areas, font rasterization, permissions, camera/gallery pickers, and native share sheets.
- Device or simulator tooling failure is `BLOCKED`, never an inferred `PASS`.
- Preserve the unrelated existing iOS and ONNX Runtime worktree changes.

## File Map

- Create `lib/core/services/assessment_readiness.dart`: immutable production gate policy with no UI or platform dependency.
- Create `test/assessment_readiness_test.dart`: exhaustive unit matrix for all five gate conditions.
- Create `test/production_assessment_config_test.dart`: regression guard against reintroducing the deleted flag/config/banner and against using different policies in the button and handler.
- Modify `lib/screens/main/evaluation_form_screen.dart`: remove UAT configuration, banner, and shortcut branches; consume `AssessmentReadiness` in both enforcement points.
- Modify `test/evaluation_form_required_data_validation_test.dart`: assert invalid required input keeps every View Assessment action disabled.
- Delete `lib/app/uat_config.dart`: remove the compile-time bypass definition.
- Delete `test/uat_assessment_gate_test.dart`: remove tests that legitimize bypass behavior.
- Create `test/platform_ui_parity_test.dart`: compare shared screen contracts at representative iPhone and Android portrait sizes.
- Create `integration_test/production_assessment_flow_test.dart`: run real bundled pose inference and prove valid production media reaches the result route.
- Modify `integration_test/screenshot_harness_app.dart`: add stable keys to the four core QA states without changing production UI.
- Modify `docs/superpowers/specs/2026-07-12-explicit-recommendation-groups-design.md`: mark its previous testing-shortcut constraint as superseded by the production-only design.
- Modify `docs/uat-last-phase-20260712.md`: clearly label the earlier shortcut result as historical and superseded.
- Modify `docs/last-phase-requirement-matrix-20260712.md`: replace the obsolete current-status shortcut claim with a historical/superseded note.
- Modify `docs/uat_evidence_20260712_last_phase/device-and-build-summary.txt`: prevent the historical build note from being read as a current build instruction.
- Create `docs/uat-production-platform-parity-20260719.md`: final command, build, test, device, screenshot, and blocker evidence.
- Create `docs/uat_evidence_20260719_platform_parity/`: captured iOS and Android PNG evidence when each platform service is available.

---

### Task 1: Central Production Assessment Readiness Policy

**Files:**
- Create: `lib/core/services/assessment_readiness.dart`
- Create: `test/assessment_readiness_test.dart`

**Interfaces:**
- Consumes: primitive UI state already calculated by `EvaluationFormScreen`.
- Produces: `const AssessmentReadiness({required bool hasMedia, required bool hasImageQualityIssues, required bool poseAssessmentReady, required bool poseBusy, required List<String> requiredDataIssues})` and `bool get canAnalyze`.

- [ ] **Step 1: Write the failing readiness matrix**

Create `test/assessment_readiness_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/core/services/assessment_readiness.dart';

void main() {
  const ready = AssessmentReadiness(
    hasMedia: true,
    hasImageQualityIssues: false,
    poseAssessmentReady: true,
    poseBusy: false,
    requiredDataIssues: <String>[],
  );

  test('valid production input is ready for assessment', () {
    expect(ready.canAnalyze, isTrue);
  });

  test('each incomplete production condition blocks assessment', () {
    final blocked = <AssessmentReadiness>[
      ready.copyWith(hasMedia: false),
      ready.copyWith(hasImageQualityIssues: true),
      ready.copyWith(poseAssessmentReady: false),
      ready.copyWith(poseBusy: true),
      ready.copyWith(requiredDataIssues: const ['missing distance']),
    ];

    expect(blocked.every((state) => !state.canAnalyze), isTrue);
  });
}
```

- [ ] **Step 2: Run the test and verify the policy is missing**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/assessment_readiness_test.dart
```

Expected: FAIL because `assessment_readiness.dart` and `AssessmentReadiness` do not exist.

- [ ] **Step 3: Implement the immutable policy**

Create `lib/core/services/assessment_readiness.dart`:

```dart
class AssessmentReadiness {
  const AssessmentReadiness({
    required this.hasMedia,
    required this.hasImageQualityIssues,
    required this.poseAssessmentReady,
    required this.poseBusy,
    required this.requiredDataIssues,
  });

  final bool hasMedia;
  final bool hasImageQualityIssues;
  final bool poseAssessmentReady;
  final bool poseBusy;
  final List<String> requiredDataIssues;

  bool get canAnalyze =>
      hasMedia &&
      !hasImageQualityIssues &&
      poseAssessmentReady &&
      !poseBusy &&
      requiredDataIssues.isEmpty;

  AssessmentReadiness copyWith({
    bool? hasMedia,
    bool? hasImageQualityIssues,
    bool? poseAssessmentReady,
    bool? poseBusy,
    List<String>? requiredDataIssues,
  }) {
    return AssessmentReadiness(
      hasMedia: hasMedia ?? this.hasMedia,
      hasImageQualityIssues:
          hasImageQualityIssues ?? this.hasImageQualityIssues,
      poseAssessmentReady: poseAssessmentReady ?? this.poseAssessmentReady,
      poseBusy: poseBusy ?? this.poseBusy,
      requiredDataIssues: requiredDataIssues ?? this.requiredDataIssues,
    );
  }
}
```

- [ ] **Step 4: Run the focused test**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/assessment_readiness_test.dart
```

Expected: PASS, including one valid state and five individually blocked states.

- [ ] **Step 5: Commit the policy**

```bash
git add lib/core/services/assessment_readiness.dart test/assessment_readiness_test.dart
git commit -m "feat: centralize production assessment readiness"
```

---

### Task 2: Remove the Bypass and Enforce the Policy Twice

**Files:**
- Create: `test/production_assessment_config_test.dart`
- Modify: `lib/screens/main/evaluation_form_screen.dart`
- Modify: `test/evaluation_form_required_data_validation_test.dart`
- Delete: `lib/app/uat_config.dart`
- Delete: `test/uat_assessment_gate_test.dart`
- Modify: `docs/superpowers/specs/2026-07-12-explicit-recommendation-groups-design.md`
- Modify: `docs/uat-last-phase-20260712.md`
- Modify: `docs/last-phase-requirement-matrix-20260712.md`
- Modify: `docs/uat_evidence_20260712_last_phase/device-and-build-summary.txt`

**Interfaces:**
- Consumes: `AssessmentReadiness.canAnalyze` from Task 1 and the existing `_requiredDataIssues(bool)` / `_imageQualityIssues(bool)` methods.
- Produces: one production-only action gate and one production-only handler guard; no `UatConfig`, `SOOKTA_UAT_BYPASS`, warning banner, or shortcut branch in executable/build files.

- [ ] **Step 1: Write the failing source/config regression**

Create `test/production_assessment_config_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assessment bypass config and build flag are absent', () {
    expect(File('lib/app/uat_config.dart').existsSync(), isFalse);

    final productionFiles = <File>[
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      File('android/app/build.gradle.kts'),
      File('android/app/src/main/AndroidManifest.xml'),
      File('ios/Flutter/Debug.xcconfig'),
      File('ios/Flutter/Release.xcconfig'),
      File('ios/Runner.xcodeproj/project.pbxproj'),
      File('ios/Runner/Info.plist'),
      File('ios/Podfile'),
      ...Directory('ios/scripts').listSync().whereType<File>(),
    ];

    for (final file in productionFiles) {
      final content = file.readAsStringSync();
      expect(content, isNot(contains('SOOKTA_UAT_BYPASS')),
          reason: file.path);
      expect(content, isNot(contains('UatConfig')), reason: file.path);
      expect(content, isNot(contains('UAT mode: View Assessment')),
          reason: file.path);
    }
  });

  test('button and handler both consume production readiness', () {
    final source =
        File('lib/screens/main/evaluation_form_screen.dart').readAsStringSync();

    expect(
      RegExp(r'AssessmentReadiness\(').allMatches(source).length,
      greaterThanOrEqualTo(2),
    );
    expect(
      source,
      contains('onAnalyze: readiness.canAnalyze ? _analyze : null'),
    );
    expect(source, contains('if (!readiness.canAnalyze)'));
  });
}
```

- [ ] **Step 2: Extend the widget regression for the disabled action**

In `test/evaluation_form_required_data_validation_test.dart`, append these assertions after the existing validation-message checks:

```dart
    final assessmentButtons =
        tester.widgetList<FilledButton>(find.widgetWithText(
      FilledButton,
      'ดูผลประเมิน',
    ));
    expect(assessmentButtons, isNotEmpty);
    expect(assessmentButtons.every((button) => button.onPressed == null), isTrue);
```

- [ ] **Step 3: Run both regressions and verify they fail**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/production_assessment_config_test.dart test/evaluation_form_required_data_validation_test.dart
```

Expected: FAIL because the config file, import, flag, banner, and shortcut branches still exist.

- [ ] **Step 4: Replace the build-time gate with `AssessmentReadiness`**

In `lib/screens/main/evaluation_form_screen.dart`, remove the `uat_config.dart` import and add:

```dart
import '../../core/services/assessment_readiness.dart';
```

Replace the existing `standardCanAnalyze`, `uatCanBypass`, and `canAnalyze` block in `build` with:

```dart
    final readiness = AssessmentReadiness(
      hasMedia: selectedImagePaths.isNotEmpty,
      hasImageQualityIssues: imageQualityIssues.isNotEmpty,
      poseAssessmentReady: poseAssessmentReady,
      poseBusy: poseBusy,
      requiredDataIssues: validationIssues,
    );
```

Delete the complete conditional yellow UAT card. Change both action call sites to:

```dart
onAnalyze: readiness.canAnalyze ? _analyze : null,
```

and:

```dart
onPressed: readiness.canAnalyze ? _analyze : null,
```

Change their disabled guidance conditions from `if (!canAnalyze)` to:

```dart
if (!readiness.canAnalyze)
```

- [ ] **Step 5: Keep only real blocking image-quality findings**

In `_imageQualityIssues(bool thai)`, delete the unconditional block that adds a generic one-person reminder whenever `selectedImagePaths.isNotEmpty`. It currently makes `imageQualityIssues.isEmpty` impossible after media is selected. Keep these as blocking findings:

```dart
final missingAngles = math.max(0, 4 - selectedImagePaths.length);
```

```dart
if (selectedImagePaths.length >= 4 && !poseBusy && !poseAssessmentReady)
```

```dart
if (latestUnreadableImageIndexes.isNotEmpty)
```

```dart
if (latestMultiPersonImageIndexes.isNotEmpty)
```

The actual multi-person detector and its indexed replacement guidance remain unchanged; only the unconditional reminder leaves the blocking list.

- [ ] **Step 6: Repeat the same policy inside `_analyze()`**

At the start of `_analyze()`, replace `uatBypass` and both shortcut-aware branches with:

```dart
    final validationIssues = _requiredDataIssues(thai);
    final imageQualityIssues = _imageQualityIssues(thai);
    final readiness = AssessmentReadiness(
      hasMedia: selectedImagePaths.isNotEmpty,
      hasImageQualityIssues: imageQualityIssues.isNotEmpty,
      poseAssessmentReady: poseAssessmentReady,
      poseBusy: poseBusy,
      requiredDataIssues: validationIssues,
    );
    if (!readiness.canAnalyze) {
      final guidance = validationIssues.isNotEmpty
          ? (thai
              ? 'กรุณาตรวจข้อมูลก่อนประเมิน: ${validationIssues.first}'
              : 'Check required data before assessment: ${validationIssues.first}')
          : imageQualityIssues.isNotEmpty
              ? imageQualityIssues.first
              : (thai
                  ? 'ยังประเมินไม่ได้ กรุณาใช้รูปที่เห็นบุคคลและท่าทางชัดเจนก่อน เพื่อหลีกเลี่ยงตัวเลขที่ไม่น่าเชื่อถือ'
                  : 'Cannot assess yet. Use a clear photo with a readable person posture to avoid unreliable numbers.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(guidance)),
      );
      return;
    }
```

Leave the calculation, draft save, and `InitialRiskScreen.routeName` navigation below this guard unchanged.

- [ ] **Step 7: Delete the bypass implementation and its approving tests**

Delete:

```text
lib/app/uat_config.dart
test/uat_assessment_gate_test.dart
```

- [ ] **Step 8: Correct obsolete documentation without rewriting historical results**

Apply these exact documentation rules:

- In `docs/superpowers/specs/2026-07-12-explicit-recommendation-groups-design.md`, replace “Keep portrait-only behavior and the compile-time UAT bypass unchanged.” with “Keep portrait-only behavior. The temporary assessment shortcut from that test round was superseded by the production-only gate design dated 2026-07-19.”
- In `docs/uat-last-phase-20260712.md`, change `PASS (UAT bypass)` to `HISTORICAL PASS — temporary test path; superseded by production gate on 2026-07-19`.
- In `docs/last-phase-requirement-matrix-20260712.md`, replace the phrase `UAT assessment bypass` with `historical temporary assessment-path check (superseded on 2026-07-19)`.
- In `docs/uat_evidence_20260712_last_phase/device-and-build-summary.txt`, label the old iOS command as historical/superseded and replace `Uploaded-video assessment via compile-time UAT bypass: PASS` with `Uploaded-video temporary-path check: HISTORICAL PASS; not accepted as production evidence after 2026-07-19`.

Do not change the scores, device dates, or other historical pass/block results.

- [ ] **Step 9: Format and run focused tests**

Run:

```bash
/Users/kpc/develop/flutter/bin/dart format lib/core/services/assessment_readiness.dart lib/screens/main/evaluation_form_screen.dart test/assessment_readiness_test.dart test/production_assessment_config_test.dart test/evaluation_form_required_data_validation_test.dart
/Users/kpc/develop/flutter/bin/flutter test test/assessment_readiness_test.dart test/production_assessment_config_test.dart test/evaluation_form_required_data_validation_test.dart test/evaluation_form_image_slots_test.dart test/portrait_orientation_config_test.dart
```

Expected: all focused tests PASS and no test output contains the deleted UAT warning.

- [ ] **Step 10: Commit production enforcement**

```bash
git add lib/core/services/assessment_readiness.dart lib/screens/main/evaluation_form_screen.dart test/assessment_readiness_test.dart test/production_assessment_config_test.dart test/evaluation_form_required_data_validation_test.dart docs/superpowers/specs/2026-07-12-explicit-recommendation-groups-design.md docs/uat-last-phase-20260712.md docs/last-phase-requirement-matrix-20260712.md docs/uat_evidence_20260712_last_phase/device-and-build-summary.txt
git add -u lib/app/uat_config.dart test/uat_assessment_gate_test.dart
git commit -m "fix: enforce production assessment validation"
```

---

### Task 3: Shared Android/iPhone Widget UI Contract

**Files:**
- Create: `test/platform_ui_parity_test.dart`
- Test: `test/portrait_orientation_config_test.dart`
- Test: `test/initial_risk_confirmation_test.dart`
- Test: `test/final_result_farmer_summary_test.dart`

**Interfaces:**
- Consumes: existing `EvaluationMenuScreen`, `EvaluationFormScreen`, `InitialRiskScreen`, `FinalResultScreen`, `risk-action-group-*`, and `recommendation-group-*` keys.
- Produces: identical application-owned text/key signatures at `390x844` iPhone and `412x915` Android portrait viewports, with no framework exception or overflow.

- [ ] **Step 1: Write the cross-platform contract test**

Create `test/platform_ui_parity_test.dart` with:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/evaluation_menu_screen.dart';
import 'package:fsookta/screens/main/final_result_screen.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        if (call.method == 'getVoices') return <Map<String, Object?>>[];
        if (call.method == 'getLanguages') return <String>['th-TH', 'en-US'];
        if (call.method == 'getDefaultVoice') return <String, Object?>{};
        return 1;
      },
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  for (final language in const <AppLanguage>[
    AppLanguage.th,
    AppLanguage.en,
  ]) {
    for (final screen in _screens(thai: language == AppLanguage.th)) {
      testWidgets(
          '${screen.name}/${language.name} has the same iPhone and Android contract',
          (tester) async {
      final signatures = <String, List<String>>{};
      for (final viewport in const [
        _Viewport('ios', Size(390, 844), TargetPlatform.iOS),
        _Viewport('android', Size(412, 915), TargetPlatform.android),
      ]) {
        debugDefaultTargetPlatformOverride = viewport.platform;
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;

        final state = SooktaAppState()..setLanguage(language);
        await tester.pumpWidget(
          AppStateScope(
            state: state,
            child: MaterialApp(home: screen.build()),
          ),
        );
        await tester.pump();

        final signature = tester
            .widgetList<Text>(find.byType(Text, skipOffstage: false))
            .map((widget) => widget.data)
            .whereType<String>()
            .where((text) => text.trim().isNotEmpty)
            .toList(growable: false);
        for (final expected in screen.requiredText) {
          expect(
            signature,
            contains(expected),
            reason: '${screen.name}/${language.name}/${viewport.name}',
          );
        }
        for (final key in screen.requiredKeys) {
          expect(find.byKey(ValueKey(key), skipOffstage: false), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        signatures[viewport.name] = signature;
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      }

      expect(signatures['android'], equals(signatures['ios']));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
  }
}
```

Append these complete fixtures and contracts in the same file:

```dart
class _Viewport {
  const _Viewport(this.name, this.size, this.platform);

  final String name;
  final Size size;
  final TargetPlatform platform;
}

class _ScreenContract {
  const _ScreenContract({
    required this.name,
    required this.build,
    required this.requiredText,
    this.requiredKeys = const <String>[],
  });

  final String name;
  final Widget Function() build;
  final List<String> requiredText;
  final List<String> requiredKeys;
}

List<_ScreenContract> _screens({required bool thai}) {
  return <_ScreenContract>[
    _ScreenContract(
      name: 'farmer workflow entry',
      build: EvaluationMenuScreen.new,
      requiredText: thai
          ? const <String>[
              'เลือกประเภทงาน',
              'โปรดเลือกกิจกรรมที่ต้องการประเมิน',
              'การปลูกกล้า',
              'การใส่ปุ๋ย',
            ]
          : const <String>[
              'Select Job Type',
              'Please select an activity to evaluate',
              'Planting',
              'Fertilizing',
            ],
    ),
    _ScreenContract(
      name: 'evaluation form',
      build: () => const EvaluationFormScreen(
        activity: SooktaActivity.fertilizing,
      ),
      requiredText: thai
          ? const <String>[
              'แบบฟอร์มประเมิน',
              'กิจกรรม: การใส่ปุ๋ย',
              'ดูผลประเมิน',
            ]
          : const <String>[
              'Evaluation Form',
              'Activity: Fertilizing',
              'View Assessment',
            ],
    ),
    _ScreenContract(
      name: 'risk reduction selection',
      build: () => InitialRiskScreen(payload: _initialPayload(thai: thai)),
      requiredText: thai
          ? const <String>[
              'ผลการประเมินเบื้องต้น',
              'เลือกวิธีลดความเสี่ยง',
              'ดูผลหลังปรับปรุง',
            ]
          : const <String>[
              'Initial Assessment',
              'Choose risk-reduction actions',
              'View Improved Result',
            ],
      requiredKeys: const <String>[
        'risk-action-group-posture',
        'risk-action-group-riskReduction',
        'risk-action-group-restRotation',
        'risk-action-group-workloadSupport',
      ],
    ),
    _ScreenContract(
      name: 'final farmer result',
      build: () => FinalResultScreen(bundle: _bundle(thai: thai)),
      requiredText: thai
          ? const <String>[
              'สรุปสำหรับเกษตรกร',
              'คำแนะนำตามกิจกรรมและความเสี่ยง',
            ]
          : const <String>[
              'Farmer summary',
              'Recommendations by activity and risk',
            ],
      requiredKeys: const <String>[
        'recommendation-group-posture',
        'recommendation-group-riskReduction',
        'recommendation-group-restRotation',
        'recommendation-group-workloadSupport',
      ],
    ),
  ];
}

InitialRiskPayload _initialPayload({required bool thai}) {
  return InitialRiskPayload(
    activity: SooktaActivity.fertilizing,
    activityName: SooktaActivity.fertilizing.label(thai: thai),
    jobType: JobType.lifting,
    before: _before,
    ergoInput: const ErgoInputData(jobType: JobType.lifting),
    rebaInput: const RebaInputData(trunkScore: 4, neckScore: 2),
  );
}

AssessmentBundle _bundle({required bool thai}) {
  return AssessmentBundle(
    activity: SooktaActivity.fertilizing,
    activityName: SooktaActivity.fertilizing.label(thai: thai),
    jobType: JobType.lifting,
    before: _before,
    after: _after,
    selectedSuggestionKeys: const <String>['act_fert_split_load'],
    breakdown: const AssessmentBreakdown(
      primaryMethod: AssessmentMethod.reba,
      rebaInput: RebaInputData(trunkScore: 4, neckScore: 2),
      rebaResult: _before,
      ergoInput: ErgoInputData(jobType: JobType.lifting),
    ),
  );
}

const _before = ErgoResult(
  riskLevel: RiskLevel.high,
  techScore: 8,
  userScore: 8,
  userScoreColor: 0xFFFF5252,
  limitValue: 9,
  suggestionKey: 'sugg_reba_high',
  economicLoss: 12000,
  bodyPartRisks: <BodyPart, RiskLevel>{BodyPart.trunk: RiskLevel.high},
);

const _after = ErgoResult(
  riskLevel: RiskLevel.medium,
  techScore: 4,
  userScore: 4,
  userScoreColor: 0xFFFFC107,
  limitValue: 9,
  suggestionKey: 'sugg_reba_medium',
  economicLoss: 6000,
  bodyPartRisks: <BodyPart, RiskLevel>{BodyPart.trunk: RiskLevel.medium},
);
```

Do not alter production scoring to satisfy the contract.

- [ ] **Step 2: Run the new contract and verify any real mismatch**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/platform_ui_parity_test.dart
```

Expected initially: either PASS because the screens are already shared Flutter widgets, or FAIL with an exact missing text/key/overflow. If it fails, change only the shared widget causing that specific failure and rerun; do not add platform forks.

- [ ] **Step 3: Run the existing recommendation and portrait contracts**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/platform_ui_parity_test.dart test/portrait_orientation_config_test.dart test/initial_risk_confirmation_test.dart test/final_result_farmer_summary_test.dart
```

Expected: PASS at both representative portrait sizes, four category cards on both recommendation surfaces, and no render exception.

- [ ] **Step 4: Commit the UI contract**

```bash
git add test/platform_ui_parity_test.dart
git commit -m "test: add android ios ui parity contract"
```

---

### Task 4: Valid Production Media Device Flow

**Files:**
- Create: `integration_test/production_assessment_flow_test.dart`
- Test: `assets/images/example_readable_pose.png`

**Interfaces:**
- Consumes: bundled readable-pose asset, real `MultiPersonPoseDetector`, real `PoseEstimationService`, production `AssessmentReadiness`, and `InitialRiskScreen.routeName`.
- Produces: device-level proof that readable media with valid inputs enables View Assessment and pushes the result workflow without a shortcut.

- [ ] **Step 1: Write the device integration test**

Create `integration_test/production_assessment_flow_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('readable production media reaches the result workflow',
      (tester) async {
    final directory = await getTemporaryDirectory();
    const assetPaths = <String>[
      'assets/images/example_readable_pose.png',
      'assets/images/example_harvesting_pose.png',
      'assets/images/example_fertilizing_pose.png',
      'assets/images/example_pruning_pose.png',
    ];
    final mediaFiles = <File>[];
    for (var index = 0; index < assetPaths.length; index += 1) {
      final bytes = await rootBundle.load(assetPaths[index]);
      final media =
          File('${directory.path}/production-readable-pose-$index.png');
      await media.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      mediaFiles.add(media);
    }
    addTearDown(() async {
      for (final media in mediaFiles) {
        if (await media.exists()) await media.delete();
      }
    });

    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);
    await state.saveEvaluationDraft(
      EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedImagePaths:
            mediaFiles.map((media) => media.path).toList(growable: false),
        selectedToolId: SooktaActivity.harvesting.defaultToolOption.id,
        durationHours: 4,
        frequency: 6.5,
        workDaysPerWeek: 5,
      ),
    );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: const EvaluationFormScreen(
            activity: SooktaActivity.harvesting,
          ),
          onGenerateRoute: (settings) {
            if (settings.name != InitialRiskScreen.routeName) return null;
            expect(settings.arguments, isA<InitialRiskPayload>());
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text(
                    'production result route',
                    key: ValueKey('production-result-route'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final button = find.widgetWithText(FilledButton, 'ดูผลประเมิน');
    for (var attempt = 0; attempt < 60; attempt += 1) {
      await tester.pump(const Duration(milliseconds: 500));
      final enabled = tester
          .widgetList<FilledButton>(button)
          .any((widget) => widget.onPressed != null);
      if (enabled) break;
    }
    expect(
      tester
          .widgetList<FilledButton>(button)
          .any((widget) => widget.onPressed != null),
      isTrue,
      reason: 'Readable bundled pose did not satisfy production readiness',
    );

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('production-result-route')),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run on the available iOS Simulator**

Boot the installed iPhone 17 Pro simulator:

```bash
xcrun simctl boot 851A067D-1E4A-44B8-8990-CFE9509C5689
open -a Simulator
/Users/kpc/develop/flutter/bin/flutter test integration_test/production_assessment_flow_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
```

Expected: PASS with real on-device TFLite inference and navigation to `production-result-route`. If CoreSimulator cannot launch, record `BLOCKED-IOS-SIMULATOR` with the command output.

- [ ] **Step 3: Run on Android when the emulator is available**

After Task 6 provisions/boots `sookta_api_35`, run:

```bash
/Users/kpc/develop/flutter/bin/flutter test integration_test/production_assessment_flow_test.dart -d emulator-5554
```

Expected: PASS with real Android TFLite inference and navigation. If the emulator cannot be provisioned or booted, record `BLOCKED-ANDROID-EMULATOR`; do not substitute the widget contract for this result.

- [ ] **Step 4: Commit the device flow**

```bash
git add integration_test/production_assessment_flow_test.dart
git commit -m "test: verify production assessment flow on device"
```

---

### Task 5: Complete Static, Test, and Production Build Verification

**Files:**
- Verify: all changed Dart files
- Verify: `android/app/src/main/AndroidManifest.xml`
- Verify: `ios/Runner/Info.plist`
- Produce: `build/app/outputs/flutter-apk/app-release.apk`
- Produce: `build/ios/iphoneos/Runner.app`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: complete automated regression evidence and production-behavior Android/iOS artifacts built without any bypass define.

- [ ] **Step 1: Format and analyze changed Dart files**

Run:

```bash
/Users/kpc/develop/flutter/bin/dart format lib/core/services/assessment_readiness.dart lib/screens/main/evaluation_form_screen.dart test/assessment_readiness_test.dart test/production_assessment_config_test.dart test/evaluation_form_required_data_validation_test.dart test/platform_ui_parity_test.dart integration_test/production_assessment_flow_test.dart
/Users/kpc/develop/flutter/bin/flutter analyze lib/core/services/assessment_readiness.dart lib/screens/main/evaluation_form_screen.dart test/assessment_readiness_test.dart test/production_assessment_config_test.dart test/evaluation_form_required_data_validation_test.dart test/platform_ui_parity_test.dart integration_test/production_assessment_flow_test.dart
```

Expected: `No issues found!`

- [ ] **Step 2: Run the complete Flutter host suite**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test
```

Expected: all tests PASS. If the known stale compiler cache stall recurs, preserve it for diagnosis:

```bash
mv build/test_cache /private/tmp/fSookta-test-cache-stalled-20260719
/Users/kpc/develop/flutter/bin/flutter test
```

Expected after a fresh cache: all tests PASS; record the cache move in the UAT report.

- [ ] **Step 3: Inspect the final diff**

Run:

```bash
git diff --check
git status --short
git diff --stat 59542a9
```

Expected: no whitespace errors; unrelated native changes remain present but unmodified by this work.

- [ ] **Step 4: Build Android release without a bypass define**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter build apk --release
```

Expected: `build/app/outputs/flutter-apk/app-release.apk` exists and the command line contains no assessment bypass define.

- [ ] **Step 5: Build iOS release behavior without codesigning and without a bypass define**

Run:

```bash
COPYFILE_DISABLE=1 /Users/kpc/develop/flutter/bin/flutter build ios --release --no-codesign
```

Expected: `build/ios/iphoneos/Runner.app` exists, the command line contains no assessment bypass define, and the build completes with the expected no-codesign notice only.

- [ ] **Step 6: Re-run production config and portrait checks after both builds**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/production_assessment_config_test.dart test/portrait_orientation_config_test.dart
```

Expected: PASS after artifact generation.

- [ ] **Step 7: Commit any test-only corrections**

If Tasks 4–5 required corrections, stage only files owned by this plan:

```bash
git add lib/core/services/assessment_readiness.dart lib/screens/main/evaluation_form_screen.dart test integration_test docs
git commit -m "test: complete production platform verification"
```

If there are no new tracked changes, skip this commit.

---

### Task 6: Android/iOS Screenshot UAT and Visual Companion

**Files:**
- Modify: `integration_test/screenshot_harness_app.dart`
- Create: `docs/uat_evidence_20260719_platform_parity/ios/09_evaluation_menu.png`
- Create: `docs/uat_evidence_20260719_platform_parity/ios/10_evaluation_form.png`
- Create: `docs/uat_evidence_20260719_platform_parity/ios/11_risk_reduction.png`
- Create: `docs/uat_evidence_20260719_platform_parity/ios/12_final_result.png`
- Create when Android runs: matching files under `docs/uat_evidence_20260719_platform_parity/android/`
- Create: `docs/uat-production-platform-parity-20260719.md`
- Modify in place: approved visual companion under `.superpowers/brainstorm/7648-1784436236/content/`

**Interfaces:**
- Consumes: existing `ScreenshotHarnessApp`, iPhone 17 Pro simulator UUID, Android SDK tools, four core screen indices `7`, `8`, `9`, `10`.
- Produces: comparable portrait PNGs, side-by-side visual companion, and an honest PASS/BLOCKED/DEFECT matrix.

- [ ] **Step 1: Add stable root keys to the harness states**

In `integration_test/screenshot_harness_app.dart`, wrap the four core children with keyed `KeyedSubtree` widgets:

```dart
KeyedSubtree(
  key: const ValueKey('qa-evaluation-menu'),
  child: const EvaluationMenuScreen(),
)
```

```dart
KeyedSubtree(
  key: const ValueKey('qa-evaluation-form'),
  child: const EvaluationFormScreen(
    activity: SooktaActivity.fertilizing,
  ),
)
```

Wrap the existing risk and final fixtures with:

```dart
KeyedSubtree(
  key: const ValueKey('qa-risk-reduction'),
  child: InitialRiskScreen(
    payload: InitialRiskPayload(
      activity: SooktaActivity.harvesting,
      activityName: SooktaActivity.harvesting.label(thai: true),
      jobType: JobType.reba,
      before: before,
      ergoInput: const ErgoInputData(jobType: JobType.reba),
      rebaInput: _rebaInput(),
    ),
  ),
)
```

and:

```dart
KeyedSubtree(
  key: const ValueKey('qa-final-result'),
  child: FinalResultScreen(
    bundle: AssessmentBundle(
      activity: SooktaActivity.harvesting,
      activityName: SooktaActivity.harvesting.label(thai: true),
      jobType: JobType.reba,
      before: before,
      after: after,
      selectedSuggestionKeys: const <String>[
        'act_avoid_bend',
        'act_reduce_arm_raise',
      ],
    ),
  ),
)
```

Do not add visible QA copy when `SOOKTA_QA_LABEL=false`.

- [ ] **Step 2: Capture iOS simulator screens**

For each start index `7`, `8`, `9`, and `10`, run the harness non-resident on iPhone 17 Pro:

```bash
/Users/kpc/develop/flutter/bin/flutter run -d 851A067D-1E4A-44B8-8990-CFE9509C5689 --debug --no-resident --target integration_test/screenshot_harness_app.dart --dart-define=SOOKTA_QA_AUTO_ADVANCE=false --dart-define=SOOKTA_QA_LABEL=false --dart-define=SOOKTA_QA_START_INDEX=7
xcrun simctl io 851A067D-1E4A-44B8-8990-CFE9509C5689 screenshot docs/uat_evidence_20260719_platform_parity/ios/09_evaluation_menu.png
```

Repeat with index/file pairs `8/10_evaluation_form.png`, `9/11_risk_reduction.png`, and `10/12_final_result.png`.

Expected: four portrait PNGs with no QA overlay, UAT warning, landscape layout, or Flutter error surface.

- [ ] **Step 3: Provision an Android emulator because no AVD/device is currently present**

Install one Apple-Silicon Android 35 image and create the dedicated AVD:

```bash
/Users/kpc/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "system-images;android-35;google_apis;arm64-v8a"
/Users/kpc/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager create avd --force --name sookta_api_35 --package "system-images;android-35;google_apis;arm64-v8a" --device "pixel_7"
/Users/kpc/Library/Android/sdk/emulator/emulator -avd sookta_api_35 -port 5554 -no-snapshot-save
```

Poll with:

```bash
/Users/kpc/Library/Android/sdk/platform-tools/adb devices -l
/Users/kpc/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
```

Expected: device state `device` and boot property `1`. Network/download/virtualization failure becomes `BLOCKED-ANDROID-EMULATOR` with its exact output.

- [ ] **Step 4: Capture Android emulator screens**

For each start index, launch the same harness on `emulator-5554`:

```bash
/Users/kpc/develop/flutter/bin/flutter run -d emulator-5554 --debug --no-resident --target integration_test/screenshot_harness_app.dart --dart-define=SOOKTA_QA_AUTO_ADVANCE=false --dart-define=SOOKTA_QA_LABEL=false --dart-define=SOOKTA_QA_START_INDEX=7
/Users/kpc/Library/Android/sdk/platform-tools/adb -s emulator-5554 exec-out screencap -p > docs/uat_evidence_20260719_platform_parity/android/09_evaluation_menu.png
```

Repeat with index/file pairs `8/10_evaluation_form.png`, `9/11_risk_reduction.png`, and `10/12_final_result.png`.

Before any tap or scroll is needed, dump the UI tree and derive coordinates from it:

```bash
/Users/kpc/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell uiautomator dump /sdcard/window.xml
/Users/kpc/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell cat /sdcard/window.xml
```

Never infer Android tap coordinates from a screenshot.

- [ ] **Step 5: Compare application-owned UI**

For each iOS/Android pair, record:

- navigation order and page title;
- Thai wording and button label;
- card/section order;
- four category-card keys and labels on risk-reduction/final screens;
- action enabled/disabled meaning;
- portrait fit and any overflow;
- system-owned differences only.

Any application-owned mismatch is `DEFECT` and must be fixed in the shared Flutter widget, followed by Tasks 3, 5, and the affected screenshots again.

- [ ] **Step 6: Publish the approved visual companion**

Confirm `.superpowers/brainstorm/7648-1784436236/state/server-info.json` exists and `server-stopped` does not. Replace `waiting.html` with a new uniquely named screen such as `platform-parity-results.html`; do not reuse an earlier filename. Show each iOS image next to the matching Android image, or an explicit Android `BLOCKED` card when capture could not run. Include the test/build/device matrix and links to the evidence files.

Push the new screen using the companion state protocol and keep the existing companion URL:

```text
http://localhost:61372/?key=f57818d82b200c97a1ea687edd7060fc6f525eed3fc2f58ffd1033ba68c918de
```

- [ ] **Step 7: Write the final UAT report**

Create `docs/uat-production-platform-parity-20260719.md` with:

- commit hash and date;
- focused/full test commands and totals;
- analyzer result;
- Android/iOS build commands and artifact paths;
- production device-flow result per platform;
- four-screen screenshot matrix;
- accepted system-owned differences;
- every blocker with exact command/output and no inferred pass;
- statement that uploaded video is accepted only after normal pose/readiness validation.

- [ ] **Step 8: Final verification**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/assessment_readiness_test.dart test/production_assessment_config_test.dart test/platform_ui_parity_test.dart test/portrait_orientation_config_test.dart test/initial_risk_confirmation_test.dart test/final_result_farmer_summary_test.dart
git diff --check
git status --short
```

Expected: all focused tests PASS; evidence/report files are present for successful platforms; unrelated native worktree changes are still unstaged.

- [ ] **Step 9: Commit QA evidence and report**

```bash
git add integration_test/screenshot_harness_app.dart docs/uat-production-platform-parity-20260719.md docs/uat_evidence_20260719_platform_parity
git commit -m "test: document production platform uat"
```
