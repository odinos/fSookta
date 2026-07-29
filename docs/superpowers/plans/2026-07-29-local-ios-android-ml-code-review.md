# Local iOS, Android, and ML Code Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ตรวจสอบ source code ล่าสุดของ Sookta แบบ local-only และให้ข้อสรุปที่อ้างอิงหลักฐานได้ว่า ML และฟีเจอร์หลักทำงานบน iOS/Android อย่างไร มีข้อบกพร่องหรือความต่างตรงไหน และต้องแก้อะไรเพื่อให้สองแพลตฟอร์มทำงานสอดคล้องกัน

**Architecture:** การตรวจแบ่งเป็น 6 แนวหลัก: baseline ของ repository, shared Flutter code, ML pipeline, native iOS, native Android และการทดสอบบน simulator/emulator/device ที่หาได้ ผลทุกข้อจะผูกกับไฟล์/บรรทัด/คำสั่ง/ผลทดสอบ และแยก “ยืนยันแล้ว”, “อนุมานจากโค้ด”, “ยังยืนยันไม่ได้เพราะไม่มีอุปกรณ์” อย่างชัดเจน

**Tech Stack:** Flutter/Dart, Kotlin/Gradle, Swift/CocoaPods/Xcode, TensorFlow Lite MoveNet, ONNX Runtime/XGBoost, Logistic Regression JSON models, Flutter unit/widget/integration tests

## Global Constraints

- ตรวจแบบ local เท่านั้น ไม่ใช้ CodeRabbit และไม่ส่ง source code ไปบริการภายนอก
- รอบตรวจนี้เป็น read-only ต่อ production source; อนุญาตให้สร้างเฉพาะรายงานและไฟล์หลักฐานการทดสอบ
- ไม่แก้ code, dependency, signing, provisioning, Firebase configuration หรือ store artifact ระหว่างการตรวจ
- ไม่สรุปว่าเครื่องจริง PASS จากผล simulator/emulator
- เอกสาร UAT เดิมใช้เป็นข้อมูลเปรียบเทียบเท่านั้น ผลปัจจุบันต้องรันใหม่จาก commit และ working tree ล่าสุด
- รักษาไฟล์ที่ผู้ใช้แก้ไว้ทั้งหมด และแยกผลจาก committed/uncommitted code
- ถ้าคำสั่งใดต้องดาวน์โหลด dependency หรือเข้าถึงเครือข่าย ให้หยุดและขออนุญาตก่อน

---

## Expected Outputs

**Files:**

- Create: `docs/reviews/local-platform-ml-review-2026-07-29.md`
- Create when test output is material: `docs/reviews/evidence/2026-07-29/`
- Do not modify: `lib/**`, `ios/**`, `android/**`, `assets/**`, `test/**`, `integration_test/**`, `pubspec.yaml`

**Final report sections:**

1. Executive summary และ release confidence
2. Findings เรียง Critical / High / Medium / Low
3. ML pipeline: MoveNet, feature extraction, Logistic Regression, XGBoost ONNX, model contracts และ fallback
4. Capability matrix: shared / iOS-only / Android-only / unverified
5. Build, permissions, privacy, storage, camera/gallery/video/TTS/export/telemetry
6. Test evidence และข้อจำกัดของหลักฐาน
7. Platform parity gap พร้อมวิธีแก้ ลำดับงาน และ acceptance criteria

---

### Task 1: Freeze the Review Baseline

**Files:**

- Inspect: `.git/HEAD`
- Inspect: `pubspec.yaml`
- Inspect: `.flutter-plugins-dependencies`
- Inspect: `README.md`
- Record in: `docs/reviews/local-platform-ml-review-2026-07-29.md`

**Interfaces:**

- Consumes: repository และ Flutter SDK ที่ติดตั้งอยู่
- Produces: commit SHA, branch, dirty-file list, SDK/toolchain versions และ dependency snapshot สำหรับอ้างอิงทุกผลตรวจ

- [ ] **Step 1: บันทึก commit, branch และ working tree โดยไม่เปลี่ยนสถานะ**

  Run:

  ```sh
  git rev-parse HEAD
  git branch --show-current
  git status --short --branch
  git diff --stat
  git diff --cached --stat
  ```

  Expected: ได้ baseline ที่แยก committed, staged และ unstaged changes ชัดเจน

- [ ] **Step 2: บันทึก toolchain ที่ใช้งานจริง**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter --version
  /Users/kpc/develop/flutter/bin/dart --version
  xcodebuild -version
  java -version
  ```

  Expected: ระบุ Flutter/Dart/Xcode/Java version ได้ หรือระบุเครื่องมือที่ไม่มีอย่างตรงไปตรงมา

- [ ] **Step 3: ตรวจ dependency snapshot แบบไม่เรียก network**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter pub deps --no-dev
  sed -n '1,180p' pubspec.yaml
  ```

  Expected: ยืนยัน direct/transitive packages และ local override ของ `third_party/onnxruntime_16kb`

- [ ] **Step 4: สร้างหัวรายงานพร้อม baseline**

  Record: วันที่, branch, commit SHA, dirty state, app version `1.3.7+24`, package ID `com.kdev.sookta` และข้อจำกัดเรื่องอุปกรณ์

---

### Task 2: Map Product Capabilities and Platform Branches

**Files:**

- Inspect: `lib/main.dart`
- Inspect: `lib/app/sookta_app.dart`
- Inspect: `lib/app/app_state.dart`
- Inspect: `lib/screens/main/**`
- Inspect: `lib/widgets/tts_button.dart`
- Inspect: `ios/Runner/AppDelegate.swift`
- Inspect: `android/app/src/main/kotlin/com/kdev/sookta/MainActivity.kt`

**Interfaces:**

- Consumes: app entry points, navigation, state, services และ native channels
- Produces: runtime flow map และรายการ branch ที่ขึ้นกับ `Platform.isIOS`, `Platform.isAndroid`, `TargetPlatform`, MethodChannel หรือ native API

- [ ] **Step 1: หา platform-specific branches ทั้ง repository**

  Run:

  ```sh
  rg -n "Platform\.is|TargetPlatform|defaultTargetPlatform|MethodChannel|EventChannel|dart:io|UIDevice|AVFoundation|MediaMetadataRetriever|Build\.VERSION" lib ios/Runner android/app/src/main test integration_test
  ```

  Expected: ได้รายการจุดแยก iOS/Android ที่ครบและตรวจย้อนกลับได้

- [ ] **Step 2: ไล่ flow จากเปิดแอปถึงบันทึกผล**

  Trace: bootstrap → onboarding → farmer/profile → activity → media capture/import → pose inference → readiness gate → risk calculation → result → history/export

  Expected: ระบุ service และ state object ที่รับผิดชอบแต่ละช่วง พร้อมจุด failure/fallback

- [ ] **Step 3: สร้าง capability matrix รุ่นแรก**

  Rows: onboarding, localization, farmer profiles, camera, gallery, video, frame extraction, pose detection, ML risk prediction, REBA, ISO 11228, TTS, persistence, history, CSV export/share, Firebase telemetry, manual PDF

  Columns: Shared Flutter, iOS implementation, Android implementation, automated evidence, device evidence, current status

---

### Task 3: Review the ML and Ergonomic Assessment Pipeline

**Files:**

- Inspect: `lib/core/services/pose_estimation_service.dart`
- Inspect: `lib/core/services/multi_person_pose_detector.dart`
- Inspect: `lib/core/services/ergo_calculator.dart`
- Inspect: `lib/core/services/daily_injury_prediction_service.dart`
- Inspect: `lib/core/services/risk_alert_model_service.dart`
- Inspect: `lib/core/ergonomics_risk_prediction/**`
- Inspect: `assets/models/**`
- Inspect: `assets/ml/**`
- Inspect: `docs/model-artifact-contract.md`
- Test: `test/ml_end_to_end_comprehensive_test.dart`
- Test: `test/ergonomic_risk_prediction_test.dart`
- Test: `test/daily_injury_prediction_service_test.dart`
- Test: `test/multi_person_pose_detector_test.dart`
- Test: `integration_test/ml_device_inference_test.dart`
- Test: `integration_test/pose_device_inference_test.dart`

**Interfaces:**

- Consumes: image bytes/frames, pose keypoints, joint feature schema, model assets และ ergonomic form inputs
- Produces: pose result, quality/readiness state, REBA/ISO score, model prediction, risk level, provenance/version และ error/fallback behavior

- [ ] **Step 1: ตรวจ model asset integrity**

  Run:

  ```sh
  shasum -a 256 assets/ml/*.tflite assets/ml/*.json assets/models/*.json assets/models/*.onnx
  ls -lh assets/ml assets/models
  ```

  Expected: ทุก asset ที่ประกาศใน `pubspec.yaml` มีอยู่ ขนาดไม่เป็นศูนย์ และ hash ถูกบันทึกในรายงาน

- [ ] **Step 2: ตรวจ schema/metadata/manifest consistency**

  Compare: input tensor shape, keypoint ordering, normalization, feature count/order, label mapping, model version, threshold และ output shape ระหว่าง JSON metadata กับ Dart code

  Expected: ระบุ mismatch ได้เป็นราย field; ไม่มีการถือว่า filename ตรงแล้ว contract จะตรงโดยอัตโนมัติ

- [ ] **Step 3: ตรวจ MoveNet preprocessing และ postprocessing**

  Verify: resize/crop/padding, RGB order, numeric type, normalization, tensor shape, keypoint confidence, person count, coordinate transform, image orientation และ mirrored camera input

  Expected: สรุปว่าพฤติกรรมภาพจากกล้อง/คลัง/วิดีโอเหมือนกันหรือไม่ และความต่างใดอาจเกิดเฉพาะแพลตฟอร์ม

- [ ] **Step 4: ตรวจ Logistic Regression และ XGBoost ONNX**

  Verify: initialization lifecycle, feature vector ordering, dtype/shape, sigmoid/threshold, class mapping, resource disposal, repeated inference, exception translation และ fallback

  Expected: ยืนยันว่า predictor ใดเป็น production path, predictor ใดเป็น A/B/research path และเมื่อ ONNX ใช้ไม่ได้แอปทำอะไร

- [ ] **Step 5: ตรวจ deterministic ergonomic logic**

  Verify: REBA input validation, ISO 11228 applicability, missing-data handling, before/after scores, risk band boundaries และ separation จาก economic-impact layer

  Expected: แยกข้อสรุป “ผลจาก ML” ออกจาก “กฎ REBA/ISO” และ “economic impact” ชัดเจน

- [ ] **Step 6: รัน ML-focused unit tests แบบ local**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter test --no-pub test/ml_end_to_end_comprehensive_test.dart test/ergonomic_risk_prediction_test.dart test/daily_injury_prediction_service_test.dart test/multi_person_pose_detector_test.dart test/ergo_calculator_test.dart
  ```

  Expected: บันทึกจำนวน tests, pass/fail/skip, stack trace และแยก failure จาก host ที่ไม่มี native runtime ออกจาก logic failure

---

### Task 4: Review iOS Native Integration

**Files:**

- Inspect: `ios/Podfile`
- Inspect: `ios/Podfile.lock`
- Inspect: `ios/Runner/AppDelegate.swift`
- Inspect: `ios/Runner/Info.plist`
- Inspect: `ios/Runner/PrivacyInfo.xcprivacy`
- Inspect: `ios/Runner/tflite_exported_symbols.txt`
- Inspect: `ios/Runner.xcodeproj/project.pbxproj`
- Inspect: `ios/Flutter/*.xcconfig`

**Interfaces:**

- Consumes: Flutter plugins, CocoaPods, native video-frame channel, TFLite C symbols, ONNX Runtime, privacy descriptions และ iOS build settings
- Produces: iOS compatibility assessment ตั้งแต่ deployment target ถึง runtime/native linking

- [ ] **Step 1: ตรวจ permission และ privacy declarations**

  Verify: camera, photo library, microphone, document/share behavior, Firebase data collection, required-reason APIs และข้อความที่ตรงกับพฤติกรรมจริง

- [ ] **Step 2: ตรวจ TFLite/ONNX native linking**

  Verify: Pod versions, architectures, exported symbols, linker flags, strip settings, release configuration และ minimum iOS version

- [ ] **Step 3: ตรวจ iOS MethodChannel**

  Compare method names, arguments, return schema, error codes, threading, temporary-file cleanup, orientation metadata และ frame selection กับ Dart caller

- [ ] **Step 4: ตรวจ build metadata และ orientation**

  Verify: bundle ID, version/build injection, portrait-only settings, iPad behavior, signing-independent release settings และ duplicate/stale generated configuration files

- [ ] **Step 5: build iOS แบบไม่ codesignและไม่ดาวน์โหลดเพิ่ม**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter build ios --release --no-codesign --no-pub
  ```

  Expected: build สำเร็จ หรือรายงาน failure พร้อมตำแหน่งและจำแนกว่าเป็น source/config/environment

---

### Task 5: Review Android Native Integration

**Files:**

- Inspect: `android/app/src/main/AndroidManifest.xml`
- Inspect: `android/app/src/main/kotlin/com/kdev/sookta/MainActivity.kt`
- Inspect: `android/app/build.gradle`
- Inspect: `android/app/build.gradle.kts`
- Inspect: `android/build.gradle`
- Inspect: `android/build.gradle.kts`
- Inspect: `android/settings.gradle`
- Inspect: `android/settings.gradle.kts`
- Inspect: `android/gradle.properties`
- Inspect: `third_party/onnxruntime_16kb/**`

**Interfaces:**

- Consumes: Flutter plugins, Gradle/AGP/Kotlin config, Android media APIs, TFLite/ONNX native libraries และ manifest permissions
- Produces: Android compatibility assessment รวม 16 KB page-size support, ABI packaging และ release build viability

- [ ] **Step 1: ตรวจ source-of-truth ของ Gradle**

  Verify: Groovy/Kotlin DSL file pairs ใดถูกใช้งานจริง, plugin versions, namespace/application ID, SDK levels, Java/Kotlin targets, signing config, minification และ packaging options

- [ ] **Step 2: ตรวจ permissions และ component declarations**

  Verify: camera, media access by Android version, microphone, exported flags, FileProvider/share, internet/telemetry และ portrait-only behavior

- [ ] **Step 3: ตรวจ Android MethodChannel**

  Compare method names, arguments, return schema, error codes, background execution, lifecycle safety, codec support, rotation metadata, temporary-file cleanup และ parity กับ iOS channel

- [ ] **Step 4: ตรวจ native ML packaging**

  Verify: ABI coverage, `.so` presence, ONNX local override, 16 KB alignment/page-size compatibility, TFLite delegate behavior และ release stripping rules

- [ ] **Step 5: build Android release bundle แบบไม่ดาวน์โหลดเพิ่ม**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter build appbundle --release --no-pub
  ```

  Expected: AAB สำเร็จ หรือรายงาน failure พร้อมตำแหน่งและจำแนกว่าเป็น source/config/environment

---

### Task 6: Run Shared Static Analysis and Regression Tests

**Files:**

- Inspect/Test: `lib/**`
- Inspect/Test: `test/**`
- Inspect/Test: `integration_test/**`
- Inspect: `analysis_options.yaml`

**Interfaces:**

- Consumes: source และ cached dependencies ปัจจุบัน
- Produces: reproducible static-analysis/test results และ coverage-gap list

- [ ] **Step 1: รัน static analysis**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter analyze --no-pub
  ```

  Expected: บันทึกทุก error/warning/info; ไม่ลด severity เพื่อให้ผลดูผ่าน

- [ ] **Step 2: รัน unit/widget test suite ทั้งหมด**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter test --no-pub
  ```

  Expected: บันทึก total/pass/fail/skip และ duration พร้อมชื่อ test ที่ล้ม

- [ ] **Step 3: ตรวจว่าการทดสอบครอบคลุม platform behavior จริงหรือเพียง mock**

  Classify each relevant test as: pure Dart, widget with mocked channel, host-native inference, simulator/emulator integration หรือ physical-device integration

  Expected: รายงานไม่ใช้ mock test เป็นหลักฐานว่า native plugin ทำงานจริง

- [ ] **Step 4: ตรวจ regression risks ที่ tests ยังไม่ครอบคลุม**

  Focus: app resume, repeated model init/dispose, low-memory behavior, image EXIF rotation, front-camera mirroring, video codec variations, permission denied/permanently denied, share cancellation, Thai TTS availability และ offline first launch

---

### Task 7: Execute Platform Runtime Tests on Available Targets

**Files:**

- Test: `integration_test/ml_device_inference_test.dart`
- Test: `integration_test/pose_device_inference_test.dart`
- Test: `integration_test/production_assessment_flow_test.dart`
- Test: `integration_test/evaluation_draft_media_resume_test.dart`
- Test: `integration_test/screenshot_parity_test.dart`

**Interfaces:**

- Consumes: locally available simulators, emulators หรือ connected devices
- Produces: per-target runtime evidence; no target is assumed available before discovery

- [ ] **Step 1: discover local targets**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter devices
  /Users/kpc/develop/flutter/bin/flutter emulators
  xcrun simctl list devices available
  ```

  Expected: รายชื่อ target พร้อม OS/version/architecture และสถานะจริง

- [ ] **Step 2: รัน ML inference test บน Android target ที่มี**

  Run per selected device:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter test integration_test/ml_device_inference_test.dart -d DEVICE_ID --no-pub
  /Users/kpc/develop/flutter/bin/flutter test integration_test/pose_device_inference_test.dart -d DEVICE_ID --no-pub
  ```

  Expected: ONNX และ TFLite native inference ทำงานจริง หรือมี failure ที่ผูกกับ device/ABI/runtime ได้

- [ ] **Step 3: รัน ML inference test บน iOS target ที่มี**

  Run per selected device:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter test integration_test/ml_device_inference_test.dart -d DEVICE_ID --no-pub
  /Users/kpc/develop/flutter/bin/flutter test integration_test/pose_device_inference_test.dart -d DEVICE_ID --no-pub
  ```

  Expected: ONNX และ TFLite native inference ทำงานจริง หรือมี failure ที่ผูกกับ simulator/device/linking ได้

- [ ] **Step 4: รัน production flow และ persistence test บนแต่ละแพลตฟอร์มที่มี**

  Run:

  ```sh
  /Users/kpc/develop/flutter/bin/flutter test integration_test/production_assessment_flow_test.dart -d DEVICE_ID --no-pub
  /Users/kpc/develop/flutter/bin/flutter test integration_test/evaluation_draft_media_resume_test.dart -d DEVICE_ID --no-pub
  ```

  Expected: readiness gate, inference, result navigation, draft/media restore และ local storage ผ่านโดยไม่มี test bypass

- [ ] **Step 5: บันทึกสิ่งที่ต้องทดสอบบนเครื่องจริง**

  Required manual checks: camera capture, gallery picker, four-view real-person media, multi-person rejection, video codec/frame extraction, microphone prompt, Thai/English TTS, background/resume, low-memory return, share sheet/CSV และ offline fresh install

---

### Task 8: Compare iOS and Android and Design the Parity Remediation

**Files:**

- Consume: `docs/reviews/local-platform-ml-review-2026-07-29.md`
- Consume: evidence from Tasks 1–7
- Do not modify production files

**Interfaces:**

- Consumes: capability matrix, code findings, build/test/runtime evidence
- Produces: final parity table และ remediation backlog ที่พร้อมนำไปวาง implementation plan แยกต่างหาก

- [ ] **Step 1: classify every capability**

  Status values:

  - `Shared and verified`
  - `Shared code, iOS verified only`
  - `Shared code, Android verified only`
  - `iOS-specific by design`
  - `Android-specific by design`
  - `Parity defect`
  - `Unverified`

- [ ] **Step 2: rank findings**

  Severity:

  - Critical: crash/data loss/wrong safety result/release unusable
  - High: core flow or one platform materially broken
  - Medium: degraded behavior, fragile fallback, incomplete privacy/permission handling
  - Low: maintainability, duplication, stale config/doc or minor UX mismatch

- [ ] **Step 3: define a concrete fix for each parity defect**

  Each item must include: affected files, root cause, intended shared contract, implementation direction, tests to add, iOS acceptance criteria, Android acceptance criteria และ device requirement

- [ ] **Step 4: state confidence and limits**

  Separate:

  - Confirmed by current code and automated test
  - Confirmed by current platform build
  - Confirmed by simulator/emulator runtime
  - Confirmed by physical device
  - Not verified

---

### Task 9: Self-Review and Deliver the Audit

**Files:**

- Review: `docs/reviews/local-platform-ml-review-2026-07-29.md`
- Review: `docs/superpowers/plans/2026-07-29-local-ios-android-ml-code-review.md`

**Interfaces:**

- Consumes: completed report and evidence
- Produces: concise Thai handoff with clickable report link and prioritized next actions

- [ ] **Step 1: verify every finding has evidence**

  Require: file and line, test/build output หรือ explicit runtime observation; remove unsupported claims

- [ ] **Step 2: verify complete user-request coverage**

  Confirm report answers: source ล่าสุดมีอะไร, ML ทำงานอย่างไร, ใช้งานปกติไหม, shared features, iOS-only, Android-only และวิธีทำ parity

- [ ] **Step 3: scan for ambiguous PASS language**

  Replace any PASS that lacks target/evidence with `unverified`, `code-level only`, `build-only` หรือ `simulator/emulator only`

- [ ] **Step 4: deliver findings-first summary**

  Lead with the highest-severity issues, then platform matrix, ML status, remediation order และ report link
