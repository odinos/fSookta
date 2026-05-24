# Ergonomic Risk Model Artifact Contract

This app runs ergonomic risk prediction fully offline. Every trained model must
use the same MoveNet feature schema before it can be shipped in the app.

## Feature Schema

- Schema asset: `assets/models/joint_feature_schema.json`
- Schema ID: `movenet-thunder-v1-17x3-normalized`
- Feature count: `51`
- Source: MoveNet Thunder single-pose output
- Flatten order: for each landmark in MoveNet index order, append `x`, `y`,
  `score`
- Missing landmark policy: emit `0.0, 0.0, 0.0`
- ERGO process contract: `assets/models/ergo_process_detail.json`, sourced
  from the Notion page `ERGO process Detail`.
- Training reference registry:
  `data/research/reference_sources/training_reference_sources.json`, covering
  local ISO 11228-1/2/3, REBA, and agriculture-checkpoint references.

The landmark order is:

1. nose
2. leftEye
3. rightEye
4. leftEar
5. rightEar
6. leftShoulder
7. rightShoulder
8. leftElbow
9. rightElbow
10. leftWrist
11. rightWrist
12. leftHip
13. rightHip
14. leftKnee
15. rightKnee
16. leftAnkle
17. rightAnkle

## Required Logistic Regression JSON

Path: `assets/models/logistic_weights.json`

Required fields:

- `version`
- `featureSchemaId`
- `modelSource`
- `inputFeatureCount`, the raw MoveNet feature count accepted by the app
- `featureCount`
- `featureEngineering`, when the app must expand raw MoveNet values before
  inference
- `intercept`
- `weights`, length must equal `featureCount`
- `thresholds.medium`
- `thresholds.high`
- `thresholds.veryHigh`

Optional fields:

- `mean`, length must equal `featureCount`
- `standardDeviation`, length must equal `featureCount`
- `featureNames`, length should equal `featureCount`
- `engineeredFeatureNames`, when `featureEngineering` is present
- `mlAlgoModelJson`, exported `ml_algo` model JSON if the training pipeline
  uses native `ml_algo` serialization

## Required XGBoost ONNX

Path: `assets/models/xgboost_model.onnx`

The ONNX graph must accept a dense Float32 tensor shaped `[1, 51]`. The app
passes the canonical MoveNet feature vector directly. If training uses
standardization, bake it into the exported ONNX graph or provide a matching
preprocessing layer before the model is exported.

## Production Gate

Do not mark the model as research-trained until all are true:

- Logistic JSON has `modelSource: "research_trained"`.
- Logistic JSON `featureSchemaId` matches `joint_feature_schema.json`.
- `xgboost_model.onnx` exists and was exported from the same feature schema.
- Fixed sample vectors from the research dataset pass on-device inference tests.
- Expert labels include the ERGO process fields required by REBA and ISO
  11228-1/2, including trunk twist, trunk side flexion, wrist twist, coupling,
  activity, lifting inputs, and push/pull force limits.

## Current REBA Expert-Seeded Model

The app now includes a first real Logistic Regression artifact trained from the
local MoveNet research dataset:

- Asset: `assets/models/logistic_weights.json`
- Model source: `research_team_reba2_plus_pseudo_trained`
- Training script: `tools/research_dataset/train_reba_logistic_model.py`
- Training rows: `388` valid MoveNet pose rows from
  `data/research/extracted/pose_feature_dataset.csv`
- Input feature count: `51` raw MoveNet values
- Model feature count: `71`, after appending `reba_angle_features_v1`
- Engineered features: trunk angle, neck angle, arm angles, elbow deviation,
  knee flexion, shoulder/hip slope and width, upper-body lean, and visibility
  quality features
- Label source: research-team REBA-2 labels extracted to
  `data/research/expert_labels/reba2_expert_labels.csv`. Exact session matches
  are preferred. Ambiguous parent media folders, such as `4.1`, use the
  traceable mean of child labels such as `4.1.1` and `4.1.2`.
- ISO 11228 research labels are extracted to
  `data/research/expert_labels/iso11228_expert_labels.csv` for the combined
  ergonomic/economic layer and future multi-task model work.
- ISO 11228-1/2/3 and agriculture recommendation references are tracked in
  `data/research/reference_sources/training_reference_sources.json`; the PDFs
  remain outside the repository because several are copyright-protected
  standards.
- Metrics output: `data/research/extracted/reba_logistic_metrics.json`

This is a real on-device ML artifact seeded by field labels from the research
team. It is still not a fully validated research model because the current
extracted pose dataset covers only a subset of sessions and some labels are
mapped at parent-folder level.
