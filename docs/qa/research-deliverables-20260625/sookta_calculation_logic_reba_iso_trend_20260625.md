# Sookta Calculation Logic: REBA, ISO 11228-1, Before/After, and 7-Record Trend

เอกสารนี้สรุปตรรกะการคำนวณในรูปแบบที่นำไปใส่ใน protocol, methods, หรือ appendix ของโครงการวิจัยได้ โดยใช้คำว่า score/risk level แทน probability เพื่อหลีกเลี่ยงการตีความว่าเป็นโอกาสเกิดโรคเฉพาะบุคคล

## 1. REBA score

REBA ใช้ประเมินความเสี่ยงจากท่าทางการทำงานของทั้งร่างกาย โดยอิงโครงสร้างคะแนน REBA ของ Hignett & McAtamney (2000) และแปลงเป็นระดับความเสี่ยงเพื่อสื่อสารผลในแอป

### Input หลัก

| กลุ่มข้อมูล | ตัวแปรตัวอย่าง | ความหมาย |
|---|---|---|
| Group A posture | trunk_score, neck_score, leg_score | คะแนนท่าทางลำตัว คอ และขา |
| Group B posture | upper_arm_score, lower_arm_score, wrist_score | คะแนนท่าทางแขนและข้อมือ |
| Load / force | load_force_score | ภาระน้ำหนักหรือแรงที่เกี่ยวข้อง |
| Coupling | coupling_score | คุณภาพการจับ/ด้ามจับ/การประคองวัตถุ |
| Activity | activity_score | งานซ้ำ ค้างท่า หรือการเปลี่ยนท่าเร็ว |

### Logic เชิงขั้นตอน

1. ประเมินท่าทางลำตัว คอ และขา แล้วรวมเป็น `score_a_base`
2. เพิ่มคะแนน load/force เป็น `score_a`
3. ประเมินต้นแขน ปลายแขน และข้อมือ แล้วรวมเป็น `score_b_base`
4. เพิ่มคะแนน coupling เป็น `score_b`
5. ใช้ `score_a` และ `score_b` เพื่อหา `score_c`
6. เพิ่ม `activity_score` เพื่อได้ `reba_score`
7. จำกัดผลลัพธ์ให้อยู่ในช่วงคะแนน REBA ที่ใช้งาน และ map เป็นระดับความเสี่ยง

### Risk level mapping

| REBA score | Risk level | Interpretation |
|---:|---|---|
| 1 | negligible | ความเสี่ยงน้อยมาก |
| 2-3 | low | ความเสี่ยงต่ำ |
| 4-7 | medium | ความเสี่ยงปานกลาง |
| 8-10 | high | ความเสี่ยงสูง |
| 11-15 | very_high | ความเสี่ยงสูงมาก |

## 2. ISO 11228-1 score

ISO 11228-1 ในบริบทแอปใช้ประเมินความเสี่ยงจาก manual handling โดยเฉพาะงานยก/ขน/ถือ/เคลื่อนย้ายวัตถุ ข้อมูลนี้ใช้ประกอบกับ REBA เมื่อกิจกรรมมีภาระงานยกหรือขนย้าย ไม่ควรตีความเป็นการวินิจฉัยอาการบาดเจ็บ

### Input หลัก

| Field | Unit | ความหมาย |
|---|---:|---|
| load_weight_kg | kg | น้ำหนักวัตถุหรือภาระที่ยก/ถือ |
| max_load_weight_kg | kg | น้ำหนักสูงสุดใน activity/window |
| lift_frequency_per_hour | count/hour | ความถี่การยก |
| carry_distance_m | m | ระยะทางขนย้ายต่อรอบ |
| carrying_exposure | ordinal | exposure จากการถือ/ขน |
| push_pull_exposure | ordinal | exposure จากงานดัน/ดึง |
| posture_component | points | คะแนนท่าทางที่เพิ่มความเสี่ยงขณะยก/ขน |

### Logic เชิงขั้นตอน

1. ตรวจว่า activity เข้าข่าย manual handling หรือไม่
2. ให้คะแนนภาระน้ำหนักจาก `load_weight_kg` และ/หรือ `max_load_weight_kg`
3. ให้คะแนน exposure จากความถี่การยก ระยะทางขนย้าย และงานดัน/ดึง
4. เพิ่มคะแนน posture modifier เมื่อท่าทางมีการก้ม เอื้อม บิดลำตัว หรือทำซ้ำ
5. รวมคะแนนเป็น `iso11228_score`
6. map เป็น `iso11228_risk_level` เพื่อสื่อสารผลร่วมกับ REBA

### Risk level mapping for export

| ISO score band | Risk level | Interpretation |
|---|---|---|
| low band | low | exposure ยังอยู่ในระดับเฝ้าระวัง |
| middle band | medium | ควรปรับปรุงวิธีทำงานหรือพักสลับงาน |
| high band | high | ควรลดภาระงาน/ปรับอุปกรณ์/ทบทวนขั้นตอนงาน |

หมายเหตุ: หากโครงการวิจัยกำหนดเกณฑ์ ISO ที่ละเอียดกว่า เช่นตามเพศ อายุ หรือ reference mass ให้ระบุ threshold version ใน protocol เพิ่มเติม และเก็บ field `iso_threshold_version`

## 3. App score before/after

แอปแสดงผลเป็นคะแนนก่อนปรับปรุงและหลังปรับปรุง ไม่ใช่ probability

### Before

`app_score_before` คือคะแนนสรุปความเสี่ยงก่อนเลือกแนวทางปรับปรุง โดยเลือกจาก method ที่เกี่ยวข้องกับ activity:

- ถ้ามี REBA อย่างเดียว ใช้ `reba_score_before`
- ถ้ามี ISO อย่างเดียว ใช้ `iso11228_score_before` ที่ map เข้า score scale ของแอป
- ถ้ามีทั้ง REBA และ ISO ใช้วิธี combined score โดยเน้นคะแนนที่สะท้อนความเสี่ยงสูงกว่า หรือใช้ weighted combination ตาม configuration ของแอป

### After

`app_score_after` คือคะแนนโดยประมาณหลังเลือก recommendation:

1. เริ่มจาก component scores ก่อนปรับปรุง
2. นำ expected effect ของ recommendation ที่เลือกไปลด component ที่เกี่ยวข้อง เช่น trunk, upper limb, wrist, load, frequency หรือ activity repetition
3. คำนวณคะแนน REBA/ISO ใหม่จาก component หลังปรับปรุง
4. ได้ `reba_score_after`, `iso11228_score_after`, และ `app_score_after`
5. คำนวณ `score_delta = app_score_before - app_score_after`

ตัวอย่างการตีความ:

- `app_score_before = 7`, `app_score_after = 5`, `score_delta = 2`
- หมายถึงคะแนนความเสี่ยงลดลง 2 คะแนนหลังเลือกแนวทางปรับปรุง
- ไม่ควรเขียนว่า probability ลดลง 2 หน่วย เพราะ field นี้เป็นคะแนน ไม่ใช่ความน่าจะเป็น

## 4. Trend 7 ครั้งล่าสุด

Trend ใช้สรุปแนวโน้มเชิง descriptive จากรายการประเมินล่าสุดของผู้เข้าร่วมคนเดียวกัน

### Window selection

1. filter เฉพาะ record ของ `participant_code` เดียวกัน
2. sort ตาม `assessment_datetime` จากเก่าไปใหม่
3. เลือกไม่เกิน 7 record ล่าสุด
4. ถ้ามีน้อยกว่า 2 record ให้ `trend_7_direction = insufficient_data`

### Metrics

| Metric | Formula | Interpretation |
|---|---|---|
| trend_7_reba_average | average(reba_score_before in window) | ค่าเฉลี่ย REBA ล่าสุด |
| trend_7_iso_average | average(iso11228_score_before in window) | ค่าเฉลี่ย ISO ล่าสุด |
| trend_7_app_average | average(app_score_before in window) | ค่าเฉลี่ย app score ล่าสุด |
| trend_7_app_slope | linear slope of app_score_before over record order | ค่าลบ = คะแนนลดลงตามเวลา |
| trend_7_direction | rule from slope/delta | improving/stable/worsening |

### Simple direction rule

สำหรับ export/sample file นี้ใช้ rule ที่อ่านง่าย:

```text
if recent_record_count < 2:
  trend_7_direction = "insufficient_data"
else if trend_7_app_slope <= -0.25:
  trend_7_direction = "improving"
else if trend_7_app_slope >= 0.25:
  trend_7_direction = "worsening"
else:
  trend_7_direction = "stable"
```

หากใช้ใน manuscript ควรระบุว่า threshold 0.25 points/record เป็น operational threshold สำหรับ descriptive trend ไม่ใช่ clinical cutoff

## 5. Reporting language recommended for researcher

ข้อความแนะนำ:

> The application reports ergonomic risk as score-based before/after estimates. It does not present individual injury probability. The after score is recalculated from the selected ergonomic recommendations and is interpreted as an estimated reduction in risk score, not as a medical diagnosis.

ข้อความภาษาไทย:

> แอปรายงานผลเป็นคะแนนความเสี่ยงก่อนและหลังปรับปรุง ไม่ได้รายงานความน่าจะเป็นของการบาดเจ็บรายบุคคล คะแนนหลังปรับปรุงเป็นค่าประมาณจากแนวทาง ergonomic recommendation ที่เลือก และใช้เพื่อการคัดกรอง/สื่อสารความเสี่ยง ไม่ใช่การวินิจฉัยทางการแพทย์
