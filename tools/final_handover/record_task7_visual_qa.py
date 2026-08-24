#!/usr/bin/env python3
"""Record the complete, manually inspected Task 7 visual surface set."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path


ROOT = Path(os.environ.get("SOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
RENDERS = ROOT / "renders" / "task7"
MANIFESTS = ROOT / "manifests"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def main() -> None:
    surfaces = []
    groups = (
        ("docx_page", RENDERS / "docs", "*.png"),
        ("workbook_sheet", RENDERS / "sheets", "*.png"),
        ("pptx_slide", RENDERS / "deck", "slide-*.png"),
        ("pdf_page", RENDERS / "pdf", "*.png"),
    )
    for kind, base, pattern in groups:
        for path in sorted(base.rglob(pattern)):
            surfaces.append({"kind": kind, "path": relative(path), "sha256": digest(path)})

    counts = {kind: sum(item["kind"] == kind for item in surfaces) for kind, _, _ in groups}
    assert counts == {"docx_page": 19, "workbook_sheet": 24, "pptx_slide": 14, "pdf_page": 57}, counts
    assert len(surfaces) == 114

    expected = {
        "schema_version": 1,
        "task": 7,
        "source_commit": "bf8867a2083357cb9d60915bf6c2233801f923d8",
        "count": len(surfaces),
        "counts": counts,
        "renders": surfaces,
    }
    MANIFESTS.mkdir(parents=True, exist_ok=True)
    expected_path = MANIFESTS / "task7_expected_visual_renders.json"
    expected_path.write_text(json.dumps(expected, ensure_ascii=False, indent=2) + "\n")

    contacts = sorted((RENDERS / "contact_sheets").glob("*.jpg"))
    assert len(contacts) == 34, len(contacts)
    visual = {
        "schema_version": 1,
        "task": 7,
        "method": "manual_view_image_contact_sheet_and_direct_page_inspection",
        "decision": "pass",
        "expected_manifest_sha256": digest(expected_path),
        "inspection_scope": ["clipping", "overlap", "broken_glyphs", "unexpected_blank_pages", "orphaned_headers_or_rows", "formula_display"],
        "contact_sheets": [{"path": relative(path), "sha256": digest(path)} for path in contacts],
        "renders": [{**item, "decision": "pass"} for item in surfaces],
        "limitations": "Visual QA confirms rendered layout only; human approvals, live-device execution, research results, acceptance, signatures, and security compliance remain outside this inspection.",
    }
    (MANIFESTS / "task7_visual_qa_manifest.json").write_text(json.dumps(visual, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"renders": len(surfaces), "contact_sheets": len(contacts), "counts": counts}, sort_keys=True))


if __name__ == "__main__":
    main()
