# ผลแก้ไขและตรวจซ้ำแบบ local: iOS, Android และ ML

วันที่ตรวจ: 29 กรกฎาคม 2026
ขอบเขต: source code และเครื่องมือในเครื่องพัฒนาเท่านั้น
เครือข่าย/บริษัทภายนอก: ไม่ upload source, รูป, model หรือผลประเมิน และไม่ต้องใช้บัญชีบริษัท

เอกสารนี้เป็นผลหลังแก้ไขจาก
[รายงานตรวจฉบับแรก](local-platform-ml-review-2026-07-29.md)
โดยเลือกวิธีที่กระทบ runtime และการตั้งค่า release เดิมน้อยที่สุด

## สรุปผล

- Flutter source analysis ผ่านโดยไม่มี issue
- Flutter test ทั้งหมดผ่าน 162 รายการ
- หลักฐาน baseline ก่อนเชื่อม Recommendation Catalog:
  Android release App Bundle build ผ่านหลังเหลือ Gradle configuration ชุดเดียว
- หลักฐาน baseline ก่อนเชื่อม Recommendation Catalog:
  iOS release แบบ `--no-codesign` build ผ่านจากสำเนาใน `/private/tmp`
- MoveNet TFLite โหลดและ infer ได้ทั้ง Android Emulator และ iOS Simulator
- XGBoost ONNX โหลดและ infer ได้ทั้งสองระบบ และให้ probability เท่ากันสำหรับ input เดียวกัน
- Video frame contract ผ่านทั้งสองระบบโดยไม่ต้องแก้ native algorithm
- Telemetry ปิดเป็นค่าเริ่มต้น และ error event ไม่ส่งข้อความที่อาจมี local path

ยังไม่ควรอธิบายว่า Daily Injury Logistic หรือ XGBoost เป็นโมเดล
ทำนายการบาดเจ็บที่ผ่านการยืนยันทางการแพทย์/งานวิจัยแล้ว
การแก้ครั้งนี้ทำให้ข้อจำกัดนั้นไม่เปลี่ยนคะแนนหลักและแสดงต่อผู้ใช้ตรงตามจริง

## สถานะ ML หลังแก้

| ส่วน | ใช้งานจริง | iOS | Android | สถานะความน่าเชื่อถือ |
|---|---|---:|---:|---|
| REBA/ISO | คะแนนหลักและระดับความเสี่ยง | ผ่าน | ผ่าน | deterministic; shared Dart |
| MoveNet Thunder | อ่าน keypoints จากภาพ | runtime ผ่าน | runtime ผ่าน | on-device; ใช้ letterbox รักษาสัดส่วน |
| MoveNet Multipose | ตรวจว่าภาพมีบุคคลเดียว | runtime/asset ผ่าน | runtime/asset ผ่าน | on-device |
| XGBoost ONNX | สัญญาณประกอบ | ผ่าน | ผ่าน | advisory-only; ไม่แก้ REBA/ISO |
| Daily Injury Logistic | ค่า prototype ภายในและ trend screen | shared Dart | shared Dart | template coefficients; `validatedProbability=null` |
| Legacy posture Logistic | traceability/test | ไม่ package | ไม่ package | ไม่ใช้ production runtime |

ผล device inference ของ XGBoost จาก feature ชุดเดียวกัน:

- Android: neutral `0.8020`, bent `0.8250`
- iOS: neutral `0.8020`, bent `0.8250`

ตัวเลขนี้ยืนยัน runtime parity เท่านั้น ไม่ได้ยืนยัน clinical validity
เพราะชุดฝึก XGBoost ที่มีอยู่ยังไม่ครอบคลุม low/medium labels อย่างเพียงพอ

## สิ่งที่แก้แบบ local

### F1 — Daily Injury Logistic

- อ่านสถานะ `researchTrained` จาก model artifact
- ไม่เปิดเผย probability ต้นแบบเป็นค่าที่ผ่านการฝึกวิจัย
- ใช้ `validatedProbability` ได้เฉพาะเมื่อ artifact ระบุว่า research-trained
- คงคำเตือนจากแนวโน้มจริงของประวัติ repeated high-risk records
  ภายใต้ชื่อ `requiresTrendAttention`
- หน้าจอระบุชัดว่า coefficients ปัจจุบันเป็นต้นแบบ

### F2 — XGBoost เปลี่ยนคะแนนหลัก

- เปลี่ยนเป็น advisory-only
- `userScore`, `riskLevel`, สี และคำแนะนำจาก REBA/ISO ไม่ถูก XGBoost แก้ไข
- ยังคง alert card และ model provenance เพื่อใช้ตรวจสอบ/วิจัย

### F3 — Draft เก่ากับ profile ID

- เมื่อ profile legacy ไม่มี ID ระบบสร้าง ID แล้ว migrate draft ไป key ใหม่ด้วย
- ทดสอบ restore รูป/วิดีโอ draft บน Android ผ่าน

### F4 — ภาพถูกบีบเป็นสี่เหลี่ยม

- ใช้ shared letterbox preprocessor ใน single-pose และ multi-pose service
- รักษา aspect ratio และเติมขอบดำให้ tensor สี่เหลี่ยม
- unit test ครอบคลุมภาพแนวนอนและแนวตั้ง
- MoveNet runtime ผ่านทั้ง Android และ iOS หลังเปลี่ยน

### F5 — รายงาน XGBoost สำเร็จทั้งที่ล้มเหลว

- เพิ่มสถานะ `success`, `unavailable`, `invalidInput`, `runtimeError`
- ข้อความหน้าจอแยก XGBoost สำเร็จออกจาก deterministic fallback
- persist inference state, error code, model version, raw probability
  และ deterministic score เพื่อ audit ย้อนหลัง

### F6 — Telemetry และ local path

- Analytics/Crashlytics collection ปิดเป็นค่าเริ่มต้น
- เปิดเฉพาะ local build ที่กำหนด
  `--dart-define=SOOKTA_TELEMETRY_ENABLED=true`
- เมื่อปิด จะไม่ติดตั้ง fatal error handlers และไม่มี analytics observer
- error telemetry ใช้รหัสหมวด เช่น `file_system_error`
  แทน `error.toString()` ที่อาจมีชื่อไฟล์หรือ path

### F7 — iOS CodeSign ใน Documents/FileProvider

- ไม่เปลี่ยน bundle ID, Podfile หรือ signing
- ยืนยันว่า build/test จากสำเนาใน `/private/tmp` ผ่าน
- แนวทางถาวรที่กระทบน้อยที่สุดคือ clone/worktree ใน local path
  เช่น `/Users/kpc/Developer/fSookta` แล้วใช้ Documents repo เป็นแหล่งอ้างอิง

### F8 — Video parity

- สร้าง H.264 fixture 4 วินาทีจาก AVFoundation ในเครื่อง
- contract ตรวจ duration, 4 timestamps, ขนาดไม่เกิน 720 และ portrait orientation
- ผ่านทั้ง AVFoundation บน iOS และ MediaMetadataRetriever บน Android
- ไม่ต้องแก้ native video implementation

### F9 — Gradle DSL ซ้ำ

- ยืนยัน baseline Android release ก่อนลบ
- ลบเฉพาะ `build.gradle.kts`/`settings.gradle.kts` ที่ไม่ active
- คง Groovy configuration ที่มี Firebase, release signing และ ABI filters
- clean release build หลังลบผ่าน; AGP และ native ABI/library set เท่า baseline

### F10 — integration_test.framework ใน iOS release

- เพิ่ม `tooling/verify_ios_release_artifact.sh` แบบ inspection-only
- release artifact มี framework ขนาดประมาณ 84 KB
- Runner dynamic-link และอ้าง `IntegrationTestPlugin` โดยตรง
- จึงคง framework ไว้ การถอดโดยไม่มีการเปลี่ยน registration
  มีความเสี่ยงต่อ launch crash มากกว่าประโยชน์ด้านขนาด

### F11 — เอกสาร model ไม่ตรง runtime

- README แยก MoveNet, XGBoost advisory-only, Daily Logistic template
  และ Legacy Logistic ที่ไม่ได้ package
- อธิบาย telemetry opt-in และ offline core assessment ตรงกับ source

## ความเหมือนและความต่างระหว่างแพลตฟอร์ม

ฟังก์ชันหลักที่เหมือนกัน:

- workflow, REBA/ISO, recommendation, history, draft และ export เป็น shared Dart
- MoveNet/XGBoost ใช้ artifact และ feature contract ชุดเดียวกัน
- video sampling ใช้ contract เดียวกันและผ่าน fixture เดียวกัน

ส่วน native เฉพาะ iOS:

- AVFoundation สำหรับอ่านวิดีโอ
- TensorFlowLiteC preload และ CocoaPods frameworks
- Xcode signing/entitlements และปัญหา FileProvider metadata ของ path เครื่องพัฒนา

ส่วน native เฉพาะ Android:

- MediaMetadataRetriever สำหรับอ่านวิดีโอ
- Gradle, ABI packaging และ Android signing
- TFLite/ONNX native libraries แยกตาม `armeabi-v7a`, `arm64-v8a`, `x86_64`

ความต่างเหล่านี้เป็น implementation detail; contract ที่ผู้ใช้เห็นผ่านเหมือนกัน
บน simulator/emulator ที่ตรวจ แต่ camera, gallery, TTS, permission และ performance
ยังควรยืนยันบน iPhone/Android เครื่องจริงก่อน release

## สิ่งที่แก้ด้วย local code อย่างเดียวไม่ได้

1. การทำให้ Daily Injury Logistic เป็น research-trained ต้องมี outcome labels,
   participant/session-separated dataset, fit, calibration และ validation จริง
2. การยืนยันว่า XGBoost ใช้ทำนาย low/medium/high/very-high ได้อย่างน่าเชื่อถือ
   ต้องเพิ่ม dataset ที่สมดุลและทำ external validation
3. การส่ง App Store/Play Store ยังต้องใช้บัญชีและ signing credential
   ของเจ้าของแอป แต่ไม่จำเป็นสำหรับ local test และ no-codesign build
4. คุณภาพกล้อง, gallery permission, TTS voice และ latency ต้องตรวจบนเครื่องจริง

## ตรวจ Recommendation Catalog และ platform parity เพิ่มเติม

ตรวจซ้ำวันที่ 30 กรกฎาคม 2026 หลังเชื่อม approved Recommendation Catalog:

- Translation Review ผ่าน approval gate 175/175 แถว หรือ 100%
- Generated Catalog มีข้อความไทย 175 แถวและอังกฤษ 175 แถว
  โดยทุกแถวเป็น atomic display item คู่ภาษาเดียวกัน
- Catalog version คือ `2026-07-29.1` และ checksum คือ
  `b77cf75ade1db152dfdebb82268ad1295d2409f6a2d96ba712b2433ed754abb0`
- focused recommendation/calculation/ML suite ผ่าน 85 tests
  และ full Flutter suite ผ่าน 162 tests
- numeric regression ใช้ fixture REBA heavy-twist และ ISO long-distance
  ก่อนและหลังอ่าน Catalog ได้ผลเท่ากัน:
  REBA user score `9`, risk `veryHigh`, economic loss `32,244` บาท;
  ISO user score `6`, risk `medium`
- parity fixture ไทยและอังกฤษตรวจ iOS/Android viewport แบบ ordered
  structural contract ครบทั้งตำแหน่ง category/item, selection key,
  display-item IDs ที่ผูกกลับจาก item ที่ render จริง, ข้อความคำแนะนำ
  ทุกข้อความ, TTS input ของแต่ละ item และ score field พร้อม label/position
  โดยหน้าคัดเลือกมี score `8` สอง field และหน้าสรุปมี `8 → 4`
  เหมือนกันทั้งสอง platform
- controlled extra-output fixture ยืนยันว่าข้อความ/TTS เพิ่มเติมในโครงสร้าง
  recommendation ถูกเก็บเข้าผลทดสอบและทำให้ exact contract ต่าง
  ไม่ถูกกรองทิ้งด้วย expected-value whitelist
- Android debug build ผ่านที่
  `build/app/outputs/flutter-apk/app-debug.apk`
- iOS simulator debug build จาก worktree ใน `Documents` compile จบ
  แต่ CodeSign ถูกขัดขวางโดย `com.apple.fileprovider.fpfs#P`/FinderInfo
  ตามข้อจำกัด F7 เดิม ไม่ใช่ source หรือ Catalog error
- สำเนา source เดียวกันที่ไม่มี `.git`, `.superpowers`, `build`
  และ generated caches ที่ไม่จำเป็นใน
  `/private/tmp/sookta-task8-ios.mrjP0g`
  ผ่านคำสั่ง iOS เดียวกัน และสร้าง
  `/private/tmp/sookta-task8-ios.mrjP0g/build/ios/iphonesimulator/Runner.app`

Source/model integrity gate ยังคงตรวจ hash แบบ strict สำหรับเอกสารผู้ว่าจ้าง
และ ML artifacts ทุกไฟล์ ส่วน `current_app_recommendation_copy`
เป็น legacy migration snapshot ที่ตั้ง policy
`legacy_baseline_snapshot` อย่างชัดเจน:

- original baseline:
  `a112ff7a1fec833cf9312a91db263bb13d7c5989ebfa1fb13deac8d908952bfe`
- current post-Catalog source:
  `d3c57a6bc57698dada8a5782ea2c2a5c7ba6cc2e26014e82f06793749f4862c5`

validator รายงาน drift นี้เป็นข้อมูล audit แต่ไม่ทำให้ gate ล้ม
เฉพาะเมื่อ `id`, `documentRole`, `hashPolicy` และ normalized repo-relative
`localPath` ตรงกับ `lib/core/localization/sookta_strings.dart` ทุกเงื่อนไข
test ยืนยันว่า arbitrary path, authoritative recommendation path,
absolute path, source อื่นที่ hash ไม่ตรง หรือ source อื่นที่พยายามใช้
policy นี้ยัง fail เสมอ
ผล `source_registry=PASS` และ `model_baseline=PASS`
โดย model hashes ทั้งห้าตรง baseline:

| Artifact | SHA-256 |
|---|---|
| `assets/models/xgboost_model.onnx` | `dbedb2ab5ce57f3af0cd620e956f30ef34a64beaea493385afd3d27994002efc` |
| `assets/models/xgboost_model_metadata.json` | `89db0df19fc6a4041a62fcd01e1155a288a19f243ed6908df5fdb03d9cbcb922` |
| `assets/ml/daily_injury_logistic_model.json` | `c444a8e68ae59fc6e7c34315aa8f725b9d9c50112b01483852a5d3b3ef268a75` |
| `assets/ml/movenet_thunder.tflite` | `8014d8fe22285265f52aa1cea84056b7704f75adf12341a7712d4cb28bd1d9b6` |
| `assets/ml/movenet_multipose_lightning.tflite` | `d4489f89e6bd6777a8b9a1a16189832131f84ff90d82fae729e670b84d7948dd` |

การตรวจรอบนี้ **ไม่มีการ train หรือ retrain ML ใด ๆ** และไม่ได้เปลี่ยน
model artifact, feature schema, สูตร REBA/ISO, selection/effect logic,
research export schema หรือ native iOS/Android source

## หลักฐานการตรวจรอบสุดท้าย

- `flutter analyze --no-pub`: ผ่าน, no issues
- `flutter test --no-pub`: ผ่าน 162 tests
- focused Task 8 Flutter suite: ผ่าน 85 tests
- recommendation approval gate: ผ่าน 175/175 (100%)
- source registry และ model baseline: ผ่าน พร้อม informational legacy drift
- Android `flutter build apk --debug --no-pub`: ผ่าน
- iOS `flutter build ios --simulator --debug --no-pub`:
  worktree ติด FileProvider CodeSign; clean local `/private/tmp` copy ผ่าน
- Android `flutter build appbundle --release --no-pub`:
  ผ่านใน baseline ก่อนเชื่อม Catalog เท่านั้น ไม่ใช่ final build ของ source ปัจจุบัน
- iOS `flutter build ios --release --no-codesign --no-pub`:
  ผ่านใน `/private/tmp` สำหรับ baseline ก่อนเชื่อม Catalog เท่านั้น
  ไม่ใช่ final build ของ source ปัจจุบัน
- Android/iOS `pose_device_inference_test.dart`: ผ่าน
- Android/iOS `ml_device_inference_test.dart`: ผ่านและค่าเท่ากัน
- Android/iOS `video_frame_contract_test.dart`: ผ่าน
- Android draft media resume integration: ผ่าน
- `git diff --check`: ผ่าน

ไม่มีการ push หรือ upload ไฟล์ใดออกจากเครื่อง
