import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from tools.final_handover.task6_fix_round1 import (
    build_corrected_payload,
    parse_flutter_expanded,
    validate_payload,
    validate_visual_decisions,
)


STAGING = Path("/private/tmp/fsookta-final-handover")


class Task6FixRound1Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.payload = build_corrected_payload(STAGING)

    def test_expanded_reporter_attributes_increment_to_preceding_displayed_test(self):
        log = (STAGING / "evidence/flutter_test_1.3.11+28.log").read_text()
        cases = parse_flutter_expanded(log)
        self.assertEqual(135, len(cases))
        self.assertEqual("AUTO-001", cases[0]["case_id"])
        self.assertEqual("AUTO-135", cases[-1]["case_id"])
        self.assertEqual(
            "clears the draft after a successful evaluation save",
            cases[-1]["name"],
        )
        self.assertNotIn("All tests passed", {case["name"] for case in cases})

    def test_requirements_preserve_every_source_record_and_terminal_status(self):
        source = json.loads((STAGING / "evidence_map.json").read_text())["records"]
        actual = self.payload["requirements"]
        self.assertEqual(155, len(actual))
        self.assertEqual(
            {
                "Pending Owner Action": 137,
                "Exception Approval Required": 12,
                "Pending Researcher Evidence": 6,
            },
            self.payload["requirement_status_counts"],
        )
        for expected, got in zip(source, actual, strict=True):
            for key in (
                "requirement_id",
                "status",
                "authoritative_sources",
                "human_action",
                "final_version_claim",
                "rationale",
            ):
                self.assertEqual(expected[key], got[key])
            self.assertIn("task6_evidence", got)

    def test_historical_uat_dimensions_are_source_exact(self):
        by_date = {row["date"]: row for row in self.payload["historical_uat"]}
        self.assertEqual("1.1.0+6", by_date["2026-05-26"]["version"])
        self.assertEqual("1.1.2+10", by_date["2026-06-07"]["version"])
        july12 = by_date["2026-07-12"]
        self.assertEqual("1.3.6+21", july12["version"])
        self.assertIn("iPhone SE", july12["device"])
        self.assertIn("iOS 26.5", july12["device"])
        self.assertEqual("No physical Android detected; iPad simulator only", july12["runner_harness"])
        self.assertEqual("Uploaded-video UAT", july12["build_workaround"])
        self.assertEqual("Temporary assessment bypass", july12["assessment_bypass"])
        july19 = by_date["2026-07-19"]
        self.assertEqual("iOS simulator + Android emulator", july19["runner_harness"])
        self.assertEqual("None - production assessment path", july19["assessment_bypass"])
        self.assertIn("BLOCKED BY DEVICE CONNECTION", july19["blocker"])
        june6_r2 = next(row for row in self.payload["historical_uat"] if row["date"] == "2026-06-06" and row["round_revision"] == "r2")
        self.assertNotIn("assessment bypass", june6_r2["build_workaround"].lower())

    def test_sus_instrument_has_all_ten_items_row5_anchors_validation_and_formula(self):
        sus = self.payload["sus"]
        self.assertEqual(list(range(1, 11)), [row["item"] for row in sus["items"]])
        self.assertEqual("Strongly disagree", sus["anchors"]["1"])
        self.assertEqual("Strongly agree", sus["anchors"]["5"])
        self.assertEqual({"type": "whole", "minimum": 1, "maximum": 5}, sus["validation"])
        self.assertEqual("=(SUM(odd_items-1)+SUM(5-even_items))*2.5", sus["score_formula_contract"])

    def test_every_pass_has_complete_hash_bound_evidence_tuple(self):
        required = {"case_id", "baseline", "timestamp", "method", "raw_path", "sha256"}
        for row in self.payload["result_rows"]:
            if row["status"] == "PASS":
                self.assertTrue(required <= set(row["evidence_tuple"]))
                self.assertRegex(row["evidence_tuple"]["sha256"], r"^[0-9a-f]{64}$")

    def test_defects_and_before_after_are_resolvable_and_hash_bound(self):
        for row in self.payload["defects"]:
            self.assertRegex(row["before_commit"], r"^[0-9a-f]{7,40}$")
            self.assertRegex(row["after_commit"], r"^[0-9a-f]{7,40}$")
            self.assertRegex(row["sha256"], r"^[0-9a-f]{64}$")
            self.assertTrue(row["source_path"])
            self.assertTrue(row["retest"])
        for row in self.payload["before_after"]:
            self.assertRegex(row["before_commit"], r"^[0-9a-f]{7,40}$")
            self.assertRegex(row["after_commit"], r"^[0-9a-f]{7,40}$")
            self.assertRegex(row["sha256"], r"^[0-9a-f]{64}$")
            self.assertTrue(row["evidence_path"])

    def test_independent_validator_rejects_each_semantic_mutation(self):
        validate_payload(self.payload, STAGING)
        mutations = []
        wrong_test = copy.deepcopy(self.payload)
        wrong_test["tests"][-1]["name"] = "All tests passed"
        mutations.append(wrong_test)
        wrong_status = copy.deepcopy(self.payload)
        wrong_status["requirements"][0]["status"] = "PASS"
        mutations.append(wrong_status)
        wrong_history = copy.deepcopy(self.payload)
        wrong_history["historical_uat"][-1]["assessment_bypass"] = "Temporary bypass"
        mutations.append(wrong_history)
        wrong_sus = copy.deepcopy(self.payload)
        wrong_sus["sus"]["items"] = [r for r in wrong_sus["sus"]["items"] if r["item"] != 5]
        mutations.append(wrong_sus)
        wrong_pass = copy.deepcopy(self.payload)
        wrong_pass["result_rows"][0]["evidence_tuple"].pop("sha256")
        mutations.append(wrong_pass)
        for mutation in mutations:
            with self.assertRaises(ValueError):
                validate_payload(mutation, STAGING)

    def test_visual_manifest_requires_external_hash_bound_decisions(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            render = root / "page-1.png"
            render.write_bytes(b"render")
            expected = [{"path": "page-1.png", "sha256": hashlib.sha256(b"render").hexdigest()}]
            with self.assertRaises(ValueError):
                validate_visual_decisions(expected, [], root)
            decisions = [{"path": "page-1.png", "sha256": expected[0]["sha256"], "decision": "PASS", "inspector": "Manual QA", "inspected_at": "2026-08-24T00:00:00Z"}]
            validate_visual_decisions(expected, decisions, root)


if __name__ == "__main__":
    unittest.main()
