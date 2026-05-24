# Screenshot Parity QA

Use this checklist on real devices only. Capture the Android native app and
Flutter app in the same language, same profile data, and same activity input.
Keep screenshots paired by row name so visual differences are easy to review.

## Device Setup

- Android native source of truth: `odinos/sookta`, branch `dev`.
- Flutter app under test: `odinos/fSookta`, current branch.
- iOS testing must use a real iPhone because camera, gallery, TFLite, and TTS
  behavior can differ from simulators.
- Use Thai as the default parity language, then repeat Language/Profile checks
  in English.
- Use the same test profile:
  - Name: `Sookta QA`
  - Age: `45`
  - Gender: `Female`
  - Weight: `55`
  - Height: `158`
  - Annual income: `120000`

## Responsive Matrix

Run the Flutter side on at least these viewport classes before final parity:

| Class | Example | Purpose |
| --- | --- | --- |
| Compact narrow | iPhone SE, small Android | Catch header, button, card, and long Thai text overflow. |
| Compact standard | iPhone Pro, Pixel | Primary phone layout target. |
| Compact tall | iPhone Pro Max, large Android | Confirm vertical spacing and scroll behavior. |
| Medium/wide | iPad mini split, tablet-ish Android | Confirm grids expand without oversized cards. |

Responsive pass criteria:

- No yellow/black Flutter overflow banners or render overflow logs.
- Header rows use `Expanded`, `Flexible`, `Wrap`, or ellipsis for long text.
- Grids adapt column count rather than assuming one fixed phone width.
- Score comparison rows can stack vertically on narrow screens.
- Body maps scale within available width and stay readable.
- Buttons wrap or become full-width on narrow screens.

## Pass Criteria

- Navigation target matches the native app after every tap.
- Back behavior matches the native app.
- Key content is visible without overlap on iPhone and Android.
- Custom avatar from camera/gallery appears on Home and Profile.
- Result pages show before/after score, economic impact, body map, risky body
  part names, selected recommendations, and TTS controls.
- TTS speaks the selected Thai/English text and stops when tapped again.

## Screen Checklist

| Row | Native route | Flutter route | Action | Expected parity |
| --- | --- | --- | --- | --- |
| `01_splash` | `splash` | `/` | Fresh install launch | Shows Sookta logo and routes by setup state. Timing may differ slightly. |
| `02_language_first_run` | `language_selection` | `/language` | Fresh install after splash | Select language cards lead to profile setup. |
| `03_setup_first_run` | `setup` | `/setup` | Enter profile, tap next | Saves profile and opens avatar selection. |
| `04_avatar_first_run` | `avatar_selection` | `/avatar` | Pick built-in avatar, confirm | Opens main tabs and marks setup complete. |
| `05_home_avatar_asset` | `main/home` | `/main` Home tab | Return to Home | Avatar, greeting, and evaluation entry are visible. |
| `06_profile_edit_setup` | `main/profile -> setup` | `/main` Profile -> `/setup` edit mode | Edit profile, tap save | Saves and returns to Profile, not Avatar. |
| `07_profile_change_language` | `main/profile -> language_selection` | `/main` Profile -> `/language` edit mode | Change language | Saves language and returns to Profile. |
| `08_avatar_camera_gallery` | `avatar_selection` | `/avatar` | Pick camera/gallery image | Custom file avatar appears on Profile and Home. |
| `09_evaluation_menu` | `evaluation_menu` | `/evaluation-menu` | Open from Home | Six activity cards navigate to form. |
| `10_evaluation_form` | `evaluation_form/{activity}` | `/evaluation-form` | Add image, choose job inputs, analyze | Moves to initial risk with matching activity. |
| `11_initial_risk` | `initial_risk/{activity}/{score}` | `/initial-risk` | Review score/body map/recommendations | Shows score, economic impact, body map, risky parts, and selectable advice. |
| `12_final_result` | `final_result/{old}/{new}/{activity}` | `/final-result` | Select advice, simulate result | Shows before/after, savings, body map, risky parts, advice, and TTS. |
| `13_history_list` | `main/history` | `/main` History tab | Save result then open History | Latest result appears and opens detail. |
| `14_history_detail` | `result_history/{historyId}` | `/history-detail` | Open latest history | Shows score, economic impact, body map, risky parts, advice, AI alert when present, and TTS. |
| `15_help_terms_contact` | `help`, `terms`, `contact` | `/help`, `/terms`, `/contact` | Open from Profile | Content pages open and back returns to Profile. |

## Screenshot Naming

Use this pattern:

```text
qa/screenshots/<row>/<platform>_<language>_<viewport>.png
```

Examples:

```text
qa/screenshots/12_final_result/flutter_th_iphone15.png
qa/screenshots/12_final_result/native_th_pixel7.png
```

## Current QA Status

- Static route/code comparison: passed for the main assessment flow.
- Flutter compile verification: passed with `flutter analyze`, `flutter test`,
  and `flutter build ios --no-codesign` on 2026-05-18.
- Simulator display-only responsive harness: captured 52 clean screenshots on
  2026-05-18 across iPhone 17e, iPhone 17 Pro, iPhone 17 Pro Max, and iPad mini
  (A17 Pro). Output:
  `qa/screenshots/responsive_sim_20260518_clean/`.
- Responsive polish verification: captured an additional 52 screenshots after
  tablet max-width hardening in
  `qa/screenshots/responsive_sim_20260518_polished/`, then a focused 26-image
  final check on iPhone 17e and iPad mini in
  `qa/screenshots/responsive_sim_20260518_finalcheck/`.
- Simulator-only accessibility pass: captured 13 screenshots with the simulator
  Dynamic Type setting at `accessibility-extra-large` in
  `qa/screenshots/sim_accessibility_text_20260518/`.
- Long-content stress pass: the screenshot harness now supports
  `SOOKTA_QA_STRESS_TEXT=true` and `SOOKTA_QA_TEXT_SCALE=<number>` for long Thai
  names, long recommendation text, and high annual-income values. The latest
  13-image stress capture is in
  `qa/screenshots/sim_stress_text_20260518_final/`.
- Simulator pass notes: no Flutter overflow banners were observed in sampled
  Home, Profile, Setup edit, Evaluation Form, Initial Risk, Final Result,
  History List, and History Detail captures. Compact phone result/detail pages
  correctly require vertical scrolling to see lower body-map and recommendation
  content.
- Simulator limitation: this workflow verifies layout and scrolling only.
  Landscape should still be checked via the Simulator UI or locked to portrait
  before submission if landscape support is not intended.
- Real-device screenshot capture remains required for camera/gallery, TFLite,
  TTS behavior, and final native-device parity because simulator capture is only
  a display/layout check.

## 2026-05-19 Store-Readiness Simulator Pass

- Static verification passed:
  - `plutil -lint ios/Runner/Info.plist ios/Runner/PrivacyInfo.xcprivacy`
  - `flutter analyze`
  - `flutter test`
  - `flutter build ios --simulator`
- iOS Store configuration updates:
  - `Info.plist` declares `ITSAppUsesNonExemptEncryption=false` for export
    compliance questionnaire readiness.
  - `PrivacyInfo.xcprivacy` declares
    `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`, matching
    the app's use of `shared_preferences` for local language/profile/history
    persistence.
  - Camera and photo library usage descriptions remain present for
    camera/gallery posture image workflows.
- Simulator viewport screenshots were captured with `simctl` on:
  - iPhone 17e: `qa/screenshots/store_ready_sim_20260519/iphone_17e/`
  - iPhone 17 Pro Max:
    `qa/screenshots/store_ready_sim_20260519/iphone_17_pro_max/`
  - iPad mini (A17 Pro):
    `qa/screenshots/store_ready_sim_20260519/ipad_mini_a17/`
- Each viewport produced 13 screenshots, 39 total. The Flutter run logs did not
  report RenderFlex overflow or framework exceptions; the only log line matched
  by the error scan was the expected `Lost connection to device` after the
  capture script terminated the debug run.
- Capture caveat: because iOS Simulator does not support Flutter profile mode,
  this round used debug builds. The screenshot files are valid for layout,
  scrollability, safe-area, and viewport checks, but some captures can show
  debug baseline paint and should not be treated as final marketing/App Store
  screenshots.
