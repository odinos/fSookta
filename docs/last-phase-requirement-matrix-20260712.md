# Sookta Last-Phase Requirement Matrix

Date: 2026-07-12

Authoritative implementation spec: `docs/superpowers/specs/2026-07-12-last-phase-requirements-design.md`

Status meanings:

- `PASS`: implemented with code and automated evidence.
- `GAP`: a confirmed behavior is still missing.
- `DEVICE-ONLY`: implementation exists, but acceptance requires physical-device observation.

| ID | Requirement | Status | Code evidence | Automated evidence | Device evidence |
| --- | --- | --- | --- | --- | --- |
| 1.1 | Change selected activity safely before final save | PASS | `initial_risk_screen.dart` pre-save confirmation and change-activity dialog; draft retained | `initial_risk_confirmation_test.dart`, `evaluation_draft_flow_test.dart` | Pending UAT |
| 1.2 | Auto-save and resume farmer/activity/date-scoped drafts | PASS | `app_state.dart`, `assessment_session.dart`, `local_image_store.dart`, `evaluation_form_screen.dart` | `evaluation_draft_state_test.dart`, `app_state_evaluation_persistence_test.dart`, `evaluation_draft_media_resume_test.dart` | Pending relaunch UAT |
| 1.3 | Final assessment action works on tablet | DEVICE-ONLY | Final action is inside scrollable responsive result flow; approved design now requires portrait only | `final_result_farmer_summary_test.dart`, `final_result_breakdown_capture_test.dart`; portrait contract added in Task 2 | Pending phone/tablet portrait UAT |
| 1.4 | Farmer profile image remains isolated per farmer ID | PASS | `UserProfile.avatarAsset` persists inside each profile; active profile consumers read that profile only; null image uses default person icon | Profile serialization/state coverage in `widget_test.dart` and `app_state_evaluation_persistence_test.dart` | Pending two-farmer UAT |
| 2.1 | Select up to four images together; preview, replace, and remove independently | PASS | `evaluation_form_screen.dart` uses `pickMultiImage`, four slots, slot replacement, and removal | `evaluation_form_image_slots_test.dart` | Pending gallery UAT |
| 2.2 | Reject multiple-person, unclear, or incomplete-body images and identify bad slots | PASS | `multi_person_pose_detector.dart` runs bundled MoveNet MultiPose Lightning before the existing single-pose assessment; invalid slots receive an X and explicit replacement guidance | `multi_person_pose_detector_test.dart`, `evaluation_form_image_slots_test.dart` | Pending real-photo UAT |
| 2.3 | Simple farmer AI result with expandable staff/research detail | PASS | `initial_risk_screen.dart` and `final_result_screen.dart` separate farmer summary from technical expansion; history/export retain technical output | `final_result_farmer_summary_test.dart`, `final_result_breakdown_capture_test.dart` | Pending visual UAT |
| 3.1 | Consistent visible TTS on important screens | PASS | Shared `TtsButton` used across onboarding, activity, assessment, result, history/help surfaces | Widget suite exercises TTS controls | iPhone listening UAT PASS; user reports Thai pronunciation is much improved and acceptable |
| 3.2 | Concise action-oriented speech | PASS | `tts_button.dart` normalizes phrasing/rate; result and activity screens provide short text | `tts_button_voice_quality_test.dart`, `final_result_farmer_summary_test.dart` | iPhone listening UAT PASS on 2026-07-12 |
| 3.3 | Readable assessment detail with icons and short sections | DEVICE-ONLY | `evaluation_form_screen.dart` uses section cards, icons, progressive technical detail, and responsive content | `evaluation_form_required_data_validation_test.dart`, screenshot capture tests | Pending tablet visual UAT |
| 3.4 | Body Map leads; angles/subscores remain technical | PASS | `body_risk_map_card.dart`, farmer-first result cards, expandable staff detail | `final_result_farmer_summary_test.dart`, `final_result_breakdown_capture_test.dart` | Pending visual UAT |
| 3.5 | REBA/ISO summary for farmers and full staff/research detail | PASS | Result screens summarize risk; technical expansion and export preserve REBA/ISO fields | `final_result_breakdown_capture_test.dart`, `assessment_export_service_test.dart` | Pending visual/export UAT |
| 4.1 | Categorized, risk-linked recommendations | PASS | `risk_recommendation_service.dart`, `initial_risk_screen.dart`, and `final_result_screen.dart` use four explicit categories with one concise selectable action per row; full text remains in staff detail | `risk_recommendation_service_test.dart`, `initial_risk_confirmation_test.dart`, `final_result_farmer_summary_test.dart` | iPhone visual UAT PASS on 2026-07-12 |
| 4.2 | Final summary includes cost, risky body parts, and specific actions | PASS | `final_result_screen.dart`, `economic_impact_comparison_card.dart`, `body_risk_map_card.dart` | `final_result_farmer_summary_test.dart`, `economic_impact_compare_capture_test.dart` | Pending visual UAT |
| 5.1 | Preserve illustrated activity-selection UI and sound controls | PASS | `evaluation_menu_screen.dart` retains activity graphics, Thai labels, and TTS | Screenshot/widget suite | Pending visual UAT |
| 5.2 | Manual uses real app screenshots and short step guidance | PASS | Bundled PDF and `assets/images/manual_pages` are exposed by `ManualDocumentService` and Help | `help_screen_image_examples_test.dart`, `help_activity_examples_capture_test.dart` | Pending PDF visual inspection on device |
| 6.1 | Simple trend with farmer/activity/month filtering and filtered export | PASS | `history_tab.dart`, `daily_prediction_screen.dart`, filtered export workflow | `history_tab_filter_trend_test.dart`, `daily_prediction_screen_test.dart`, `assessment_export_service_test.dart` | iPhone filter/export UAT PASS on 2026-07-12 |
| 6.2 | Complete research metadata in each export | PASS | `assessment_export_service.dart` exports farmer, date, activity, risk, body, photo, AI, and app-version metadata | `assessment_export_service_test.dart`, `training_data_export_service_test.dart` | iPhone exported-file flow UAT PASS on 2026-07-12 |
| 6.3 | Backup and migrate old data across app updates | PASS | `app_state.dart` creates pre-schema backup, migrates legacy draft/history, and stamps schema/app versions | `evaluation_draft_state_test.dart`, `app_state_evaluation_persistence_test.dart`, `assessment_export_service_test.dart` | Pending upgrade/relaunch UAT |

## Confirmed Implementation Work

1. Physical-device validation of the portrait-only platform configuration.
2. Physical-device validation of multi-person rejection with real photos.

## Baseline Evidence

- `/Users/kpc/develop/flutter/bin/flutter analyze --no-pub`: PASS on 2026-07-12 (`No issues found!`).
- `/Users/kpc/develop/flutter/bin/flutter test --no-pub --concurrency=2`: PASS during overnight verification (107 tests, zero failures).
- Android debug artifact: created on 2026-07-12 at `build/app/outputs/flutter-apk/app-debug.apk`; APK inspection confirms `android:screenOrientation="1"` (portrait) and both MoveNet models are bundled. The Flutter/Gradle command did not return its normal completion line and is reported as `PARTIAL PASS`.
- iOS signed Profile build: `PASS`; a clean build from fresh derived data was signed, bundle-verified, installed, and inspected for portrait-only orientation and required ML assets.
- Physical-device UAT: iPhone workflow is `PASS` for install/launch, orientation, avatars, drafts, activity changes, photo slots, multi-person rejection, UAT assessment bypass, categorized recommendations, Thai TTS, filtering, and export. Offline relaunch remains pending. Android physical UAT has not started by user instruction.
