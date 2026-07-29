# Sookta Field-Test Export Data Dictionary

Date stamped: 2026-06-23

This dictionary describes the all-farmer export used for field-test and PhD research data review.

## General Fields

| Field | Meaning | Source |
| --- | --- | --- |
| `Export Generated At` | Timestamp when the export file is created | App device clock |
| `Record ID` / `transaction_id` | One saved assessment transaction | App history record id |
| `Farmer ID` / `user_id` | Research participant id | Farmer profile |
| `Name` / `ชื่อผู้ใช้` | Participant display name | Farmer profile |
| `Role` / `บทบาท/หน้าที่` | Farmer or staff role | Farmer profile |
| `Work Space` / `พื้นที่ทำงาน` | Optional work space/plot note | Farmer profile or later CSV edit |
| `Age` | Age in years | Farmer profile |
| `Gender` | Sex/gender value entered in profile | Farmer profile |
| `Weight (kg)` | Body weight | Farmer profile |
| `Height (cm)` | Height | Farmer profile |
| `BMI` | Body mass index | Profile-derived value |
| `BMI Category` | BMI category label | Profile-derived value |
| `assessment_date` | Date of the transaction | App history timestamp |
| `assessment_time` | Time of the transaction | App history timestamp |

## Activity And Input Fields

| Field | Meaning | Source |
| --- | --- | --- |
| `Activity Stage` | Land preparation, planting, maintenance, harvesting, or transport | Activity definition |
| `Specific Task` | Selected task name shown in the app | Activity selection |
| `task_type` | Internal activity id | Activity enum |
| `Posture Description` | Summary of REBA/ISO input dimensions | Assessment breakdown |
| `Tool Used` | Selected tool/load item | Evaluation form |
| `Tool Weight (kg)` | Locked tool weight from selected tool | Tool option |
| `Tool Weight Code` | Weight band code used in research schema | Tool option |
| `Manual Handling Weight (kg)` / `load_before` | Weight/load used for ISO lifting when relevant | Evaluation detail input |
| `Manual Handling Distance (m)` | Carrying/transport distance when relevant | Evaluation detail input |
| `Frequency per hour` / `frequency_before` | Frequency converted to per-hour basis | Evaluation detail input |
| `Duration (minutes)` / `duration_before` | Duration converted to minutes | Evaluation detail input |
| `Work days per week` | Work days per week for repeated work dimensions | Evaluation detail input |

## Risk Fields

| Field | Meaning | Source |
| --- | --- | --- |
| `REBA Score` / `REBA_before` | REBA posture score before selected advice | REBA calculation |
| `REBA_risk_before` | Risk level from before-improvement REBA score | REBA calculation |
| `ISO 11228 Risk Level` / `ISO_risk_before` | ISO risk level when ISO is applicable | ISO 11228 calculation |
| `ISO_before` | ISO user-facing score/index when ISO is applicable | ISO 11228 calculation |
| `Before Score` | Overall before-improvement score shown to user | Combined assessment result |
| `Before Risk` | Overall before-improvement risk level | Combined assessment result |
| `After Score` / `REBA_after` | Score after selected recommendations | Recommendation simulation |
| `After Risk` / `REBA_risk_after` | After-improvement risk level | Recommendation simulation |
| `ISO_after` / `ISO_risk_after` | ISO values recorded for the same transaction when available | Assessment breakdown |
| `REBA_reduction` | `Before Score - After Score` | Export calculation |
| `REBA_reduction_percent` | `REBA_reduction / Before Score` | Export calculation |

## Seven-Transaction Trend Fields

Trend fields are calculated from the latest 7 transactions for the same farmer and use before-improvement actual-risk scores.

| Field | Meaning |
| --- | --- |
| `trend_REBA_average` | Average of latest before-improvement scores |
| `trend_REBA_maximum` | Highest before-improvement score in the 7-record window |
| `trend_high_risk_count` | Number of latest records high/very high before improvement |
| `trend_level` | Low/watch/high/very high level derived from `trend_high_risk_count` |
| `trend_direction` | `increasing`, `decreasing`, or `stable` from first-to-last before score |

## Body Region Risk Fields

| Field | Meaning |
| --- | --- |
| `MSD Symptom Location` | Body parts marked as risky in the app |
| `MSD Symptom Severity` | Highest body-part risk level |
| `neck_risk` | Neck risk level |
| `shoulder_risk` | Shoulder/arm risk level inferred from arm risk |
| `upper_limb_risk` | Highest risk from arm and wrist regions |
| `wrist_risk` | Wrist risk level |
| `back_risk` | Trunk/back risk level |
| `knee_risk` | Leg/knee risk level |

## Economic Impact Fields

| Field | Meaning |
| --- | --- |
| `Medical Cost (THB)` | Estimated treatment/medical cost component |
| `Lost Workdays` | Estimated lost workdays from highest risk |
| `Productivity Loss (THB)` | Estimated lost/reduced income component |
| `Before Impact (THB)` | Estimated before-improvement impact |
| `After Impact (THB)` | Estimated after-improvement impact |
| `Estimated Saved (THB)` | Before impact minus after impact |
| `Economic Impact Formula` | Formula note used for the estimate |

## Photo And Evidence Fields

| Field | Meaning |
| --- | --- |
| `photo_id` | App-generated pose evidence id when pose frames are stored |
| `photo_timestamp` | Timestamp linked to the pose evidence |

## Research Follow-Up Placeholder Fields

These fields are stored on each transaction when available and exported for field-test analysis. If the app record does not yet contain the value, the export leaves the cell blank so research staff can fill it in Excel/CSV.

| Field | Meaning |
| --- | --- |
| `time_on_task_seconds` | Time spent by the user to complete the task |
| `completion_status` | Completed, partial, failed, or skipped |
| `assistance_required` | Whether staff assistance was needed |
| `error_count` | Number of observed user errors |
| `expert_REBA` | Expert-reviewed REBA score |
| `expert_risk_level` | Expert-reviewed risk level |
| `expert_assessment_date` | Date of expert review |
| `expert_comments` | Expert reviewer notes |

## Important Disclaimer

The assessment output is for risk communication, learning, and research data collection only. It is not a medical diagnosis and does not confirm injury or treatment need. If a farmer has severe, unusual, or persistent pain, they should consult medical personnel or occupational-health specialists.
