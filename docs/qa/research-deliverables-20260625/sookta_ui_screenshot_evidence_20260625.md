# Sookta UI Screenshot Evidence: No Probability, Separate Before/After

## Evidence file

Screenshot:

`/Users/kpc/Documents/GitHub/fSookta/outputs/research-deliverables-20260625/sookta_ui_before_after_no_probability_evidence_20260625.jpg`

## What the screenshot shows

- The UI separates the score before improvement and after improvement.
- Thai labels shown in the app are `ก่อนปรับ` and `หลังปรับ`.
- The displayed values are score values: before = 7, after = 5.
- The summary text explains that the result is better because the score decreased from 7 to 5.
- No probability field or probability wording is shown in this screen.

## iPhone launch note

On 2026-06-25, the paired physical iPhone was detected through CoreDevice:

- Device: iPhone SE, iOS 26.5
- App: Sookta
- Bundle identifier: `com.kdev.sookta`
- Version: 1.3.4, build 17

The app was launched successfully on the iPhone with:

`xcrun devicectl device process launch --device ABD658CA-9FDE-5F6E-8228-CFE6D830F4AE --terminate-existing com.kdev.sookta`

Direct live pixel capture from the physical iPhone could not be completed because the available screenshot service returned:

`Could not start screenshotr service: Invalid service`

For this evidence package, the attached screenshot is therefore the existing app screenshot from the project evidence set, copied into the deliverables folder. It should be treated as UI evidence for the before/after and no-probability requirement, while the iPhone launch note documents that the latest installed iPhone app was reachable and launchable.
