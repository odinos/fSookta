import json
import os
import unittest
import zipfile
from pathlib import Path
from openpyxl import load_workbook
from pypdf import PdfReader

ROOT = Path(os.environ.get("SOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
ART = ROOT / "artifacts"
MAN = ROOT / "manifests"

EDITABLE = [
    "09_Security_Privacy_and_Data_Protection_Report.docx",
    "09_Security_and_Access_Control_Matrices.xlsx",
    "10_End_User_Manual.docx",
    "10_Research_Admin_Manual.docx",
    "10_Developer_Handover_Manual.docx",
    "10_Knowledge_Transfer_Deck.pptx",
    "10_Knowledge_Transfer_Minutes.docx",
    "11_Research_Publication_Package.docx",
    "11_Publication_Tables.xlsx",
]


class Task7ArtifactTests(unittest.TestCase):
    def test_editable_and_pdf_pairs_exist(self):
        for name in EDITABLE:
            self.assertTrue((ART / name).is_file(), name)
            self.assertTrue((ART / f"{Path(name).stem}.pdf").is_file(), name)

    def test_offline_security_fallback_is_disclosed_and_value_safe(self):
        report = json.loads((MAN / "task7_offline_security_inspection.json").read_text())
        self.assertEqual(report["method"], "offline_source_backed_fallback")
        self.assertFalse(report["sealed_codex_security_report"])
        self.assertEqual(report["source_commit"], "bf8867a2083357cb9d60915bf6c2233801f923d8")
        dumped = json.dumps(report)
        for forbidden in ["AIza", "BEGIN PRIVATE KEY", "client_secret"]:
            self.assertNotIn(forbidden, dumped)

    def test_documents_preserve_human_boundaries(self):
        required = {
            "09_Security_Privacy_and_Data_Protection_Report.docx": ["Pending Owner", "N/A with Rationale", "SOOKTA_TELEMETRY_ENABLED"],
            "10_End_User_Manual.docx": ["1.3.11+28", "four-image", "not a medical certificate"],
            "10_Research_Admin_Manual.docx": ["coded identifier", "Pending Researcher", "consent"],
            "10_Developer_Handover_Manual.docx": ["bf8867a2083357cb9d60915bf6c2233801f923d8", "Technical builds", "full-history"],
            "10_Knowledge_Transfer_Minutes.docx": ["Draft — Pending Meeting", "Pending Attendee", "Pending Signature"],
            "11_Research_Publication_Package.docx": ["Pending Researcher", "Do not infer", "historical"],
        }
        for name, needles in required.items():
            with zipfile.ZipFile(ART / name) as zf:
                text = zf.read("word/document.xml").decode("utf-8")
            for needle in needles:
                self.assertIn(needle, text, f"{name}: {needle}")

    def test_manifest_binds_every_render(self):
        expected = json.loads((MAN / "task7_expected_visual_renders.json").read_text())
        external_path = ROOT / "manual-decisions/task7_external_visual_decision.json"
        self.assertTrue(external_path.is_file(), "external visual decision absent")
        visual = json.loads((MAN / "task7_visual_qa_manifest.json").read_text())
        external = json.loads(external_path.read_text())
        self.assertEqual(external["decision"], "PASS")
        self.assertEqual(external["expected_manifest_sha256"], visual["expected_manifest_sha256"])
        expected_paths = {x["path"] for x in expected["renders"]}
        actual_paths = {x["path"] for x in visual["renders"]}
        self.assertEqual(expected_paths, actual_paths)
        self.assertTrue(all(x["decision"] == "pass" for x in visual["renders"]))

    def test_workbooks_have_bounded_print_metadata(self):
        for name in ["09_Security_and_Access_Control_Matrices.xlsx", "11_Publication_Tables.xlsx"]:
            wb = load_workbook(ART / name, read_only=False, data_only=False)
            for ws in wb.worksheets:
                self.assertEqual(ws.page_setup.fitToWidth, 1, f"{name}:{ws.title}")
                self.assertEqual(ws.page_setup.orientation, "landscape", f"{name}:{ws.title}")
                self.assertTrue(ws.print_area, f"{name}:{ws.title}")
            if name.startswith("09_"):
                self.assertEqual(wb["Control Summary"]["B9"].value, '=IF(COUNTIF(\'Risk Register\'!E5:E9,"Open*")>0,"OPEN ACTIONS","NO OPEN ROWS")')

    def test_document_page_breaks_do_not_orphan_control_tables(self):
        sec = PdfReader(ART / "09_Security_Privacy_and_Data_Protection_Report.pdf")
        self.assertIn("Offline inspection observations", sec.pages[2].extract_text())
        self.assertTrue(sec.pages[3].extract_text().lstrip().startswith("Draft non-retention"))
        kt = PdfReader(ART / "10_Knowledge_Transfer_Minutes.pdf")
        self.assertIn("Acknowledgement and signatures", kt.pages[-1].extract_text())


if __name__ == "__main__":
    unittest.main()
