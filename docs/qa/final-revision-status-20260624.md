# SookTa Final Revision Status Report

Date stamped: 2026-06-24
Source workbook: `/Users/kpc/Desktop/SookTa Application – Final Revision Requirements for Field Test and PhD Research.xlsx`

## Summary

- Done: 21
- Partial: 6
- Deferred: 1

## Status Matrix

| ID | Requirement | Status | Evidence / Notes | File or Screenshot |
| --- | --- | --- | --- | --- |
| Task 1 | เพิ่ม wording “กรุณาปรับ…” | Done | หน้าปรับรายละเอียดงานจริงใช้ข้อความ “กรุณาปรับรายละเอียดงานจริง” และ subtitle อธิบายให้เลือกค่าจริงที่ระบบใช้คำนวณ | `lib/screens/main/evaluation_form_screen.dart` |
| Task 2 | Lock ส่วน “น้ำหนักโดยประมาณ” | Done | ตัด dropdown น้ำหนักโดยประมาณออก และแสดง Locked Load Summary ตามเครื่องมือ/น้ำหนักที่เลือก | `lib/screens/main/evaluation_form_screen.dart` |
| Task 3 | เปลี่ยนชื่อคณะ + เอาเบอร์ออก ใช้ Line ID | Done | หน้าติดต่อแสดง Faculty of Allied Health Sciences, Thammasat University และ Line ID 089088 | `lib/screens/main/contact_screen.dart` |
| Task 4 | แนบคู่มือ | Done | Help/Profile มีปุ่มเปิดคู่มือ PDF ชัดเจนผ่าน ManualDocumentService | `assets/documents/sookta_user_manual.pdf` |
| Task 5 | แนบรูปที่ถูกต้อง/ตัวอย่างการถ่ายรูป | Done | เพิ่ม gallery รูปตัวอย่างแยกตามกิจกรรม กดดูภาพเต็มได้ และเพิ่มรูปตัวอย่างภาพที่อ่านง่ายในหน้าประเมิน | `build/manual_screenshots/help_activity_examples_th.png` |
| Task 6 | คำว่า Work Space / ตัดคำว่าสวน | Done | Profile/export ใช้ “พื้นที่ทำงาน (ไม่บังคับ)” และ EN เป็น Work Space | `lib/app/app_text.dart` |
| Task 7 | EN: Transplanting -> Planting | Done | SooktaActivity.transplanting และ localization ใช้คำว่า Planting | `lib/core/models/assessment_session.dart` |
| Task 8 | การแปรผล Logistic Regression ต้องชัดและรับค่าหลังประเมิน | Partial | UI ปัจจุบันเปลี่ยนเป็นการสื่อสาร “แนวโน้มความเสี่ยง” ไม่ใช้ probability/clinical wording; Logistic Regression จริงจาก outcome ยังเป็น future เพราะยังไม่มี outcome labels จริงครบ | `lib/screens/main/daily_prediction_screen.dart` |
| Task 9 | แปลผลให้ง่ายขึ้นสำหรับชาวสวน | Done | Trend/result screens แสดงระดับแนวโน้ม ค่าจริง และคำอธิบายง่าย พร้อม disclaimer | `lib/screens/main/daily_prediction_screen.dart` |
| No10-1 | ปรับหน้า “ทำนายจากประวัติ 7 รายการ” | Done | เปลี่ยนเป็น “แนวโน้มความเสี่ยง 7 ครั้งล่าสุด” / Latest 7 Risk Trend และไม่แสดง probability ในหน้านี้ | `lib/screens/main/daily_prediction_screen.dart` |
| No10-2 | แยก Before Improvement / After Improvement | Done | ประวัติและ export มี REBA/ISO before-after และ reduction metrics | `lib/core/services/assessment_export_service.dart` |
| No10-3 | Trend ใช้ Before Improvement เท่านั้น | Done | DailyInjuryPredictionService ใช้ scoreBefore/riskBefore/chartScores จาก before records | `lib/core/services/daily_injury_prediction_service.dart` |
| No10-4 | ลบค่า % ที่อธิบายที่มาไม่ได้ แสดงเป็นค่าจริง | Done | Trend screen แสดงค่าจริง เช่น average/max/high-risk count/load/frequency ไม่ใช้เปอร์เซ็นต์ probability | `lib/screens/main/daily_prediction_screen.dart` |
| No10-5 | เพิ่ม Trend Level | Done | Trend level คำนวณจาก high-risk count: 0-1 low, 2-3 watch, 4-5 high, 6-7 very high | `lib/core/services/daily_injury_prediction_service.dart` |
| No10-6 | เพิ่มหน้า/ส่วนศักยภาพการลดความเสี่ยง | Done | Initial/final result มี before-after score และ economic impact comparison card | `build/manual_screenshots/economic_impact_compare_card_current_th.png` |
| No10-7 | กำหนดนิยาม Transaction และบันทึก ID/date/time/task | Done | All-history export มี transaction_id, user_id, assessment_date, assessment_time, task_type | `lib/core/services/assessment_export_service.dart` |
| No10-8 | Export CSV / Excel | Partial | ทำ CSV ที่เปิดด้วย Excel ได้ครบฟิลด์วิจัยแล้ว แต่ยังไม่ใช่ native .xlsx โดยตรง | `docs/qa/sample-field-export-p2-20260624.csv` |
| No10-9 | เก็บ Body Region Risk | Done | Export มี neck/shoulder/upper_limb/wrist/back/knee risk และ mapping upper limb จาก arms/wrists | `lib/core/services/assessment_export_service.dart` |
| No10-10 | เก็บ Usability Testing | Partial | Model/export รองรับ time_on_task_seconds, completion_status, assistance_required, error_count แล้ว แต่ยังไม่มี UI เฉพาะให้เจ้าหน้าที่กรอกทุกค่าในแอป | `lib/app/app_state.dart` |
| No10-11 | รองรับ App vs Expert Agreement | Partial | Model/export รองรับ expert_REBA, expert_risk_level, expert_assessment_date, expert_comments แล้ว แต่ยังไม่มี workflow UI สำหรับ expert review/import อย่างสมบูรณ์ | `lib/app/app_state.dart` |
| No10-12 | จัดเก็บภาพประกอบ/Photo ID/Timestamp | Partial | Export สร้าง photo_id/photo_timestamp เมื่อมี pose frames; ยังไม่ได้ export ไฟล์ภาพต้นฉบับหรือระบบจัดการ photo evidence เต็มรูปแบบ | `lib/core/services/assessment_export_service.dart` |
| No10-13 | เพิ่ม Disclaimer | Done | Trend/result/export screens มีข้อความว่าใช้เพื่อสื่อสารความเสี่ยงและงานวิจัย ไม่ใช่การวินิจฉัยโรค | `lib/screens/main/daily_prediction_screen.dart` |
| No10-14 | แนวทาง Logistic Regression ในอนาคต | Deferred | ยังไม่ควรแสดงเป็น predictive model จริงจนกว่าจะมี outcome จริง เช่น MSD_symptom/treatment แล้ว train/validate ใหม่ | `docs/ml-training-data-audit-20260624.md` |
| No10-15 | พร้อม Field Test 28 มิ.ย. Priority 1/2/3 | Partial | P1 หลักเสร็จ, P2 ส่วนใหญ่เสร็จ/บางส่วน, P3 เป็นงานหลังมี outcome จริง เช่น ROC/calibration/predictive dashboard | `docs/final-revision-p1-audit-20260623.md` |
| Noted 1 | Data dictionary | Done | มี Data Dictionary สำหรับ field-test export | `docs/field-test-export-data-dictionary-20260623.md` |
| Noted 2 | Calculation logic REBA/ISO/Trend | Done | มี technical/calculation docs และรายงานนี้รวม flow/status ล่าสุด | `docs/Sookta_Ergonomic_Risk_ML_Process_Technical_Document.docx` |
| Noted 3 | Sample export CSV/Excel 5-10 records | Done | มี sample export CSV P2 และ export tests ครอบคลุม mandatory fields | `docs/qa/sample-field-export-p2-20260624.csv` |
| Noted 4 | Screenshot หลังแก้ UI | Done | มี manual screenshots ล่าสุดรวม help activity examples, trend, export, ISO dropdown, economic compare | `build/manual_screenshots/` |

## Screenshot Evidence

### รูปตัวอย่างตามกิจกรรมใน Help ล่าสุด
![รูปตัวอย่างตามกิจกรรมใน Help ล่าสุด](/Users/kpc/Documents/GitHub/fSookta/build/manual_screenshots/help_activity_examples_th.png)

### กดดูภาพเต็มของกิจกรรมได้
![กดดูภาพเต็มของกิจกรรมได้](/Users/kpc/Documents/GitHub/fSookta/build/manual_screenshots/help_activity_example_full_preview_th.png)

### Dropdown ISO11228-2 / รายละเอียดงานจริง
![Dropdown ISO11228-2 / รายละเอียดงานจริง](/Users/kpc/Documents/GitHub/fSookta/build/manual_screenshots/iso11228_2_dropdowns_closed_th.png)

### หน้าคะแนน REBA/ISO แยกกัน
![หน้าคะแนน REBA/ISO แยกกัน](/Users/kpc/Documents/GitHub/fSookta/build/manual_screenshots/final_result_separate_reba_iso_scores_th.png)

### Trend ใช้ Before Improvement และแสดงค่าจริง
![Trend ใช้ Before Improvement และแสดงค่าจริง](/Users/kpc/Documents/GitHub/fSookta/build/manual_screenshots/final_revision_before_trend_th.png)

### Export training/research data
![Export training/research data](/Users/kpc/Documents/GitHub/fSookta/build/manual_screenshots/final_revision_training_export_th.png)

### Economic impact before/after comparison
![Economic impact before/after comparison](/Users/kpc/Documents/GitHub/fSookta/build/manual_screenshots/economic_impact_compare_card_current_th.png)

## Remaining Work That Still Matters

- Native `.xlsx` export ถ้าผู้วิจัยต้องการไฟล์ Excel จริง ไม่ใช่ CSV ที่เปิดด้วย Excel
- UI/workflow สำหรับกรอก usability testing และ expert assessment ในแอปโดยตรง
- ระบบจัดเก็บ/export photo evidence ต้นฉบับแบบเต็ม ไม่ใช่เพียง photo_id/timestamp จาก pose frames
- Logistic Regression predictive model จริง, ROC, calibration และ predictive dashboard หลังมี outcome labels ภาคสนามเพียงพอ