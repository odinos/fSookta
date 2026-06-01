# Sookta

Sookta เป็นแอป Flutter สำหรับงานวิจัยและการสื่อสารความเสี่ยงด้านสรีรศาสตร์ของงานชาวสวนกาแฟ แอปช่วยให้ผู้ใช้ถ่ายรูปหรือเลือกรูปท่าทางการทำงาน ประเมินความเสี่ยงจากท่าทาง แสดงส่วนของร่างกายที่ควรระวัง แสดงผลกระทบทางเศรษฐกิจโดยประมาณ และให้คำแนะนำที่นำไปใช้ลดความเสี่ยงได้

แอปนี้ออกแบบให้ใช้งานแบบ offline-first บน iOS และ Android โดยใช้โมเดลและข้อมูลอ้างอิงที่ bundle อยู่ในแอป ไม่ต้องพึ่ง server สำหรับการประเมินหลัก

## สถานะปัจจุบัน

- Flutter app สำหรับ iOS และ Android
- Version ปัจจุบันใน `pubspec.yaml`: `1.1.0+8`
- Bundle/Application ID: `com.kdev.sookta`
- รองรับภาษาไทยและอังกฤษ
- มี Firebase Crashlytics สำหรับ crash reporting
- ข้อมูลผู้เข้าร่วมวิจัย รูปที่ใช้ประเมิน ประวัติ และไฟล์ export เก็บในเครื่องผู้ใช้เป็นหลัก

## สำหรับผู้ใช้งาน

### แอปนี้ทำอะไร

Sookta ช่วยประเมินความเสี่ยงจากท่าทางการทำงานของชาวสวนกาแฟในกิจกรรม เช่น เพาะปลูก ใส่ปุ๋ย พ่นสาร ตัดแต่ง เก็บเกี่ยว และขนย้ายผลผลิต

ผลลัพธ์ที่แอปแสดงประกอบด้วย:

- ระดับความเสี่ยงจากท่าทาง
- คะแนนและคำอธิบายความเสี่ยง
- แผนภาพร่างกายพร้อมจุดเสี่ยง
- รายการส่วนของร่างกายที่ควรระวัง
- คำแนะนำตามกิจกรรมและระดับความเสี่ยง
- ผลกระทบทางเศรษฐกิจโดยประมาณจากข้อมูลค่าใช้จ่าย
- ประวัติการประเมินและไฟล์ CSV สำหรับเจ้าหน้าที่หรือนักวิจัย

### วิธีใช้งานโดยย่อ

1. เลือกภาษาไทยหรืออังกฤษ
2. อ่านและยอมรับเงื่อนไขการใช้งาน
3. สร้างหรือเลือกข้อมูลเกษตรกร/ผู้เข้าร่วมวิจัย
4. เลือกกิจกรรมการทำงาน
5. ถ่ายรูปท่าทาง หรือเลือกรูปจากคลังภาพ
6. ให้แอปประเมินความเสี่ยง
7. อ่านผลลัพธ์ จุดเสี่ยง คำแนะนำ และผลกระทบโดยประมาณ
8. บันทึกผลลงประวัติ
9. Export CSV เมื่อต้องส่งข้อมูลให้เจ้าหน้าที่หรือนักวิจัย

### ข้อจำกัดสำคัญ

Sookta ไม่ใช่เครื่องมือวินิจฉัยโรค ไม่ใช่อุปกรณ์การแพทย์ และไม่ใช่เครื่องมือยืนยันการบาดเจ็บของบุคคล ผลลัพธ์เป็นข้อมูลเพื่อการสื่อสารความเสี่ยง การศึกษา และการสนับสนุนงานวิจัยด้านสรีรศาสตร์เท่านั้น หากมีอาการเจ็บปวดหรือบาดเจ็บ ควรปรึกษาบุคลากรทางการแพทย์

## การประเมินความเสี่ยงทำงานอย่างไร

แอปใช้กระบวนการประเมินหลายชั้น:

1. รับภาพจากกล้องหรือคลังภาพ
2. ใช้ MoveNet Thunder เพื่อประมาณตำแหน่งข้อต่อร่างกาย
3. แปลงตำแหน่งข้อต่อเป็น feature vector ตาม schema `movenet-thunder-v1-17x3-normalized`
4. คำนวณคะแนนเชิงสรีรศาสตร์จาก REBA สำหรับทุกงาน
5. ถ้างานมีมิติที่เกี่ยวกับการยก ถือ ขนย้าย ดัน ลาก หรือการทำซ้ำ จะนำ ISO 11228 มาพิจารณาร่วมตามความเหมาะสม
6. ใช้โมเดล ML แบบ offline เพื่อช่วยประเมินระดับความเสี่ยง
7. นำผลความเสี่ยงไปแสดงผลร่วมกับ body map, คำแนะนำ และ economic impact layer

โมเดลที่อยู่ในแอป:

- Logistic Regression: `assets/models/logistic_weights.json`
- XGBoost ONNX: `assets/models/xgboost_model.onnx`
- MoveNet Thunder: `assets/ml/movenet_thunder.tflite`

รายละเอียด contract ของโมเดลอยู่ที่ [docs/model-artifact-contract.md](docs/model-artifact-contract.md)

## Economic Impact Layer

ข้อมูลค่าใช้จ่ายทางเศรษฐกิจไม่ได้ใช้เป็น label เพื่อ train โมเดลความเสี่ยงโดยตรง แต่ใช้เป็นชั้นข้อมูลหลังการประเมิน เพื่อช่วยสื่อสารผลกระทบที่ผู้ใช้เข้าใจได้ง่ายขึ้น เช่น:

- ค่าใช้จ่ายตามส่วนของร่างกายที่มีความเสี่ยง
- ค่าใช้จ่ายในการพบแพทย์หรือรับบริการรักษา
- ค่าเดินทาง
- รายได้ที่สูญเสีย
- วันทำงานที่เสียไป

แนวคิดคือให้โมเดลเน้นประเมินความเสี่ยงจากท่าทาง ส่วน economic impact ใช้ช่วยอธิบายผลกระทบให้ชาวสวนและทีมวิจัยเห็นภาพมากขึ้น

## Privacy และข้อมูลผู้ใช้

- แอปไม่ต้อง login
- แอปไม่แสดงโฆษณา
- รูปภาพและประวัติการประเมินเก็บในเครื่องเป็นหลัก
- การ export/share เกิดขึ้นเมื่อผู้ใช้กด export เอง
- Firebase Crashlytics ใช้สำหรับรายงาน crash และช่วยแก้ปัญหา runtime
- ข้อมูลในแอปไม่ควรถูกอธิบายว่าเป็นการวินิจฉัยทางการแพทย์

ถ้ามีการเพิ่ม Analytics, cloud sync, remote database หรือการส่งข้อมูลวิจัยขึ้น server ในอนาคต ต้องอัปเดต Privacy Policy, App Store App Privacy และ Google Play Data Safety ให้ตรงกับพฤติกรรมจริงก่อนส่ง release

## สำหรับนักพัฒนา

### Requirements

- Flutter SDK
- Xcode และ CocoaPods สำหรับ iOS
- Android Studio / Android SDK สำหรับ Android
- Java ที่ใช้ร่วมกับ Android Gradle Plugin ได้
- Apple Developer account สำหรับ archive/upload iOS
- Android upload keystore สำหรับ Play Store release

บนเครื่องนี้ Flutter อยู่ที่:

```sh
/Users/kpc/develop/flutter/bin/flutter
```

ถ้า shell ยังไม่เห็นคำสั่ง `flutter` ให้เพิ่ม PATH:

```sh
export PATH="$PATH:/Users/kpc/develop/flutter/bin"
source ~/.zshrc
flutter --version
```

### Setup

```sh
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

หลังเพิ่มหรือเปลี่ยน native plugin ให้รัน `pod install` ทุกครั้ง

### Firebase Config

ไฟล์ Firebase ที่ต้องมี:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `ios/firebase_app_id_file.json`
- `lib/firebase_options.dart`

ในโปรเจกต์นี้ Firebase ใช้สำหรับ Crashlytics เป็นหลัก ถ้าเปลี่ยน Firebase project หรือ bundle id/package name ต้องตรวจสอบให้ตรงกันทั้ง Android, iOS และ Firebase Console

### โครงสร้างโค้ดสำคัญ

```text
lib/main.dart                         Firebase/Crashlytics bootstrap
lib/app/                              app state, theme, localization entry
lib/core/models/                      assessment, pose, economic models
lib/core/services/                    REBA/ISO calculation, export, ML, TTS-related services
lib/core/ergonomics_risk_prediction/  risk prediction abstraction and predictors
lib/screens/onboarding/               splash, language, setup, avatar
lib/screens/main/                     home, assessment, camera, result, history, help, profile
lib/widgets/                          shared UI widgets such as body map and TTS button
assets/models/                        Logistic/XGBoost/model schema assets
assets/ml/                            MoveNet and risk alert assets
tools/research_dataset/               research dataset extraction/training scripts
docs/                                 handoff, ML, store, UAT, and release notes
```

### Useful Commands

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build appbundle --release
flutter build ipa --release
```

ระหว่าง build iOS ถ้าเจอ error แนว `resource fork, Finder information, or similar detritus not allowed` ให้ build จากสำเนาใน path ที่ไม่ใช่ cloud/FileProvider เช่น `/private/tmp` แล้วค่อยนำ IPA ที่ได้ไป upload

### Store Build Artifacts

ตัวอย่าง artifact ล่าสุดที่เตรียมไว้:

```text
build/store/releases/1.1.0+8/Sookta-1.1.0+8.aab
build/store/releases/1.1.0+8/Sookta-1.1.0+8.ipa
```

ก่อนส่ง Store ทุกครั้งควรตรวจ:

- `flutter analyze`
- `flutter test`
- build Android App Bundle ผ่าน
- build iOS IPA ผ่าน
- camera/gallery/TTS/export/offline ML บนเครื่องจริง
- App Privacy / Data Safety ตรงกับ dependency และพฤติกรรมจริง
- `PrivacyInfo.xcprivacy` ตรงกับ SDK และ data usage จริง

## Model Training และ Dataset

ข้อมูล training อยู่ใน `data/research/` และ script อยู่ใน `tools/research_dataset/`

เอกสารสำคัญ:

- [docs/reba-ml-training-v1.md](docs/reba-ml-training-v1.md)
- [docs/model-artifact-contract.md](docs/model-artifact-contract.md)
- [docs/ml-training-reference-sources.md](docs/ml-training-reference-sources.md)
- [docs/iso11228-app-recommendations.md](docs/iso11228-app-recommendations.md)

หลักการสำคัญ:

- REBA ใช้เป็นฐานสำหรับทุกงาน
- ISO 11228 ใช้เพิ่มเติมเฉพาะงานที่มีมิติ lifting, carrying, pushing, pulling หรือ repetitive handling
- Logistic Regression และ XGBoost ONNX เป็นโมเดล offline สำหรับ A/B testing และการพัฒนางานวิจัยต่อ
- Economic impact เป็น post-assessment layer ไม่ใช่ training label ของโมเดล posture risk

## Store และ Release Docs

- [docs/app-store-connect-v1-metadata.md](docs/app-store-connect-v1-metadata.md)
- [docs/app-store-review-required-fields.md](docs/app-store-review-required-fields.md)
- [docs/app-store-age-rating-answers.md](docs/app-store-age-rating-answers.md)
- [docs/play-store-v1-metadata.md](docs/play-store-v1-metadata.md)
- [docs/android-play-store-release.md](docs/android-play-store-release.md)
- [docs/store-readiness-final-checklist.md](docs/store-readiness-final-checklist.md)

## Development Notes

- อย่าเปลี่ยน bundle id/application id ถ้าไม่จำเป็น
- อย่า commit keystore, key password, provisioning private files หรือไฟล์ secret อื่น
- หลังเพิ่ม native dependency ให้ตรวจ iOS pods และ Android release build
- ทดสอบ camera, gallery, TTS และ ML บนเครื่องจริงก่อนสรุปว่า release พร้อมใช้งาน
- ถ้าเพิ่ม dependency ที่เก็บหรือส่งข้อมูล ต้องอัปเดต privacy documents และ store declarations ให้ตรงทันที
