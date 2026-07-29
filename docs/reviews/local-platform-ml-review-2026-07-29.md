# รายงานตรวจ Source Code, ML และความเท่าเทียม iOS/Android (Local Audit)

> สถานะ: เอกสารนี้บันทึก finding ก่อนแก้ไขเพื่อเก็บ audit trail
> ผลหลังแก้และตรวจซ้ำอยู่ที่
> [local-platform-ml-remediation-result-2026-07-29.md](local-platform-ml-remediation-result-2026-07-29.md)

วันที่ตรวจ: 29 กรกฎาคม 2026
โครงการ: Sookta `1.3.7+24`
Branch/commit: `codex/ios-real-integrations` / `516cc880c1cb04d73a90dc92d4e21ae98d86710a`

## บทสรุปสำหรับการตัดสินใจ

ตัวแอปหลักใช้ Flutter ร่วมกันเกือบทั้งหมด จึงไม่มี feature หลักใดที่ตั้งใจให้ใช้ได้เพียง iOS หรือ Android ระบบ build แบบ release ผ่านทั้งสองแพลตฟอร์ม และยืนยันบน local runtime แล้วว่า ONNX/XGBoost และ TFLite/MoveNet โหลดและ infer ได้ทั้ง Android Emulator และ iOS Simulator

อย่างไรก็ตาม ยังไม่ควรสรุปว่า “ML พร้อมใช้เป็นโมเดลทำนายเชิงวิจัย/สุขภาพ” แม้ runtime จะทำงาน เพราะพบปัญหาด้านความถูกต้องของโมเดลสำคัญสองรายการ:

1. XGBoost ถูกฝึกด้วยข้อมูลที่มีเฉพาะ `high` และ `veryHigh` แต่สามารถยกระดับคะแนน REBA จริงในแอปได้
2. Daily Injury Logistic Regression ที่หน้าจอ production ใช้อยู่ระบุเองว่าเป็น template coefficients และยังไม่มี outcome labels สำหรับ fit โมเดล

ดังนั้นสถานะที่เหมาะสมคือ:

- Core application และ deterministic REBA/ISO: ใช้งานและทดสอบได้ดี
- ML runtime บน iOS/Android: ใช้งานได้
- ML scientific validity: ยังเป็น research prototype ไม่ควรใช้เป็นข้อสรุปทางคลินิกหรือให้แก้คะแนนหลักจนกว่าจะ validate เพิ่ม
- Platform parity: โครงสร้างดีและผล ONNX เท่ากัน แต่ยังต้องทดสอบกล้อง/วิดีโอ/TTS บนเครื่องจริงทั้งสองระบบก่อน release

## ขอบเขตและวิธีตรวจ

การตรวจทั้งหมดทำแบบ local โดยไม่ส่ง source code ไปยังบริการภายนอก และไม่ต้องใช้บัญชีบริษัท:

- อ่าน source, native configuration, assets และ dependency metadata
- Flutter static analysis
- Unit/widget tests ทั้งชุด
- ML-focused tests
- Release build สำหรับ iOS และ Android
- ตรวจ native binaries และ Android 16 KB page alignment
- Integration tests บน Android Emulator API 35
- Integration tests บน iOS Simulator 26.5
- ตรวจความเหมือนของ native video channel และ platform-specific code

ข้อจำกัด:

- ไม่มี iPhone จริงเชื่อมต่อในรอบตรวจนี้
- ไม่ได้ทดสอบกล้องจริง, microphone, gallery permission และ codec วิดีโอจากอุปกรณ์จริง
- iOS Simulator build จากโฟลเดอร์ Documents เดิมติด FileProvider metadata/code signing จึงยืนยัน ML จากสำเนา local ใน `/private/tmp`

## ผลการทดสอบที่ยืนยันแล้ว

| รายการ | ผล |
|---|---|
| `flutter analyze --no-pub` | ผ่าน, 0 issues |
| Flutter unit/widget tests | ผ่าน 120/120 |
| ML-focused tests | ผ่าน 51/51 |
| iOS release build แบบ no-codesign | ผ่าน, `Runner.app` 100.6 MB |
| Android release AAB | ผ่าน, 149.6 MB |
| Android ONNX inference | ผ่าน: neutral `0.8020`, bent `0.8250` |
| iOS ONNX inference | ผ่าน: neutral `0.8020`, bent `0.8250` |
| Android TFLite/MoveNet runtime | ผ่าน |
| iOS TFLite/MoveNet runtime | ผ่าน |
| Android production assessment flow | ผ่าน |
| Android draft + saved media resume | ไม่ผ่านอย่างสม่ำเสมอ; พบ root cause แล้ว |
| Android native library alignment | ONNX/TFLite 16 KB compatible |

ผล ONNX บน iOS และ Android เท่ากันทุกหลักที่ integration test แสดง จึงถือว่า predictor/runtime parity ผ่านสำหรับ fixed vectors ชุดปัจจุบัน

## Findings เรียงตามความสำคัญ

### [สูง] F1 — Daily Injury Logistic Regression ใช้ template coefficients ใน production

หลักฐาน:

- `assets/ml/daily_injury_logistic_model.json` ระบุ source ว่า `template_coefficients_pending_research_msd_symptom_labels`
- ระบุว่าต้อง fit coefficients ด้วย labeled outcome data
- `trainingStatus.researchTrained` เป็น `false` แต่ `readyForAppUse` เป็น `true`
- `DailyInjuryPredictionService` ถูกเรียกจากหน้าจอ production ได้แก่ daily prediction, risk-reduction potential และ final result

ผลกระทบ:

- ตัวเลข probability มีลักษณะเหมือนผลจากโมเดลที่ train แล้ว ทั้งที่ coefficients ยังเป็นค่าต้นแบบ
- เสี่ยงต่อการตีความเป็น “ความน่าจะเป็นการบาดเจ็บ” จริง
- iOS และ Android ให้ผลเหมือนกัน แต่เป็นความเหมือนของโมเดลที่ยังไม่ผ่าน validation

ข้อเสนอ:

1. จนกว่าจะมี CMDQ/research follow-up labels ให้เปลี่ยน UI เป็น “rule-based research indicator” และไม่แสดงเป็น injury probability
2. ตั้ง `readyForAppUse=false` หรือใช้ feature flag เฉพาะ research mode
3. Fit ด้วย maximum likelihood บน outcome labels จริง แยก train/validation ตามผู้เข้าร่วม ไม่ใช่สุ่มแถว
4. บันทึก calibration, AUC/PR-AUC, sensitivity/specificity, Brier score และ confidence interval

### [สูง] F2 — XGBoost เปลี่ยนคะแนนหลักได้ แต่ชุด train ไม่มี low/medium

หลักฐาน:

- [xgboost_model_metadata.json](../../assets/models/xgboost_model_metadata.json) มี 388 samples แบ่งเป็น `high=236`, `veryHigh=152` เท่านั้น
- `calibrationMatchedSampleCount=0`
- holdout risk accuracy เท่ากับ `0.6667`
- manifest ระบุเองว่าต้องเก็บ low/medium media เพิ่ม และยังไม่ใช่ clinical validation
- [`_applyXGBoostGuardrail`](../../lib/screens/main/evaluation_form_screen.dart) สามารถยกคะแนนเป็นอย่างน้อย 4/7/9 ตามระดับจากโมเดล
- fixed vectors ที่ต่างกันระหว่าง neutral และ bent ให้ `0.8020` กับ `0.8250` ต่างกันเพียง `0.023`

ผลกระทบ:

- โมเดลยังไม่เรียนรู้ขอบเขต low/medium จากข้อมูลจริง แต่สามารถยกระดับ deterministic REBA/ISO ได้
- มีโอกาสเกิด false positive และบิดเบือนข้อมูลวิจัย/คะแนนก่อนปรับปรุง
- guardrail ไม่ลดคะแนน จึงลดความเสี่ยงด้าน false negative บางส่วน แต่ไม่ได้ทำให้โมเดล valid

ข้อเสนอ:

1. ให้ XGBoost เป็น advisory-only ก่อน ไม่ให้แก้ `userScore` หรือ `riskLevel`
2. เก็บข้อมูลครบทุกระดับโดยเฉพาะ low/medium และแยก validation ตามคน/session
3. เพิ่ม fixed, expert-labeled fixtures ที่ตรวจ expected class และ expected separation ไม่ใช่เพียงตรวจค่าอยู่ในช่วง 0–1
4. ทำ calibration และกำหนด acceptance criteria เดียวกันบน iOS/Android

### [สูง] F3 — แบบร่างพร้อม media หายหลัง restore เพราะ profile migration

Integration test `evaluation_draft_media_resume_test.dart` ไม่ผ่านซ้ำสองครั้งบน Android

Root cause:

1. แบบร่างถูกบันทึกขณะ `profileId` ยังว่าง จึงใช้ key `no-profile`
2. ระหว่าง restore, [`_ensureProfileId`](../../lib/app/app_state.dart) สร้าง profile ID ใหม่ให้ legacy profile
3. [`evaluationDraftForProfile`](../../lib/app/app_state.dart) ต้องการให้ draft profile ID ตรงกับ profile ใหม่
4. draft เดิมจึงยังอยู่ใน storage แต่ lookup ไม่พบ และหน้าแบบฟอร์มไม่แสดงว่า restore สำเร็จ

ผลกระทบ:

- ผู้ใช้ที่บันทึกแบบร่างก่อน profile migration อาจมองไม่เห็นแบบร่างและรูปเดิม
- เป็น shared Dart code จึงมีผลได้ทั้ง iOS และ Android แม้พบจาก Android test

ข้อเสนอ:

- ขณะสร้าง profile ID ใหม่ ให้ migrate drafts/history ที่ profile ID ว่างไปยัง ID ใหม่ใน transaction เดียว
- เพิ่ม restore test ที่สร้าง state ใหม่จริงทั้ง iOS และ Android
- อย่า catch exception ใน restore โดยไม่บันทึกสาเหตุ

### [กลาง] F4 — MoveNet บิดสัดส่วนภาพ non-square ก่อนหา pose

[`PoseEstimationService`](../../lib/core/services/pose_estimation_service.dart) ใช้ `copyResize` บังคับภาพทุกภาพเป็น `256x256` โดยไม่ letterbox/pad และไม่ remap coordinates กลับตามสัดส่วนเดิม

ผลกระทบ:

- ภาพแนวตั้งจากกล้องจะถูกบีบด้านกว้าง
- มุมลำตัว/แขน/ขาที่ใช้สร้าง REBA และ XGBoost features อาจคลาดเคลื่อน
- มีผลเหมือนกันทั้ง iOS และ Android จึงไม่ใช่ parity bug แต่เป็น accuracy bug

ข้อเสนอ:

- ใช้ aspect-ratio-preserving letterbox ใน shared Dart preprocessing
- remap keypoints จาก input tensor กลับสู่ original image coordinates
- เพิ่ม golden tensor/keypoint tests ด้วยภาพ portrait, landscape และ rotated media

### [กลาง] F5 — สถานะ XGBoost อาจรายงานว่าสำเร็จทั้งที่ inference ล้มเหลว

- [`_predictXGBoostAlert`](../../lib/screens/main/evaluation_form_screen.dart) catch ทุก error แล้วคืน `null` โดยไม่มีสถานะสาเหตุ
- ข้อความสำเร็จสำหรับภาพนิ่งบอกว่า “ตรวจเทียบด้วย XGBoost แล้ว” โดยไม่ได้ตรวจว่า `xgbAlert` ไม่เป็น `null`

ผลกระทบ:

- ผู้ใช้และทีมวิจัยแยกไม่ได้ว่าผลผ่าน XGBoost จริงหรือ fallback ไป deterministic REBA
- audit/reproducibility อ่อนลง

ข้อเสนอ:

- แยกสถานะ `success / unavailable / invalidInput / runtimeError`
- แสดง “REBA สำเร็จ แต่ XGBoost ไม่พร้อม” เมื่อ predictor เป็น `null`
- persist `modelVersion`, raw probability, deterministic score ก่อน guardrail และ inference status

### [กลาง] F6 — Telemetry เปิดอัตโนมัติและ error text อาจมี local path

[`FirebaseTelemetryService.initialize`](../../lib/core/services/firebase_telemetry_service.dart) เปิด Analytics และ Crashlytics collection ทันทีเมื่อ Firebase พร้อม โดยไม่มี opt-in ในโค้ด และ event `pose_analysis_failed` ส่ง `e.toString()` ซึ่งอาจมีชื่อไฟล์หรือ local path

ผลกระทบ:

- แอปอธิบายว่า offline-first แต่ยังมี network telemetry
- source code ไม่ถูกส่ง แต่ข้อมูลกิจกรรม/คะแนน/ความเสี่ยงและข้อความ error ถูกส่งเมื่อออนไลน์

ข้อเสนอ:

- เพิ่ม consent/setting และอธิบายใน privacy notice
- sanitize error เป็น error code; ไม่ส่ง raw path/filename
- แยก “core assessment works offline” ออกจาก “optional telemetry uses internet” ใน README/UI

### [กลาง] F7 — iOS build/test จาก Documents มี FileProvider code-signing blocker

- iOS release แบบ `--no-codesign` build ผ่าน
- Simulator integration build ในโฟลเดอร์เดิมล้มด้วย macOS metadata/code signing
- เมื่อคัดลอกไป `/private/tmp` ทั้ง ONNX และ TFLite tests ผ่าน
- Podfile เพิ่ม metadata-stripping phase ให้หลาย targets และเกิด warning ว่ารันทุก build

สรุป: ไม่ใช่ runtime defect ของ iOS ML แต่เป็น build-path/reliability problem

ข้อเสนอ:

- ใช้ workspace ที่ไม่อยู่ใต้ FileProvider/cloud sync สำหรับ iOS CI/release
- กำหนด derived/build directory ใน local non-FileProvider path
- ลด scripts stripping ให้เหลือจุดเดียวที่มี inputs/outputs ชัดเจน

### [กลาง] F8 — Native video extractor มี contract เหมือนกัน แต่ output อาจต่างกัน

ทั้งสองฝั่งใช้ channel `sookta/video_frames`, methods และ response schema เดียวกัน:

- iOS: [`AVAssetImageGenerator`](../../ios/Runner/AppDelegate.swift), preferred transform, tolerance ±0.25 วินาที, max 720
- Android: [`MediaMetadataRetriever`](../../android/app/src/main/kotlin/com/kdev/sookta/MainActivity.kt), closest sync frame, scaled 720x720 เฉพาะ API 27+

ความต่างที่ควรตรวจ:

- frame timestamp ที่ได้จริงและ keyframe selection
- orientation/rotation
- Android ก่อน API 27 ไม่ resize
- codec/variable-frame-rate behavior

ข้อเสนอ:

- ใช้วิดีโอ fixtures เดียวกันและเปรียบเทียบ frame count, timestamps, dimensions, orientation และ pose outputs ด้วย tolerance ที่กำหนด
- ทดสอบ API 26, 35 และ iOS รุ่นต่ำสุด/ล่าสุดบนเครื่องจริง

### [ต่ำ] F9 — มีไฟล์ Gradle Groovy และ Kotlin DSL ซ้ำกัน

มีทั้ง `.gradle` และ `.gradle.kts` ใน root/app/settings โดย Groovy เป็นชุดที่ใช้งานจริงและมี Firebase/signing/ABI config มากกว่า Kotlin DSL

ผลกระทบ: ผู้ดูแลอาจแก้ผิดไฟล์และคิดว่าค่าถูกใช้งานแล้ว

ข้อเสนอ: เลือก DSL เดียวและลบหรือ archive ชุดที่ไม่ใช้งาน

### [ต่ำ] F10 — `integration_test.framework` อยู่ใน iOS release artifact

พบ `integration_test.framework` ใน `build/ios/iphoneos/Runner.app/Frameworks` แม้เป็น dev dependency

ผลกระทบ: เพิ่มขนาดและเพิ่ม test-only code ใน production artifact โดยไม่จำเป็น

ข้อเสนอ: แยก test target/configuration หรือ exclude integration test plugin จาก archive/release

### [ต่ำ] F11 — README ทำให้เข้าใจผิดเรื่อง Logistic Regression รุ่นเก่า

README ระบุ `assets/models/logistic_weights.json` เป็นโมเดลของแอปและบอก Logistic/XGBoost ใช้สำหรับ A/B testing แต่ไฟล์นั้นไม่ได้อยู่ใน `pubspec` และ manifest ระบุว่าเก็บเพื่อ traceability เท่านั้น

ข้อเสนอ: แยกเอกสารให้ชัดระหว่าง:

- Legacy posture logistic: ไม่ package/ไม่ใช้งาน
- Daily injury logistic: package และถูกเรียกจริง แต่ยังเป็น template ไม่ research-trained
- XGBoost ONNX: runtime production guardrail แต่ scientific validation ยังไม่พอ

## สถานะ ML แต่ละส่วน

| ML/วิธีคำนวณ | ใช้ตรงไหน | iOS | Android | ความพร้อมเชิงวิทยาศาสตร์ |
|---|---|---|---|---|
| Deterministic REBA/ISO 11228 | คะแนนหลัก | shared/ผ่าน tests | shared/ผ่าน tests | เป็นฐานที่ควรใช้ต่อ |
| MoveNet Thunder TFLite | single-person pose | runtime ผ่าน | runtime ผ่าน | ต้องแก้ aspect ratio และ validate keypoints |
| MoveNet MultiPose Lightning | ตรวจหลายคนในภาพ | package/shared code | package/shared code | unit logic ผ่าน; ต้อง device fixture test |
| XGBoost ONNX | guardrail ยกระดับคะแนน | runtime ผ่าน | runtime ผ่าน | ยังไม่ควรแก้คะแนนหลัก |
| Legacy posture Logistic | test/traceability | ไม่ package | ไม่ package | ไม่ใช้ production |
| Daily Injury Logistic | daily/final/risk reduction screens | shared Dart | shared Dart | template coefficients; ยังไม่ research-trained |

## ส่วนที่ใช้ได้ทั้ง iOS และ Android

- Onboarding, ภาษาไทย/อังกฤษ, profile/farmer management
- แบบฟอร์มกิจกรรมและ deterministic REBA/ISO
- ประวัติ, before/after, economic impact, export/share
- กล้อง/แกลเลอรีผ่าน Flutter plugins
- TTS (เสียงจริงขึ้นกับ voice ของ OS)
- MoveNet single-person/multi-person
- XGBoost ONNX
- Daily prediction service
- Firebase Analytics/Crashlytics
- วิดีโอไม่เกิน 20 วินาทีและดึงภาพสูงสุด 8 frames ผ่าน native adapter

## ส่วนเฉพาะแพลตฟอร์ม

ไม่มี business feature หลักที่เป็น iOS-only หรือ Android-only แต่มี implementation เฉพาะระบบ:

### iOS-only implementation

- AVAssetImageGenerator สำหรับดึง video frames
- TensorFlow Lite symbol preload ด้วย `dlopen`
- AVAudioSession/TTS category
- Info.plist permissions สำหรับ camera/photo/microphone
- CocoaPods และ Xcode code-signing

### Android-only implementation

- MediaMetadataRetriever สำหรับดึง video frames
- local ONNX Android package รุ่น 16 KB compatible
- ABI packaging สำหรับ `arm64-v8a`, `armeabi-v7a`, `x86_64`
- Android TTS queue/audio navigation attributes
- Gradle/Firebase plugins และ signing config

ความต่างเหล่านี้เป็น adapter ที่จำเป็นตาม OS ไม่ได้แปลว่าผู้ใช้ได้รับ feature ต่างกัน แต่ต้องมี contract tests เพื่อคุมผลลัพธ์ให้ใกล้กัน

## Roadmap เพื่อให้ทำงานเหมือนกันทั้ง iOS และ Android

### Phase 0 — ก่อนใช้ผล ML เป็นคะแนนจริง

1. ปิด score-changing XGBoost guardrail หรือเปลี่ยนเป็น advisory-only
2. เปลี่ยน Daily Injury Logistic เป็น research indicator จนกว่าจะ fit coefficients จริง
3. แสดง/persist model status, version, raw probability และ deterministic score
4. แก้ draft/profile migration และเพิ่ม regression test

เกณฑ์ผ่าน:

- การล้มของ ML ไม่เปลี่ยนหรือทำให้ deterministic REBA/ISO หาย
- ผู้ใช้เห็นชัดว่าโมเดลทำงานหรือ fallback
- แบบร่างเก่าที่ไม่มี profile ID ถูก migrate และเปิดได้

### Phase 1 — ML accuracy และ parity

1. ทำ letterbox preprocessing ร่วมใน Dart
2. สร้าง expert-labeled fixtures ครบ low/medium/high/veryHigh
3. ทดสอบ tensor, keypoints, XGBoost probability และ final score บนทั้งสอง OS
4. Fit/calibrate โมเดลจาก participant/session-separated data

เกณฑ์ผ่าน:

- fixed input ให้ tensor/keypoints เท่ากันภายใน tolerance
- iOS/Android probability ต่างกันไม่เกิน tolerance ที่กำหนด
- confusion matrix ครบทุก risk class
- calibration metrics และ external/holdout validation ผ่านเกณฑ์วิจัยที่ตกลง

### Phase 2 — Native device parity

1. ทดสอบ iPhone จริงและ Android จริงอย่างน้อยอย่างละ 2 รุ่น
2. ทดสอบกล้อง, gallery permission, วิดีโอ portrait/landscape/VFR, TTS ไทย และ low-memory
3. เปรียบเทียบ native extracted frames จาก fixture เดียวกัน
4. ย้าย iOS release workspace ออกจาก FileProvider

### Phase 3 — Build/privacy hygiene

1. ลบ Gradle DSL ที่ไม่ใช้งาน
2. ตัด `integration_test.framework` จาก release
3. เพิ่ม telemetry consent และ sanitize errors
4. ปรับ README/model cards ให้ตรงสถานะจริง

## ข้อสรุปการปล่อยใช้งาน

สามารถเดินหน้าพัฒนาและทดสอบตัวแอปทั้ง iOS/Android ได้โดยใช้ account ส่วนบุคคลและเครื่อง local ไม่ต้องติดต่อบริษัทภายนอกสำหรับการ review นี้

ก่อนปล่อยเป็น research prototype:

- ควรแก้ F1–F3
- ยืนยันกล้อง/วิดีโอ/TTS บนเครื่องจริง
- ทำ privacy disclosure สำหรับ Firebase

ก่อนอ้างว่าเป็น validated injury/risk prediction:

- ต้องมี outcome labels และ expert labels ที่ครบทุกระดับ
- ต้อง train/calibrate/validate ใหม่
- ต้องเก็บ model provenance และผลก่อน/หลัง ML guardrail เพื่อให้ audit ซ้ำได้
