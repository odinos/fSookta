# แบบออกแบบการเผยแพร่ Sookta 1.3.8+25

วันที่: 1 สิงหาคม 2026

## เป้าหมาย

จัดทำไฟล์สำหรับส่งขึ้น Apple App Store และ Google Play Store จากงานปรับถ้อยคำและรูปประโยคภาษาไทย–อังกฤษที่ผ่านการทบทวนแล้ว โดยไม่รวมงาน Trend/ML รุ่นใหม่หรืองานทดลองที่ไม่เกี่ยวข้อง

## แหล่งโค้ดและขอบเขต

- ใช้ branch `codex/recommendation-localization-review` เป็นแหล่ง release
- เปลี่ยนเวอร์ชัน Flutter จาก `1.3.7+24` เป็น `1.3.8+25`
- รวมเฉพาะพฤติกรรมและข้อความที่มีอยู่ใน branch นี้ ณ commit `eb4cc87`
- ไม่ merge commit งานฝึกโมเดลหรือ Trend/ML จาก branch `codex/ios-real-integrations`
- ไม่เพิ่มฟีเจอร์ เปลี่ยนสูตรคำนวณ หรือเปลี่ยนพฤติกรรมการเก็บข้อมูลในรอบนี้

## ผลลัพธ์ที่ส่งมอบ

ไฟล์ทั้งหมดจัดเก็บใน `outputs/store-builds/1.3.8+25/`:

1. Android App Bundle แบบ release (`.aab`) สำหรับ Google Play Console
2. iOS App Store package (`.ipa`) สำหรับ App Store Connect
3. เอกสาร metadata ภาษาไทยและอังกฤษสำหรับทั้ง Apple App Store และ Google Play Store
4. เอกสารผลตรวจ release ระบุคำสั่งที่ใช้ ผลทดสอบ เวอร์ชัน และตำแหน่ง artifact

## Store metadata

จัดทำข้อความต่อไปนี้แยกตามแพลตฟอร์มและภาษา:

- คำอธิบายแอปฉบับเต็ม
- ข้อความ “มีอะไรใหม่” / “What’s New” สำหรับเวอร์ชัน 1.3.8
- ข้อความต้องสะท้อนเฉพาะความสามารถที่มีอยู่จริงในแอป
- เน้นว่ารอบนี้ปรับความชัดเจนและความสอดคล้องของคำแนะนำด้านการยศาสตร์ทั้งสองภาษา
- ไม่กล่าวอ้างว่าแอปวินิจฉัย รักษา หรือทดแทนคำแนะนำจากบุคลากรทางการแพทย์

## ขั้นตอน build และการตรวจสอบ

1. ตรวจว่า working tree สะอาดและอยู่บน branch ที่กำหนด
2. เพิ่มเลขเวอร์ชันใน `pubspec.yaml` และปรับการทดสอบหรือเอกสารอ้างอิงเวอร์ชันที่เกี่ยวข้อง
3. รัน dependency resolution, static analysis และชุดทดสอบ Flutter ทั้งหมด
4. สร้าง Android release App Bundle ด้วย signing configuration ที่มีอยู่
5. สร้าง iOS archive และ export แบบ App Store ด้วย signing configuration ที่มีอยู่
6. ตรวจ metadata ภายใน AAB/IPA ว่าเป็น version `1.3.8` และ build `25`
7. ตรวจ signature และโครงสร้าง artifact ตามเครื่องมือตรวจ release ที่มีอยู่ในโปรเจกต์
8. บันทึกผลตรวจจริง รวมถึงข้อจำกัดใด ๆ ที่ต้องยืนยันต่อบน App Store Connect หรือ Play Console

## การจัดการข้อผิดพลาด

- หาก signing credential ใช้งานไม่ได้ ให้หยุดที่ผล build ที่พิสูจน์ได้และรายงาน blocker โดยไม่สร้าง artifact ที่อ้างว่าพร้อมส่ง Store
- หาก test, analysis หรือการตรวจเวอร์ชันล้มเหลว ให้แก้เฉพาะสิ่งที่เกี่ยวข้องกับ release นี้และรันการตรวจเต็มซ้ำ
- ไม่ข้ามข้อผิดพลาดเพื่อสร้างไฟล์ส่งมอบ

## เกณฑ์สำเร็จ

- source release เป็น branch งาน localization ที่กำหนดและไม่มี Trend/ML รุ่นใหม่
- `pubspec.yaml` ระบุ `1.3.8+25`
- static analysis และชุดทดสอบที่เกี่ยวข้องผ่าน
- ได้ `.aab` และ `.ipa` ที่ตรวจพบ version `1.3.8 (25)` และมี signing สำหรับ Store
- เอกสาร Store ภาษาไทย–อังกฤษครบทั้งสองแพลตฟอร์มและสอดคล้องกับความสามารถจริง
