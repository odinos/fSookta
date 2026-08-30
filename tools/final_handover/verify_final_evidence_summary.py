#!/usr/bin/env python3
"""Independently compare runtime evidence files against a safe JSON summary."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def fingerprint(path: Path) -> tuple[str | None, int | None]:
    if not path.exists():
        return None, None
    digest = hashlib.sha256()
    if path.is_dir():
        members = tuple(sorted(member for member in path.rglob("*") if member.is_file()))
        for member in members:
            member_hash, _ = fingerprint(member)
            digest.update(str(member.relative_to(path)).encode("utf-8"))
            digest.update(b"\0")
            digest.update((member_hash or "").encode("ascii"))
            digest.update(b"\n")
        return digest.hexdigest(), sum(member.stat().st_size for member in members)
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest(), path.stat().st_size


def records(summary: dict) -> list[dict]:
    if "primary_logs" in summary:
        return [*summary.get("primary_logs", []), *summary.get("additional_logs", []), *summary.get("artifacts", [])]
    evidence = summary.get("evidence", {})
    return [*evidence.get("primary_logs", []), *evidence.get("fallback_logs", []), *summary.get("technical_artifacts", [])]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summary", type=Path, required=True)
    args = parser.parse_args()
    summary = json.loads(args.summary.read_text(encoding="utf-8"))
    mismatches = []
    summary_records = records(summary)
    if not summary_records:
        print("runtime-summary mismatch: no required records")
        return 1
    for record in summary_records:
        path = Path(record["path"])
        actual_hash, actual_size = fingerprint(path)
        if record.get("exists") is not True or not path.exists() or actual_hash != record.get("sha256") or actual_size != record.get("byte_size"):
            mismatches.append(str(path))
    if mismatches:
        print("runtime-summary mismatch: " + ", ".join(mismatches))
        return 1
    print(f"runtime-summary comparison: {len(summary_records)} records matched SHA-256 and byte size")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
