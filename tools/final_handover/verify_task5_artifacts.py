#!/usr/bin/env python3
"""Independent fail-closed verifier for Task 5 handover artifacts."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path

from openpyxl import load_workbook
from pypdf import PdfReader

from build_task5_ai_data import (
    ALGORITHM_WORKBOOK_SHEETS, ALLOWED_STATUSES, COMMIT,
    DATA_WORKBOOK_SHEETS, VERSION,
)

EXPECTED_EXPORT_HEADERS = [
    "Export Generated At","export_schema_version","assessment_reference_sources","assessment_scope_note","calculation_standard_note",
    "Record ID","App Version","Farmer ID","Name","Role","Work Space","Age","Gender","Weight (kg)","Height (cm)","BMI","BMI Category",
    "Date of data entry","Activity Stage","Specific Task","Posture Description","REBA Score","ISO 11228 Risk Level","Tool Used","Tool Weight (kg)",
    "Tool Weight Code","Manual Handling Weight (kg)","Manual Handling Distance (m)","Frequency per hour","Duration (minutes)","Work days per week",
    "MSD Symptom Location","MSD Symptom Severity","Medical Cost (THB)","Lost Workdays","Productivity Loss (THB)","Before Score","After Score",
    "Before Risk","After Risk","Before Impact (THB)","After Impact (THB)","Estimated Saved (THB)","Economic Impact Formula","User Feedback Notes",
    "transaction_id","user_id","assessment_date","assessment_time","task_type","REBA_before","REBA_risk_before","ISO_before","ISO_risk_before",
    "load_before","frequency_before","duration_before","REBA_after","REBA_risk_after","ISO_after","ISO_risk_after","REBA_reduction",
    "REBA_reduction_percent","trend_REBA_average","trend_REBA_maximum","trend_high_risk_count","trend_level","trend_direction","neck_risk",
    "shoulder_risk","upper_limb_risk","wrist_risk","back_risk","knee_risk","photo_id","photo_timestamp","time_on_task_seconds","completion_status",
    "assistance_required","error_count","expert_REBA","expert_risk_level","expert_assessment_date","expert_comments",
]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def archive_text(path: Path) -> str:
    if path.suffix.lower() not in {".docx", ".xlsx"}:
        return path.read_text(encoding="utf-8", errors="ignore")
    with zipfile.ZipFile(path) as archive:
        return "\n".join(
            archive.read(name).decode("utf-8", errors="ignore")
            for name in archive.namelist()
            if name.endswith((".xml", ".rels"))
        )


def doc_text(path: Path) -> str:
    from docx import Document
    document = Document(path)
    return "\n".join(p.text for p in document.paragraphs) + "\n" + "\n".join(
        " | ".join(cell.text for cell in row.cells)
        for table in document.tables for row in table.rows
    )


def verify_status_values(values) -> list[str]:
    normalized = [str(value).strip() for value in values if value is not None and str(value).strip()]
    assert normalized and all(value in ALLOWED_STATUSES for value in normalized), normalized
    return normalized


def assert_claim_boundaries(text: str) -> None:
    sentences = re.split(r"(?<=[.!?])\s+|\n+", text.lower())
    forbidden = [
        "clinically validated", "clinical validation completed", "externally validated",
        "production-ready", "all participants consented", "data was de-identified",
        "ethical approval obtained", "researcher accepted",
    ]
    for sentence in sentences:
        # A prohibited-claim register must be able to name the claim it bans.
        negated = any(marker in sentence for marker in (
            "do not state", "do not claim", "no clinical validation",
            "not clinically validated", "not externally validated",
            "is not claimed", "are not claimed", "not proven",
        ))
        if negated:
            continue
        for phrase in forbidden:
            assert phrase not in sentence, phrase


def assert_synthetic_examples(values: list[str]) -> None:
    joined = "\n".join(values)
    forbidden = ["FSK-944631", "ddd"]
    assert not any(token in joined for token in forbidden), joined


def _independent_field_privacy(owner: str, field: str) -> str:
    """Classify an owned serializer field by its exact source role."""
    history_participant_snapshot = {
        "farmerProfileId", "farmerId", "farmerName", "farmerRole", "farmerLocation",
        "farmerAge", "farmerGender", "farmerWeight", "farmerHeight", "farmerBmi",
        "farmerBmiCategory", "photoId", "photoTimestamp",
    }
    history_technical_metadata = {"id", "dateTime", "appVersion", "aiModelSource"}
    history_financial = {"economicLoss", "moneySaved"}
    draft_participant_linkage = {"farmerProfileId", "farmerId", "farmerName", "selectedImagePaths"}
    draft_timestamp_metadata = {"appVersion", "assessmentDateKey", "savedAt"}
    if owner == "UserProfile":
        return "Sensitive financial data" if field == "incomePerYear" else "Sensitive participant/profile data"
    if owner == "EvaluationHistoryRecord":
        if field in history_participant_snapshot: return "Sensitive participant/profile data"
        if field in history_technical_metadata: return "Operational metadata"
        if field in history_financial: return "Sensitive financial data"
        return "Sensitive assessment/research data"
    if owner == "EvaluationDraft":
        if field in draft_participant_linkage: return "Sensitive participant/profile data"
        if field in draft_timestamp_metadata: return "Operational metadata"
        return "Sensitive assessment/research data"
    if owner in {"ErgoInputData", "RebaInputData"}:
        return "Sensitive financial data" if field == "dailyIncome" else "Sensitive assessment/research data"
    if owner == "ErgoResult":
        return "Sensitive financial data" if field == "economicLoss" else "Sensitive assessment/research data"
    if owner in {"AssessmentBreakdown", "MotionAnalysisSummary", "PoseRebaFrameAnalysis"}:
        return "Sensitive assessment/research data"
    raise AssertionError(f"Unclassified source-owned privacy field: {owner}.{field}")


def _independent_persisted_semantics(owner: str, field: str, dart_type: str) -> dict[str, str]:
    key = field.lower(); base = dart_type.rstrip("?")
    if key.endswith("ms"): unit = "milliseconds"
    elif key.endswith("seconds"): unit = "seconds"
    elif key.endswith("hours"): unit = "hours"
    elif key.endswith("minutes"): unit = "minutes"
    elif key.endswith("daysperweek"): unit = "days/week"
    elif "frequency" in key: unit = "events/hour"
    elif key.endswith("fps"): unit = "frames/second"
    elif key.endswith("deg"): unit = "degrees"
    elif "probability" in key: unit = "probability 0..1"
    elif key.endswith("ratio"): unit = "ratio 0..1"
    elif "weight" in key: unit = "kg"
    elif "distance" in key: unit = "m or source-labeled distance"
    elif "income" in key: unit = "THB/day or source profile period"
    elif any(token in key for token in ("economic", "money", "cost", "loss")): unit = "THB"
    elif "score" in key or key in {"techscore", "limitvalue"}: unit = "score/ratio"
    else: unit = "N/A"
    if base == "bool": allowed = "true or false"
    elif base == "int": allowed = ">= 0; source constructor/fromJson fallback applies"
    elif base == "double": allowed = "0..1" if key.endswith("ratio") or "probability" in key else ">= 0 unless source calculation permits signed value"
    elif base == "DateTime": allowed = "ISO-8601 text in persisted JSON"
    elif base.startswith("List<"): allowed = f"JSON array matching {base}"
    elif base.startswith("Map<"): allowed = f"JSON object matching {base} enum-name mapping"
    elif base in {"RiskLevel", "AiAlertLevel", "SooktaActivity", "JobType", "AssessmentMethod", "MotionPattern"}: allowed = f"{base}.name enum text"
    elif base in {"AssessmentBreakdown", "RebaInputData", "ErgoInputData", "ErgoResult", "MotionAnalysisSummary"}: allowed = f"Nested {base} JSON object"
    else: allowed = "Text/identifier accepted by the owning constructor/fromJson"
    privacy = _independent_field_privacy(owner, field)
    overrides = {
        ("ErgoInputData", "liftFrequency"):("lifts/minute", ">= 0 lifts/minute"),
        ("EvaluationDraft", "frequency"):("lifts/minute", ">= 0 lifts/minute"),
        ("ErgoInputData", "horizontalDist"):("cm", ">= 0 cm"),
        ("ErgoInputData", "verticalHeight"):("cm", ">= 0 cm"),
        ("EvaluationDraft", "horizontalDistanceText"):("cm", "Numeric text in cm"),
        ("EvaluationDraft", "verticalHeightText"):("cm", "Numeric text in cm"),
        ("ErgoInputData", "initialForce"):("N", ">= 0 N"), ("ErgoInputData", "sustainForce"):("N", ">= 0 N"),
        ("EvaluationDraft", "initialForce"):("N", ">= 0 N"), ("EvaluationDraft", "sustainForce"):("N", ">= 0 N"),
        ("ErgoResult", "limitValue"):("kg, N, or encoded REBA limit (context-dependent)", ">= 0; interpret only with the calculation method/job type"),
        ("UserProfile", "incomePerYear"):("THB/year", "Numeric text >= 0 THB/year or blank"),
        ("UserProfile", "age"):("years", "Numeric text >= 0 years or blank"),
        ("UserProfile", "height"):("cm", "Numeric text > 0 cm or blank"),
        ("UserProfile", "weight"):("kg", "Numeric text > 0 kg or blank"),
        ("EvaluationHistoryRecord", "farmerAge"):("years", "Numeric text >= 0 years or blank"),
        ("EvaluationHistoryRecord", "farmerHeight"):("cm", "Numeric text > 0 cm or blank"),
        ("EvaluationHistoryRecord", "farmerWeight"):("kg", "Numeric text > 0 kg or blank"),
        ("EvaluationHistoryRecord", "farmerBmi"):("kg/m2", "> 0 kg/m2 when present"),
        ("EvaluationHistoryRecord", "aiRiskPercent"):("%", "Integer 0..100 when present"),
        ("EvaluationHistoryRecord", "expertReba"):("REBA score points", ">= 0 when present"),
        ("ErgoInputData", "dailyIncome"):("THB/day", ">= 0 THB/day"), ("RebaInputData", "dailyIncome"):("THB/day", ">= 0 THB/day"),
        ("EvaluationDraft", "durationHours"):("hours", "> 0 hours in the evaluation flow"), ("ErgoInputData", "durationHours"):("hours", "> 0 hours in the evaluation flow"),
        ("EvaluationDraft", "workDaysPerWeek"):("days/week", "> 0 days/week in the evaluation flow"), ("ErgoInputData", "workDaysPerWeek"):("days/week", "> 0 days/week in the evaluation flow"),
        ("EvaluationDraft", "pushPullDistance"):("m", ">= 0 m"), ("EvaluationDraft", "transportDistanceText"):("m", "Numeric text in m"),
        ("ErgoInputData", "transportDistance"):("m", ">= 0 m"), ("ErgoInputData", "toolWeightBandCode"):("category code", "Non-negative integer category code"),
        ("ErgoResult", "userScoreColor"):("ARGB integer", "32-bit ARGB color value"),
    }
    if owner in {"MotionAnalysisSummary", "PoseRebaFrameAnalysis"} and key.endswith("deg"): allowed = "Finite angle in degrees when present"
    if owner == "MotionAnalysisSummary" and field.endswith("FrameCount"): unit, allowed = "frames", ">= 0 integer frames"
    if (owner, field) in overrides: unit, allowed = overrides[(owner, field)]
    return {"type":dart_type, "nullable":"Yes" if dart_type.endswith("?") else "No", "unit":unit, "allowed":allowed, "privacy":privacy}


def _independent_owner_location(owner: str, field: str) -> str:
    if owner == "EvaluationHistoryRecord": return f"SharedPreferences sookta.history[] -> {owner}.{field}"
    if owner == "EvaluationDraft": return f"SharedPreferences sookta.evaluationDrafts[] / legacy draft -> {owner}.{field}"
    if owner == "UserProfile": return f"SharedPreferences sookta.farmers[] / sookta.profile -> {owner}.{field}"
    if owner == "ErgoResult": return f"Nested AssessmentBreakdown rebaResult/isoResult -> {owner}.{field}"
    if owner == "AssessmentBreakdown": return f"SharedPreferences sookta.history[] -> EvaluationHistoryRecord.assessmentBreakdown/afterAssessmentBreakdown -> {owner}.{field}"
    if owner == "RebaInputData": return f"Nested EvaluationDraft.rebaInput or AssessmentBreakdown.rebaInput -> {owner}.{field}"
    if owner == "ErgoInputData": return f"Nested EvaluationDraft.ergoInput or AssessmentBreakdown.ergoInput -> {owner}.{field}"
    if owner == "PoseRebaFrameAnalysis": return f"Nested AssessmentBreakdown.poseFrames[] -> {owner}.{field}"
    if owner == "MotionAnalysisSummary": return f"Nested AssessmentBreakdown.motionSummary -> {owner}.{field}"
    return f"Nested persisted model -> {owner}.{field}"


def _independent_export_contracts(headers: list[str]) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    operational = "Operational metadata"; participant = "Sensitive participant/profile data"
    assessment = "Sensitive assessment/research data"; financial = "Sensitive financial/impact data"
    def add(fields, dtype, nullable, allowed, unit, missing, privacy):
        for field in fields: result[field] = {"type":dtype,"nullable":nullable,"allowed":allowed,"unit":unit,"missing":missing,"privacy":privacy}
    add(["Export Generated At"],"ISO-8601 date-time text","No","DateTime.now().toIso8601String() including device offset when available","N/A","Never blank",operational)
    add(["export_schema_version"],"text","No","Non-empty source-controlled export schema version","N/A","Never blank",operational)
    add(["assessment_reference_sources","assessment_scope_note","calculation_standard_note"],"text","No","Source-controlled reference/scope text","N/A","Never blank",operational)
    add(["Record ID","transaction_id"],"integer","No",">= 0 history record identifier","identifier","Never blank; direct record.id",participant)
    add(["App Version"],"text","Yes","Application version text or '-'","N/A","'-' when record.appVersion is null",operational)
    add(["Farmer ID","user_id"],"text","No","Resolved farmer/profile identifier; final fallback record-<id>","identifier","Never blank because _resolvedFarmerId supplies record-<id>",participant)
    add(["Name","Role","Work Space"],"text","Yes","Profile text, record fallback, or '-'","N/A","'-' when both profile and record value are empty/unavailable",participant)
    add(["Age"],"numeric text","Yes","Numeric age text or '-'","years","'-' when both profile and record value are empty/unavailable",participant)
    add(["Gender"],"text","Yes","Source profile/record gender text or '-'","N/A","'-' when both profile and record value are empty/unavailable",participant)
    add(["Weight (kg)"],"numeric text","Yes","Numeric weight text or '-'","kg","'-' when both profile and record value are empty/unavailable",participant)
    add(["Height (cm)"],"numeric text","Yes","Numeric height text or '-'","cm","'-' when both profile and record value are empty/unavailable",participant)
    add(["BMI"],"decimal-number text","Yes","> 0 formatted to one decimal place, or '-'","kg/m2","'-' when BMI cannot be derived",participant)
    add(["BMI Category"],"text","Yes","Underweight; Normal weight; Above Asian BMI range; localized Thai values; '-' when unavailable","N/A","'-' when BMI category cannot be derived",participant)
    add(["Date of data entry","assessment_date"],"YYYY-MM-DD text","No","Calendar date formatted YYYY-MM-DD","N/A","Never blank; record.dateTime is required",assessment)
    add(["assessment_time"],"HH:mm:ss text","No","00:00:00..23:59:59 local device time","N/A","Never blank; record.dateTime is required",assessment)
    add(["Activity Stage"],"text","Yes","English activity stage label or '-'","N/A","'-' when record.activity is null",assessment)
    add(["Specific Task","task_type"],"text","No","Source activity name/text; task_type prefers enum name","N/A","Non-null source string; may be empty only if source activityName is empty",assessment)
    add(["Posture Description"],"text","Yes","Method and REBA component-score description or '-'","N/A","'-' when assessmentBreakdown is null",assessment)
    add(["REBA Score"],"integer","Yes","REBA user score 1..15 or '-'","REBA score points","'-' when assessmentBreakdown is null",assessment)
    add(["ISO 11228 Risk Level","ISO_risk_before","ISO_risk_after"],"text","Yes","Low; Medium; High; Very high; localized Thai values; or '-'","risk tier","'-' when applicable ISO result is absent",assessment)
    add(["Tool Used"],"text","Yes","Localized tool label or '-'","N/A","'-' when ergoInput is absent or tool labels are empty",assessment)
    add(["Tool Weight (kg)"],"number","Yes",">= 0; tool weight with load-weight fallback","kg","'-' when ergoInput is absent",assessment)
    add(["Tool Weight Code"],"integer","Yes","Positive encoded tool-weight band","category code","'-' when code is zero or ergoInput is absent",assessment)
    add(["Manual Handling Weight (kg)","load_before"],"number","Yes",">= 0 handled load","kg","'-' when ergoInput is absent",assessment)
    add(["Manual Handling Distance (m)"],"number","Yes",">= 0 transport distance","m","'-' when ergoInput is absent",assessment)
    add(["Frequency per hour","frequency_before"],"number","Yes",">= 0; ErgoInputData.liftFrequency multiplied by 60 and formatted by _num","lifts/hour","'-' when ergoInput is absent",assessment)
    add(["Duration (minutes)","duration_before"],"number","Yes",">= 0; durationHours multiplied by 60 and formatted by _num","minutes","'-' when ergoInput is absent",assessment)
    add(["Work days per week"],"number","Yes","> 0 in evaluation flow; formatted by _num","days/week","'-' when ergoInput is absent",assessment)
    add(["MSD Symptom Location"],"text","Yes","Comma-separated non-low-risk body parts or '-'","N/A","'-' when no body part exceeds low risk",assessment)
    add(["MSD Symptom Severity","Before Risk","After Risk","REBA_risk_before","REBA_risk_after","trend_level","neck_risk","shoulder_risk","upper_limb_risk","wrist_risk","back_risk","knee_risk"],"text","No","Low; Medium; High; Very high; localized Thai values","risk tier","Never blank; source supplies a risk or low-risk fallback",assessment)
    add(["Medical Cost (THB)","Productivity Loss (THB)","Before Impact (THB)","After Impact (THB)","Estimated Saved (THB)"],"integer","No",">= 0 source economic-impact amount","THB","Never blank; source calculation returns an integer",financial)
    add(["Lost Workdays"],"integer","No",">= 0 estimated lost workdays","days","Never blank; source calculation returns an integer",financial)
    add(["Before Score","After Score","REBA_before"],"integer","No","Source user score; REBA path is 1..15","score points","Never blank; required record score or deterministic fallback",assessment)
    add(["Economic Impact Formula"],"text","No","Human-readable formula including effective score reduction","N/A","Never blank",financial)
    add(["User Feedback Notes"],"text","Yes","Selected suggestions joined with ' | ' or '-'","N/A","'-' when selectedSuggestions is empty",assessment)
    add(["ISO_before","ISO_after"],"integer","Yes","ISO user score when applicable or '-'","score points","'-' when applicable ISO result is absent",assessment)
    add(["REBA_after"],"integer","Yes","REBA user score 1..15 or '-'","REBA score points","'-' when afterAssessmentBreakdown is absent",assessment)
    add(["REBA_reduction"],"integer","Yes","Signed before-minus-after REBA score difference","score points","'-' when before or after REBA result is absent",assessment)
    add(["REBA_reduction_percent"],"percentage text","Yes","Rounded integer percent text, including sign when reduction is negative","%","'-' when before score <= 0 or either score is absent",assessment)
    add(["trend_REBA_average"],"number","No",">= 0 average before score formatted by _num","score points","Never blank; trend window contains the current record",assessment)
    add(["trend_REBA_maximum"],"integer","No",">= 0 maximum before score","score points","Never blank; trend window contains the current record",assessment)
    add(["trend_high_risk_count"],"integer","No",">= 0 count of high/very-high records","records","Never blank",assessment)
    add(["trend_direction"],"text","No","increasing; decreasing; stable","N/A","Never blank",assessment)
    add(["photo_id"],"text","Yes","Persisted photo ID, derived pose-frame ID, or '-'","identifier","'-' when no persisted ID or pose frame is available",participant)
    add(["photo_timestamp"],"ISO-8601 date-time text","Yes","ISO-8601 timestamp or '-'","N/A","'-' when neither persisted nor derived photo timestamp is available",participant)
    add(["time_on_task_seconds"],"integer","Yes",">= 0 elapsed time-on-task seconds","seconds","Blank string when record.timeOnTaskSeconds is null",assessment)
    add(["completion_status"],"text","Yes","Research workflow completion-status text","N/A","Blank string when record.completionStatus is null",assessment)
    add(["assistance_required"],"boolean text","Yes","true; false","N/A","Blank string when record.assistanceRequired is null",assessment)
    add(["error_count"],"integer","Yes",">= 0 workflow error count","errors","Blank string when record.errorCount is null",assessment)
    add(["expert_REBA"],"number","Yes","Expert comparator REBA value formatted by _num","REBA score points","Blank string when record.expertReba is null",assessment)
    add(["expert_risk_level"],"text","Yes","Low; Medium; High; Very high; localized Thai values","risk tier","Blank string when record.expertRiskLevel is null",assessment)
    add(["expert_assessment_date"],"ISO-8601 date-time text","Yes","DateTime.toIso8601String()","N/A","Blank string when record.expertAssessmentDate is null",assessment)
    add(["expert_comments"],"text","Yes","Expert comments text","N/A","Blank string when record.expertComments is null",assessment)
    result["trend_level"]["allowed"] = "Low; Medium; High; Very high (localized when Thai export is selected)"
    assert set(result) == set(headers), (set(headers)-set(result), set(result)-set(headers))
    return result


def extract_authoritative_source_contracts(root: Path) -> dict:
    """Independently derive critical contracts from authoritative source files."""
    dart_fields: dict[tuple[str, str], str] = {}
    serialized_fields: set[tuple[str, str]] = set()
    for relative in ["lib/app/app_state.dart", "lib/core/models/assessment_session.dart", "lib/core/models/evaluation_models.dart"]:
        text = (root / relative).read_text(encoding="utf-8")
        matches = list(re.finditer(r"(?m)^class\s+(\w+)", text))
        for index, match in enumerate(matches):
            owner = match.group(1)
            section = text[match.start():(matches[index + 1].start() if index + 1 < len(matches) else len(text))]
            for dart_type, field in re.findall(r"(?m)^\s*final\s+([^;=]+?)\s+(\w+)\s*;", section):
                dart_fields[(owner, field)] = dart_type.strip()
            declared = {field for (declared_owner, field) in dart_fields if declared_owner == owner}
            for field in set(re.findall(r"(?m)^\s*['\"](\w+)['\"]\s*:", section)) & declared:
                serialized_fields.add((owner, field))
        # AssessmentBreakdown serializes nested ErgoResult values through a typed helper.
        for helper in re.finditer(r"_resultToJson\s*\(\s*ErgoResult\s+\w+\s*\)([\s\S]*?)(?=\n\s*(?:static\s+)?(?:Map|factory|class)\b)", text):
            declared = {field for (declared_owner, field) in dart_fields if declared_owner == "ErgoResult"}
            for field in set(re.findall(r"['\"](\w+)['\"]\s*:", helper.group(1))) & declared:
                serialized_fields.add(("ErgoResult", field))
    app_state_text = (root / "lib/app/app_state.dart").read_text(encoding="utf-8")
    export_text = (root / "lib/core/services/assessment_export_service.dart").read_text(encoding="utf-8")
    assert "highRiskCount >= 6" in export_text and "RiskLevel.veryHigh" in export_text
    trend_levels = ["Low", "Medium", "High", "Very high"]
    telemetry_text = (root / "lib/core/services/firebase_telemetry_service.dart").read_text(encoding="utf-8")
    callsite_text = (root / "lib/screens/main/evaluation_form_screen.dart").read_text(encoding="utf-8")
    telemetry_events: dict[str, list[str]] = {}
    for event, expected in {
        "app_start":["platform","build_mode"], "assessment_image_added":["source","image_count"],
        "assessment_calculated":["activity","job_type","primary_method","risk_level","score","image_count","uses_iso11228"],
        "assessment_saved":["activity","before_risk","after_risk","before_score","after_score","suggestion_count"],
        "export_created":["export_type","record_count"],
    }.items():
        block = re.search(rf"logEvent\(\s*['\"]{event}['\"]\s*,\s*\{{([\s\S]*?)\}}\s*\)", telemetry_text)
        assert block, event
        actual = re.findall(r"(?m)^\s*['\"](\w+)['\"]\s*:", block.group(1))
        assert actual == expected, (event, actual)
        telemetry_events[event] = actual
    generic = re.search(r"logEvent\(\s*['\"]pose_analysis_failed['\"]\s*,\s*\{([\s\S]*?)\}\s*\)", callsite_text)
    assert generic
    telemetry_events["pose_analysis_failed"] = re.findall(r"(?m)^\s*['\"](\w+)['\"]\s*:", generic.group(1))
    assert telemetry_events["pose_analysis_failed"] == ["platform", "error_code"]
    assert "logAppOpen()" in telemetry_text and "FirebaseAnalyticsObserver(" in telemetry_text
    wrapper_methods = {
        "assessment_image_added": "logImageAdded", "assessment_calculated": "logAssessmentCalculated",
        "assessment_saved": "logAssessmentSaved", "export_created": "logExportCreated",
    }
    telemetry_call_sites = {"app_start": ["lib/core/services/firebase_telemetry_service.dart"]}
    dart_sources = list((root / "lib").rglob("*.dart"))
    for event, method in wrapper_methods.items():
        telemetry_call_sites[event] = sorted(
            path.relative_to(root).as_posix() for path in dart_sources
            if path.name != "firebase_telemetry_service.dart" and f"FirebaseTelemetryService.{method}(" in path.read_text(encoding="utf-8")
        )
        assert telemetry_call_sites[event], event
    generic_path = "lib/screens/main/evaluation_form_screen.dart"
    observer_paths = sorted(
        path.relative_to(root).as_posix() for path in dart_sources
        if path.name != "firebase_telemetry_service.dart" and "FirebaseTelemetryService.navigatorObservers" in path.read_text(encoding="utf-8")
    )
    assert observer_paths
    train_text = (root / "tools/research_dataset/train_xgboost_onnx_model.py").read_text(encoding="utf-8")
    test_size = float(re.search(r"--test-size[\s\S]{0,160}?default=([0-9.]+)", train_text).group(1))
    random_seed = int(re.search(r"--random-state[\s\S]{0,160}?default=(\d+)", train_text).group(1))
    xgb = {"test_size":test_size,"random_seed":random_seed,"split_method":"GroupShuffleSplit"}
    for key, expected in {"n_estimators":"96","max_depth":"3","learning_rate":"0.055","subsample":"0.88","colsample_bytree":"0.86","reg_lambda":"1.4","reg_alpha":"0.02","min_child_weight":"2","n_jobs":"1","tree_method":"\"hist\""}.items():
        assert re.search(rf"{key}\s*=\s*{re.escape(expected)}", train_text), key
    # Bind the export contract to source order and source conversions. These
    # checks do not import or call the artifact builder's schema helpers.
    header_block = export_text[
        export_text.index("static String buildAllHistoryCsv"):
        export_text.index("for (final record in records)")
    ]
    cursor = 0
    for header in EXPECTED_EXPORT_HEADERS:
        cursor = header_block.index(f"'{header}'", cursor) + len(header) + 2
    for token in [
        "ergoInput.liftFrequency * 60", "_timeOnly(record.dateTime)",
        "record.timeOnTaskSeconds ?? ''", "_bmiCategory(profile, record, thai)",
    ]:
        assert token in export_text, token

    persisted_contracts = {}
    for owner, field in serialized_fields:
        dart_type = dart_fields[(owner, field)]
        persisted_contracts[(owner, field)] = {
            **_independent_persisted_semantics(owner, field, dart_type),
            "persisted_location": _independent_owner_location(owner, field),
        }
    preference_types = {
        "sookta.activeProfileId":"String", "sookta.dataSchemaVersion":"int",
        "sookta.evaluationDraft":"EvaluationDraft", "sookta.evaluationDrafts":"List<EvaluationDraft>",
        "sookta.farmers":"List<FarmerProfile>", "sookta.history":"List<EvaluationHistoryRecord>",
        "sookta.language":"String", "sookta.latestBackup":"String", "sookta.nextHistoryId":"int",
        "sookta.profile":"FarmerProfile", "sookta.setupCompleted":"bool",
        "sookta.backup.schema.<version>.<timestamp>":"JSON object",
    }
    # Derive container sensitivity from the payloads that source actually
    # serializes, not from preference-key spelling.
    draft_fields = {field for owner, field in serialized_fields if owner == "EvaluationDraft"}
    history_fields = {field for owner, field in serialized_fields if owner == "EvaluationHistoryRecord"}
    assert {"farmerProfileId", "farmerId", "farmerName", "selectedImagePaths", "rebaInput", "savedAt"}.issubset(draft_fields)
    assert {"farmerProfileId", "farmerName", "farmerRole", "farmerLocation", "economicLoss", "assessmentBreakdown"}.issubset(history_fields)
    assert "'savedAt': savedAt?.toIso8601String()" in (root / "lib/core/models/assessment_session.dart").read_text(encoding="utf-8")
    backup_block = app_state_text[
        app_state_text.index("Future<void> _backupBeforeSchemaMigration"):
        app_state_text.index("EvaluationDraft _withActiveDraftMetadata")
    ]
    for symbol in ["_profileKey", "_farmersKey", "_activeProfileIdKey", "_historyKey", "_evaluationDraftKey", "_evaluationDraftsKey"]:
        assert f"{symbol}:" in backup_block, symbol
    composite = "Sensitive composite participant/profile + assessment/research + financial data"
    preference_privacy = {
        "sookta.activeProfileId":"Sensitive participant/profile data",
        "sookta.dataSchemaVersion":"Operational metadata",
        "sookta.evaluationDraft":composite,
        "sookta.evaluationDrafts":composite,
        "sookta.farmers":"Sensitive participant/profile data",
        "sookta.history":composite,
        "sookta.language":"Operational metadata",
        "sookta.latestBackup":"Operational metadata",
        "sookta.nextHistoryId":"Operational metadata",
        "sookta.profile":"Sensitive participant/profile data",
        "sookta.setupCompleted":"Operational metadata",
        "sookta.backup.schema.<version>.<timestamp>":composite,
    }
    assert set(preference_privacy) == set(preference_types)
    preference_contracts = {}
    for key, dtype in preference_types.items():
        preference_contracts[key] = {
            "type": dtype, "nullable": "No" if dtype in {"bool", "int"} else "Yes",
            "unit": "N/A", "privacy": preference_privacy[key],
            "persisted_location": f"SharedPreferences: {key}",
        }
    return {
        "dart_fields":dart_fields, "serialized_fields":serialized_fields,
        "persisted_contracts":persisted_contracts,
        "preference_contracts":preference_contracts,
        "export_contracts":_independent_export_contracts(EXPECTED_EXPORT_HEADERS),
        "trend_levels":trend_levels, "telemetry_events":telemetry_events,
        "telemetry_call_sites":telemetry_call_sites,
        "generic_call_site_paths":{"pose_analysis_failed":generic_path},
        "log_app_open":True, "analytics_observer":True,
        "analytics_observer_call_sites":observer_paths, "xgb":xgb,
    }


def verify_visual_manifest(staging: Path, manifest_path: Path, expected: dict[str, list[str]]) -> None:
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    assert payload["status"] == "passed"
    rows = {row["path"]: row for row in payload["artifacts"]}
    assert set(rows) == set(expected)
    for artifact_relative, render_relatives in expected.items():
        row = rows[artifact_relative]
        artifact = staging / artifact_relative
        assert row["sha256"] == digest(artifact)
        renders = {render["path"]: render for render in row["renders"]}
        assert set(renders) == set(render_relatives)
        for relative in render_relatives:
            assert renders[relative]["status"] == "passed"
            assert renders[relative]["sha256"] == digest(staging / relative)


def verify_formula_summary(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    assert data["status"] == "passed"
    assert data["formula_error_matches"] == 0
    assert data["formula_contracts"]
    for contract in data["formula_contracts"]:
        assert contract["status"] == "passed"
        assert contract["expected_formula"] == contract["actual_formula"]
        assert contract["expected_value"] == contract["actual_value"]
    return data


def verify_checksums(staging: Path, required: list[Path]) -> int:
    rows: dict[str, str] = {}
    for line in (staging / "manifests/SHA256SUMS.txt").read_text(encoding="ascii").splitlines():
        checksum, relative = line.split("  ", 1); rows[relative] = checksum
    for relative, checksum in rows.items():
        path = staging / relative
        assert path.is_file(), relative
        assert digest(path) == checksum, relative
    for path in required:
        relative = path.relative_to(staging).as_posix()
        assert rows.get(relative) == digest(path), relative
    return len(rows)


def verify_source_contracts(facts: dict, root: Path) -> dict:
    independent = extract_authoritative_source_contracts(root)
    assert len(facts["recommendation_messages"]) == 26
    triggers = facts["recommendation_triggers"]
    assert len(triggers) == 24
    exact = {(r["activity"], r["risk_tier"]):(r["activity_key"], r["weight_key"]) for r in triggers}
    prefixes = {"transplanting":"transplant", "fertilizing":"fert", "pesticide":"pesticide", "pruning":"pruning", "harvesting":"harvest", "transport":"transport"}
    manual = {"transplanting", "fertilizing", "pesticide", "transport"}
    for activity, prefix in prefixes.items():
        for tier in ("low", "medium", "high", "veryHigh"):
            mapped = "high" if tier == "veryHigh" else tier
            assert exact[(activity,tier)] == (f"act_{prefix}_ref_{mapped}", f"act_ref_weight_{mapped}" if activity in manual else "N/A")
    assert facts["daily_runtime_tiers"] == [{"high_risk_count":"0-1","level":"Low"},{"high_risk_count":"2-3","level":"Watch"},{"high_risk_count":"4-5","level":"High"},{"high_risk_count":"6-7","level":"Critical"}]
    assert facts["daily_probability_thresholds"]["used_by_predict_for_records"] is False
    evidence = {r["evidence_id"]:r for r in facts["training_evidence"]}["xgboost_training"]
    assert (evidence["split_method"], evidence["test_size"], evidence["random_seed"]) == ("GroupShuffleSplit", .22, 42)
    assert evidence["xgb_parameters"] == {"objective":"reg:squarederror","n_estimators":96,"max_depth":3,"learning_rate":0.055,"subsample":0.88,"colsample_bytree":0.86,"reg_lambda":1.4,"reg_alpha":0.02,"min_child_weight":2,"random_state":42,"n_jobs":1,"tree_method":"hist"}
    assert evidence["dataset_status"] == "Pending Researcher Evidence"
    assert evidence["raw_metrics_status"] == "Pending Owner Action"
    roles = {r["role_id"]:r for r in facts["model_algorithm_inventory"]}
    assert len(roles) == 10 and roles["movenet_multipose"]["authority"] == "Single-person eligibility gate"
    for role in (roles["legacy_logistic_weights"], roles["deprecated_risk_alert"]): assert re.fullmatch(r"[0-9a-f]{64}", role["binary_sha256"])
    # Fail closed on the full source-derived persisted contract, including
    # duplicate field names owned by different Dart value objects.
    persisted_rows = facts["persisted_schema_rows"]
    record_rows = {(row["owner"], row["field"]):row for row in persisted_rows if row["owner"] != "SharedPreferences"}
    assert len(record_rows) == len(persisted_rows) - len(independent["preference_contracts"])
    assert set(record_rows) == set(independent["persisted_contracts"])
    for identity, expected_contract in independent["persisted_contracts"].items():
        actual = record_rows[identity]
        for column in ["type", "nullable", "unit", "allowed", "privacy", "persisted_location"]:
            assert actual[column] == expected_contract[column], (identity, column, actual[column], expected_contract[column])
        assert actual["description"] and actual["validation"] and actual["derivation"]
    preference_rows = {row["field"]:row for row in persisted_rows if row["owner"] == "SharedPreferences"}
    assert set(preference_rows) == set(independent["preference_contracts"])
    assert set(facts["preference_keys"]) == set(independent["preference_contracts"])
    for key, expected_contract in independent["preference_contracts"].items():
        actual = preference_rows[key]
        for column in ["type", "nullable", "unit", "privacy", "persisted_location"]:
            assert actual[column] == expected_contract[column], (key, column, actual[column], expected_contract[column])

    export_rows = facts["export_schema_rows"]
    assert facts["all_history_csv_headers"] == EXPECTED_EXPORT_HEADERS
    assert [row["field"] for row in export_rows] == EXPECTED_EXPORT_HEADERS
    assert len(export_rows) == len({row["field"] for row in export_rows}) == 84
    for row in export_rows:
        expected_contract = independent["export_contracts"][row["field"]]
        for column in ["type", "nullable", "allowed", "unit", "missing", "privacy"]:
            assert row[column] == expected_contract[column], (row["field"], column, row[column], expected_contract[column])
        assert row["description"] and row["validation"] and row["derivation"]
    telemetry = facts["firebase_telemetry"]
    assert telemetry["default_off"] and telemetry["crashlytics_context"]
    assert telemetry["events"]["assessment_calculated"] == ["activity","job_type","primary_method","risk_level","score","image_count","uses_iso11228"]
    assert telemetry["events"] == independent["telemetry_events"]
    assert telemetry["wrapper_call_sites"] == independent["telemetry_call_sites"]
    assert telemetry["generic_call_site_paths"] == independent["generic_call_site_paths"]
    assert telemetry["analytics_observer_call_sites"] == independent["analytics_observer_call_sites"]
    assert telemetry["log_app_open"] and telemetry["analytics_observer_navigation"]
    assert evidence["split_method"] == independent["xgb"]["split_method"]
    assert evidence["test_size"] == independent["xgb"]["test_size"]
    assert evidence["random_seed"] == independent["xgb"]["random_seed"]
    trend = next(row for row in export_rows if row["field"] == "trend_level")
    assert all(label in trend["allowed"] for label in independent["trend_levels"])
    assert "Critical" not in trend["allowed"] + trend["derivation"]
    return independent


def verify(staging: Path) -> dict:
    artifacts = staging / "artifacts"; manifests = staging / "manifests"
    stems = [
        "04_AI_Algorithm_and_Model_Technical_Report",
        "04_Algorithm_Recommendation_and_Reference_Matrices",
        "04_AI_Training_and_Non_Training_Statement",
        "05_Local_Storage_and_Data_Management_Manual",
        "05_Data_Dictionary_and_Export_Schema",
    ]
    required: list[Path] = []
    for stem in stems:
        editable = artifacts / f"{stem}{'.xlsx' if 'Matrices' in stem or 'Dictionary' in stem else '.docx'}"
        pdf = artifacts / f"{stem}.pdf"
        assert editable.is_file() and editable.stat().st_size > 1000, editable
        assert pdf.is_file() and pdf.stat().st_size > 1000, pdf
        required.extend([editable, pdf])
    ai = doc_text(required[0]); statement = doc_text(required[4]); manual = doc_text(required[6])
    for text in [ai, statement, manual]:
        assert VERSION in text and COMMIT in text
        assert_claim_boundaries(text)
    for token in ["MoveNet Thunder", "XGBoost ONNX", "Template coefficients", "Primary deterministic", "Advisory only", "no clinical validation"]:
        assert token.lower() in ai.lower(), token
    for token in ["Prohibited claims", "Complete - Pending Signature", "Preparer", "Technical reviewer", "Owner", "Researcher"]:
        assert token in statement, token
    for token in ["SharedPreferences", "sookta.latestBackup", "schema version is 2", "N/A with Rationale", "default off", "retention", "deletion"]:
        assert token.lower() in manual.lower(), token
    algorithm = load_workbook(required[2], read_only=True, data_only=False)
    data = load_workbook(required[8], read_only=True, data_only=False)
    assert algorithm.sheetnames == ALGORITHM_WORKBOOK_SHEETS
    assert data.sheetnames == DATA_WORKBOOK_SHEETS
    statuses = []
    for workbook in [algorithm, data]:
        for sheet in workbook.worksheets:
            for row in sheet.iter_rows(values_only=True):
                for value in row:
                    if value in ALLOWED_STATUSES:
                        statuses.append(value)
    verify_status_values(statuses)
    assert {"Complete", "Pending Owner Action", "Pending Researcher Evidence", "N/A with Rationale", "Complete - Pending Signature"}.issubset(set(statuses))
    sheet = data["Export Schema Order"]
    headers = [cell.value for cell in sheet[4]]
    assert headers[0:3] == ["Field / variable", "Description", "Type"]
    rows = list(sheet.iter_rows(min_row=5, values_only=False))
    assert len(rows) == 84
    example_index = headers.index("Synthetic example")
    examples = [str(row[example_index].value) for row in rows if row[example_index].value is not None]
    assert_synthetic_examples(examples)
    timestamp_row = next(row for row in rows if row[0].value == "expert_assessment_date")
    timestamp_cell = timestamp_row[example_index]
    assert timestamp_cell.data_type == "s" and "2026-08-24T09:00:00+07:00" in timestamp_cell.value
    def body_rows(worksheet):
        return list(worksheet.iter_rows(min_row=5, values_only=True))
    assert len(body_rows(algorithm["Recommendation Messages"])) == 26
    assert len(body_rows(algorithm["Recommendation Triggers"])) == 24
    assert len(body_rows(algorithm["Model Algorithm Inventory"])) == 10
    persisted_values = body_rows(data["Persisted Keys Records"])
    assert len(persisted_values) > len({row[0] for row in persisted_values})
    algorithm.close(); data.close()
    summary = verify_formula_summary(manifests / "task5_workbook_build_summary.json")
    expected = json.loads((manifests / "task5_expected_visual_renders.json").read_text(encoding="utf-8"))
    verify_visual_manifest(staging, manifests / "task5_visual_qa_manifest.json", expected)
    counts = json.loads((manifests / "task5_render_counts.json").read_text(encoding="utf-8"))
    assert len(PdfReader(required[1]).pages) == counts["ai_report"]
    assert len(PdfReader(required[5]).pages) == counts["training_statement"]
    assert len(PdfReader(required[7]).pages) == counts["data_manual"]
    assert len(PdfReader(required[3]).pages) == counts["algorithm_pdf"]
    assert len(PdfReader(required[9]).pages) == counts["data_pdf"]
    forbidden_secret = re.compile(r"(?i)(-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|AIza[0-9A-Za-z_-]{20,}|password\s*[:=]\s*\S+|api[_-]?key\s*[:=]\s*\S+)")
    forbidden_identity = re.compile(r"FSK-944631|>ddd<")
    for path in required:
        text = archive_text(path)
        assert not forbidden_secret.search(text), path
        assert not forbidden_identity.search(text), path
    checksum_entries = verify_checksums(staging, required)
    input_data = json.loads((staging / "working/task5/task5_build_input.json").read_text(encoding="utf-8"))
    source_root = Path(input_data["source_root"])
    independent = verify_source_contracts(input_data, source_root)
    # Compare every workbook row against independently reconstructed source
    # contracts. This rejects missing, extra, duplicated, or semantically
    # incorrect rows rather than sampling a few representative fields.
    data_check = load_workbook(required[8], read_only=True, data_only=False)
    persisted_sheet = data_check["Persisted Keys Records"]
    persisted_headers = [cell.value for cell in persisted_sheet[4]]
    pidx = {name:index for index,name in enumerate(persisted_headers)}
    persisted_values = list(persisted_sheet.iter_rows(min_row=5, values_only=True))
    actual_persisted = {
        (row[pidx["Field / variable"]], row[pidx["Persisted location / key"]]): row
        for row in persisted_values
    }
    expected_persisted = {}
    for (owner, field), contract in independent["persisted_contracts"].items():
        expected_persisted[(field, contract["persisted_location"])] = contract
    for field, contract in independent["preference_contracts"].items():
        expected_persisted[(field, contract["persisted_location"])] = contract
    assert len(actual_persisted) == len(persisted_values) == len(expected_persisted) == 190
    assert set(actual_persisted) == set(expected_persisted)
    for identity, contract in expected_persisted.items():
        row = actual_persisted[identity]
        for column in ["Type", "Nullable", "Unit", "Privacy class"]:
            key = {"Type":"type", "Nullable":"nullable", "Unit":"unit", "Privacy class":"privacy"}[column]
            assert row[pidx[column]] == contract[key], (identity, column, row[pidx[column]], contract[key])
        if "allowed" in contract:
            assert row[pidx["Allowed values / range"]] == contract["allowed"], identity
        for column in ["Description", "Derivation / formula", "Validation / fallback"]:
            assert str(row[pidx[column]] or "").strip(), (identity, column)

    export_sheet = data_check["Export Schema Order"]
    export_headers = [cell.value for cell in export_sheet[4]]
    eidx = {name:index for index,name in enumerate(export_headers)}
    export_values = list(export_sheet.iter_rows(min_row=5, values_only=True))
    assert [row[eidx["Field / variable"]] for row in export_values] == EXPECTED_EXPORT_HEADERS
    assert len(export_values) == len({row[eidx["Field / variable"]] for row in export_values}) == 84
    for row in export_values:
        field = row[eidx["Field / variable"]]
        contract = independent["export_contracts"][field]
        for column, key in [("Type","type"),("Nullable","nullable"),("Allowed values / range","allowed"),("Unit","unit"),("Missing code","missing"),("Privacy class","privacy")]:
            assert row[eidx[column]] == contract[key], (field, column, row[eidx[column]], contract[key])
        for column in ["Description", "Derivation / formula", "Validation / fallback"]:
            assert str(row[eidx[column]] or "").strip(), (field, column)

    privacy_text = "\n".join(str(value) for row in data_check["Privacy Retention"].iter_rows(values_only=True) for value in row if value is not None)
    report_text = "\n".join([ai, manual])
    telemetry_tokens = ["logAppOpen", "FirebaseAnalyticsObserver", "SDK-generated", "Crashlytics"]
    for event, fields in independent["telemetry_events"].items():
        telemetry_tokens.extend([event, *fields])
    for token in telemetry_tokens:
        assert token in privacy_text, ("Privacy Retention", token)
        if token == "SDK-generated":
            assert token in report_text or "SDK-defined" in report_text, ("reports", token)
        else:
            assert token in report_text, ("reports", token)

    training_workbook = load_workbook(required[2], read_only=True, data_only=False)
    training_sheet = training_workbook["Training Evaluation"]
    training_headers = [cell.value for cell in training_sheet[4]]
    tidx = {name:index for index,name in enumerate(training_headers)}
    xgb_row = next(row for row in training_sheet.iter_rows(min_row=5, values_only=True) if row[0] == "xgboost_training")
    assert xgb_row[tidx["Split method"]] == "GroupShuffleSplit"
    assert xgb_row[tidx["Test size"]] == 0.22 and xgb_row[tidx["Seed"]] == 42
    assert xgb_row[tidx["Dataset status"]] == "Pending Researcher Evidence"
    assert xgb_row[tidx["Raw metrics status"]] == "Pending Owner Action"
    for token in ["n_estimators", "tree_method", "reg_lambda", "min_child_weight"]: assert token in xgb_row[tidx["XGBRegressor parameters"]]
    training_workbook.close(); data_check.close()
    missing = [row for row in input_data["source_citations"] if row["status"] != "Resolved"]
    assert not missing, missing
    return {
        "status": "passed_with_human_actions", "primary_artifacts": 10,
        "document_pdf_pages": counts["ai_report"] + counts["training_statement"] + counts["data_manual"],
        "workbook_sheets": summary["sheets"], "workbook_pdf_pages": counts["algorithm_pdf"] + counts["data_pdf"],
        "formula_contracts": len(summary["formula_contracts"]), "formula_error_scan": "0 errors",
        "visual_manifest": digest(manifests / "task5_visual_qa_manifest.json"),
        "checksum_entries": checksum_entries, "model_algorithm_roles": len(input_data["model_algorithm_inventory"]),
        "training_evidence_records": len(input_data["training_evidence"]),
        "persisted_schema_rows": summary["persisted_schema_rows"],
        "export_schema_rows": summary["export_schema_rows"],
        "human_actions": input_data["human_actions"],
    }


def main() -> None:
    parser = argparse.ArgumentParser(); parser.add_argument("--staging", type=Path, default=Path("/private/tmp/fsookta-final-handover")); parser.add_argument("--summary", type=Path, required=True)
    args = parser.parse_args(); result = verify(args.staging)
    args.summary.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
