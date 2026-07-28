# ข้อกำหนดทางเทคนิค Sookta Application Version 2.1.0

## Document Control

| รายการ | ค่า |
|---|---|
| ชื่อเอกสาร | ข้อกำหนดทางเทคนิค Sookta Application |
| Release/Document Version | Sookta Application 2.1.0 |
| เอกสารฉบับ | Technical Specification |
| Source Branch | `codex/ios-real-integrations` |
| Application Source Snapshot | `08e436665db617ff4e42e26cfc914549ed7d9eb5` |
| Documentation Baseline | `42533f809714ab50cce84973b210af946249ac6e` |
| Internal Version จาก source snapshot | `1.3.7+24` |
| วันที่จัดทำ | 28 กรกฎาคม 2026 |
| ภาษา | ภาษาไทยเป็นหลัก ใช้ภาษาอังกฤษสำหรับ identifier, schema, formula และชื่อมาตรฐาน |
| สถานะ | Controlled technical specification สำหรับ release 2.1.0 |

> **การควบคุมเวอร์ชัน:** ชื่อ release ของเอกสารนี้คือ 2.1.0 ตามเวอร์ชันที่
> กำหนดสำหรับ Store ส่วน `1.3.7+24` คือค่าใน `pubspec.yaml` ณ application
> source snapshot ที่ใช้ตรวจสอบ เอกสารนี้ไม่ได้เปลี่ยน application source,
> version หรือ build artifact

## 1. Purpose, Scope and System Boundaries

### 1.1 วัตถุประสงค์

เอกสารนี้กำหนดโครงสร้าง สัญญาข้อมูล ลำดับประมวลผล สูตรคำนวณ model
contract การจัดเก็บ การส่งออก การตั้งค่า platform และหลักฐานทดสอบของ Sookta
Application 2.1.0 เพื่อให้ตรวจสอบ implementation และแยกส่วนที่อ้างอิง
guideline ออกจากส่วนที่เป็น application adaptation หรือ research template
ได้อย่างชัดเจน

### 1.2 ขอบเขตระบบ

ขอบเขตในเอกสารครอบคลุม Flutter application บน iOS และ Android ตั้งแต่
startup, onboarding, farmer profile, media ingestion, pose estimation,
REBA/ISO-style screening, recommendation, economic impact, history, daily
trend, export, local persistence, Firebase telemetry และ native platform
configuration

ขอบเขตไม่รวม backend กลาง การวินิจฉัยทางการแพทย์ การรับรองมาตรฐาน ISO
การแทนผู้ประเมินการยศาสตร์ที่มีคุณสมบัติ การสอบเทียบโมเดลกับประชากรภาคสนาม
และกระบวนการเผยแพร่ Store ที่อยู่นอก source snapshot

### 1.3 นิยามสถานะและสัญญาหลัก

| คำศัพท์ | นิยามทางเทคนิค |
|---|---|
| Production path | เส้นทางที่ผู้ใช้ release ใช้งานจริง ตั้งแต่ media readiness gate ถึงผลและ history โดยไม่มี temporary UAT bypass |
| Fallback | ผลลัพธ์หรือเส้นทางสำรองเมื่อ optional service/model ใช้งานไม่ได้ โดยต้องไม่ทำให้ผลหลักมีความเสี่ยงต่ำลงอย่างไม่สมเหตุผล |
| Readiness gate | validation ที่ต้องผ่านก่อนเรียก assessment เช่น จำนวน media, ความพร้อมของ pose และ single-person condition |
| Draft key | composite identity ที่ผูกแบบร่างกับเกษตรกรและกิจกรรม เพื่อป้องกันข้อมูลข้ามบุคคลหรือข้ามงาน |
| Assessment bundle | object ที่รวม input, REBA, ISO-style result, frame analysis, motion summary และ metadata สำหรับส่งต่อหน้าผล |
| History record | transaction ที่บันทึกผลก่อนปรับ ผลหลังจำลองลดความเสี่ยง คำแนะนำ เกษตรกร กิจกรรม และเวลาสร้าง |
| Model asset contract | ข้อตกลงระหว่างไฟล์โมเดล schema การเรียง feature tensor shape output และ threshold ที่ runtime ต้องตรวจให้ตรงกัน |
| Traceability status | สถานะว่า implementation ตรงตามแหล่งอ้างอิง เป็น Sookta adaptation, research template, deprecated หรือยังขาด UAT |

### 1.4 ลำดับความน่าเชื่อถือของหลักฐาน

1. application source และ native configuration ที่ทำงานจริง
2. model asset, schema และ metadata ที่ package มากับ application
3. automated test และผล UAT ที่อ้างถึง source snapshot
4. requirement/design record ที่ได้รับการยืนยัน
5. guideline และแหล่งอ้างอิงภายนอก

## 2. System Context and Architecture

<!-- DOCX_DIAGRAM:system-context -->

### 2.1 Actors และ external boundaries

| Actor/ระบบ | Input | Output/ผลกระทบ | Boundary |
|---|---|---|---|
| เกษตรกร/เจ้าหน้าที่ภาคสนาม | profile, activity, media, task parameters, action selection | screening result, recommendation, history, export | ผู้ใช้ควบคุม input และการ share |
| คณะวิจัย | participant code, export, expert/outcome label | dataset สำหรับวิเคราะห์ภายนอก | ไม่มี backend research pipeline ใน app |
| iOS/Android | camera/gallery, file sandbox, native video frame channel, share sheet | media/file access และ lifecycle | permission และ storage policy ของ OS |
| Firebase | app-open/event/crash diagnostics เมื่อเริ่มได้ | telemetry ภายนอกเครื่อง | optional; app ทำงานต่อเมื่อ initialize ไม่สำเร็จ |
| Model assets | MoveNet, ONNX, feature schema, logistic JSON | pose/features/risk guardrail | package ภายใน application |

Application เป็น offline-first mobile client ไม่มี server-side source of truth
ข้อมูลการใช้งานหลักจึงมี authoritative copy อยู่ใน application sandbox ของ
อุปกรณ์ ส่วนไฟล์ export จะออกนอก sandbox เมื่อผู้ใช้เลือกปลายทางใน share sheet

### 2.2 Runtime containers

`main.dart` เตรียม Flutter binding ล็อก orientation และเรียก Firebase แบบ
fail-safe ก่อนสร้าง `SooktaApp` ภายใน `SooktaApp` มี `SooktaAppState` เพียง
instance เดียวและเผยแพร่ผ่าน `AppStateScope` ซึ่งเป็น `InheritedNotifier`
หน้าจออ่าน/แก้ state ผ่าน scope นี้ ส่วน service เป็น stateless/static หรือมี
instance เฉพาะ pipeline ตามความเหมาะสม

เส้นแบ่งความรับผิดชอบ:

- UI รับ input แสดง validation และควบคุม navigation
- `SooktaAppState` เป็น transaction coordinator ของ profile, farmer, draft,
  history และ persistence
- model/domain classes กำหนด serialization contract
- core services คำนวณ วิเคราะห์ media แนะนำ ส่งออก และบันทึก telemetry
- native layer จัด permission, orientation, camera/gallery และ video frame
- assets กำหนด schema/weights/model ที่ต้องสอดคล้องกับ runtime

### 2.3 Trust และ failure boundary

ผลหลักต้องยังคำนวณได้เมื่อ Firebase ใช้งานไม่ได้ ส่วน ML guardrail ต้องไม่ลด
ระดับผลจากสูตรหลัก ถ้า model/schema initialize ไม่สำเร็จให้ใช้ formula result
พร้อม error/diagnostic ที่เหมาะสม การ parse local state ที่เสียหายจะ reset
runtime state เป็นค่าเริ่มต้นที่ปลอดภัย แต่ backup ก่อน migration ยังอยู่ใน
`SharedPreferences`

## 3. Flutter Module and Dependency Structure

<!-- DOCX_DIAGRAM:module-dependency -->

### 3.1 Module catalogue

| Module | หน้าที่ | Dependency หลัก |
|---|---|---|
| `lib/main.dart` | bootstrap, orientation, Firebase error capture | Flutter, Firebase, `SooktaApp` |
| `lib/app/` | app composition, state, text/build metadata | screens, models, persistence |
| `lib/screens/onboarding/` | Splash, Language, Setup, Avatar | `SooktaAppState`, image/camera |
| `lib/screens/main/` | tabs, assessment, result, history, help/export | services, models, widgets |
| `lib/core/models/` | immutable DTO/domain/serialization | enum และ primitive types |
| `lib/core/services/` | calculation, media, recommendation, export, telemetry | models, assets, platform plugins |
| `lib/core/ergonomics_risk_prediction/` | feature schema, predictors, guardrail | ONNX Runtime, asset loader |
| `lib/widgets/` | reusable presentation และ accessibility behavior | theme, localization |
| `ios/`, `android/` | permissions, orientation, native build/channel | Flutter embedding และ SDK |
| `assets/models/`, `assets/ml/` | model/schema/metadata | predictor contracts |

### 3.2 Dependency direction

หน้าจออ้างอิง app state, models และ services แต่ services ไม่อ้างอิงหน้าจอ
domain models ไม่ควรรู้จัก widget หรือ navigation การเปลี่ยนสูตรหรือ model
contract ต้องเริ่มที่ service/asset แล้วปรับ test และ UI mapping ตามลำดับ
ข้อมูลที่ผ่าน route แบบ typed payload ได้แก่ `InitialRiskPayload` และ
`AssessmentBundle`; route ไม่ควร reconstruct ผลจากข้อความที่แสดงบน UI

### 3.3 Application composition contract

`MaterialApp` ใช้ theme จาก `buildSooktaTheme()`, ปิด debug banner, จำกัด
text scale ด้วย `ClampedTextScale`, ติด observer จาก
`FirebaseTelemetryService.navigatorObservers` และกำหนด `/` เป็น initial
route route ที่ constructor ไม่ต้องรับ argument อยู่ใน `routes`; route ที่มี
argument หรือ edit mode ใช้ `_generateRoute`

## 4. Route Map and State Transitions

<!-- DOCX_DIAGRAM:route-state -->

### 4.1 Startup decision

`SplashScreen` รอ `SooktaAppState.restore()` และเวลาหน่วงขั้นต่ำประมาณ 900
มิลลิวินาที จากนั้นเลือกปลายทางตามลำดับ:

```text
setupCompleted == true              → /main
setupCompleted == false และ hasLanguage → /setup
นอกนั้น                                → /language
```

route เป้าหมายแทนที่ splash เพื่อไม่ให้ปุ่มย้อนกลับกลับเข้าสู่ startup

### 4.2 Onboarding state machine

```text
/language --setLanguage--> /setup
/setup --saveProfile--> /avatar
/avatar --saveAvatarAndFinish--> /main
```

เมื่อเปิด Language หรือ Setup จาก Profile จะส่ง `arguments == true` เพื่อ
เปิด edit mode และต้องไม่ล้าง onboarding/history เดิม การเพิ่มเกษตรกรภายหลัง
ใช้ `/farmers`; profile ใหม่ต้องได้ `profileId` ใหม่และกลายเป็น active farmer

### 4.3 Assessment state machine

```text
/main → /evaluation-menu
/evaluation-menu → /evaluation-form(SooktaActivity)
/evaluation-form → /initial-risk(InitialRiskPayload)
/initial-risk → เลือกคำแนะนำ/ยืนยัน
/initial-risk → /final-result(AssessmentBundle)
/final-result → /daily-prediction หรือ /main
```

ก่อนออกจาก Evaluation Form ระบบบันทึก `EvaluationDraft` ตามจุดที่ UI กำหนด
เมื่อบันทึก final transaction สำเร็จ draft เดิมจึงถูกลบ ถ้า persistence
ล้มเหลว history insertion และ next ID จะ rollback

### 4.4 Typed route validation

- `/evaluation-form` รับ `SooktaActivity`; ถ้า type ไม่ตรงใช้
  `SooktaActivity.transplanting`
- `/initial-risk` ต้องรับ `InitialRiskPayload`; ถ้าไม่ตรงแสดง
  `RouteErrorScreen`
- `/final-result` ต้องรับ `AssessmentBundle`; ถ้าไม่ตรงแสดง
  `RouteErrorScreen`
- `/history-detail` รับ `int historyId`; ถ้าไม่ตรงส่ง `-1` ให้หน้าจอจัดการ
- route ที่ไม่รู้จักคืน `null` ให้ `MaterialApp` ใช้ default unknown-route
  behavior

## 5. State, Persistence and Schema Migration

<!-- DOCX_DIAGRAM:restore-migration -->

### 5.1 State owner และ observable contract

`SooktaAppState extends ChangeNotifier` เป็น owner ของ `language`, current
`profile`, `farmers`, `activeProfileId`, `setupCompleted`, `history`,
`evaluationDrafts`, `nextHistoryId` และ `hydrated` getter ที่คืน collection
ใช้ unmodifiable view เพื่อไม่ให้ UI เปลี่ยน state โดยข้าม method

`restore()` memoize `Future` ไว้ใน `_restoreFuture` จึงไม่อ่าน storage ซ้ำ
พร้อมกัน หลัง restore สำเร็จหรือล้มเหลวต้องตั้ง `_hydrated = true` และ
`notifyListeners()`

### 5.2 Restore order

1. เปิด `SharedPreferences`
2. ตรวจ schema และสร้าง backup ถ้า version เก่ากว่า 2
3. restore language และ legacy profile
4. restore setup flag และ next history ID
5. restore farmer list; ถ้าว่างให้ migrate legacy profile
6. เลือก active farmer จาก key หรือใช้รายการแรก
7. restore history และเลื่อน `nextHistoryId` ให้มากกว่า ID สูงสุด
8. restore legacy draft และ draft collection
9. เติม farmer/date/app metadata ให้ legacy draft แล้ว index ด้วย composite key
10. เลือก draft ล่าสุดของ active farmerและบันทึก schema version 2

ถ้ามี exception ใดในกระบวนการ parse/restore ระบบ reset runtime state ทั้งชุด
เป็นค่าเริ่มต้น ไม่โยน exception ไปทำให้ startup crash

### 5.3 Schema migration และ backup

`_currentDataSchemaVersion = 2` ถ้า stored version ต่ำกว่า 2 ระบบสร้าง object
backup ที่มี `fromSchemaVersion`, `toSchemaVersion`, `createdAt` และสำเนา
profile/farmers/active/history/nextId/draft/drafts จากนั้นบันทึกที่
`sookta.backup.schema.<oldVersion>.<microseconds>` และชี้ key ล่าสุดด้วย
`sookta.latestBackup`

กลไกนี้เป็น snapshot backup ไม่ใช่ rollback UI อัตโนมัติ การกู้คืนต้องใช้
เครื่องมือ/ขั้นตอนสนับสนุนภายนอก source ปัจจุบัน

### 5.4 Persistence transaction semantics

method ที่เปลี่ยนค่าทั่วไปเรียก `_persistSoon()` หลัง hydrated และไม่ await
เพื่อให้ UI ตอบสนองทันที ส่วน `saveEvaluationDraft`, `clearEvaluationDraft`
และ `saveEvaluation` await `_persist()` เพราะเป็น transaction สำคัญ

`saveEvaluation` สร้าง record และแทรก index 0 ก่อนเขียน storage หากเขียนไม่
สำเร็จจะลบ record คืน draft และคืน `_nextHistoryId` เมื่อยังปลอดภัย จึงไม่
ประกาศผลสำเร็จทั้งที่ history ไม่ถูกเก็บ

### 5.5 Draft isolation

`_draftKey()` สร้าง:

```text
<farmerProfileId หรือ no-profile>|<activity.name>|<YYYY-MM-DD>
```

`saveEvaluationDraft()` คัดลอก media ทุกไฟล์ผ่าน `LocalImageStore` ก่อนเติม
farmer ID/name, assessment date, app version และ `savedAt` แล้วจึง persist
การค้น draft รับ profile และ optional activity และเลือกฉบับล่าสุดตามเวลา

## 6. Domain Models and Serialization Contracts

### 6.1 Serialization rules

DTO ที่ต้องเก็บระยะยาวใช้ `toJson()`/`fromJson()` โดย enum เก็บเป็น `.name`,
วันเวลาเป็น ISO-8601 และ number parser ยอมรับ `num` ก่อนแปลงเป็น int/double
field ใหม่ต้องมี default ที่เปิดข้อมูลเก่าได้ การเปลี่ยนชื่อ field หรือ enum
ต้องเพิ่ม migration/compatibility test

### 6.2 Core contracts

| Class | หน้าที่ | Invariant สำคัญ |
|---|---|---|
| `UserProfile` | ข้อมูลเกษตรกรและ avatar | `profileId` เป็น identity ภายใน; BMI คำนวณเมื่อ weight/height >0 |
| `EvaluationDraft` | form state ที่ยังไม่เป็น transaction | ผูก activity/job/farmer/date; selected media เป็น persistent paths |
| `InitialRiskPayload` | payload จาก form ไปหน้าผลก่อนปรับ | มี activity, `ErgoInputData`, `RebaInputData`, before result และ optional breakdown |
| `AssessmentBundle` | payload ไปผลสุดท้าย | เก็บ before/after, selected keys และ breakdown สองช่วง |
| `ErgoInputData` | input งานยกหรือดัน–ดึง | หน่วยต้องตรงกับ service: kg, cm, ครั้ง/นาทีหรือชั่วโมงตาม field, hour, day/week |
| `RebaInputData` | input lookup REBA | score component และ modifier ต้องอยู่ในช่วงที่ calculator clamp ได้ |
| `PoseRebaFrameAnalysis` | ผลต่อ frame | image index/timestamp ต้อง trace กลับ media sample ได้ |
| `MotionAnalysisSummary` | aggregation หลาย frame | ratio 0–1; count ไม่เกิน readable/sampled ตามความหมาย |
| `AssessmentBreakdown` | หลักฐานรวมของการคำนวณ | primary method, REBA input/result, optional ISO, pose frames และ motion |
| `ErgoResult` | result ที่ UI ใช้ | `userScore` 1–9, risk, suggestion, economic loss และ optional AI alert |
| `EvaluationHistoryRecord` | persisted final transaction | ID เพิ่มขึ้น, farmer snapshot, before/after, app version และ research fields |

### 6.3 Risk และ method enums

- `RiskLevel`: `low`, `medium`, `high`, `veryHigh` เรียงจากต่ำไปสูง
- `BodyPart`: `neck`, `trunk`, `legs`, `arms`, `wrists`
- `JobType`: `lifting`, `pushPull`, `reba`
- `AssessmentMethod`: `rebaIsoCombined`, `reba`,
  `iso11228Lifting`, `iso11228PushPull`
- `MotionPattern`: `stableLowRisk`, `intermittentWorstPosture`,
  `repeatedRiskMovement`, `staticHighRiskHold`

### 6.4 Farmer snapshot ใน history

History ไม่อ้าง profile แบบ pointer อย่างเดียว แต่คัดลอก farmer ID, name,
role, location, age, gender, weight, height, BMI และ category ณ เวลาประเมิน
ทำให้ record ยังอธิบายได้เมื่อ profile ถูกแก้หรือลบ `profileForRecord()`
พยายามคืน current farmer ก่อน หากไม่พบจึง reconstruct จาก snapshot

## 7. Media Ingestion and Quality Gates

### 7.1 Supported input

หน้า `EvaluationFormScreen` รองรับภาพนิ่ง 1–4 ช่องในระดับ state แต่
production readiness กำหนดให้ครบ 4 มุม วิดีโอรับจากกล้องหรือ gallery
ความยาวไม่เกิน 20 วินาทีและแยกได้สูงสุด 8 frames หลังรับ media ระบบต้อง
เรียก pose analysis ใหม่และ invalidate pose/XGBoost result เดิม

ภาพจาก picker/camera และ frame จากวิดีโอถูกอ้างด้วย local path ก่อนบันทึก
draft จะคัดลอกผ่าน `LocalImageStore.saveImageFile()` ไป application
Documents directory เพื่อไม่ให้ temporary picker path หาย

### 7.2 Video native contract

`VideoFrameExtractionService` ใช้ `MethodChannel('sookta/video_frames')`
พร้อม method:

| Method | Request | Response | Validation |
|---|---|---|---|
| `getVideoDurationMs` | `{path}` | positive `int` ms | null/≤0 → exception |
| `extractFrames` | `{path,maxDurationMs,maxFrames}` | duration, paths, timestamps | duration ≤20s และ frame ไม่ว่าง |

ถ้าจำนวน timestamp ไม่เท่าจำนวน frame Dart layer สร้าง timestamp แบบกระจาย
เท่ากันที่ `duration × (index+1)/(frameCount+1)` native implementation ของ
iOS และ Android ต้องคืน path ที่ Flutter process อ่านได้

### 7.3 Single-person gate

ทุกภาพผ่าน `MultiPersonPoseDetector.countPeopleFromFile()` ซึ่ง resize เป็น
256×256 และเรียก `movenet_multipose_lightning.tflite` output รองรับสูงสุด
6 คน คนหนึ่งนับเมื่อ person score ที่ index 55 ≥0.3
`requiresSinglePersonReplacement(count)` คืน true เมื่อ count ไม่เท่ากับ 1
ดังนั้นทั้งศูนย์คนและหลายคนต้องเปลี่ยนภาพ

### 7.4 Pose readability

`PoseEstimationService.estimatePoseFromFile()` decode และ resize 256×256
โหลด `assets/ml/movenet_thunder.tflite` ด้วย 4 threads และอ่าน output
`[1,1,17,3]` เป็น `(y,x,score)` ค่า person score คือค่าเฉลี่ย 17 keypoints
ถ้า ≤0.2 คืน null ส่วนจุดที่ใช้คำนวณมิติยกต้องมี confidence >0.3

### 7.5 Composite readiness

`AssessmentReadiness.canAnalyze` เป็นจริงเมื่อ:

```text
hasMedia
AND NOT hasImageQualityIssues
AND poseAssessmentReady
AND NOT poseBusy
AND requiredDataIssues.isEmpty
```

quality issue รวมภาพไม่ครบ 4 มุม อ่าน pose ไม่ได้ มี unreadable frame หรือ
มีจำนวนคนไม่เท่ากับหนึ่ง required data issue รวม duration/work days ≤0,
frequency <0, tool ไม่อยู่ใน activity และค่าระยะ/แรงที่จำเป็นไม่เป็นจำนวนบวก
ปุ่ม “ดูผลประเมิน” ใน production ผูกกับเงื่อนไขนี้ ไม่มี bypass

## 8. Assessment Processing Pipeline

<!-- DOCX_DIAGRAM:assessment-sequence -->

### 8.1 Processing sequence

1. รับ/copy media และสร้าง timestamp metadata
2. ตรวจจำนวนคนทุก frame
3. เรียก MoveNet Thunder และตัด frame ที่อ่าน pose ไม่ได้
4. สร้าง 51 joint features ตาม schema เมื่อ loader พร้อม
5. แปลง pose เป็น `RebaInputData` ต่อ frame
6. เลือก frame ที่ REBA score สูงสุดเป็น worst posture
7. สรุป motion สำหรับ source ชนิดวิดีโอ
8. คำนวณ REBA และ branch ISO-style ตาม `JobType`
9. รวมผลด้วย maximum-risk rule
10. ใช้ XGBoost/ONNX เป็น upward-only guardrail เมื่อ inference สำเร็จ
11. สร้าง `AssessmentBreakdown`, save draft และส่ง `InitialRiskPayload`
12. ผู้ใช้เลือก action; ระบบจำลอง after result และยืนยันก่อนบันทึก history

### 8.2 Job dispatch

| `JobType` | Primary calculation | ISO-style branch | `AssessmentMethod` |
|---|---|---|---|
| `reba` | REBA | ไม่มี | `reba` |
| `lifting` | REBA | `calculateLiftingRisk` | `rebaIsoCombined` |
| `pushPull` | REBA | `calculatePushPullRisk` | `rebaIsoCombined` |

activity กำหนด default job type แต่เจ้าหน้าที่สามารถเปลี่ยนได้ จึงห้าม
อนุมาน method จากชื่อกิจกรรมเพียงอย่างเดียว

### 8.3 Frame aggregation

`_worstFrame()` ใช้ `rebaScore` สูงสุดโดยถ้าเท่ากันคง frame ก่อนหน้า
motion ratio ใช้ readable frame เป็น denominator:

```text
ratio = matching_frame_count / readable_frame_count
sample_rate_fps = sampled_frame_count / duration_seconds
estimated_seconds = ratio × duration_seconds
```

movement change เพิ่มหนึ่งเมื่อระหว่าง frame ติดกัน max delta ของ
trunk/neck/upper-arm ≥20° หรือผลรวม delta ≥35° ค่า estimated seconds เป็น
การอนุมานจาก sampling ไม่ใช่ continuous measurement

## 9. Algorithm Specifications

### 9.1 Method contract summary

| Method | Input → Output | Unit/Range | Test |
|---|---|---|---|
| `UserProfile.bmi` | profile text → `double?` | kg/m² | app-state/export tests |
| `analyzeRebaPose` | `Person, RebaInputData` → frame analysis | degree, score | pose/REBA regression |
| `calculateRebaScoreBreakdown` | REBA input → lookup detail | final 1–15 | `ergo_calculator_test.dart` |
| `calculateRebaRisk` | REBA input → `ErgoResult` | UI score 1–9 | `ergo_calculator_test.dart` |
| `calculateLiftingRisk` | ergonomic input → RWL/LI result | kg, ratio | `ergo_calculator_test.dart` |
| `calculatePushPullRisk` | ergonomic input → force ratio | ratio | `ergo_calculator_test.dart` |
| `calculateCombinedRebaIsoRisk` | two results → combined | maximum risk/score | calculator/ML tests |
| `EconomicImpactService.estimate` | risk/income/body map → cost breakdown | บาท | economic tests |
| `compareBeforeAfter` | before impact/scores → comparison | บาท, 0–1 | economic tests |
| `featureValuesForWindow` | 7 history records → normalized features | 0–1 | daily prediction tests |

### 9.2 BMI

```text
weight_kg = parse(profile.weight)
height_m = parse(profile.height) / 100
BMI = weight_kg / (height_m × height_m)
```

คืน null ถ้า parse ไม่ได้หรือค่า ≤0 category คือ <18.5 underweight,
18.5–<23 normal และ ≥23 above Asian BMI range แสดงทศนิยม 1 ตำแหน่ง BMI
เป็น profile/research feature ไม่เข้าคะแนน REBA หรือ ISO โดยตรง

### 9.3 Pose geometry to REBA input

จุดที่ confidence ≤0.3 ถือว่าไม่พร้อมสำหรับ geometry helper มุมแนวดิ่ง:

```text
vertical_angle = atan2(abs(delta_x), abs(delta_y)) × 180 / pi
horizontal_tilt = atan2(abs(delta_y), abs(delta_x)) × 180 / pi
three_point_angle = angle ระหว่าง vector (p1-p2) และ (p3-p2), clamp 0–180
```

threshold:

| Component | Mapping |
|---|---|
| trunk | ≤5°→1, ≤20°→2, ≤60°→3, >60°→4 |
| neck | ≤20°→1, >20°→2; side/twist เพิ่ม 1 สูงสุด 3 |
| upper arm | ≤20°→1, ≤45°→2, ≤90°→3, >90°→4; abduction/elevation เพิ่มอย่างละ 1 สูงสุด 6 |
| lower arm | 60–100°→1, นอกช่วง→2 |
| legs | knee angle <150°→2, อื่น→1 |
| neck side bending | เห็นสอง ear และ shoulder tilt >12° |
| trunk side bending | abs(shoulder tilt − hip tilt) >12° |
| trunk twisting | abs(shoulder midpoint x − hip midpoint x)/torso width >0.22 |

มิติยกประเมิน scale จาก shoulder–hip =53 ซม.:

```text
units_per_cm = distance(shoulder, hip) / 53
H = abs(wrist.x - ankle.x) / units_per_cm, clamp 25–65 cm
V = (ankle.y - wrist.y) / units_per_cm, clamp 0–175 cm
```

ค่าดังกล่าวเป็น pose estimate ผู้ใช้ต้องตรวจแก้เมื่อภาพ perspective ต่างจาก
สมมติฐาน

### 9.4 REBA

`calculateRebaScoreBreakdown()` ใช้ lookup matrix:

```text
adjusted_trunk = trunk + twist_modifier + side_flex_modifier
adjusted_wrist = wrist + wrist_twist_modifier
table_A = lookup(neck, adjusted_trunk, legs)
score_A = table_A + load_score
table_B = lookup(lower_arm, upper_arm, adjusted_wrist)
score_B = table_B + coupling_score
score_C = lookup(score_A, score_B)
raw_final = score_C + activity_score
final = apply_Sookta_safety_floors(raw_final), clamp 1–15
```

lookup index ถูก clamp ตาม matrix: neck 1–3, trunk 1–5, legs 1–4,
upper arm 1–6, lower arm 1–2, wrist 1–3 และ A/B score 1–12

Sookta safety floors:

- severe trunk ≥4 + neck ≥2 + activity ≥1 → final อย่างน้อย 9
- severe trunk ≥4 + อย่างน้อยหนึ่งใน neck/activity/legs/upper-limb demand
  → อย่างน้อย 8
- severe trunk ≥4 เพียงอย่างเดียว → อย่างน้อย 6
- adjusted trunk ≥3 + neck + activity + upper-limb demand → อย่างน้อย 8

การ map final score ไป UI: 1→1, 2→2, 3→3, 4→4, 5→5, 6–7→6,
8→7, 9–10→8, ≥11→9 ความเสี่ยง REBA: ≤3 low, ≤7 medium,
≤10 high, >10 veryHigh

### 9.5 ISO 11228-1 style lifting/carrying approximation

```text
reference_mass = 20 kg เมื่อ gender == female, นอกนั้น 25 kg
H = max(horizontalDist, 25)
HM = clamp(25/H, 0.7, 1.0)
VM = clamp(1 - 0.003×abs(verticalHeight-75), 0.7, 1.0)
FM = 1.00/0.94/0.84/0.75/0.50 ตาม frequency ≤0.2/≤1/≤4/≤6/>6
DM = 1.00/0.85/0.75/0.60 ตาม distance ≤2/≤10/≤20/>20
RWL = reference_mass × VM × HM × FM × DM
LI = loadWeight / RWL; ถ้า RWL≤0 ใช้ 99
```

LI map ไป user score: ≤0.5→1, ≤0.75→2, ≤1→3, ≤1.5→4,
≤2→5, ≤3→6, ≤4→7, ≤5→8, >5→9 risk คือ ≤1 low,
≤3 medium, >3 high

สูตรนี้เป็น mobile screening approximation ใช้ multiplier บางส่วนจาก
implementation ไม่ใช่ full-standard ISO assessment หรือ certification

### 9.6 ISO 11228-2 style push/pull approximation

```text
limits male   = initial 25, sustained 15
limits female = initial 20, sustained 12
risk_ratio = max(initialForce/initialLimit, sustainForce/sustainLimit)
```

ratio map ไป user score: ≤0.4→1, ≤0.6→2, <0.8→3, ≤0.9→4,
≤1→5, ≤1.2→6, ≤1.5→7, ≤2→8, >2→9 risk คือ <0.8 low,
0.8–1 medium และ >1 high หน่วย force ต้องตรงกับ limit ที่แอปสื่อสาร
implementation นี้ไม่ครอบคลุมตัวแปรมาตรฐานทุกตัว

### 9.7 Combined result

`calculateCombinedRebaIsoRisk()` เลือก risk และ user score สูงสุด รวม
body-part map โดยเลือก risk สูงสุดต่อส่วน รวม suggestion key แบบ unique และ
คำนวณ economic impact ใหม่ `techScore` ของ combined result เท่ากับ
combined user score เพื่อไม่ผสม REBA raw score กับ LI/force ratio

### 9.8 Simulation หลังเลือก action

แต่ละ recommendation key ลด 1 หรือ 2 คะแนน ผลรวม cap ที่ 4:

```text
reduction = min(sum(selected_action_reduction), 4)
after_score = clamp(before_user_score - reduction, 1, 9)
after_tech_score = max(1, before_tech_score - reduction)
```

body-part risk ที่ action ครอบคลุมลดลงหนึ่งระดับ และ breakdown ของ REBA/ISO
ถูกจำลองในแนวเดียวกัน นี่คือ potential impact simulation ไม่ใช่การวัดท่าจริง
หลังปรับ หากต้องการผลจริงต้องเก็บ media และประเมินใหม่

### 9.9 Economic impact

ถ้า overall risk = low คืนทุกค่าเป็นศูนย์ มิฉะนั้น:

```text
body_treatment = sum(body_part_average_cost × body_part_risk_multiplier)
medical_visit = weighted_average(public/private/clinic) × overall_multiplier
medicine = survey_average_medicine × overall_multiplier
travel = survey_average_travel × overall_multiplier
lost_income = max(daily_income × assumed_lost_days,
                  survey_average_lost_income × overall_multiplier)
reduced_income = survey_average_reduced_income × overall_multiplier
total = body_treatment + medical_visit + medicine + travel
        + lost_income + reduced_income
```

risk multiplier = low 0, medium 0.35, high 0.75, veryHigh 1.0
lost days = 0/2/7/30 ตามลำดับ รายได้ต่อวันใช้ `incomePerYear/365` เมื่อ >0
มิฉะนั้น 350 บาท compensation อยู่ใน breakdown แต่ไม่รวม `totalCost`

การเปรียบเทียบก่อน–หลัง:

```text
score_reduction = max(0, before_score-after_score)
effective_reduction = min(score_reduction, 4)
reduction_rate = min(1, 0.28 × effective_reduction)
after_impact = round(before_impact × (1-reduction_rate))
saved = before_impact-after_impact
```

### 9.10 Daily trend และ Logistic Regression

เรียง record ตามเวลาและใช้ 7 รายการล่าสุด ถ้าน้อยกว่า 7 คืน
`hasEnoughData=false`, probability 0 และระดับ insufficient เมื่อครบ 7:

```text
logit = intercept + sum(beta_i × normalized_feature_i)
p = sigmoid(logit)
p_overall = max(p_REBA, p_ISO11228) เมื่อ asset มีสองสมการ
```

อย่างไรก็ตามระดับที่ UI ใช้ใน production มาจากจำนวน REBA high/veryHigh:
0–1 low, 2–3 watch, 4–5 high, 6–7 critical ไม่ได้ใช้ probability เป็น
validated injury decision trend = last-first: ≥1 increasing, ≤−1 decreasing,
นอกนั้น stable

feature หลัก normalize 0–1 ได้แก่ score 1–9, count/7, load/50,
frequency per hour/720, economic loss/40,000, age/80, BMI 15–35,
carrying exposure = 0.45 load +0.25 duration +0.20 frequency +0.10 distance
และ push/pull exposure = 0.60 force ratio +0.25 duration +0.15 distance

## 10. Machine Learning Assets and Inference Contracts

<!-- DOCX_DIAGRAM:model-contracts -->

### 10.1 Asset registry

| Layer | Asset | Input/Output | Production status |
|---|---|---|---|
| Single pose | `assets/ml/movenet_thunder.tflite` | image 256×256 →17 keypoints | production pose input |
| Multi pose | `assets/ml/movenet_multipose_lightning.tflite` | image 256×256 →≤6 pose rows | production single-person gate |
| Feature schema | `assets/models/joint_feature_schema.json` | 17×(x,y,score)=51 | production contract |
| Posture risk | `assets/models/xgboost_model.onnx` | Float32 `[1,51]` → probability/logit | upward-only research guardrail |
| XGBoost metadata | `assets/models/xgboost_model_metadata.json` | provenance/threshold/metrics | traceability |
| Daily trend | `assets/ml/daily_injury_logistic_model.json` | 7-record normalized features → probabilities | template; UI level count-based |
| Legacy posture logistic | `assets/models/logistic_weights.json` | 51→71 engineered features | not packaged/ไม่ใช้ assessment ปัจจุบัน |
| Deprecated alert ensemble | `assets/ml/risk_alert_models.json` | assessment feature vector | compatibility path ไม่ใช่ production assessment |

### 10.2 Joint feature schema

schema ID `movenet-thunder-v1-17x3-normalized`, feature count 51, order คือ
landmark index จาก nose ถึง rightAnkle และภายในแต่ละ landmark เป็น x, y,
score ช่วง 0–1 ค่า missing คือ `[0,0,0]` และ clip to range
`MoveNetJointFeatureExtractor` ต้อง validate schema ก่อน extract

### 10.3 XGBoost ONNX runtime

`XGBoostOnnxPredictor` โหลด asset ด้วย ONNX Runtime, input name `input`,
ตรวจ vector ไม่ว่าง จำนวนเท่ากับ schema และทุกค่า finite แล้วสร้าง
Float32 tensor `[1,featureCount]` หาก output มีอย่างน้อยสองตัวใช้ค่าตัวที่สอง
เป็น probability มิฉะนั้นใช้ตัวแรก ถ้าค่านอก 0–1 ถือเป็น logit และผ่าน
sigmoid

threshold default: medium 0.272727, high 0.636364, veryHigh 0.909091
หน้า form รันทุก frame ที่มี features แล้วเลือกผลที่ risk สูงสุด; ถ้า risk
เท่ากันเลือก confidence สูงสุด error ใดคืน null เพื่อให้สูตรหลักทำงานต่อ

guardrail:

```text
ถ้า xgb_risk <= formula_risk: คง result และแนบ alert
ถ้าสูงกว่า: ยกระดับ risk และ floor score เป็น medium≥4, high≥7, veryHigh≥9
```

model metadata ระบุ training 298, holdout 90, risk distribution มีเฉพาะ
high/veryHigh และ holdout risk accuracy 0.6667 จึงห้ามกล่าวอ้างว่า validated
สำหรับประชากรหรือทำนายการบาดเจ็บ

### 10.4 Daily model contract

asset version `daily-injury-logistic-template-2026-06-14` กำหนดขั้นต่ำ
7 transactions และสมการ REBA/ISO แยกกัน แต่ `trainingStatus.researchTrained`
เป็น false เนื่องจากไม่มี confirmed seven-transaction MSD symptom outcome
coefficients เป็น template จนกว่าจะ fit ด้วย maximum likelihood/
cross-entropy จาก label จริง

### 10.5 Resource lifecycle

TFLite/ONNX interpreter ถูก cache ต่อ service/predictor instance และมี
`dispose()` ปิด resource หน้าจอต้องไม่สร้าง model ต่อ frame ONNX input,
run options และ output ถูก release ใน `finally`; model/session failure
แปลงเป็น typed exception ใน predictor และถูก UI fallback เป็น formula result

## 11. Recommendation Engine

### 11.1 Four-category contract

`RiskRecommendationService.farmerRecommendations()` ต้องคืนรายการ action
ที่อ่านง่ายแยก 4 หมวด:

1. `activityPosture` — ท่าทางเฉพาะกิจกรรม
2. `riskReduction` — วิธีลด hazard/load/force
3. `restRecovery` — พัก ฟื้นตัว และ rotation
4. `workloadSupport` — เครื่องมือ ผู้ช่วย และการจัดงาน

แต่ละ `FarmerRecommendation` มี category, title, detail และ action key
เนื้อหาขึ้นกับ activity, overall risk และ body-part risk โดย manual-handling
activity เพิ่ม key ของ ISO-style suggestions

### 11.2 Selection และ deduplication

calculator สร้าง technical suggestion keys จาก input/threshold
recommendation service แปลงเป็นข้อความไทย/อังกฤษและรวมกับ activity/body map
key ต้อง unique เพื่อไม่ให้ action เดียวลดคะแนนซ้ำ UI แสดงเป็น 4 cards
และเก็บ selected key ไว้ใน `AssessmentBundle`/history

### 11.3 Communication constraint

คำแนะนำเป็น risk-control suggestion ไม่ใช่ treatment prescription ควรบอก
ให้ผู้ใช้ลดแรง/ระยะ/ความถี่ ปรับท่า/เครื่องมือ วางแผนพัก และขอผู้ช่วยตามงาน
หากมีอาการต้องใช้ช่องทางสุขภาพที่เหมาะสม ไม่ใช้คะแนนจำลองหลังเลือกคำแนะนำ
แทนการประเมินซ้ำ

## 12. Draft, History and Export Contracts

### 12.1 Draft lifecycle

form hydrate จาก draft ที่ profile/activity ตรงกันและ copy ค่า media/tool/
workload/REBA input กลับสู่ controller การเปลี่ยน input ที่สำคัญ schedule
autosave; การเปลี่ยน media ต้องวิเคราะห์ pose ใหม่ ก่อน persist
`saveEvaluationDraft()` ย้าย media เข้า Documents directory และประทับ
`savedAt`

draft ไม่ใช่ history และไม่มีผล final เมื่อ `saveEvaluation()` สำเร็จเท่านั้น
จึงลบ draft transaction นั้น การล้มเหลวระหว่างเขียน history ต้องคืน draft
และ history ID ตามเดิม

### 12.2 History identity และ immutability

`_nextHistoryId` เป็น integer monotonic ภายในเครื่อง restore จะบังคับให้มากกว่า
ID สูงสุดเสมอ record ถูก insert ต้น list เพื่อแสดงล่าสุดก่อน เมื่อ profile
ถูกเปลี่ยนภายหลัง record เก่ายังคง farmer snapshot และ app version เดิม

History เก็บ before/after results, selected suggestions, body risk,
AI guardrail metadata, full calculation breakdown, photo trace identifier
และช่อง research/expert ที่ nullable การแก้ outcome label ไม่ควรแก้
formula-derived field เดิม

### 12.3 Assessment CSV

`AssessmentExportService` สร้าง UTF-8 CSV พร้อม BOM และ quote ทุก field
ใน application Documents directory ชื่อไฟล์มี timestamp รองรับ:

- `exportExcelCsv()` — assessment/bundle เดียวแบบอ่านด้วย Excel
- `exportHistoryRecordCsv()` — history record เดียว
- `exportAllHistoryCsv()` — flat rows ทุกเกษตรกร

ไฟล์ assessment รวม participant/profile, activity/job, before/after,
worksheet fields, calculation breakdown, economic detail, body risk,
recommendation และ reference source ส่วน all-history schema เพิ่ม field
สำหรับ research trend, photo, task completion, expert REBA และ comments
`export_schema_version` และ source note ต้องปรากฏใน output

### 12.4 Training export

`TrainingDataExportService.exportTrainingFiles()` สร้างสองไฟล์:

| Dataset | Grain | Eligibility | Label state |
|---|---|---|---|
| daily logistic | rolling window 7 transactions ต่อ farmer | จำนวน records ≥7 | outcome columns ว่าง รอ research follow-up |
| XGBoost pose | หนึ่งแถวต่อ pose frame | `jointFeatures.length == 51` | pseudo-label + ช่อง training/expert label |

จำนวน daily rows ต่อ farmer = `max(0, records−6)` ส่วน XGBoost rows เท่ากับ
จำนวน frame ที่มี 51 features daily CSV มี 26 primary feature columns และ
compatibility aliases; outcome เช่น `msd_symptom_present` ต้องเติมภายหลัง
ห้ามใช้ pseudo-label เป็น clinical ground truth

### 12.5 CSV safety

ทุก cell escape double quote และครอบด้วย quote แต่ source ปัจจุบันไม่ได้
ระบุ formula-injection neutralization สำหรับค่าที่ผู้ใช้กรอกขึ้นต้นด้วย
`=`, `+`, `-` หรือ `@` ผู้รับไฟล์จึงต้องเปิดใน environment ที่เชื่อถือได้
และทีมพัฒนาควรพิจารณา hardening ก่อนใช้ export จาก input ที่ไม่เชื่อถือ

## 13. Error Handling, Telemetry and Fallback

### 13.1 Error taxonomy

| Failure | Detection | User/runtime behavior |
|---|---|---|
| Firebase initialize | exception ใน `_initializeCrashlytics` | report ผ่าน Flutter error channel เท่าที่ทำได้ แล้วเปิด app ต่อโดยไม่มี telemetry |
| Flutter/platform fatal | installed handlers เมื่อ Firebase ready | ส่ง Crashlytics fatal; zone handler ไม่ทำให้เกิด backend dependency |
| state parse/restore | catch รอบ `_restore` | reset runtime state เป็นค่าเริ่มต้นและ hydrate |
| invalid typed route | `is` check | `RouteErrorScreen` หรือ sentinel `-1` |
| video duration/frame | `VideoFrameExtractionException` | แจ้งเปลี่ยนวิดีโอ/ลดความยาว |
| unreadable/multi-person pose | null/count !=1 | mark เฉพาะภาพที่ต้องเปลี่ยนและ block readiness |
| schema/model load | typed exception หรือ catch ใน form | ไม่ใช้ XGBoost; ใช้สูตรหลัก |
| ONNX malformed input/output | finite/count/output check | catch แล้ว fallback สูตรหลัก |
| persistence final save | exception จาก `_persist` | rollback history/draft/ID และ rethrow |
| export/file/share | plugin/file exception | แสดง error โดยหน้าจอผู้เรียก |

### 13.2 Firebase event contract

เมื่อ Firebase app พร้อม `FirebaseTelemetryService.initialize()` เปิด
Crashlytics/Analytics collection, ติด navigator observer และส่ง `app_start`
event หลัก:

| Event | Parameters |
|---|---|
| `app_start` | platform, build_mode |
| `assessment_image_added` | source, image_count |
| `assessment_calculated` | activity, job_type, primary_method, risk_level, score, image_count, uses_iso11228 |
| `assessment_saved` | activity, before/after risk/score, suggestion_count |
| `export_created` | export_type, record_count |

key ถูก normalize ให้เป็น `[A-Za-z0-9_]`, ต้องเริ่มด้วยตัวอักษรและยาวไม่เกิน
40; string value ถูกตัดที่ 100 ตัวอักษร source ปัจจุบันตั้ง collection เป็น
true เมื่อ Firebase พร้อมและไม่มี user-visible consent/opt-out control

### 13.3 Privacy boundary ของ telemetry

event methods ปัจจุบันไม่ส่งชื่อ farmer, participant code, media path หรือ
ค่ารักษาโดยตรง แต่ screen route และ crash diagnostics อาจเป็น operational
metadata การใช้งานวิจัย/production ต้องทบทวน privacy notice, lawful basis,
retention และการขอความยินยอมให้ตรงกับบริบทจริง

## 14. Platform Configuration

### 14.1 iOS

| Setting | Source value |
|---|---|
| Bundle identifier | `$(PRODUCT_BUNDLE_IDENTIFIER)`; project/release ใช้ `com.kdev.sookta` |
| Marketing/build | `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` |
| Deployment target | iOS 15.0 |
| Orientation iPhone | `UIInterfaceOrientationPortrait` เท่านั้น |
| Orientation iPad | `UIInterfaceOrientationPortrait` เท่านั้น |
| Multitasking | `UIRequiresFullScreen=true` เพื่อรองรับ portrait-only validation |
| Encryption declaration | `ITSAppUsesNonExemptEncryption=false` |
| Permissions | Camera, Photo Library, Photo Add, Microphone usage descriptions |
| Scene | single scene; `UIApplicationSupportsMultipleScenes=false` |

Microphone description ระบุว่าอาจใช้เมื่อ system camera บันทึกวิดีโอ แต่เสียง
ไม่ใช้ในการประเมิน ergonomic result

### 14.2 Android

| Setting | Source value |
|---|---|
| namespace/application ID | `com.kdev.sookta` |
| SDK | Flutter-provided compile/min/target SDK; verified artifact เดิม target 36 |
| NDK | `28.2.13676358` |
| Java/Kotlin | JVM 17 |
| ABI filters | armeabi-v7a, arm64-v8a, x86_64 |
| Orientation | `MainActivity android:screenOrientation="portrait"` |
| Permissions | INTERNET, CAMERA |
| Camera feature | optional (`required=false`) |
| Launch mode | `singleTop` |
| Signing | release keystore จาก `android/key.properties` เมื่อมี |

repository มีทั้ง `build.gradle` และ `build.gradle.kts`; configuration ที่
ตรวจ artifact ก่อนหน้าตรงกับ Groovy `build.gradle` ซึ่งรองรับ release keystore
ส่วน `.kts` ยังมี debug-signing placeholder จึงต้องไม่สลับ build script โดย
ไม่ได้ตั้ง signing ให้ production และควรลด duplicate configuration ในอนาคต

### 14.3 Portrait-only contract

contract มีสามชั้น: iOS plist, Android manifest และ widget/platform regression
test iPad ต้องใช้ `UIRequiresFullScreen=true`; มิฉะนั้น App Store ต้องการ
orientation ครบเพื่อ multitasking และจะปฏิเสธ portrait-only bundle

## 15. Test Architecture and Traceability

### 15.1 Test layers

| Layer | Scope | Evidence pattern |
|---|---|---|
| Unit | formula, mappings, schema, model helper | `*_service_test.dart`, `ergo_calculator_test.dart` |
| Widget/flow | validation, route, grouping, persistence | screen/flow tests |
| Configuration | orientation, production gate, parity, store version | config/source inspection tests |
| ML integration | schema, feature, asset load, predictor fallback | `ml_end_to_end_comprehensive_test.dart` |
| Device UAT | permission, camera/gallery, TTS, native channel, real layout | dated UAT records |
| Store artifact | IPA/AAB metadata, signing, bundletool/Xcode export | release verification record |

### 15.2 Current verification baseline

หลักฐานที่บันทึกกับ source snapshot: Flutter full suite 120/120, focused
calculation/ML 52/52 และ production simulator/emulator flow ผ่านเมื่อ
19 กรกฎาคม 2026 ในการจัดทำ Technical Specification นี้ state/draft/avatar
targeted suite ผ่าน 8/8 และ media/calculation/ML suite ผ่าน 61/61

Physical iPhone UAT วันที่ 12 กรกฎาคม 2026 ผ่าน install/launch,
portrait-only, multi-farmer/avatar, draft/activity, media, multi-person,
recommendation, Thai TTS, history/filter/export แต่การทดสอบผลช่วงนั้นเคยใช้
temporary uploaded-video bypass หลังถอด bypass แล้วมีหลักฐาน simulator/
emulator แต่ยังไม่มี physical iPhone production-flow rerun ที่ปิดครบใน
source evidence Android เครื่องจริงยังไม่มี UAT ครบ

### 15.3 Test data boundary

widget test ใช้ fixture/mocks สำหรับ platform/model บางส่วน จึงยืนยัน
navigation, validation และ mapping ไม่เท่ากับยืนยัน camera sensor, gallery
permission, TFLite/ONNX performance หรือไฟล์ native channel บนอุปกรณ์จริง
Store/UAT gate ต้องทดสอบ artifact เดียวกับที่จะอัปโหลด

## 16. Build, Versioning, Signing and Store Artifacts

### 16.1 Version sources

Flutter `pubspec.yaml` ณ application source snapshot ระบุ `1.3.7+24`
โดย build แปลงเป็น iOS `CFBundleShortVersionString/CFBundleVersion` และ
Android `versionName/versionCode` release/document version ที่ผู้ใช้กำหนด
สำหรับเอกสารนี้คือ 2.1.0 จึงต้องเปลี่ยนและตรวจ version ใน artifact 2.1.0
ก่อนอัปโหลดจริง ห้ามสรุปว่า artifact 2.1.0 มีอยู่จากชื่อเอกสารเพียงอย่างเดียว

### 16.2 Release build gates

1. ปิด bypass/debug route และตรวจ production assessment gate
2. รัน analyze และ full automated suite
3. ตั้ง version/build ใหม่ที่ Store train ยังเปิด
4. ตรวจ portrait metadata และ permission strings
5. Android ต้องมี release keystore และสร้าง signed AAB
6. iOS ต้อง archive/export ด้วย Apple Distribution profile
7. เปิด artifact ตรวจ package/bundle ID, version/build, orientation,
   signing entitlement และ embedded model/assets
8. smoke/UAT ด้วย artifact เดียวกับที่จะส่ง Store
9. อัปโหลดและผ่าน server-side validation

### 16.3 Historical artifact evidence

เอกสาร `store-release-verification-1.3.7+24-20260719.md` ระบุ AAB/IPA เดิม
ผ่าน analyze, 120 tests, bundletool/Xcode export, portrait/full-screen และ
signing พร้อม hash แต่หลักฐานนี้ผูกกับ 1.3.7+24 ไม่ใช่ 2.1.0 สามารถใช้เป็น
ขั้นตอนอ้างอิงได้แต่ไม่ใช้แทนการสร้าง/ตรวจ artifact 2.1.0

### 16.4 Secret handling

`android/key.properties`, keystore, certificate private key และ App Store
credential ต้องอยู่นอก source control เอกสารนี้ไม่บันทึกรหัสผ่านหรือ private
key signing identity/team/profile ที่เปิดเผยได้ควรบันทึกใน release evidence
เฉพาะเท่าที่จำเป็น

## 17. Security, Privacy and Known Limitations

### 17.1 Data at rest และ sharing

profile/history/draft อยู่ใน `SharedPreferences`; media/CSV อยู่ Documents
directory ภายใน sandbox source ปัจจุบันไม่ใช้ application-layer encryption
CSV มีข้อมูลระบุตัวบุคคล สุขภาพเชิงคัดกรอง รายได้และงาน เมื่อ share แล้ว
สำเนาอยู่นอกการควบคุมของ Sookta ต้องใช้ participant code จำกัดผู้รับ
เข้ารหัสช่องทางส่ง และกำหนด retention/delete policy

### 17.2 Security observations

- ไม่มี authentication หรือ role-based access ภายใน local app
- ไม่มี server synchronization/remote revoke
- restore exception reset state แต่ไม่มี UI กู้ backup
- CSV quote escaping มี แต่ยังไม่มี spreadsheet formula neutralization
- Firebase collection เปิดเมื่อ initialize สำเร็จโดยไม่มี visible opt-out
- release signing ขึ้นกับไฟล์ local ที่ต้องจัดการอย่างปลอดภัย

### 17.3 Scientific/clinical limitations

- pose เป็น 2D และไวต่อมุมกล้อง แสง การบังและเสื้อผ้า
- REBA pose mapping และ safety floors เป็น Sookta adaptation
- ISO 11228-1/2 เป็นสูตรย่อ ไม่ใช่ full-standard assessment
- ISO 11228-3 อยู่ใน recommendation layer ไม่ได้คำนวณมาตรฐานฉบับเต็ม
- XGBoost dataset ไม่สมดุลและไม่มี low/medium ใน matched set ปัจจุบัน
- daily logistic coefficients ยังไม่ fit จาก confirmed outcome
- after result เป็น simulation จาก action keys ไม่ใช่ post-intervention measure
- economic impact เป็น estimate จาก survey/default assumptions ไม่ใช่
  medical bill หรือ individual compensation

### 17.4 Minimum production/UAT closure

ก่อนประกาศ 2.1.0 พร้อมใช้งานจริงต้องสร้าง signed artifact 2.1.0 และทดสอบ
physical iPhone production flow หลังถอด bypass ครบทุก gate จากนั้นตรวจ
Android parity และ physical Android flow โดยเฉพาะ video channel, permissions,
TFLite/ONNX, Thai TTS, export/share และ rotation lock

## ภาคผนวก A Route Catalogue

| Route | Screen | Arguments | Preconditions | Next/Fallback |
|---|---|---|---|---|
| `/` | `SplashScreen` | ไม่มี | app start | `/main`, `/setup` หรือ `/language` |
| `/language` | `LanguageSelectionScreen` | `bool editMode` | ไม่มี | `/setup` หรือย้อนกลับเมื่อ edit |
| `/setup` | `SetupScreen` | `bool editMode` | language สำหรับ first run | `/avatar` หรือย้อนกลับเมื่อ edit |
| `/avatar` | `AvatarSelectionScreen` | ไม่มี | profile ถูกบันทึก | `/main`; เปิด `CameraCaptureScreen` แบบ direct route |
| `/main` | `MainTabsScreen` | ไม่มี | setup complete ใน normal flow | Home/History/Profile tabs |
| `/farmers` | `FarmerManagerScreen` | ไม่มี | app state hydrated | add/edit/delete/select farmer |
| `/evaluation-menu` | `EvaluationMenuScreen` | ไม่มี | active farmer | `/evaluation-form` ใหม่หรือ resume draft |
| `/evaluation-form` | `EvaluationFormScreen` | `SooktaActivity` | active farmer/activity | `/initial-risk`; default transplanting เมื่อ type ผิด |
| `/initial-risk` | `InitialRiskScreen` | `InitialRiskPayload` | readiness/assessment สำเร็จ | `/final-result` หรือ `RouteErrorScreen` |
| `/final-result` | `FinalResultScreen` | `AssessmentBundle` | user confirmation | `/daily-prediction` หรือ `/main`; error เมื่อ payload ผิด |
| `/history-detail` | `HistoryDetailScreen` | `int historyId` | record ควรมีอยู่ | ส่ง `-1` เมื่อ argument ผิดแล้วให้ screen แสดง missing state |
| `/daily-prediction` | `DailyPredictionScreen` | ไม่มี | active farmer; ใช้ได้เต็มเมื่อมี 7 records | `/risk-reduction-potential` |
| `/risk-reduction-potential` | `RiskReductionPotentialScreen` | ไม่มี | ไม่มี | ย้อนกลับ |
| `/help` | `HelpScreen` | ไม่มี | ไม่มี | `/references` |
| `/references` | `ReferencesScreen` | ไม่มี | ไม่มี | ย้อนกลับ |
| `/terms` | `TermsScreen` | ไม่มี | ไม่มี | ย้อนกลับ |
| `/contact` | `ContactScreen` | ไม่มี | ไม่มี | ย้อนกลับ |
| `/training-data-export` | `TrainingDataExportScreen` | ไม่มี | มีสิทธิ์ share/file | share sheet หรือ error message |

## ภาคผนวก B Persistence Key Catalogue

| Key | Type | Producer/Consumer | Default/Migration |
|---|---|---|---|
| `sookta.language` | String enum name | `setLanguage`, `restore` | null |
| `sookta.profile` | JSON object | current/legacy profile | empty `UserProfile` |
| `sookta.farmers` | JSON array | farmer CRUD | migrate legacy profile เมื่อ array ว่าง |
| `sookta.activeProfileId` | String | select/save farmer | farmer รายการแรก |
| `sookta.setupCompleted` | bool | avatar finish/add farmer | false |
| `sookta.history` | JSON array | `saveEvaluation`, restore | empty |
| `sookta.nextHistoryId` | int | history allocator | 1 หรือ max history ID + 1 |
| `sookta.evaluationDraft` | JSON object | legacy/current draft compatibility | null |
| `sookta.evaluationDrafts` | JSON array | draft collection | empty; migrate legacy draft |
| `sookta.dataSchemaVersion` | int | restore/persist | legacy = 1; current = 2 |
| `sookta.latestBackup` | String key reference | schema backup | null |
| `sookta.backup.schema.<v>.<timestamp>` | JSON object | pre-migration backup | สร้างเมื่อ stored schema <2 |

## ภาคผนวก C Data Dictionary

| Entity | Field group | Type/Unit | Required/Default |
|---|---|---|---|
| `UserProfile` | profileId, farmerId, name, role, location | String | empty แล้ว app เติม internal ID เมื่อบันทึก |
| `UserProfile` | age, weight, height, incomePerYear | numeric text | empty; parser รองรับ comma decimal เฉพาะ weight/height |
| `UserProfile` | gender, avatarAsset | String/String? | `Male`/null |
| `EvaluationDraft` | activity, jobType | enum | required |
| `EvaluationDraft` | farmer/date/app metadata | String? | เติมจาก active state ก่อน persist |
| `EvaluationDraft` | selectedImagePaths | List<String> | empty; สูงสุดตาม UI media slots |
| `EvaluationDraft` | duration, frequency, force, distance, load | double | ค่า default จาก constructor/UI |
| `ErgoInputData` | loadWeight/toolWeightKg | kg | ≥0 |
| `ErgoInputData` | horizontalDist, verticalHeight, transportDistance | cm | defaults 25/75/0 |
| `ErgoInputData` | liftFrequency, durationHours, workDaysPerWeek | double | defaults 0.2/1/3 |
| `ErgoInputData` | initialForce, sustainForce | หน่วยเดียวกับ limit ใน app | defaults 0/0 |
| `RebaInputData` | trunk/neck/leg/arm/wrist score | integer component | default 1 |
| `RebaInputData` | twist/side-flex flags | bool | false |
| `RebaInputData` | load/coupling/activity score | integer modifier | default 0 |
| `PoseRebaFrameAnalysis` | imageIndex, timestampMs | int/int? ms | index required |
| `PoseRebaFrameAnalysis` | angles | double? degree | null เมื่อคำนวณไม่ได้ |
| `PoseRebaFrameAnalysis` | jointFeatures | List<double> | empty หรือ 51 values ตาม schema |
| `MotionAnalysisSummary` | counts/ratios/estimated seconds | int/double | required core; ratios 0–1 |
| `ErgoResult` | techScore/userScore/limitValue | double/int/double | required; user score 1–9 |
| `ErgoResult` | risk/bodyPartRisks/suggestions | enum/map/list | required/default empty ตาม constructor |
| `EvaluationHistoryRecord` | id/dateTime/appVersion | int/ISO date/String? | ID/date required |
| `EvaluationHistoryRecord` | before/after/economic | int/enum/int | required |
| `EvaluationHistoryRecord` | expert/outcome research fields | nullable | ผู้วิจัยเติมภายหลัง |

## ภาคผนวก D Algorithm Pseudocode

### D.1 Production assessment

```text
function assess(form):
  readiness = validateMediaPoseAndTaskInputs(form)
  require readiness.canAnalyze

  frames = []
  for media in form.media:
    require multiPersonCount(media) == 1
    pose = MoveNetThunder(media)
    require pose != null
    features = extract51Features(pose) if schemaAvailable else []
    frames += analyzeRebaPose(pose, form.rebaInput, features)

  worst = max(frames, by=rebaScore)
  reba = calculateRebaRisk(worst.rebaInput)
  iso = dispatchISO(form.jobType, form.ergoInput)
  result = iso == null ? reba : combineByMaximum(reba, iso)

  xgb = bestAvailableOnnxAlert(frames)
  if xgb != null:
    result = upwardOnlyGuardrail(result, xgb)

  return InitialRiskPayload(result, fullBreakdown)
```

### D.2 REBA lookup

```text
function reba(input):
  trunk = clamp(input.trunk + input.twist + input.sideFlex, 1, 5)
  wrist = clamp(input.wrist + input.wristTwist, 1, 3)
  A = tableA[neck][trunk][legs] + input.load
  B = tableB[lowerArm][upperArm][wrist] + input.coupling
  raw = tableC[clamp(A,1,12)][clamp(B,1,12)] + input.activity
  final = clamp(applySooktaSafetyFloors(raw, input), 1, 15)
  return breakdown(A, B, raw, final, risk(final))
```

### D.3 Lifting

```text
function lifting(input):
  ref = input.gender == female ? 20 : 25
  HM = clamp(25/max(input.H,25), 0.7, 1)
  VM = clamp(1-0.003*abs(input.V-75), 0.7, 1)
  FM = frequencyMultiplier(input.frequency)
  DM = distanceMultiplier(input.distance)
  RWL = ref*HM*VM*FM*DM
  LI = RWL > 0 ? input.load/RWL : 99
  return mapLiftingIndex(LI)
```

### D.4 Push/pull

```text
function pushPull(input):
  initialLimit = female ? 20 : 25
  sustainLimit = female ? 12 : 15
  ratio = max(input.initialForce/initialLimit,
              input.sustainForce/sustainLimit)
  return mapForceRatio(ratio)
```

### D.5 Daily trend

```text
function predict(records):
  ordered = sortByDate(records)
  if ordered.length < 7:
    return insufficient(probability=0)
  window = last7(ordered)
  features = normalizeResearchFeatures(window)
  pReba = sigmoid(beta0Reba + dot(betaReba, features))
  pIso = sigmoid(beta0Iso + dot(betaIso, features))
  count = numberOfRebaHighOrVeryHigh(window)
  level = count<=1 ? low : count<=3 ? watch : count<=5 ? high : critical
  return report(level, max(pReba,pIso), researchTrained=false)
```

## ภาคผนวก E Requirement-Class-Test-Guideline Matrix

| Requirement | Screen/Service | Class/Method | Automated test | UAT/Config | Guideline | Status |
|---|---|---|---|---|---|---|
| first run แยก returning user | Splash/Onboarding | `restore`, startup route | widget/app-state | iPhone 12 ก.ค. | app design | ผ่าน |
| เกษตรกรหลายคนและ avatar | Farmer Manager | farmer CRUD | farmer avatar test | iPhone 12 ก.ค. | requirement | ผ่าน |
| draft แยก farmer/activity/date | Evaluation Menu/Form | `_draftKey`, save/restore | draft state/flow | iPhone 12 ก.ค. | data integrity | ผ่าน |
| 4 มุมและ pose พร้อม | Evaluation Form | `AssessmentReadiness` | readiness/required-data | simulator 19 ก.ค. | capture protocol | ผ่าน simulated |
| หนึ่งบุคคลต่อภาพ | Evaluation Form | `MultiPersonPoseDetector` | detector/ML tests | iPhone 12 ก.ค. | safety gate | ผ่าน |
| REBA pose screening | Evaluation Form | `analyzeRebaPose`, REBA | calculator/ML tests | UAT บางส่วน | REBA/MoveNet | Sookta adaptation |
| งานยก/ขน | Evaluation Form | `calculateLiftingRisk` | calculator tests | simulated | ISO 11228-1 | สูตรย่อ |
| งานดัน–ดึง | Evaluation Form | `calculatePushPullRisk` | calculator tests | simulated | ISO 11228-2 | สูตรย่อ |
| XGBoost guardrail | Evaluation Form | predictor/guardrail | ML end-to-end | host runtime | XGBoost/ONNX | research-assisted |
| คำแนะนำ 4 หมวด | Initial Risk | recommendations | recommendation/UI | iPhone 12 ก.ค. | ILO/ISO mapping | ผ่าน |
| production result no bypass | Form→Initial Risk | `canAnalyze`, `_analyze` | production config | simulator 19 ก.ค. | release requirement | physical rerun ค้าง |
| history และ daily trend | History/Daily | save/predict | persistence/daily/history | iPhone 12 ก.ค. | Logistic Regression | trend ผ่าน; model template |
| export assessment/training | Result/Profile | export services | export tests | iPhone 12 ก.ค. | research protocol | ผ่าน; sensitive CSV |
| portrait-only iOS/Android | platform config | plist/manifest | portrait config | iPhone + emulator | UI requirement | ผ่าน config |
| iOS/Android UI parity | shared Flutter UI | widgets/theme | parity test | simulator/emulator | UI requirement | physical Android ค้าง |
| Store version 2.1.0 | build pipeline | pubspec/artifact metadata | store version test ต้องอัปเดต | ยังไม่มี artifact 2.1.0 ใน snapshot | release control | ต้องสร้าง/ตรวจ |

## ภาคผนวก F Source Code Index

| Area | Production source | Regression evidence |
|---|---|---|
| Bootstrap/telemetry | `lib/main.dart`; `firebase_telemetry_service.dart` | widget/full suite |
| Navigation | `lib/app/sookta_app.dart`; `route_error_screen.dart` | widget/flow tests |
| State/persistence | `lib/app/app_state.dart` | app-state/draft tests |
| Domain contracts | `assessment_session.dart`; `evaluation_models.dart`; `pose_models.dart` | serialization/service tests |
| Media readiness | `assessment_readiness.dart`; `evaluation_form_screen.dart` | readiness/required-data tests |
| Image persistence | `local_image_store.dart` | draft state tests |
| Video frames | `video_frame_extraction_service.dart`; native channel | image-slot/device UAT |
| Pose/person | `pose_estimation_service.dart`; `multi_person_pose_detector.dart` | detector/ML tests |
| REBA/ISO-style | `ergo_calculator.dart` | calculator tests |
| ML schema/predictor | `core/ergonomics_risk_prediction/`; `assets/models/` | ergonomic/ML end-to-end |
| Recommendation | `risk_recommendation_service.dart` | recommendation tests |
| Economic impact | `economic_impact_service.dart` | economic impact tests |
| Daily trend | `daily_injury_prediction_service.dart`; daily asset | daily/ML tests |
| Assessment export | `assessment_export_service.dart` | assessment export tests |
| Training export | `training_data_export_service.dart` | training export tests |
| iOS | `ios/Runner/Info.plist`; `ios/Podfile`; Xcode project | plist/portrait/store evidence |
| Android | manifest; `android/app/build.gradle` | portrait/parity/store evidence |

## เอกสารอ้างอิง

Chen, T., & Guestrin, C. (2016). XGBoost: A scalable tree boosting system.
In *Proceedings of the 22nd ACM SIGKDD International Conference on Knowledge
Discovery and Data Mining* (pp. 785–794).
https://doi.org/10.1145/2939672.2939785

Google for Developers. (2025, August 25). *Logistic regression*.
https://developers.google.com/machine-learning/crash-course/logistic-regression

Hignett, S., & McAtamney, L. (2000). Rapid entire body assessment (REBA).
*Applied Ergonomics, 31*(2), 201–205.
https://doi.org/10.1016/S0003-6870(99)00039-3

International Labour Organization. (2014). *Ergonomic checkpoints in
agriculture: Practical and easy-to-implement solutions for improving safety,
health and working conditions in agriculture* (2nd ed.).
https://www.ilo.org/resource/training-material/ergonomic-checkpoints-agriculture-practical-and-easy-implement-solutions

International Organization for Standardization. (2007a).
*ISO 11228-2:2007 Ergonomics—Manual handling—Part 2: Pushing and pulling*.
https://www.iso.org/standard/26521.html

International Organization for Standardization. (2021).
*ISO 11228-1:2021 Ergonomics—Manual handling—Part 1: Lifting, lowering and
carrying*. https://www.iso.org/standard/76820.html

International Organization for Standardization. (2026).
*ISO 11228-3:2026 Ergonomics—Manual handling—Part 3: Handling of low loads at
high frequency*. https://www.iso.org/standard/11228-3

Microsoft. (n.d.). *ONNX Runtime mobile*.
https://onnxruntime.ai/docs/get-started/with-mobile.html

TensorFlow. (n.d.). *MoveNet: Ultra fast and accurate pose detection model*.
https://www.tensorflow.org/hub/tutorials/movenet

หมายเหตุ: source code ของ Sookta 2.1.0 ยังมีข้อความอ้างอิง
ISO 11228-3:2007 เดิมเพื่อ trace ผลย้อนหลัง แต่ ISO ระบุว่าฉบับนั้นถูกถอน
เมื่อ 8 พฤษภาคม 2026 และแทนที่ด้วย ISO 11228-3:2026 การเปลี่ยน registry
ในรอบถัดไปต้องทบทวน mapping และคำแนะนำกับฉบับใหม่ก่อนอ้างใช้ในงานวิจัย
