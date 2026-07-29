# Sookta UI Comparison Screenshots

วันที่จัดทำ: 26/06/2026

ชุดภาพนี้รวบรวมหน้าจอในแอปที่มีการเปรียบเทียบคะแนนก่อน/หลังปรับปรุง หรือผลกระทบก่อน/หลังปรับปรุง เพื่อใช้เป็นหลักฐานประกอบเอกสารวิจัยและ QA หลังปรับ UI ให้เลิกใช้การสื่อสารแบบ probability

## รายการภาพหน้าจอ

| ลำดับ | หน้าในแอป | ไฟล์ภาพ | แหล่งที่มา | สิ่งที่เห็นในภาพ | สถานะ probability |
|---:|---|---|---|---|---|
| 1 | หน้าแรก - ภาพรวมความเสี่ยงล่าสุด | `comparison_screenshots/01_iphone_home_latest_risk_before_after_no_probability.png` | iPhone จริงผ่าน Xcode Devices and Simulators | การ์ดล่าสุดแสดงกิจกรรมและคะแนน `ก่อน 8 หลัง 4` | ไม่พบคำว่า probability |
| 2 | ผลการประเมินเบื้องต้น - คะแนนหลังทำตามคำแนะนำ | `comparison_screenshots/02_initial_result_after_score_preview.jpg` | ภาพจากแอปในชุด manual เดิม | หลังเลือกคำแนะนำ ระบบแสดงคะแนนหลังปรับและผลกระทบประมาณการ พร้อมปุ่มดูผลหลังปรับปรุง | ไม่พบคำว่า probability |
| 3 | บันทึกและสรุปผลสำเร็จ - ผลลัพธ์หลังปรับปรุง | `comparison_screenshots/03_final_result_before_after_summary.jpg` | ภาพจากแอปในชุด manual เดิม | แสดงคะแนน `ก่อนปรับ 7` ไป `หลังปรับ 5` พร้อมสรุปผลกระทบที่ลดลง | ไม่พบคำว่า probability |
| 4 | ผลตรวจย้อนหลัง - รายการประวัติ | `comparison_screenshots/04_history_list_before_after_row.jpg` | ภาพจากแอปในชุด manual เดิม | รายการประวัติแสดง `ก่อน 7 -> หลัง 5` และจำนวนเงินที่อาจลดลง | ไม่พบคำว่า probability |
| 5 | รายละเอียดผลตรวจย้อนหลัง | `comparison_screenshots/05_history_detail_before_after_economic_impact.jpg` | ภาพจากแอปในชุด manual เดิม | แสดงคะแนน `ก่อน 7` และ `หลัง 5` แยกเป็นป้ายคะแนน พร้อมผลกระทบก่อนปรับและจำนวนเงินที่อาจลดลง | ไม่พบคำว่า probability |
| 6 | Logistic Regression / Trend 7 ครั้งล่าสุด | `comparison_screenshots/06_iphone_logistic_trend_before_after_parallel_lines_20260626.png` | iPhone จริงผ่าน Xcode Devices and Simulators | กราฟ 7 ครั้งล่าสุดแสดงเส้น `ก่อนปรับ` และ `หลังปรับ` แยกกันเป็นสองเส้นขนาน สีเขียว/ส้ม | ไม่พบคำว่า probability |

## หมายเหตุสำหรับเอกสารวิจัย

- ภาพที่ 1 เป็นภาพจาก iPhone จริงที่ถ่ายด้วย Xcode Devices and Simulators
- ภาพที่ 6 เป็นภาพจาก iPhone จริงหลังแก้หน้า Logistic Regression / Trend ให้แสดงเส้น before/after แยกกัน
- ภาพที่ 2-5 เป็นภาพหน้าจอจากแอปที่มีอยู่ในชุดเอกสาร/manual เดิม ใช้เพื่อให้ครอบคลุมทุกหน้าที่มีการเปรียบเทียบใน flow
- หน้าที่ตรวจพบจากโค้ดว่ามีการเปรียบเทียบโดยตรง ได้แก่ `home_tab.dart`, `initial_risk_screen.dart`, `final_result_screen.dart`, `history_tab.dart`, และ `history_detail_screen.dart`
- ข้อความในภาพทั้งหมดสื่อสารเป็นคะแนนก่อน/หลังหรือผลกระทบก่อน/หลัง ไม่ใช้คำว่า probability ใน UI ที่ส่งมอบชุดนี้
