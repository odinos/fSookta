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
    persisted_record_fields: dict[str, str] = {}
    for relative in record_sources:
        text = (root / relative).read_text(encoding="utf-8")
        # Dart map literals in the persistence models are the executable schema.
        # Preserve first ownership when a field is reused by a nested value object.
        for _, field in re.findall(r"(?m)^\s{4,8}(['\"])([^'\"]+)\1\s*:", text):
            persisted_record_fields.setdefault(field, relative)
    xgb_artifact = manifest["artifacts"]["xgboost"]
    metrics_rel = xgb_artifact["metricsPath"]
    metrics_path = root / metrics_rel
    preference_keys = dict(re.findall(r"static const (_\w+Key)\s*=\s*'([^']+)'", app_state))
    schema_match = re.search(r"_currentDataSchemaVersion\s*=\s*(\d+)", app_state)
    all_history_headers = _all_history_headers(export_text)
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
            "training_class": "Pretrained; not fine-tuned in project", "authority": "Pose fallback",
            "fallback": "Thunder/manual path", "limitations": "Upstream artifact release unavailable; multi-person ambiguity",
            "citation": "lib/core/services/pose_estimation_service.dart",
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
    ]

    training_evidence = [
        {
            "evidence_id": "xgboost_training", "component": xgb["version"],
            "dataset_source": xgb["trainingSource"], "total_samples": xgb["totalSampleCount"],
            "training_samples": xgb["trainingSampleCount"], "holdout_samples": xgb["holdoutSampleCount"],
            "unit": "Pose feature rows", "split": "298 train / 90 holdout (method and seed not recorded in metadata)",
            "preprocessing": xgb["featureEngineering"], "features": xgb["featureCount"],
            "labels": xgb["labelSource"], "hyperparameters": "See source-controlled training script; exact run config not fully serialized in metadata",
            "random_seed": "Unavailable in exported metadata; inspect training script before reproduction",
            "class_handling": json.dumps(xgb["riskDistribution"], sort_keys=True),
            "selection_criteria": "Not recorded as a formal model-selection protocol",
            "holdout_risk_accuracy": xgb["holdout"]["riskAccuracy"],
            "holdout_mae": xgb["holdout"]["combinedRebaEquivalentScoreMae"],
            "evaluation_boundary": "Internal holdout only; high/veryHigh classes only; no external/clinical validation",
            "raw_metrics_status": "Complete" if metrics_path.exists() else "Pending Owner Action",
            "raw_metrics_note": f"{metrics_rel} is {'present' if metrics_path.exists() else 'not present'} in authoritative baseline",
            "research_trained": True, "citation": "assets/models/xgboost_model_metadata.json",
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
        "preference_keys": sorted(preference_keys.values()),
        "preference_key_symbols": preference_keys,
        "persisted_record_fields": [
            {"field": field, "source": persisted_record_fields[field]}
            for field in sorted(persisted_record_fields)
        ],
        "data_schema_version": int(schema_match.group(1)) if schema_match else None,
        "all_history_csv_headers": all_history_headers,
        "daily_training_headers": daily_headers,
        "xgboost_feature_headers": xgb["featureNames"],
        "recommendation_messages": _recommendation_messages(recommendation_text),
        "reference_sources": refs["sources"], "reference_copyright_note": refs["copyrightNote"],
        "daily_model": daily, "baseline_surrogate": baseline,
        "source_citations": [
            _resolve(root, p) for p in [
                "lib/core/services/ergo_calculator.dart",
                "lib/core/services/risk_recommendation_service.dart",
                "lib/core/services/assessment_export_service.dart",
                "lib/core/services/training_data_export_service.dart",
                "lib/app/app_state.dart", "lib/core/models/evaluation_models.dart",
                "assets/models/xgboost_model_metadata.json",
                "assets/models/model_artifact_manifest.json",
                "assets/ml/daily_injury_logistic_model.json",
                "assets/models/joint_feature_schema.json",
                "test/ergo_calculator_test.dart", "test/assessment_export_service_test.dart",
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
            "Capture or select local media; preprocess and letterbox locally; run bundled MoveNet; reject unreadable/low-confidence pose input; derive pose geometry; calculate deterministic REBA and applicable ISO; retain the higher applicable risk; optionally attach XGBoost advisory; generate bounded bilingual recommendations; persist locally; export only on explicit user action.",
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
    doc.add_paragraph("No formal model-selection protocol, full run configuration, or random seed is serialized in the final metadata. The available source-controlled training script must be reviewed and rerun before reproducibility or quality acceptance is claimed.")
    doc.add_heading("5. Daily logistic training boundary", level=1)
    doc.add_paragraph(facts["daily_model"]["trainingStatus"]["reason"])
    doc.add_paragraph("The encoded probability equation and thresholds are operational template behavior, not evidence that coefficients were fitted to participant outcomes. A research team must supply governed labels, fit the coefficients, define the split/seed/class handling, evaluate the model, and approve use.")
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
    doc.add_page_break()
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
