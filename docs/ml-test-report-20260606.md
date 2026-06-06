# Sookta ML Test Report - 2026-06-06

## 1. วัตถุประสงค์

รายงานนี้สรุปการทดสอบระบบ Machine Learning ของแอป Sookta หลังแยกบทบาทของโมเดลเป็น 2 กลุ่มหลัก:

1. **REBA + ISO11228 risk assessment layer** ใช้ MoveNet features, REBA/ISO calculation, XGBoost ONNX และ risk guardrail เพื่อประเมินความเสี่ยงจากท่าทาง/งานจริง
2. **Daily injury prediction layer** ใช้ Logistic Regression แยกต่างหาก เพื่อทำนายจากประวัติการประเมิน 7 transactions ล่าสุดของชาวสวน

ขอบเขตคำว่า “ทุก case ที่เป็นไปได้” ในรายงานนี้หมายถึงการครอบคลุมทุกกลุ่มเงื่อนไขสำคัญที่เกิดขึ้นได้ในระบบจริงและใน code path หลัก ไม่ใช่การ enumerate ค่า `double` ทุกค่าของ feature vector 51 มิติซึ่งมีจำนวนไม่สิ้นสุด

## 2. สรุปผล

**สถานะรวม: PASS**

- `flutter analyze`: PASS
- `flutter test`: PASS, 53 tests
- Host ML comprehensive suite: PASS, 18 ML cases
- iPhone device ML inference: PASS, 1 integration case
- ONNX/XGBoost inference บน iPhone จริง: PASS
- Logistic Regression daily prediction: PASS
- REBA/ISO combined-risk guardrail: PASS
- Invalid input / malformed feature / missing pose handling: PASS

## 3. Model Artifacts ที่ทดสอบ

| Artifact | Path | Role | สถานะ |
|---|---|---|---|
| MoveNet Thunder TFLite | `assets/ml/movenet_thunder.tflite` | อ่าน keypoints จากรูปภาพ | Included in app asset; invalid image path tested |
| Joint feature schema | `assets/models/joint_feature_schema.json` | กำหนด 51 MoveNet features | PASS |
| XGBoost ONNX | `assets/models/xgboost_model.onnx` | REBA+ISO risk predictor บน device | PASS on iPhone |
| XGBoost metadata | `assets/models/xgboost_model_metadata.json` | ระบุ version/source/feature count | Verified by schema/model loading path |
| Logistic weights | `assets/models/logistic_weights.json` | Logistic asset สำหรับ feature validation / legacy predictor path | PASS |
| Daily injury LR | `assets/ml/daily_injury_logistic_model.json` | ทำนายจาก 7 transactions ล่าสุด | PASS |
| Risk alert model | `assets/ml/risk_alert_models.json` | Baseline LR+XGB-compatible guardrail | PASS |

## 4. Test Case Matrix

Test case matrix ชุดนี้ถูกจัดทำก่อนรัน automated test โดยแบ่งตาม code path ที่มีผลต่อความถูกต้องของ ML ได้แก่ feature schema, preprocessing, model lifecycle, model validation, inference, risk mapping, daily prediction, REBA/ISO guardrail และ invalid-input handling

| ID | Area | Case | Expected Result | Actual Result |
|---|---|---|---|---|
| ML-001 | Feature schema | โหลด canonical MoveNet schema | `featureCount = 51`, first/last feature ถูกต้อง | PASS |
| ML-002 | Feature extraction | clamp x/y/score และเติม missing joints เป็น 0 | ได้ 51 features, ค่าถูก clamp | PASS |
| ML-003 | XGBoost lifecycle | เรียก predict ก่อน `initModel()` | throw `ModelLoadException` | PASS |
| ML-004 | XGBoost host runtime | host runner ไม่มี ONNX dylib | test ไม่ fail และบันทึก limitation | PASS |
| ML-005 | XGBoost validation | empty/short/NaN features | throw `InvalidJointFeaturesException` เมื่อ runtime พร้อม | PASS |
| ML-DEVICE-001 | XGBoost device inference | โหลด ONNX และ predict บน iPhone จริง | probability อยู่ใน 0..1 และ invalid length ถูก reject | PASS |
| ML-006 | Logistic asset | โหลด `logistic_weights.json` และ predict valid 51 features | probability 0..1 | PASS |
| ML-007 | Logistic threshold | low / medium / high / veryHigh boundary groups | map risk level ถูกต้อง | PASS |
| ML-008 | Logistic validation | short / Infinity features | throw `InvalidJointFeaturesException` | PASS |
| ML-009 | Logistic preprocessing | feature engineering 51 -> 71 | inference สำเร็จ probability 0..1 | PASS |
| ML-010 | Daily LR insufficient | 0 ถึง 6 transactions | level = insufficient | PASS |
| ML-011 | Daily LR level mapping | low / watch / high / critical groups | map level ถูกต้อง | PASS |
| ML-012 | Daily LR windowing | records ไม่เรียง + มี 8 records | sort และใช้ล่าสุด 7 records | PASS |
| ML-013 | Daily LR actual asset | 7 วัน score สูง + trunk high | `requiresCareAlert = true` | PASS |
| ML-014 | Risk alert | REBA / lifting / push-pull job types | probability 0..1 และ feature importance มีค่า | PASS |
| ML-015 | Pose -> REBA | deep bending synthetic pose | trunk score = 4, neck score = 2, trunk high, recommendation ตรงหลัง | PASS |
| ML-016 | REBA+ISO combined | REBA และ ISO มี risk คนละมิติ | combined risk ไม่ต่ำกว่า risk สูงสุดของแต่ละมิติ | PASS |
| ML-017 | Lifting dimensions | pose ใช้งานได้ + pose missing | ได้ H/V ในช่วงกำหนด และ missing เป็น null | PASS |
| ML-018 | Invalid image | bytes ไม่ใช่รูปภาพ | `estimatePoseFromFile()` คืน `null` | PASS |

## 5. ผลลัพธ์ Device Inference บน iPhone จริง

รันคำสั่ง:

```sh
/usr/bin/env COPYFILE_DISABLE=1 /Users/kpc/develop/flutter/bin/flutter test integration_test/ml_device_inference_test.dart -d 00008030-0008788421F3802E
```

ผลลัพธ์:

```text
ML_DEVICE_RESULT: xgNeutral=0.7796 xgBent=0.7177 lrNeutral=0.7074 lrBent=0.9672
00:02 +1: All tests passed!
```

การตีความ:

- XGBoost ONNX สามารถโหลดและ infer บน iPhone จริงได้
- Logistic Regression asset สามารถ infer บน iPhone จริงได้
- invalid feature length ถูก reject หลัง ONNX runtime init แล้ว
- ค่า probability อยู่ในช่วง 0.0 ถึง 1.0 ตาม contract

หมายเหตุสำคัญ: ใน host `flutter test` บน macOS ไม่สามารถโหลด `libonnxruntime.1.15.1.dylib` ได้ จึงไม่ถือว่าเป็น app bug เพราะ iOS runtime โหลดผ่าน CocoaPods/embedded framework แทน และ device integration test ยืนยันแล้วว่า ONNX ทำงานบน iPhone จริง

## 6. Automated Test Commands

```sh
/Users/kpc/develop/flutter/bin/flutter analyze
/Users/kpc/develop/flutter/bin/flutter test
/Users/kpc/develop/flutter/bin/flutter test test/ml_end_to_end_comprehensive_test.dart
/usr/bin/env COPYFILE_DISABLE=1 /Users/kpc/develop/flutter/bin/flutter test integration_test/ml_device_inference_test.dart -d 00008030-0008788421F3802E
```

## 7. Coverage Summary

ครอบคลุมแล้ว:

- Model artifact loading
- Feature schema correctness
- MoveNet feature extraction and clamping
- XGBoost ONNX lifecycle and device inference
- Logistic Regression asset inference
- Logistic Regression threshold mapping
- Daily 7-transaction prediction
- REBA + ISO combined-risk rule
- Deep bending trunk-risk case
- Lifting H/V estimation from pose
- Invalid image / invalid features / missing pose handling

ยังไม่ครอบคลุมด้วย automation ชุดนี้:

- ความถูกต้องเชิงสถิติของโมเดลกับ field-labeled dataset ใหม่จากทีมวิจัย
- Accuracy, precision, recall, confusion matrix จาก labeled holdout set ล่าสุด
- การทดสอบรูปจริงจำนวนมากแบบ batch จาก Drive/media catalog
- การฟังคุณภาพเสียง TTS ด้วยหูคนจริง
- Camera/gallery native permission flow ระหว่างถ่ายรูปจริง

## 8. Risk And Recommendation

### 8.1 Reliability ที่ยืนยันได้

จากการทดสอบนี้ ยืนยันได้ว่า **ระบบ ML pipeline ในแอปทำงานครบตาม technical contract**:

- input ถูก validate
- model assets โหลดได้
- device inference ทำงาน
- output probability อยู่ในช่วงที่ถูกต้อง
- risk mapping ทำงานตาม threshold
- daily prediction ใช้ 7 transactions ล่าสุดจริง
- deep bending ไม่ถูกลดเป็น arm-only risk ใน REBA logic

### 8.2 Reliability ที่ยังต้องพิสูจน์ด้วยข้อมูลวิจัย

ยังไม่สามารถสรุปได้ว่าโมเดล “แม่นยำทางวิจัย” จนถึงระดับ production clinical/ergonomic validity หากยังไม่มี labeled test set ที่แยกจาก training set อย่างชัดเจน ต้องให้ทีมวิจัยส่งข้อมูลต่อไปนี้:

- รูป/วิดีโอจริงพร้อม label REBA score
- ค่า ISO11228-1 ของงานยก/ถือ/ขนย้าย
- activity stage และ specific task
- treatment / medical cost / lost workdays label สำหรับ daily Logistic Regression
- holdout split ที่ไม่ซ้ำกับ training data

### 8.3 Priority ถัดไป

1. ทำ batch evaluation กับ dataset จริงจากทีมวิจัย
2. สร้าง confusion matrix แยก REBA และ ISO11228
3. เทียบ predicted score กับ worksheet/manual assessment
4. เพิ่ม report export สำหรับ ML audit ต่อ transaction
5. ตั้ง acceptance threshold เช่น macro F1, high-risk recall และ false-low-risk rate

## 9. Files Added

| File | Purpose |
|---|---|
| `test/ml_end_to_end_comprehensive_test.dart` | Host comprehensive ML unit/integration-style tests |
| `integration_test/ml_device_inference_test.dart` | Real-device ONNX + Logistic inference test |
| `docs/ml-test-report-20260606.md` | This report |
| `docs/Sookta_ML_Test_Report_20260606.docx` | Word version of this report |
