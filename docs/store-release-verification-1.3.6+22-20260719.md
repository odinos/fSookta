# Store Release Verification — Sookta 1.3.6+22

วันที่ตรวจ: 19 กรกฎาคม 2026  
Branch: `codex/ios-real-integrations`

## สรุป

Release นี้สร้างจากโค้ดล่าสุดหลังจบการพัฒนาและ UAT ตามข้อกำหนด 15 ข้อ รวมถึงการถอด assessment bypass ออกจาก production, การล็อกหน้าจอแนวตั้ง และการตรวจ UI parity ระหว่าง iOS/Android

- Version name: `1.3.6`
- Build number / Android version code: `22`
- Bundle/Application ID: `com.kdev.sookta`
- `flutter analyze --no-pub`: PASS — ไม่พบ issue
- `flutter test --no-pub`: PASS — `118/118`

## Android App Bundle

ไฟล์: `outputs/store-builds/1.3.6+22/Sookta-1.3.6+22-android-release.aab`

- Release build: PASS
- Bundletool validation: PASS
- Package: `com.kdev.sookta`
- Version name: `1.3.6`
- Version code: `22`
- Target SDK: `36`
- Orientation: portrait
- Upload certificate SHA-256: `D9:B7:F7:A9:34:17:AE:00:D6:09:CE:23:D9:AF:AE:40:88:D8:BF:2D:01:B0:CC:15:96:57:7F:65:40:CC:59:84`
- Upload certificate expiry: 9 ตุลาคม 2053
- R8 mapping: `outputs/store-builds/1.3.6+22/Sookta-1.3.6+22-android-mapping.txt`

## iOS App Store IPA

ไฟล์: `outputs/store-builds/1.3.6+22/Sookta-1.3.6+22-ios-appstore.ipa`

- Xcode archive: PASS
- Xcode App Store export: PASS
- Bundle ID: `com.kdev.sookta`
- Version: `1.3.6`
- Build: `22`
- Deployment target: iOS 15.0
- Architecture: arm64
- Orientation iPhone: portrait only
- Orientation iPad: portrait only
- Signing type: Apple Distribution
- Signing certificate SHA-1: `90AB5A45873807B86357BC9DB3B2995AA9C6854A`
- Provisioning profile: `Sookta AppStore com.kdev.sookta`
- Provisioning expiry: 23 พฤษภาคม 2027
- Team ID: `RN66WU3W56`
- `application-identifier`: `RN66WU3W56.com.kdev.sookta`
- `get-task-allow`: `false`
- `beta-reports-active`: `true`

Xcode สร้าง `DistributionSummary.plist` และ `ExportOptions.plist` ไว้ร่วมกับ release artifacts เพื่อใช้ตรวจข้อมูล signing ย้อนหลัง

หมายเหตุ: คำสั่ง `codesign --verify` ภายนอก Xcode บนเครื่องนี้รายงาน `CSSMERR_TP_NOT_TRUSTED` เพราะ trust chain ใน Keychain ของ shell ไม่พร้อม และให้ผลเดียวกันกับ IPA รุ่น `1.3.6+21` เดิม อย่างไรก็ตาม Xcode distribution pipeline เซ็น app และ embedded frameworks ด้วย Apple Distribution certificate สำเร็จ และ App Store export จบโดยไม่มี signing error การยืนยันขั้นสุดท้ายจาก Apple จะเกิดเมื่อ upload และผ่าน App Store Connect processing

## SHA-256

```text
d82678dbb1d3ef9bc4df69fa6aef0672262cf5fce7be8d2d1d595ba30d6e145a  Sookta-1.3.6+22-android-release.aab
618e954644f8d12df1848c76607b830b51010e208e8e82ec4bf3119eefbc9dab  Sookta-1.3.6+22-android-mapping.txt
7c1a82013623ce6022d4c50e85bde799c5aa9ebcb6da7002932c1786fb80a821  Sookta-1.3.6+22-ios-appstore.ipa
```
