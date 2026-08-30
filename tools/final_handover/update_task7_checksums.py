#!/usr/bin/env python3
"""Add the current Task 7 deliverables to the cumulative staging checksum file."""
from __future__ import annotations

import hashlib
import os
from pathlib import Path


ROOT = Path(os.environ.get("SOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
MANIFEST = ROOT / "manifests" / "SHA256SUMS.txt"
TASK7 = [
    *(f"artifacts/{name}" for name in (
        "09_Security_Privacy_and_Data_Protection_Report.docx", "09_Security_Privacy_and_Data_Protection_Report.pdf",
        "09_Security_and_Access_Control_Matrices.xlsx", "09_Security_and_Access_Control_Matrices.pdf",
        "10_End_User_Manual.docx", "10_End_User_Manual.pdf",
        "10_Research_Admin_Manual.docx", "10_Research_Admin_Manual.pdf",
        "10_Developer_Handover_Manual.docx", "10_Developer_Handover_Manual.pdf",
        "10_Knowledge_Transfer_Deck.pptx", "10_Knowledge_Transfer_Deck.pdf",
        "10_Knowledge_Transfer_Minutes.docx", "10_Knowledge_Transfer_Minutes.pdf",
        "11_Research_Publication_Package.docx", "11_Research_Publication_Package.pdf",
        "11_Publication_Tables.xlsx", "11_Publication_Tables.pdf",
    )),
    "manifests/task7_expected_visual_renders.json",
    "manifests/task7_offline_security_inspection.json",
    "manifests/task7_visual_qa_manifest.json",
]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    prior = {}
    if MANIFEST.is_file():
        for line in MANIFEST.read_text().splitlines():
            if not line.strip():
                continue
            checksum, relative = line.split(None, 1)
            prior[relative.strip()] = checksum
    for relative in TASK7:
        path = ROOT / relative
        assert path.is_file(), relative
        prior[relative] = digest(path)
    MANIFEST.write_text("".join(f"{prior[path]}  {path}\n" for path in sorted(prior)))
    print(f"checksums={len(prior)}")


if __name__ == "__main__":
    main()
