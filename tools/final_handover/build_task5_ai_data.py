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
from docx.enum.text import WD_BREAK
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
    """Classify whole field tokens; do not let `language` match `age`."""
    key = field.lower()
    sensitive_exact = {"name", "age", "gender", "weight", "height", "bmi", "farmerid", "profileid", "farmer_id", "user_id", "participant_code"}
    health_tokens = ("risk", "score", "reba", "iso", "msd", "medical", "expert", "symptom", "economic", "impact", "productivity", "lostwork", "lost_work", "pose", "joint")
    media_tokens = ("photo", "image", "avatar")
    if key == "sookta.history":
        return "Sensitive research/health-adjacent"
    if key in sensitive_exact or any(token in key for token in media_tokens):
        return "Sensitive participant/profile data"
    if any(token in key for token in health_tokens):
        return "Sensitive research/health-adjacent"
    if owner and any(token in owner.lower() for token in ("evaluation", "assessment", "research")):
        return "Assessment/research data"
    return "Operational metadata"


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
        dtype, allowed, unit = _semantic_type(field)
        optional_tokens = ("optional", "after", "expert", "msd", "medical", "photo", "image", "avatar", "comments", "notes", "iso", "feedback", "path", "location")
        nullable = "Yes" if any(token in field.lower() for token in optional_tokens) else "No"
        readable = re.sub(r"(?<!^)(?=[A-Z])", " ", field).replace("_", " ").strip().lower()
        rows.append({
            "field": field, "owner": owner, "description": f"Persisted {readable} value owned by {owner}",
            "type": dtype, "nullable": nullable,
            "allowed": allowed, "unit": unit, "source": owner, "derivation": f"Serialized by {owner}.toJson and restored by {owner}.fromJson",
            "missing": "null/blank preserved" if nullable == "Yes" else "Required or restored from the constructor/fromJson default", "privacy": _privacy(field, owner),
            "persisted_location": f"Owning {owner} JSON under AppState profile/draft/history preferences",
            "export_location": "Mapped only where assessment_export_service.dart declares a column", "synthetic_example": "synthetic_value",
            "validation": f"Validate against {owner} constructor/fromJson and source enum/range before use", "version": VERSION, "evidence": source,
        })
    return rows


def _export_schema_rows(headers: list[str]) -> list[dict]:
    descriptions = {
        "Export Generated At":"Timestamp when the all-history export file was generated", "export_schema_version":"Export schema identifier", "assessment_reference_sources":"Reference-source identifiers attached to the export", "assessment_scope_note":"Scope and evidence-boundary note", "calculation_standard_note":"REBA/ISO calculation-method note",
        "Record ID":"Application history record identifier", "App Version":"Application version saved with the assessment", "Farmer ID":"Research-facing farmer identifier", "Name":"Farmer display name", "Role":"Farmer role", "Work Space":"Recorded work-space/location text", "Age":"Farmer age", "Gender":"Farmer gender used by applicable calculations", "Weight (kg)":"Farmer body weight", "Height (cm)":"Farmer height", "BMI":"Body-mass index derived from weight and height", "BMI Category":"BMI category derived by the application", "Date of data entry":"Assessment record date and time", "Activity Stage":"Agricultural activity enum/display label", "Specific Task":"Specific task text", "Posture Description":"Observed posture description", "REBA Score":"Before-intervention deterministic REBA score", "ISO 11228 Risk Level":"Before-intervention ISO 11228 risk level when applicable", "Tool Used":"Selected tool name", "Tool Weight (kg)":"Tool weight", "Tool Weight Code":"Encoded tool-weight category", "Manual Handling Weight (kg)":"Manually handled load", "Manual Handling Distance (m)":"Manual-handling travel distance", "Frequency per hour":"Task/lift frequency per hour", "Duration (minutes)":"Task duration", "Work days per week":"Work frequency by days per week", "MSD Symptom Location":"Research MSD symptom location", "MSD Symptom Severity":"Research MSD symptom severity", "Medical Cost (THB)":"Direct medical cost captured for research", "Lost Workdays":"Lost workdays captured for research", "Productivity Loss (THB)":"Productivity loss captured for research", "Before Score":"Before-intervention user score", "After Score":"After-intervention user score", "Before Risk":"Before-intervention combined risk tier", "After Risk":"After-intervention combined risk tier", "Before Impact (THB)":"Estimated economic impact before recommendations", "After Impact (THB)":"Estimated economic impact after recommendations", "Estimated Saved (THB)":"Estimated impact reduction", "Economic Impact Formula":"Human-readable economic-impact formula/assumption", "User Feedback Notes":"User/research feedback notes",
        "transaction_id":"Stable transaction/history identifier", "user_id":"Profile/farmer identifier associated with the transaction", "assessment_date":"Assessment calendar date", "assessment_time":"Assessment local time", "task_type":"Activity/task type", "REBA_before":"Before-intervention REBA score", "REBA_risk_before":"Before-intervention REBA risk tier", "ISO_before":"Before-intervention ISO user score when applicable", "ISO_risk_before":"Before-intervention ISO risk tier when applicable", "load_before":"Before-intervention handled/tool load", "frequency_before":"Before-intervention frequency per hour", "duration_before":"Before-intervention duration", "REBA_after":"After-intervention REBA score", "REBA_risk_after":"After-intervention REBA risk tier", "ISO_after":"After-intervention ISO user score when applicable", "ISO_risk_after":"After-intervention ISO risk tier when applicable", "REBA_reduction":"Absolute REBA score reduction", "REBA_reduction_percent":"REBA reduction divided by before score", "trend_REBA_average":"Average before REBA score in the trend window", "trend_REBA_maximum":"Maximum before REBA score in the trend window", "trend_high_risk_count":"Count of high/very-high before records in the trend window", "trend_level":"Daily trend level derived from high-risk count", "trend_direction":"Direction of the recent REBA trend", "neck_risk":"Neck body-part risk tier", "shoulder_risk":"Shoulder/arm body-part risk tier", "upper_limb_risk":"Upper-limb body-part risk tier", "wrist_risk":"Wrist body-part risk tier", "back_risk":"Back/trunk body-part risk tier", "knee_risk":"Knee/leg body-part risk tier", "photo_id":"Research photo identifier", "photo_timestamp":"Photo capture/association timestamp", "time_on_task_seconds":"Research time-on-task duration", "completion_status":"Research workflow completion status", "assistance_required":"Whether assistance was required", "error_count":"Research workflow error count", "expert_REBA":"Expert comparator REBA score", "expert_risk_level":"Expert comparator risk tier", "expert_assessment_date":"Expert assessment timestamp", "expert_comments":"Expert comparator comments",
    }
    score_fields = {"REBA Score","Before Score","After Score","REBA_before","REBA_after","expert_REBA","trend_REBA_average","trend_REBA_maximum","ISO_before","ISO_after"}
    date_fields = {"Export Generated At","Date of data entry","assessment_date","assessment_time","photo_timestamp","expert_assessment_date"}
    required = {"Export Generated At","export_schema_version","Record ID","transaction_id","REBA_before","REBA_risk_before"}
    rows=[]
    for index, field in enumerate(headers, 1):
        dtype, allowed, unit = _semantic_type(field)
        if field in score_fields:
            dtype, allowed, unit = "integer or decimal number", "REBA 1..15 where REBA; ISO/application score >= 0", "score points"
        if field in date_fields:
            dtype, allowed, unit = "ISO-8601 text", "ISO-8601 date/date-time text", "N/A"
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
        elif field == "trend_level": derivation = "0-1 Low; 2-3 Watch; 4-5 High; 6-7 Critical by high-risk record count"
        example = "'2026-08-24T09:00:00+07:00" if field in date_fields else (6 if field in score_fields else f"SYN-{index:03d}" if "ID" in field or field.endswith("_id") else "synthetic_value")
        rows.append({"field":field,"description":descriptions[field],"type":dtype,"nullable":"No" if field in required else "Yes","allowed":allowed,"unit":unit,"source":source,"derivation":derivation,"missing":"Blank string for unavailable optional export value; '-' only where the source explicitly emits it","privacy":_privacy(field),"persisted_location":persisted,"export_location":f"{index}: {field}","synthetic_example":example,"validation":"Preserve exact column order, type/range, applicability and source blank behavior","version":VERSION,"evidence":"lib/core/services/assessment_export_service.dart"})
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
    persisted_record_fields: list[dict] = []
    seen_record_fields: set[tuple[str, str, str]] = set()
    for relative in record_sources:
        text = (root / relative).read_text(encoding="utf-8")
        class_matches = list(re.finditer(r"(?m)^class\s+(\w+)", text))
        for index, class_match in enumerate(class_matches):
            owner = class_match.group(1)
            end = class_matches[index + 1].start() if index + 1 < len(class_matches) else len(text)
            section = text[class_match.start():end]
            for _, field in re.findall(r"(?m)^\s{4,12}(['\"])([^'\"]+)\1\s*:", section):
                identity = (owner, field, relative)
                if identity not in seen_record_fields:
                    persisted_record_fields.append({"owner": owner, "field": field, "source": relative})
                    seen_record_fields.add(identity)
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
            "identifier": "Bundled multipose fallback; upstream release/version not recorded in repository metadata",
            "binary_sha256": sha(root / "assets/ml/movenet_multipose_lightning.tflite"),
            "runtime_path": "assets/ml/movenet_multipose_lightning.tflite",
            "provenance": "Bundled pretrained TensorFlow Lite asset",
            "input": "Image tensor", "output": "Candidate poses/keypoints",
            "training_class": "Pretrained; not fine-tuned in project", "authority": "Single-person eligibility gate",
            "fallback": "Reject unless exactly one confident person; Thunder estimates pose only after gate passes", "limitations": "Counts eligible people; does not supply the assessment pose",
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
            "limitations":"Asset load is evidenced by the legacy service test, not the current UI flow", "citation":"lib/core/services/risk_alert_model_service.dart; test/risk_alert_model_service_test.dart",
            "current_reference_status":"Deprecated service; test-only asset load",
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
        "firebase_telemetry": {"default_off":True,"flag":"SOOKTA_TELEMETRY_ENABLED","events":{"app_start":["platform","build_mode"],"assessment_image_added":["source","image_count"],"assessment_calculated":["activity","job_type","primary_method","risk_level","score","image_count","uses_iso11228"],"assessment_saved":["activity","before_risk","after_risk","before_score","after_score","suggestion_count"],"export_created":["export_type","record_count"]},"crashlytics_context":True,"note":"When enabled, safe event parameters go to Analytics and the same event/key-value context is logged to Crashlytics."},
        "reference_sources": refs["sources"], "reference_copyright_note": refs["copyrightNote"],
        "daily_model": daily, "baseline_surrogate": baseline,
        "source_citations": [
            _resolve(root, p) for p in [
                "lib/core/services/ergo_calculator.dart",
                "lib/core/services/risk_recommendation_service.dart",
                "lib/core/services/daily_injury_prediction_service.dart",
                "lib/core/services/multi_person_pose_detector.dart",
                "lib/screens/main/evaluation_form_screen.dart",
                "lib/core/services/firebase_telemetry_service.dart",
                "lib/core/services/economic_impact_service.dart",
                "lib/core/services/assessment_export_service.dart",
                "lib/core/services/training_data_export_service.dart",
                "lib/app/app_state.dart", "lib/core/models/evaluation_models.dart",
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
        for cell in row.cells:
            set_cell_margins(cell)
            for run in cell.paragraphs[0].runs:
                run.font.name = "Arial"
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
    doc.add_paragraph(f"The source-controlled training script uses GroupShuffleSplit(n_splits=1, test_size={xgb['test_size']}, random_state={xgb['random_seed']}) and XGBRegressor parameters {json.dumps(xgb['xgb_parameters'], sort_keys=True)}. The configured dataset path {xgb['dataset_path']} is {xgb['dataset_status']}; the separate raw metrics path is {xgb['raw_metrics_status']}. No formal model-selection protocol is evidenced. Citation: tools/research_dataset/train_xgboost_onnx_model.py; assets/models/xgboost_model_metadata.json.")
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
    doc.add_paragraph("Assessment persistence remains local by default. Firebase telemetry is separately controlled by SOOKTA_TELEMETRY_ENABLED and defaults off. If enabled, outbound Analytics events/fields are: app_start(platform, build_mode); assessment_image_added(source, image_count); assessment_calculated(activity, job_type, primary_method, risk_level, score, image_count, uses_iso11228); assessment_saved(activity, before_risk, after_risk, before_score, after_score, suggestion_count); export_created(export_type, record_count). The same safe event key/value context is logged to Crashlytics. Evidence: lib/core/services/firebase_telemetry_service.dart.")
    doc.add_heading("9. References and evidence", level=1)
    _add_bullets(doc, [
        f"{source['id']}: {source['title']} | SHA-256 {source['sha256']} | Use: {source['trainingUse']}"
        for source in facts["reference_sources"]
    ])
    doc.add_paragraph(f"Copyright boundary: {facts['reference_copyright_note']}")
    doc.add_page_break()
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
    doc.add_paragraph("Local assessment persistence is the default. SOOKTA_TELEMETRY_ENABLED defaults false. When an owner enables it, Firebase Analytics receives app_start(platform, build_mode), assessment_image_added(source, image_count), assessment_calculated(activity, job_type, primary_method, risk_level, score, image_count, uses_iso11228), assessment_saved(activity, before_risk, after_risk, before_score, after_score, suggestion_count), and export_created(export_type, record_count). Crashlytics receives the same sanitized event/key-value context. Owner approval, Firebase-project custody, disclosure, and retention remain Pending Owner Action. Evidence: lib/core/services/firebase_telemetry_service.dart.")
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
