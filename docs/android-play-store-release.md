# Android Play Store Release Checklist

Updated: 2026-06-06

This app should be uploaded to Google Play as a signed Android App Bundle (`.aab`).
The package name must stay `com.kdev.sookta` unless the store listing is intentionally
created under a new application identity.

## One-Time Developer Setup

1. Create or use the Google Play Console developer account.
2. Create the Sookta app listing with package name `com.kdev.sookta`.
3. Enroll in Play App Signing when creating the first release. New Play apps use
   Play App Signing; the local key below is the upload key.
4. Generate an upload keystore on the release machine:

```sh
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

5. Copy `android/key.properties.example` to `android/key.properties` and fill in
   the local password, alias, and absolute keystore path. `android/key.properties`
   and `*.jks` files are ignored by git and must not be committed.

## Build Commands

Run these from the Flutter repo root after `flutter pub get`:

```sh
flutter analyze
flutter test
flutter build appbundle --release
```

The upload artifact is:

```text
build/app/outputs/bundle/release/app-release.aab
```

Latest local verification:

- Version: `1.1.2+10`
- Package: `com.kdev.sookta`
- Command run from repo root:
  `/Users/kpc/Documents/GitHub/fSookta`
- Output:
  `/Users/kpc/Documents/GitHub/fSookta/build/app/outputs/bundle/release/app-release.aab`
- Size: about `109MB`
- Status: `flutter analyze`, `flutter test`, and
  `flutter build appbundle --release` passed on 2026-06-06. The AAB is signed
  with the local upload key referenced by ignored `android/key.properties`.

If Google Play asks for native debug symbols, upload:

```text
build/app/outputs/native-debug-symbols/release/native-debug-symbols.zip
```

## Store Console Items

- Complete App content, Data safety, privacy policy URL, target audience, ads
  declaration, app access, and content rating questionnaires.
- Disclose camera/gallery access, local profile/history storage, Firebase
  Crashlytics crash data, and Firebase Analytics product/app interaction data
  accurately.
- Do not describe the current ML assets as a clinically validated diagnostic
  model. Use the research-prototype wording already present in app copy.
- Use screenshots from a release/profile build across small and large Android
  phones.
- Confirm the app targets the current Google Play target API requirement before
  uploading. As of 2026-05-24, new apps and updates must target Android 15 / API
  35 or higher.

## Final Device Smoke Test

Before production rollout, test on at least one real Android device:

- Camera capture and gallery import.
- MoveNet/TFLite posture inference on real images.
- Result, recommendation, TTS, history, profile, language switching.
- App relaunch after force close keeps profile/history.
- No debug labels, QA text, or simulator-only copy appears in screenshots.
