# Store Readiness Final Checklist

Updated: 2026-06-06

This checklist aligns the Flutter app with the Functional Design Document scope:
SookTa is a research prototype for ergonomic risk communication, preventive
awareness, and education. It is not a medical device, clinical diagnosis tool,
confirmed injury predictor, or exact economic forecasting system.

## Ready In App Code

- iOS bundle identifier remains `com.kdev.sookta`.
- Camera and photo library usage descriptions are present in `Info.plist`.
- `ITSAppUsesNonExemptEncryption` is set to `false` for App Store export
  compliance questionnaire readiness.
- `PrivacyInfo.xcprivacy` declares UserDefaults access for local
  profile/language/history persistence.
- Native Sookta launcher assets have been restored for Android and iOS.
- The iOS launch image uses the Sookta logo instead of the Flutter placeholder.
- Profile, language, avatar, activity selection, ergonomic assessment, results,
  recommendation re-score, history, body risk map, economic impact estimates,
  responsive layout, and TTS are implemented in the Flutter app.
- Result and history screens include research-prototype disclaimers matching the
  Functional Design Document.
- Android release keep rules are present for TensorFlow Lite and ONNX runtime
  dependencies when shrinking is enabled.
- Android release signing is prepared through ignored local `android/key.properties`
  and `android/key.properties.example`; real keystore files must stay outside git.
- Android Play Store release steps are documented in
  `docs/android-play-store-release.md`.

## Android Play Store Submission

- Generate the upload keystore locally and fill `android/key.properties` before
  building the Play artifact. Do not commit passwords or `.jks` files.
- Run `flutter analyze`, `flutter test`, and `flutter build appbundle --release`.
- Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.
- Complete Play Console Data safety, privacy policy, content rating, target
  audience, app access, ads declaration, and screenshots.
- Test the release build on a physical Android phone before production rollout.

Latest build verification:

- Store version prepared in git: `1.1.2+10`.
- iOS App Store IPA build passed from
  `/Users/kpc/Documents/GitHub/fSookta`; the generated app reports
  `CFBundleShortVersionString=1.1.2`, `CFBundleVersion=10`, and
  `CFBundleIdentifier=com.kdev.sookta`.
- iOS IPA output:
  `/Users/kpc/Documents/GitHub/fSookta/build/ios/ipa/Sookta.ipa`.
- Android App Bundle build passed from
  `/Users/kpc/Documents/GitHub/fSookta`; output is
  `/Users/kpc/Documents/GitHub/fSookta/build/app/outputs/bundle/release/app-release.aab`.
- Android upload signing is configured locally through ignored
  `android/key.properties`; do not commit `android/key.properties` or the
  upload `.jks` file.

## Must Pass Before TestFlight/App Store Submission

- Run on a physical iPhone and verify camera capture, gallery selection,
  posture image orientation, TFLite MoveNet inference, TTS playback, and
  profile/history persistence after app restart.
- Create/export the final IPA with an Apple Distribution certificate and provisioning
  profile, then upload to TestFlight. A release archive builds successfully from a
  local non-cloud path; IPA export currently requires the distribution account setup.
- Complete App Store Connect privacy answers consistently with local profile,
  photo/camera use, local history storage, and any research data export flow that
  will be used during field testing.
- Use App Store screenshots captured from a non-debug build without QA labels,
  debug paint, or simulator-only overlays.

## Research Model Scope

- The current XGBoost ONNX artifact is present at
  `assets/models/xgboost_model.onnx` and is used for posture-risk support in the
  REBA/ISO assessment flow.
- The daily Logistic Regression artifact is present at
  `assets/ml/daily_injury_logistic_model.json` and is used only for the
  7-transaction trend-prediction flow.
- The current ML assets must still be described as research-prototype ergonomic
  risk support, not as clinically validated diagnostic AI, medical diagnosis, or
  confirmed injury prediction.

## Deferred After Store/TestFlight If Time Is Tight

- Continued calibration of ML coefficients from expert-labeled field datasets.
- Batch validation with a held-out research dataset, including false-low-risk
  rate and high-risk recall.
- Firebase dashboard smoke checks after the first production/TestFlight users
  generate analytics/crash events.
- Remote research data sync, if required by the final research workflow.
- Pixel-perfect parity fixes that do not block the iOS research prototype flow.


## Build Environment Note

The working copy is currently under a macOS FileProvider/cloud-synced Documents
path. Device release signing can fail there because `com.apple.provenance` or
Finder metadata is copied into `App.framework`. For App Store/TestFlight builds,
use a local non-cloud path such as `/private/tmp/fSookta-store-build` or move the
checkout to a normal local development directory before archiving.
