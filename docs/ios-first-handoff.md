# iOS-first handoff

This project can be edited on Windows, but iOS builds, signing, CocoaPods, TestFlight, and device camera validation must be completed on macOS with Xcode.

## What is already prepared in this repo

- iOS display name is `Sookta`.
- iOS bundle identifier is `com.kdev.sookta`.
- Minimum iOS deployment target is `15.0`.
- Camera and photo library usage descriptions are present in `ios/Runner/Info.plist`.
- A baseline `ios/Runner/PrivacyInfo.xcprivacy` file is included in the Runner resources.

## Mac/Xcode setup steps

1. Install the current stable Flutter SDK, Xcode, Xcode command-line tools, and CocoaPods.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select the `Runner` target, then set `Signing & Capabilities` to the Apple Developer Team.
4. Confirm `Bundle Identifier` is `com.kdev.sookta`. If this ID is unavailable in Apple Developer, choose the final ID before Firebase setup.
5. Run:

   ```sh
   flutter clean
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter run -d <ios-device-id>
   ```

6. Test on a physical iPhone before relying on posture analysis. The simulator is not enough for camera, image orientation, and TFLite performance.

## Firebase handoff

Do this only after the final iOS bundle ID is confirmed.

1. Add an iOS app in Firebase with the same bundle ID.
2. Download `GoogleService-Info.plist`.
3. Add it to `ios/Runner` through Xcode so it is included in the Runner target.
4. Add FlutterFire dependencies and initialize Firebase in Dart.
5. Verify Crashlytics dSYM upload during archive builds.

## Privacy manifest follow-up

The current privacy manifest is intentionally minimal. Update it before TestFlight/App Store submission after the final dependency set is known, especially if the app enables analytics, crash reporting, shared preferences, local database storage, file timestamps, or any SDK that declares collected data.
