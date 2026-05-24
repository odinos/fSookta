# Android Pixel Parity QA - 2026-05-18

## Test Device

- Device: `R5CW13JKESA`
- Screen: `1080x2316`
- Density: `450`
- Font scale: `1.0`
- Native source: `/private/tmp/sookta-native`, branch `dev`
- Flutter source: current fSookta workspace

## Screenshot Sets

- Android native source-of-truth:
  `qa/screenshots/android_native_parity_20260518/`
- Flutter Android profile harness:
  `qa/screenshots/android_flutter_parity_20260518_profile_final2/`

## Build Notes

- Native Android debug build passed with `sh gradlew assembleDebug` after
  setting `JAVA_HOME` to Android Studio JBR and `ANDROID_HOME` to the local SDK.
- Flutter Android profile build passed after updating Android Gradle Plugin to
  `8.11.1` and aligning Java/Kotlin JVM targets to `17`.
- Flutter release APK is still blocked by R8 missing TFLite GPU delegate keep
  rules. This does not block profile screenshot QA, but should be fixed before
  Android release builds are needed.

## Current Parity Findings

| Area | Status | Notes |
| --- | --- | --- |
| Language screen | Close | Flutter matches general content and spacing, but uses `TH/EN` circles while native uses flag icons. Flutter also has a green app bar on edit-mode harness captures; native first-run has no app bar. |
| Setup screen | Partial | Core fields match. Flutter has heavier outlined fields and larger vertical spacing; native fields are softer rounded cards. Gender selected default differs in some captures because Flutter harness uses female while native first-run defaults male. |
| Home | Partial | Flutter now has native-like background, greeting, avatar, and evaluation entry. Remaining differences: card composition differs, Flutter includes right-side illustration, native card is centered with icon. Flutter harness still shows QA label overlay in bottom-right and has a baseline artifact on some Home text in the harness capture. |
| Profile | Partial | Data and avatar match. Layout differs: native uses three stat cards in one row; Flutter wraps to two columns on this Android width. Native has bottom tab bar; Flutter harness screen is standalone. |
| Evaluation menu | Close | Activity grid, imagery, labels, and two-column structure are close. Minor differences remain in app-bar height, card size, spacing, and image scale. |
| Evaluation form | Partial | Both show image slots, camera/gallery controls, and REBA input. Flutter stacks image slots vertically in the current capture while native uses a 2x2 grid; this is a high-priority parity gap. |
| Result/history | Not native-captured yet | Native result pages require completing analysis with image/input state. Flutter result/history captures exist, but native source captures are still needed before pixel comparison. |

## Priority Fixes For Flutter

1. Make Evaluation Form image picker area match native 2x2 grid on Android phone
   widths.
2. Align Profile stats layout with native on 1080px Android width: three cards in
   one row when enough physical width is available.
3. Align Home evaluation card composition with native or decide intentionally
   that Flutter improved card with illustration is acceptable.
4. Adjust Language first-run visuals if strict parity is required: use flag
   icons and remove app-bar from first-run capture.
5. Create a native result-page capture route or seed path so Initial Risk, Final
   Result, History List, and History Detail can be compared from native pixels.

## Remaining Capture Work

- Capture native Initial Risk, Final Result, History List, and History Detail
  after either adding a test image/input path or seeding navigation state.
- Re-capture Flutter without harness label overlay for final pixel artifacts.
- Run image-diff tooling only after both sides have matching route/state and no
  QA labels.
