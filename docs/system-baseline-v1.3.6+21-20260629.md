# Sookta System Baseline v1.3.6+21

Snapshot date: 2026-06-29

## Version Baseline

- Canonical app version: `1.3.6+21`
- Source of truth:
  - `pubspec.yaml`: `version: 1.3.6+21`
  - `lib/app/build_info.dart`: `SooktaBuildInfo.label = 1.3.6+21`
- Android application ID: `com.kdev.sookta`
- iOS bundle/versioning uses Flutter build name/build number through the Runner project for main build configurations.
- README version/status was updated in this baseline pass so the documented current version matches `1.3.6+21`.

## Product Summary

Sookta is an offline-first Flutter app for ergonomic risk assessment and research support in coffee-farming workflows. It helps field users capture posture evidence, estimate ergonomic risk, explain affected body areas, estimate economic impact, recommend risk-reduction actions, save assessment history, and export CSV files for staff/research follow-up.

The app is not positioned as a medical diagnosis or medical certification tool.

## Primary Users And Context

- Farmers / field participants: guided assessment, readable results, voice support, recommendations.
- Research or field staff: manage farmer records, export assessment/history/training CSV files, review history and trend signals.
- Project owner / support channel: surfaced through the Contact screen.

## Current Navigation And Screens

- Onboarding:
  - Splash
  - Language selection: Thai / English
  - Setup profile
  - Avatar selection from built-in assets, camera, or gallery
- Main tabs:
  - Home
  - History
  - Profile
- Assessment flow:
  - Activity selection
  - Evaluation form
  - Initial risk result
  - Final/improved result
- Supporting screens:
  - Farmer manager
  - History detail
  - Daily prediction / seven-record trend
  - Risk reduction potential
  - Training data export
  - Help / user manual / activity examples
  - References
  - Terms
  - Contact / version display
  - Route error fallback

## Main Capabilities

### Profile And Farmer Management

- Stores language, setup completion, active profile, farmer list, and assessment history locally with `SharedPreferences`.
- Supports multiple farmer profiles.
- Tracks farmer ID, name, role, location, age, gender, weight, height, annual income, avatar, BMI, and BMI category.
- Computes daily income from annual income, with a default fallback.

### Assessment Inputs

- Supports six coffee-farming activities:
  - Planting / transplanting
  - Fertilizing
  - Pesticide spraying
  - Pruning
  - Harvesting
  - On-farm transport
- Each activity has default job type, tool/load options, workload assumptions, and localized labels.
- Job types:
  - REBA
  - ISO 11228 lifting
  - ISO 11228 push/pull
  - Combined REBA + ISO where relevant
- Supports advanced/manual ergonomic inputs:
  - Load weight
  - Horizontal distance
  - Vertical height
  - Frequency
  - Duration
  - Work days per week
  - Transport/push-pull distance
  - Initial and sustained force
  - REBA posture component scores and modifiers

### Image, Video, And Pose Analysis

- Captures or imports photos.
- Supports up to four image slots per assessment.
- Captures or imports videos up to 20 seconds.
- Extracts up to eight video frames via native platform method channel `sookta/video_frames`.
- Uses bundled MoveNet Thunder TFLite model for pose estimation.
- Converts MoveNet keypoints into REBA posture inputs and joint feature vectors.
- Estimates lifting H/V dimensions from pose when possible.
- For video, builds a motion summary including readable frames, high-risk frame ratio, dominant risk body part, movement changes, and worst posture selection.

### Ergonomic Risk Calculation

- REBA calculation uses table-based scoring for posture, load, coupling, and activity factors.
- ISO lifting risk uses load, H/V dimensions, frequency, duration, gender reference mass, and related multipliers.
- ISO push/pull risk uses initial/sustained forces and distance inputs.
- Combined REBA + ISO keeps the higher real-task risk when ISO applies.
- Risk levels: low, medium, high, very high.
- Body part risk map covers neck, trunk, legs, arms, and wrists.

### ML And Risk Signals

- Bundled ML assets:
  - `assets/ml/movenet_thunder.tflite`
  - `assets/models/xgboost_model.onnx`
  - `assets/models/xgboost_model_metadata.json`
  - `assets/models/joint_feature_schema.json`
  - `assets/ml/daily_injury_logistic_model.json`
  - `assets/ml/risk_alert_models.json`
- Current assessment flow uses XGBoost ONNX as a guardrail on posture-derived risk.
- Daily/seven-record prediction uses logistic regression features from recent history.
- Legacy risk alert service is still present but comments indicate posture assessment now uses `XGBoostOnnxPredictor`, while logistic regression is reserved for daily injury prediction.

### Results And Recommendations

- Shows before-improvement risk score, level, explanation, body map, assessment method summary, and economic impact.
- Lets user select realistic risk-reduction actions.
- Simulates after-improvement score and impact reduction.
- Shows final result and saves it to local history.
- Recommendation content is activity-specific, body-part-aware, and localized in Thai/English.
- Includes voice/TTS buttons across key screens to read guidance and results.

### History, Trends, And Export

- Stores assessment history locally.
- History tab lists all records and supports exporting one record or all records as Excel-compatible CSV.
- History detail can export an individual record.
- Final result can export staff CSV.
- Training data export produces CSV bundles for research/model work.
- Daily prediction/trend screen uses recent records to show trend signals and before/after series.
- Export content includes profile fields, activity, job type, scores, risk levels, assessment breakdown, body part risk, impact estimates, selected recommendations, and research notes.

### Help, Documentation, And Compliance Surfaces

- Help screen includes activity examples and user guidance.
- User manual PDF is bundled at `assets/documents/sookta_user_manual.pdf`.
- References and terms screens are part of the app.
- Contact screen displays project owner information and the app version.
- Research disclaimer components are present in result surfaces.
- Firebase Crashlytics and Analytics are initialized if Firebase config is available.

## Technical Shape

- Flutter app targeting Android and iOS.
- State management is a simple inherited `SooktaAppState` over `ChangeNotifier`.
- Local-first data storage uses `SharedPreferences` and app documents/temp directories.
- Native/platform integrations:
  - Camera
  - Image picker
  - Share sheet
  - TTS
  - TFLite
  - ONNX Runtime through local `third_party/onnxruntime_16kb` override
  - Firebase Crashlytics/Analytics
  - Native video frame extraction channel
- Test coverage includes unit tests, widget tests, ML tests, export tests, screenshot capture tests, and integration smoke/device inference tests.

## UI/UX Redesign Notes

- The feature surface is broad. A redesign should treat this as an operational/research workflow, not just a simple consumer health app.
- The assessment flow has many high-value states that need deliberate UX:
  - Empty/no image
  - Pose detection in progress
  - Pose unreadable
  - Video too long or frame extraction failed
  - Pose readable but H/V dimensions unavailable
  - ML guardrail available/unavailable
  - Before/after recommendation selection
  - Export/share success or failure
- The system already has strong domain logic. UI/UX work should avoid changing scoring semantics unless the calculation/test suite is updated intentionally.
- Multi-farmer data ownership is important: every history/export surface should make the active farmer and record context obvious.
- Voice/TTS is a first-class accessibility aid and should remain visible in redesigned guidance/result moments.
- The app currently mixes farmer-friendly language, staff export language, research documentation, and model/training tools. The redesign should separate these roles more clearly.
- Dashboard/home could expose the latest score, active farmer, trend readiness, and next assessment action more prominently.
- Profile currently contains many operational tools; consider grouping profile, research export, help/legal, and contact into clearer sections.
- Result screens are the most important redesign area: score, body map, economic impact, method breakdown, selected actions, and final export all compete for attention.

## Known Baseline Issues Before UI/UX Work

- `android/app/build.gradle.kts` still has default Flutter TODO comments around application ID and signing config, even though the app ID is set.
- Android release signing currently references debug signing in Gradle; verify release pipeline before any store submission.
- Some research/export/model features are exposed from Profile and may feel too technical for farmer-facing users.
- The codebase has both current and legacy ML services; redesign documentation should name which signal is shown where to avoid confusing users.
