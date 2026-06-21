# Sookta Daily Outcome Label Template

เอกสารนี้อธิบายไฟล์ Excel สำหรับให้ทีมวิจัยกรอก outcome labels เพื่อใช้ train และทดสอบ Logistic Regression สำหรับการทำนายความเสี่ยงจากประวัติการประเมินรายวันของชาวสวน

## ขอบเขตการใช้งานและความปลอดภัย

ผลประเมินในแอปใช้เพื่อการสื่อสารความเสี่ยง การเรียนรู้ และการเก็บข้อมูลวิจัยเท่านั้น ไม่ใช่การวินิจฉัยทางการแพทย์หรือการยืนยันการบาดเจ็บ หากมีอาการปวดรุนแรงหรือผิดปกติ ควรปรึกษาบุคลากรทางการแพทย์หรือผู้เชี่ยวชาญด้านอาชีวอนามัย

## ไฟล์หลัก

- Excel template: `data/research/templates/daily_injury_outcome_label_template.xlsx`
- Converter: `tools/research_dataset/convert_daily_outcome_labels.py`
- Converter unit test: `tools/research_dataset/convert_daily_outcome_labels_test.py`
- Example fixture CSV: `data/research/templates/daily_injury_outcome_example_fixture.csv`
- Example fixture JSON: `data/research/templates/daily_injury_outcome_example_fixture.json`

## Outcome Label ที่ควรใช้

โมเดลนี้เป็น binary Logistic Regression ดังนั้น label หลักควรเป็นค่า 0 หรือ 1:

| Field | ค่า | ความหมาย |
| --- | --- | --- |
| `requires_medical_treatment_within_7_days` | `0` | หลังจากประเมินครบ 7 transaction แล้ว ไม่พบการพบแพทย์ ไม่พบการรักษา และไม่มีอาการ MSD ที่ทีมวิจัยเห็นว่าต้องติดตามรักษา |
| `requires_medical_treatment_within_7_days` | `1` | หลังจากประเมินครบ 7 transaction แล้ว พบอย่างน้อยหนึ่งเงื่อนไข เช่น พบแพทย์ ต้องรักษา มีอาการ MSD ระดับ moderate/severe หรือมีวันหยุดงานที่สัมพันธ์กับอาการจากการทำงาน |

คอลัมน์ evidence เช่น `medical_visit_within_7_days`, `treatment_required_within_7_days`, `msd_symptom_present`, `msd_symptom_location`, `msd_symptom_severity`, `lost_workdays_7d`, `direct_medical_cost_thb` และ `productivity_loss_thb` ไม่ใช่ target โดยตรง แต่ใช้ตรวจสอบว่าทำไมแถวนั้นจึง label เป็น 0 หรือ 1

## หน่วยข้อมูลต่อหนึ่งแถว

1 row ใน sheet `Training_Data` = ชาวสวน 1 คน + หน้าต่างข้อมูล 7 transaction

`transaction_count` ต้องเป็น 7 เสมอ เพราะโมเดลนี้ออกแบบให้ดูประวัติการประเมินครบ 7 รายการก่อนทำนายว่ามีความเสี่ยงที่จะเจ็บป่วยจนต้องรักษาหรือไม่

## Feature Columns

ค่าต่อไปนี้ต้องเป็นตัวเลข normalized ในช่วง 0.0 ถึง 1.0 เพื่อให้ตรงกับ logic ในแอป:

| Field | ความหมาย |
| --- | --- |
| `avg_score_before_norm` | ค่าเฉลี่ยคะแนนความเสี่ยงก่อนเลือกคำแนะนำใน 7 transaction |
| `max_score_before_norm` | คะแนนสูงสุดก่อนเลือกคำแนะนำใน 7 transaction |
| `avg_score_after_norm` | ค่าเฉลี่ยคะแนนหลังเลือกคำแนะนำ |
| `high_or_above_days_norm` | สัดส่วนวันที่มีความเสี่ยง high หรือ veryHigh |
| `very_high_days_norm` | สัดส่วนวันที่มีความเสี่ยง veryHigh |
| `no_improvement_days_norm` | สัดส่วนวันที่คะแนนหลังคำแนะนำไม่ลดลง |
| `trunk_high_days_norm` | สัดส่วนวันที่ส่วนลำตัว/หลังมีความเสี่ยงสูง |
| `neck_or_upper_limb_high_days_norm` | สัดส่วนวันที่คอ แขน ไหล่ หรือข้อมือมีความเสี่ยงสูง |
| `iso_days_norm` | สัดส่วนวันที่กิจกรรมต้องใช้ ISO 11228-1 ร่วมกับ REBA |
| `avg_economic_loss_norm` | ค่า economic impact เฉลี่ยที่ normalize แล้ว |
| `repeated_same_activity_norm` | สัดส่วนการทำกิจกรรมซ้ำในช่วง 7 transaction |
| `recent_score_slope_norm` | แนวโน้มคะแนนในช่วงล่าสุด ยิ่งสูงยิ่งมีแนวโน้มแย่ลง |

## วิธีแปลงเป็น Training/Test Fixture

แปลงข้อมูลจริงเป็น CSV/JSON:

```bash
python tools/research_dataset/convert_daily_outcome_labels.py \
  data/research/templates/daily_injury_outcome_label_template.xlsx \
  --output-csv data/research/extracted/daily_injury_outcome_training_ready.csv \
  --output-json data/research/extracted/daily_injury_outcome_training_ready.json
```

แปลงแถวตัวอย่างเพื่อใช้เป็น fixture ทดสอบ:

```bash
python tools/research_dataset/convert_daily_outcome_labels.py \
  data/research/templates/daily_injury_outcome_label_template.xlsx \
  --include-examples \
  --output-csv data/research/templates/daily_injury_outcome_example_fixture.csv \
  --output-json data/research/templates/daily_injury_outcome_example_fixture.json
```

รัน unit test ของ converter:

```bash
python -m unittest tools.research_dataset.convert_daily_outcome_labels_test
```

## กติกาสำคัญก่อนนำไป Train

- ใช้ `row_type=research` สำหรับข้อมูลจริงเท่านั้น
- แถว `row_type=example` จะถูกข้ามโดย default เพื่อไม่ให้ปนกับข้อมูลจริง
- `transaction_count` ต้องเป็น 7
- target ต้องเป็น 0 หรือ 1 เท่านั้น
- feature ทั้ง 12 ตัวต้องเป็น numeric และอยู่ในช่วง 0.0 ถึง 1.0
- ถ้า label มีความไม่แน่นอน ให้กรอก `label_confidence=low` เพื่อให้สามารถคัดออกจาก training run ได้
