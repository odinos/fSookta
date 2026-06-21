# App Store Connect Metadata - Version 1.1.2

Updated: 2026-06-06

## Current Build

- App version: `1.1.2`
- Build number: `10`
- Bundle identifier: `com.kdev.sookta`
- Latest local IPA:
  `/Users/kpc/Documents/GitHub/fSookta/build/ios/ipa/Sookta.ipa`
- Build verification: `flutter analyze` passed, `flutter test` passed, and
  `flutter build ipa --release --export-method app-store` passed on
  2026-06-06.

## Screenshot Folders

- Fresh simulator captures, 2026-05-30:
  `/Users/kpc/Documents/GitHub/fSookta/build/store/screenshots_20260530`
- Fresh iPhone 6.9-inch selected screenshots:
  `/Users/kpc/Documents/GitHub/fSookta/build/store/screenshots_20260530/selected_iphone_6_9`
- Fresh iPad 13-inch selected screenshots:
  `/Users/kpc/Documents/GitHub/fSookta/build/store/screenshots_20260530/selected_ipad_13`
- iPhone 6.9-inch selected screenshots:
  `/Users/kpc/Desktop/Sookta_AppStore_v1/selected_iphone_6_9`
- iPad 13-inch selected screenshots:
  `/Users/kpc/Desktop/Sookta_AppStore_v1/selected_ipad_13_reviewed`
- iPad 13-inch previous selected screenshots:
  `/Users/kpc/Desktop/Sookta_AppStore_v1/selected_ipad_13`
- Raw captures:
  `/Users/kpc/Desktop/Sookta_AppStore_v1/iphone_6_9`
  `/Users/kpc/Desktop/Sookta_AppStore_v1/ipad_13`

## Screenshot QA Notes

- Use `selected_ipad_13_reviewed` for App Store Connect iPad screenshots.
- The older iPad selected file `05_language.png` was actually a profile screen
  captured before the three profile stat cards were kept on one row.
- The profile overview screenshots with `Sookta QA` underlined were kept out of
  the reviewed iPad set because they show a debug baseline artifact from the
  simulator capture, not production UI.

## App Information

- Name: `Sookta สุขท่า`
- Subtitle: `ประเมินท่าทางชาวสวนกาแฟ`
- Category: `Health & Fitness`
- Secondary Category: `Education`

## en-US App Information

- Name: `Sookta`
- Subtitle: `Coffee posture risk check`
- Category: `Health & Fitness`
- Secondary Category: `Education`

## Promotional Text

สุขท่าช่วยชาวสวนกาแฟประเมินความเสี่ยงจากท่าทางทำงาน พร้อมคำแนะนำเบื้องต้นและผลกระทบทางเศรษฐกิจเพื่อใช้สื่อสารในงานวิจัย

## Description

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

## Keywords

สุขท่า,ประเมินท่าทาง,ชาวสวน,กาแฟ,ความเสี่ยง,สรีรศาสตร์,ปวดหลัง,ท่าทำงาน,REBA,เกษตร

## What's New In Version 1.1.2

ปรับปรุงการประเมิน REBA/ISO ให้สอดคล้องกับเอกสารอ้างอิงมากขึ้น เพิ่มการแยกโมเดลความเสี่ยงท่าทางและการทำนายแนวโน้ม 7 รายการล่าสุด ปรับข้อความแจ้งเตือนเมื่อรูปไม่พบท่าทางบุคคล เพิ่มรายงานทดสอบ ML/UAT และปรับปรุงคำแนะนำ เสียงอ่าน ประวัติ และการส่งออกข้อมูลสำหรับงานวิจัย

## en-US Promotional Text

Assess coffee-farming posture risk on device, review affected body areas, hear guidance, and export research records.

## en-US Description

Sookta is an education and research-support app for ergonomic risk awareness in coffee-farming workflows. It helps users assess posture-related ergonomic risks for activities such as transplanting, fertilizing, spraying, pruning, harvesting, and transporting produce.

Users can capture a posture photo or select an image from the photo library. The app summarizes the risk level, affected body areas, posture recommendations, and estimated economic impact so farmers, field staff, and research teams can better understand the potential impact of unsafe working postures.

Key features:

- Thai and English language support
- Multiple participant or farmer profiles on one device
- Coffee-farming activity selection
- Camera and photo library support for posture assessment
- Offline ergonomic risk assessment on device
- REBA and ISO11228-informed risk scoring for relevant workflows
- Body map showing affected or high-risk body areas
- Activity-specific recommendations to help reduce ergonomic risk
- Text-to-speech guidance in Thai and English
- Local assessment history and CSV export for field staff or researchers

Important notice: Sookta is intended for ergonomic risk communication, education, and research-support purposes only. It is not a medical diagnosis tool, not a regulated medical device, not a clinical injury prediction tool, and not an exact personal medical-cost or economic-loss calculator. If you have pain, injury, or health concerns, please consult qualified medical personnel.

## en-US Keywords

ergonomics,posture,coffee,farming,risk,REBA,ISO11228,back pain,research,farmer

## en-US What's New In Version 1.1.2

Improved REBA/ISO assessment alignment, separated posture-risk and 7-record trend-prediction model flows, improved invalid posture-photo messaging, updated ML/UAT reports, and refined recommendations, text-to-speech, history, and research export support.

## Review Notes

This app is a research prototype for ergonomic risk communication and education for Thai coffee farmers. It is not a medical diagnosis tool, clinical injury prediction tool, or exact economic forecasting system.

Camera and photo library access are used so participants can capture or select posture images for ergonomic assessment. Profile and history data are stored locally on the device unless the user manually exports or shares a CSV file.

Firebase Analytics and Crashlytics are enabled to monitor app quality, crashes,
and basic product interaction events. They are not used for advertising or
cross-app tracking.

## URLs To Prepare

- Privacy Policy URL: required before submission.
- Thai Support URL:
  `https://docs.google.com/document/d/1wMofRzvLG356_l-S5cXJonhcwoeYvgc_rnykpugMFIY`
- Marketing URL: optional.
