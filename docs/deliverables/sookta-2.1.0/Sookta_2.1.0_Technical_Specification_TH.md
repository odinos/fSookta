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
Application 2.1.0 ในระดับที่ทีมพัฒนาสามารถตรวจสอบ implementation และทีมวิจัย
สามารถแยกส่วนที่อ้างอิง guideline ออกจากส่วนที่เป็น application adaptation
หรือ research template ได้

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

## 5. State, Persistence and Schema Migration

<!-- DOCX_DIAGRAM:restore-migration -->

## 6. Domain Models and Serialization Contracts

## 7. Media Ingestion and Quality Gates

## 8. Assessment Processing Pipeline

<!-- DOCX_DIAGRAM:assessment-sequence -->

## 9. Algorithm Specifications

## 10. Machine Learning Assets and Inference Contracts

<!-- DOCX_DIAGRAM:model-contracts -->

## 11. Recommendation Engine

## 12. Draft, History and Export Contracts

## 13. Error Handling, Telemetry and Fallback

## 14. Platform Configuration

## 15. Test Architecture and Traceability

## 16. Build, Versioning, Signing and Store Artifacts

## 17. Security, Privacy and Known Limitations

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

## ภาคผนวก E Requirement-Class-Test-Guideline Matrix

## ภาคผนวก F Source Code Index

## เอกสารอ้างอิง
