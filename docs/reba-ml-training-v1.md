# REBA ML Training v1

Updated: 2026-05-24

This document records the first real offline ML artifact added to fSookta after
the store-submission build. The goal is to make the ML path repeatable while
keeping the research claims honest.

## Source

- REBA worksheet: `/Users/kpc/Documents/Doc/REBA.pdf`
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
- Label source: deterministic REBA pseudo-labels
- Risk distribution:
  - low: `3`
  - medium: `381`
  - high: `4`
  - very high: `0`
- Training-set risk accuracy: `0.982`
- REBA score mean absolute error: `0.4839`

The high accuracy is mostly caused by the dataset being dominated by medium-risk
samples. It should not be interpreted as proof of validated model quality.

## App Integration

The Logistic Regression predictor already loads:

```text
assets/models/logistic_weights.json
```

The exported JSON now contains:

- `modelSource: reba_worksheet_pseudo_trained`
- `mean` and `standardDeviation` used for the same preprocessing at inference
- `weights` and `intercept`
- probability thresholds mapped to the REBA risk bands
- embedded training metrics for auditability

## Next Research Iteration

1. Review the generated pseudo-label dataset with the research team.
2. Add or capture more clear low-risk, high-risk, and very-high-risk examples.
3. Replace pseudo-labels with expert-reviewed labels where available.
4. Retrain Logistic Regression and compare metrics.
5. Train XGBoost and export `assets/models/xgboost_model.onnx` for A/B testing.
