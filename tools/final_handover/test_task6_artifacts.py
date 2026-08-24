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

import build_task6_audit_test_uat as builder
import record_task6_visual_qa as recorder
import verify_task6_artifacts as verifier


SOURCE = Path("/private/tmp/fsookta-final-handover/authoritative-materializations/source-g6tsggy7/source")


class Task6FactsTests(unittest.TestCase):
    def test_algorithm_report_keeps_signoff_on_a_fresh_page(self) -> None:
        import inspect
        source = inspect.getsource(builder.build_algorithm_report)
        signoff = source.index('doc.add_heading("8. Sign-off"')
        self.assertIn("doc.add_page_break()", source[:signoff].split("doc.add_heading", 1)[-1])

    def test_final_logs_are_the_only_final_baseline_pass_source(self) -> None:
        facts = builder.collect_facts(SOURCE)
        self.assertEqual(facts["baseline"]["version"], "1.3.11+28")
        self.assertEqual(facts["baseline"]["commit"], builder.COMMIT)
        self.assertEqual(facts["final_commands"]["flutter_test"]["status"], "PASS")
        self.assertEqual(facts["final_commands"]["flutter_test"]["test_count"], 135)
        self.assertEqual(facts["final_commands"]["android_release"]["status"], "Technical Build Only")
        self.assertEqual(facts["final_commands"]["ios_release"]["status"], "Technical Build Only")

    def test_historical_uat_never_promotes_to_final_baseline(self) -> None:
        rows = builder.collect_facts(SOURCE)["historical_uat"]
        self.assertGreaterEqual(len(rows), 5)
        self.assertTrue(all(row["evidence_layer"] == "Historical" for row in rows))
        self.assertTrue(all(row["version"] != "1.3.11+28" for row in rows))
        self.assertTrue(any(row["bypass_status"] != "None" for row in rows))
        self.assertFalse(any(row["final_baseline_pass"] for row in rows))

    def test_final_hardware_uat_is_pending_without_participant_claims(self) -> None:
        facts = builder.collect_facts(SOURCE)
        pending = facts["final_hardware_actions"]
        required = {"camera", "gallery", "tts_audio", "share_export", "offline_inference", "android_device", "iphone_device", "tablet_device", "performance", "uat_participants", "sus_responses", "acceptance"}
        self.assertTrue(required.issubset({row["action_key"] for row in pending}))
        self.assertTrue(all(row["status"] in builder.ALLOWED_STATUSES for row in pending))
        self.assertEqual(facts["final_uat_status"], "Pending Researcher Evidence")
        self.assertEqual(facts["participant_count"], 0)

    def test_algorithm_cases_are_source_or_test_grounded(self) -> None:
        cases = builder.collect_facts(SOURCE)["algorithm_cases"]
        self.assertGreaterEqual(len(cases), 15)
        self.assertTrue(all(row["evidence_path"] for row in cases))
        self.assertTrue(all(row["baseline"] == "1.3.11+28" for row in cases))
        self.assertTrue(all(row["tester_category"] == "Automated test runner" for row in cases))

    def test_git_rows_have_real_hash_dates_subjects_and_changed_paths(self) -> None:
        rows = builder.collect_facts(SOURCE)["git_history"]
        self.assertGreaterEqual(len(rows), 20)
        self.assertTrue(all(len(row["commit"]) == 40 for row in rows))
        self.assertTrue(all(row["date"].endswith("Z") or "+" in row["date"] for row in rows))
        self.assertTrue(all(row["subject"] and row["changed_paths"] for row in rows))


class Task6VerifierTests(unittest.TestCase):
    def test_independent_source_grounding_rejects_git_mutation(self) -> None:
        facts = json.loads((builder.STAGING / "working" / "task6" / "task6_build_input.json").read_text())
        verifier.assert_source_grounding(facts, SOURCE)
        mutated = copy.deepcopy(facts)
        mutated["git_history"][0]["subject"] = "fabricated subject"
        with self.assertRaises(AssertionError):
            verifier.assert_source_grounding(mutated, SOURCE)

    def test_verifier_rejects_unsupported_final_uat_pass(self) -> None:
        facts = {"final_uat_status": "PASS", "participant_count": 0, "historical_uat": [], "final_hardware_actions": []}
        with self.assertRaises(AssertionError):
            verifier.assert_claim_boundaries(facts)

    def test_visual_manifest_is_hash_bound_and_exact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            render = root / "one.png"
            render.write_bytes(b"render")
            expected = {"expected": [{"path": "one.png", "sha256": builder.sha(render)}]}
            manifest = recorder.build_manifest(root, expected, {"one.png": "PASS"})
            verifier.assert_visual_manifest(expected, manifest, root)
            manifest["renders"][0]["sha256"] = "0" * 64
            with self.assertRaises(AssertionError):
                verifier.assert_visual_manifest(expected, manifest, root)


if __name__ == "__main__":
    unittest.main()
