# Sookta REBA + ISO11228-1 Calibration Training Log

Date: 2026-06-07

## Calibration Source

- Source file: `/Users/kpc/Documents/TestSookta/Calibtation/Calibtation.pdf`
- Extracted calibration rows:
  - Transplanting / การปลูกกล้า: REBA 11, ISO11228 16, SookTa 3
  - Fertilizing / การใส่ปุ๋ย: REBA 9, ISO11228 10, SookTa 3
- App training file: `data/research/expert_labels/calibration_reba_iso_labels_20260607.csv`

The calibration PDF provides REBA, ISO11228, and SookTa summary scores. It does not provide Logistic Regression coefficients, daily injury/treatment labels, or any other fields suitable for training the 7-transaction Logistic Regression predictor.

## ISO11228 Workbook Source

- Source file: `/Users/kpc/Documents/Doc/ISO11228 Pirawan.xlsx`
- Extractor: `tools/research_dataset/extract_iso11228_workbook_labels.py`
- Output: `data/research/expert_labels/iso11228_expert_labels.csv`
- Extracted labels: 34 sessions
- Included activities: transplanting, fertilizing, pesticide spraying, pruning, harvesting, on-farm transport
- Skipped rows: worksheet blocks with total score 0 or notes indicating no video

This workbook is now the primary ISO label source for REBA+ISO model training. It replaced the earlier smaller ISO label CSV.

## Model Separation Decision

- Current posture assessment model: `assets/models/xgboost_model.onnx`
- Current posture assessment input: 51 raw MoveNet joint features
- Current posture assessment target: combined REBA + ISO REBA-equivalent risk probability
- Removed from packaged posture-assessment assets: `assets/models/logistic_weights.json`
- Daily predictive Logistic Regression remains separate at `assets/ml/daily_injury_logistic_model.json`

## Label Preparation

Command:

```bash
PYTHONPATH=/private/tmp/fsookta-ml-deps:. \
/Users/kpc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
tools/research_dataset/train_reba_logistic_model.py \
--labels-only \
--metrics-output data/research/extracted/reba_iso_label_prep_metrics.json
```

Result:

- Pose samples prepared: 388
- Calibration label rows loaded: 2
- Calibration matched pose samples: 0
- ISO11228 workbook matched pose samples: 388
- Combined REBA+ISO sample count: 388
- Resulting risk distribution: 236 high, 152 veryHigh
- Reason calibration remains unmatched: the current downloaded raw pose dataset contains pruning, harvesting, and on-farm transport rows, but no transplanting/fertilizing pose rows yet.
- Logistic Regression output: skipped

## XGBoost ONNX Training

Command:

```bash
PYTHONPATH=/private/tmp/fsookta-ml-deps:. \
/Users/kpc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
tools/research_dataset/train_xgboost_onnx_model.py
```

Result:

- Model version: `reba-iso-xgboost-onnx-2026-06-07`
- Output: `assets/models/xgboost_model.onnx`
- Metadata: `assets/models/xgboost_model_metadata.json`
- Metrics: `data/research/extracted/xgboost_onnx_metrics.json`
- Training samples: 298
- Holdout samples: 90
- Holdout risk accuracy: 0.6667
- Holdout combined REBA-equivalent score MAE: 0.8256

## Important Limitation

The ISO11228 workbook now affects the fitted XGBoost model for all currently matched pose rows. The calibration PDF has also been wired into the training pipeline, but it cannot affect the fitted trees until raw pose rows for transplanting/fertilizing are downloaded and extracted. Once those media rows exist in `data/research/media/transplanting` and `data/research/media/fertilizing`, rerunning the same commands will apply these calibration scores to the model training set.

The full ISO workbook shifts the current matched training set to high/veryHigh only. This is more consistent with the supplied ISO worksheet labels, but it also reduces holdout class balance. More low/medium expert-labeled media should be collected before claiming final validation accuracy.

## Recommendation Source

- Source file: `/Users/kpc/Documents/TestSookta/Calibtation/ชุดคำแนะนำตามความเสี่ยง Body map.pdf`
- App files updated:
  - `lib/core/services/risk_recommendation_service.dart`
  - `lib/screens/main/initial_risk_screen.dart`
  - `lib/core/localization/sookta_strings.dart`

The recommendation source is used as an application guidance layer, not as numeric ML training data. The app now adds body-part-specific recommendations for neck, trunk, arms/shoulders, wrists/hands, legs/knees, and manual handling according to the detected Body Map risk level.
