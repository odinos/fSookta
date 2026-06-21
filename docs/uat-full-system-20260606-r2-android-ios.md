# Sookta Full-System UAT Report - Android First, iOS Follow-up

วันที่ทดสอบ: 2026-06-06  
รอบรายงาน: R2 Android/iOS device UAT attempt  
Branch: `codex/ios-real-integrations`  
App version: `1.1.2+10`  
Bundle/Application ID: `com.kdev.sookta`

## สรุปผู้บริหาร

รอบนี้เริ่มทดสอบจาก Android device ก่อนตามคำขอ แล้วตามด้วย iOS device จริง

ผลล่าสุด:

- Android device authorize แล้ว และ `flutter devices` เห็นเป็น `SM S918B`, Android 16 API 36
- Android debug build สำเร็จ, install สำเร็จ, launch สำเร็จ และจับ screenshot first-run/setup ได้จริง
- Android TTS init ได้: `SooktaTTS: language th-TH available=true`
- Android Firebase logging มี request สำเร็จ: `Status Code: 200`
- Android automated integration screenshot harness ยังไม่จบ (`did not complete`) และ ADB connection หลุดช่วง finalization
- iOS uninstall สำเร็จ, build/sign/install/launch สำเร็จบน iPhone จริง
- iOS TTS init ได้ แต่ยังเลือก Thai compact voice `Kanya`
- iOS screenshot ผ่าน CLI ยังไม่ได้ เพราะ `idevicescreenshot` ติด `Invalid service`

ข้อสรุป: รอบนี้ยืนยันได้ว่าแอปรันจริงบนทั้ง Android และ iOS ได้ แต่ยังไม่ใช่ full functional UAT ที่ครบ camera/gallery/export/TTS listening/ML real-photo ทุก flow เพราะยังมีข้อจำกัดจาก device automation และ connection instability

## Device Inventory

| Device | Result |
|---|---|
| Android | `SM S918B`, serial `R5CW13JKESA`, Android 16 API 36 |
| iOS | iPhone SE `(iPhone12,8)`, identifier `00008030-0008788421F3802E`, iOS 26.5 |
| Android ADB status at start | PASS: `device usb:1-1.4 product:dm3qxxx model:SM_S918B` |
| Android ADB status at end | UNSTABLE: final `adb devices` file showed no attached device after a later disconnect |
| iOS devicectl status | PASS: `available (paired)` |

## Evidence Files

### Android Screenshots

| Evidence | Description |
|---|---|
| `docs/uat_evidence_20260606_android_ios/android/01_launch.png` | First-run language screen after Android install/launch |
| `docs/uat_evidence_20260606_android_ios/android/02_setup.png` | Setup screen top after selecting Thai |
| `docs/uat_evidence_20260606_android_ios/android/03_setup_bottom.png` | Setup screen while keyboard was still open during adb text entry |
| `docs/uat_evidence_20260606_android_ios/android/04_setup_keyboard_closed.png` | Setup state after keyboard close attempt |
| `docs/uat_evidence_20260606_android_ios/android/05_setup_scrolled.png` | Setup lower form: role, age, gender, weight, height, income |
| `docs/uat_evidence_20260606_android_ios/android/06_setup_filled.png` | adb text-entry limitation evidence; numeric text appended to age field |

### Logs / Device Info

| Evidence | Description |
|---|---|
| `docs/uat_evidence_20260606_android_ios/android/launch_logcat_tail.txt` | Android logcat tail after successful launch |
| `docs/uat_evidence_20260606_android_ios/android/adb_devices_final.txt` | Final Android ADB list, showing connection had dropped by that moment |
| `docs/uat_evidence_20260606_android_ios/ios/device_info.txt` | iOS device information |
| `docs/uat_evidence_20260606_android_ios/ios/devicectl_devices_final.txt` | Final iOS devicectl device list |

## Commands And Results

| Command / Action | Result |
|---|---|
| `adb devices -l` | PASS at start: Android authorized |
| `flutter devices` | PASS at start: Android + iPhone visible |
| `adb uninstall com.kdev.sookta` | FAIL: `DELETE_FAILED_INTERNAL_ERROR`, likely because another installed copy was tied to Secure Folder user 150 |
| `pm clear --user 0 com.kdev.sookta` | PASS: cleared user 0 app state |
| `flutter run -d R5CW13JKESA --debug --no-pub` | PASS: Android build/install/launch succeeded |
| Android screenshot capture via `adb exec-out screencap -p` | PASS: screenshots saved |
| Android `flutter test integration_test/screenshot_parity_test.dart -d R5CW13JKESA` | FAIL/BLOCKED: harness did not complete after 3m11s; ADB reported device not found during finalization |
| `xcrun devicectl device uninstall app ... com.kdev.sookta` | PASS: iOS app uninstalled |
| iOS `flutter run -d 00008030... --debug --no-pub` from temp clean worktree | PASS: build/install/launch succeeded |
| `idevicescreenshot` | FAIL/BLOCKED: `Could not start screenshotr service: Invalid service` |

## Android UAT Result

| Area | Status | Notes |
|---|---|---|
| Device authorization | PASS | Android was authorized and visible at the start |
| Fresh-start state | PARTIAL PASS | `pm clear --user 0` succeeded; uninstall failed because of Secure Folder/user profile package issue |
| Build/install/launch | PASS | `app-debug.apk` built and installed; app launched |
| First-run language screen | PASS | Screenshot captured, Thai/English choices visible, layout clean |
| TTS initialization | PASS-CODE/LOG | `SooktaTTS: language th-TH available=true` |
| Firebase connectivity | PARTIAL PASS | Launch log included Firebase request status `200` |
| Setup screen top | PASS | Screenshot shows readable Thai copy, randomized participant code, TTS buttons |
| Setup screen lower fields | PASS-VISUAL | Role, age, gender, weight, height, income visible and responsive |
| Manual adb text-entry form completion | BLOCKED/AUTOMATION LIMITATION | Raw adb input kept focus on wrong field; this is an adb automation limitation, not conclusive app defect |
| Automated screenshot harness | FAIL/BLOCKED | Harness launched but did not complete; finalization saw ADB device not found |
| Camera/gallery/manual ML | NOT EXECUTED | Requires stable device interaction and real permission dialogs |
| Export/share sheet | NOT EXECUTED | Requires completed assessment and manual share sheet interaction |

## iOS UAT Result

| Area | Status | Notes |
|---|---|---|
| Device pairing | PASS | iPhone available/paired in `devicectl` |
| Fresh uninstall | PASS | `App uninstalled` |
| Build/sign/install/launch | PASS | Xcode build done, app installed and launched |
| Runtime log | PASS | Flutter VM service started; app printed TTS initialization logs |
| TTS initialization | PASS-CODE/LOG | Thai voice selected: `com.apple.voice.super-compact.th-TH.Kanya` |
| TTS audio clarity | PENDING-MANUAL | Must be listened to on the physical iPhone |
| iOS screenshot capture via CLI | BLOCKED | `idevicescreenshot` screenshotr service invalid |
| Full page navigation UAT | PENDING-MANUAL | App launched, but automated screenshot capture was not available this round |

## Current Blockers

| ID | Severity | Blocker | Impact | Next Action |
|---|---:|---|---|---|
| UAT-R2-001 | P0 | Android ADB connection unstable after initial success | Blocks long-running integration UAT and reliable final log capture | Reconnect USB cable, avoid hubs, keep phone awake, rerun `adb devices -l` before next UAT |
| UAT-R2-002 | P1 | Android raw adb text entry unreliable on Flutter form fields | Cannot complete setup form reliably through coordinate-only automation | Use manual device input for form UAT, or create dedicated integration test that fills widgets directly |
| UAT-R2-003 | P1 | Android screenshot parity harness does not complete | Automated all-screen capture cannot be accepted as PASS | Split harness into smaller tests with per-screen timeout and remove problematic waits |
| UAT-R2-004 | P1 | iOS CLI screenshot unavailable | Cannot capture iPhone evidence automatically this round | Use Xcode Organizer/device manual screenshot, or configure a supported screenshot service |
| UAT-R2-005 | P2 | iOS Thai TTS uses compact voice | Audio may sound less clear | Install enhanced Thai voice if available and retest listening quality |

## Page / Function Coverage Matrix

| Function | Android | iOS | Result |
|---|---|---|---|
| Install / Launch | PASS | PASS | Both devices launched app successfully |
| Language selection | PASS-VISUAL | PASS-LAUNCH ONLY | Android screenshot captured; iOS launched but screenshot blocked |
| Setup profile screen | PASS-VISUAL | NOT VISUALLY CAPTURED | Android top/lower screenshots captured |
| TTS setup | PASS-LOG | PASS-LOG, PENDING-AUDIO | Code/runtime init logged; human listening still needed |
| Firebase init/connectivity | PARTIAL PASS | NOT DASHBOARD VERIFIED | Android log included successful Firebase request; dashboard not checked |
| Avatar selection | NOT EXECUTED | NOT EXECUTED | Blocked by automation/harness limitation |
| Home/Profile/Farmer manager | NOT EXECUTED | NOT EXECUTED | Needs manual or fixed harness |
| Evaluation menu/form | NOT EXECUTED | NOT EXECUTED | Needs manual or fixed harness |
| Camera capture | NOT EXECUTED | NOT EXECUTED | Must be tested manually on physical device |
| Gallery picker | NOT EXECUTED | NOT EXECUTED | Must be tested manually on physical device |
| MoveNet / real-photo ML | NOT EXECUTED | NOT EXECUTED | Requires camera/gallery completion |
| REBA/ISO calculation logic | NOT RERUN THIS ROUND | NOT RERUN THIS ROUND | Covered by prior automated unit tests, but not rerun in this R2 device round |
| Result/recommendations/history | NOT EXECUTED | NOT EXECUTED | Needs completed assessment flow |
| Export/share sheet | NOT EXECUTED | NOT EXECUTED | Needs completed assessment flow and manual share sheet interaction |

## Findings

1. Android now reaches first-run and setup screens successfully on a real device.
2. Android UI layout on Samsung S23 Ultra-class screen is readable and does not show obvious overflow on language/setup pages.
3. Android TTS and Firebase initialization produce runtime logs, but actual voice clarity still needs human listening.
4. Android connection instability is now the main blocker for long-running automated UAT.
5. iOS build/sign/install/launch is healthy from a clean temp worktree.
6. iOS CLI screenshot capture is blocked by device screenshot service, so visual iOS evidence still needs manual screenshot capture or a different capture tool.
7. Full functional UAT is still pending for camera/gallery/offline ML/export because those flows require stable real-device interaction.

## Recommended Next UAT Pass

1. Keep Android plugged directly into Mac, no hub.
2. Disable sleep/lock screen on Android during UAT.
3. Confirm `adb devices -l` is stable for at least 2 minutes.
4. Do manual Android setup using the phone keyboard, not raw adb text entry.
5. Complete one assessment using gallery image and one using camera.
6. Test invalid/no-person image and confirm no numeric risk result is shown.
7. Save result, open history, export CSV, verify share sheet.
8. Repeat the same functional checklist on iPhone manually.
9. Capture iPhone screenshots manually if `idevicescreenshot` remains unavailable.
10. Fix/split integration screenshot harness for future regression testing.

## Final Status

รอบ R2 นี้ดีขึ้นกว่ารอบก่อนเพราะ Android authorize แล้วและสามารถ build/install/launch ได้จริง พร้อม screenshot evidence จาก Android หลายหน้า ส่วน iOS ก็ยืนยัน build/install/launch ได้จริงหลัง uninstall

ยังไม่ควรสรุปว่า full UAT ทั้งระบบผ่านครบ เพราะ camera/gallery/ML/export/history/recommendation ยังไม่ได้ทดสอบจบจริงบนทั้งสองอุปกรณ์ และ automated harness ยังมี blocker ที่ต้องแก้หรือแทนด้วย manual UAT
