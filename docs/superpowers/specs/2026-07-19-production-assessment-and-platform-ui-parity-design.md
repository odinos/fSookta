# Production Assessment Gate and Platform UI Parity Design

## Goal

Remove the assessment UAT bypass completely and verify that the Android user interface matches the iOS user interface for all shared Flutter screens.

## Scope

This change covers:

- the assessment form's result-button gate;
- validation performed when assessment begins;
- removal of UAT-only configuration, copy, and tests;
- portrait configuration checks on Android and iOS;
- cross-platform visual verification of the main farmer workflow.

It does not change ergonomic formulas, pose-estimation thresholds, research exports, saved data schemas, or platform-native permission, camera, gallery, and share-sheet interfaces.

## Production Assessment Behavior

The application must not contain a runtime or compile-time path that bypasses assessment validation.

The **View Assessment** button is enabled only when all conditions are true:

1. at least one image or extracted video frame is present;
2. no image-quality issue is active;
3. pose assessment is ready;
4. pose analysis is not busy;
5. all required activity and ergonomic inputs are valid.

When assessment is requested, the handler repeats the production validation before calculation. Missing required data or unreadable posture media must stop navigation and show actionable guidance. No UAT banner, UAT build flag, or media-only shortcut remains.

## Removal Boundary

Remove:

- `lib/app/uat_config.dart`;
- the `SOOKTA_UAT_BYPASS` compile-time environment flag;
- the UAT warning banner on the evaluation form;
- both bypass branches in `evaluation_form_screen.dart`;
- `test/uat_assessment_gate_test.dart`;
- build and UAT documentation that instructs developers to enable the bypass.

Keep:

- production image-quality validation;
- multiple-person rejection;
- pose-readiness checks;
- required-data validation;
- the existing production error messages;
- uploaded-video support when extracted frames pass normal production validation.

## Android and iOS UI Parity

Shared Flutter screens must use the same:

- navigation order;
- Thai and English copy;
- cards and section hierarchy;
- colors, icons, spacing, and button labels;
- enabled and disabled states;
- four recommendation categories;
- portrait-only layout behavior.

The comparison covers:

1. the main farmer workflow entry;
2. the evaluation form;
3. the risk-reduction action selection screen;
4. the final farmer result screen.

Expected platform differences are limited to system-owned interfaces and rendering details:

- status/navigation bars and safe-area insets;
- font rasterization;
- permission dialogs;
- camera and gallery pickers;
- native share sheets.

These expected differences must not change the order, wording, availability, or meaning of shared application actions.

## Verification Strategy

### Automated Production Gate

Use regression tests to prove:

- no UAT configuration or `SOOKTA_UAT_BYPASS` reference remains;
- incomplete media and missing required data keep the assessment action disabled;
- analysis cannot proceed when pose assessment is not ready;
- valid production input still reaches the result workflow.

### Shared UI Contract

Run widget tests at representative portrait sizes for iPhone and Android phones. Verify the same key headings, card order, recommendation groups, button states, and absence of overflow.

### Platform Builds and Visual Evidence

Build without any bypass define:

- a signed or no-codesign iOS production-behavior artifact;
- an Android production-behavior artifact.

When platform services are available, install and launch on an Android emulator and iOS simulator. Capture the same workflow states at comparable portrait dimensions and publish side-by-side evidence in the approved visual companion.

If ADB or CoreSimulator cannot start because of host-service restrictions, report the platform run as `BLOCKED`. Do not convert code inspection or widget tests into a physical/emulator `PASS`.

## Error Handling

- Required-data failures retain entered values and identify the first missing item.
- Unreadable or incomplete posture media remains replaceable without clearing other assessment data.
- A build or emulator failure does not alter saved application data.
- Platform-tooling errors are recorded separately from product failures.

## Acceptance Criteria

- No UAT bypass implementation, flag, banner, test, or build instruction remains.
- Production validation is enforced both in the button state and in the assessment handler.
- Focused regression tests pass.
- The complete Flutter test suite passes.
- Changed-file static analysis reports no issues.
- Android and iOS builds contain no bypass define.
- Shared Flutter UI contracts pass at Android and iPhone portrait sizes.
- Android/iOS screenshots are compared in the visual companion when platform services are available.
- Any remaining platform-specific difference is either system-owned or documented as a defect/blocker.
