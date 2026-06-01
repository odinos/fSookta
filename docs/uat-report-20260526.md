# fSookta UAT Report - 2026-05-26

## Scope

UAT รอบนี้เป็น automated baseline และ checklist สำหรับ manual UAT ของ fSookta version `1.1.0+6` บน branch `codex/ios-real-integrations`

Update 2026-05-27: resumed real-device UAT from clean archive tree at `/private/tmp/fSookta-uat-archive`, then verified the main source tree at `/Users/kpc/Documents/GitHub/fSookta`.

Update 2026-05-28: resumed again after automation heartbeat. The clean archive tree still exists, but `flutter devices` did not detect the iPhone; only macOS and Chrome were visible. P0 camera/gallery/TTS/export/offline ML checks remain blocked until the iPhone is unlocked, connected, trusted, and visible to Flutter.

Google Sheets checklist/report:
https://docs.google.com/spreadsheets/d/19UJDCacfmsr1KIjxigE4vpH97cnU2Z2sYFJGQ1ikYB8/edit?usp=drivesdk

## Automated Baseline

| Check | Result | Notes |
| --- | --- | --- |
| `flutter analyze` | PASS | No issues found |
| `flutter test` | PASS | 29 tests passed |
| REBA calculation | PASS | Covered by `ergo_calculator_test.dart` |
| ISO11228 + combined risk | PASS | Covered by `ergo_calculator_test.dart` |
| ML risk alert model loading | PASS | Covered by `risk_alert_model_service_test.dart` |
| MoveNet joint feature schema | PASS | Covered by `ergonomic_risk_prediction_test.dart` |
| CSV export | PASS | Covered by `assessment_export_service_test.dart` |
| Widget smoke test | PASS | Onboarding language screen renders |

## P0 Manual UAT Still Required

These must be tested on real devices before store rollout:

- iPhone Debug signing configuration is patched in the source tree to use Automatic Apple Development for Debug only. Release/Profile App Store signing remains unchanged.
- iPhone debug build/codesign is cleared when building from the clean archive tree after using Automatic Apple Development signing for Debug.
- iPhone debug app install passed via:
  `/usr/bin/env COPYFILE_DISABLE=1 /Users/kpc/develop/flutter/bin/flutter install -d 00008030-0008788421F3802E --debug --device-timeout=60`
- Building directly under `/Users/kpc/Documents/GitHub/fSookta` still fails because macOS FileProvider/provenance xattrs are applied to copied frameworks:
  `resource fork, Finder information, or similar detritus not allowed` on `Flutter.framework` and `objective_c.framework`.
  Use a clean archive under `/private/tmp` or move the working copy to a non-FileProvider path before device/store builds.
- iPhone automated launch/attach from tooling is still blocked by CoreDevice/Flutter attach behavior:
  `Timed out waiting for CONFIGURATION_BUILD_DIR to update` and `CoreDeviceService` initialize timeout from `devicectl`.
- iPhone real-device camera permission and capture flow
- iPhone gallery/photo library permission and image selection flow
- Android real-device camera/gallery permission behavior
- TTS sound on iPhone and Android
- Offline evaluation flow with bundled model assets
- Full assessment loop: select farmer -> capture/select image -> calculate -> select recommendation -> save -> history -> CSV export
- Share sheet/export behavior on iOS and Android
- Runtime stability after repeated assessments

## P1 Manual UAT Still Required

- Thai/English switching across all screens
- Help, Terms, Contact copy review
- Store privacy configuration review against actual dependencies
- Responsive spot-check on small iPhone, large iPhone, and iPad simulator

## Current Real-Device P0 Checklist

Run these on the installed iPhone app before sign-off:

1. Camera: open assessment -> take photo -> grant camera permission -> preview returns to assessment.
2. Gallery: open assessment -> choose image -> grant photo library permission -> selected image appears.
3. Offline ML: enable Airplane Mode -> complete assessment -> result appears without network.
4. TTS: open recommendation/result -> tap speaker button -> Thai/English audio is heard.
5. Export/share sheet: export from Final Result and History -> share sheet opens -> CSV can be saved/shared.
6. Persistence: close and reopen app -> farmer, saved history, recommendations, and result detail remain available.
7. Repeat stability: run at least three assessments in a row without crash or broken navigation.

## Known Open Defects / Follow-ups

| ID | Priority | Area | Description |
| --- | --- | --- | --- |
| DEF-001 | P1 | Contact | Verify Contact screen app version text. Code snapshot showed `0.1.0+1`; should match current release if still present. |
| DEF-002 | P0 | Real Device | Camera/gallery/TTS/performance have not been re-tested on real devices in this UAT round. |
| DEF-003 | P0 | iOS real-device build/signing | Partially cleared: source Debug signing is now Automatic Apple Development for team `RN66WU3W56`, and clean archive build/install passed from `/private/tmp/fSookta-uat-archive`. Building directly from `/Users/kpc/Documents/GitHub/fSookta` still fails because FileProvider/provenance xattrs are attached to copied frameworks. Recommended build path: clean archive in `/private/tmp` or a non-FileProvider working copy. |
| DEF-004 | P1 | iOS tooling launch/attach | After successful Debug build, `flutter run` still failed during debugger launch/attach with `Timed out waiting for CONFIGURATION_BUILD_DIR to update`; direct `devicectl` also timed out while initializing `CoreDeviceService`. This blocks automated launch from Codex but not the installed app itself. |

## UAT Decision

Automated readiness is acceptable for continuing UAT. iPhone install is no longer blocked by DEF-003, but production/store-ready sign-off still requires manual confirmation of camera, gallery, TTS, offline ML, export/share sheet, and repeated assessment stability on at least one iPhone and one Android device.
