#!/usr/bin/env python3
"""Independent, fail-closed verification for Task 7 handover artifacts."""
from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import zipfile
from pathlib import Path

from docx import Document
from openpyxl import load_workbook
from pypdf import PdfReader


ROOT = Path(os.environ.get("SOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
ART = ROOT / "artifacts"
MAN = ROOT / "manifests"
COMMIT = "bf8867a2083357cb9d60915bf6c2233801f923d8"
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
PDF_PAGES = {
    "09_Security_Privacy_and_Data_Protection_Report.pdf": 4,
    "09_Security_and_Access_Control_Matrices.pdf": 15,
    "10_End_User_Manual.pdf": 3,
    "10_Research_Admin_Manual.pdf": 3,
    "10_Developer_Handover_Manual.pdf": 3,
    "10_Knowledge_Transfer_Deck.pdf": 14,
    "10_Knowledge_Transfer_Minutes.pdf": 3,
    "11_Research_Publication_Package.pdf": 3,
    "11_Publication_Tables.pdf": 9,
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def text_docx(path: Path) -> str:
    doc = Document(path)
    return "\n".join(p.text for p in doc.paragraphs) + "\n" + "\n".join(c.text for t in doc.tables for r in t.rows for c in r.cells)


def verify_pairs() -> None:
    assert len(EDITABLE) == len(PDF_PAGES) == 9
    for name in EDITABLE:
        assert (ART / name).is_file(), name
        assert (ART / f"{Path(name).stem}.pdf").is_file(), name


def verify_documents() -> None:
    boundaries = {
        "09_Security_Privacy_and_Data_Protection_Report.docx": ("Pending Owner", "N/A with Rationale", "does not certify compliance"),
        "10_End_User_Manual.docx": ("four-image", "not a medical certificate", "1.3.11+28"),
        "10_Research_Admin_Manual.docx": ("coded identifier", "Pending Researcher", "consent"),
        "10_Developer_Handover_Manual.docx": (COMMIT, "Technical builds", "full-history"),
        "10_Knowledge_Transfer_Minutes.docx": ("Draft — Pending Meeting", "Pending Attendee", "Pending Signature"),
        "11_Research_Publication_Package.docx": ("Pending Researcher", "Do not infer", "historical"),
    }
    for name, needles in boundaries.items():
        text = text_docx(ART / name)
        assert all(needle in text for needle in needles), name
        assert "Created with Python" not in text and "python-docx" not in text


def verify_workbooks() -> dict:
    expected = {"09_Security_and_Access_Control_Matrices.xlsx": 15, "11_Publication_Tables.xlsx": 9}
    formulas = 0
    for name, sheets in expected.items():
        book = load_workbook(ART / name, data_only=False)
        assert len(book.sheetnames) == sheets, (name, book.sheetnames)
        for sheet in book.worksheets:
            assert sheet.page_setup.orientation == "landscape", (name, sheet.title)
            assert sheet.page_setup.fitToWidth == 1, (name, sheet.title)
            assert sheet.print_area, (name, sheet.title)
            for row in sheet.iter_rows():
                for cell in row:
                    if cell.data_type == "f":
                        formulas += 1
                        assert not re.search(r"#(?:REF|VALUE|DIV/0|NAME|N/A)!?", str(cell.value), re.I)
        if name.startswith("09_"):
            assert book["Control Summary"]["B9"].value == '=IF(B6>0,"OPEN ACTIONS","NO OPEN ROWS")'
    assert formulas == 1, formulas
    return {"workbooks": 2, "sheets": 24, "formulas": formulas, "formula_errors": 0}


def verify_deck() -> dict:
    path = ART / "10_Knowledge_Transfer_Deck.pptx"
    with zipfile.ZipFile(path) as zf:
        slides = [n for n in zf.namelist() if re.fullmatch(r"ppt/slides/slide\d+\.xml", n)]
        xml = "\n".join(zf.read(n).decode("utf-8", "ignore") for n in zf.namelist() if n.endswith(".xml"))
    assert len(slides) == 14
    assert xml.count("[Sources]") >= 14
    for layout in ("08", "14", "17", "19"):
        assert f"codex-grid-layout-library#slide-{layout}-" in xml
    return {"slides": 14, "source_note_blocks": xml.count("[Sources]")}


def verify_pdfs() -> dict:
    actual = {name: len(PdfReader(ART / name).pages) for name in PDF_PAGES}
    assert actual == PDF_PAGES, actual
    assert sum(actual.values()) == 57
    return {"pdfs": 9, "pdf_pages": 57}


def verify_security() -> dict:
    report = json.loads((MAN / "task7_offline_security_inspection.json").read_text())
    assert report["method"] == "offline_source_backed_fallback"
    assert report["source_commit"] == COMMIT
    assert report["sealed_codex_security_report"] is False
    assert len(report["findings"]) == 5
    assert report["files_scanned"] == 619
    dump = json.dumps(report)
    for forbidden in ("AIza", "BEGIN PRIVATE KEY", "client_secret"):
        assert forbidden not in dump
    return {"security_method": report["method"], "security_observations": 5, "source_files_scanned": 619}


def verify_visual() -> dict:
    expected_path = MAN / "task7_expected_visual_renders.json"
    expected = json.loads(expected_path.read_text())
    visual = json.loads((MAN / "task7_visual_qa_manifest.json").read_text())
    assert expected["count"] == 114
    assert expected["counts"] == {"docx_page": 19, "workbook_sheet": 24, "pptx_slide": 14, "pdf_page": 57}
    assert visual["expected_manifest_sha256"] == sha(expected_path)
    assert visual["decision"] == "pass" and len(visual["contact_sheets"]) == 34
    assert {x["path"] for x in expected["renders"]} == {x["path"] for x in visual["renders"]}
    for item in expected["renders"]:
        path = ROOT / item["path"]
        assert path.is_file() and sha(path) == item["sha256"], item["path"]
    assert all(item["decision"] == "pass" for item in visual["renders"])
    return {"visual_surfaces": 114, "contact_sheets": 34}


def verify() -> dict:
    verify_pairs()
    result = {"status": "passed_with_human_actions", "editable_artifacts": 9, "pdf_artifacts": 9, "documents": 6}
    result.update(verify_workbooks())
    result.update(verify_deck())
    result.update(verify_pdfs())
    result.update(verify_security())
    result.update(verify_visual())
    verify_documents()
    return result


if __name__ == "__main__":
    root_arg = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT
    ROOT, ART, MAN = root_arg, root_arg / "artifacts", root_arg / "manifests"
    print(json.dumps(verify(), ensure_ascii=False, indent=2, sort_keys=True))
