# Sookta iOS Full-Page Smoke UAT - 2026-06-06

## Scope

Tested on a real iPhone device using Flutter integration test automation.

- Device: iPhone SE (`00008030-0008788421F3802E`)
- iOS: 26.5 (`23F77`)
- Build type: debug device deployment
- Workspace used for device build: `/private/tmp/fSookta-ios-full-uat-min-20260606`
- Source workspace: `/Users/kpc/Documents/GitHub/fSookta`

## Result

PASS after fixing an iOS accessibility semantics issue in the Setup screen.

The final run completed in 1 minute 56 seconds and reported:

```text
01:56 +1: All tests passed!
```

## Screens Covered

The smoke test renders the following flows in both Thai and English.

- Language selection: first-run and edit mode
- Profile setup: first-run and edit mode
- Avatar selection
- Main tabs: Home, History, Profile
- Farmer manager: list, add dialog, edit dialog, delete confirmation dialog
- Evaluation menu
- Evaluation form for all activities:
  - Transplanting
  - Fertilizing
  - Pesticide spraying
  - Pruning
  - Harvesting
  - On-farm transport
- Initial risk result
- Final result
- History detail
- 7-day daily prediction
- Help
- References
- Terms
- Contact

## Issue Found And Fixed

The first iOS run failed on the Setup screen with this Flutter debug assertion:

```text
Invisible SemanticsNodes should not be added to the tree.
```

Root cause:

- `SooktaTtsButton` was placed inside `TextField` `suffixIcon`.
- On iPhone SE viewport height, lower text fields could be offscreen while their suffix icon semantics remained focusable.
- This can confuse accessibility navigation, especially with VoiceOver.

Fix applied:

- Moved Setup field TTS buttons out of `TextField.suffixIcon` and into a small row below each field.
- Kept `suffixIcon` only for the participant-code refresh button.
- Changed `SooktaTtsButton` to expose accessibility with `Semantics` and `ExcludeSemantics` around the visual `IconButton`, avoiding duplicate/hidden semantics nodes.

## Verification Commands

```sh
/Users/kpc/develop/flutter/bin/flutter analyze
/Users/kpc/develop/flutter/bin/flutter test
/usr/bin/env COPYFILE_DISABLE=1 /Users/kpc/develop/flutter/bin/flutter test integration_test/ios_full_page_smoke_test.dart -d 00008030-0008788421F3802E
```

## Verification Summary

- `flutter analyze`: PASS
- `flutter test`: PASS, 35 tests
- iOS build/install/launch: PASS
- iOS Thai full-page smoke: PASS
- iOS English full-page smoke: PASS
- iOS TTS initialization logs:
  - Thai selected voice: `Kanya`, locale `th-TH`
  - English selected voice: `Reed`, locale `en-GB` fallback for requested `en-US`

## Manual Checks Still Required

The automation verifies Flutter rendering, navigation, localization, runtime errors, and TTS initialization. These user-facing native flows still require a human to operate the physical phone:

- Camera permission prompt and real photo capture
- Gallery permission prompt and real image selection
- Audible TTS clarity and volume quality
- Native iOS share sheet for CSV export
- Real image-to-pose-to-risk assessment using field photos

