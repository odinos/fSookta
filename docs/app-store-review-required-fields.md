# App Store Review Required Fields

Updated: 2026-06-06

Use this document to clear the App Store Connect blockers shown on the iOS
version submission page.

## 1. Privacy Policy URL

Location in App Store Connect:

- App Privacy
- Privacy Policy URL

Recommended action:

- Add a public URL that can be opened without login.
- A published Google Doc or a public website page is acceptable.
- Do not use a private Drive link.

Suggested privacy policy content:

```text
Privacy Policy for Sookta สุขท่า

Last updated: June 6, 2026

Sookta สุขท่า is an ergonomic risk awareness and research-support application
for coffee-farming workflows. The app helps users record posture assessments,
view risk results, and export assessment records for research follow-up.

Data handled by the app:
- Participant profile information entered by the user, such as participant code
  and role.
- Posture photos captured with the camera or selected from the photo library.
- Ergonomic assessment results, recommendations, history, and exported CSV
  files.

How data is used:
- Camera and photo library access are used only to capture or select posture
  images for on-device ergonomic assessment.
- Assessment history and profile data are stored locally on the user's device.
- Export files are created only when the user chooses to export or share them.
- Firebase Analytics and Crashlytics are used to monitor app stability, crash
  reports, and basic product interaction events.

Data collection:
- The app does not require sign-in.
- The app does not include advertising.
- The app does not track users across apps or websites.
- The app does not sell personal information.
- In the current release, the app does not send profile, photo, or assessment
  history data to developer servers.
- The app may send crash data and app interaction events to Firebase for app
  quality monitoring. These events are not used for advertising or cross-app
  tracking.

Health and research notice:
- Sookta is not a medical diagnosis tool, not a regulated medical device, and
  not a substitute for medical advice.
- Results are intended for ergonomic risk communication, education, and
  research-support purposes only.
- Users with pain, injury, or medical concerns should consult qualified medical
  personnel.

Contact:
For support or privacy questions, contact: [insert support email]
```

## 2. Regulated Medical Device Declaration

Location in App Store Connect:

- App Information
- Regulated Medical Device

Recommended answer:

```text
No. This app is not a regulated medical device.
```

If App Store Connect asks by region, answer `No` for every listed region,
including the United States, EU/EEA, United Kingdom, and any other available
region.

Reviewer-safe wording:

```text
Sookta provides ergonomic risk awareness and research-support information only.
It does not diagnose, treat, prevent, monitor, or make clinical decisions about
any disease, injury, or medical condition.
```

## 3. Thai Support URL

Location in App Store Connect:

- iOS App Version 1.1.2
- Thai localization
- Support URL

Recommended action:

- Add a public support page URL that can be opened without login.
- The page can be a published Google Doc or website page.

Prepared Thai support page:

```text
https://docs.google.com/document/d/1wMofRzvLG356_l-S5cXJonhcwoeYvgc_rnykpugMFIY
```

Suggested support page content:

```text
Sookta สุขท่า - Support

Sookta สุขท่า is an application for ergonomic risk awareness and research
support for coffee-farming workflows.

Basic usage:
1. Select language.
2. Create or select a participant profile.
3. Choose a farming activity.
4. Capture a posture photo or select one from the photo library.
5. Run the assessment.
6. Review the risk level, affected body areas, recommendations, and estimated
   economic impact.
7. Save the result or export the history file when needed.

Permissions:
- Camera: used to capture posture photos for assessment.
- Photo Library: used to select posture photos for assessment.

Important notice:
Sookta is not a medical diagnosis tool or regulated medical device. Results are
for ergonomic risk communication, education, and research-support purposes only.

Support contact:
[insert support email]
```

## 4. Copyright

Location in App Store Connect:

- iOS App Version 1.1.2
- Copyright

Recommended value if the Apple Developer account holder owns the submission:

```text
© 2026 Methee Treewichian
```

If the project contract assigns copyright to another legal owner, use that legal
owner instead.

## 5. App Privacy Practices

Location in App Store Connect:

- App Privacy
- Data Collection

Recommended answer for the current release:

```text
The developer collects limited app-quality data only.
```

Recommended App Privacy disclosure:

- Data types collected:
  - Crash Data
  - Product Interaction / App Interactions
- Purpose:
  - App Functionality
  - Analytics
- Linked to user:
  - No
- Used for tracking:
  - No

Reason:

- No login is required.
- No advertising or cross-app tracking is included.
- Profile, participant, photo, assessment history, and export data are stored on
  the device unless the user manually exports or shares a file.
- Camera and photo library access are used for on-device assessment only.
- Firebase Crashlytics and Firebase Analytics are enabled to monitor crashes,
  app stability, and basic product interaction events.

If server upload, account sync, or research cloud sync is added in a future
release, update App Privacy again before submitting that release.

## 6. Review Notes

Paste this in App Review notes:

```text
Sookta is a research and education app for ergonomic risk communication for Thai
coffee-farming workflows.

No login or demo account is required. The reviewer can use the app immediately
after launch.

Suggested review steps:
1. Launch the app.
2. Select Thai or English.
3. Create or use a participant profile.
4. Open the assessment flow and choose a farming activity.
5. Capture a posture photo with the camera or select a photo from the photo
   library.
6. Run the assessment.
7. Review the risk result, affected body areas, economic impact estimate, and
   recommendations.
8. Use the speaker button to test text-to-speech.
9. Save the result, open History, and export/share the CSV file.

Camera and photo library access are used only so users can capture or select
posture images for on-device ergonomic assessment. Profile, participant,
assessment history, and export data are stored locally on the device unless the
user manually exports or shares the file.

Firebase Analytics and Crashlytics are enabled only for app-quality monitoring,
crash diagnostics, and basic product interaction analytics. They are not used
for advertising or cross-app tracking.

The app is not a medical diagnosis tool, not a regulated medical device, not a
clinical injury prediction tool, and not an exact personal medical-cost
calculator. Results are intended for ergonomic risk awareness, education, and
research-support communication only.
```
