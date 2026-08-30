import json
import os
import unittest
from pathlib import Path


ROOT = Path(os.environ.get("SOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
MANIFEST = ROOT / "manifests/task7_final_content_inspection.json"
EDITABLE = {
    "09_Security_Privacy_and_Data_Protection_Report.docx",
    "09_Security_and_Access_Control_Matrices.xlsx",
    "10_End_User_Manual.docx",
    "10_Research_Admin_Manual.docx",
    "10_Developer_Handover_Manual.docx",
    "10_Knowledge_Transfer_Deck.pptx",
    "10_Knowledge_Transfer_Minutes.docx",
    "11_Research_Publication_Package.docx",
    "11_Publication_Tables.xlsx",
}


class Task7FixRound3Tests(unittest.TestCase):
    def setUp(self):
        self.report = json.loads(MANIFEST.read_text())

    def test_final_scan_consumes_every_task7_editable_office_output(self):
        scanned = {row["container"] for row in self.report["scanned_office_containers"]}
        self.assertTrue(EDITABLE <= scanned)
        for name in EDITABLE:
            row = next(row for row in self.report["scanned_office_containers"] if row["container"] == name)
            self.assertGreater(row["content_items_scanned"], 0, name)
            self.assertGreater(row["bytes_scanned"], 0, name)

    def test_final_scan_consumes_all_non_self_task7_manifests(self):
        expected = {path.name for path in (ROOT / "manifests").glob("task7_*.json") if path.name != MANIFEST.name}
        actual = {row["path"] for row in self.report["scanned_task7_manifests"]}
        self.assertEqual(actual, expected)

    def test_every_participant_shaped_candidate_has_disposition(self):
        rows = self.report["participant_candidate_dispositions"]
        self.assertGreater(len(rows), 0)
        self.assertEqual(sum(row["occurrences"] for row in rows), self.report["participant_candidate_total"])
        for row in rows:
            self.assertTrue(row["domain"] and row["path"] and row["pattern"])
            self.assertTrue(row["category"] and row["disposition"] and row["status"])
            self.assertNotIn("matched_value", row)
        pending = sum(row["occurrences"] for row in rows if row["status"].startswith("Open - Pending"))
        self.assertEqual(pending, self.report["participant_candidates_pending_review"])

    def test_all_four_google_markers_have_exact_dispositions(self):
        rows = self.report["google_api_key_marker_dispositions"]
        self.assertEqual(sum(row["occurrences"] for row in rows), 4)
        self.assertEqual({row["path"] for row in rows}, {
            "lib/firebase_options.dart",
            "ios/Runner/GoogleService-Info.plist",
            "android/app/google-services.json",
        })
        self.assertTrue(all(row["category"] == "official_firebase_client_configuration" for row in rows))
        self.assertTrue(all(row["status"] == "Open - Pending Owner" for row in rows))


if __name__ == "__main__":
    unittest.main()
