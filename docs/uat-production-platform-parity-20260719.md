# รายงานตรวจสอบ Production Assessment และ UI iOS/Android

วันที่ทดสอบ: 19 กรกฎาคม 2026

เอกสารข้อกำหนดอ้างอิง: `/Users/kpc/Desktop/App Developer_LastPhase.md`

Requirement matrix อ้างอิง: `docs/last-phase-requirement-matrix-20260712.md`

## สรุปผล

- **PASS — การพัฒนา:** ความสามารถตามข้อกำหนด 1.1–6.3 มีอยู่ในแอปและมี automated test ครอบคลุมตาม requirement matrix
- **PASS — Production assessment:** ยกเลิกทางลัด UAT แล้ว ปุ่มและ handler ใช้เงื่อนไข production ชุดเดียวกัน
- **PASS — iOS Simulator:** เส้นทางประเมินจริงผ่าน MoveNet/TFLite และเปิดหน้าผลลัพธ์สำเร็จ
- **PASS — Android Emulator:** เส้นทางประเมินจริงผ่าน MoveNet/TFLite และเปิดหน้าผลลัพธ์สำเร็จ
- **PASS — UI parity:** หน้าหลักของกระบวนการประเมินใช้โครงสร้างเดียวกันบน iOS และ Android โดยแตกต่างเฉพาะส่วนของระบบปฏิบัติการที่ยอมรับได้
- **PASS — Portrait only:** Android, iPhone และ iPad ถูกกำหนดให้รองรับแนวตั้งเท่านั้น
- **BLOCKED — iPhone เครื่องจริงรอบนี้:** iPhone SE เชื่อมต่อและจับคู่แล้ว แต่ CoreDevice รายงาน `unavailable` และ `tunnelState: unavailable` จึงยังติดตั้ง/เปิดชุดทดสอบรอบนี้บนเครื่องจริงไม่ได้

ผลสรุปจึงหมายถึง **โค้ดและแพ็กเกจพร้อมตามข้อกำหนด แต่ยังไม่ควรปิดรายการ UAT เครื่องจริง** จนกว่า iPhone SE จะกลับมาอยู่ในสถานะ available และสามารถรันเส้นทาง production ได้ครบหนึ่งรอบ

## ขอบเขตข้อกำหนดจากเอกสาร

| กลุ่ม | ข้อกำหนด | ผลการพัฒนา | หลักฐานหลัก |
| --- | --- | --- | --- |
| 1 | เปลี่ยนกิจกรรม, draft/auto-save, responsive final action, avatar แยกรายเกษตรกร | PASS | Widget/state/persistence tests และ requirement matrix |
| 2 | รูปสูงสุด 4 รูป, preview/เปลี่ยน/ลบ, ตรวจหลายคน/ภาพไม่พร้อม, farmer/admin result | PASS | Image-slot, MoveNet MultiPose, result-summary tests |
| 3 | TTS, ข้อความเสียงกระชับ, UI อ่านง่าย, Body Map, REBA/ISO detail | PASS | TTS, farmer-summary, breakdown และ screenshot tests |
| 4 | คำแนะนำ 4 หมวดและสรุปตามความเสี่ยงจริง | PASS | Recommendation service, UI parity และ final-result tests |
| 5 | คงหน้ากิจกรรมแบบภาพประกอบและคู่มือใช้ภาพจริง | PASS | Help/manual และ activity capture tests |
| 6 | Trend/filter/export, metadata, backup และ migration | PASS | History, export, training-data และ persistence tests |

ข้อกำหนดรายข้อพร้อมตำแหน่งโค้ดและ automated evidence อยู่ใน `docs/last-phase-requirement-matrix-20260712.md`

## การยกเลิก Assessment Bypass

ตรวจแล้วไม่พบรายการต่อไปนี้ใน production source หรือ platform build files:

- `SOOKTA_UAT_BYPASS`
- `UatConfig`
- ข้อความแจ้ง UAT shortcut เดิม

สถานะปุ่ม “ดูผลประเมิน” และ handler ก่อนคำนวณใช้ `AssessmentReadiness` ชุดเดียวกัน โดยต้องผ่านครบทุกเงื่อนไข:

1. มี media
2. ไม่มี image-quality issue
3. pose assessment พร้อม
4. pose analysis ไม่อยู่ระหว่างทำงาน
5. ข้อมูลกิจกรรมและ ergonomic input ครบ

วิดีโอที่อัปโหลดไม่ข้ามเงื่อนไขเหล่านี้ เฟรมจากวิดีโอต้องผ่าน image-quality และ pose-readiness เหมือนรูปภาพ

## ผล Automated Test

| รายการ | ผล |
| --- | --- |
| Static analysis สำหรับไฟล์ที่แก้ | PASS — `No issues found` |
| Flutter test suite ทั้งหมด | PASS — 118 tests, 0 failures |
| Production assessment บน Android 15 Emulator | PASS |
| Production assessment บน iOS 26.5 Simulator | PASS |
| Regression: Android zero-height warm-up frame | PASS |
| Regression: iPhone/Android ใช้ compact score layout เดียวกัน | PASS |
| UI contract สำหรับสองขนาดหน้าจอและสองภาษา | PASS |
| Recommendation selection แสดง 4 หมวด | PASS |

Integration test ใช้ bundled detector-readable media และเรียก MoveNet/TFLite จริงเพื่อยืนยัน gate, inference และ navigation โดยไม่มี assessment bypass อย่างไรก็ตาม fixture ใช้ภาพตัวอย่างที่อ่านได้สองภาพสลับกันในสี่ช่อง จึงไม่ใช่หลักฐานแทนการถ่ายบุคคลจริงจากสี่มุม

## ผล Build

| Platform | ผล | Artifact |
| --- | --- | --- |
| Android release APK | PASS — 206.5 MB | `build/app/outputs/flutter-apk/app-release.apk` |
| iOS release, no codesign | PASS — 100.6 MB | `/private/tmp/sookta-build/ios/iphoneos/Runner.app` |

SHA-256 ของ Android APK:

`dae706103e97e8f7abccfcbb1febe2965d77e644dcc176e4bebf1ffcfa613e1f`

iOS build ใช้ build directory แยกภายใต้ `/private/tmp` เพื่อหลีกเลี่ยง metadata ของ FileProvider ในโฟลเดอร์ Documents ที่ทำให้ codesign ตรวจพบ extended attributes ไม่ใช่การปิดหรือลดความเข้มงวดของการตรวจในแอป และไม่ได้เปลี่ยน global Flutter configuration

## Portrait-only

- Android: `android:screenOrientation="portrait"`
- iPhone: `UIInterfaceOrientationPortrait` เท่านั้น
- iPad: `UIInterfaceOrientationPortrait` เท่านั้น

ภาพ UAT ทุกภาพเป็นแนวตั้ง:

- iOS: 1206 × 2622
- Android: 1080 × 2400

## UI Parity

ตรวจเปรียบเทียบหน้าต่อไปนี้:

1. หน้าเลือกกิจกรรม
2. หน้ากรอก/แนบข้อมูลประเมิน
3. หน้าความเสี่ยงและเลือกวิธีลดความเสี่ยง
4. หน้าสรุปผล

ผลตรวจ:

- ลำดับเนื้อหา, card, สี, icon, label และสถานะสำคัญตรงกัน
- คะแนนก่อน–หลังใช้รูปแบบแนวตั้งเหมือนกันทั้ง iPhone และ Android phone
- หน้าเลือกวิธีลดความเสี่ยงมี 4 หมวดตาม UI contract
- ไม่พบ overflow หรือ runtime layout exception ในภาพชุดสุดท้าย
- ความแตกต่างที่เหลือเป็น status/navigation bar, safe area และ font rasterization ของระบบปฏิบัติการ

หลักฐานภาพ:

- `docs/uat_evidence_20260719_platform_parity/ios/`
- `docs/uat_evidence_20260719_platform_parity/android/`

ระหว่าง UAT พบรอยต่างและแก้ไขแล้วสองรายการ:

1. Android warm-up frame อาจมีความสูงเป็นศูนย์ ทำให้หน้าเลือกกิจกรรมส่งค่าความสูงติดลบ — แก้ด้วยการ clamp ที่ศูนย์และเพิ่ม regression test
2. หน้าผลลัพธ์ Android เคยวางคะแนนก่อน–หลังแนวนอน ขณะที่ iPhone วางแนวตั้ง — ปรับ breakpoint และเพิ่ม test สำหรับความกว้าง 390/412

## สถานะ iPhone เครื่องจริง

อุปกรณ์ที่ตรวจพบ:

- Model: iPhone SE (`iPhone12,8`)
- UDID: `00008030-0008788421F3802E`
- Pairing: paired
- Developer Mode: enabled
- CoreDevice state: `unavailable`
- DDI services: unavailable
- Tunnel state: unavailable

ดังนั้นรอบนี้ยังทำ physical-device production UAT ต่อไม่ได้ สถานะที่ถูกต้องคือ **BLOCKED BY DEVICE CONNECTION** ไม่ใช่ app failure และไม่สามารถอนุมานเป็น PASS ได้

เมื่ออุปกรณ์กลับมา available ให้รัน UAT เครื่องจริงอย่างน้อย:

1. ติดตั้ง release/development-signed build
2. ยืนยันว่าแอปหมุนแนวนอนไม่ได้
3. อัปโหลด/ถ่ายภาพบุคคลจริงครบ 4 มุม
4. ยืนยันว่าภาพที่ไม่พร้อมและภาพหลายคนถูกปฏิเสธ
5. ผ่านปุ่ม “ดูผลประเมิน” โดยไม่มี bypass
6. เลือกคำแนะนำครบ 4 หมวดและเปิดหน้าสรุปผล
7. ตรวจเสียงไทย, บันทึกประวัติ และ export

## ข้อสรุปการรับมอบ

โค้ดปัจจุบันผ่าน requirement, regression, platform build, simulated production flow และ UI parity ตามขอบเขตที่ทำอัตโนมัติได้ การรับมอบด้าน implementation จัดเป็น **PASS** ส่วน physical iPhone UAT รอบสุดท้ายยังเป็น **BLOCKED** จนกว่าสถานะอุปกรณ์จะพร้อมให้ติดตั้งและรันแอป
