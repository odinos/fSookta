# Sookta Full-System UAT Report

วันที่ทดสอบ: 2026-06-06  
Branch: `codex/ios-real-integrations`  
Commit ที่อ้างอิง: `44e2b0d`  
App version: `1.1.2+10`  
Bundle/Application ID: `com.kdev.sookta`

## Executive Summary

รอบนี้เป็นการพยายามทำ UAT ทั้งระบบบนอุปกรณ์จริง 2 ฝั่ง คือ iPhone และ Android ตั้งแต่ first-run/onboarding ไปจนถึง evaluation, ML, result, recommendation, export, history, help, references, TTS และ telemetry

ผลตามหลักฐานจริง:

- Static validation ผ่าน: `flutter analyze` ไม่มี issue และ `flutter test` ผ่านทั้งหมด 35 tests
- iOS real device เห็นเครื่องจริง, build/install/launch ผ่านจาก temp worktree ที่สะอาด และเริ่ม integration test ได้
- iOS automated screenshot harness ค้างหลัง launch จึงยังไม่ถือว่า screenshot UAT ครบทุกหน้า
- Android real device ยัง `unauthorized` ผ่าน ADB/Flutter จึงยังไม่สามารถติดตั้งหรือทำ UAT จริงบน Android ได้
- Camera, gallery, TTS listening, export/share sheet และ offline ML จากรูปจริง ยังต้องทำ manual UAT ต่อบนเครื่องจริง เพราะต้องใช้ interaction กับ device/permission/เสียงจริง

## Device And Environment

| รายการ | ผล |
|---|---|
| iOS device | `iPhone` identifier `00008030-0008788421F3802E`, iOS 26.5, paired/available |
| iOS model จาก devicectl | iPhone SE (iPhone12,8) |
| Android device | `R5CW13JKESA` |
| Android status | `unauthorized usb:1-1.4` |
| Flutter SDK | `/Users/kpc/develop/flutter/bin/flutter` |
| Android ADB | `/Users/kpc/Library/Android/sdk/platform-tools/adb` |
| Test date/timezone | 2026-06-06 Asia/Bangkok |

## Commands Executed

| Command | Result |
|---|---|
| `flutter devices` | iPhone detected; Android shown as `not authorized` |
| `adb devices -l` | `R5CW13JKESA unauthorized` |
| `xcrun devicectl list devices` | iPhone available/paired |
| `flutter analyze` | PASS: `No issues found` |
| `flutter test` | PASS: 35 tests passed |
| `flutter test integration_test/screenshot_parity_test.dart -d 00008030-0008788421F3802E` from repo path | FAIL: iOS codesign blocked by xattr/resource fork metadata |
| Same integration test from `/private/tmp/fSookta-uat-minimal-20260606` | BUILD/INSTALL/LAUNCH PASS, but screenshot harness did not complete after 5m31s |

## Automated Validation Passed

Unit/widget test coverage that passed in this run:

- REBA official table behavior, including deep forward bending not reported as low risk
- ISO lifting and push/pull calculation paths
- Combined REBA + ISO risk uses the higher real-task risk
- Activity-specific recommendation text is bundled in Thai and English
- Pose landmarks can auto-fill REBA posture scores
- Deep bending pose is scored as trunk risk instead of arm-only risk
- Export CSV generation for summary, history, and all-farmer worksheet
- Economic impact cost table and body-area cost estimates
- Daily injury Logistic Regression waits for 7 transactions and flags repeated high trunk-risk history
- Risk alert model loading and feature contribution tests
- Widget tests for onboarding render and farmer manager language switching

## iOS Real Device Result

| Area | Status | Evidence / Notes |
|---|---|---|
| Device detection | PASS | Flutter and `devicectl` detect iPhone |
| Build/install/launch | PASS from temp worktree | App installed and launched on iPhone through integration test runner |
| Repo-path iOS build | BLOCKED | Codesign failed because generated build artifacts had `resource fork, Finder information, or similar detritus not allowed` |
| First-run screenshot harness | BLOCKED | Test launched but did not complete after 5m31s; process was terminated to avoid leaving a stuck session |
| TTS engine initialization | PARTIAL PASS | Log shows iOS selected Thai voice `Kanya`, locale `th-TH`, quality `default/super-compact` |
| TTS audio quality | MANUAL REQUIRED | Must be listened to on iPhone speaker/headphones; code cannot verify clarity |
| Camera/gallery permissions | MANUAL REQUIRED | Need physical device interaction with permission dialogs |
| Export/share sheet | MANUAL REQUIRED | Share sheet cannot be fully validated by headless command alone |

Important iOS log captured:

```text
SooktaTTS: iOS audio shared=1 category=1
SooktaTTS: available voices=180 desired=th-TH selected={locale: th-TH, name: Kanya, quality: default, gender: female, identifier: com.apple.voice.super-compact.th-TH.Kanya}
SooktaTTS: volume=1 voiceOrLanguage=1
```

Interpretation: app-level TTS setup runs, but this iPhone currently resolves to a compact Thai voice. For clearer Thai voice, install/download an enhanced Thai voice in iOS Speech settings if available, then retest.

## Android Real Device Result

| Area | Status | Evidence / Notes |
|---|---|---|
| ADB detection | BLOCKED | `R5CW13JKESA unauthorized usb:1-1.4` |
| Flutter device detection | BLOCKED | Flutter reports Android device is not authorized |
| Fresh install | NOT EXECUTED | Cannot install until USB debugging authorization is accepted |
| Camera/gallery/TTS/export/ML | NOT EXECUTED | Blocked by Android authorization |

Android next action:

1. On Android device, open Developer options.
2. Use `Revoke USB debugging authorizations`.
3. Unplug and reconnect USB cable.
4. When prompted, tap `Allow USB debugging` and optionally `Always allow from this computer`.
5. Verify with `/Users/kpc/Library/Android/sdk/platform-tools/adb devices -l`.

## Page And Function UAT Matrix

Legend:

- `PASS-CODE`: validated by analyze/unit/widget test or code path
- `PASS-IOS-LAUNCH`: iOS app build/install/launch reached this UAT session, but page not manually completed
- `PENDING-DEVICE`: must be touched/listened/confirmed on physical device
- `BLOCKED`: cannot execute due device/tooling blocker

| Page / Function | iOS | Android | Current Result |
|---|---:|---:|---|
| Fresh install / first app launch | PASS-IOS-LAUNCH | BLOCKED | iOS launch works from temp worktree; Android unauthorized |
| Splash routing | PASS-CODE | PASS-CODE | Widget test confirms onboarding render after splash |
| Language selection Thai/English | PASS-CODE, PENDING-DEVICE | BLOCKED | Route exists and widget coverage present; device tap not completed |
| Setup profile / participant code / role / gender | PASS-CODE, PENDING-DEVICE | BLOCKED | Code includes randomized participant ID action and role selector; manual form UAT pending |
| TTS guidance on onboarding/setup | PARTIAL PASS, PENDING-DEVICE | BLOCKED | iOS TTS initializes; audio clarity must be listened to |
| Avatar selection from built-in avatar | PASS-CODE, PENDING-DEVICE | BLOCKED | Route covered by integration harness but harness did not complete |
| Avatar from gallery/camera file path | PENDING-DEVICE | BLOCKED | Needs real permission dialogs and media picker |
| Home tab / active farmer overview | PASS-CODE, PENDING-DEVICE | BLOCKED | Harness includes Home screen; not completed |
| Profile tab | PASS-CODE, PENDING-DEVICE | BLOCKED | Route and language edit paths exist |
| Manage Farmers add/edit/delete/select | PASS-CODE, PENDING-DEVICE | BLOCKED | Widget language test passed; manual CRUD pending |
| Evaluation menu / activity selection | PASS-CODE, PENDING-DEVICE | BLOCKED | Route exists; TTS added on activity cards |
| Evaluation form top/bottom responsive layout | PASS-CODE, PENDING-DEVICE | BLOCKED | Harness includes form screens; not completed |
| Activity-specific process defaults | PASS-CODE | PASS-CODE | Covered in calculator/service tests indirectly |
| Load dropdown with kg labels | PASS-CODE, PENDING-DEVICE | BLOCKED | Screenshots existed from earlier QA; current device UAT pending |
| Camera capture | PENDING-DEVICE | BLOCKED | Requires real camera permission and physical capture |
| Gallery picker | PENDING-DEVICE | BLOCKED | Requires real photo permission and media selection |
| Invalid image/person-not-found guard | PASS-CODE, PENDING-DEVICE | BLOCKED | Code path/test coverage exists; real image negative test pending |
| MoveNet pose extraction | PASS-CODE, PENDING-DEVICE | BLOCKED | Unit test covers landmarks -> REBA scoring; real photo inference pending |
| XGBoost/ONNX risk alert | PASS-CODE, PENDING-DEVICE | BLOCKED | Model load/feature tests pass; real-device inference pending |
| REBA calculation | PASS-CODE | PASS-CODE | Official table and deep bending tests pass |
| ISO11228 calculation | PASS-CODE | PASS-CODE | Lifting/push-pull tests pass |
| Combined REBA + ISO risk | PASS-CODE | PASS-CODE | Test confirms higher real-task risk is kept |
| Initial Risk Result | PASS-CODE, PENDING-DEVICE | BLOCKED | Harness includes screen; not completed |
| Body risk map and risky parts | PASS-CODE, PENDING-DEVICE | BLOCKED | Tests and screen code present; device visual pending |
| Economic impact layer | PASS-CODE, PENDING-DEVICE | BLOCKED | Cost table and estimate tests pass |
| Recommendation selection | PASS-CODE, PENDING-DEVICE | BLOCKED | Recommendation bundle test passes; manual checkbox flow pending |
| Before/after score comparison | PASS-CODE, PENDING-DEVICE | BLOCKED | Calculation path exists; manual UX pending |
| Final result save | PASS-CODE, PENDING-DEVICE | BLOCKED | Export/history tests validate saved record format |
| Daily 7-transaction injury prediction | PASS-CODE, PENDING-DEVICE | BLOCKED | Logistic Regression tests pass; device alert flow pending |
| History list | PASS-CODE, PENDING-DEVICE | BLOCKED | Harness includes screen; not completed |
| History detail | PASS-CODE, PENDING-DEVICE | BLOCKED | Harness includes screen; not completed |
| Export single history CSV | PASS-CODE, PENDING-DEVICE | BLOCKED | CSV test passes; share sheet pending |
| Export all farmers CSV | PASS-CODE, PENDING-DEVICE | BLOCKED | All-farmer worksheet CSV test passes |
| Help page | PASS-CODE, PENDING-DEVICE | BLOCKED | Route exists with Thai/English content and TTS |
| References page | PASS-CODE, PENDING-DEVICE | BLOCKED | Route exists; references content present |
| Terms page | PASS-CODE, PENDING-DEVICE | BLOCKED | Route exists; manual scroll/read pending |
| Contact/support page | PASS-CODE, PENDING-DEVICE | BLOCKED | Route exists; manual link/open pending |
| Localization switch after setup | PASS-CODE, PENDING-DEVICE | BLOCKED | Farmer manager language widget test passes |
| Firebase Analytics / Crashlytics | PASS-CODE, PENDING-DASHBOARD | BLOCKED | Code initializes Firebase and logs events; dashboard verification requires real app use/network |
| Offline behavior | PASS-CODE, PENDING-DEVICE | BLOCKED | ML assets are local; real no-network test pending |

## Defects / Blockers

| ID | Severity | Title | Evidence | Recommended Action |
|---|---:|---|---|---|
| UAT-BLK-001 | P0 | Android device not authorized | `R5CW13JKESA unauthorized` | Accept USB debugging prompt on Android, then rerun install/UAT |
| UAT-BLK-002 | P1 | iOS build from repo path hits xattr/codesign metadata | `resource fork, Finder information, or similar detritus not allowed` | Build from clean temp path or move repo/build artifacts out of file-provider affected path; keep using `COPYFILE_DISABLE=1` |
| UAT-BLK-003 | P1 | iOS automated screenshot harness does not complete after launch | test reached `captures iPhone screenshot parity screens` but did not complete after 5m31s | Split harness into smaller smoke tests, add timeout/logging per screen, or use manual UAT screenshots |
| UAT-BLK-004 | P1 | Android full UAT cannot start | ADB unauthorized | Same as UAT-BLK-001 |
| UAT-OBS-001 | P2 | iOS Thai TTS selected compact voice | `com.apple.voice.super-compact.th-TH.Kanya` | Install enhanced/premium Thai voice if available; retest clarity |

## Required Manual UAT To Finish "Complete UAT"

These steps still need to be completed on both physical devices after blockers are cleared.

### Fresh Install And Onboarding

1. Uninstall Sookta from device.
2. Install latest build.
3. Open app.
4. Select Thai, then repeat once with English.
5. Confirm splash routes to language screen on a fresh install.
6. Enter setup profile with generated participant code.
7. Select role `ชาวสวน` and `เจ้าหน้าที่`.
8. Confirm age/weight/height row layout does not overflow.
9. Confirm TTS can read setup guidance clearly.
10. Select built-in avatar and verify Home opens.

### Farmer Management

1. Open Profile > Manage Farmers.
2. Add farmer.
3. Edit farmer.
4. Delete farmer.
5. Select another farmer and confirm Home/History links data to active farmer.
6. Switch language and confirm labels update without broken Thai/English text.

### Evaluation And ML

1. Open Evaluation menu.
2. Select every activity type.
3. Add photo from gallery.
4. Capture photo from camera.
5. Use at least one valid person posture image.
6. Use at least one invalid/no-person image and confirm no misleading numeric result is shown.
7. Confirm MoveNet/pose extraction creates body posture inputs.
8. Confirm deep forward bending identifies trunk/back risk and not arm-only risk.
9. Confirm REBA score, ISO risk if applicable, and combined risk are shown.
10. Confirm load choices show kg labels.
11. Confirm risk recommendation matches affected body parts.

### Result, Recommendation, History, Export

1. Open Initial Result.
2. Confirm body map and risky-part list are visible.
3. Confirm economic impact section is understandable and not overstated as medical diagnosis.
4. Select recommendations.
5. Confirm score improvement/before-after section updates.
6. Save Final Result.
7. Open History list.
8. Open History detail.
9. Export one record.
10. Export all farmers.
11. Confirm share sheet opens and output CSV can be opened in spreadsheet app.

### TTS

1. Test TTS on Language screen.
2. Test TTS on Setup fields.
3. Test TTS on Evaluation menu/activity cards.
4. Test TTS on Evaluation guidance.
5. Test TTS on Initial Result.
6. Test TTS on Recommendations.
7. Test TTS on Final Result/History/Help/References/Terms where available.
8. Record whether Thai voice is clear enough for farmer users.

### Telemetry

1. Run app with internet enabled.
2. Complete one assessment.
3. Create one export.
4. Force a test crash only in a debug/internal build if a crash test hook exists.
5. Confirm Firebase Analytics dashboard receives route/event logs.
6. Confirm Firebase Crashlytics dashboard receives crash/non-fatal logs.

## Conclusion

The app is code-valid and the core ergonomic calculation tests are passing, including the recent fixes for REBA deep bending and REBA + ISO separation. However, full UAT on both physical devices is not complete yet because Android is blocked by USB debugging authorization and iOS automated screenshot UAT launched but did not finish.

The next practical step is to clear Android ADB authorization, then perform the manual physical-device UAT checklist above on both iPhone and Android, especially camera/gallery, real-photo ML, TTS listening quality, export/share sheet, and Firebase dashboard verification.
