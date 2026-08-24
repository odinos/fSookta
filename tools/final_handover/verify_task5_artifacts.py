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
    return {"dart_fields":dart_fields,"serialized_fields":serialized_fields,"trend_levels":trend_levels,"telemetry_events":telemetry_events,"telemetry_call_sites":telemetry_call_sites,"generic_call_site_paths":{"pose_analysis_failed":generic_path},"log_app_open":True,"analytics_observer":True,"analytics_observer_call_sites":observer_paths,"xgb":xgb}


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
    assert len(facts["export_schema_rows"]) == 84
    assert len(facts["persisted_schema_rows"]) > len({r["field"] for r in facts["persisted_schema_rows"]})
    persisted_pairs = {(row["owner"], row["field"]) for row in facts["persisted_schema_rows"]}
    assert independent["serialized_fields"].issubset(persisted_pairs)
    assert "sookta.backup.schema.<version>.<timestamp>" in facts["preference_keys"]
    assert all(r["description"] and r["type"] and r["validation"] and "source-defined" not in r["type"].lower() for r in facts["export_schema_rows"])
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
    trend = next(row for row in facts["export_schema_rows"] if row["field"] == "trend_level")
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
    # Compare workbook cells against an independent Dart declaration scan.
    data_check = load_workbook(required[8], read_only=True, data_only=False)
    persisted_sheet = data_check["Persisted Keys Records"]
    persisted_headers = [cell.value for cell in persisted_sheet[4]]
    pidx = {name:index for index,name in enumerate(persisted_headers)}
    persisted_values = list(persisted_sheet.iter_rows(min_row=5, values_only=True))
    for owner, field, expected_type in [
        ("EvaluationHistoryRecord","id","int"), ("EvaluationHistoryRecord","timeOnTaskSeconds","int?"),
        ("EvaluationDraft","selectedImagePaths","List<String>"), ("RebaInputData","trunkTwist","bool"),
        ("PoseRebaFrameAnalysis","imageIndex","int"), ("PoseRebaFrameAnalysis","timestampMs","int?"),
        ("AssessmentBreakdown","isoMethod","AssessmentMethod?"), ("AssessmentBreakdown","isoResult","ErgoResult?"),
        ("AssessmentBreakdown","xgboostProbability","double?"), ("ErgoResult","techScore","double"),
    ]:
        assert independent["dart_fields"][(owner,field)] == expected_type
        matches = [row for row in persisted_values if row[0] == field and owner in str(row[pidx["Persisted location / key"]])]
        assert len(matches) == 1, (owner,field,len(matches))
        assert matches[0][pidx["Type"]] == expected_type
        assert matches[0][pidx["Nullable"]] == ("Yes" if expected_type.endswith("?") else "No")
    training_sheet = load_workbook(required[2], read_only=True, data_only=False)["Training Evaluation"]
    training_headers = [cell.value for cell in training_sheet[4]]
    tidx = {name:index for index,name in enumerate(training_headers)}
    xgb_row = next(row for row in training_sheet.iter_rows(min_row=5, values_only=True) if row[0] == "xgboost_training")
    assert xgb_row[tidx["Split method"]] == "GroupShuffleSplit"
    assert xgb_row[tidx["Test size"]] == 0.22 and xgb_row[tidx["Seed"]] == 42
    assert xgb_row[tidx["Dataset status"]] == "Pending Researcher Evidence"
    assert xgb_row[tidx["Raw metrics status"]] == "Pending Owner Action"
    for token in ["n_estimators", "tree_method", "reg_lambda", "min_child_weight"]: assert token in xgb_row[tidx["XGBRegressor parameters"]]
    data_check.close()
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
