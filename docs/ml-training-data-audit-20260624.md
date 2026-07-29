# ML Training Data Audit - App Export 2026-06-24

## Input Files

| File | Rows | Columns | Farmers | Main activities |
|---|---:|---:|---|---|
| `sookta_all_farmers_2026-06-22T212333510721.csv` | 23 | 40 | FSK-807516: 23 | Harvesting: 5, Planting: 12, Maintenance: 4, Maintenance / Pruning: 2 |
| `sookta_all_farmers_2026-06-23T080342545527.csv` | 7 | 40 | FSK-240919: 7 | Planting: 4, Maintenance: 3 |


## Combined Readiness

- Combined transaction rows: **30**
- Farmers: **2**
- Sliding 7-transaction windows generated for Logistic Regression labeling: **18**
- Duplicate logical records found: **0** from the audit pass

## What This Data Can Train

### Daily Logistic Regression

Status: **feature rows are ready, but model training is still blocked until outcome labels are filled.**

The two CSV exports contain enough app history to create 7-transaction windows. I generated:

`data/research/extracted/app_exports/daily_logistic_windows_from_app_exports_20260624_unlabeled.csv`

The following outcome columns are intentionally blank and must be filled by the research team before fitting Logistic Regression:

- `requires_medical_treatment_within_7_days`
- `msd_symptom_present`
- `medical_visit_within_7_days`
- `treatment_required_within_7_days`
- `msd_symptom_location`
- `msd_symptom_severity`
- `lost_workdays_7d`
- `direct_medical_cost_thb`
- `productivity_loss_thb`
- `label_confidence`
- `outcome_source`
- `reviewer_id`
- `reviewed_at`

Important: app-generated REBA score, ISO score, and economic impact must be used as input features, not as the target label. Training against the app's own risk result would create circular validation and would not prove the model predicts real treatment or MSD outcomes.

Because these two files are the older all-farmers summary export, they do not contain assessment body-part breakdown fields. The converted CSV therefore sets `trunk_high_days_norm`, `neck_high_days_norm`, and `upper_limb_high_days_norm` to `0`. It intentionally does **not** derive those features from `MSD Symptom Location`, because symptom location belongs to outcome/follow-up evidence and using it as an input would leak the answer into training.

### XGBoost / ONNX REBA + ISO Posture Model

Status: **not trainable from these two CSV files alone.**

The XGBoost ONNX trainer expects raw MoveNet pose feature rows with 51 landmark values plus research labels. These all-farmer CSV exports contain assessment summaries, but they do not contain:

- `nose_x` ... `rightAnkle_score` 51-value MoveNet features
- frame timestamp / frame index
- pose confidence / pose status
- research expert REBA or ISO label per frame

Use the app's training export for `sookta_train_xgboost_pose_*.csv` or rerun media extraction from raw images/videos to generate pose-level rows.

## Pipeline Notes Found During Code Review

- The app export service already creates modern 26-feature daily Logistic windows.
- The Python trainer now accepts the current app-exported 26-feature daily Logistic window CSV directly. It still keeps backward compatibility with the older transaction-template input.
- The current production Logistic JSON is still marked `researchTrained: false`, so it should not be described as research-trained until outcome labels are supplied and the model is refit.

## Recommended Next Step

1. Send `daily_logistic_windows_from_app_exports_20260624_unlabeled.csv` to the research team.
2. Fill the outcome label columns from 7-day follow-up, CMDQ, medical visit, treatment, symptoms, and lost workday evidence.
3. Re-import the labeled CSV and train Daily Logistic Regression.
4. Keep XGBoost/ONNX training separate using raw pose datasets, not this all-farmer summary export.
