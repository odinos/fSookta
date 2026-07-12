# Sookta Last-Phase Requirements Design

Date: 2026-07-12

Source: `/Users/kpc/Desktop/App Developer_LastPhase.md`

## Goal

Verify every requirement in the source document against the current Flutter application, preserve compliant behavior, implement only confirmed gaps, and complete evidence-backed UAT on the connected physical devices.

## Scope and Principles

- Cover every requirement from High through Low-Medium priority.
- Preserve the current illustrated activity-selection screen and avoid unrelated redesign.
- Keep the farmer-facing experience simple while retaining technical data for staff and research exports.
- Preserve the existing uncommitted work and build on it without reverting unrelated changes.
- Treat automated checks, simulator/tablet layout checks, and physical-device UAT as separate evidence layers.
- Report hardware or automation blockers as blockers; do not convert incomplete manual checks into passes.

## Architecture

The existing offline-first Flutter architecture remains unchanged. Requirement gaps will be addressed inside the current state, model, service, screen, and widget boundaries. Persistent changes use the existing `SharedPreferences`-backed state and local image store; research output continues through the existing export services.

The verification layer consists of focused unit/widget regression tests, existing integration tests, responsive layout checks, platform builds, and physical-device UAT. A requirement matrix will link each source requirement to code, automated evidence, and device evidence.

## Requirement Coverage Design

### 1. Data Integrity and Assessment Continuity

- Allow users to return or change activity before final save.
- Warn that current assessment data will be cleared or retained as a draft when changing activity.
- Persist drafts after meaningful form changes and restore the latest matching draft after relaunch.
- Identify drafts by farmer profile, activity, and assessment date.
- Persist draft media into application-owned storage so temporary picker paths survive relaunch.
- Keep the final assessment action visible and tappable on phone and tablet layouts in portrait and landscape.
- Bind farmer avatars to profile IDs and show a deterministic default avatar when no image exists.

### 2. Image Selection and Validation

- Support selecting up to four images in one picker action.
- Show four independent preview slots and allow replacement or removal per slot.
- Validate each image independently before assessment.
- Reject or clearly flag images with multiple people, insufficient landmarks, or unusable quality.
- Keep technical landmark and posture outputs available for saved records and exports.

### 3. Farmer, Staff, and Research Presentation

- Farmer mode leads with risk level, short body-part descriptions, body map, and actionable guidance.
- Technical angles, REBA, ISO 11228, worst posture, and landmark details remain under expandable detail or staff-oriented surfaces.
- Technical fields remain persisted and exportable even when hidden from the farmer summary.
- Important screens use a consistent, visible TTS control with concise action-oriented Thai speech.
- Dense assessment questions use short sections, icons, and readable spacing.

### 4. Recommendations and Final Summary

- Group recommendations into posture, risk reduction, rest/task rotation, and tools/work methods.
- Derive recommendations from the actual activity and detected risky body parts.
- Final summary keeps economic impact and adds the highest-risk body parts plus specific corrective actions.
- Avoid generic posture thresholds that are unrelated to the assessed activity.

### 5. Manual and Existing Activity UI

- Preserve the current illustrated activity-selection UI, Thai labels, and sound controls.
- Verify the bundled manual uses real application screenshots, short captions, and visible callouts in actual workflow order.
- Replace or update manual pages only where current screenshots no longer match the app.

### 6. Trends, Export, Backup, and Migration

- Keep the trend view simple, with clear farmer/activity/month filters and limited visual complexity.
- Support export filtering by month and activity.
- Every assessment export must include farmer ID, farmer name, assessment date, activity, risk score, risky body parts, image references, AI analysis, and app version.
- Retain raw and derived REBA/ISO/landmark values needed by researchers.
- Back up persisted data before schema migration and migrate legacy profiles, drafts, and history without data loss.
- Verify an older persisted fixture remains readable and exportable after migration.

## Data Flow

1. The active farmer chooses an activity and begins an evaluation.
2. Each meaningful change updates a farmer/activity/date-scoped draft.
3. Selected images are copied into persistent local storage and validated per slot.
4. Valid media flows through pose estimation and ergonomic calculation.
5. Farmer-facing results render simplified risk and recommendations; expandable details expose technical outputs.
6. Final save creates a version-stamped history record and removes only the completed draft.
7. Trend and export services filter stored history without altering source records.
8. On schema upgrade, a backup is written before migrated data replaces the active representation.

## Error Handling

- Persistence failures leave the current in-memory assessment intact and show a recoverable message.
- Invalid images identify the affected slot and explain the required replacement.
- Activity changes require explicit confirmation when assessment data already exists.
- Missing required data prevents final calculation without discarding entered values.
- Export and share failures show a retryable error and do not mutate history.
- Migration failure falls back to preserved data or backup and must not silently reset user data.

## Testing Strategy

### Automated

- Begin from the current clean automated baseline: analyzer passes and 97 tests pass.
- Add a failing regression test before each confirmed behavior change.
- Cover draft scoping/media restoration, change-activity confirmation, multi-image replacement, invalid-image slot feedback, profile-avatar isolation, export metadata, migration, farmer/admin detail separation, and responsive final-action behavior.
- Run the complete analyzer and test suite after focused tests pass.

### Layout and Builds

- Exercise phone, iPad/tablet, portrait, and landscape sizes through widget/integration coverage.
- Build Android and iOS artifacts using the project toolchain.
- Treat successful compilation as build evidence, not functional UAT.

### Physical-Device UAT

Run on every connected supported physical device, prioritizing one Android phone and one iPhone/iPad when available:

1. Install and launch the current build.
2. Create or switch between at least two farmer profiles and verify avatar isolation.
3. Start an assessment, enter data, terminate/relaunch, and resume the correct draft.
4. Change activity mid-assessment and verify the warning and chosen clear/draft behavior.
5. Select four images together, replace and remove one image, and verify per-slot previews.
6. Try an unusable or multi-person image and verify actionable rejection.
7. Complete an assessment and verify the final action is tappable and unobstructed.
8. Verify simplified farmer results, expandable technical details, body map, and risk-specific recommendations.
9. Listen to required Thai TTS prompts and confirm they are concise and understandable.
10. Filter trend/history and export by month/activity; inspect required metadata.
11. Relaunch offline and verify saved records, drafts, images, and assessment flow remain available.
12. Capture screenshots, logs, exported samples, device/build versions, passes, failures, and blockers in a dated UAT report.

Hardware-dependent checks such as audible voice quality, native permission dialogs, camera behavior, and share sheets require human-observable device evidence. If automation cannot perform them, the report will mark them `PENDING-MANUAL` rather than `PASS`.

## Acceptance Criteria

- Every source requirement has a matrix row with status and evidence.
- No confirmed requirement gap remains without an implementation or documented external blocker.
- Static analysis reports no issues and the full automated suite passes.
- Android and iOS build verification completes for the available toolchain.
- Physical-device UAT is attempted on all connected supported devices and produces a dated evidence report.
- The final report distinguishes `PASS`, `FAIL`, `BLOCKED`, `NOT AVAILABLE`, and `PENDING-MANUAL` accurately.

## Out of Scope

- Replacing the existing illustrated activity-selection design.
- Introducing cloud synchronization or a new backend.
- Changing validated REBA/ISO research formulas unless a requirement gap demonstrates an error.
- Store submission, production deployment, or destructive reset of existing user data.
