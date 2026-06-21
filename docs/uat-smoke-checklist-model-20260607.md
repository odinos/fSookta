# รายงาน Smoke Test และ UAT รอบ Checklist + Model Separation

วันที่ทดสอบ: 2026-06-07 09:45 ICT  
โปรเจกต์: Sookta / fSookta Flutter  
Branch: `codex/ios-real-integrations`  
Base commit: `1b3bbb8`  
App version: `1.1.2+10`  
ผู้จัดทำรายงาน: Codex

## 1. สรุปภาพรวม

รอบนี้เป็นการตรวจหลังปรับปรุงชุดใหญ่ 2 ส่วนหลัก

1. Checklist ใหม่จากผู้ทดสอบ: เพิ่มการแสดงผลมุมท่าทาง, REBA Score Breakdown, Worst Posture, Activity/Load/Coupling/Repetition detail, Body Map reason และ Export field สำหรับเจ้าหน้าที่
2. Model Separation: แยกโมเดล REBA + ISO11228-1 ออกจาก Logistic Regression โดยให้ REBA/ISO ใช้ MoveNet + XGBoost ONNX และให้ Logistic Regression ใช้เฉพาะการทำนายแนวโน้มจากประวัติ 7 transaction

ผลโดยรวม: โค้ดและ automated test ผ่าน, Android release artifact พร้อมและผ่าน 16KB ELF alignment, iOS release build ผ่านเมื่อ build จาก clean local tree. แต่ device integration runner ยังมี blocker สำหรับการทดสอบบนเครื่องจริงแบบครบ flow: Android ติด `assembleDebug` ค้างระหว่าง integration test และ iOS ติด Dart VM Service / LLDB attach ระหว่าง device integration test

## 2. สภาพแวดล้อมทดสอบ

| รายการ | ค่า |
|---|---|
| Flutter | `/Users/kpc/develop/flutter/bin/flutter` |
| Repo path | `/Users/kpc/Documents/GitHub/fSookta` |
| Clean iOS build tree | `/private/tmp/fSookta-ios-cleanbuild-20260607` |
| iOS device | iPhone SE, `iPhone12,8`, iOS 26.5, UDID `00008030-0008788421F3802E`, Developer Mode enabled |
| Android device | Samsung SM-S918B, Android 16 API 36, serial `R5CW13JKESA` |
| Timezone | Asia/Bangkok |

## 3. สรุปผลตามประเภทการทดสอบ

| หมวด | ผล | หลักฐาน / หมายเหตุ |
|---|---:|---|
| `flutter analyze` | ผ่าน | `No issues found! (ran in 95.8s)` |
| `flutter test` | ผ่าน | 51 tests passed |
| Android release appbundle | ผ่าน | `build/app/outputs/bundle/release/app-release.aab`, 131,908,325 bytes, built 2026-06-07 08:37 |
| Android 16KB ELF alignment | ผ่าน | [16kb_elf_alignment.txt](/Users/kpc/Documents/GitHub/fSookta/docs/uat_evidence_20260607_checklist_model/android/16kb_elf_alignment.txt) |
| iOS release build no-codesign | ผ่านใน clean tree | `/private/tmp/fSookta-ios-cleanbuild-20260607/build/ios/iphoneos/Runner.app`, 187MB |
| iOS build ใน repo path หลัก | ไม่ผ่าน | ติด resource fork / FileProvider xattr ใน `Documents/GitHub` ไม่ใช่ Dart compile failure |
| iOS full-page smoke บนเครื่องจริง | ผ่านบางส่วน / ไม่จบ | ติดตั้งและเปิดได้, ผ่านหน้า Language TH 2 เคส, ค้างที่ Setup first-run test completion |
| iOS ML device inference | ไม่จบ | ติด Dart VM Service / LLDB attach หลัง launch |
| Android full-page smoke บนเครื่องจริง | ไม่จบ | ติด `Running Gradle task 'assembleDebug'...` นานเกินเวลาทดสอบ |
| Android ML device inference | ไม่จบ | ติด `assembleDebug` จุดเดียวกับ full-page smoke |

## 4. Automated Test ที่ผ่าน

คำสั่ง:

```bash
/Users/kpc/develop/flutter/bin/flutter analyze
/Users/kpc/develop/flutter/bin/flutter test
```

ผลสำคัญจาก test suite:

| กลุ่มทดสอบ | รายละเอียดที่ยืนยันได้ |
|---|---|
| REBA calculation parity | ใช้ official REBA Table A/B/C, deep forward bending ไม่ถูกประเมินเป็น low risk |
| Pose-derived REBA | landmarks จาก MoveNet auto-fill REBA posture scores และ deep bending map ไป trunk risk ไม่ใช่ arm-only risk |
| ISO11228 | lifting / push-pull / combined REBA+ISO เลือกความเสี่ยงที่สูงกว่าตามลักษณะงานจริง |
| Export | CSV/Excel-compatible export มี Thai summary fields, history export และ all-farmer worksheet |
| Daily Logistic Regression | ต้องมี 7 transaction, ใช้เฉพาะ 7 รายการล่าสุด, แยกระดับ low/watch/high/critical |
| XGBoost ONNX host load | โหลด ONNX artifact ได้ใน host runtime และ reject malformed feature vector |
| Invalid image | image bytes ที่อ่าน pose ไม่ได้ return no pose estimate ไม่ควรสร้างตัวเลขประเมินที่ไม่น่าเชื่อถือ |
| Localization | widget test ครอบคลุม onboarding และ farmer manager เมื่อเปลี่ยนภาษา |

## 5. Checklist ใหม่จากผู้ทดสอบ

| Checklist | สถานะ | จุดที่อยู่ในแอป / code |
|---|---:|---|
| แสดงมุมคอ ลำตัว แขน ขา | ทำแล้ว | `PoseRebaFrameAnalysis`, `AssessmentBreakdownCard` |
| วิเคราะห์หลายภาพและเลือก Worst Posture | ทำแล้ว | `poseFrames`, `worstPoseImageIndex`, `_worstFrame()` |
| แสดง REBA Score A/B/C และ final score | ทำแล้ว | `RebaScoreBreakdown`, `calculateRebaScoreBreakdown()` |
| แสดงเหตุผลการให้คะแนน | ทำแล้ว | `AssessmentBreakdownCard`, `assessmentBodyRiskReasons()` |
| Activity Score จากระยะเวลา/ซ้ำ/ถือค้าง | ทำแล้ว | Evaluation Form เพิ่ม duration, repetition, static hold |
| Load Score เป็นช่วง kg | ทำแล้ว | <=5kg = 0, <=15kg = 1, >15kg = 2 |
| Coupling quality | ทำแล้ว | Good/Fair/Poor mapping เป็น +0/+1/+2 |
| Repetition และวันทำงานต่อสัปดาห์ | ทำแล้ว | เพิ่ม `workDaysPerWeek` และ export field |
| Body Map linked recommendation | ทำแล้ว | `BodyRiskMapCard` รับ `bodyRiskReasons` |
| Export field สำหรับเจ้าหน้าที่ | ทำแล้ว | เพิ่ม REBA/ISO detail, per-photo angle, worst posture flag, work days/week |
| ใช้ calibration / raw research data | ทำแล้วบางส่วน | XGBoost retrain จาก REBA-2 + ISO workbook; calibration PDF wired แต่ยัง match raw pose เป็น 0 เพราะยังไม่มี pose rows transplanting/fertilizing |

## 6. Model Separation และความถูกต้องของ flow

### 6.1 REBA + ISO11228-1 posture assessment

| รายการ | ค่า |
|---|---|
| Model | `assets/models/xgboost_model.onnx` |
| Metadata | `assets/models/xgboost_model_metadata.json` |
| Version | `reba-iso-xgboost-onnx-2026-06-07` |
| Input | 51 raw MoveNet joint features |
| Output | REBA + ISO REBA-equivalent risk probability |
| ใช้ Logistic Regression หรือไม่ | ไม่ใช้ใน posture assessment |

Flow ที่ใช้จริง:

1. ผู้ใช้เลือกรูป/ถ่ายรูป
2. MoveNet อ่าน keypoints 17 จุด รวม 51 ค่า (`x`, `y`, `score`)
3. `ErgoCalculator.analyzeRebaPose()` คำนวณมุมคอ ลำตัว ต้นแขน แขนล่าง ขา และ infer REBA input
4. หากมีหลายภาพ ระบบเลือกภาพที่ REBA score สูงสุดเป็น Worst Posture
5. XGBoost ONNX ตรวจเทียบความเสี่ยงจาก MoveNet features
6. ระบบใช้ guardrail โดยไม่ลดความเสี่ยงที่ REBA/ISO คำนวณได้ หาก XGBoost เห็นความเสี่ยงสูงกว่า จะดันผลขึ้นตามระดับนั้น
7. Body Map และคำแนะนำเลือกจากอวัยวะ/ส่วนงานที่เสี่ยงจริง

### 6.2 Daily Logistic Regression

| รายการ | ค่า |
|---|---|
| Model | `assets/ml/daily_injury_logistic_model.json` |
| Version | `daily-injury-logistic-template-2026-06-06` |
| Input | ประวัติประเมินล่าสุด 7 transaction |
| Output | โอกาสต้องติดตามอาการ/รักษา แบ่งเป็น low/watch/high/critical |
| ใช้กับ REBA/ISO หรือไม่ | ไม่ใช้ |
| สถานะ research-trained | ยังไม่ใช่ research-trained เพราะยังไม่มี label ผลลัพธ์การรักษารายวันจากทีมวิจัย |

หมายเหตุ: ใน code ยังมี helper/test สำหรับ legacy Logistic Regression predictor เพื่อความเข้ากันได้และการทดสอบหน่วยย่อย แต่ asset `assets/models/logistic_weights.json` ไม่ถูก package ใน `pubspec.yaml` แล้ว และ flow หน้าประเมินใช้ XGBoost ONNX เป็นตัวตรวจเทียบ posture assessment

## 7. Training Log และข้อจำกัดของโมเดลล่าสุด

อ้างอิงจาก [ml-calibration-training-20260607.md](/Users/kpc/Documents/GitHub/fSookta/docs/ml-calibration-training-20260607.md)

| รายการ | ค่า |
|---|---:|
| Total samples | 388 |
| Training samples | 298 |
| Holdout samples | 90 |
| Risk distribution | high 236, veryHigh 152 |
| Holdout risk accuracy | 0.6667 |
| Holdout combined score MAE | 0.8256 |
| Calibration matched samples | 0 |

ข้อจำกัดสำคัญ:

- ชุดข้อมูลที่ match ได้ตอนนี้มีเฉพาะ high / veryHigh ทำให้ยังไม่ควร claim ว่าโมเดลแยก low / medium ได้แม่นยำในภาคสนาม
- Calibration PDF มีค่าของ transplanting/fertilizing แล้ว แต่ยังไม่ match กับ pose dataset เพราะ raw pose rows ของกิจกรรมนั้นยังไม่ถูก extract เข้ามา
- Logistic Regression daily predictor เป็น template ที่พร้อมใช้งานในแอป แต่ยังต้อง retrain เมื่อทีมวิจัยให้ label ว่า transaction window ใดนำไปสู่การรักษาจริง

## 8. Device UAT Matrix

| Feature / Function | Android SM-S918B | iPhone SE | สรุป |
|---|---:|---:|---|
| เปิดแอป / launch | ยังไม่จบ automation เพราะ `assembleDebug` ค้าง | ติดตั้ง/launch ได้บางส่วนจาก full-page smoke | ต้อง rerun manual หรือแก้ runner |
| Language TH/EN | Pending device smoke | TH language first-run/edit pass ก่อน test ไม่จบ | host/widget test ผ่าน |
| Setup/Profile/Farmer | Pending device smoke | ค้างที่ setup first-run ใน test runner | ต้อง manual verify หลังแก้ runner |
| Evaluation Form | Pending device smoke | Pending device smoke | automated widget/full-page ยังไม่จบ device |
| 4-photo pose analysis | Unit/host test ผ่าน | Pending device smoke | logic ทำแล้ว ต้อง manual/photo UAT ต่อ |
| Worst Posture | Unit/host test ผ่าน | Pending device smoke | logic ทำแล้ว |
| REBA A/B/C breakdown | Unit/host test ผ่าน | Pending device smoke | logic/export ทำแล้ว |
| Body Map + reason | Unit/host test ผ่าน | Pending device smoke | UI ทำแล้ว |
| Export Excel/CSV | Unit test ผ่าน | Pending real share/export manual | ต้อง UAT real device |
| TTS | Pending real-device manual | TTS logs พบ voice `th-TH Kanya` ระหว่าง iOS smoke | ต้องฟังจริงในรอบ manual |
| Camera/Gallery | Pending real-device manual | Pending real-device manual | ต้อง UAT จริง เพราะ simulator/test harness ไม่แทน permission/device camera |
| XGBoost ONNX device inference | Pending เพราะ Android debug runner ค้าง | Pending เพราะ VM Service attach ไม่สำเร็จ | host test ผ่าน, device runner ต้องแก้ |
| Daily Logistic Regression page | Unit test ผ่าน | Pending device smoke | flow อยู่ใน app และ history tab |
| Offline behavior | Unit/host build ผ่าน | Pending real-device manual | ต้องปิด network แล้วลอง camera/gallery/ML/export |

## 9. รายละเอียด Build Artifact

| Platform | Artifact | สถานะ |
|---|---|---|
| Android | `/Users/kpc/Documents/GitHub/fSookta/build/app/outputs/bundle/release/app-release.aab` | Build ผ่าน, 131,908,325 bytes |
| iOS | `/private/tmp/fSookta-ios-cleanbuild-20260607/build/ios/iphoneos/Runner.app` | Build no-codesign ผ่าน, 187MB |

ข้อสังเกต iOS: build จาก repo path หลักใน `Documents/GitHub` ยังติด xattr/resource fork จาก FileProvider metadata ระหว่าง codesign. Clean tree ใน `/private/tmp` build ผ่าน จึงควร archive/store build จาก clean local path ที่ไม่มี FileProvider xattr หรือแก้ metadata ก่อน archive

## 10. Blockers และความเสี่ยงก่อนส่ง Store

| Priority | Blocker / Risk | ผลกระทบ | ข้อเสนอแนะ |
|---|---|---|---|
| P0 | Android integration test ค้างที่ `assembleDebug` | ยังไม่มี smoke result บน Android device ครบทุกหน้า | ตรวจ Gradle debug build แบบ verbose, run `./gradlew :app:assembleDebug --info`, ตรวจ native deps / Gradle daemon |
| P0 | iOS integration runner ไม่เจอ Dart VM Service / LLDB attach | ยังไม่มี ML device inference pass บน iPhone | ใช้ clean tree ต่อ, ตรวจ Xcode Automation permission, ปิด LLDB สำหรับ test runner, ลอง `flutter run --debug` manual |
| P0 | Camera/Gallery/TTS/Export ยังไม่ได้ manual UAT ครบรอบนี้ | เป็น feature ที่ต้องใช้ hardware/permission จริง | ทำ manual checklist บน Android + iPhone หลัง app ติดตั้งจริง |
| P1 | Model holdout accuracy 0.6667 และ class imbalance | ใช้สื่อสารความเสี่ยงได้ แต่ยังไม่ควร claim ความแม่นยำเชิงวินิจฉัย | เพิ่ม low/medium expert-labeled media และ raw pose ของ transplanting/fertilizing |
| P1 | Daily Logistic Regression ยังเป็น template | ยังไม่ใช่ research-trained injury/treatment predictor | รอ label ผลการรักษารายวัน/7 วันจากทีมวิจัยแล้ว retrain |

## 11. สรุปความพร้อม

| ด้าน | สถานะ |
|---|---:|
| Code quality / static analysis | พร้อม |
| Unit / host integration logic | พร้อม |
| Android store artifact | พร้อมระดับ build + 16KB alignment |
| iOS store build path | พร้อมเมื่อใช้ clean tree; repo path หลักยังมี xattr blocker |
| Device UAT ครบทุกหน้า | ยังไม่ครบ |
| Real camera/gallery/TTS/export/offline ML | ยังต้อง rerun manual/device |
| Model separation | ทำแล้วใน flow หลัก |
| Research model credibility | ใช้เป็น research prototype ได้ แต่ยังต้องเพิ่ม label เพื่อ claim ความแม่นยำจริง |

## 12. Next Actions ที่ควรทำทันที

1. แก้/วิเคราะห์ Android `assembleDebug` ที่ค้างด้วย Gradle verbose log
2. รัน Android manual smoke บน SM-S918B หลังติดตั้ง build จริง: language, setup, farmer, camera, gallery, evaluation, result, TTS, export, daily prediction
3. รัน iOS manual smoke จาก clean local path หรือ Xcode Archive path ที่ไม่มี xattr: camera, gallery, TTS, export, offline ML
4. เก็บ screenshot/logcat/device logs เพิ่มใน `docs/uat_evidence_20260607_checklist_model/`
5. เพิ่ม expert-labeled low/medium media และ pose rows ของ transplanting/fertilizing แล้ว retrain XGBoost ONNX
6. ให้ทีมวิจัยส่ง daily treatment labels เพื่อ retrain `assets/ml/daily_injury_logistic_model.json`

