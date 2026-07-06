# Sookta Data Dictionary: REBA, ISO 11228-1, Before/After, and 7-Record Trend

เอกสารนี้อธิบายความหมายของ field สำหรับชุดข้อมูล export งานวิจัยจากแอป Sookta โดยออกแบบให้ใช้ประกอบเอกสารโครงการวิจัยหรือภาคผนวก dataset ได้ทันที

## ขอบเขตข้อมูล

หนึ่งแถวแทนหนึ่งรายการประเมินของเกษตรกรหนึ่งคนในกิจกรรมหนึ่งครั้ง ข้อมูลเป็นผลประเมินเชิง ergonomic risk เพื่อการคัดกรองและการสื่อสารความเสี่ยง ไม่ใช่การวินิจฉัยทางการแพทย์

| Field | Type | Unit / Format | Description | Research note |
|---|---:|---|---|---|
| record_id | text | unique id | รหัสรายการประเมินภายในชุด export | ใช้เป็น primary key ของ observation |
| export_generated_at | datetime | ISO 8601 | วันเวลาที่สร้างไฟล์ export | ใช้ audit version ของข้อมูล |
| assessment_datetime | datetime | ISO 8601 | วันเวลาที่ทำแบบประเมิน | ใช้เรียงลำดับ time series และ trend |
| participant_code | text | coded id | รหัสผู้เข้าร่วมวิจัย/เกษตรกรแบบไม่ระบุตัวตน | ไม่ควรใช้ชื่อจริงใน export วิจัย |
| farmer_group | text | category | กลุ่ม/พื้นที่/ชุดเก็บข้อมูลภาคสนาม | ใช้ stratify หรือ filter dataset |
| age_years | number | years | อายุผู้เข้าร่วม ณ วันที่ประเมิน | ควรเก็บเป็นตัวเลขเต็ม |
| sex | text | female/male/other/unknown | เพศตามที่ผู้เข้าร่วมระบุ | ใช้เพื่อวิเคราะห์ subgroup |
| height_cm | number | cm | ส่วนสูง | ใช้คำนวณ BMI |
| weight_kg | number | kg | น้ำหนักตัว | ใช้คำนวณ BMI |
| bmi | number | kg/m2 | ดัชนีมวลกาย = weight_kg / (height_m^2) | Derived field |
| activity_id | text | coded id | รหัสกิจกรรม เช่น pruning, harvesting, transport | ใช้เชื่อมกับ activity taxonomy |
| activity_name | text | label | ชื่อกิจกรรมที่ประเมิน | เช่น เก็บเกี่ยว, พ่นยา, ขนย้าย |
| crop_or_work_context | text | label | บริบทงาน/พืช/สถานที่ทำงาน | เพิ่ม context สำหรับ interpretation |
| assessment_method | text | REBA / ISO11228-1 / REBA+ISO11228-1 | วิธีประเมินหลักที่ใช้ในรายการนี้ | ถ้าใช้ทั้งสอง method ให้ระบุ combined |
| source_kind | text | camera / gallery / manual | แหล่งที่มาของ posture หรือข้อมูลประเมิน | ใช้ตรวจ reproducibility |
| source_path_or_label | text | optional | path, filename, หรือ label ของรูป/วิดีโอที่ใช้ประเมิน | ไม่ควรใส่ข้อมูลระบุตัวตน |
| pose_quality_score | number | 0-1 | คะแนนความเชื่อมั่นของ pose estimation ถ้ามี | ใช้ flag แถวที่คุณภาพภาพต่ำ |
| reba_score_before | number | points | คะแนน REBA ก่อนปรับปรุง | ช่วงทั่วไป 1-15; ค่ายิ่งสูงยิ่งเสี่ยง |
| reba_risk_before | text | category | ระดับความเสี่ยง REBA ก่อนปรับปรุง | negligible, low, medium, high, very_high |
| iso11228_score_before | number | points | คะแนน/ดัชนี ISO 11228-1 ก่อนปรับปรุงจาก module lifting/manual handling | ใช้เมื่อ activity เข้าข่ายยก/ขน/ดัน/ดึง |
| iso11228_risk_before | text | category | ระดับความเสี่ยง ISO ก่อนปรับปรุง | low, medium, high หรือ equivalent ตามเกณฑ์แอป |
| app_score_before | number | points | คะแนนสรุปก่อนปรับปรุงที่แอปใช้สื่อสารความเสี่ยง | แยกจาก probability; เป็น score ไม่ใช่โอกาสเกิดโรค |
| app_risk_before | text | category | ระดับความเสี่ยงก่อนปรับปรุงจาก app_score_before | ใช้ใน UI และ export |
| trunk_score_before | number | points | คะแนนส่วนลำตัวก่อนปรับปรุง | REBA component |
| neck_score_before | number | points | คะแนนส่วนคอก่อนปรับปรุง | REBA component |
| leg_score_before | number | points | คะแนนขา/เข่าก่อนปรับปรุง | REBA component |
| upper_arm_score_before | number | points | คะแนนต้นแขนก่อนปรับปรุง | REBA component |
| lower_arm_score_before | number | points | คะแนนปลายแขนก่อนปรับปรุง | REBA component |
| wrist_score_before | number | points | คะแนนข้อมือก่อนปรับปรุง | REBA component |
| load_force_score_before | number | points | คะแนนแรง/น้ำหนักที่เกี่ยวข้องก่อนปรับปรุง | REBA/ISO supporting component |
| coupling_score_before | number | points | คะแนนการจับยึด/ด้ามจับก่อนปรับปรุง | REBA component |
| activity_score_before | number | points | คะแนนลักษณะงานซ้ำ/ค้างท่า/เปลี่ยนท่าเร็ว | REBA component |
| load_weight_kg | number | kg | น้ำหนักของวัตถุ/เครื่องมือ/ภาระที่ยกหรือถือ | ใช้กับ ISO และ load component |
| lift_frequency_per_hour | number | count/hour | ความถี่การยก/เคลื่อนย้ายต่อชั่วโมง | ใช้กับ ISO |
| carry_distance_m | number | m | ระยะทางขนย้ายต่อรอบถ้ามี | ใช้กับ carrying exposure |
| push_pull_exposure | text | none/low/medium/high | ระดับ exposure งานดัน/ดึง | ใช้เป็นตัวแปรประกอบ ISO/manual handling |
| selected_recommendation_ids | text | semicolon-separated | รหัสแนวทางปรับปรุงที่ผู้ใช้เลือก | CSV-friendly โดยคั่นด้วย semicolon |
| selected_recommendation_text | text | text | คำอธิบายแนวทางปรับปรุงที่เลือก | ใช้ประกอบ qualitative review |
| reba_score_after | number | points | คะแนน REBA หลังปรับปรุงโดยประมาณ | คำนวณหลังใช้ recommendation effect |
| reba_risk_after | text | category | ระดับความเสี่ยง REBA หลังปรับปรุง | ใช้เทียบ before/after |
| iso11228_score_after | number | points | คะแนน ISO หลังปรับปรุงโดยประมาณ | คำนวณเฉพาะเมื่อมีข้อมูล ISO |
| iso11228_risk_after | text | category | ระดับความเสี่ยง ISO หลังปรับปรุง | ใช้เทียบ before/after |
| app_score_after | number | points | คะแนนสรุปหลังปรับปรุง | แสดงเป็น score after ไม่ใช่ probability |
| app_risk_after | text | category | ระดับความเสี่ยงหลังปรับปรุง | ใช้ใน UI หลังแก้ |
| score_delta | number | points | app_score_before - app_score_after | ค่าบวกหมายถึงคะแนนลดลง |
| risk_level_changed | boolean | TRUE/FALSE | ระบุว่าระดับความเสี่ยงเปลี่ยน category หรือไม่ | ใช้สรุปผล intervention |
| estimated_economic_loss_before_thb_year | number | THB/year | ผลกระทบทางเศรษฐกิจโดยประมาณก่อนปรับปรุง | ใช้เพื่อสื่อสารภาระต้นทุน ไม่ใช่ผลวินิจฉัย |
| estimated_economic_loss_after_thb_year | number | THB/year | ผลกระทบทางเศรษฐกิจโดยประมาณหลังปรับปรุง | Derived from after score/risk |
| estimated_savings_thb_year | number | THB/year | estimated_economic_loss_before - estimated_economic_loss_after | ค่าประมาณเพื่อการสื่อสาร |
| recent_record_count | number | count | จำนวนรายการย้อนหลังที่ใช้คำนวณ trend | สูงสุด 7 รายการล่าสุดต่อ participant |
| recent_reba_scores | text | semicolon-separated numbers | คะแนน REBA ของรายการย้อนหลังที่ใช้ใน trend | เรียงจากเก่าไปใหม่ |
| recent_iso11228_scores | text | semicolon-separated numbers | คะแนน ISO ของรายการย้อนหลังที่ใช้ใน trend | เรียงจากเก่าไปใหม่ |
| recent_app_scores | text | semicolon-separated numbers | app score ของรายการย้อนหลังที่ใช้ใน trend | เรียงจากเก่าไปใหม่ |
| trend_7_reba_average | number | points | ค่าเฉลี่ย REBA ใน 7 รายการล่าสุดหรือน้อยกว่านั้นถ้ามีข้อมูลไม่ครบ | ใช้สรุป burden ล่าสุด |
| trend_7_iso_average | number | points | ค่าเฉลี่ย ISO ใน 7 รายการล่าสุด | ใช้เฉพาะ activity ที่มี ISO |
| trend_7_app_average | number | points | ค่าเฉลี่ย app score ใน 7 รายการล่าสุด | ใช้สรุปภาพรวมล่าสุด |
| trend_7_app_slope | number | points/record | slope ของ app score ตามลำดับเวลาใน window ล่าสุด | ค่าลบ = แนวโน้มดีขึ้น, ค่าบวก = แย่ลง |
| trend_7_direction | text | improving/stable/worsening/insufficient_data | ทิศทาง trend จาก slope/delta | ใช้สื่อสารแบบ descriptive |
| outcome_followup_status | text | pending / completed / not_applicable | สถานะติดตาม outcome หลังประเมิน | ใช้สำหรับงานวิจัยเชิงติดตาม |
| msd_symptom_present_7d | text | yes/no/unknown | มีอาการ musculoskeletal ภายใน 7 วันหลังประเมินหรือไม่ | outcome label ถ้ามี follow-up |
| medical_visit_within_7d | text | yes/no/unknown | พบแพทย์/บุคลากรสุขภาพภายใน 7 วันหรือไม่ | outcome label |
| lost_workdays_7d | number | days | จำนวนวันหยุดงานภายใน 7 วัน | outcome label |
| label_confidence | text | low/medium/high | ความมั่นใจของ outcome label | ระบุจากแหล่งข้อมูลและผู้ review |
| reviewer_id | text | coded id | รหัสผู้ตรวจ label/ข้อมูล | ไม่ควรใช้ชื่อจริง |
| notes | text | free text | หมายเหตุการเก็บข้อมูล | หลีกเลี่ยงข้อมูลระบุตัวตน |

## CSV/Excel compatibility notes

- ใช้หนึ่ง header row เท่านั้นใน sheet `Sample Export`
- field ที่มีหลายค่าใช้ semicolon เช่น `R01;R04`
- วันที่ใช้ ISO 8601 เพื่อให้แปลง CSV แล้ว parse ได้ง่าย
- ไม่ใช้ merged cells ใน data sheet
- numeric fields เก็บเป็นตัวเลข ไม่ใส่หน่วยใน cell
- outcome medical fields เป็น label สำหรับงานวิจัย ไม่ใช่ diagnosis
