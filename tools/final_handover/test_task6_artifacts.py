#!/usr/bin/env python3
"""Behavior-first tests for Task 6 audit, verification, and UAT artifacts."""

from __future__ import annotations

import sys
import tempfile
import unittest
import copy
import json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import record_task6_visual_qa as recorder
import task6_source
import verify_task6_artifacts as verifier

SOURCE = Path("/private/tmp/fsookta-final-handover/authoritative-materializations/source-g6tsggy7/source")
STAGING = Path("/private/tmp/fsookta-final-handover")


class Task6FactsTests(unittest.TestCase):
    def test_algorithm_report_keeps_exact_test_appendix_on_a_fresh_page(self) -> None:
        import inspect
        import build_task6_documents
        source = inspect.getsource(build_task6_documents.algorithm_report)
        appendix = source.index("d.add_heading('Appendix A - Exact automated test order'")
        self.assertIn("d.add_page_break()", source[:appendix].split("d.add_heading", 1)[-1])

    def test_final_logs_are_the_only_final_baseline_pass_source(self) -> None:
        facts = task6_source.build_corrected_payload(STAGING)
        commands = json.loads((STAGING / "working/task6/task6_build_input.json").read_text())["final_commands"]
        self.assertEqual(facts["baseline"]["version"], "1.3.11+28")
        self.assertEqual(facts["baseline"]["commit"], task6_source.COMMIT)
        self.assertEqual(commands["flutter_test"]["status"], "PASS")
        self.assertEqual(commands["flutter_test"]["test_count"], 135)
        self.assertEqual(commands["android_release"]["status"], "Technical Build Only")
        self.assertEqual(commands["ios_release"]["status"], "Technical Build Only")
        self.assertEqual({row["case_id"] for row in facts["result_rows"] if row["status"] == "PASS"}, {f"AUTO-{index:03d}" for index in range(1, 136)} | {"STATIC-001"})

    def test_historical_uat_never_promotes_to_final_baseline(self) -> None:
        facts = task6_source.build_corrected_payload(STAGING)
        rows = facts["historical_uat"]
        self.assertGreaterEqual(len(rows), 5)
        self.assertTrue(all(row["evidence_layer"].startswith("Historical") for row in rows))
        self.assertTrue(all(row["version"] != "1.3.11+28" for row in rows))
        self.assertTrue(any(row["assessment_bypass"] == "Temporary assessment bypass" for row in rows))
        self.assertIn("historical", facts["claim_boundary"].lower())

    def test_final_hardware_uat_is_pending_without_participant_claims(self) -> None:
        facts = task6_source.build_corrected_payload(STAGING)
        pending = facts["human_gaps"]
        required = {"camera", "gallery", "tts_audio", "share_export", "offline_inference", "android_device", "iphone_device", "tablet_device", "performance", "uat_participants", "sus_responses", "acceptance"}
        self.assertTrue(required.issubset({row["action_key"] for row in pending}))
        allowed = {"Pending Owner Action", "Pending Researcher Evidence", "Complete - Pending Signature"}
        self.assertTrue(all(row["status"] in allowed for row in pending))
        self.assertFalse(any(row["case_id"].startswith("UAT-") and row["status"] == "PASS" for row in facts["result_rows"]))

    def test_algorithm_cases_are_source_or_test_grounded(self) -> None:
        facts = task6_source.build_corrected_payload(STAGING)
        cases = [row for row in facts["result_rows"] if row.get("category") == "Algorithm / reference"]
        self.assertGreaterEqual(len(cases), 15)
        self.assertTrue(all(row["raw_path"] and row["sha256"] for row in cases))
        self.assertTrue(all(row["baseline"] == "1.3.11+28" for row in cases))
        self.assertTrue(all(row["tester_category"] == "Automated host/unit/widget runner" for row in cases))

    def test_git_rows_have_real_hash_dates_subjects_and_changed_paths(self) -> None:
        rows = task6_source.build_corrected_payload(STAGING)["git_history"]
        self.assertGreaterEqual(len(rows), 20)
        self.assertTrue(all(len(row["commit"]) == 40 for row in rows))
        self.assertTrue(all(row["date"].endswith("Z") or "+" in row["date"] for row in rows))
        self.assertTrue(all(row["subject"] and row["changed_paths"] for row in rows))


class Task6VerifierTests(unittest.TestCase):
    def test_independent_source_grounding_rejects_git_mutation(self) -> None:
        facts = task6_source.build_corrected_payload(STAGING)
        verifier.verify_git_history(STAGING, facts)
        mutated = copy.deepcopy(facts)
        mutated["git_history"][0]["subject"] = "fabricated subject"
        with self.assertRaises(AssertionError):
            verifier.verify_git_history(STAGING, mutated)

    def test_verifier_rejects_unsupported_final_uat_pass(self) -> None:
        facts = {"final_uat_status": "PASS", "participant_count": 0, "historical_uat": [], "final_hardware_actions": []}
        with self.assertRaises(AssertionError):
            verifier.assert_claim_boundaries(facts)

    def test_visual_manifest_is_hash_bound_and_exact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            render = root / "one.png"
            render.write_bytes(b"render")
            expected_path = root / "expected.json"
            decision_path = root / "decision.json"
            output_path = root / "record.json"
            expected = {"count": 1, "renders": [{"path": "one.png", "sha256": recorder.sha(render)}]}
            expected_path.write_text(json.dumps(expected))
            decision = {"decision": "PASS", "inspector": "External manual QA", "inspected_at": "2026-08-24T15:10:00+07:00", "expected_manifest_sha256": recorder.sha(expected_path), "expected_render_count": 1}
            decision_path.write_text(json.dumps(decision))
            manifest = recorder.consume(expected_path, decision_path, output_path)
            self.assertEqual(manifest["expected_manifest_sha256"], recorder.sha(expected_path))
            expected["renders"][0]["sha256"] = "0" * 64
            expected_path.write_text(json.dumps(expected))
            with self.assertRaises(ValueError):
                recorder.consume(expected_path, decision_path, output_path)


if __name__ == "__main__":
    unittest.main()
