# แบบออกแบบคลังคำแนะนำและคำแปลที่ผ่านการอนุมัติ

วันที่: 2026-07-29  
สถานะ: อนุมัติแล้ว
ขอบเขต: Recommendation และ localization เท่านั้น  
นอกขอบเขต: การแก้สูตรคำนวณ การเปลี่ยนโมเดล ML และการ train

## 1. เป้าหมาย

สร้างคลังคำแนะนำกลางแบบมีเวอร์ชันสำหรับแอป Sookta โดยใช้ข้อความจาก
เอกสารที่ผู้ว่าจ้างส่งให้เป็นต้นฉบับหลัก ไม่สร้างข้อความคำแนะนำขึ้นใหม่ใน
โค้ดหรือด้วย ML

ข้อความเดียวกันต้องถูกใช้กับ:

- หน้าจอ
- Body Map
- หน้าผลหลังปรับปรุง
- หน้าสรุปและประวัติ
- เสียงอ่าน
- รายงาน
- ไฟล์ส่งออกที่ผู้ใช้มองเห็น

ระบบต้องเลือกภาษาไทยหรืออังกฤษตามภาษาที่ผู้ใช้เลือก และให้ iOS กับ Android
ใช้คลังข้อความและกฎชุดเดียวกัน

## 2. หลักการที่ได้รับการอนุมัติ

1. ML ส่งออกได้เฉพาะคะแนน ระดับ ความน่าจะเป็น หรือแนวโน้ม
2. ML ไม่สร้าง ไม่แปล และไม่เลือกข้อความด้วยการเรียนรู้จากข้อความ
3. กฎที่ตรวจสอบได้เลือก `selection_key` เดิม
4. Catalog เชื่อม `selection_key` ไปยัง `recommendation_id` สำหรับข้อความ
   แสดงผลหนึ่งหรือหลายรายการ
5. Internal key, enum, field name, feature name และชื่อสำหรับโปรแกรมคงเป็น
   ภาษาอังกฤษ
6. แปลเฉพาะข้อความที่ผู้ใช้เห็น ได้ยิน หรือได้รับในรายงานและไฟล์ส่งออก
7. ภาษาไทยต้องมาจากต้นฉบับที่ลงทะเบียน
8. ภาษาอังกฤษทุกข้อความในขอบเขตรอบนี้ต้องสมบูรณ์และผ่านการอนุมัติครบ 100%
   ก่อนเริ่มสร้าง App Catalog หรือแก้โค้ดแอป
9. คำแปลใช้รูปแบบตรงตามต้นฉบับเป็นค่าเริ่มต้น และใช้ plain English เฉพาะ
   เมื่อคำแปลตรงอ่านเข้าใจยาก
10. ห้ามเปลี่ยนตัวเลข หน่วย เวลา เงื่อนไข คำปฏิเสธ ระดับความเสี่ยง หรือ
    ความเร่งด่วนระหว่างการแปล

## 3. เอกสารต้นทาง

### 3.1 เอกสารจากผู้ว่าจ้าง

| Source ID | ไฟล์ | SHA-256 | บทบาท |
| --- | --- | --- | --- |
| `body_map_recommendations` | `/Users/kpc/Documents/TestSookta/Calibtation/ชุดคำแนะนำตามความเสี่ยง Body map.pdf` | `fee5c283139b78f605edf18a40fd1d5b4a48893f8e0aa9b3a037630944cb4d2c` | ข้อความเฉพาะส่วนร่างกายและระดับความเสี่ยง |
| `app_recommendations_v3` | `/Users/kpc/Documents/Doc/fortrain/คำแนะนำแต่ละดับความเสี่ยงใน app Ref. ISO11228, REBA V3.pdf` | `ec80da8a80a4c9fee6255b2787ae86c79fdddef69b53574eab07bb43fcab87b5` | ข้อความตามกิจกรรมและระดับความเสี่ยง |
| `ilo_ergonomic_checkpoints_agriculture` | `/Users/kpc/Documents/Doc/fortrain/wcms_168042.pdf` | `3ca8a3c621ad6efb58e818de8c5d64ec257bb13c74f191e96c5f60d4d47acf8e` | หลักฐานต้นทางและข้อความสำรองที่ตรงเงื่อนไข |
| `reba_employee_assessment_worksheet` | `/Users/kpc/Documents/Doc/REBA.pdf` | `b23cf52703aacf6cd348f81044f91672cc7bf50f5273be82243d4a11a95155e8` | วิธีให้คะแนน REBA และระดับความเสี่ยง |
| `iso11228_pirawan_project_workbook` | `/Users/kpc/Documents/Doc/ISO11228 Pirawan.xlsx` | `980930d38680ffe215dda38cabe5985fe205b63ade112db63cd9a0a844b16342` | ตัวอย่างประเมิน 36 เคสและแบบประเมินที่ปรับใช้ในโครงการ |

### 3.2 ข้อจำกัดการใช้เอกสาร

- เอกสารมาตรฐานหรือเอกสารที่มีข้อจำกัดด้านลิขสิทธิ์ไม่ถูกนำเข้า repository
  โดยอัตโนมัติ
- Source Registry เก็บ path, checksum, หน้า ส่วน และบทบาทเพื่อให้ตรวจสอบ
  ย้อนกลับได้
- Excel ของโครงการใช้เป็นตัวอย่างและ calibration reference ไม่อ้างว่า
  สูตร A-F ช่วง 6-18 เป็นวิธีคำนวณ ISO 11228 โดยตรง
- ข้อความเดิมในโค้ดเป็น candidate สำหรับการเทียบตรวจ ไม่ใช่ต้นฉบับที่
  ได้รับอนุมัติโดยอัตโนมัติ

## 4. ลำดับความสำคัญของแหล่งข้อความ

เมื่อมีข้อความซ้อนกัน ใช้ลำดับ:

1. Body Map สำหรับคำแนะนำเฉพาะส่วนร่างกาย
2. เอกสาร V3 สำหรับคำแนะนำตามกิจกรรมและระดับความเสี่ยง
3. ILO สำหรับหลักฐานและข้อความสำรองที่มีความหมายตรงอย่างชัดเจน
4. ไม่พบข้อความที่ได้รับอนุมัติ: ไม่สร้างข้อความคำแนะนำใหม่

หากเอกสารที่มีลำดับสูงกว่าขัดแย้งกับเอกสารอื่นด้านตัวเลข หน่วย เวลา หรือ
เงื่อนไข ระบบจัดทำ conflict record และหยุดรายการนั้นไว้ที่ `needs_revision`
จนกว่าผู้ใช้จะอนุมัติ ไม่รวมข้อความจากหลายเอกสารเข้าด้วยกันเอง

## 5. สถาปัตยกรรม

ลำดับการทำงาน:

1. REBA/ISO และ ML ทำงานตามพฤติกรรมเดิม
2. กฎ recommendation selection เดิมให้ `selection_key`
3. `selection_key` และ improvement effect เดิมไม่เปลี่ยน
4. Catalog เชื่อม `selection_key` หนึ่งค่าไปยัง display item ได้หนึ่งหรือ
   หลายรายการ
5. Recommendation Resolver อ่าน display items จาก App Catalog
6. Resolver เลือกข้อความตามภาษาและ approval status
7. หน้าจอ TTS รายงาน และ export ใช้ผลจาก Resolver เดียวกัน

App Catalog เป็น read-only bundled asset ในรอบนี้ ไม่มี backend ไม่มี cloud
และไม่ต้องติดต่อบริษัทหรือผู้ดูแลบัญชีองค์กร

## 6. แบบข้อมูล

### 6.1 Source Registry

ฟิลด์ขั้นต่ำ:

```text
source_id
file_name
local_path
sha256
document_date
document_role
priority
language
page_count
copyright_or_distribution_note
registry_version
```

### 6.2 Recommendation Master

หนึ่ง display item ต้องเป็นหนึ่งการกระทำที่ผู้ใช้ทำตามได้ หากข้อความต้นฉบับ
ของคีย์เดิมมีหลายการกระทำ ให้คง `selection_key` เดิมแล้วเชื่อมไปยัง
display item หลายรายการ การเลือก การบันทึก และ improvement effect ยังคงใช้
`selection_key` เดิม

```text
recommendation_id
selection_key
display_order
category
activity
body_part
risk_level
trigger_condition
thai_source_text
source_id
source_page
source_section
source_priority
catalog_version
record_status
```

ข้อกำหนด:

- `recommendation_id` เป็นภาษาอังกฤษ ไม่เปลี่ยนตามภาษา และระบุ display item
- `selection_key` คือ legacy key ที่รักษาการเชื่อมกับกฎ persistence และ
  improvement effect เดิม
- `selection_key` ซ้ำได้ แต่คู่ `selection_key + display_order` ต้องไม่ซ้ำ
- `thai_source_text` ต้องตรงกับข้อความต้นฉบับที่ผ่านการตรวจ
- `trigger_condition` ไม่อ้างอิงข้อความ localized
- ทุก ID ต้องมี provenance

### 6.3 Translation Review

```text
recommendation_id
thai_source_text
english_draft
translation_style
numbers_match
units_match
timing_match
urgency_match
negation_match
meaning_review
review_comment
approval_status
approved_by
approved_at
translation_version
```

ค่าที่รองรับ:

- `translation_style`: `direct`, `plain_english`
- `approval_status`: `pending`, `approved`, `rejected`, `needs_revision`

### 6.4 App Catalog

App Catalog ประกอบด้วยรายการที่พร้อมใช้ใน runtime:

```text
catalog_version
source_registry_version
generated_at
catalog_checksum
recommendations[]
```

แต่ละ recommendation มี:

```text
id
selection_key
display_order
category
activity
body_part
risk_level
source
display.th
display.en
display.en_status
```

`display.en` ถูก package เข้าแอปได้เมื่อ `en_status` เป็น `approved` เท่านั้น
หากต้องเก็บ draft เพื่อการตรวจ ให้เก็บในเอกสาร review ที่ไม่ถูก package
เข้า runtime asset App Catalog จะไม่ถูกสร้างและการพัฒนา integration จะไม่เริ่ม
จนกว่าทุกรายการที่ผู้ใช้เห็น ได้ยิน หรือได้รับในไฟล์จะมีภาษาอังกฤษสมบูรณ์และ
ผ่านการอนุมัติครบ 100%

หากต้นฉบับเป็นภาษาอังกฤษ เช่น ILO และจำเป็นต้องใช้เป็น fallback ที่ผู้ใช้เห็น
ต้องสร้างคำแปลไทยแยกและให้ผู้ใช้อนุมัติก่อน ทั้งสองภาษาจึงจะเข้า App Catalog
ได้ ในรอบนี้ให้ใช้ ILO เป็นหลักฐานประกอบก่อน และใช้เป็นข้อความแสดงผลเฉพาะ
รายการที่ผ่าน approval gate ดังกล่าว

## 7. การแปลและการอนุมัติ

ขั้นตอน:

1. ดึงข้อความไทยพร้อม source locator
2. แยก recommendation ID
3. สร้างคำแปลตรง
4. ปรับเป็น plain English เฉพาะข้อความที่อ่านยาก
5. ตรวจตัวเลข หน่วย เวลา คำปฏิเสธ และความเร่งด่วนอัตโนมัติ
6. แสดงไทยและอังกฤษแบบแถวต่อแถว
7. ผู้ใช้แก้ข้อความหรือกำหนด approval status
8. ตรวจว่า English approval coverage เท่ากับ 100%
9. ผู้ใช้อนุมัติชุดคำแปลฉบับสมบูรณ์
10. จึงเริ่มสร้าง App Catalog และงาน integration

การแก้คำแปลที่อนุมัติแล้วต้องเพิ่ม translation version และอนุมัติใหม่

## 8. พฤติกรรมตามภาษา

### 8.1 ภาษาไทย

หน้าจอ TTS รายงาน และไฟล์ส่งออกใช้ `display.th`

### 8.2 ภาษาอังกฤษ

- ใช้เฉพาะ `display.en` ที่ได้รับอนุมัติ
- ไม่อนุญาตให้ App Catalog หรือแอปรุ่นพัฒนาในรอบนี้มีคำแปลอังกฤษที่ยัง
  `pending`, `rejected` หรือ `needs_revision`
- ห้ามแสดง draft
- ห้ามแสดง internal key
- เมื่อเลือกอังกฤษ หน้าจอ TTS รายงาน และไฟล์ส่งออกต้องใช้ภาษาอังกฤษที่
  อนุมัติแล้วครบทุกข้อความ
- ไม่มี fallback ปะปนภาษาไทยใน English mode

### 8.3 Asset หรือ ID ผิดปกติ

- Build-time validation ต้องหยุด build หากคีย์ที่กฎเดิมเลือกได้ไม่มีใน Catalog
- Build-time validation ต้องหยุด build หากข้อความอังกฤษรายการใดไม่มีหรือ
  ไม่ได้สถานะ `approved`
- Runtime ต้องไม่สร้างคำแนะนำใหม่
- Runtime ต้องไม่แสดง internal key
- รายการที่หาไม่ได้ถูกซ่อน
- ข้อความสถานะระบบต้องเป็นข้อความ UI ที่ผ่านกระบวนการอนุมัติภาษา
- คะแนนและผลคำนวณต้องยังคงเดิม

## 9. Scope Lock

### 9.1 สิ่งที่ทำได้ในรอบนี้

- Source Registry
- Recommendation Master
- Current-app Comparison Report
- Translation Review
- Conflict and Missing-source Report
- App Catalog
- Recommendation Resolver
- การเชื่อมข้อความกับหน้าจอ TTS รายงาน export และ history detail
- Tests และ local QA

### 9.2 สิ่งที่ห้ามเปลี่ยน

- สูตรและตาราง REBA
- สูตร ISO 11228
- Combined-risk rule
- Body-part risk calculation
- Before/after score calculation
- Economic impact calculation
- XGBoost model, ONNX artifact และ feature schema
- Daily Logistic model และ feature schema
- MoveNet และ image/video processing
- native iOS/Android implementation
- numeric history/export schema

ไฟล์ที่มีทั้ง calculation และ display logic แก้ได้เฉพาะเส้นทาง localized text
และต้องผ่าน numeric regression test

## 10. การรักษา recommendation behavior เดิม

รอบนี้คง:

- Selection key
- Recommendation selection condition
- Category
- Priority/order
- Improvement effect
- Selected action persistence

เปลี่ยนได้:

- Display text ที่ทำให้ตรงเอกสาร
- Approved English translation
- Source provenance
- Catalog metadata

หากพบว่า key เดิมชี้ไปยังข้อความผิดเอกสาร ให้บันทึก finding และขออนุมัติ
ก่อนแก้ mapping

## 11. การทดสอบ

### 11.1 Catalog validation

- ID ไม่ซ้ำ
- ทุก ID มี source
- Source hash ตรง Registry
- Thai text ผ่านการตรวจต้นฉบับ
- Runtime asset ไม่มี English draft
- English approval coverage เท่ากับ 100%
- English mode ไม่มี Thai fallback
- ตัวเลข หน่วย เวลา negation และ urgency ตรงกัน
- ทุก selection key ที่ถูกเลือกได้ resolve สำเร็จ
- ลำดับ source priority ถูกต้อง

### 11.2 Selection regression

Fixture เดิมต้องให้:

- Selection keys เหมือนเดิม
- Display-item recommendation IDs มีค่าคงที่ตาม Catalog version
- Category และ order เหมือนเดิม
- Selected action effects เหมือนเดิม
- After score เหมือนเดิมเมื่อเลือก ID ชุดเดิม

### 11.3 Localization consistency

ข้อความที่ Resolver คืนต้องตรงกันระหว่าง:

- Initial risk
- Body Map
- Final result
- History detail
- TTS input
- Report content
- User-facing export content

Training/research export ที่ออกแบบสำหรับการประมวลผลด้วยโปรแกรมยังคง
internal column names และ enum values เป็นภาษาอังกฤษ ส่วนรายงานหรือไฟล์สรุป
ที่ผู้ใช้เปิดอ่านต้อง localized ตามภาษาที่เลือก

### 11.4 Core numeric regression

ก่อนและหลังต้องได้ค่าเหมือนเดิม:

- REBA score
- ISO score/index
- Overall risk
- Body-part risk
- Before score
- After score
- Economic impact
- XGBoost output
- Daily Logistic output

### 11.5 Model integrity

บันทึกและเปรียบเทียบ hash ของ:

- ONNX model
- XGBoost metadata
- Daily Logistic asset
- MoveNet assets ที่เกี่ยวข้อง

Hash ต้องไม่เปลี่ยนในรอบนี้

### 11.6 iOS/Android parity

ใช้ assessment fixtures ชุดเดียวกันตรวจ:

- Recommendation IDs
- Category และ order
- Selected locale
- Display text
- TTS input text
- Report/export text
- Numeric outputs

ความแตกต่างที่ยอมรับได้มีเฉพาะบริการระบบ เช่น voice ที่ติดตั้งหรือ file
picker ไม่ใช่ข้อความหรือผลคำนวณ

## 12. ระยะดำเนินงานและ Approval Gates

### ระยะ A: เอกสารก่อนแก้แอป

ผลส่งมอบ:

- Source Registry
- Thai Recommendation Master
- Current-app Comparison Report
- English Translation Review
- Conflict and Missing-source Report

Gate: ผู้ใช้อนุมัติข้อความไทยและคำแปลอังกฤษครบทุกข้อความ และ English
approval coverage เท่ากับ 100% ก่อนเริ่มสร้าง Catalog หรือแก้โค้ด

### ระยะ B: Catalog

- สร้าง App Catalog จากรายการที่อนุมัติ
- ตรวจ schema, source coverage และ checksum

Gate: Catalog validation ผ่าน

### ระยะ C: Integration

- เชื่อม Resolver กับ user-facing surfaces
- รัน regression และ platform parity tests

Gate: ผลทดสอบ local ผ่านและผู้ใช้ตรวจผล

## 13. สิ่งที่ส่งต่อไประยะ ML ในอนาคต

การตัดสินใจต่อไปนี้ได้รับการเห็นชอบเชิงนโยบาย แต่ห้าม implement ในรอบนี้:

- Economic loss ไม่ควรเป็น feature ของ risk/discomfort ML เพราะเป็นผลคำนวณ
  downstream และเสี่ยงต่อ target leakage
- XGBoost posture model ไม่ควรใช้อายุ น้ำหนักตัว ส่วนสูง BMI รายได้ หรือ
  economic loss เป็น input
- อายุและ BMI สำหรับ Daily Ergonomic Discomfort Trend ต้องทดลอง Base
  เทียบ Extended model และใช้ได้เมื่อ real-world validation สนับสนุน
- น้ำหนักสิ่งของหรือเครื่องมือแยกจากน้ำหนักตัว
- Synthetic data ไม่แทน independent real-world holdout
- ML training ต้องมีเอกสาร แผนทดสอบ และ approval gate แยก

## 14. เกณฑ์สำเร็จ

งานรอบนี้สำเร็จเมื่อ:

1. ข้อความไทยทุกข้อความตรวจสอบย้อนกลับถึงเอกสารผู้ว่าจ้างได้
2. คำแปลอังกฤษทุกข้อความที่ใช้จริงได้รับอนุมัติ
3. หน้าจอ TTS รายงาน และ export ใช้ Catalog เดียวกัน
4. iOS และ Android ได้ข้อความและ ID เหมือนกัน
5. Core numeric regression ผ่าน
6. Model hashes ไม่เปลี่ยน
7. ไม่มีการ train หรือเปลี่ยน ML artifact
8. ไม่มี recommendation text ที่ระบบหรือ ML สร้างขึ้นเอง
9. Selection key, persistence และ improvement effect เดิมไม่เปลี่ยน
10. English approval coverage เท่ากับ 100% ก่อนเริ่ม development
