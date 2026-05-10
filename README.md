# fSookta

Starter Flutter application scaffolded for Android and iOS.

## Requirements

- Flutter SDK on `PATH`
- Android Studio / Android SDK for Android builds
- Xcode and CocoaPods on macOS for iOS builds

This machine did not have the Flutter SDK available when the scaffold was created, so the project was generated manually. After installing Flutter, run:

```powershell
flutter doctor
flutter pub get
flutter create --platforms=android,ios --project-name fsookta --org com.example .
flutter test
```

The `flutter create` command refreshes platform-specific generated files while keeping the existing Dart source.

## Useful Commands

```powershell
flutter run
flutter test
flutter build apk
flutter build ios
```

