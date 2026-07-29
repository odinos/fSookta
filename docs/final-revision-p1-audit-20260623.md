# Sookta Final Revision P1 Audit

Date stamped: 2026-06-23

Source document:
`/Users/kpc/Desktop/SookTa Application – Final Revision Requirements for Field Test and PhD Research.xlsx`

## Scope

This audit checks the P0/P1 field-test changes that affect the farmer-facing workflow and the research export workflow. It focuses on the items in the workbook `Task`, `No10`, and `Noted` sheets.

## Result Summary

| Requirement | Current status | Evidence in app/code |
| --- | --- | --- |
| Use Before Improvement / Actual Risk for the 7-transaction trend | Done | `DailyInjuryPredictionService.predictForRecords()` uses `scoreBefore`, `riskBefore`, and before-score chart values so the trend reflects real recorded work risk. |
| Rename daily prediction into a trend communication screen | Done | `DailyPredictionScreen` title is `แนวโน้มความเสี่ยง 7 ครั้งล่าสุด` / `Latest 7 Risk Trend`. |
| Do not show probability as a user-facing diagnosis | Done | Daily trend UI does not show probability. Initial AI posture signal now shows text level only, not percent. |
| Separate Before Improvement and After Improvement | Done | Initial result and final result show before score, after score, and economic impact comparison. |
| Show easy farmer-facing interpretation | Done | Initial result explains current score, selected-action score, economic impact before/after, and selected advice in simple text with TTS. |
| Add prominent PDF user manual | Done | Profile menu and Help screen include prominent PDF manual entry using `ManualDocumentService`. |
| Add readable posture example | Done | Help/Evaluation form use `assets/images/example_readable_pose.png`. |
| Lock estimated load to selected tool | Done | Evaluation form uses locked selected tool/load summary, not an editable estimated-load dropdown. |
| Update Work Space wording | Done | App text uses `พื้นที่ทำงาน (ไม่บังคับ)` / `Work Space (Optional)`. |
| Rename English Transplanting to Planting | Done | `SooktaActivity.transplanting` label and localization use `Planting`. |
| Update contact information | Done | Contact screen uses Faculty of Allied Health Sciences, Thammasat University, and Line ID `089088`. |
| Export mandatory research fields | Done | All-history CSV includes transaction, farmer, REBA/ISO before-after, trend, body-region, photo fields, UAT placeholders, and expert assessment placeholders. |
| Stamp today/every export with generated timestamp | Done | Export services include `Export Generated At` / file-generated timestamp from `DateTime.now()`. |

## Calculation Logic Check

### Current Transaction

One transaction means one completed assessment saved from the final result screen. The app stores:

- `transaction_id`: saved record id.
- `user_id`: farmer id, profile id, or fallback record id.
- `assessment_date` and `assessment_time`: saved transaction timestamp.
- `task_type`: selected activity.
- `REBA_before` and `REBA_risk_before`: posture risk before selecting advice.
- `ISO_before` and `ISO_risk_before`: ISO result when the activity includes ISO 11228.
- `REBA_after` and `REBA_risk_after`: simulated after-improvement score from selected advice.
- `ISO_after` and `ISO_risk_after`: currently mirrors the ISO result for the transaction when ISO is used.

### Seven-Transaction Trend

The latest 7 records are filtered per farmer and ordered by date. The trend fields use the before-improvement actual-risk values:

- `trend_REBA_average`: average of `scoreBefore`.
- `trend_REBA_maximum`: maximum of `scoreBefore`.
- `trend_high_risk_count`: number of records whose `riskBefore` is high or very high.
- `trend_direction`: increasing/decreasing/stable from last score minus first score.

Trend level shown in the app:

- 0-1 high-risk records: low.
- 2-3 high-risk records: watch.
- 4-5 high-risk records: high.
- 6-7 high-risk records: very high/critical.

### Economic Impact Before/After

The app uses the approximate communication formula:

`afterImpact = beforeImpact x (1 - scoreReduction x 28%)`

The score reduction is capped internally by the economic comparison service to avoid negative impact. This number is presented as an approximate economic communication estimate, not a medical cost or confirmed income loss.

## Export Proof

Primary code:

- `lib/core/services/assessment_export_service.dart`
- `lib/core/services/daily_injury_prediction_service.dart`
- `lib/screens/main/daily_prediction_screen.dart`
- `lib/screens/main/initial_risk_screen.dart`
- `lib/screens/main/final_result_screen.dart`

Tests:

- `test/assessment_export_service_test.dart`
- `test/daily_injury_prediction_service_test.dart`
- `test/widget_test.dart`

Sample export:

- `docs/qa/sample-field-export-20260623.csv`

Data dictionary:

- `docs/field-test-export-data-dictionary-20260623.md`

## P2 Follow-Up

P2 was completed on 2026-06-24. The export no longer only reserves blank placeholder columns: transaction records can persist usability and expert-review values, and all-history export maps those values into the research columns. See `docs/final-revision-p2-audit-20260624.md`.
