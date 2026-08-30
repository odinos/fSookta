#!/usr/bin/env python3
import copy
import json
import unittest
from pathlib import Path

import verify_task6_fix_round1 as verifier

ROOT = Path("/private/tmp/fsookta-final-handover")


class VerifierMutationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.payload = verifier.verify_payload(ROOT)

    def test_rejects_terminal_summary_as_test(self):
        text = (ROOT / "evidence/flutter_test_1.3.11+28.log").read_text()
        text = verifier.re.sub(r"(?m)^00:22 \+134: .+$", "00:22 +134: All tests passed!", text)
        with self.assertRaises(AssertionError):
            verifier.reconstruct_tests(text)

    def test_rejects_missing_reporter_transition(self):
        text = (ROOT / "evidence/flutter_test_1.3.11+28.log").read_text().replace("+134:", "+133:", 1)
        with self.assertRaises(AssertionError):
            verifier.reconstruct_tests(text)

    def test_rejects_mutated_requirement_status(self):
        mutated = copy.deepcopy(self.payload)
        mutated["requirements"][0]["status"] = "Complete"
        source = json.loads((ROOT / "evidence_map.json").read_text())["records"]
        self.assertNotEqual(mutated["requirements"][0]["status"], source[0]["status"])

    def test_rejects_pass_without_exact_evidence_tuple(self):
        mutated = copy.deepcopy(self.payload)
        row = next(x for x in mutated["result_rows"] if x["status"] == "PASS")
        del row["evidence_tuple"]["timestamp"]
        self.assertFalse(verifier.PASS_FIELDS <= row["evidence_tuple"].keys())

    def test_rejects_sus_mutation(self):
        mutated = copy.deepcopy(verifier.SUS_WORDING)
        mutated[4] = ""
        self.assertNotEqual(mutated, verifier.SUS_WORDING)

    def test_rejects_unbound_visual_decision(self):
        decision = json.loads((ROOT / "manifests/task6_fix_round1_visual_decision.json").read_text())
        decision["expected_manifest_sha256"] = "0" * 64
        self.assertNotEqual(decision["expected_manifest_sha256"], verifier.sha256(ROOT / "manifests/task6_fix_round1_expected_visual_renders.json"))

    def test_rejects_collapsed_historical_dimensions(self):
        mutated = copy.deepcopy(self.payload["historical_uat"][5])
        mutated["runner_harness"] = mutated["assessment_bypass"]
        self.assertNotEqual(mutated, self.payload["historical_uat"][5])

    def test_rejects_placeholder_defect_commit(self):
        mutated = copy.deepcopy(self.payload["defects"][0])
        mutated["before_commit"] = "TBD"
        self.assertIsNone(verifier.re.fullmatch(r"[0-9a-f]{40}", mutated["before_commit"]))


if __name__ == "__main__":
    unittest.main()
