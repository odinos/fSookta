# Store Release Verification — Sookta 1.3.8+25

วันที่ตรวจ: 1 สิงหาคม 2026  
Branch: `codex/recommendation-localization-review`  
Release source commit: `904580f3a269a7d18b17d89c8c907f585a09f426`

## ขอบเขต release

Release นี้รวมงานปรับถ้อยคำและรูปประโยคคำแนะนำด้านการยศาสตร์ภาษาไทย–อังกฤษที่ผ่านการทบทวนแล้ว และไม่รวมงาน Trend/ML รุ่นใหม่

- Marketing version: `1.3.8`
- Build number: `25`
- Bundle/Application ID: `com.kdev.sookta`
- Commit งานฝึก Trend/ML `4c14457` ไม่ได้เป็น ancestor ของ release นี้: PASS
- ไม่มีการ merge branch `codex/ios-real-integrations` เข้าสู่ release นี้

## ผลทดสอบก่อน build

- `flutter pub get`: PASS; lockfile ไม่เปลี่ยน
- `flutter analyze --no-pub`: PASS — ไม่พบ issue
- `flutter test --no-pub`: PASS — `171/171`
- Version regression test: PASS — source และ in-app build label เป็น `1.3.8+25`
- Store metadata ไทย–อังกฤษ: PASS
- Google Play short descriptions: 44 ตัวอักษรภาษาไทย และ 42 ตัวอักษรภาษาอังกฤษ

## Android App Bundle

ไฟล์: `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-release.aab`

- Flutter/Gradle release build: PASS
- Bundletool 1.18.1 validation: PASS
- JAR signature verification: PASS (`jar verified`)
- Upload certificate owner: `CN=Methee Treewichian, L=Sainoi, ST=Nonthaburi, C=TH`
- Upload certificate SHA-1: `90:39:88:23:7D:BE:35:2F:D0:1A:33:F0:F2:70:51:D2:7A:D8:CE:EB`
- Upload certificate SHA-256: `D9:B7:F7:A9:34:17:AE:00:D6:09:CE:23:D9:AF:AE:40:88:D8:BF:2D:01:B0:CC:15:96:57:7F:65:40:CC:59:84`
- Package: `com.kdev.sookta`
- Version name: `1.3.8`
- Version code: `25`
- Compile SDK: `36`
- Target SDK: `36`
- Minimum SDK: `24`
- ABI: `armeabi-v7a`, `arm64-v8a`, `x86_64`
- Size: `149,714,835` bytes

ไฟล์ mapping: `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-mapping.txt`

### หมายเหตุ Android build

คำสั่งแรกที่ใช้ `--no-pub` ข้ามการ regenerate platform tooling ทำให้ `GeneratedPluginRegistrant.java` ที่ค้างจากการรัน test ยังอ้างถึง dev-only `integration_test` ขณะที่ release classpath ตัด dependency นี้ออก จึง compile ไม่ผ่าน การ build ขั้นสุดท้ายใช้ `flutter build appbundle --release` เพื่อให้ Flutter regenerate release registrant ตามปกติ ยืนยันแล้วว่า registrant ขั้นสุดท้ายไม่มี `integration_test` และ build ผ่าน โดยไม่มีการแก้ runtime source หรือเพิ่ม dependency

## iOS App Store IPA

ไฟล์: `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-ios-appstore.ipa`

- สร้างจาก tracked source ใน clean temporary directory: PASS
- Xcode archive: PASS
- Xcode App Store export: PASS
- Flutter App Settings Validation: PASS
- Bundle ID: `com.kdev.sookta`
- Version: `1.3.8`
- Build: `25`
- Deployment target: iOS `15.0`
- Architecture: `arm64`
- `UIRequiresFullScreen`: `true`
- iPhone orientations: `UIInterfaceOrientationPortrait`
- iPad orientations: `UIInterfaceOrientationPortrait`
- Signing type: Apple Distribution
- Signing certificate SHA-1: `90AB5A45873807B86357BC9DB3B2995AA9C6854A`
- Team ID: `RN66WU3W56`
- Provisioning profile: `Sookta AppStore com.kdev.sookta`
- Provisioning profile UUID: `94ecc8dc-3f79-4896-95e6-ecb4c5482439`
- Provisioning profile expiry: `2027-05-23 20:35:57 +07`
- Application identifier: `RN66WU3W56.com.kdev.sookta`
- `get-task-allow`: `false`
- `beta-reports-active`: `true`
- Size: `77,624,305` bytes

### หมายเหตุ iOS signing และ integration test framework

Xcode distribution pipeline archive และ export ด้วย Apple Distribution certificate สำเร็จ และ `DistributionSummary.plist` ยืนยัน certificate, team, version และ provisioning profile ข้างต้น

คำสั่ง `codesign --verify` ภายนอก Xcode บน shell เครื่องนี้รายงาน `CSSMERR_TP_NOT_TRUSTED` และคำสั่ง `security cms` ไม่สามารถ decode embedded profile ได้ แต่ให้ผลเดียวกันกับ IPA รุ่น `1.3.7+24` ที่ผ่านกระบวนการเดิม การตรวจ profile ในรอบนี้ใช้ OpenSSL CMS verification ซึ่งผ่าน (`Verification successful`) และอ่านค่า profile ได้ครบ จึงบันทึกข้อจำกัดของ Keychain trust ใน shell ไว้โดยไม่ตีความเป็น Xcode export failure การยืนยันขั้นสุดท้ายจาก Apple จะเกิดหลังอัปโหลดและผ่าน App Store Connect processing

`integration_test.framework` ขนาดประมาณ 108 KB ยังคงอยู่ใน IPA และ Runner อ้างถึง framework นี้โดยตรง ซึ่งตรงกับ safety decision ที่บันทึกไว้ใน `docs/reviews/local-platform-ml-remediation-result-2026-07-29.md` การลบ framework หลัง build อาจทำให้แอปเปิดไม่ขึ้น จึงไม่ได้ดัดแปลง artifact หลัง Xcode export

## SHA-256

```text
618e954644f8d12df1848c76607b830b51010e208e8e82ec4bf3119eefbc9dab  Sookta-1.3.8+25-android-mapping.txt
68ab2615dfc82d0fd38032fb7d39fe1a05b8a502ccea557ef64b0149454be515  Sookta-1.3.8+25-android-release.aab
783b79a7e09ce9d2c7f1524e526729f0fa160ad36409481530bfbd9d1bd40e63  Sookta-1.3.8+25-ios-appstore.ipa
599b7f1f2bc41969ce8c48ef0a6c3527c25166c0f776c6931efcd15625e05dc6  Sookta-1.3.8+25-ios-distribution-summary.plist
9e5fc4f38661b8a81d1b7fcb90f0772d440301d60dd91e11b9d7bdb47b0f79c4  Sookta-1.3.8+25-ios-export-options.plist
```

## Store metadata

ข้อความพร้อมคัดลอกสำหรับทั้งสองแพลตฟอร์มและสองภาษาอยู่ที่ `docs/store-metadata-1.3.8+25-th-en.md` ประกอบด้วย:

- Apple App Store: ชื่อ คำบรรยาย ข้อความโปรโมต คำอธิบาย คำสำคัญ และ What's New ภาษาไทย–อังกฤษ
- Google Play Store: ชื่อ คำอธิบายสั้น คำอธิบายเต็ม และ What's New ภาษาไทย–อังกฤษ
- ข้อจำกัดการใช้งานและข้อความไม่กล่าวอ้างการวินิจฉัยหรือการรักษาทางการแพทย์

## ขอบเขตการยืนยัน

ไฟล์ในชุดนี้ผ่าน local build, Xcode export, Bundletool validation, metadata inspection, signing inspection, static analysis และ Flutter tests แล้ว การยืนยันฝั่งเซิร์ฟเวอร์ยังต้องเกิดเมื่อเจ้าของบัญชีอัปโหลด AAB เข้า Google Play Console และ IPA เข้า App Store Connect
