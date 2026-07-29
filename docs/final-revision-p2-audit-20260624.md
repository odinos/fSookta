# Sookta Final Revision P2 Audit

Date stamped: 2026-06-24

Source document:
`/Users/kpc/Desktop/SookTa Application – Final Revision Requirements for Field Test and PhD Research.xlsx`

## P2 Scope

The workbook defines Priority 2 as:

- Body Region Risk
- Expert Assessment Fields
- Improvement Card
- Trend Level

Note: The workbook text says the trend should use Before Improvement values. The app now follows the workbook and bases the trend on before-improvement actual-risk records.

## Implementation Status

| P2 item | Status | Evidence |
| --- | --- | --- |
| Body Region Risk | Done | All-history export includes `neck_risk`, `shoulder_risk`, `upper_limb_risk`, `wrist_risk`, `back_risk`, `knee_risk`. `upper_limb_risk` now uses the higher risk between arms and wrists. |
| Expert Assessment Fields | Done | `EvaluationHistoryRecord` persists `expertReba`, `expertRiskLevel`, `expertAssessmentDate`, and `expertComments`; export maps them into `expert_REBA`, `expert_risk_level`, `expert_assessment_date`, and `expert_comments`. |
| Usability Fields supporting Field Test | Done | `EvaluationHistoryRecord` persists `timeOnTaskSeconds`, `completionStatus`, `assistanceRequired`, and `errorCount`; export maps them into the field-test columns. |
| Improvement Card | Done | Initial and final result screens show before/after score and economic impact comparison via `EconomicImpactComparisonCard`. |
| Trend Level | Done | All-history export adds `trend_level`; UI trend level already follows low/watch/high/very high based on high-risk count. |

## Trend Level Rule

The app uses the latest 7 transactions for the selected farmer. The trend uses before-improvement actual-risk scores:

| High-risk records in latest 7 | Trend level |
| --- | --- |
| 0-1 | Low / ต่ำ |
| 2-3 | Watch / เฝ้าระวัง |
| 4-5 | High / สูง |
| 6-7 | Very high / สูงมาก |

## Updated Export Fields

New or strengthened P2 fields:

- `trend_level`
- `time_on_task_seconds`
- `completion_status`
- `assistance_required`
- `error_count`
- `expert_REBA`
- `expert_risk_level`
- `expert_assessment_date`
- `expert_comments`

Related files:

- `lib/app/app_state.dart`
- `lib/core/services/assessment_export_service.dart`
- `test/assessment_export_service_test.dart`
- `docs/field-test-export-data-dictionary-20260623.md`
- `docs/qa/sample-field-export-p2-20260624.csv`

## Verification

Tests added/updated:

- All-farmer export maps wrist risk into `upper_limb_risk`.
- All-farmer export includes `trend_level` derived from latest 7 before-improvement actual-risk records.
- All-farmer export persists and outputs usability and expert assessment fields from transaction JSON.

Verification command used from the clean temp tree:

`flutter test test/assessment_export_service_test.dart --reporter compact`
