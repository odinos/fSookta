# SookTa QA Report: Requirement 1-5 Real Device Installation and Acceptance Test

วันที่ทดสอบ: 7 กรกฎาคม 2026  
ผู้ทดสอบ: Codex  
โปรเจกต์: SookTa Application  
เวอร์ชันแอป: 1.3.6+21  
Commit ที่ใช้ทดสอบ: 4e424b5  

## สรุปผล

ผลโดยรวม: ผ่านแบบมีข้อจำกัดด้าน automation บน iPhone จริง

แอปจริงแบบ release สามารถ build, sign, install และ launch บน iPhone จริงได้สำเร็จ ไม่มี crash ทันทีหลังเปิดแอปจาก log ที่ตรวจในช่วง smoke test

ชุดทดสอบ functional acceptance สำหรับข้อ 1-5 ผ่านทั้งหมดบน Flutter test runner จำนวน 13 tests

ข้อจำกัดที่พบ: การรัน integration test runner โดยตรงบน iPhone จริงยังติดปัญหา Xcode CodeSign จาก macOS extended attributes ใน build output ระหว่างขั้นตอน package/sign ของ Flutter/Xcode ไม่ใช่ failure จาก logic ของ requirement ข้อ 1-5

## สภาพแวดล้อมที่ใช้ทดสอบ

| รายการ | ค่า |
|---|---|
| เครื่องจริง | iPhone SE |
| Model | iPhone12,8 |
| iOS | 26.5 (23F77) |
| Device UDID | 00008030-0008788421F3802E |
| CoreDevice identifier | ABD658CA-9FDE-5F6E-8228-CFE6D830F4AE |
| Flutter SDK | /Users/kpc/develop/flutter |
| Xcode | 26.6 |
| Bundle ID | com.kdev.sookta |
| Signing identity | Apple Development: Methee Treewichian |

## ขั้นตอนติดตั้งบนเครื่องจริง

| ขั้นตอน | คำสั่ง/วิธี | ผลลัพธ์ |
|---|---|---|
| ตรวจเครื่องที่ต่ออยู่ | `xcrun devicectl list devices` และ `flutter devices` | พบ iPhone จริง สถานะ available/paired |
| Build release app | `flutter build ios --release --no-codesign` | ผ่าน ได้ `build/ios/iphoneos/Runner.app` ขนาด 90.9 MB |
| สร้าง app bundle ที่ไม่มี metadata รบกวน codesign | `ditto --norsrc --noextattr build/ios/iphoneos/Runner.app /private/tmp/sookta-release-qa/Runner.app` | ผ่าน |
| Sign embedded frameworks | `codesign` ทุก framework ใน `Runner.app/Frameworks` | ผ่าน |
| Sign app bundle | `codesign` ที่ `/private/tmp/sookta-release-qa/Runner.app` | ผ่าน |
| ติดตั้งบน iPhone | `xcrun devicectl device install app --device 00008030-0008788421F3802E /private/tmp/sookta-release-qa/Runner.app` | ผ่าน |
| Launch แอป | `xcrun devicectl device process launch --device 00008030-0008788421F3802E com.kdev.sookta` | ผ่าน |
| ตรวจ log หลัง launch | `idevicesyslog -u 00008030-0008788421F3802E -p Runner` | ไม่พบ immediate crash ในช่วง smoke test |

## ขอบเขต Requirement ที่ทดสอบ

| ข้อ | Requirement | สิ่งที่ต้องยืนยัน |
|---|---|---|
| 1 | บันทึกข้อมูลประเมินให้ครบและไม่สูญหาย | ข้อมูลประเมิน, profile, activity, score, suggestion และ breakdown ถูกบันทึกและ restore ได้ |
| 2 | เปลี่ยนกิจกรรม/ท่าทางก่อนบันทึกผล | ก่อนยืนยันต้องยังไปผลลัพธ์สุดท้ายไม่ได้ และต้องมีทางเลือกแก้ข้อมูลก่อนบันทึก |
| 3 | บันทึกแบบร่างและกลับมาทำต่อ | แบบร่างถูก restore กลับเข้า form ได้ และถูกล้างหลัง save สำเร็จ |
| 4 | ตรวจข้อมูลจำเป็นก่อนส่งประเมิน | ข้อมูลผิด/ขาดต้องแสดงข้อความเตือนและปิดปุ่มประเมิน |
| 5 | รายงานส่งออกมีข้อมูลอ้างอิงครบ | CSV export ต้องมีแหล่งอ้างอิง วิธีประเมิน และหมายเหตุขอบเขตการใช้งาน |

## ผลทดสอบรายข้อ

| ข้อ | เคส | Expected Result | Actual Result | สถานะ |
|---|---|---|---|---|
| 1 | Save evaluation แล้ว restore state ใหม่ | ประวัติมี 1 record พร้อม field สำคัญครบ | record restore ได้ครบ: profile, activity, score, suggestion, breakdown | ผ่าน |
| 1 | Guard: ไม่ควรมี phantom record ก่อน save | ไม่มี record แปลกปลอมใน history | ตรวจจาก restore state และ history lookup ไม่พบ record ที่ไม่ได้ save | ผ่าน |
| 2 | ก่อนติ๊กยืนยันข้อมูล | ปุ่ม `ดูผลหลังปรับปรุง` ต้อง disabled | ปุ่ม disabled และมีทางเลือกแก้ท่าทาง/เลือกกิจกรรมใหม่ | ผ่าน |
| 2 | หลังติ๊กยืนยันข้อมูล | ปุ่ม `ดูผลหลังปรับปรุง` ต้อง enabled | ปุ่ม enabled หลังยืนยัน | ผ่าน |
| 3 | มี draft เดิมแล้วเปิด form | ต้องเห็นข้อความนำ draft กลับมาและข้อมูลเดิมใน form | draft restore ได้ รวมรูป, tool, ค่าแรง/ระยะ, advanced detail | ผ่าน |
| 3 | Save evaluation สำเร็จหลังมี draft | draft ต้องถูกล้าง ไม่กลับมาซ้ำ | draft เป็น null หลัง save และ restore แล้วยังไม่มี draft | ผ่าน |
| 4 | ใส่ข้อมูลตัวเลขผิดหรือขาด | ต้องแสดงรายการข้อมูลผิดและ block การประเมิน | แสดง H/V/transport error และปุ่มประเมิน disabled | ผ่าน |
| 4 | ข้อมูลจำเป็นถูกต้อง | ไม่ควรแสดง required-data error | ไม่พบข้อความ required-data error | ผ่าน |
| 5 | Export record แบบ push/pull | ต้องมี reference ISO11228-2 และ scope note | CSV มี `ISO11228-2`, แหล่งอ้างอิง และหมายเหตุไม่ใช่ใบรับรองแพทย์ | ผ่าน |
| 5 | Export record แบบ lifting/combined | ต้องมี reference schema และ source REBA/ISO11228-1 | CSV มี `export_schema_version`, `assessment_reference_sources`, `REBA`, `ISO 11228-1:2021` | ผ่าน |

## Automated Test Evidence

คำสั่งที่รัน:

```bash
/Users/kpc/develop/flutter/bin/flutter test --reporter expanded \
  test/app_state_evaluation_persistence_test.dart \
  test/initial_risk_confirmation_test.dart \
  test/evaluation_draft_flow_test.dart \
  test/evaluation_draft_state_test.dart \
  test/evaluation_form_required_data_validation_test.dart \
  test/assessment_export_service_test.dart
```

ผลลัพธ์:

```text
00:01 +13: All tests passed!
```

คำสั่งตรวจ static analysis:

```bash
/Users/kpc/develop/flutter/bin/flutter analyze lib test integration_test/requirements_1_5_device_acceptance_test.dart
```

ผลลัพธ์:

```text
No issues found!
```

## Device Automation Attempt

มีการเพิ่ม target สำหรับทดสอบ acceptance บน device:

```text
integration_test/requirements_1_5_device_acceptance_test.dart
```

ผลการตรวจไฟล์:

```text
flutter analyze lib test integration_test/requirements_1_5_device_acceptance_test.dart
No issues found!
```

ผลการรันบน iPhone จริงด้วย `flutter test -d 00008030-0008788421F3802E`:

```text
Failed to build iOS app
Command CodeSign failed with a nonzero exit code
resource fork, Finder information, or similar detritus not allowed
```

การวิเคราะห์สาเหตุ:

1. Flutter/Xcode สร้าง framework และ app bundle ใน build output ที่มี macOS extended attributes เช่น `com.apple.FinderInfo`, `com.apple.fileprovider.fpfs#P`, `com.apple.provenance`
2. Build phase เดิมของโปรเจกต์มีการล้าง metadata แล้ว แต่ Xcode บางขั้นตอน เช่น `CopySwiftLibs` และ final packaging สามารถเติม metadata กลับมาหลัง build phase นั้น
3. เมื่อถึง final CodeSign ของ `Runner.app` หรือ framework ภายใน app จึงถูกปฏิเสธโดย codesign
4. การ build release แบบ `--no-codesign` แล้ว manual sign หลังล้าง metadata สามารถติดตั้งและ launch บนเครื่องจริงได้

## ข้อจำกัดของผลทดสอบรอบนี้

1. ทดสอบ install และ launch บน iPhone จริงสำเร็จ
2. ทดสอบ functional behavior ข้อ 1-5 ด้วย automated Flutter test runner สำเร็จ
3. ยังไม่สามารถรัน integration test runner แบบ fully automated บน iPhone จริงจนจบได้ เพราะติดปัญหา build/signing environment
4. ยังไม่ได้ทำ manual tap-through ทุกหน้าบน iPhone จริง เนื่องจากรอบนี้ใช้ devicectl/syslog และไม่มีเครื่องมือควบคุม UI physical device แบบกดหน้าจอครบ flow

## ข้อเสนอแนะเพื่อให้รัน Device Automation ได้เต็มรูปแบบในรอบถัดไป

| ลำดับ | งานที่ควรทำ | เหตุผล |
|---|---|---|
| 1 | ปรับ iOS build pipeline ให้ล้าง xattr หลัง `CopySwiftLibs` และก่อน final CodeSign | เพื่อให้ `flutter test -d iPhone` และ `flutter run` ไม่ล้มที่ CodeSign |
| 2 | ทำ script sign/install สำหรับ QA โดยเฉพาะ | ใช้เป็น fallback เมื่อ Xcode/Flutter ติด metadata จาก File Provider |
| 3 | เพิ่ม XCUITest หรือ Maestro/Appium สำหรับกด UI บนเครื่องจริง | จะทำให้ยืนยัน flow ด้วยการแตะหน้าจอจริงได้ครบ |
| 4 | เก็บ device log เฉพาะ error/crash แบบ filtered | ลด noise จาก syslog และทำ evidence อ่านง่ายขึ้น |

## สรุปสำหรับผู้ว่าจ้าง

ระบบในข้อ 1-5 ผ่านการตรวจด้านการทำงานหลักแล้ว ได้แก่ การบันทึกประวัติ, การยืนยันก่อนบันทึก, การกลับมาทำแบบร่างต่อ, การเตือนข้อมูลไม่ครบ และการส่งออกรายงานพร้อมแหล่งอ้างอิง

แอปเวอร์ชัน release ถูกติดตั้งและเปิดบน iPhone จริงได้สำเร็จ อย่างไรก็ตาม การรันชุดทดสอบอัตโนมัติบน iPhone จริงยังติดข้อจำกัดจากขั้นตอน signing ของ iOS build environment ซึ่งเป็นปัญหากระบวนการ build/test ไม่ใช่ข้อผิดพลาดของ feature ข้อ 1-5
