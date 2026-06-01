# Google Play Store Metadata - Version 1.0

Updated: 2026-05-31

## App Information

- App name: `Sookta สุขท่า`
- Default language: Thai
- Package name: `com.kdev.sookta`
- Version name/code: `1.0.0` / `2`
- Category: `Health & Fitness`
- Tags to consider: `Health`, `Education`, `Agriculture`, `Ergonomics`

## Store Listing Graphics

- App icon, 512 x 512 PNG:
  `build/store/play_listing/sookta-play-icon-512.png`
- Feature graphic, 1024 x 500 PNG:
  `build/store/play_listing/sookta-feature-graphic-1024x500.png`
- Feature graphic, 1024 x 500 JPEG fallback:
  `build/store/play_listing/sookta-feature-graphic-1024x500.jpg`
- Phone screenshots, 1080 x 1920 JPEG, recommended for Google Play upload:
  `build/store/play_listing/phone_screenshots_1080x1920_jpg`
- Phone screenshots, 1080 x 1920 PNG fallback:
  `build/store/play_listing/phone_screenshots_1080x1920`

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

## en-US Store Listing

### App Name

Sookta

### Short Description

Posture risk assessment for coffee farmers

### Full Description

Sookta is an education and research-support app for ergonomic risk awareness in
coffee-farming workflows. It helps users assess posture-related ergonomic risks
for activities such as transplanting, fertilizing, spraying, pruning,
harvesting, and transporting produce.

Users can capture a posture photo or select an image from the photo library.
The app then summarizes the risk level, affected body areas, posture
recommendations, and estimated economic impact so farmers, field staff, and
research teams can better understand the potential impact of unsafe working
postures.

Key features:

- Thai and English language support
- Multiple participant or farmer profiles on one device
- Coffee-farming activity selection
- Camera and photo library support for posture assessment
- Offline ergonomic risk assessment on device
- Risk score and risk level summary
- Body map showing affected or high-risk body areas
- Activity-specific recommendations to help reduce ergonomic risk
- Text-to-speech guidance in Thai and English
- Local assessment history
- Export records as CSV files for field staff or researchers

Important notice:

Sookta is intended for ergonomic risk communication, education, and
research-support purposes only. It is not a medical diagnosis tool, not a
regulated medical device, not a clinical injury prediction tool, and not an
exact personal medical-cost or economic-loss calculator. If you have pain,
injury, or health concerns, please consult qualified medical personnel.

### What's New

Initial release of Sookta for ergonomic risk awareness in coffee-farming
workflows, with posture assessment, body risk map, recommendations, estimated
economic impact, local history, and CSV export.

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
