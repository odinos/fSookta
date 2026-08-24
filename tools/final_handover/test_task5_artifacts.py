#!/usr/bin/env python3
"""Behavior-first tests for Task 5 AI and data handover artifacts."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_task5_ai_data as builder
import record_task5_visual_qa as recorder
import verify_task5_artifacts as verifier
from docx import Document


SOURCE = Path(
    "/private/tmp/fsookta-final-handover/authoritative-materializations/"
    "source-g6tsggy7/source"
)


class SourceGroundingTests(unittest.TestCase):
    def test_inventory_separates_current_legacy_and_test_only_roles(self) -> None:
        facts = builder.inspect_source(SOURCE)
        roles = {row["role_id"]: row for row in facts["model_algorithm_inventory"]}
        self.assertEqual(len(roles), 10)
        self.assertEqual(roles["xgboost_onnx"]["training_class"], "Project-trained")
        self.assertEqual(roles["daily_logistic"]["training_class"], "Template coefficients")
        self.assertEqual(roles["movenet_thunder"]["training_class"], "Pretrained; not fine-tuned in project")
        self.assertEqual(roles["reba"]["authority"], "Primary deterministic")
        self.assertEqual(roles["xgboost_onnx"]["authority"], "Advisory only")
        self.assertEqual(roles["movenet_multipose"]["authority"], "Single-person eligibility gate")
        self.assertIn("evaluation_form_screen.dart", roles["movenet_multipose"]["citation"])
        self.assertEqual(roles["legacy_logistic_weights"]["current_reference_status"], "Legacy/test-only; not packaged")
        self.assertEqual(roles["deprecated_risk_alert"]["current_reference_status"], "Deprecated service; test-only asset load")
        self.assertEqual(len(roles["legacy_logistic_weights"]["binary_sha256"]), 64)
        self.assertEqual(len(roles["deprecated_risk_alert"]["binary_sha256"]), 64)

    def test_training_evidence_preserves_holdout_limits_and_missing_raw_metrics(self) -> None:
        facts = builder.inspect_source(SOURCE)
        evidence = {row["evidence_id"]: row for row in facts["training_evidence"]}
        xgb = evidence["xgboost_training"]
        self.assertEqual(xgb["total_samples"], 388)
        self.assertEqual(xgb["training_samples"], 298)
        self.assertEqual(xgb["holdout_samples"], 90)
        self.assertEqual(xgb["holdout_risk_accuracy"], 0.6667)
        self.assertEqual(xgb["raw_metrics_status"], "Pending Owner Action")
        self.assertIn("not present", xgb["raw_metrics_note"])
        self.assertFalse(evidence["daily_logistic_template"]["research_trained"])
        self.assertEqual(xgb["split_method"], "GroupShuffleSplit")
        self.assertEqual(xgb["test_size"], 0.22)
        self.assertEqual(xgb["random_seed"], 42)
        self.assertEqual(xgb["dataset_status"], "Pending Researcher Evidence")
        self.assertEqual(xgb["xgb_parameters"]["n_estimators"], 96)
        self.assertEqual(xgb["xgb_parameters"]["tree_method"], "hist")

    def test_persistence_and_csv_contracts_are_extracted_from_source(self) -> None:
        facts = builder.inspect_source(SOURCE)
        self.assertIn("sookta.dataSchemaVersion", facts["preference_keys"])
        self.assertEqual(facts["data_schema_version"], 2)
        self.assertGreaterEqual(len(facts["preference_keys"]), 10)
        self.assertIn("transaction_id", facts["all_history_csv_headers"])
        self.assertIn("Export Generated At", facts["all_history_csv_headers"])
        self.assertIn("REBA_before", facts["all_history_csv_headers"])
        self.assertIn("completion_status", facts["all_history_csv_headers"])
        persisted = {row["field"] for row in facts["persisted_record_fields"]}
        self.assertIn("profileId", persisted)
        self.assertIn("scoreBefore", persisted)
        self.assertIn("selectedImagePaths", persisted)
        self.assertIn("appVersion", persisted)
        self.assertIn("sookta.backup.schema.<version>.<timestamp>", facts["preference_keys"])
        app_versions = [row for row in facts["persisted_record_fields"] if row["field"] == "appVersion"]
        self.assertGreaterEqual(len({row["owner"] for row in app_versions}), 2)

    def test_source_contracts_cover_exact_runtime_behavior(self) -> None:
        facts = builder.inspect_source(SOURCE)
        triggers = facts["recommendation_triggers"]
        self.assertEqual(len(triggers), 24)
        lookup = {(r["activity"], r["risk_tier"]): r for r in triggers}
        self.assertEqual(lookup[("transplanting", "low")]["activity_key"], "act_transplant_ref_low")
        self.assertEqual(lookup[("fertilizing", "medium")]["activity_key"], "act_fert_ref_medium")
        self.assertEqual(lookup[("harvesting", "veryHigh")]["activity_key"], "act_harvest_ref_high")
        self.assertEqual(lookup[("transport", "veryHigh")]["weight_key"], "act_ref_weight_high")
        self.assertEqual(facts["daily_runtime_tiers"], [
            {"high_risk_count": "0-1", "level": "Low"},
            {"high_risk_count": "2-3", "level": "Watch"},
            {"high_risk_count": "4-5", "level": "High"},
            {"high_risk_count": "6-7", "level": "Critical"},
        ])
        self.assertFalse(facts["daily_probability_thresholds"]["used_by_predict_for_records"])

    def test_export_and_telemetry_contracts_are_semantically_complete(self) -> None:
        facts = builder.inspect_source(SOURCE)
        rows = facts["export_schema_rows"]
        self.assertEqual(len(rows), 84)
        self.assertEqual([row["field"] for row in rows], facts["all_history_csv_headers"])
        self.assertTrue(all(row["description"] and row["type"] and row["validation"] for row in rows))
        self.assertFalse(any("source-defined" in row["type"].lower() for row in rows))
        history = next(row for row in facts["persisted_schema_rows"] if row["field"] == "sookta.history")
        language = next(row for row in facts["persisted_schema_rows"] if row["field"] == "sookta.language")
        self.assertIn("Sensitive", history["privacy"])
        self.assertNotIn("Sensitive participant", language["privacy"])
        self.assertTrue(all(row["nullable"] in {"Yes", "No"} for row in facts["persisted_schema_rows"]))
        self.assertFalse(any("source-defined" in str(value).lower() for row in facts["persisted_schema_rows"] for value in row.values()))
        events = facts["firebase_telemetry"]["events"]
        self.assertEqual(events["assessment_calculated"], ["activity", "job_type", "primary_method", "risk_level", "score", "image_count", "uses_iso11228"])
        self.assertEqual(events["assessment_saved"], ["activity", "before_risk", "after_risk", "before_score", "after_score", "suggestion_count"])
        self.assertTrue(facts["firebase_telemetry"]["default_off"])
        self.assertTrue(facts["firebase_telemetry"]["crashlytics_context"])


class ContentContractTests(unittest.TestCase):
    def test_bullet_helper_applies_readable_paragraph_spacing(self) -> None:
        document = Document()
        builder._add_bullets(document, ["One", "Two"])
        self.assertTrue(all(p.paragraph_format.space_after.pt >= 4 for p in document.paragraphs))
        self.assertEqual([p.text for p in document.paragraphs], ["• One", "\n• Two"])

    def test_required_workbook_sheets_are_exact(self) -> None:
        self.assertEqual(len(builder.ALGORITHM_WORKBOOK_SHEETS), 15)
        self.assertEqual(len(builder.DATA_WORKBOOK_SHEETS), 9)
        self.assertIn("Recommendation Messages", builder.ALGORITHM_WORKBOOK_SHEETS)
        self.assertIn("Export Schema Order", builder.DATA_WORKBOOK_SHEETS)

    def test_claim_guard_rejects_unqualified_validation_claims(self) -> None:
        verifier.assert_claim_boundaries(
            "Software verification passed. No clinical validation or external validity is claimed."
        )
        verifier.assert_claim_boundaries(
            "Do not state that the model is clinically validated or externally validated."
        )
        with self.assertRaises(AssertionError):
            verifier.assert_claim_boundaries("The model is clinically validated and production-ready.")
        with self.assertRaises(AssertionError):
            verifier.assert_claim_boundaries("All participants consented and data was de-identified.")

    def test_status_vocabulary_is_fail_closed(self) -> None:
        verifier.verify_status_values(["Complete", "Pending Owner Action", "N/A with Rationale"])
        with self.assertRaises(AssertionError):
            verifier.verify_status_values(["Almost complete"])

    def test_synthetic_examples_cannot_contain_real_capture_identity(self) -> None:
        verifier.assert_synthetic_examples(["SYN-001", "Synthetic Farmer", "2026-08-24T09:00:00+07:00"])
        with self.assertRaises(AssertionError):
            verifier.assert_synthetic_examples(["FSK-944631", "ddd"])


class VisualManifestTests(unittest.TestCase):
    def test_visual_expectations_cover_all_ten_primary_artifacts(self) -> None:
        expected = recorder.task5_visual_expectations()
        self.assertEqual(len(expected), 10)
        self.assertTrue(all(renders for renders in expected.values()))

    def test_checksum_update_preserves_existing_entries(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "artifacts").mkdir()
            (root / "manifests").mkdir()
            prior = root / "artifacts/prior.txt"
            current = root / "artifacts/current.txt"
            prior.write_text("prior", encoding="utf-8")
            current.write_text("current", encoding="utf-8")
            recorder.update_checksums(root, [prior])
            recorder.update_checksums(root, [current])
            manifest = (root / "manifests/SHA256SUMS.txt").read_text(encoding="ascii")
            self.assertIn("artifacts/prior.txt", manifest)
            self.assertIn("artifacts/current.txt", manifest)


if __name__ == "__main__":
    unittest.main()
