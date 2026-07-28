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

## 3. Flutter Module and Dependency Structure

<!-- DOCX_DIAGRAM:module-dependency -->

## 4. Route Map and State Transitions

<!-- DOCX_DIAGRAM:route-state -->

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

## ภาคผนวก B Persistence Key Catalogue

## ภาคผนวก C Data Dictionary

## ภาคผนวก D Algorithm Pseudocode

## ภาคผนวก E Requirement-Class-Test-Guideline Matrix

## ภาคผนวก F Source Code Index

## เอกสารอ้างอิง
