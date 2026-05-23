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
- `featureCount`
- `intercept`
- `weights`, length must equal `featureCount`
- `thresholds.medium`
- `thresholds.high`
- `thresholds.veryHigh`

Optional fields:

- `mean`, length must equal `featureCount`
- `standardDeviation`, length must equal `featureCount`
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

## Current REBA Pseudo-Trained Model

The app now includes a first real Logistic Regression artifact trained from the
local MoveNet research dataset:

- Asset: `assets/models/logistic_weights.json`
- Model source: `reba_worksheet_pseudo_trained`
- Training script: `tools/research_dataset/train_reba_logistic_model.py`
- Training rows: `388` valid MoveNet pose rows from
  `data/research/extracted/pose_feature_dataset.csv`
- Label source: deterministic REBA pseudo-labels derived from posture geometry,
  task defaults, and the REBA worksheet risk bands in `/Users/kpc/Documents/Doc/REBA.pdf`
- Metrics output: `data/research/extracted/reba_logistic_metrics.json`

This is a real on-device ML artifact, but it is not yet an expert-validated
research model. The current source data is strongly concentrated in the medium
risk band, so the next research iteration should add or review more low, high,
and very-high posture samples before using the model for comparative research
claims.
