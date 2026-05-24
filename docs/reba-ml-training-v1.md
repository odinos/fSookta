# REBA ML Training v1

Updated: 2026-05-24

This document records the first real offline ML artifact added to fSookta after
the store-submission build. The goal is to make the ML path repeatable while
keeping the research claims honest.

## Source

- REBA worksheet: `/Users/kpc/Documents/Doc/REBA.pdf`
- Secondary REBA implementation reference:
  `https://ergo-plus.com/reba-assessment-tool-guide/`
- Research-team REBA-2 labels:
  `data/research/expert_labels/reba2_expert_labels.csv`, extracted from
  `/Users/kpc/Documents/Doc/ผลวิเคราะห์ REBA-2.xlsx`
- Research-team ISO 11228 labels:
  `data/research/expert_labels/iso11228_expert_labels.csv`, extracted from
  `/Users/kpc/Documents/Doc/ISO11228 Pirawan.xlsx`
- Local model-training reference registry:
  `data/research/reference_sources/training_reference_sources.json`
- ISO/REBA/agriculture references under `/Users/kpc/Documents/Doc/fortrain/`:
  ISO 11228-1, ISO 11228-2, ISO 11228-3, the REBA step-by-step guide, and
  `wcms_168042.pdf` for agriculture recommendation controls
- Pose dataset: `data/research/extracted/pose_feature_dataset.csv`
- Feature schema: `assets/models/joint_feature_schema.json`
- Flutter model asset: `assets/models/logistic_weights.json`

The REBA worksheet provides the score-to-risk interpretation:

- `1`: low/negligible risk
- `2-3`: low risk
- `4-7`: medium risk
- `8-10`: high risk
- `11+`: very high risk

## Training Command

Run from the Flutter repo root:

```sh
/Users/kpc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/research_dataset/train_reba_logistic_model.py
```

Outputs:

- `assets/models/logistic_weights.json`
- `data/research/extracted/reba_logistic_metrics.json`
- `data/research/extracted/reba_labeled_pose_dataset.csv`

The generated files under `data/research/extracted/` are ignored by git because
they are research outputs. The Flutter asset is committed because the app uses it
offline.

## Current Metrics

- Training sample count: `388`
- Raw input feature count: `51`
- Model feature count after `reba_angle_features_v1`: `71`
- Label source: research-team REBA-2 labels for the extracted sessions
- Label match distribution:
  - exact expert session match: `264`
  - parent-session mean from child labels: `124`
- Risk distribution:
  - low: `29`
  - medium: `154`
  - high: `205`
  - very high: `0`
- Training-set risk accuracy: `0.5644`
- REBA score mean absolute error: `1.5791`

The previous pseudo-label model reported higher accuracy because almost every
sample was labeled medium risk. The current metrics are more conservative but
more useful for research because they are anchored to field labels from the
research team.

## Feature Engineering

The app still receives the canonical 51-value MoveNet vector. Before Logistic
Regression inference, both the training script and the Flutter predictor append
20 REBA-oriented geometry features:

- trunk angle and neck angle
- left/right/worst upper-arm angle
- left/right elbow angle and worst lower-arm deviation from the REBA lower-arm
  comfort band
- left/right knee angle and worst knee flexion
- shoulder and hip slope/width
- upper-body lean
- visible keypoint ratio, average keypoint score, lower-body visibility, and
  upper-body visibility

This makes the current Logistic Regression model closer to REBA reasoning while
keeping the on-device input contract stable for MoveNet.

## App Integration

The Logistic Regression predictor already loads:

```text
assets/models/logistic_weights.json
```

The exported JSON now contains:

- `modelSource: research_team_reba2_plus_pseudo_trained`
- `inputFeatureCount: 51`
- `featureCount: 71`
- `featureEngineering: reba_angle_features_v1`
- `mean` and `standardDeviation` used for the same preprocessing at inference
- `weights` and `intercept`
- probability thresholds mapped to the REBA risk bands
- embedded training metrics for auditability

## Economic Impact Layer

Treatment-cost survey data is intentionally used after risk assessment, not as
the ML training label. The current flow is:

```text
MoveNet features -> REBA expert-seeded Logistic Regression -> risk/body areas
-> EconomicImpactService -> estimated impact shown to the farmer
```

The economic layer combines:

- body-area treatment costs, such as neck, shoulder, wrist, back, hip, thigh,
  and knee
- weighted average medical visit costs from public hospital, private hospital,
  and private clinic/doctor records
- medicine/supplies, travel, lost income, and reduced income survey rows

This keeps the model focused on posture risk while still communicating the
practical financial impact from the cost tables.

## Next Research Iteration

1. Extract pose rows for more sessions listed in the REBA-2 workbook.
2. Replace parent-session mean labels with exact frame/session labels where the
   research team can identify them.
3. Use ISO 11228-1/2/3 from the local reference registry to expand structured
   lifting, push/pull, and repetitive upper-limb label fields.
4. Use the agriculture checkpoints reference to map recommendations to auditable
   control categories.
5. Train XGBoost and export `assets/models/xgboost_model.onnx` for A/B testing.
6. Run fixed-vector on-device inference tests against expert-labeled samples.
