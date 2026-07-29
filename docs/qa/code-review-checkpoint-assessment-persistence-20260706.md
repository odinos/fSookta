# Code Review Checkpoint: Assessment Persistence

Date: 2026-07-06
Branch: `codex/ios-real-integrations`
Scope: Code requirement item 1, "บันทึกข้อมูลประเมินให้ครบและไม่สูญหาย"

## Review Goal

ตรวจเฉพาะการปรับปรุง flow บันทึกผลประเมินให้เขียนข้อมูลลง storage สำเร็จก่อนระบบถือว่าบันทึกแล้ว และไม่ให้ผู้ใช้ส่งออกไฟล์ก่อน record พร้อมใช้งาน

## Files To Review First

1. `lib/app/app_state.dart`
   - `saveEvaluation()` เปลี่ยนเป็น async และรอ `_persist()`
   - แยก `_createEvaluationRecord()` เพื่อให้การสร้าง record อ่านง่ายขึ้น
   - เพิ่ม rollback ถ้า persist ไม่สำเร็จ เพื่อไม่ทิ้ง history ใน memory แบบไม่ตรงกับ storage

2. `lib/screens/main/final_result_screen.dart`
   - เพิ่ม `_saveResultOnce()` เพื่อกันการบันทึกซ้ำ
   - รอผล `saveEvaluation()` ก่อนเปิดให้ export
   - ส่ง `afterAssessmentBreakdown` เข้า record ให้ครบ

3. `lib/screens/onboarding/splash_screen.dart`
   - capture/research route รอ `ensureResearchCaptureData()` ให้เสร็จก่อนเปลี่ยนหน้า

## Tests To Review

1. `test/app_state_evaluation_persistence_test.dart`
   - regression test หลัก: save แล้วสร้าง state ใหม่ จากนั้น restore ต้องได้ history record กลับมา

2. `test/daily_prediction_screen_test.dart`
   - ปรับ test fixture ให้ await async save และ mock `SharedPreferences`

3. `test/final_revision_training_capture_test.dart`
   - ปรับ test fixture ให้ await async save
   - ปรับ assertion ให้ตรงกับ UI ปัจจุบันและไม่ fragile จาก scroll position

## Verification Run

Command:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/app_state_evaluation_persistence_test.dart test/daily_prediction_screen_test.dart test/final_result_breakdown_capture_test.dart test/economic_impact_compare_capture_test.dart test/final_revision_training_capture_test.dart test/assessment_export_service_test.dart test/training_data_export_service_test.dart
```

Result:

```text
13 tests passed
```

## Review Notes

- ยังไม่ควร commit dirty tree ทั้งหมด เพราะมีไฟล์อื่นจำนวนมากที่ไม่เกี่ยวกับ item 1 ปนอยู่
- ถ้าต้องทำ commit เพื่อ checkpoint ควร commit เฉพาะไฟล์ในรายการด้านบน และตรวจ diff รายไฟล์ก่อน
- `flutter analyze` เคยรันแล้วแต่ค้างนานโดยไม่มี output เพิ่ม จึงยังไม่นับว่า analyze ผ่าน

## Suggested Review Order

1. อ่าน `test/app_state_evaluation_persistence_test.dart` ก่อน เพื่อเข้าใจ behavior ที่ต้องการ
2. อ่าน `saveEvaluation()` และ `_createEvaluationRecord()` ใน `app_state.dart`
3. อ่าน `_saveResultOnce()` ใน `final_result_screen.dart`
4. ตรวจ UI export button ว่าถูก disable จนกว่า `savedRecord` พร้อม
5. ตรวจ `splash_screen.dart` เฉพาะ capture route
6. รัน test command ด้านบนซ้ำก่อน commit
