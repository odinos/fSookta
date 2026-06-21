# Sookta ML Model Separation - 2026-06-06

## Change Summary

The app now separates posture-risk assessment from daily injury/treatment
prediction.

## 1. REBA and ISO11228-1 Assessment

REBA and ISO11228 assessment remains the source of truth for the current
assessment result shown to the farmer.

- MoveNet reads body keypoints from the photo.
- REBA posture scores are inferred from the photo for every activity, not only
  REBA-only tasks.
- Lifting tasks combine REBA with ISO11228-1 lifting exposure.
- XGBoost ONNX is used as a separate posture-risk guardrail/calibration model.
- Logistic Regression is no longer called during the assessment flow.

This prevents Logistic Regression coefficients trained for a different target
from distorting today's REBA/ISO score or body-part recommendations.

## 2. Logistic Regression Daily Prediction

Logistic Regression is moved to a separate 7-transaction history prediction
flow.

- 1 transaction = 1 assessment day.
- The app uses the latest 7 transactions for the selected farmer.
- The model predicts whether the pattern should be flagged for research/medical
  follow-up.
- The prediction is shown on a separate screen from the History tab.
- The app displays a notification after saving when a farmer reaches every 7
  records and the model flags high follow-up risk.

Current asset:

- `assets/ml/daily_injury_logistic_model.json`

Training template:

- `data/research/templates/daily_injury_logistic_training_template.csv`

Trainer:

- `tools/research_dataset/train_daily_injury_logistic_model.py`

## 3. Training Status

The existing REBA/ISO dataset contains posture and risk labels, but does not
yet contain confirmed outcome labels such as treatment-required MSD follow-up.
Therefore, the daily Logistic model is implemented as an app-ready template
model and must be retrained once the research team supplies daily outcome
labels.

Run after labels are added:

```bash
python3 tools/research_dataset/train_daily_injury_logistic_model.py \
  --input data/research/templates/daily_injury_logistic_training_template.csv \
  --output assets/ml/daily_injury_logistic_model.json
```

## 4. Body Angle Logic Fix

The pose-to-REBA logic now uses both left/right landmarks and midpoint fallback.
For trunk, arms, and legs it chooses the worst visible side instead of relying
on the first right/left landmark available. This reduces the risk of deep
forward-bending postures being incorrectly attributed only to the arms.

## 5. REBA Table Alignment

The app and training label generator now use the standard REBA worksheet flow:

- Table A combines neck, trunk, and legs, then force/load is added as Score A.
- Table B combines upper arm, lower arm, and wrist, then coupling is added as
  Score B.
- Table C combines Score A and Score B.
- Activity is added after Table C to produce the final REBA score.

XGBoost was retrained on 2026-06-06 after this alignment:

- Asset: `assets/models/xgboost_model.onnx`
- Metadata: `assets/models/xgboost_model_metadata.json`
- Metrics: `data/research/extracted/xgboost_onnx_metrics.json`
- Holdout risk accuracy: `0.9333`
- Holdout combined REBA-equivalent score MAE: `0.6679`
