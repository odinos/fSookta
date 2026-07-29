# Local Minimal-Impact Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** แก้ findings F1–F11 จาก local audit ด้วยการเปลี่ยนแปลงที่เล็กที่สุด ปลอดภัยต่อข้อมูลเดิม และยืนยันได้บนเครื่องพัฒนาโดยไม่พึ่งบัญชีบริษัทหรือบริการ review ภายนอก

**Architecture:** รักษา deterministic REBA/ISO เป็นผลหลักและให้ ML ที่ยังไม่ผ่าน research validation เป็นข้อมูลประกอบเท่านั้น การแก้ shared behavior ทำใน Dart เพื่อให้ iOS/Android ได้ผลเหมือนกัน ส่วน native code ใช้ contract tests และ local build gates แทนการปรับโครงสร้างครั้งใหญ่

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, SharedPreferences, TFLite, ONNX Runtime, XCTest/Xcode, Gradle, Android Emulator, iOS Simulator

## Global Constraints

- ทำงานแบบ local เท่านั้น ไม่ upload source, model, media หรือผลทดสอบไปยังบริษัทภายนอก
- ไม่เปลี่ยน deterministic REBA/ISO formulas ในแผนนี้
- ทุก task ต้องเริ่มจาก failing regression test และจบด้วย full `flutter analyze`/`flutter test`
- ห้ามลบหรือเขียนทับข้อมูลผู้ใช้เดิมระหว่าง schema migration
- ML failure ต้องไม่ทำให้ผู้ใช้ทำ assessment หลักต่อไม่ได้
- คง bundle ID/package name และ version `1.3.7+24` จนกว่าจะจบ remediation
- ทำทีละ task และ commit แยก เพื่อ rollback ได้ด้วย `git revert`

---

## ลำดับที่แนะนำ

| ลำดับ | Finding | วิธีที่กระทบน้อยที่สุด | ความเสี่ยง |
|---|---|---|---|
| 1 | F2 XGBoost เปลี่ยนคะแนน | คง inference/card แต่หยุดเปลี่ยน REBA/ISO | ต่ำ |
| 2 | F1 Daily Logistic template | ทำ validated probability เป็น `null` เมื่อยังไม่ train; คงคำเตือนจาก trend จริง | ต่ำ–กลาง |
| 3 | F3 Draft migration | migrate เฉพาะ draft ที่ profile ID ว่าง | ต่ำ |
| 4 | F5 XGBoost status | เพิ่ม status object และข้อความ fallback | ต่ำ |
| 5 | F6 Telemetry | sanitize error และ default collection เป็น off | ต่ำ |
| 6 | F11 README | แก้คำอธิบายให้ตรง artifact | ต่ำมาก |
| 7 | F4 Pose aspect ratio | shared letterbox preprocessor | กลาง |
| 8 | F8 Video parity | เพิ่ม fixture/contract tests ก่อนแตะ native algorithm | ต่ำ |
| 9 | F7 iOS FileProvider | ย้าย local workspace/build path; ยังไม่แก้ Podfile | ต่ำมาก |
| 10 | F9 Gradle ซ้ำ | ลบ KTS ที่ยืนยันแล้วว่าไม่ active | ต่ำ |
| 11 | F10 integration framework | เพิ่ม release gate ก่อน; ยังไม่ถอด framework จนผ่าน launch test | ต่ำ |

## Task 1: ทำ XGBoost เป็น advisory-only (F2)

**Files:**
- Modify: `lib/screens/main/evaluation_form_screen.dart:1695-1712`
- Test: `test/xgboost_guardrail_test.dart`
- Modify: `assets/models/model_artifact_manifest.json`

**Interfaces:**
- Consumes: `ErgoResult result`, `AiRiskAlert alert`
- Produces: `_applyXGBoostGuardrail` ที่คืน deterministic score/risk เดิมและแนบ `aiRiskAlert`

- [ ] **Step 1: แยก guardrail เป็นฟังก์ชันที่ทดสอบได้**

ย้าย logic ไปไฟล์ใหม่ถ้าจำเป็น:

```dart
ErgoResult attachAdvisoryXGBoostAlert(
  ErgoResult deterministic,
  AiRiskAlert alert,
) {
  return deterministic.copyWith(aiRiskAlert: alert);
}
```

- [ ] **Step 2: เขียน failing test**

```dart
test('XGBoost advisory never changes deterministic score or risk', () {
  const deterministic = ErgoResult(
    riskLevel: RiskLevel.low,
    techScore: 2,
    userScore: 2,
    userScoreColor: 0xFF66BB6A,
    limitValue: 9,
    suggestionKey: 'sugg_safe',
  );
  const alert = AiRiskAlert(
    probability: 0.95,
    logisticProbability: 0,
    xgBoostProbability: 0.95,
    level: AiAlertLevel.critical,
    modelVersion: 'test',
    modelSource: 'test',
    featureImportance: [],
  );

  final result = attachAdvisoryXGBoostAlert(deterministic, alert);
  expect(result.userScore, 2);
  expect(result.riskLevel, RiskLevel.low);
  expect(result.aiRiskAlert, same(alert));
});
```

- [ ] **Step 3: รัน test ให้เห็น failure ก่อน**

Run:

```bash
flutter test test/xgboost_guardrail_test.dart
```

Expected: FAIL เพราะฟังก์ชันยังไม่มี หรือคะแนนถูกยก

- [ ] **Step 4: ใช้ advisory function ใน evaluation flow**

แทน `_applyXGBoostGuardrail` เดิมด้วยการแนบ alert เท่านั้น ห้ามแก้ `userScore`, `riskLevel`, color หรือ suggestion

- [ ] **Step 5: ระบุสถานะใน manifest**

เพิ่ม note:

```json
"runtimePolicy": "advisory_only_does_not_modify_reba_or_iso_score"
```

- [ ] **Step 6: Verify local**

```bash
flutter test test/xgboost_guardrail_test.dart test/ml_end_to_end_comprehensive_test.dart
flutter analyze --no-pub
flutter test --no-pub
```

**Rollback:** revert commit นี้แล้ว behavior จะกลับไปยกคะแนนแบบเดิม โดยไม่ต้อง migrate data

## Task 2: ปิดการตีความ Daily Logistic template เป็นโมเดลที่ validate แล้ว (F1)

**Files:**
- Modify: `lib/core/services/daily_injury_prediction_service.dart`
- Modify: `lib/screens/main/daily_prediction_screen.dart`
- Modify: `lib/screens/main/final_result_screen.dart`
- Modify: `lib/screens/main/risk_reduction_potential_screen.dart`
- Test: `test/daily_injury_prediction_service_test.dart`
- Test: `test/daily_prediction_screen_test.dart`

**Interfaces:**
- Produces: `DailyInjuryPrediction.isResearchTrained`
- Behavior: trend/chart และคำเตือนจาก repeated actual REBA/ISO ยังแสดงเหมือนเดิม แต่ logistic probability ไม่ถูกนำเสนอเป็นค่าที่ validate แล้ว

- [ ] **Step 1: เขียน failing model-status test**

```dart
test('template probability is not exposed as research-trained', () {
  final service = DailyInjuryPredictionService.fromJson({
    'version': 'template',
    'source': 'template_coefficients',
    'minTransactions': 7,
    'trainingStatus': {
      'readyForAppUse': true,
      'researchTrained': false,
    },
    'thresholds': {'watch': 0.45, 'high': 0.65, 'critical': 0.82},
    'logisticRegression': {
      'intercept': 20,
      'coefficients': <String, double>{},
    },
  });

  final prediction = service.predictForRecords([
    for (var day = 1; day <= 7; day++)
      _record(
        day,
        score: 9,
        afterScore: 8,
        risk: RiskLevel.high,
      ),
  ]);
  expect(prediction.isResearchTrained, isFalse);
  expect(prediction.validatedProbability, isNull);
  expect(prediction.requiresTrendAttention, isTrue);
});
```

- [ ] **Step 2: Parse training status**

เพิ่ม field ใน model:

```dart
final bool researchTrained;
```

อ่านจาก:

```dart
final trainingStatus =
    Map<String, Object?>.from(json['trainingStatus'] as Map? ?? {});
final researchTrained =
    trainingStatus['researchTrained'] as bool? ?? false;
```

ส่งต่อมายัง result:

```dart
final bool isResearchTrained;

double? get validatedProbability =>
    isResearchTrained ? probability : null;

bool get requiresTrendAttention =>
    level == DailyInjuryPredictionLevel.high ||
    level == DailyInjuryPredictionLevel.critical;
```

- [ ] **Step 3: คง actual trend แต่ซ่อน probability UI**

เมื่อ `isResearchTrained == false`:

- แสดง chart, average, maximum, high-risk count ตามเดิม
- เปลี่ยนหัวข้อเป็น “แนวโน้มจากคะแนนที่บันทึก”
- แสดง badge “โมเดลต้นแบบ—ไม่ใช่ค่าความน่าจะเป็นที่ผ่านการฝึก”
- ไม่แสดง logistic probability, critical model alert หรือข้อความชวนตีความเป็น injury prediction

- [ ] **Step 4: แก้ final-result alert**

`_showDailyPredictionAlertIfNeeded` ใช้ `requiresTrendAttention` ซึ่งมาจาก repeated actual high-risk records ไม่ใช่ logistic probability และคง alias เดิมเฉพาะเพื่อ compatibility:

```dart
final repeatedActualHighRisk =
    prediction.highRiskCount >= 4;
```

ข้อความต้องใช้คำว่า “แนวโน้มคะแนนประเมิน” ไม่ใช้ “โอกาสบาดเจ็บ”

- [ ] **Step 5: Verify local**

```bash
flutter test test/daily_injury_prediction_service_test.dart
flutter test test/daily_prediction_screen_test.dart
flutter test --no-pub
```

**Rollback:** ไม่มี schema change; revert ได้ทันที ข้อมูล history ไม่เปลี่ยน

## Task 3: Migrate แบบร่างที่ไม่มี profile ID อย่างปลอดภัย (F3)

**Files:**
- Modify: `lib/app/app_state.dart:194-305`
- Test: `test/evaluation_draft_state_test.dart`
- Test: `integration_test/evaluation_draft_media_resume_test.dart`

**Interfaces:**
- Produces: private `_adoptUnownedDrafts(String profileId)`
- เงื่อนไข: migrate เฉพาะ draft ที่ `farmerProfileId` เป็น `null` หรือว่าง และเฉพาะเมื่อ restore สร้าง profile ใหม่จาก legacy profile

- [ ] **Step 1: เขียน regression test ที่ reproduce bug**

Test ต้อง:

1. เริ่ม preferences ว่าง
2. บันทึก draft ก่อนมี profile ID
3. สร้าง `SooktaAppState` ใหม่และ `restore()`
4. ยืนยันว่า profile ใหม่มี ID
5. ยืนยันว่า draft ถูกค้นด้วย ID ใหม่นั้นได้

```dart
expect(restored.profile.profileId, isNotEmpty);
expect(
  restored.evaluationDraftForProfile(
    restored.profile.profileId,
    activity: SooktaActivity.harvesting,
  ),
  isNotNull,
);
```

- [ ] **Step 2: เก็บ migration target ตอนสร้าง legacy profile ID**

ใน `_restore`:

```dart
String? adoptedLegacyProfileId;
if (_farmers.isEmpty && legacyProfile != null) {
  final normalized = _ensureProfileId(legacyProfile);
  _farmers.add(normalized);
  if (legacyProfile.profileId.isEmpty) {
    adoptedLegacyProfileId = normalized.profileId;
  }
}
```

- [ ] **Step 3: Adopt หลังโหลด drafts เสร็จ**

```dart
void _adoptUnownedDrafts(String profileId) {
  final candidates = _evaluationDrafts.values
      .where((draft) => (draft.farmerProfileId ?? '').trim().isEmpty)
      .toList(growable: false);
  for (final draft in candidates) {
    _evaluationDrafts.remove(_draftKey(draft));
    final adopted = draft.copyWith(farmerProfileId: profileId);
    _evaluationDrafts[_draftKey(adopted)] = adopted;
  }
}
```

เรียกหลัง parse `_evaluationDrafts` และก่อนกำหนด `_evaluationDraft`

- [ ] **Step 4: Persist migration**

เมื่อมีการ adopt ให้เรียก `_persist()` หลัง restore สำเร็จหนึ่งครั้ง เพื่อไม่ migrate ซ้ำ

- [ ] **Step 5: Verify local ทั้งสอง platform**

```bash
flutter test test/evaluation_draft_state_test.dart
flutter test integration_test/evaluation_draft_media_resume_test.dart -d emulator-5554
flutter test integration_test/evaluation_draft_media_resume_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
```

**Rollback:** สำรอง SharedPreferences JSON ก่อน schema migration มีอยู่แล้ว; ห้ามลบ media file

## Task 4: ทำ XGBoost failure/status ให้ตรวจสอบย้อนหลังได้ (F5)

**Files:**
- Create: `lib/core/models/ml_inference_status.dart`
- Modify: `lib/screens/main/evaluation_form_screen.dart`
- Modify: `lib/core/models/evaluation_models.dart`
- Test: `test/xgboost_status_test.dart`

**Interfaces:**
- Produces:

```dart
enum MlInferenceState { success, unavailable, invalidInput, runtimeError }

class XGBoostInferenceOutcome {
  const XGBoostInferenceOutcome({
    required this.state,
    this.alert,
    this.errorCode,
  });
  final MlInferenceState state;
  final AiRiskAlert? alert;
  final String? errorCode;
}
```

- [ ] **Step 1: เขียน failing tests**

ครอบคลุม:

- empty features → `invalidInput`
- predictor load error → `runtimeError`
- successful inference → `success` พร้อม alert
- status text ห้ามมี “checked with XGBoost” เมื่อ outcome ไม่ใช่ success

- [ ] **Step 2: เปลี่ยน return type**

เปลี่ยน `_predictXGBoostAlert` จาก `Future<AiRiskAlert?>` เป็น:

```dart
Future<XGBoostInferenceOutcome> _predictXGBoostAlert(
  List<PoseRebaFrameAnalysis> frameAnalyses,
)
```

catch ต้องคืน sanitized code:

```dart
return const XGBoostInferenceOutcome(
  state: MlInferenceState.runtimeError,
  errorCode: 'xgboost_runtime_error',
);
```

- [ ] **Step 3: เปลี่ยนข้อความ**

- success: “ตรวจเทียบสัญญาณด้วย XGBoost แล้ว”
- unavailable/error: “คำนวณ REBA แล้ว; XGBoost ไม่พร้อม จึงไม่ถูกนำมาใช้”

- [ ] **Step 4: Persist เฉพาะ provenance ที่จำเป็น**

เพิ่มใน history/export:

- inference state
- model version
- raw probability
- deterministic score ก่อนแนบ advisory

ใช้ nullable fields เพื่ออ่านข้อมูลเก่าได้

- [ ] **Step 5: Verify**

```bash
flutter test test/xgboost_status_test.dart
flutter test test/app_state_evaluation_persistence_test.dart
flutter test --no-pub
```

## Task 5: Telemetry แบบ local-safe และ default-off (F6)

**Files:**
- Modify: `lib/core/services/firebase_telemetry_service.dart`
- Modify: `lib/main.dart`
- Modify: `lib/screens/main/evaluation_form_screen.dart:946-956`
- Test: `test/firebase_telemetry_service_test.dart`
- Modify: `README.md`

**Interfaces:**
- Produces: `initialize({required bool enabled})`
- Build control: `--dart-define=SOOKTA_TELEMETRY_ENABLED=true`
- Default: false

- [ ] **Step 1: เขียน sanitization tests**

```dart
test('telemetry never includes local paths', () {
  final value = FirebaseTelemetryService.sanitizeErrorForTest(
    FileSystemException('failed', '/Users/name/photo.jpg'),
  );
  expect(value, 'file_system_error');
  expect(value, isNot(contains('/Users/')));
  expect(value, isNot(contains('photo.jpg')));
});
```

- [ ] **Step 2: Default collection off**

```dart
const telemetryEnabled = bool.fromEnvironment(
  'SOOKTA_TELEMETRY_ENABLED',
  defaultValue: false,
);
```

และ:

```dart
await FirebaseCrashlytics.instance
    .setCrashlyticsCollectionEnabled(enabled);
await _analytics.setAnalyticsCollectionEnabled(enabled);
_enabled = enabled;
if (!enabled) return;
```

- [ ] **Step 3: ส่ง error code แทน `e.toString()`**

```dart
'error_code': FirebaseTelemetryService.errorCode(e),
```

mapping ขั้นต่ำ:

- `FileSystemException` → `file_system_error`
- `PlatformException` → `platform_${_safeKey(error.code)}`
- `FormatException` → `invalid_input_format`
- อื่น ๆ → `unexpected_error`

- [ ] **Step 4: Verify offline/default build**

```bash
flutter test test/firebase_telemetry_service_test.dart
flutter build appbundle --release --no-pub
flutter build ios --release --no-codesign --no-pub
```

ตรวจ log ว่า default build ไม่มี `app_start` event

**Rollback:** เปิด telemetry ชั่วคราวได้จาก local build define โดยไม่เปลี่ยน source

## Task 6: แก้เอกสาร ML ให้ตรง behavior (F11)

**Files:**
- Modify: `README.md:53-64,182-201`
- Modify: `assets/models/model_artifact_manifest.json`
- Test: `test/production_assessment_config_test.dart`

- [ ] **Step 1: เขียน documentation assertion**

เพิ่ม test อ่าน README/manifest และยืนยันคำสำคัญ:

```dart
expect(readme, contains('Legacy posture Logistic'));
expect(readme, contains('ไม่ถูก package'));
expect(readme, contains('template coefficients'));
expect(readme, contains('XGBoost advisory-only'));
```

- [ ] **Step 2: แยกโมเดลเป็นสามชนิด**

README ต้องระบุ:

1. Legacy posture Logistic — traceability only, not packaged
2. Daily Logistic — packaged แต่ template/not research-trained
3. XGBoost ONNX — on-device advisory, ไม่แก้ REBA/ISO

- [ ] **Step 3: Verify**

```bash
flutter test test/production_assessment_config_test.dart
git diff --check
```

## Task 7: Letterbox preprocessing ร่วมสำหรับ MoveNet (F4)

**Files:**
- Create: `lib/core/services/pose_image_preprocessor.dart`
- Modify: `lib/core/services/pose_estimation_service.dart`
- Modify: `lib/core/services/multi_person_pose_detector.dart`
- Create: `test/pose_image_preprocessor_test.dart`
- Test: `integration_test/pose_device_inference_test.dart`

**Interfaces:**
- Produces:

```dart
class PoseImagePreprocessor {
  static const inputSize = 256;
  static img.Image letterbox(img.Image source);
}
```

- [ ] **Step 1: เขียน image geometry tests**

สำหรับภาพ `100x200`:

- resized content ต้องเป็น `128x256`
- padding ซ้าย/ขวาอย่างละ 64 pixels
- output ต้องเป็น `256x256`

สำหรับภาพ `200x100`:

- content `256x128`
- padding บน/ล่างอย่างละ 64 pixels

- [ ] **Step 2: Implement uniform-scale letterbox**

```dart
static img.Image letterbox(img.Image source) {
  const size = inputSize;
  final scale = math.min(size / source.width, size / source.height);
  final width = math.max(1, (source.width * scale).round());
  final height = math.max(1, (source.height * scale).round());
  final resized = img.copyResize(
    source,
    width: width,
    height: height,
    interpolation: img.Interpolation.linear,
  );
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
  img.compositeImage(
    canvas,
    resized,
    dstX: (size - width) ~/ 2,
    dstY: (size - height) ~/ 2,
  );
  return canvas;
}
```

เก็บ keypoints ใน normalized tensor square สำหรับ calculation เพื่อรักษามุมหลัง uniform scaling ห้าม remap เป็น x/width และ y/height แยกกันก่อนคำนวณมุม

- [ ] **Step 3: ใช้ preprocessor เดียวกันใน single/multipose**

แทน `copyResize` สองจุดด้วย:

```dart
final resized = PoseImagePreprocessor.letterbox(decoded);
```

- [ ] **Step 4: สร้าง baseline comparison**

ใช้ภาพ fixture เดิมบันทึก:

- person confidence
- trunk/neck/arm angles
- final deterministic REBA

review การเปลี่ยนแปลงก่อนรับค่าใหม่ เพราะผล pose อาจเปลี่ยนโดยตั้งใจ

- [ ] **Step 5: Verify iOS/Android**

```bash
flutter test test/pose_image_preprocessor_test.dart
flutter test --no-pub
flutter test integration_test/pose_device_inference_test.dart -d emulator-5554
flutter test integration_test/pose_device_inference_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
```

**Rollback:** revert task นี้อย่างเดียวได้; model files ไม่เปลี่ยน

## Task 8: เพิ่ม video contract tests ก่อนแก้ native code (F8)

**Files:**
- Add: `assets/test_fixtures/video/portrait_h264_4s.mp4`
- Add: `assets/test_fixtures/video/landscape_h264_4s.mp4`
- Create: `integration_test/video_frame_contract_test.dart`
- Modify: `pubspec.yaml`
- ภายหลังเท่านั้น: `ios/Runner/AppDelegate.swift`
- ภายหลังเท่านั้น: `android/app/src/main/kotlin/com/kdev/sookta/MainActivity.kt`

**Interfaces:**
- Contract:
  - `durationMs` tolerance ±150 ms
  - frame count 4
  - timestamp tolerance ±300 ms
  - max dimension ≤720
  - orientation ตรง fixture

- [ ] **Step 1: สร้าง fixtures local**

ใช้ไฟล์ที่ไม่มีข้อมูลส่วนบุคคล สร้างด้วย local tool เช่น FFmpeg หรือกล้อง simulator และ commit เฉพาะไฟล์สั้น

- [ ] **Step 2: เขียน integration contract test**

เรียก `VideoFrameExtractionService` และตรวจ contract ด้านบน รวมทั้งไฟล์ output เปิดอ่านเป็น image ได้

- [ ] **Step 3: รันทั้งสองระบบก่อนแก้ native**

```bash
flutter test integration_test/video_frame_contract_test.dart -d emulator-5554
flutter test integration_test/video_frame_contract_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
```

- [ ] **Step 4: ปรับ native เฉพาะ assertion ที่ไม่ผ่าน**

ลำดับแก้น้อยไปมาก:

1. Android API <27 resize output หลัง `getFrameAtTime`
2. normalize rotation ถ้า fixture แสดง orientation ผิด
3. ปรับ timestamp option/tolerance เฉพาะเมื่อเกิน contract

ห้ามพยายามทำ pixel-perfect ระหว่าง AVFoundation และ MediaMetadataRetriever

## Task 9: แก้ iOS FileProvider โดยจัดการเครื่องพัฒนา ไม่แตะ source (F7)

**Files:** ไม่มี production source change ในขั้นแรก

- [ ] **Step 1: สร้าง local workspace นอก Documents/iCloud**

ตัวอย่าง:

```bash
mkdir -p /Users/kpc/Developer
git clone --local \
  /Users/kpc/Documents/GitHub/fSookta \
  /Users/kpc/Developer/fSookta-local
```

นำเฉพาะ uncommitted documents ที่ต้องการตามไปด้วยอย่างระมัดระวัง หรือ commit ก่อน clone

- [ ] **Step 2: Resolve dependencies local**

```bash
cd /Users/kpc/Developer/fSookta-local
flutter pub get --offline
cd ios
pod install
```

- [ ] **Step 3: Verify**

```bash
flutter test integration_test/ml_device_inference_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
flutter test integration_test/pose_device_inference_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
flutter build ios --release --no-codesign
```

- [ ] **Step 4: ยังไม่ลด metadata scripts**

ให้เก็บ Podfile ปัจจุบันไว้จน workspace ใหม่ผ่านซ้ำอย่างน้อย 3 clean builds จากนั้นเปิด task แยกเพื่อลด scripts ทีละ phase พร้อม build test ทุกครั้ง

**Rollback:** กลับมาใช้ repo เดิมได้ทันที; ไม่มี source/data migration

## Task 10: เหลือ Gradle DSL ชุดเดียว (F9)

**Files:**
- Delete: `android/build.gradle.kts`
- Delete: `android/settings.gradle.kts`
- Delete: `android/app/build.gradle.kts`
- Verify: Groovy files ทั้งสาม

- [ ] **Step 1: เก็บ baseline**

```bash
flutter build appbundle --release --no-pub
```

บันทึก application ID, version, ABI list และ Firebase plugin tasks

- [ ] **Step 2: ลบเฉพาะ KTS ที่ไม่ active**

ก่อนลบยืนยันว่า Gradle output ใช้:

- `android/settings.gradle`
- `android/build.gradle`
- `android/app/build.gradle`

- [ ] **Step 3: Build ซ้ำและเปรียบเทียบ**

```bash
flutter clean
flutter pub get --offline
flutter build appbundle --release --no-pub
unzip -l build/app/outputs/bundle/release/app-release.aab
```

Expected: package/version/ABI/native libs เท่า baseline

**Rollback:** restore ไฟล์ KTS จาก commit ก่อนหน้า

## Task 11: จัดการ integration_test.framework แบบ safety gate (F10)

**Files:**
- Create: `tooling/verify_ios_release_artifact.sh`
- ภายหลัง: `ios/Podfile`
- ภายหลัง: iOS release plugin registration configuration

**เหตุผลที่ไม่ควรถอดทันที:** framework ถูก register เป็น native plugin; ลบจาก `.app` โดยตรงอาจทำให้ dyld หรือ GeneratedPluginRegistrant crash ตอนเปิดแอป ผลกระทบของการรีบแก้สูงกว่าขนาดที่ประหยัดได้

- [ ] **Step 1: เพิ่ม local inspection gate**

Script ต้องรายงานแต่ยังไม่ fail ในรอบแรก:

```bash
APP="build/ios/iphoneos/Runner.app"
test -d "$APP"
find "$APP/Frameworks" -maxdepth 1 -name 'integration_test.framework' -print
otool -L "$APP/Runner" | grep -i integration_test || true
nm -u "$APP/Runner" | grep -i IntegrationTest || true
```

- [ ] **Step 2: วัดขนาดและ dependency จริง**

```bash
du -sh build/ios/iphoneos/Runner.app/Frameworks/integration_test.framework
```

ถ้า binary มี dynamic dependency ห้ามลบ framework หลัง build

- [ ] **Step 3: ทำ isolated experiment**

ใน branch แยก:

1. ทำ Release-only plugin exclusion ที่ Podfile/registration
2. clean pod install
3. build release
4. install/launch บน simulator และ iPhone จริง
5. รัน smoke flow เปิดแอป → assessment → save

- [ ] **Step 4: Acceptance**

รับการถอด framework เฉพาะเมื่อ:

- ไม่มี `integration_test.framework`
- app launch ผ่านบน simulator และ iPhone จริง
- ONNX/TFLite tests และ release smoke flow ผ่าน
- ไม่มี GeneratedPluginRegistrant missing-class error

ถ้ายังไม่มี iPhone จริง ให้คง framework ไว้และบันทึกเป็น accepted low-severity debt

## Final Local Verification

หลังทำแต่ละ task:

```bash
flutter analyze --no-pub
flutter test --no-pub
git diff --check
```

หลังครบ shared-code tasks 1–7:

```bash
flutter build appbundle --release --no-pub
flutter build ios --release --no-codesign --no-pub
```

Device/simulator matrix:

```bash
flutter test integration_test/ml_device_inference_test.dart -d emulator-5554
flutter test integration_test/pose_device_inference_test.dart -d emulator-5554
flutter test integration_test/production_assessment_flow_test.dart -d emulator-5554
flutter test integration_test/evaluation_draft_media_resume_test.dart -d emulator-5554

flutter test integration_test/ml_device_inference_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
flutter test integration_test/pose_device_inference_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
flutter test integration_test/production_assessment_flow_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
flutter test integration_test/evaluation_draft_media_resume_test.dart -d 851A067D-1E4A-44B8-8990-CFE9509C5689
```

## Local-Only Definition of Done

- deterministic REBA/ISO ไม่ถูก ML เปลี่ยน
- template Daily Logistic ไม่แสดง probability เสมือน validate แล้ว; trend alert มาจากประวัติคะแนนจริง
- draft ที่ไม่มี profile ID เปิดได้หลัง restore
- XGBoost failure มีสถานะและข้อความตรงความจริง
- default build ไม่ส่ง telemetry และ error logs ไม่มี local path
- portrait/landscape pose ใช้ uniform-scale preprocessing
- video channel ผ่าน contract เดียวกันทั้งสอง OS
- iOS build/test ทำซ้ำได้จาก non-FileProvider workspace
- Android release มี Gradle DSL source of truth ชุดเดียว
- iOS test framework ถูกคงไว้จนพิสูจน์ว่าเอาออกแล้ว launch ปลอดภัย
- README และ model manifest ตรงกับ runtime behavior
