#!/usr/bin/env python3
"""Record explicit Task 3 visual QA after a human/agent has inspected every render."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime
from pathlib import Path

from verify_task3_artifacts import STAGING, task3_visual_expectations


CONFIRMATION = "I inspected every listed render at 100%"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--staging", type=Path, default=STAGING)
    parser.add_argument("--inspected-at", required=True, help="ISO-8601 timestamp with timezone")
    parser.add_argument("--reviewer-role", required=True)
    parser.add_argument("--notes", required=True)
    parser.add_argument("--confirm-inspected", required=True)
    args = parser.parse_args()
    if args.confirm_inspected != CONFIRMATION:
        raise SystemExit(f"Refusing to create visual QA manifest without exact confirmation: {CONFIRMATION!r}")
    datetime.fromisoformat(args.inspected_at)
    if not args.reviewer_role.strip() or not args.notes.strip():
        raise SystemExit("reviewer role and notes must be non-empty")

    artifacts = []
    for artifact_relative, render_relatives in task3_visual_expectations().items():
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
                "notes": "Inspected at 100%; legible with no clipping, overlap, or broken content.",
            })
        artifacts.append({
            "path": artifact_relative,
            "sha256": digest(artifact),
            "status": "passed",
            "notes": "All bound final renders passed visual inspection.",
            "renders": renders,
        })

    payload = {
        "schema_version": 1,
        "inspected_at": args.inspected_at,
        "reviewer_role": args.reviewer_role,
        "status": "passed",
        "notes": args.notes,
        "artifacts": artifacts,
    }
    output = args.staging / "manifests" / "task3_visual_qa_manifest.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"path": str(output), "sha256": digest(output), "artifact_entries": len(artifacts)}, indent=2))


if __name__ == "__main__":
    main()
