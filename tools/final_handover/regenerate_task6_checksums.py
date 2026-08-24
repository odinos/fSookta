#!/usr/bin/env python3
"""Re-hash the cumulative handover inventory without adding SHA256SUMS itself."""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path("/private/tmp/fsookta-final-handover")
MANIFEST = ROOT / "manifests/SHA256SUMS.txt"
ADDITIONS = {
    "manifests/task6_fix_round1_expected_visual_renders.json",
    "manifests/task6_fix_round1_contact_sheets.json",
    "manifests/task6_fix_round1_visual_decision.json",
    "manifests/task6_verification_summary.json",
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    paths = {line.split("  ", 1)[1].strip() for line in MANIFEST.read_text().splitlines() if "  " in line}
    paths.update(ADDITIONS)
    missing = sorted(path for path in paths if not (ROOT / path).is_file())
    if missing:
        raise SystemExit(f"missing checksum targets: {missing}")
    lines = [f"{digest(ROOT / path)}  {path}" for path in sorted(paths)]
    MANIFEST.write_text("\n".join(lines) + "\n")
    print(f"checksum entries: {len(lines)}")


if __name__ == "__main__":
    main()
