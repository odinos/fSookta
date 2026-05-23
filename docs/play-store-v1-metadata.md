# Google Play Store Metadata - Version 1.0

Updated: 2026-05-24

## App Information

- App name: `Sookta สุขท่า`
- Default language: Thai
- Package name: `com.kdev.sookta`
- Version name/code: `1.0.0` / `2`
- Category: `Health & Fitness`
- Tags to consider: `Health`, `Education`, `Agriculture`, `Ergonomics`

## Short Description

ประเมินความเสี่ยงท่าทางชาวสวนกาแฟ พร้อมคำแนะนำและผลกระทบทางเศรษฐกิจเบื้องต้น

## Full Description

Sookta สุขท่า เป็นแอปพลิเคชันสำหรับงานวิจัยด้านสรีรศาสตร์ของชาวสวนกาแฟไทย ช่วยประเมินความเสี่ยงจากท่าทางการทำงาน เช่น การปลูกกล้า การใส่ปุ๋ย การฉีดพ่น การตัดแต่งกิ่ง การเก็บเกี่ยว และการขนย้ายผลผลิต

ผู้ใช้สามารถถ่ายภาพหรือเลือกรูปท่าทางการทำงาน แล้วแอปจะช่วยสรุประดับความเสี่ยง จุดของร่างกายที่ควรระวัง คำแนะนำในการปรับท่าทาง และผลกระทบทางเศรษฐกิจโดยประมาณ เพื่อให้ชาวสวนและทีมวิจัยเห็นภาพความเสี่ยงจากการทำงานผิดท่าได้ง่ายขึ้น

คุณสมบัติหลัก:

- เลือกประเภทงานของชาวสวนกาแฟ
- ถ่ายภาพหรือเลือกรูปเพื่อใช้ประกอบการประเมินท่าทาง
- แสดงคะแนนความเสี่ยงก่อนและหลังแนวทางปรับปรุง
- แสดงแผนภาพร่างกายและตำแหน่งที่มีความเสี่ยง
- สรุปผลกระทบด้านค่าใช้จ่ายและรายได้ที่อาจสูญเสียโดยประมาณ
- บันทึกประวัติการประเมินบนเครื่อง
- มีคำแนะนำและเสียงอ่านภาษาไทย/อังกฤษ

หมายเหตุ: ผลประเมินในแอปใช้เพื่อการสื่อสารความเสี่ยง การเรียนรู้ และงานวิจัยเท่านั้น ไม่ใช่การวินิจฉัยทางการแพทย์ ไม่ใช่การยืนยันการบาดเจ็บ และไม่ใช่การคำนวณค่าใช้จ่ายจริงเฉพาะบุคคล หากมีอาการปวดหรือบาดเจ็บควรปรึกษาบุคลากรทางการแพทย์

## What's New

เปิดตัว Sookta สุขท่า สำหรับงานวิจัยด้านสรีรศาสตร์ชาวสวนกาแฟ พร้อมการประเมินความเสี่ยงจากท่าทาง แผนภาพร่างกาย คำแนะนำ ผลกระทบทางเศรษฐกิจ และประวัติผลประเมิน

## Play Console Notes

- Use the same privacy policy and support URL prepared for App Store Connect.
- In Data safety, disclose camera access, photo/media picker usage, and local
  profile/history storage. The current app does not send profile/history data to
  a backend unless Firebase or export flow is added later.
- Do not describe the current ML assets as clinically validated diagnostic AI.
  Use research-prototype wording.
- The current unsigned build verification artifact is:
  `/private/tmp/fSookta-store-build/build/app/outputs/bundle/release/app-release.aab`.
  Rebuild after configuring the local upload keystore before uploading.

## Screenshot Plan

Capture clean screenshots from a release/profile Android build without QA labels.
Recommended coverage:

1. Home / start assessment
2. Profile with avatar and one-row age/weight/height stats
3. Activity selection
4. Camera or image selection flow
5. Initial risk result
6. Final result with body map and economic impact
7. Recommendations with TTS control
8. History list and detail
