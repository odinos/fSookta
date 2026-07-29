# Store Release Verification — Sookta 1.3.7+24

วันที่ตรวจ: 19 กรกฎาคม 2026  
Branch: `codex/ios-real-integrations`

## สาเหตุที่ต้องสร้างเวอร์ชัน 1.3.7

App Store Connect ปิด pre-release train ของเวอร์ชัน `1.3.6` แล้ว จึงไม่รับ build ใหม่ที่ใช้ marketing version เดิม แม้เลข build จะเพิ่มขึ้นก็ตาม

Release นี้ย้ายไปใช้ train ใหม่:

- Marketing version: `1.3.7`
- Build number: `24`
- ค่าใน source, Android App Bundle และ iOS IPA ตรงกัน

## ผลทดสอบ

- Version: `1.3.7+24`
- Bundle/Application ID: `com.kdev.sookta`
- `flutter analyze --no-pub`: PASS — ไม่พบ issue
- `flutter test --no-pub`: PASS — `120/120`
- Regression test ของเลข Store version: PASS
- Regression test ของ portrait-only และ iPad full-screen: PASS
- iPhone orientations: portrait only
- iPad orientations: portrait only

## Android App Bundle

ไฟล์: `outputs/store-builds/1.3.7+24/Sookta-1.3.7+24-android-release.aab`

- Bundletool validation: PASS
- Package: `com.kdev.sookta`
- Version name: `1.3.7`
- Version code: `24`
- Target SDK: `36`
- Orientation: portrait

## iOS App Store IPA

ไฟล์: `outputs/store-builds/1.3.7+24/Sookta-1.3.7+24-ios-appstore.ipa`

- Xcode archive: PASS
- Xcode App Store export: PASS
- Bundle ID: `com.kdev.sookta`
- Version: `1.3.7`
- Build: `24`
- Deployment target: iOS 15.0
- `UIRequiresFullScreen`: `true`
- iPhone orientations: `UIInterfaceOrientationPortrait`
- iPad orientations: `UIInterfaceOrientationPortrait`
- Signing type: Apple Distribution
- Provisioning profile: `Sookta AppStore com.kdev.sookta`
- Provisioning profile UUID: `94ecc8dc-3f79-4896-95e6-ecb4c5482439`
- Team ID: `RN66WU3W56`
- Signing certificate SHA-1: `90AB5A45873807B86357BC9DB3B2995AA9C6854A`
- `get-task-allow`: `false`
- `beta-reports-active`: `true`

ค่าข้างต้นตรวจจาก `Info.plist` ภายใน IPA ที่ export แล้วและ distribution summary ไม่ใช่เฉพาะไฟล์ source

## SHA-256

```text
f511bd3bdf2507a4d24276e7a59806545594a12d3f4b5e402ddf0aaf81ea70ae  Sookta-1.3.7+24-android-release.aab
618e954644f8d12df1848c76607b830b51010e208e8e82ec4bf3119eefbc9dab  Sookta-1.3.7+24-android-mapping.txt
6f8ff4ed9e65fd63c84aef5d70e57d1b2951ee8bda37da25466d9a4dc1ef390a  Sookta-1.3.7+24-ios-appstore.ipa
e0a3de3683b154ed9a079893524d917777d756e6f70abe17a5f6b0070463c413  Sookta-1.3.7+24-ios-distribution-summary.plist
9e5fc4f38661b8a81d1b7fcb90f0772d440301d60dd91e11b9d7bdb47b0f79c4  Sookta-1.3.7+24-ios-export-options.plist
```

## ขอบเขตการยืนยัน

ชุดไฟล์นี้ผ่านการ build, export, ตรวจ metadata, signing และ regression test ในเครื่องแล้ว การยืนยันจากเซิร์ฟเวอร์ App Store Connect จะสมบูรณ์หลังอัปโหลด IPA ชุดนี้เข้าสู่ train `1.3.7`
