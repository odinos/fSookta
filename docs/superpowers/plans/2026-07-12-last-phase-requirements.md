# Sookta Last-Phase Requirements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verify and complete every requirement in `2026-07-12-last-phase-requirements-design.md`, lock the app to portrait orientation, and produce physical-device UAT evidence.

**Architecture:** Preserve the existing offline-first Flutter design and the uncommitted feature work already present. Add only confirmed gaps inside current state/model/service/screen boundaries, with platform orientation locks in iOS and Android configuration and regression coverage for every behavior change.

**Tech Stack:** Flutter/Dart, SharedPreferences, image_picker, iOS Info.plist, Android Manifest, flutter_test, integration_test, Xcode/CoreDevice, Android SDK/ADB.

## Global Constraints

- The English design spec is authoritative.
- Support portrait orientation only on iOS and Android phones and tablets.
- Preserve the current illustrated activity-selection UI.
- Preserve existing uncommitted work and unrelated user changes.
- Keep farmer output simple while retaining staff/research technical data.
- Never report hardware-dependent checks as passed without physical-device evidence.

---

### Task 1: Requirement Matrix and Gap Audit

**Files:**
- Create: `docs/last-phase-requirement-matrix-20260712.md`
- Inspect: `lib/app/app_state.dart`
- Inspect: `lib/core/models/assessment_session.dart`
- Inspect: `lib/core/services/assessment_export_service.dart`
- Inspect: `lib/core/services/pose_estimation_service.dart`
- Inspect: `lib/screens/main/evaluation_form_screen.dart`
- Inspect: `lib/screens/main/evaluation_menu_screen.dart`
- Inspect: `lib/screens/main/initial_risk_screen.dart`
- Inspect: `lib/screens/main/final_result_screen.dart`
- Inspect: `lib/screens/main/daily_prediction_screen.dart`
- Inspect: `lib/screens/main/farmer_manager_screen.dart`
- Inspect: `lib/screens/main/help_screen.dart`
- Inspect: `lib/widgets/tts_button.dart`

**Interfaces:**
- Consumes: Every numbered requirement in `/Users/kpc/Desktop/App Developer_LastPhase.md`.
- Produces: One matrix row per requirement with `PASS`, `GAP`, or `DEVICE-ONLY`, plus exact code/test evidence and the implementation task responsible for each gap.

- [ ] **Step 1: Create the matrix skeleton**

```markdown
| ID | Requirement | Status | Code evidence | Automated evidence | Device evidence |
| --- | --- | --- | --- | --- | --- |
| 1.1 | Change selected activity safely | GAP | pending audit | pending audit | pending UAT |
```

- [ ] **Step 2: Audit all 19 numbered source requirements**

Run:

```bash
rg -n "draft|pickMultiImage|poseAssessmentReady|appVersion|trend|avatarAsset|TtsButton|BodyRiskMap|recommend" lib test
```

Expected: each matrix row links to at least one exact file and test, or is marked `GAP` with a concrete missing behavior.

- [ ] **Step 3: Verify the audit document is complete**

Run:

```bash
rg -c '^\| [1-6]\.[1-9]' docs/last-phase-requirement-matrix-20260712.md
```

Expected: `19`.

- [ ] **Step 4: Commit the audit only**

```bash
git add docs/last-phase-requirement-matrix-20260712.md
git commit -m "docs: audit last-phase requirements"
```

### Task 2: Portrait-Only Platform Contract

**Files:**
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `test/portrait_orientation_config_test.dart`

**Interfaces:**
- Consumes: iOS `UISupportedInterfaceOrientations` arrays and Android `android:screenOrientation`.
- Produces: iOS phone/iPad portrait-only declarations and Android `portrait` activity orientation.

- [ ] **Step 1: Write failing platform-configuration tests**

```dart
test('iOS supports portrait orientation only', () {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  expect(plist, contains('<string>UIInterfaceOrientationPortrait</string>'));
  expect(plist, isNot(contains('UIInterfaceOrientationLandscapeLeft')));
  expect(plist, isNot(contains('UIInterfaceOrientationLandscapeRight')));
  expect(plist, isNot(contains('UIInterfaceOrientationPortraitUpsideDown')));
});

test('Android main activity is locked to portrait', () {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();
  expect(manifest, contains('android:screenOrientation="portrait"'));
});
```

- [ ] **Step 2: Run tests and verify the expected failure**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/portrait_orientation_config_test.dart --no-pub
```

Expected: FAIL because iOS includes landscape values and Android has no portrait lock.

- [ ] **Step 3: Add minimal platform locks**

Use these iOS arrays:

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

Add this attribute to `.MainActivity`:

```xml
android:screenOrientation="portrait"
```

- [ ] **Step 4: Run focused tests until green**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/portrait_orientation_config_test.dart --no-pub
```

Expected: all orientation configuration tests pass.

- [ ] **Step 5: Commit orientation files only**

```bash
git add ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml test/portrait_orientation_config_test.dart
git commit -m "feat: lock app to portrait orientation"
```

### Task 3: Validate and Complete Existing Functional Work

**Files:**
- Modify: `lib/app/app_state.dart`
- Modify: `lib/core/models/assessment_session.dart`
- Modify: `lib/core/services/assessment_export_service.dart`
- Modify: `lib/core/services/local_image_store.dart`
- Modify: `lib/screens/main/evaluation_form_screen.dart`
- Modify: `lib/screens/main/evaluation_menu_screen.dart`
- Modify: `lib/screens/main/initial_risk_screen.dart`
- Modify: `lib/screens/main/final_result_screen.dart`
- Modify: `lib/screens/main/daily_prediction_screen.dart`
- Modify: `lib/widgets/tts_button.dart`
- Test: `test/evaluation_draft_state_test.dart`
- Test: `test/evaluation_form_image_slots_test.dart`
- Test: `test/assessment_export_service_test.dart`
- Test: `test/final_result_farmer_summary_test.dart`
- Test: `test/history_tab_filter_trend_test.dart`
- Test: `test/tts_button_voice_quality_test.dart`

**Interfaces:**
- Consumes: existing uncommitted implementations for draft scoping, persistent media, image slots, farmer summary, trend filtering, export metadata, migration backup, and concise TTS.
- Produces: verified behavior for all matrix rows, with any discovered defect corrected through a focused red-green regression cycle.

- [ ] **Step 1: Run the focused requirement suite**

```bash
/Users/kpc/develop/flutter/bin/flutter test test/evaluation_draft_state_test.dart test/evaluation_form_image_slots_test.dart test/assessment_export_service_test.dart test/final_result_farmer_summary_test.dart test/history_tab_filter_trend_test.dart test/tts_button_voice_quality_test.dart --no-pub
```

Expected: every existing last-phase regression test passes.

- [ ] **Step 2: Inspect each matrix row against user-observable behavior**

Use these exact ownership boundaries:

```text
Draft persistence -> SooktaAppState/EvaluationDraft/LocalImageStore
Image selection or slot validation -> EvaluationFormScreen/PoseEstimationService
Farmer summary or technical disclosure -> InitialRiskScreen/FinalResultScreen
Trend/export -> DailyPredictionScreen/AssessmentExportService
Avatar isolation -> UserProfile/FarmerManagerScreen/profile consumers
TTS -> existing TtsButton and screen-provided concise text
```

Expected: every non-device-only matrix row has both code evidence and a passing test.

- [ ] **Step 3: For any failing behavior, add a focused failing test before editing production code**

The test must be placed in the exact existing test file responsible for that behavior and must fail because the requirement is missing, not because of fixture setup.

- [ ] **Step 4: Apply the minimum production fix and rerun the focused suite**

```bash
/Users/kpc/develop/flutter/bin/flutter test test/evaluation_draft_state_test.dart test/evaluation_form_image_slots_test.dart test/assessment_export_service_test.dart test/final_result_farmer_summary_test.dart test/history_tab_filter_trend_test.dart test/tts_button_voice_quality_test.dart --no-pub
```

Expected: all selected tests pass.

- [ ] **Step 5: Update matrix evidence and commit only files changed by this task**

```bash
git status --short
git diff --check
```

Expected: no whitespace errors; stage the exact functional and test files shown by the diff, plus `docs/last-phase-requirement-matrix-20260712.md`, then commit with a requirement-specific message.

### Task 4: Full Automated Verification and Builds

**Files:**
- Modify only if verification exposes a regression caused by Tasks 2-3.
- Record: `docs/last-phase-requirement-matrix-20260712.md`

**Interfaces:**
- Consumes: complete working tree after Tasks 1-3.
- Produces: fresh analyzer, test, Android build, and iOS build evidence.

- [ ] **Step 1: Run static analysis**

```bash
/Users/kpc/develop/flutter/bin/flutter analyze --no-pub
```

Expected: `No issues found!`.

- [ ] **Step 2: Run the complete automated suite**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub
```

Expected: all tests pass with zero failures.

- [ ] **Step 3: Build Android debug artifact**

```bash
/Users/kpc/develop/flutter/bin/flutter build apk --debug --no-pub
```

Expected: exit code 0 and `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 4: Build iOS without signing**

```bash
/usr/bin/env COPYFILE_DISABLE=1 /Users/kpc/develop/flutter/bin/flutter build ios --debug --no-codesign --no-pub
```

Expected: exit code 0 and `build/ios/iphoneos/Runner.app` exists.

- [ ] **Step 5: Record exact command results in the matrix**

Update the matrix with dates, exit codes, total test count, and artifact paths.

### Task 5: Physical-Device UAT and Final Evidence

**Files:**
- Create: `docs/uat-last-phase-20260712.md`
- Create: `docs/uat_evidence_20260712_last_phase/` evidence files.
- Modify: `docs/last-phase-requirement-matrix-20260712.md`

**Interfaces:**
- Consumes: built application, connected device list, approved 13-step UAT checklist.
- Produces: device-specific `PASS`, `FAIL`, `BLOCKED`, `NOT AVAILABLE`, or `PENDING-MANUAL` evidence.

- [ ] **Step 1: Detect connected physical devices**

```bash
/Users/kpc/develop/flutter/bin/flutter devices
/Users/kpc/Library/Android/sdk/platform-tools/adb devices -l
xcrun devicectl list devices
```

Expected: record every detected physical device and connection state.

- [ ] **Step 2: Install and launch on each available device**

```bash
/Users/kpc/develop/flutter/bin/flutter install -d R5CW13JKESA --debug
/usr/bin/env COPYFILE_DISABLE=1 /Users/kpc/develop/flutter/bin/flutter install -d 00008030-0008788421F3802E --debug
```

Expected: successful install on each device currently reported as connected. If either known device ID is unavailable, record `NOT AVAILABLE` for that device rather than treating the command as a product failure.

- [ ] **Step 3: Execute the approved 13-step physical checklist**

Record orientation lock, multi-farmer avatars, draft resume, activity change, four-image selection/replacement/removal, invalid-image feedback, final action, farmer/admin results, TTS, filtered export, offline relaunch, and captured evidence.

- [ ] **Step 4: Inspect an exported research file**

Required fields:

```text
Farmer ID
Farmer name
Assessment date
Activity
Risk score
Risky body parts
Image references
AI analysis
App version
```

- [ ] **Step 5: Write the final UAT report**

The report must include device models/OS versions, app version, commands, screenshots/log paths, requirement matrix, unresolved defects, and manual-only checks. Do not label unobserved behavior as `PASS`.

- [ ] **Step 6: Re-run final verification after UAT-driven fixes**

```bash
/Users/kpc/develop/flutter/bin/flutter analyze --no-pub
/Users/kpc/develop/flutter/bin/flutter test --no-pub
```

Expected: analyzer clean and all tests pass.

- [ ] **Step 7: Commit reports and evidence index**

```bash
git add docs/uat-last-phase-20260712.md docs/uat_evidence_20260712_last_phase docs/last-phase-requirement-matrix-20260712.md
git commit -m "test: document last-phase physical UAT"
```
