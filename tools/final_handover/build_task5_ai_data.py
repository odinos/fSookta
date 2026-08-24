#!/usr/bin/env python3
"""Build source-grounded Task 5 AI/algorithm/data DOCX inputs and workbook data."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from pathlib import Path

from docx import Document
from docx.oxml import OxmlElement
from docx.shared import Inches, Pt

from build_task4_architecture import (
    COMMIT,
    TREE,
    VERSION,
    add_evidence_table,
    add_title,
    configure_doc,
    set_cell_margins,
)

STAGING = Path("/private/tmp/fsookta-final-handover")
ALLOWED_STATUSES = {
    "Complete", "Complete - Pending Signature", "Pending Owner Action",
    "Pending Researcher Evidence", "N/A with Rationale",
    "Exception Approval Required",
}

ALGORITHM_WORKBOOK_SHEETS = [
    "Control Summary", "Model Algorithm Inventory", "REBA Tables Thresholds",
    "ISO Formulas Applicability", "Boundary Decision Cases",
    "Image Pose Failure", "XGBoost Logistic IO", "Detected Risk Mapping",
    "Recommendation Triggers", "Priority Conflict Dedup", "Recommendation Messages",
    "Research Traceability", "Training Evaluation", "Limitations", "Human Actions",
]
DATA_WORKBOOK_SHEETS = [
    "Control Summary", "Persisted Keys Records", "Export Schema Order",
    "Enumerations Values", "Derivations", "Privacy Retention",
    "Migration Compatibility", "Evidence Sources", "Human Actions",
]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _resolve(root: Path, relative: str) -> dict:
    path = root / relative
    return {
        "path": relative,
        "status": "Resolved" if path.exists() else "Pending Owner Action",
        "sha256": sha(path) if path.is_file() else "Unavailable",
    }


def _all_history_headers(text: str) -> list[str]:
    start = text.index("static String buildAllHistoryCsv")
    section = text[start:text.index("for (final record in records)", start)]
    # The header is the first nested list. It contains conditional Thai/English
    # display labels; for those columns use the stable English branch.
    section = re.sub(r"thai\s*\?\s*'[^']*'\s*:\s*'([^']*)'", r"'\1'", section)
    return re.findall(r"'([^']+)'", section)[0:]


def _const_strings(text: str, name: str) -> list[str]:
    match = re.search(rf"static const {re.escape(name)}\s*=\s*\[(.*?)\];", text, re.S)
    if not match:
        return []
    return re.findall(r"'([^']+)'", match.group(1))


def _recommendation_messages(text: str) -> list[dict]:
    pairs = re.findall(r"thai\s*\?\s*'([^']+)'\s*:\s*'([^']+)'", text, re.S)
    seen: set[tuple[str, str]] = set()
    rows = []
    for index, (thai, english) in enumerate(pairs, 1):
        pair = (thai.strip(), english.strip())
        if pair in seen:
            continue
        seen.add(pair)
        rows.append({
            "message_id": f"farmer_message_{index:02d}",
            "thai": pair[0], "english": pair[1],
            "source": "lib/core/services/risk_recommendation_service.dart",
        })
    return rows


def _privacy(field: str, owner: str = "") -> str:
    """Return the explicit privacy contract for one persisted key/owned field."""
    composite = "Sensitive composite participant/profile + assessment/research + financial data"
    preferences = {
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
    if not owner:
        if field not in preferences:
            raise ValueError(f"Missing explicit preference privacy contract: {field}")
        return preferences[field]

    participant_history = {
        "farmerProfileId", "farmerId", "farmerName", "farmerRole", "farmerLocation",
        "farmerAge", "farmerGender", "farmerWeight", "farmerHeight", "farmerBmi",
        "farmerBmiCategory", "photoId", "photoTimestamp",
    }
    operational_history = {"id", "dateTime", "appVersion", "aiModelSource"}
    financial_history = {"economicLoss", "moneySaved"}
    participant_draft = {"farmerProfileId", "farmerId", "farmerName", "selectedImagePaths"}
    operational_draft = {"appVersion", "assessmentDateKey", "savedAt"}
    if owner == "UserProfile":
        return "Sensitive financial data" if field == "incomePerYear" else "Sensitive participant/profile data"
    if owner == "EvaluationHistoryRecord":
        if field in participant_history: return "Sensitive participant/profile data"
        if field in operational_history: return "Operational metadata"
        if field in financial_history: return "Sensitive financial data"
        return "Sensitive assessment/research data"
    if owner == "EvaluationDraft":
        if field in participant_draft: return "Sensitive participant/profile data"
        if field in operational_draft: return "Operational metadata"
        return "Sensitive assessment/research data"
    if owner in {"ErgoInputData", "RebaInputData"}:
        return "Sensitive financial data" if field == "dailyIncome" else "Sensitive assessment/research data"
    if owner == "ErgoResult":
        return "Sensitive financial data" if field == "economicLoss" else "Sensitive assessment/research data"
    if owner in {"AssessmentBreakdown", "MotionAnalysisSummary", "PoseRebaFrameAnalysis"}:
        return "Sensitive assessment/research data"
    raise ValueError(f"Missing explicit persisted-field privacy contract: {owner}.{field}")


def _semantic_type(field: str) -> tuple[str, str, str]:
    key = field.lower()
    if any(token in key for token in ("date", "time", "timestamp", "createdat", "savedat", "updatedat")):
        return "ISO-8601 text", "ISO-8601 with device offset when available", "N/A"
    if key.startswith("is") or key.startswith("has") or key in {"setupcompleted", "assistance_required", "uses_iso11228"}:
        return "boolean", "true or false", "N/A"
    if any(token in key for token in ("score", "count", "age", "workdays", "work_days", "error_count", "seconds", "duration", "frequency")):
        unit = "score points" if "score" in key or "reba" in key or key.startswith("iso") else "count"
        if "seconds" in key: unit = "seconds"
        if "duration" in key: unit = "minutes"
        if "frequency" in key: unit = "events/hour"
        return "integer or decimal number", ">= 0; REBA source values are integer score points", unit
    if any(token in key for token in ("weight", "height", "distance", "cost", "impact", "saved", "loss", "income", "bmi", "percent", "ratio", "force")):
        unit = "kg" if "weight" in key else "cm" if "height" in key else "m" if "distance" in key else "THB" if any(t in key for t in ("cost", "impact", "saved", "loss", "income")) else "%" if "percent" in key else "ratio"
        return "decimal number", ">= 0", unit
    if any(token in key for token in ("paths", "images", "recommendations", "breakdown", "history", "farmers", "drafts")):
        return "JSON array", "Array encoded by owning model", "N/A"
    return "text", "Source enum/text vocabulary or non-empty identifier where required", "N/A"


def _class_sections(text: str) -> dict[str, str]:
    matches = list(re.finditer(r"(?m)^class\s+(\w+)", text))
    return {
        match.group(1): text[match.start():(matches[index + 1].start() if index + 1 < len(matches) else len(text))]
        for index, match in enumerate(matches)
    }


def _dart_unit(field: str, dart_type: str) -> str:
    key = field.lower()
    if key.endswith("ms"): return "milliseconds"
    if key.endswith("seconds"): return "seconds"
    if key.endswith("hours"): return "hours"
    if key.endswith("minutes"): return "minutes"
    if key.endswith("daysperweek"): return "days/week"
    if "frequency" in key: return "events/hour"
    if key.endswith("fps"): return "frames/second"
    if key.endswith("deg"): return "degrees"
    if "probability" in key: return "probability 0..1"
    if key.endswith("ratio"): return "ratio 0..1"
    if "weight" in key: return "kg"
    if "distance" in key: return "m or source-labeled distance"
    if "income" in key: return "THB/day or source profile period"
    if "economic" in key or "money" in key or "cost" in key or "loss" in key: return "THB"
    if "score" in key or key in {"techscore", "limitvalue"}: return "score/ratio"
    return "N/A"


def _dart_allowed(field: str, dart_type: str) -> str:
    base = dart_type.rstrip("?")
    key = field.lower()
    if base == "bool": return "true or false"
    if base == "int": return ">= 0; source constructor/fromJson fallback applies"
    if base == "double":
        return "0..1" if key.endswith("ratio") or "probability" in key else ">= 0 unless source calculation permits signed value"
    if base == "DateTime": return "ISO-8601 text in persisted JSON"
    if base.startswith("List<"): return f"JSON array matching {base}"
    if base.startswith("Map<"): return f"JSON object matching {base} enum-name mapping"
    if base in {"RiskLevel", "AiAlertLevel", "SooktaActivity", "JobType", "AssessmentMethod", "MotionPattern"}: return f"{base}.name enum text"
    if base in {"AssessmentBreakdown", "RebaInputData", "ErgoInputData", "ErgoResult", "MotionAnalysisSummary"}: return f"Nested {base} JSON object"
    return "Text/identifier accepted by the owning constructor/fromJson"


def _owner_location(owner: str, field: str) -> str:
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


def _persisted_semantics(owner: str, field: str, dart_type: str) -> dict[str, str]:
    """Return source-backed semantic metadata for a serialized Dart field."""
    readable = re.sub(r"(?<!^)(?=[A-Z])", " ", field).replace("_", " ").strip().lower()
    data = {
        "description": f"Persisted {readable} value owned by {owner}",
        "unit": _dart_unit(field, dart_type),
        "allowed": _dart_allowed(field, dart_type),
        "privacy": _privacy(field, owner),
    }
    overrides: dict[tuple[str, str], tuple[str, str, str]] = {
        ("ErgoInputData", "liftFrequency"): ("Lift repetition frequency in lifts/minute; all-history export multiplies by 60 for the per-hour column", "lifts/minute", ">= 0 lifts/minute"),
        ("EvaluationDraft", "frequency"): ("Draft lift/task repetition frequency passed to ErgoInputData.liftFrequency", "lifts/minute", ">= 0 lifts/minute"),
        ("ErgoInputData", "horizontalDist"): ("Horizontal hand-to-body lifting distance H", "cm", ">= 0 cm"),
        ("ErgoInputData", "verticalHeight"): ("Vertical hand height V used by the lifting calculation", "cm", ">= 0 cm"),
        ("EvaluationDraft", "horizontalDistanceText"): ("Draft numeric text for horizontal hand-to-body lifting distance H", "cm", "Numeric text in cm"),
        ("EvaluationDraft", "verticalHeightText"): ("Draft numeric text for vertical hand height V", "cm", "Numeric text in cm"),
        ("ErgoInputData", "initialForce"): ("Initial push/pull force", "N", ">= 0 N"),
        ("ErgoInputData", "sustainForce"): ("Sustained push/pull force", "N", ">= 0 N"),
        ("EvaluationDraft", "initialForce"): ("Draft initial push/pull force", "N", ">= 0 N"),
        ("EvaluationDraft", "sustainForce"): ("Draft sustained push/pull force", "N", ">= 0 N"),
        ("ErgoResult", "limitValue"): ("Context-dependent limit: lifting RWL in kg, push/pull initial-force limit in N, or encoded REBA limit", "kg, N, or encoded REBA limit (context-dependent)", ">= 0; interpret only with the calculation method/job type"),
        ("UserProfile", "incomePerYear"): ("Annual income stored as numeric text and converted to daily income by dividing by 365", "THB/year", "Numeric text >= 0 THB/year or blank"),
        ("UserProfile", "age"): ("Participant age stored as numeric text", "years", "Numeric text >= 0 years or blank"),
        ("UserProfile", "height"): ("Participant height stored as numeric text", "cm", "Numeric text > 0 cm or blank"),
        ("UserProfile", "weight"): ("Participant body weight stored as numeric text", "kg", "Numeric text > 0 kg or blank"),
        ("EvaluationHistoryRecord", "farmerAge"): ("Profile age snapshot stored with the assessment", "years", "Numeric text >= 0 years or blank"),
        ("EvaluationHistoryRecord", "farmerHeight"): ("Profile height snapshot stored with the assessment", "cm", "Numeric text > 0 cm or blank"),
        ("EvaluationHistoryRecord", "farmerWeight"): ("Profile body-weight snapshot stored with the assessment", "kg", "Numeric text > 0 kg or blank"),
        ("EvaluationHistoryRecord", "farmerBmi"): ("Body-mass index snapshot derived from height and weight", "kg/m2", "> 0 kg/m2 when present"),
        ("EvaluationHistoryRecord", "aiRiskPercent"): ("Optional advisory AI risk percentage", "%", "Integer 0..100 when present"),
        ("EvaluationHistoryRecord", "expertReba"): ("Optional expert-comparator REBA value", "REBA score points", ">= 0 when present"),
        ("ErgoInputData", "dailyIncome"): ("Daily income used by economic-impact calculation", "THB/day", ">= 0 THB/day"),
        ("RebaInputData", "dailyIncome"): ("Daily income used by economic-impact calculation", "THB/day", ">= 0 THB/day"),
        ("EvaluationDraft", "durationHours"): ("Draft task duration", "hours", "> 0 hours in the evaluation flow"),
        ("ErgoInputData", "durationHours"): ("Task duration", "hours", "> 0 hours in the evaluation flow"),
        ("EvaluationDraft", "workDaysPerWeek"): ("Draft work days per week", "days/week", "> 0 days/week in the evaluation flow"),
        ("ErgoInputData", "workDaysPerWeek"): ("Work days per week", "days/week", "> 0 days/week in the evaluation flow"),
        ("EvaluationDraft", "pushPullDistance"): ("Draft push/pull travel distance", "m", ">= 0 m"),
        ("EvaluationDraft", "transportDistanceText"): ("Draft numeric text for transport distance", "m", "Numeric text in m"),
        ("ErgoInputData", "transportDistance"): ("Manual-handling transport or push/pull distance", "m", ">= 0 m"),
        ("ErgoInputData", "toolWeightBandCode"): ("Encoded tool-weight band category", "category code", "Non-negative integer category code"),
        ("ErgoResult", "userScoreColor"): ("ARGB color integer associated with the user risk score", "ARGB integer", "32-bit ARGB color value"),
    }
    if owner in {"MotionAnalysisSummary", "PoseRebaFrameAnalysis"} and field.lower().endswith("deg"):
        data.update(description=f"Pose-derived {readable}", unit="degrees", allowed="Finite angle in degrees when present")
    if owner == "MotionAnalysisSummary" and field.endswith("FrameCount"):
        data.update(description=f"Count of sampled frames classified for {readable.removesuffix(' frame count')}", unit="frames", allowed=">= 0 integer frames")
    if owner == "ErgoResult" and field == "limitValue":
        data["privacy"] = "Sensitive assessment/research data"
    if owner == "UserProfile" and field == "incomePerYear":
        data["privacy"] = "Sensitive financial data"
    if owner == "UserProfile" and field == "location":
        data["privacy"] = "Sensitive participant/profile data"
    override = overrides.get((owner, field))
    if override:
        data.update(description=override[0], unit=override[1], allowed=override[2])
    return data


def _extract_persisted_dart_contracts(root: Path, record_sources: list[str]) -> list[dict]:
    rows: list[dict] = []
    seen: set[tuple[str, str, str]] = set()
    all_sections: dict[str, tuple[str, str]] = {}
    for relative in record_sources:
        text = (root / relative).read_text(encoding="utf-8")
        for owner, section in _class_sections(text).items():
            all_sections.setdefault(owner, (relative, section))
            declarations = {field: dart_type for dart_type, field in re.findall(r"(?m)^\s*final\s+([^;=]+?)\s+(\w+)\s*;", section)}
            for _, field, expression in re.findall(r"(?m)^\s{4,12}(['\"])([^'\"]+)\1\s*:\s*([^,\n]+)", section):
                if field not in declarations:
                    continue
                identity = (owner, field, relative)
                if identity in seen:
                    continue
                rows.append({"owner":owner,"field":field,"source":relative,"dart_type":declarations[field].strip(),"serializer_expression":expression.strip(),"required":f"required this.{field}" in section})
                seen.add(identity)
    # ErgoResult is serialized by AssessmentBreakdown._resultToJson rather than
    # by an ErgoResult.toJson method. Preserve the value-object owner.
    if "ErgoResult" in all_sections and "AssessmentBreakdown" in all_sections:
        result_relative, result_section = all_sections["ErgoResult"]
        result_declarations = {field: dart_type for dart_type, field in re.findall(r"(?m)^\s*final\s+([^;=]+?)\s+(\w+)\s*;", result_section)}
        breakdown_section = all_sections["AssessmentBreakdown"][1]
        method = breakdown_section[breakdown_section.index("static Map<String, Object?> _resultToJson"):breakdown_section.index("static ErgoResult _resultFromJson")]
        for _, field, expression in re.findall(r"(?m)^\s{6,10}(['\"])([^'\"]+)\1\s*:\s*([^,\n]+)", method):
            if field in result_declarations:
                identity = ("ErgoResult", field, result_relative)
                if identity not in seen:
                    rows.append({"owner":"ErgoResult","field":field,"source":result_relative,"dart_type":result_declarations[field].strip(),"serializer_expression":expression.strip(),"required":f"required this.{field}" in result_section})
                    seen.add(identity)
    return sorted(rows, key=lambda row: (row["source"], row["owner"], row["field"]))


def _persisted_rows(preference_keys: list[str], record_rows: list[dict]) -> list[dict]:
    key_details = {
        "sookta.profile": ("Current farmer profile JSON object", "FarmerProfile", "Empty/default profile"),
        "sookta.farmers": ("All farmer profiles JSON array", "List<FarmerProfile>", "[]"),
        "sookta.activeProfileId": ("Identifier of the active farmer profile", "String", "null"),
        "sookta.setupCompleted": ("Whether initial setup completed", "bool", "false"),
        "sookta.history": ("Persisted ergonomic evaluation history JSON array", "List<EvaluationHistoryRecord>", "[]"),
        "sookta.nextHistoryId": ("Next monotonically advanced history identifier", "int", "recomputed above restored maximum"),
        "sookta.language": ("Selected application language code", "String", "application default"),
        "sookta.evaluationDraft": ("Legacy/current single evaluation draft JSON", "EvaluationDraft", "null"),
        "sookta.evaluationDrafts": ("Per-profile evaluation drafts JSON array", "List<EvaluationDraft>", "[]"),
        "sookta.dataSchemaVersion": ("Local persistence schema version", "int", "1 before migration"),
        "sookta.latestBackup": ("Pointer to newest dynamic pre-migration backup key", "String", "null"),
        "sookta.backup.schema.<version>.<timestamp>": ("Dynamic pre-migration snapshot containing prior preference payload", "JSON object", "created only before an upgrade"),
    }
    rows = []
    for key in preference_keys:
        description, dtype, missing = key_details[key]
        rows.append({
            "field": key, "owner": "SharedPreferences", "description": description,
            "type": dtype, "nullable": "No" if dtype in {"bool", "int"} else "Yes", "allowed": "JSON/value shape stated in Type; dynamic key embeds prior schema version and microsecond timestamp",
            "unit": "N/A", "source": "SharedPreferences", "derivation": "Written/read by AppState persistence and migration code",
            "missing": missing, "privacy": _privacy(key), "persisted_location": f"SharedPreferences: {key}",
            "export_location": "Not a direct export column; nested history fields feed exports", "synthetic_example": "synthetic_value",
            "validation": "Decode with AppState restore/migration; malformed restore fails visibly", "version": VERSION, "evidence": "lib/app/app_state.dart",
        })
    for item in record_rows:
        field, owner, source = item["field"], item["owner"], item["source"]
        dtype = item["dart_type"]
        semantics = _persisted_semantics(owner, field, dtype)
        nullable = "Yes" if dtype.endswith("?") else "No"
        rows.append({
            "field": field, "owner": owner, "description": semantics["description"],
            "type": dtype, "nullable": nullable,
            "allowed": semantics["allowed"], "unit": semantics["unit"], "source": owner, "derivation": f"Serializer expression: {item['serializer_expression']}",
            "missing": "null preserved by nullable declaration/serializer" if nullable == "Yes" else "Non-null declaration; constructor/fromJson fallback is authoritative", "privacy": semantics["privacy"],
            "persisted_location": _owner_location(owner, field),
            "export_location": "Mapped only where assessment_export_service.dart declares a column", "synthetic_example": "synthetic_value",
            "validation": f"Dart `{dtype} {field}`; {'required constructor parameter' if item['required'] else 'constructor default/optional parameter'}; verify serializer expression and fromJson conversion", "version": VERSION, "evidence": source,
        })
    return rows


def _export_semantic_contracts(headers: list[str]) -> dict[str, dict[str, str]]:
    contracts: dict[str, dict[str, str]] = {}

    def add(fields: list[str], dtype: str, nullable: str, allowed: str, unit: str,
            missing: str, privacy: str) -> None:
        for field in fields:
            contracts[field] = {"type":dtype, "nullable":nullable, "allowed":allowed,
                                "unit":unit, "missing":missing, "privacy":privacy}

    operational = "Operational metadata"
    participant = "Sensitive participant/profile data"
    assessment = "Sensitive assessment/research data"
    financial = "Sensitive financial/impact data"
    add(["Export Generated At"], "ISO-8601 date-time text", "No", "DateTime.now().toIso8601String() including device offset when available", "N/A", "Never blank", operational)
    add(["export_schema_version"], "text", "No", "Non-empty source-controlled export schema version", "N/A", "Never blank", operational)
    add(["assessment_reference_sources", "assessment_scope_note", "calculation_standard_note"], "text", "No", "Source-controlled reference/scope text", "N/A", "Never blank", operational)
    add(["Record ID", "transaction_id"], "integer", "No", ">= 0 history record identifier", "identifier", "Never blank; direct record.id", participant)
    add(["App Version"], "text", "Yes", "Application version text or '-'", "N/A", "'-' when record.appVersion is null", operational)
    add(["Farmer ID", "user_id"], "text", "No", "Resolved farmer/profile identifier; final fallback record-<id>", "identifier", "Never blank because _resolvedFarmerId supplies record-<id>", participant)
    add(["Name", "Role", "Work Space"], "text", "Yes", "Profile text, record fallback, or '-'", "N/A", "'-' when both profile and record value are empty/unavailable", participant)
    add(["Age"], "numeric text", "Yes", "Numeric age text or '-'", "years", "'-' when both profile and record value are empty/unavailable", participant)
    add(["Gender"], "text", "Yes", "Source profile/record gender text or '-'", "N/A", "'-' when both profile and record value are empty/unavailable", participant)
    add(["Weight (kg)"], "numeric text", "Yes", "Numeric weight text or '-'", "kg", "'-' when both profile and record value are empty/unavailable", participant)
    add(["Height (cm)"], "numeric text", "Yes", "Numeric height text or '-'", "cm", "'-' when both profile and record value are empty/unavailable", participant)
    add(["BMI"], "decimal-number text", "Yes", "> 0 formatted to one decimal place, or '-'", "kg/m2", "'-' when BMI cannot be derived", participant)
    add(["BMI Category"], "text", "Yes", "Underweight; Normal weight; Above Asian BMI range; localized Thai values; '-' when unavailable", "N/A", "'-' when BMI category cannot be derived", participant)
    add(["Date of data entry", "assessment_date"], "YYYY-MM-DD text", "No", "Calendar date formatted YYYY-MM-DD", "N/A", "Never blank; record.dateTime is required", assessment)
    add(["assessment_time"], "HH:mm:ss text", "No", "00:00:00..23:59:59 local device time", "N/A", "Never blank; record.dateTime is required", assessment)
    add(["Activity Stage"], "text", "Yes", "English activity stage label or '-'", "N/A", "'-' when record.activity is null", assessment)
    add(["Specific Task", "task_type"], "text", "No", "Source activity name/text; task_type prefers enum name", "N/A", "Non-null source string; may be empty only if source activityName is empty", assessment)
    add(["Posture Description"], "text", "Yes", "Method and REBA component-score description or '-'", "N/A", "'-' when assessmentBreakdown is null", assessment)
    add(["REBA Score"], "integer", "Yes", "REBA user score 1..15 or '-'", "REBA score points", "'-' when assessmentBreakdown is null", assessment)
    add(["ISO 11228 Risk Level", "ISO_risk_before", "ISO_risk_after"], "text", "Yes", "Low; Medium; High; Very high; localized Thai values; or '-'", "risk tier", "'-' when applicable ISO result is absent", assessment)
    add(["Tool Used"], "text", "Yes", "Localized tool label or '-'", "N/A", "'-' when ergoInput is absent or tool labels are empty", assessment)
    add(["Tool Weight (kg)"], "number", "Yes", ">= 0; tool weight with load-weight fallback", "kg", "'-' when ergoInput is absent", assessment)
    add(["Tool Weight Code"], "integer", "Yes", "Positive encoded tool-weight band", "category code", "'-' when code is zero or ergoInput is absent", assessment)
    add(["Manual Handling Weight (kg)", "load_before"], "number", "Yes", ">= 0 handled load", "kg", "'-' when ergoInput is absent", assessment)
    add(["Manual Handling Distance (m)"], "number", "Yes", ">= 0 transport distance", "m", "'-' when ergoInput is absent", assessment)
    add(["Frequency per hour", "frequency_before"], "number", "Yes", ">= 0; ErgoInputData.liftFrequency multiplied by 60 and formatted by _num", "lifts/hour", "'-' when ergoInput is absent", assessment)
    add(["Duration (minutes)", "duration_before"], "number", "Yes", ">= 0; durationHours multiplied by 60 and formatted by _num", "minutes", "'-' when ergoInput is absent", assessment)
    add(["Work days per week"], "number", "Yes", "> 0 in evaluation flow; formatted by _num", "days/week", "'-' when ergoInput is absent", assessment)
    add(["MSD Symptom Location"], "text", "Yes", "Comma-separated non-low-risk body parts or '-'", "N/A", "'-' when no body part exceeds low risk", assessment)
    add(["MSD Symptom Severity", "Before Risk", "After Risk", "REBA_risk_before", "REBA_risk_after",
         "trend_level", "neck_risk", "shoulder_risk", "upper_limb_risk", "wrist_risk", "back_risk", "knee_risk"],
        "text", "No", "Low; Medium; High; Very high; localized Thai values", "risk tier", "Never blank; source supplies a risk or low-risk fallback", assessment)
    add(["Medical Cost (THB)", "Productivity Loss (THB)", "Before Impact (THB)", "After Impact (THB)", "Estimated Saved (THB)"],
        "integer", "No", ">= 0 source economic-impact amount", "THB", "Never blank; source calculation returns an integer", financial)
    add(["Lost Workdays"], "integer", "No", ">= 0 estimated lost workdays", "days", "Never blank; source calculation returns an integer", financial)
    add(["Before Score", "After Score", "REBA_before"], "integer", "No", "Source user score; REBA path is 1..15", "score points", "Never blank; required record score or deterministic fallback", assessment)
    add(["Economic Impact Formula"], "text", "No", "Human-readable formula including effective score reduction", "N/A", "Never blank", financial)
    add(["User Feedback Notes"], "text", "Yes", "Selected suggestions joined with ' | ' or '-'", "N/A", "'-' when selectedSuggestions is empty", assessment)
    add(["ISO_before", "ISO_after"], "integer", "Yes", "ISO user score when applicable or '-'", "score points", "'-' when applicable ISO result is absent", assessment)
    add(["REBA_after"], "integer", "Yes", "REBA user score 1..15 or '-'", "REBA score points", "'-' when afterAssessmentBreakdown is absent", assessment)
    add(["REBA_reduction"], "integer", "Yes", "Signed before-minus-after REBA score difference", "score points", "'-' when before or after REBA result is absent", assessment)
    add(["REBA_reduction_percent"], "percentage text", "Yes", "Rounded integer percent text, including sign when reduction is negative", "%", "'-' when before score <= 0 or either score is absent", assessment)
    add(["trend_REBA_average"], "number", "No", ">= 0 average before score formatted by _num", "score points", "Never blank; trend window contains the current record", assessment)
    add(["trend_REBA_maximum"], "integer", "No", ">= 0 maximum before score", "score points", "Never blank; trend window contains the current record", assessment)
    add(["trend_high_risk_count"], "integer", "No", ">= 0 count of high/very-high records", "records", "Never blank", assessment)
    add(["trend_direction"], "text", "No", "increasing; decreasing; stable", "N/A", "Never blank", assessment)
    add(["photo_id"], "text", "Yes", "Persisted photo ID, derived pose-frame ID, or '-'", "identifier", "'-' when no persisted ID or pose frame is available", participant)
    add(["photo_timestamp"], "ISO-8601 date-time text", "Yes", "ISO-8601 timestamp or '-'", "N/A", "'-' when neither persisted nor derived photo timestamp is available", participant)
    add(["time_on_task_seconds"], "integer", "Yes", ">= 0 elapsed time-on-task seconds", "seconds", "Blank string when record.timeOnTaskSeconds is null", assessment)
    add(["completion_status"], "text", "Yes", "Research workflow completion-status text", "N/A", "Blank string when record.completionStatus is null", assessment)
    add(["assistance_required"], "boolean text", "Yes", "true; false", "N/A", "Blank string when record.assistanceRequired is null", assessment)
    add(["error_count"], "integer", "Yes", ">= 0 workflow error count", "errors", "Blank string when record.errorCount is null", assessment)
    add(["expert_REBA"], "number", "Yes", "Expert comparator REBA value formatted by _num", "REBA score points", "Blank string when record.expertReba is null", assessment)
    add(["expert_risk_level"], "text", "Yes", "Low; Medium; High; Very high; localized Thai values", "risk tier", "Blank string when record.expertRiskLevel is null", assessment)
    add(["expert_assessment_date"], "ISO-8601 date-time text", "Yes", "DateTime.toIso8601String()", "N/A", "Blank string when record.expertAssessmentDate is null", assessment)
    add(["expert_comments"], "text", "Yes", "Expert comments text", "N/A", "Blank string when record.expertComments is null", assessment)
    contracts["trend_level"]["allowed"] = "Low; Medium; High; Very high (localized when Thai export is selected)"
    missing = set(headers) - set(contracts)
    extra = set(contracts) - set(headers)
    if missing or extra:
        raise ValueError(f"Export semantic contract mismatch: missing={sorted(missing)} extra={sorted(extra)}")
    return contracts


def _export_schema_rows(headers: list[str]) -> list[dict]:
    descriptions = {
        "Export Generated At":"Timestamp when the all-history export file was generated", "export_schema_version":"Export schema identifier", "assessment_reference_sources":"Reference-source identifiers attached to the export", "assessment_scope_note":"Scope and evidence-boundary note", "calculation_standard_note":"REBA/ISO calculation-method note",
        "Record ID":"Application history record identifier", "App Version":"Application version saved with the assessment", "Farmer ID":"Research-facing farmer identifier", "Name":"Farmer display name", "Role":"Farmer role", "Work Space":"Recorded work-space/location text", "Age":"Farmer age", "Gender":"Farmer gender used by applicable calculations", "Weight (kg)":"Farmer body weight", "Height (cm)":"Farmer height", "BMI":"Body-mass index derived from weight and height", "BMI Category":"BMI category derived by the application", "Date of data entry":"Assessment record date and time", "Activity Stage":"Agricultural activity enum/display label", "Specific Task":"Specific task text", "Posture Description":"Observed posture description", "REBA Score":"Before-intervention deterministic REBA score", "ISO 11228 Risk Level":"Before-intervention ISO 11228 risk level when applicable", "Tool Used":"Selected tool name", "Tool Weight (kg)":"Tool weight", "Tool Weight Code":"Encoded tool-weight category", "Manual Handling Weight (kg)":"Manually handled load", "Manual Handling Distance (m)":"Manual-handling travel distance", "Frequency per hour":"Task/lift frequency per hour", "Duration (minutes)":"Task duration", "Work days per week":"Work frequency by days per week", "MSD Symptom Location":"Research MSD symptom location", "MSD Symptom Severity":"Research MSD symptom severity", "Medical Cost (THB)":"Direct medical cost captured for research", "Lost Workdays":"Lost workdays captured for research", "Productivity Loss (THB)":"Productivity loss captured for research", "Before Score":"Before-intervention user score", "After Score":"After-intervention user score", "Before Risk":"Before-intervention combined risk tier", "After Risk":"After-intervention combined risk tier", "Before Impact (THB)":"Estimated economic impact before recommendations", "After Impact (THB)":"Estimated economic impact after recommendations", "Estimated Saved (THB)":"Estimated impact reduction", "Economic Impact Formula":"Human-readable economic-impact formula/assumption", "User Feedback Notes":"User/research feedback notes",
        "transaction_id":"Stable transaction/history identifier", "user_id":"Profile/farmer identifier associated with the transaction", "assessment_date":"Assessment calendar date", "assessment_time":"Assessment local time", "task_type":"Activity/task type", "REBA_before":"Before-intervention REBA score", "REBA_risk_before":"Before-intervention REBA risk tier", "ISO_before":"Before-intervention ISO user score when applicable", "ISO_risk_before":"Before-intervention ISO risk tier when applicable", "load_before":"Before-intervention handled/tool load", "frequency_before":"Before-intervention frequency per hour", "duration_before":"Before-intervention duration", "REBA_after":"After-intervention REBA score", "REBA_risk_after":"After-intervention REBA risk tier", "ISO_after":"After-intervention ISO user score when applicable", "ISO_risk_after":"After-intervention ISO risk tier when applicable", "REBA_reduction":"Absolute REBA score reduction", "REBA_reduction_percent":"REBA reduction divided by before score", "trend_REBA_average":"Average before REBA score in the trend window", "trend_REBA_maximum":"Maximum before REBA score in the trend window", "trend_high_risk_count":"Count of high/very-high before records in the trend window", "trend_level":"Daily trend level derived from high-risk count", "trend_direction":"Direction of the recent REBA trend", "neck_risk":"Neck body-part risk tier", "shoulder_risk":"Shoulder/arm body-part risk tier", "upper_limb_risk":"Upper-limb body-part risk tier", "wrist_risk":"Wrist body-part risk tier", "back_risk":"Back/trunk body-part risk tier", "knee_risk":"Knee/leg body-part risk tier", "photo_id":"Research photo identifier", "photo_timestamp":"Photo capture/association timestamp", "time_on_task_seconds":"Research time-on-task duration", "completion_status":"Research workflow completion status", "assistance_required":"Whether assistance was required", "error_count":"Research workflow error count", "expert_REBA":"Expert comparator REBA score", "expert_risk_level":"Expert comparator risk tier", "expert_assessment_date":"Expert assessment timestamp", "expert_comments":"Expert comparator comments",
    }
    contracts = _export_semantic_contracts(headers)
    rows=[]
    for index, field in enumerate(headers, 1):
        contract = contracts[field]
        if index <= 5:
            source, persisted = "AssessmentExportService export metadata", "Generated at export; not persisted"
        elif 6 <= index <= 17:
            source, persisted = "EvaluationHistoryRecord with FarmerProfile fallback", "sookta.history[] and sookta.profile/sookta.farmers[]"
        elif 18 <= index <= 45:
            source, persisted = "EvaluationHistoryRecord assessment/economic/research fields", "sookta.history[]"
        elif 46 <= index <= 74:
            source, persisted = "EvaluationHistoryRecord flat research projection", "sookta.history[]"
        else:
            source, persisted = "EvaluationHistoryRecord.researchData", "sookta.history[].researchData"
        derivation = f"Direct mapping for `{field}` in _worksheetFlatRow, with only its explicit null/blank/profile fallback"
        if field == "BMI": derivation = "weightKg / (heightCm / 100)^2"
        elif field == "REBA_reduction": derivation = "REBA_before - REBA_after"
        elif field == "REBA_reduction_percent": derivation = "REBA_reduction / REBA_before; blank when before <= 0"
        elif field in {"After Impact (THB)","Estimated Saved (THB)"}: derivation = "EconomicImpactService comparison: reduction capped at 4 points, rate capped at 1.0, rounded and clamped 0..999999"
        elif field == "trend_level":
            derivation = "_trendLevel(highRiskCount): 0-1 Low; 2-3 Medium; 4-5 High; >=6 Very high; localized for Thai export"
        if field == "assessment_time": derivation = "_timeOnly(record.dateTime): zero-padded HH:mm:ss"
        elif field == "time_on_task_seconds": derivation = "record.timeOnTaskSeconds ?? ''"
        elif field == "BMI Category": derivation = "_bmiCategory(profile, record, thai) localized category label"
        date_like = "date" in contract["type"].lower() or field == "assessment_time"
        score_like = "score" in contract["unit"].lower()
        example = "'2026-08-24T09:00:00+07:00" if date_like else ("'09:00:00" if field == "assessment_time" else 6 if score_like or contract["type"] in {"integer", "number"} else f"SYN-{index:03d}" if "ID" in field or field.endswith("_id") else "synthetic_value")
        rows.append({"field":field,"description":descriptions[field],"type":contract["type"],"nullable":contract["nullable"],"allowed":contract["allowed"],"unit":contract["unit"],"source":source,"derivation":derivation,"missing":contract["missing"],"privacy":contract["privacy"],"persisted_location":persisted,"export_location":f"{index}: {field}","synthetic_example":example,"validation":"Preserve exact column order, semantic type, range, applicability and source-specific '-' versus blank behavior","version":VERSION,"evidence":"lib/core/services/assessment_export_service.dart"})
    return rows


def inspect_source(root: Path) -> dict:
    manifest = _json(root / "assets/models/model_artifact_manifest.json")
    xgb = _json(root / "assets/models/xgboost_model_metadata.json")
    schema = _json(root / "assets/models/joint_feature_schema.json")
    daily = _json(root / "assets/ml/daily_injury_logistic_model.json")
    baseline = _json(root / "assets/ml/risk_alert_models.json")
    refs = _json(root / "data/research/reference_sources/training_reference_sources.json")
    app_state = (root / "lib/app/app_state.dart").read_text(encoding="utf-8")
    export_text = (root / "lib/core/services/assessment_export_service.dart").read_text(encoding="utf-8")
    training_export = (root / "lib/core/services/training_data_export_service.dart").read_text(encoding="utf-8")
    recommendation_text = (root / "lib/core/services/risk_recommendation_service.dart").read_text(encoding="utf-8")
    record_sources = [
        "lib/app/app_state.dart",
        "lib/core/models/assessment_session.dart",
        "lib/core/models/evaluation_models.dart",
    ]
    persisted_record_fields = _extract_persisted_dart_contracts(root, record_sources)
    xgb_artifact = manifest["artifacts"]["xgboost"]
    metrics_rel = xgb_artifact["metricsPath"]
    metrics_path = root / metrics_rel
    preference_keys = dict(re.findall(r"static const (_\w+Key)\s*=\s*'([^']+)'", app_state))
    schema_match = re.search(r"_currentDataSchemaVersion\s*=\s*(\d+)", app_state)
    all_history_headers = _all_history_headers(export_text)
    preference_values = sorted(preference_keys.values()) + ["sookta.backup.schema.<version>.<timestamp>"]
    prefixes = {"transplanting":"transplant", "fertilizing":"fert", "pesticide":"pesticide", "pruning":"pruning", "harvesting":"harvest", "transport":"transport"}
    manual = {"transplanting", "fertilizing", "pesticide", "transport"}
    recommendation_triggers = []
    for activity, prefix in prefixes.items():
        for tier in ("low", "medium", "high", "veryHigh"):
            mapped = "high" if tier == "veryHigh" else tier
            activity_key = f"act_{prefix}_ref_{mapped}"
            if activity_key not in recommendation_text:
                raise ValueError(f"Recommendation key missing from source: {activity_key}")
            recommendation_triggers.append({"activity":activity,"risk_tier":tier,"activity_key":activity_key,"weight_key":f"act_ref_weight_{mapped}" if activity in manual else "N/A","manual_handling":activity in manual,"source":"lib/core/services/risk_recommendation_service.dart"})
    daily_headers = [
        "row_type", "export_generated_at", "window_id", "farmer_id",
        "participant_code", "window_start_date", "window_end_date",
        "transaction_count", "transaction_ids", "activity_summary",
        "assessment_methods",
        *_const_strings(training_export, "dailyFeatureColumns"),
        "msd_symptom_present", "requires_medical_treatment_within_7_days",
        "medical_visit_within_7_days", "treatment_required_within_7_days",
        "msd_symptom_location", "msd_symptom_severity", "lost_workdays_7d",
        "direct_medical_cost_thb", "productivity_loss_thb", "label_confidence",
        "outcome_source", "reviewer_id", "reviewed_at", "notes",
    ]

    inventory = [
        {
            "role_id": "movenet_thunder", "component": "MoveNet Thunder",
            "identifier": schema["schemaId"],
            "binary_sha256": sha(root / "assets/ml/movenet_thunder.tflite"),
            "runtime_path": "assets/ml/movenet_thunder.tflite",
            "provenance": "Bundled pretrained TensorFlow Lite asset; upstream release/version not recorded in repository metadata",
            "input": "Letterboxed 256x256 image tensor", "output": "17 keypoints x/y/score",
            "training_class": "Pretrained; not fine-tuned in project", "authority": "Pose feature provider",
            "fallback": "Pose unavailable; deterministic manual inputs remain available",
            "limitations": "2D keypoints; confidence/visibility and capture quality limits; no project training evidence",
            "citation": "assets/models/joint_feature_schema.json; lib/core/services/pose_estimation_service.dart",
        },
        {
            "role_id": "movenet_multipose", "component": "MoveNet MultiPose Lightning",
            "identifier": "Bundled single-person eligibility/person-count gate; upstream release/version not recorded",
            "binary_sha256": sha(root / "assets/ml/movenet_multipose_lightning.tflite"),
            "runtime_path": "assets/ml/movenet_multipose_lightning.tflite",
            "provenance": "Bundled pretrained TensorFlow Lite asset",
            "input": "Image tensor", "output": "Confident person count and eligible/reject decision (eligible only when count == 1)",
            "training_class": "Pretrained; not fine-tuned in project", "authority": "Single-person eligibility gate",
            "fallback": "Reject/recapture when count is zero, multiple, or unavailable; Thunder estimates pose only after gate passes", "limitations": "Person-count eligibility gate only; does not supply assessment keypoints",
            "citation": "lib/core/services/multi_person_pose_detector.dart; lib/screens/main/evaluation_form_screen.dart",
        },
        {
            "role_id": "reba", "component": "REBA table scorer",
            "identifier": "Source-controlled REBA tables at final commit", "binary_sha256": "N/A",
            "runtime_path": "lib/core/services/ergo_calculator.dart",
            "provenance": "Deterministic source tables plus cited REBA reference",
            "input": "Trunk, neck, legs, arms, wrist, load, coupling, activity",
            "output": "Score A/B/C, final REBA, risk tier", "training_class": "Not trained; deterministic",
            "authority": "Primary deterministic", "fallback": "Manual component inputs",
            "limitations": "Encoded safety floors are project rules and must be interpreted separately from the original method",
            "citation": "lib/core/services/ergo_calculator.dart; test/ergo_calculator_test.dart",
        },
        {
            "role_id": "iso11228", "component": "ISO 11228 lifting/push-pull logic",
            "identifier": "Source-controlled ISO applicability/formulas at final commit", "binary_sha256": "N/A",
            "runtime_path": "lib/core/services/ergo_calculator.dart",
            "provenance": "Deterministic implementation informed by ISO 11228 reference registry",
            "input": "Load/force, geometry, frequency, duration, transport, gender",
            "output": "Lifting index or force ratio, risk tier", "training_class": "Not trained; deterministic",
            "authority": "Primary deterministic when applicable", "fallback": "REBA remains primary for non-manual-handling tasks",
            "limitations": "Not a certification of ISO conformance; applicability and source licensing require review",
            "citation": "lib/core/services/ergo_calculator.dart; data/research/reference_sources/training_reference_sources.json",
        },
        {
            "role_id": "xgboost_onnx", "component": "XGBoost ONNX posture advisory",
            "identifier": xgb["version"], "binary_sha256": sha(root / "assets/models/xgboost_model.onnx"),
            "runtime_path": "assets/models/xgboost_model.onnx",
            "provenance": "Repository metadata records project training from document-guided/research labels",
            "input": f"{xgb['inputFeatureCount']} raw MoveNet features ({xgb['featureSchemaId']})",
            "output": "Advisory probability/risk signal", "training_class": "Project-trained",
            "authority": "Advisory only", "fallback": "Unavailable/invalid/runtime error => advisory omitted; REBA/ISO unchanged",
            "limitations": "Holdout contains only high/veryHigh classes; no external or clinical validation",
            "citation": "assets/models/xgboost_model_metadata.json; assets/models/model_artifact_manifest.json",
        },
        {
            "role_id": "daily_logistic", "component": "Seven-transaction daily logistic predictor",
            "identifier": daily["version"], "binary_sha256": sha(root / "assets/ml/daily_injury_logistic_model.json"),
            "runtime_path": "assets/ml/daily_injury_logistic_model.json",
            "provenance": daily["source"], "input": f"{len(daily['features'])} normalized daily-window features",
            "output": "Follow-up probability/tier", "training_class": "Template coefficients",
            "authority": "Research-follow-up template only", "fallback": "Insufficient rows/unavailable outcome; no prediction claim",
            "limitations": daily["trainingStatus"]["reason"],
            "citation": "assets/ml/daily_injury_logistic_model.json; docs/logistic-regression-theory-review-20260607.md",
        },
        {
            "role_id": "recommendations", "component": "Recommendation rules/catalog",
            "identifier": f"Source rules at {COMMIT[:12]}", "binary_sha256": "N/A",
            "runtime_path": "lib/core/services/risk_recommendation_service.dart",
            "provenance": "Researcher/source-controlled deterministic rules and bilingual strings",
            "input": "Activity, overall risk, body-part risks", "output": "Categorized bilingual recommendations",
            "training_class": "Not trained; researcher/source-defined", "authority": "Advisory guidance",
            "fallback": "Deduplicate; maximum two per category; base activity recommendations retained",
            "limitations": "Researcher approval and reference-to-message review pending",
            "citation": "lib/core/services/risk_recommendation_service.dart",
        },
        {
            "role_id": "economic_impact", "component": "Economic-impact calculations",
            "identifier": f"Source formulas at {COMMIT[:12]}", "binary_sha256": "N/A",
            "runtime_path": "lib/core/services/economic_impact_service.dart",
            "provenance": "Source-controlled calculation layer", "input": "Risk, income, body-part risks",
            "output": "Estimated impact and before/after comparison", "training_class": "Not trained; deterministic",
            "authority": "Contextual estimate only", "fallback": "Default income if missing as encoded in source",
            "limitations": "Not clinical, actuarial, or accounting validation; assumptions require owner/researcher review",
            "citation": "lib/core/services/economic_impact_service.dart; lib/core/models/economic_impact_models.dart",
        },
        {
            "role_id":"legacy_logistic_weights", "component":"Legacy REBA logistic artifact", "identifier":manifest["version"],
            "binary_sha256":sha(root / "assets/models/logistic_weights.json"), "runtime_path":"assets/models/logistic_weights.json",
            "provenance":"Historical project artifact retained for research traceability", "input":"Legacy engineered pose features", "output":"Legacy advisory probability",
            "training_class":"Legacy project-trained; test/report traceability", "authority":"No current assessment authority", "fallback":"Current REBA/ISO plus XGBoost advisory",
            "limitations":"Not packaged as a Flutter asset and not referenced by the current assessment flow", "citation":"assets/models/model_artifact_manifest.json; lib/core/ergonomics_risk_prediction/data/predictors/logistic_regression_predictor.dart; test/logistic_regression_predictor_test.dart",
            "current_reference_status":"Legacy/test-only; not packaged",
        },
        {
            "role_id":"deprecated_risk_alert", "component":"Deprecated risk-alert model service", "identifier":baseline.get("version", "legacy-risk-alert"),
            "binary_sha256":sha(root / "assets/ml/risk_alert_models.json"), "runtime_path":"assets/ml/risk_alert_models.json",
            "provenance":"Deprecated JSON logistic model retained for compatibility tests", "input":"Legacy assessment feature map", "output":"Legacy risk-alert probabilities",
            "training_class":"Deprecated/test-only model", "authority":"No current assessment authority", "fallback":"Current daily predictor and deterministic assessment flow",
            "limitations":"Test reads the JSON file directly and exercises fromJson; it does not verify rootBundle loading. Asset is absent from pubspec and the current bundle/UI flow", "citation":"lib/core/services/risk_alert_model_service.dart; test/risk_alert_model_service_test.dart; pubspec.yaml",
            "current_reference_status":"Deprecated service; JSON/fromJson test only; absent from current pubspec bundle",
        },
    ]
    for item in inventory:
        item.setdefault("current_reference_status", "Current runtime/source role")

    training_evidence = [
        {
            "evidence_id": "xgboost_training", "component": xgb["version"],
            "dataset_source": xgb["trainingSource"], "total_samples": xgb["totalSampleCount"],
            "training_samples": xgb["trainingSampleCount"], "holdout_samples": xgb["holdoutSampleCount"],
            "unit": "Pose feature rows", "split": "GroupShuffleSplit; default test_size 0.22; random_state 42", "split_method":"GroupShuffleSplit", "test_size":0.22,
            "preprocessing": xgb["featureEngineering"], "features": xgb["featureCount"],
            "labels": xgb["labelSource"], "hyperparameters": "Full XGBRegressor parameters captured from the source-controlled training script",
            "random_seed": 42, "xgb_parameters":{"objective":"reg:squarederror","n_estimators":96,"max_depth":3,"learning_rate":0.055,"subsample":0.88,"colsample_bytree":0.86,"reg_lambda":1.4,"reg_alpha":0.02,"min_child_weight":2,"random_state":42,"n_jobs":1,"tree_method":"hist"},
            "class_handling": json.dumps(xgb["riskDistribution"], sort_keys=True),
            "selection_criteria": "Not recorded as a formal model-selection protocol",
            "holdout_risk_accuracy": xgb["holdout"]["riskAccuracy"],
            "holdout_mae": xgb["holdout"]["combinedRebaEquivalentScoreMae"],
            "evaluation_boundary": "Internal holdout only; high/veryHigh classes only; no external/clinical validation",
            "raw_metrics_status": "Complete" if metrics_path.exists() else "Pending Owner Action",
            "raw_metrics_path": metrics_rel,
            "raw_metrics_note": f"{metrics_rel} is {'present' if metrics_path.exists() else 'not present'} in authoritative baseline",
            "dataset_path":"data/research/extracted/reba_labeled_pose_dataset.csv", "dataset_status":"Complete" if (root / "data/research/extracted/reba_labeled_pose_dataset.csv").exists() else "Pending Researcher Evidence",
            "research_trained": True, "citation": "assets/models/xgboost_model_metadata.json; tools/research_dataset/train_xgboost_onnx_model.py",
        },
        {
            "evidence_id": "daily_logistic_template", "component": daily["version"],
            "dataset_source": "Outcome-labeled seven-transaction dataset unavailable", "total_samples": 0,
            "training_samples": 0, "holdout_samples": 0, "unit": "Seven-transaction farmer window",
            "split": "N/A", "preprocessing": "Feature template encoded in JSON", "features": len(daily["features"]),
            "labels": daily["targetLabel"]["name"], "hyperparameters": "Template coefficients only",
            "random_seed": "N/A", "class_handling": "N/A", "selection_criteria": "N/A",
            "holdout_risk_accuracy": None, "holdout_mae": None,
            "evaluation_boundary": daily["trainingStatus"]["reason"],
            "raw_metrics_status": "Pending Researcher Evidence",
            "raw_metrics_note": "Supply labeled MSD follow-up outcomes, consent/governance evidence, fitted coefficients, and evaluation report",
            "research_trained": False, "citation": "assets/ml/daily_injury_logistic_model.json",
        },
        {
            "evidence_id": "legacy_logistic", "component": manifest["legacyArtifactsNotPackagedInApp"]["logisticRegression"]["path"],
            "dataset_source": "Historical repository artifact", "total_samples": 388,
            "training_samples": 388, "holdout_samples": 0, "unit": "Pose feature rows",
            "split": "Training-set metrics only", "preprocessing": "71 engineered features", "features": 71,
            "labels": "Document-guided/research labels described in artifact", "hyperparameters": "Historical traceability only",
            "random_seed": "Unavailable", "class_handling": "See legacy JSON", "selection_criteria": "Unavailable",
            "holdout_risk_accuracy": None, "holdout_mae": None,
            "evaluation_boundary": "Legacy, not packaged, not used in current REBA/ISO assessment",
            "raw_metrics_status": "N/A with Rationale", "raw_metrics_note": "Not current runtime evidence",
            "research_trained": True, "citation": "assets/models/logistic_weights.json; assets/models/model_artifact_manifest.json",
        },
    ]

    return {
        "version": VERSION, "commit": COMMIT, "tree": TREE, "source_root": str(root),
        "model_algorithm_inventory": inventory, "training_evidence": training_evidence,
        "preference_keys": preference_values,
        "preference_key_symbols": preference_keys,
        "persisted_record_fields": persisted_record_fields,
        "persisted_schema_rows": _persisted_rows(preference_values, persisted_record_fields),
        "data_schema_version": int(schema_match.group(1)) if schema_match else None,
        "all_history_csv_headers": all_history_headers,
        "daily_training_headers": daily_headers,
        "xgboost_feature_headers": xgb["featureNames"],
        "recommendation_messages": _recommendation_messages(recommendation_text),
        "recommendation_triggers": recommendation_triggers,
        "daily_runtime_tiers": [{"high_risk_count":"0-1","level":"Low"},{"high_risk_count":"2-3","level":"Watch"},{"high_risk_count":"4-5","level":"High"},{"high_risk_count":"6-7","level":"Critical"}],
        "daily_probability_thresholds": {"values":daily.get("thresholds", daily.get("riskThresholds", {})), "loaded_by_helper":True, "used_by_predict_for_records":False, "note":"Threshold metadata is loaded and levelFor(probability) exists, but predictForRecords assigns level from _levelForHighRiskCount."},
        "export_schema_rows": _export_schema_rows(all_history_headers),
        "firebase_telemetry": {
            "default_off": True,
            "flag": "SOOKTA_TELEMETRY_ENABLED",
            "wrapper_events": {
                "app_start": ["platform", "build_mode"],
                "assessment_image_added": ["source", "image_count"],
                "assessment_calculated": ["activity", "job_type", "primary_method", "risk_level", "score", "image_count", "uses_iso11228"],
                "assessment_saved": ["activity", "before_risk", "after_risk", "before_score", "after_score", "suggestion_count"],
                "export_created": ["export_type", "record_count"],
            },
            "wrapper_call_sites": {
                "app_start": ["lib/core/services/firebase_telemetry_service.dart"],
                "assessment_image_added": ["lib/screens/main/evaluation_form_screen.dart"],
                "assessment_calculated": ["lib/screens/main/evaluation_form_screen.dart"],
                "assessment_saved": ["lib/screens/main/final_result_screen.dart"],
                "export_created": ["lib/screens/main/final_result_screen.dart", "lib/screens/main/training_data_export_screen.dart"],
            },
            "events": {
                "app_start": ["platform", "build_mode"],
                "assessment_image_added": ["source", "image_count"],
                "assessment_calculated": ["activity", "job_type", "primary_method", "risk_level", "score", "image_count", "uses_iso11228"],
                "assessment_saved": ["activity", "before_risk", "after_risk", "before_score", "after_score", "suggestion_count"],
                "export_created": ["export_type", "record_count"],
                "pose_analysis_failed": ["platform", "error_code"],
            },
            "generic_call_sites": {"pose_analysis_failed": ["platform", "error_code"]},
            "generic_call_site_paths": {"pose_analysis_failed": "lib/screens/main/evaluation_form_screen.dart"},
            "log_app_open": True,
            "analytics_observer_navigation": True,
            "analytics_observer_call_sites": ["lib/app/sookta_app.dart"],
            "observer_note": "FirebaseAnalyticsObserver can emit SDK-generated navigation/screen analytics; event names/payload are controlled by the Firebase SDK and are not explicitly enumerated in repository source.",
            "crashlytics_context": True,
            "note": "When enabled, explicit logEvent calls send sanitized parameters to Analytics and log the same context to Crashlytics. logAppOpen and observer-generated screen/navigation analytics are separate SDK paths.",
        },
        "reference_sources": refs["sources"], "reference_copyright_note": refs["copyrightNote"],
        "daily_model": daily, "baseline_surrogate": baseline,
        "source_citations": [
            _resolve(root, p) for p in [
                "lib/core/services/ergo_calculator.dart",
                "lib/core/services/risk_recommendation_service.dart",
                "lib/core/services/daily_injury_prediction_service.dart",
                "lib/core/services/multi_person_pose_detector.dart",
                "lib/screens/main/evaluation_form_screen.dart",
                "lib/screens/main/final_result_screen.dart",
                "lib/screens/main/training_data_export_screen.dart",
                "lib/app/sookta_app.dart",
                "lib/core/services/firebase_telemetry_service.dart",
                "lib/core/services/economic_impact_service.dart",
                "lib/core/services/assessment_export_service.dart",
                "lib/core/services/training_data_export_service.dart",
                "lib/app/app_state.dart", "lib/core/models/assessment_session.dart",
                "lib/core/models/evaluation_models.dart", "pubspec.yaml",
                "assets/models/xgboost_model_metadata.json",
                "assets/models/model_artifact_manifest.json",
                "assets/ml/daily_injury_logistic_model.json",
                "assets/models/joint_feature_schema.json",
                "assets/models/logistic_weights.json",
                "assets/ml/risk_alert_models.json",
                "lib/core/services/risk_alert_model_service.dart",
                "tools/research_dataset/train_xgboost_onnx_model.py",
                "test/ergo_calculator_test.dart", "test/assessment_export_service_test.dart",
                "test/risk_alert_model_service_test.dart",
                "test/app_state_evaluation_persistence_test.dart",
            ]
        ],
    }


def _add_bullets(doc: Document, items: list[str]) -> None:
    for index, item in enumerate(items):
        # Literal bullets render consistently in both Word and LibreOffice; the
        # built-in list style has merged adjacent wrapped items in PDF output.
        prefix = "\n• " if index else "• "
        paragraph = doc.add_paragraph(f"{prefix}{item}")
        paragraph.paragraph_format.left_indent = Inches(0.22)
        paragraph.paragraph_format.first_line_indent = Inches(-0.16)
        paragraph.paragraph_format.space_after = Pt(4)


def _add_signature_table(doc: Document) -> None:
    table = doc.add_table(rows=1, cols=4)
    table.autofit = False
    widths = [1.45, 1.9, 1.55, 1.6]
    for i, width in enumerate(widths):
        table.columns[i].width = Inches(width)
    headers = ["Role", "Name / signature", "Date", "Status"]
    for i, text in enumerate(headers):
        table.cell(0, i).text = text
    for role in ["Preparer", "Technical reviewer", "Owner", "Researcher"]:
        cells = table.add_row().cells
        values = [role, "________________", "____________", "Complete - Pending Signature"]
        for i, value in enumerate(values):
            cells[i].text = value
    for row in table.rows:
        tr_pr = row._tr.get_or_add_trPr()
        tr_pr.append(OxmlElement("w:cantSplit"))
        for cell in row.cells:
            set_cell_margins(cell)
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.space_before = Pt(0)
                paragraph.paragraph_format.space_after = Pt(0)
                for run in paragraph.runs:
                    run.font.name = "Arial"
                    run.font.size = Pt(8)
        row.cells[0].paragraphs[0].runs[0].bold = True


def build_ai_report(output: Path, facts: dict) -> None:
    doc = Document(); configure_doc(doc)
    add_title(doc, "AI, Algorithm, and Model Technical Report", "Source-grounded specification, evidence limits, and recommendation traceability")
    add_evidence_table(doc, [
        ("Authority", f"SookTa {VERSION}; commit {COMMIT}; tree {TREE}"),
        ("Interpretation boundary", "Software/algorithm verification only; no clinical validation or external validity"),
        ("Current status", "Complete - Pending Signature; human evidence remains explicitly pending"),
    ])
    sections = [
        ("1. Executive technical boundary", [
            "The primary assessment result is deterministic REBA plus applicable ISO 11228 logic. MoveNet supplies pose features. The ONNX XGBoost result is advisory and cannot modify the deterministic score. Daily logistic coefficients are templates pending outcome-labeled research data.",
            "This report does not assert diagnosis, treatment effectiveness, external validity, clinical validation, participant consent, ethics approval, or researcher acceptance.",
        ]),
        ("2. End-to-end assessment workflow", [
            "Capture or select local media; MultiPose counts confident people and rejects the image unless exactly one is eligible; only then MoveNet Thunder estimates 17 pose keypoints. The app derives pose geometry, calculates deterministic REBA and applicable ISO, retains the higher applicable risk, optionally attaches the XGBoost advisory, generates bounded bilingual recommendations, persists locally, and exports only on explicit user action. Evidence: lib/core/services/multi_person_pose_detector.dart; lib/screens/main/evaluation_form_screen.dart; lib/core/services/pose_estimation_service.dart.",
        ]),
        ("3. Model and algorithm role separation", []),
    ]
    for title, paragraphs in sections:
        doc.add_heading(title, level=1)
        for paragraph in paragraphs:
            doc.add_paragraph(paragraph)
    for row in facts["model_algorithm_inventory"]:
        doc.add_heading(row["component"], level=2)
        doc.add_paragraph(f"Role: {row['training_class']} | Authority: {row['authority']} | Identifier: {row['identifier']}")
        doc.add_paragraph(f"Input/output: {row['input']} -> {row['output']}. Runtime: {row['runtime_path']}. SHA-256: {row['binary_sha256']}.")
        doc.add_paragraph(f"Fallback: {row['fallback']}. Limits: {row['limitations']}. Evidence: {row['citation']}.")
    doc.add_heading("4. XGBoost training and evaluation evidence", level=1)
    xgb = facts["training_evidence"][0]
    add_evidence_table(doc, [
        ("Model", xgb["component"]), ("Samples", f"{xgb['total_samples']} total; {xgb['training_samples']} train; {xgb['holdout_samples']} holdout"),
        ("Unit", xgb["unit"]), ("Features", f"{xgb['features']} raw MoveNet features"),
        ("Labels", xgb["labels"]), ("Holdout result", f"risk accuracy {xgb['holdout_risk_accuracy']}; combined REBA-equivalent MAE {xgb['holdout_mae']}"),
        ("Boundary", xgb["evaluation_boundary"]), ("Raw metrics", f"{xgb['raw_metrics_status']}: {xgb['raw_metrics_note']}"),
    ])
    doc.add_paragraph(f"The source-controlled training script uses GroupShuffleSplit(n_splits=1, test_size={xgb['test_size']}, random_state={xgb['random_seed']}) and XGBRegressor parameters {json.dumps(xgb['xgb_parameters'], sort_keys=True)}. Dataset path {xgb['dataset_path']} has status {xgb['dataset_status']}; the distinct raw-metrics path {xgb['raw_metrics_path']} has status {xgb['raw_metrics_status']}. No formal model-selection protocol is evidenced. Citation: tools/research_dataset/train_xgboost_onnx_model.py; assets/models/xgboost_model_metadata.json; assets/models/model_artifact_manifest.json.")
    doc.add_heading("5. Daily logistic training boundary", level=1)
    doc.add_paragraph(facts["daily_model"]["trainingStatus"]["reason"])
    doc.add_paragraph("predictForRecords assigns the displayed daily level from the count of High/Very High before-records in its seven-record window: 0-1 Low, 2-3 Watch, 4-5 High, and 6-7 Critical. The JSON probability thresholds are loaded and a levelFor(probability) helper exists, but predictForRecords does not use those thresholds for its tier. Those thresholds are therefore template/helper metadata, not runtime tier logic. Evidence: lib/core/services/daily_injury_prediction_service.dart; assets/ml/daily_injury_logistic_model.json.")
    doc.add_heading("6. REBA and ISO deterministic specification", level=1)
    _add_bullets(doc, [
        "REBA uses source tables A/B/C, load, coupling and activity modifiers; final risk tiers are Low <=3, Medium <=7, High <=10, Very High >10.",
        "Lifting uses a reference mass by gender and horizontal, vertical, frequency and distance multipliers; lifting index maps to user score/risk.",
        "Push/pull uses the maximum initial/sustained force ratio against encoded gender-specific limits; ratio maps to user score/risk.",
        "The combined result keeps the higher risk and higher user score; source tests are software verification, not standards certification.",
    ])
    doc.add_heading("7. Recommendation logic", level=1)
    doc.add_paragraph("Activity, overall risk, and body-part risk produce posture, risk-reduction, rest/rotation, and workload-support items. Duplicate category/text pairs are removed; no more than two items per category are returned. Risk/activity keys and bilingual messages are source-controlled. Researcher approval of wording and source mapping remains pending.")
    doc.add_heading("8. Failure handling and safety boundaries", level=1)
    _add_bullets(doc, [
        "Unreadable image or unavailable pose does not create a fabricated pose result.",
        "XGBoost unavailable, invalid input, or runtime error suppresses only the advisory output.",
        "Daily logistic requires at least seven transactions and remains a follow-up template.",
        "Remote database/API is N/A with Rationale for the current assessment path; optional default-off Firebase telemetry is separate.",
    ])
    doc.add_heading("8.1 Optional outbound telemetry", level=2)
    doc.add_paragraph("Assessment persistence remains local by default. Firebase telemetry is separately controlled by SOOKTA_TELEMETRY_ENABLED and defaults off. Explicit enabled paths are logAppOpen; app_start(platform, build_mode); assessment_image_added(source, image_count); assessment_calculated(activity, job_type, primary_method, risk_level, score, image_count, uses_iso11228); assessment_saved(activity, before_risk, after_risk, before_score, after_score, suggestion_count); export_created(export_type, record_count); and the generic call site pose_analysis_failed(platform, error_code). Explicit logEvent parameters are sanitized for Analytics and the same context is logged to Crashlytics. FirebaseAnalyticsObserver may additionally generate SDK-defined navigation/screen events whose exact event names/payload are not enumerated by repository source. Evidence: lib/core/services/firebase_telemetry_service.dart; lib/screens/main/evaluation_form_screen.dart.")
    doc.add_heading("9. References and evidence", level=1)
    _add_bullets(doc, [
        f"{source['id']}: {source['title']} | SHA-256 {source['sha256']} | Use: {source['trainingUse']}"
        for source in facts["reference_sources"]
    ])
    doc.add_paragraph(f"Copyright boundary: {facts['reference_copyright_note']}")
    doc.add_heading("10. Human-owned actions", level=1)
    _add_bullets(doc, human_actions())
    doc.add_heading("11. Review and signature", level=1); _add_signature_table(doc)
    output.parent.mkdir(parents=True, exist_ok=True); doc.save(output)


def build_training_statement(output: Path, facts: dict) -> None:
    doc = Document(); configure_doc(doc)
    add_title(doc, "AI Training and Non-Training Technical Statement", "Signature draft defining trained, pretrained, deterministic, template, advisory, and legacy components")
    doc.add_heading("Statement", level=1)
    doc.add_paragraph("Based only on the authoritative repository evidence, the components below are classified without extending their evidence boundary. This draft is technically complete but is not an executed legal, research, or acceptance statement until authorized signatures are supplied.")
    for row in facts["model_algorithm_inventory"]:
        doc.add_heading(row["component"], level=2)
        doc.add_paragraph(f"Classification: {row['training_class']}. Authority: {row['authority']}. Identifier/evidence: {row['identifier']}; {row['citation']}.")
        doc.add_paragraph(f"Limitation: {row['limitations']}")
    doc.add_heading("Prohibited claims", level=1)
    _add_bullets(doc, [
        "Do not state that MoveNet was trained or fine-tuned by this project.",
        "Do not state that XGBoost is clinically validated, externally validated, production-quality, or a replacement for deterministic REBA/ISO.",
        "Do not state that daily logistic template coefficients were fitted to research outcome labels.",
        "Do not state that REBA/ISO implementation constitutes standards certification or clinical diagnosis.",
        "Do not state that participant consent, ethics approval, de-identification, privacy acceptance, or researcher acceptance is complete without signed evidence.",
    ])
    doc.add_heading("Evidence gaps and required actions", level=1); _add_bullets(doc, human_actions())
    doc.add_heading("Document control", level=1)
    add_evidence_table(doc, [("Application", VERSION), ("Commit", COMMIT), ("Tree", TREE), ("Status", "Complete - Pending Signature")])
    doc.add_heading("Signatures", level=1); _add_signature_table(doc)
    output.parent.mkdir(parents=True, exist_ok=True); doc.save(output)


def build_data_manual(output: Path, facts: dict) -> None:
    doc = Document(); configure_doc(doc)
    add_title(doc, "Local Storage and Data Management Manual", "Operational guide for profiles, assessments, local files, schema migration, export, privacy, and recovery")
    doc.add_heading("1. Architecture and applicability", level=1)
    doc.add_paragraph("Profiles, active-profile selection, setup state, history, drafts, schema version, and the latest pre-migration backup are serialized in SharedPreferences. Captured media is copied into application documents. CSV exports are generated in application documents and shared only after explicit user selection. Temporary decoded/video frames use temporary storage.")
    add_evidence_table(doc, [("Schema version", str(facts["data_schema_version"])), ("Preference keys", str(len(facts["preference_keys"]))), ("Remote database", "N/A with Rationale - no remote assessment database or server schema in source"), ("Cloud backup", "N/A with Rationale - no assessment cloud-backup path in source"), ("Telemetry", "Optional Firebase telemetry, default off; separate from assessment persistence")])
    doc.add_paragraph()
    doc.add_heading("2. Identifiers and active profile behavior", level=1)
    doc.add_paragraph("Each farmer profile uses profileId; farmerId is a research-facing identifier field. activeProfileId chooses the current profile. Legacy single-profile data may be adopted into the profile list; history and draft lookups use the profile identifier. Deleting a farmer removes the profile entry and selects the first remaining profile, but source behavior does not prove automatic deletion of all historical records or copied media for that identifier.")
    doc.add_heading("3. Drafts, history, and image linkage", level=1)
    _add_bullets(doc, [
        "Drafts are keyed per profile/activity and sorted by savedAt; selected media paths are copied before draft persistence.",
        "History records retain before/after scores, risk, recommendations, breakdowns, optional advisory data, research placeholders, media paths, and timestamps as encoded by model serializers.",
        "Local image paths are sensitive linkage metadata. A file path is not image content, but can reveal device/application structure and connect a record to participant media.",
    ])
    doc.add_heading("4. Schema version and migration", level=1)
    doc.add_paragraph("The current SharedPreferences schema version is 2. Restore creates a latestBackup snapshot before migration and adopts legacy profile/draft data when present. The code resets in-memory state on an unhandled restore error. Migration verification must preserve a real backup and test representative prior schemas before release.")
    doc.add_heading("5. CSV generation and share flow", level=1)
    doc.add_paragraph(f"The all-history research export defines {len(facts['all_history_csv_headers'])} ordered columns. Assessment, single-history, all-history, daily-logistic training, and XGBoost pose-training exports are local CSV files. DateTime.now().toIso8601String() supplies generated timestamps. CSV quoting escapes embedded quotes. The application invokes the OS share flow only after a file is created.")
    doc.add_heading("6. Validation, duplicates, missing values, and time", level=1)
    _add_bullets(doc, [
        "Numeric profile inputs are parsed best-effort; missing/invalid values remain blank, null, zero, or '-' depending on the specific source field. The Data Dictionary records field-level behavior.",
        "No general duplicate-participant detector is evidenced. History IDs advance from nextHistoryId and are corrected above the maximum restored ID; duplicate semantic assessments remain possible.",
        "Timestamps use ISO 8601 strings from the device clock. The code does not normalize all values to UTC; timezone offset presence depends on the DateTime instance/device behavior.",
        "Recommendation output deduplicates category/text pairs, but this is not a database deduplication rule.",
    ])
    doc.add_heading("7. Backup, restore, retention, and deletion", level=1)
    _add_bullets(doc, [
        "Before schema migration, the current preference payload is retained under sookta.latestBackup; this is an application-local migration safeguard, not a complete disaster-recovery backup.",
        "There is no evidenced automatic remote backup, remote retention policy, or server restore procedure: N/A with Rationale.",
        "User/owner must define research retention periods, secure export destinations, device decommissioning, backup custody, and participant-media deletion evidence.",
        "Delete actions must be verified across preference records, copied image files, local CSV exports, OS-shared copies, and any external research repository; source does not prove end-to-end erasure.",
    ])
    doc.add_heading("7.1 Optional Firebase telemetry", level=2)
    doc.add_paragraph("Local assessment persistence is the default. SOOKTA_TELEMETRY_ENABLED defaults false. When enabled, explicit paths include logAppOpen; app_start(platform, build_mode); assessment_image_added(source, image_count); assessment_calculated(activity, job_type, primary_method, risk_level, score, image_count, uses_iso11228); assessment_saved(activity, before_risk, after_risk, before_score, after_score, suggestion_count); export_created(export_type, record_count); and generic pose_analysis_failed(platform, error_code). Crashlytics receives the same sanitized context for explicit logEvent calls. FirebaseAnalyticsObserver can separately generate SDK-defined navigation/screen analytics; repository source does not enumerate those exact SDK payloads. Owner approval, Firebase-project custody, disclosure, and retention remain Pending Owner Action. Evidence: lib/core/services/firebase_telemetry_service.dart; lib/screens/main/evaluation_form_screen.dart.")
    doc.add_heading("8. Error and failure recovery", level=1)
    _add_bullets(doc, [
        "Restore failure clears in-memory restored state and continues hydrated; investigate rather than treating a reset screen as proof of deletion.",
        "Image copy failure or missing path must remain visible to the workflow; never substitute participant media.",
        "Export failures should leave the original local data unchanged; inspect application/device logs without copying secrets or participant media into public evidence.",
    ])
    doc.add_heading("9. Privacy classes and responsibilities", level=1)
    _add_bullets(doc, [
        "Direct identifiers: name, farmer/participant code, profile identifier, avatar/media linkage.",
        "Sensitive research/health-adjacent data: age, gender, BMI inputs, MSD symptom/outcome placeholders, expert assessment fields, ergonomic risk and recommendations.",
        "Operational metadata: application version, schema version, timestamps, status/error fields, device-local paths.",
        "Users must share only to an approved destination. Owner/researcher must approve consent, lawful basis, access, retention, de-identification/pseudonymization, deletion, and breach procedures.",
    ])
    doc.add_heading("10. Evidence and human actions", level=1)
    doc.add_paragraph("Evidence: lib/app/app_state.dart; lib/core/models/assessment_session.dart; lib/core/models/evaluation_models.dart; lib/core/services/local_image_store.dart; lib/core/services/assessment_export_service.dart; lib/core/services/training_data_export_service.dart; test/app_state_evaluation_persistence_test.dart; test/assessment_export_service_test.dart.")
    _add_bullets(doc, human_actions())
    doc.add_heading("11. Review and signature", level=1); _add_signature_table(doc)
    output.parent.mkdir(parents=True, exist_ok=True); doc.save(output)


def human_actions() -> list[str]:
    return [
        "Pending Owner Action: approve model/recommendation authority, scope, privacy disclosures, retention/deletion, and production use boundaries.",
        "Pending Researcher Evidence: supply governed outcome labels, participant/annotation units, consent/ethics and de-identification evidence where applicable, and researcher-approved evaluation criteria.",
        "Pending Owner Action: provide the missing raw XGBoost metrics artifact or approve the metadata-only evidence limitation; rerun training with recorded seed/configuration if reproducibility is required.",
        "Pending Researcher Evidence: review REBA/ISO reference mapping, project safety floors, bilingual recommendation wording, dataset label provenance, and limitations.",
        "Pending Owner Action: define backup/restore, secure export destination, access control, retention schedule, end-to-end deletion, and incident response procedures.",
        "Complete - Pending Signature: preparer, technical reviewer, owner, and researcher signature/date blocks.",
    ]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--staging", type=Path, default=STAGING)
    args = parser.parse_args()
    facts = inspect_source(args.source)
    if facts["version"] != VERSION:
        raise SystemExit("Baseline mismatch")
    working = args.staging / "working/task5"
    artifacts = args.staging / "artifacts"
    manifests = args.staging / "manifests"
    for path in [working, artifacts, manifests]:
        path.mkdir(parents=True, exist_ok=True)
    build_ai_report(working / "04_AI_Algorithm_and_Model_Technical_Report.raw.docx", facts)
    build_training_statement(working / "04_AI_Training_and_Non_Training_Statement.raw.docx", facts)
    build_data_manual(working / "05_Local_Storage_and_Data_Management_Manual.raw.docx", facts)
    payload = {**facts, "algorithm_workbook_sheets": ALGORITHM_WORKBOOK_SHEETS,
               "data_workbook_sheets": DATA_WORKBOOK_SHEETS,
               "human_actions": human_actions()}
    (working / "task5_build_input.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "documents": 3, "model_algorithm_roles": len(facts["model_algorithm_inventory"]),
        "training_evidence_records": len(facts["training_evidence"]),
        "preference_keys": len(facts["preference_keys"]),
        "all_history_headers": len(facts["all_history_csv_headers"]),
        "recommendation_messages": len(facts["recommendation_messages"]),
    }, indent=2))


if __name__ == "__main__":
    main()
