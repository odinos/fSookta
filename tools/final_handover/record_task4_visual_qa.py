#!/usr/bin/env python3
"""Record hash-bound Task 4 visual QA and extend the shared checksum manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime
from pathlib import Path

import build_task4_architecture as builder


STAGING = Path("/private/tmp/fsookta-final-handover")
CONFIRMATION = "I inspected every listed Task 4 render at 100%"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def task4_visual_expectations() -> dict[str, list[str]]:
    report_pages = [f"renders/task4/docx/report/page-{page}.png" for page in range(1, 11)]
    api_pages = [f"renders/task4/docx/api/page-{page}.png" for page in range(1, 3)]
    workbook_sheets = [
        "renders/task4/xlsx/03_Technical_Stack_and_Module_Specification__Summary.png",
        "renders/task4/xlsx/03_Technical_Stack_and_Module_Specification__Modules.png",
        "renders/task4/xlsx/03_Technical_Stack_and_Module_Specification__Technology_Stack.png",
        "renders/task4/xlsx/03_Technical_Stack_and_Module_Specification__Evidence_Sources.png",
    ]
    workbook_pages = [f"renders/task4/pdf/workbook/page-{page}.png" for page in range(1, 5)]
    expected: dict[str, list[str]] = {
        "artifacts/03_Final_Technical_Development_Report.docx": report_pages,
        "artifacts/03_Final_Technical_Development_Report.pdf": report_pages,
        "artifacts/03_API_Applicability_Statement.docx": api_pages,
        "artifacts/03_API_Applicability_Statement.pdf": api_pages,
        "artifacts/03_Technical_Stack_and_Module_Specification.xlsx": workbook_sheets,
        "artifacts/03_Technical_Stack_and_Module_Specification.pdf": workbook_pages,
    }
    for spec in builder.diagram_specs():
        basename = spec["basename"]
        png = f"artifacts/diagrams/{basename}.png"
        expected[f"artifacts/diagrams/{basename}.drawio"] = [png]
        expected[png] = [png]
    return expected


def update_checksums(staging: Path, paths: list[Path]) -> Path:
    output = staging / "manifests" / "SHA256SUMS.txt"
    entries: dict[str, str] = {}
    if output.is_file():
        for line in output.read_text(encoding="ascii").splitlines():
            if not line.strip():
                continue
            checksum, relative = line.split("  ", 1)
            entries[relative] = checksum
    for path in paths:
        relative = path.relative_to(staging).as_posix()
        entries[relative] = digest(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        "".join(f"{entries[relative]}  {relative}\n" for relative in sorted(entries)),
        encoding="ascii",
    )
    for relative, checksum in entries.items():
        path = staging / relative
        if not path.is_file() or digest(path) != checksum:
            raise RuntimeError(f"checksum round-trip failed: {relative}")
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--staging", type=Path, default=STAGING)
    parser.add_argument("--inspected-at", required=True, help="ISO-8601 timestamp with timezone")
    parser.add_argument("--reviewer-role", required=True)
    parser.add_argument("--notes", required=True)
    parser.add_argument("--confirm-inspected", required=True)
    args = parser.parse_args()
    if args.confirm_inspected != CONFIRMATION:
        raise SystemExit(f"Refusing to record visual QA without exact confirmation: {CONFIRMATION!r}")
    datetime.fromisoformat(args.inspected_at)
    if not args.reviewer_role.strip() or not args.notes.strip():
        raise SystemExit("reviewer role and notes must be non-empty")

    expected = task4_visual_expectations()
    artifacts = []
    for artifact_relative, render_relatives in expected.items():
        artifact = args.staging / artifact_relative
        if not artifact.is_file():
            raise SystemExit(f"Final artifact is missing: {artifact}")
        renders = []
        for render_relative in render_relatives:
            render = args.staging / render_relative
            if not render.is_file():
                raise SystemExit(f"Inspected render is missing: {render}")
            renders.append({
                "path": render_relative,
                "sha256": digest(render),
                "status": "passed",
                "notes": "Inspected at 100%; legible with no clipping, overlap, broken content, or obscured connectors.",
            })
        artifacts.append({
            "path": artifact_relative,
            "sha256": digest(artifact),
            "status": "passed",
            "notes": "All bound final renders passed visual inspection.",
            "renders": renders,
        })

    manifests = args.staging / "manifests"
    manifests.mkdir(parents=True, exist_ok=True)
    expected_path = manifests / "task4_expected_visual_renders.json"
    expected_path.write_text(json.dumps(expected, indent=2) + "\n", encoding="utf-8")
    visual_path = manifests / "task4_visual_qa_manifest.json"
    payload = {
        "schema_version": 1,
        "inspected_at": args.inspected_at,
        "reviewer_role": args.reviewer_role,
        "status": "passed",
        "notes": args.notes,
        "artifacts": artifacts,
    }
    visual_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    primary_paths = [args.staging / relative for relative in expected]
    workbook_summary = manifests / "task4_workbook_build_summary.json"
    checksum = update_checksums(
        args.staging,
        [*primary_paths, expected_path, visual_path, workbook_summary],
    )
    print(json.dumps({
        "expected_map": str(expected_path),
        "visual_manifest": str(visual_path),
        "visual_manifest_sha256": digest(visual_path),
        "artifact_entries": len(artifacts),
        "unique_render_files": len({render for renders in expected.values() for render in renders}),
        "checksum_manifest": str(checksum),
        "checksum_entries": len(checksum.read_text(encoding="ascii").splitlines()),
    }, indent=2))


if __name__ == "__main__":
    main()
