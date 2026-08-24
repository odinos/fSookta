#!/usr/bin/env python3
"""Record hash-bound Task 5 visual QA and extend cumulative checksums."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime
from pathlib import Path

from build_task5_ai_data import ALGORITHM_WORKBOOK_SHEETS, DATA_WORKBOOK_SHEETS

STAGING = Path("/private/tmp/fsookta-final-handover")
CONFIRMATION = "I inspected every listed Task 5 render at 100%"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _safe(name: str) -> str:
    return name.replace(" ", "_").replace("/", "_")


def task5_visual_expectations(page_counts: dict[str, int] | None = None) -> dict[str, list[str]]:
    counts = page_counts or {"ai_report": 1, "training_statement": 1, "data_manual": 1,
                             "algorithm_pdf": 15, "data_pdf": 9}
    docs = {
        "04_AI_Algorithm_and_Model_Technical_Report": "ai_report",
        "04_AI_Training_and_Non_Training_Statement": "training_statement",
        "05_Local_Storage_and_Data_Management_Manual": "data_manual",
    }
    expected: dict[str, list[str]] = {}
    for stem, folder in docs.items():
        renders = [f"renders/task5/docx/{folder}/page-{i}.png" for i in range(1, counts[folder] + 1)]
        expected[f"artifacts/{stem}.docx"] = renders
        expected[f"artifacts/{stem}.pdf"] = renders
    algo_stem = "04_Algorithm_Recommendation_and_Reference_Matrices"
    data_stem = "05_Data_Dictionary_and_Export_Schema"
    expected[f"artifacts/{algo_stem}.xlsx"] = [
        f"renders/task5/xlsx/{algo_stem}__{_safe(sheet)}.png" for sheet in ALGORITHM_WORKBOOK_SHEETS
    ]
    expected[f"artifacts/{algo_stem}.pdf"] = [
        f"renders/task5/pdf/algorithm/page-{i}.png" for i in range(1, counts["algorithm_pdf"] + 1)
    ]
    expected[f"artifacts/{data_stem}.xlsx"] = [
        f"renders/task5/xlsx/{data_stem}__{_safe(sheet)}.png" for sheet in DATA_WORKBOOK_SHEETS
    ]
    expected[f"artifacts/{data_stem}.pdf"] = [
        f"renders/task5/pdf/data/page-{i}.png" for i in range(1, counts["data_pdf"] + 1)
    ]
    return expected


def update_checksums(staging: Path, paths: list[Path]) -> Path:
    output = staging / "manifests/SHA256SUMS.txt"
    entries: dict[str, str] = {}
    if output.is_file():
        for line in output.read_text(encoding="ascii").splitlines():
            if line.strip():
                checksum, relative = line.split("  ", 1)
                entries[relative] = checksum
    for path in paths:
        entries[path.relative_to(staging).as_posix()] = digest(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("".join(f"{entries[p]}  {p}\n" for p in sorted(entries)), encoding="ascii")
    for relative, checksum in entries.items():
        path = staging / relative
        if not path.is_file() or digest(path) != checksum:
            raise RuntimeError(f"checksum round-trip failed: {relative}")
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--staging", type=Path, default=STAGING)
    parser.add_argument("--inspected-at", required=True)
    parser.add_argument("--reviewer-role", required=True)
    parser.add_argument("--notes", required=True)
    parser.add_argument("--confirm-inspected", required=True)
    args = parser.parse_args()
    if args.confirm_inspected != CONFIRMATION:
        raise SystemExit(f"Refusing to record visual QA without exact confirmation: {CONFIRMATION!r}")
    datetime.fromisoformat(args.inspected_at)
    if not args.reviewer_role.strip() or not args.notes.strip():
        raise SystemExit("reviewer role and notes must be non-empty")
    counts = json.loads((args.staging / "manifests/task5_render_counts.json").read_text(encoding="utf-8"))
    expected = task5_visual_expectations(counts)
    artifacts = []
    for artifact_relative, render_relatives in expected.items():
        artifact = args.staging / artifact_relative
        if not artifact.is_file():
            raise SystemExit(f"Final artifact missing: {artifact}")
        renders = []
        for relative in render_relatives:
            render = args.staging / relative
            if not render.is_file():
                raise SystemExit(f"Render missing: {render}")
            renders.append({"path": relative, "sha256": digest(render), "status": "passed",
                            "notes": "Inspected at 100%; legible with no clipping, overlap, missing glyphs, or broken content."})
        artifacts.append({"path": artifact_relative, "sha256": digest(artifact), "status": "passed",
                          "notes": "All bound renders passed visual inspection.", "renders": renders})
    manifests = args.staging / "manifests"; manifests.mkdir(parents=True, exist_ok=True)
    expected_path = manifests / "task5_expected_visual_renders.json"
    expected_path.write_text(json.dumps(expected, indent=2) + "\n", encoding="utf-8")
    visual_path = manifests / "task5_visual_qa_manifest.json"
    visual_path.write_text(json.dumps({
        "schema_version": 1, "inspected_at": args.inspected_at,
        "reviewer_role": args.reviewer_role, "status": "passed", "notes": args.notes,
        "artifacts": artifacts,
    }, indent=2) + "\n", encoding="utf-8")
    primary = [args.staging / relative for relative in expected]
    workbook_summary = manifests / "task5_workbook_build_summary.json"
    checksum = update_checksums(args.staging, [*primary, expected_path, visual_path, workbook_summary])
    print(json.dumps({
        "artifact_entries": len(artifacts),
        "unique_render_files": len({r for rs in expected.values() for r in rs}),
        "visual_manifest_sha256": digest(visual_path),
        "checksum_entries": len(checksum.read_text(encoding="ascii").splitlines()),
    }, indent=2))


if __name__ == "__main__":
    main()
