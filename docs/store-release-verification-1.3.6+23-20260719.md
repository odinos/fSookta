# Store Release Verification — Sookta 1.3.6+23

วันที่ตรวจ: 19 กรกฎาคม 2026  
Branch: `codex/ios-real-integrations`

## สาเหตุที่ต้องสร้าง build 23

App Store validation ของ build 22 ปฏิเสธ iPad bundle เพราะแอปประกาศรองรับเฉพาะ `UIInterfaceOrientationPortrait` แต่ยังไม่ได้ opt out จาก iPad multitasking ซึ่งกำหนดให้แอปต้องรองรับทั้ง 4 orientations

Release นี้ยังคงข้อกำหนด portrait-only และเพิ่ม:

```xml
<key>UIRequiresFullScreen</key>
<true/>
```

จึงเป็นการบอกระบบว่า iPad app ต้องใช้ compatibility mode สำหรับแอปที่ล็อก orientation แทนการเปิด landscape เพื่อผ่าน validation

## ผลทดสอบ

- Version: `1.3.6+23`
- Bundle/Application ID: `com.kdev.sookta`
- `flutter analyze --no-pub`: PASS — ไม่พบ issue
- `flutter test --no-pub`: PASS — `119/119`
- Regression test ยืนยัน `UIRequiresFullScreen=true`: PASS
- iPhone orientations: portrait only
- iPad orientations: portrait only

## Android App Bundle

ไฟล์: `outputs/store-builds/1.3.6+23/Sookta-1.3.6+23-android-release.aab`

- Bundletool validation: PASS
- Package: `com.kdev.sookta`
- Version name: `1.3.6`
- Version code: `23`
- Target SDK: `36`
- Orientation: portrait

## iOS App Store IPA

ไฟล์: `outputs/store-builds/1.3.6+23/Sookta-1.3.6+23-ios-appstore.ipa`

- Xcode archive: PASS
- Xcode App Store export: PASS
- Bundle ID: `com.kdev.sookta`
- Version: `1.3.6`
- Build: `23`
- Deployment target: iOS 15.0
- `UIRequiresFullScreen`: `true`
- iPhone orientations: `UIInterfaceOrientationPortrait`
- iPad orientations: `UIInterfaceOrientationPortrait`
- Signing type: Apple Distribution
- Provisioning profile: `Sookta AppStore com.kdev.sookta`
- Team ID: `RN66WU3W56`
- `get-task-allow`: `false`
- `beta-reports-active`: `true`

ค่าข้างต้นตรวจจาก `Info.plist` ภายใน IPA ที่ export แล้ว ไม่ใช่เฉพาะไฟล์ source

## SHA-256

```text
f6a7d58dbe029b93869c2c56d886725a76c9b2ce2aecbe1414ecef13f97b91f9  Sookta-1.3.6+23-android-release.aab
618e954644f8d12df1848c76607b830b51010e208e8e82ec4bf3119eefbc9dab  Sookta-1.3.6+23-android-mapping.txt
f9f9dc4e9360e18d612e9760206e816afce63e56f5e8b1ed30c6bd3257d38349  Sookta-1.3.6+23-ios-appstore.ipa
```
