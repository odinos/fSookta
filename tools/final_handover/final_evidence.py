#!/usr/bin/env python3
"""Capture and validate non-sensitive technical evidence for the frozen release.

The runner always archives the pinned commit before it invokes Flutter.  It does
not read application source from the invoking worktree, so its output cannot be
mistaken for evidence from a later branch revision.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import platform
import re
import shlex
import subprocess
import sys
import tarfile
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Mapping, Sequence


AUTHORITATIVE_COMMIT = "bf8867a2083357cb9d60915bf6c2233801f923d8"
AUTHORITATIVE_VERSION = "1.3.11+28"
PRIMARY_LOG_NAMES = (
    "flutter_analyze_1.3.11+28.log",
    "flutter_test_1.3.11+28.log",
    "build_android_1.3.11+28.log",
    "build_ios_1.3.11+28.log",
)
REQUIRED_LOG_FIELDS = (
    f"Version: {AUTHORITATIVE_VERSION}",
    f"Commit: {AUTHORITATIVE_COMMIT}",
    "Command:",
    "Start timestamp (UTC):",
    "End timestamp (UTC):",
    "Environment:",
    "Exit code:",
    "Complete stdout/stderr follows:",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def command_text(command: Sequence[str]) -> str:
    return shlex.join(tuple(command))


def render_log_header(
    command: Sequence[str], started_at: str, environment: Mapping[str, str]
) -> str:
    """Render the common evidence header before raw process output."""
    return "\n".join((
        "SookTa final-version technical evidence",
        f"Version: {AUTHORITATIVE_VERSION}",
        f"Commit: {AUTHORITATIVE_COMMIT}",
        f"Command: {command_text(command)}",
        f"Start timestamp (UTC): {started_at}",
        "Environment:",
        json.dumps(dict(environment), ensure_ascii=False, indent=2, sort_keys=True),
        "",
        "Complete stdout/stderr follows:",
        "--- stdout ---",
    )) + "\n"


def validate_log_text(text: str) -> list[str]:
    """Return a stable list of missing required metadata markers."""
    labels = (
        f"Version: {AUTHORITATIVE_VERSION}",
        f"Commit: {AUTHORITATIVE_COMMIT}",
        "Command:",
        "Start timestamp (UTC):",
        "End timestamp (UTC):",
        "Environment:",
        "Exit code:",
        "complete stdout/stderr marker",
    )
    markers = REQUIRED_LOG_FIELDS
    return [f"missing {label}" for label, marker in zip(labels, markers) if marker not in text]


def run_output(command: Sequence[str], cwd: Path | None = None) -> tuple[int, str, str]:
    result = subprocess.run(
        tuple(command), cwd=cwd, check=False, text=True, capture_output=True
    )
    return result.returncode, result.stdout, result.stderr


def environment_snapshot(flutter: str) -> dict[str, str]:
    flutter_exit, flutter_stdout, flutter_stderr = run_output((flutter, "--version"))
    xcode_exit, xcode_stdout, xcode_stderr = run_output(("xcodebuild", "-version"))
    return {
        "flutter_command": flutter,
        "flutter_version_exit_code": str(flutter_exit),
        "flutter_version_output": (flutter_stdout + flutter_stderr).strip(),
        "operating_system": platform.platform(),
        "python": sys.version.replace("\n", " "),
        "xcodebuild_exit_code": str(xcode_exit),
        "xcodebuild_output": (xcode_stdout + xcode_stderr).strip(),
    }


def write_command_log(
    path: Path, command: Sequence[str], cwd: Path, environment: Mapping[str, str]
) -> int:
    started_at = utc_now()
    exit_code, stdout, stderr = run_output(command, cwd)
    ended_at = utc_now()
    with path.open("w", encoding="utf-8") as handle:
        handle.write(render_log_header(command, started_at, environment))
        handle.write(stdout)
        if stdout and not stdout.endswith("\n"):
            handle.write("\n")
        handle.write("--- stderr ---\n")
        handle.write(stderr)
        if stderr and not stderr.endswith("\n"):
            handle.write("\n")
        handle.write(f"End timestamp (UTC): {ended_at}\n")
        handle.write(f"Exit code: {exit_code}\n")
    return exit_code


def write_combined_log(
    path: Path,
    command: Sequence[str],
    started_at: str,
    ended_at: str,
    environment: Mapping[str, str],
    exit_code: int,
    combined_output: str,
) -> None:
    """Write an auditable log from a completed background command's output."""
    with path.open("w", encoding="utf-8") as handle:
        handle.write(render_log_header(command, started_at, environment))
        handle.write("--- combined stdout/stderr ---\n")
        handle.write(combined_output)
        if combined_output and not combined_output.endswith("\n"):
            handle.write("\n")
        handle.write(f"End timestamp (UTC): {ended_at}\n")
        handle.write(f"Exit code: {exit_code}\n")


def git_value(repository: Path, *args: str) -> str:
    exit_code, stdout, stderr = run_output(("git", "-C", str(repository), *args))
    if exit_code:
        raise RuntimeError(f"git {' '.join(args)} failed: {stderr.strip()}")
    return stdout.strip()


def materialize_authoritative_source(repository: Path, output_root: Path) -> tuple[Path, str, int]:
    """Archive the exact commit into a fresh temporary directory and verify it."""
    output_root.mkdir(parents=True, exist_ok=True)
    materialization = Path(tempfile.mkdtemp(prefix="source-", dir=output_root))
    archive_path = materialization / "authoritative-source.tar"
    exit_code, stdout, stderr = run_output(
        ("git", "-C", str(repository), "archive", "--format=tar", "--output", str(archive_path), AUTHORITATIVE_COMMIT)
    )
    if exit_code:
        raise RuntimeError(f"git archive failed: {stderr or stdout}")
    with tarfile.open(archive_path) as archive:
        archive.extractall(materialization / "source")
    source = materialization / "source"
    version_match = re.search(r"^version:\s*(\S+)", (source / "pubspec.yaml").read_text(encoding="utf-8"), re.MULTILINE)
    if version_match is None or version_match.group(1) != AUTHORITATIVE_VERSION:
        raise RuntimeError("materialized pubspec version does not match the authoritative version")
    file_count = sum(1 for item in source.rglob("*") if item.is_file())
    tree_id = git_value(repository, "rev-parse", f"{AUTHORITATIVE_COMMIT}^{{tree}}")
    return source, tree_id, file_count


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_source_metadata(
    evidence_dir: Path, repository: Path, source: Path, tree_id: str, file_count: int, environment: Mapping[str, str]
) -> Path:
    path = evidence_dir / "final_source_metadata.txt"
    archive_command = ("git", "-C", str(repository), "archive", "--format=tar", AUTHORITATIVE_COMMIT)
    metadata = [
        "SookTa authoritative final-source metadata",
        f"Version: {AUTHORITATIVE_VERSION}",
        f"Commit: {AUTHORITATIVE_COMMIT}",
        f"Tree ID: {tree_id}",
        f"Materialized source: {source}",
        f"File count: {file_count}",
        f"Command: {command_text(archive_command)}",
        f"Start timestamp (UTC): {utc_now()}",
        "Environment:",
        json.dumps(dict(environment), ensure_ascii=False, indent=2, sort_keys=True),
        "Complete stdout/stderr follows:",
        "--- stdout ---",
        "git archive completed; extracted authoritative source and verified pubspec version.",
        "--- stderr ---",
        "",
        f"End timestamp (UTC): {utc_now()}",
        "Exit code: 0",
        "",
    ]
    path.write_text("\n".join(metadata), encoding="utf-8")
    return path


def validate_evidence(evidence_dir: Path) -> dict[str, object]:
    records = []
    for name in PRIMARY_LOG_NAMES:
        path = evidence_dir / name
        errors = ["missing file"] if not path.exists() else validate_log_text(path.read_text(encoding="utf-8"))
        records.append({"path": str(path), "sha256": sha256(path) if path.exists() else None, "errors": errors})
    return {
        "schema_version": 1,
        "version": AUTHORITATIVE_VERSION,
        "commit": AUTHORITATIVE_COMMIT,
        "generated_at_utc": utc_now(),
        "records": records,
        "valid": not any(record["errors"] for record in records),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", type=Path, required=True)
    parser.add_argument("--evidence-dir", type=Path, required=True)
    parser.add_argument("--materialization-root", type=Path, required=True)
    parser.add_argument("--flutter", default="/Users/kpc/develop/flutter/bin/flutter")
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--summary-output", type=Path)
    args = parser.parse_args()

    if args.validate_only:
        summary = validate_evidence(args.evidence_dir)
        rendered = json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
        if args.summary_output:
            args.summary_output.write_text(rendered, encoding="utf-8")
        else:
            print(rendered, end="")
        return 0 if summary["valid"] else 1

    args.evidence_dir.mkdir(parents=True, exist_ok=True)
    environment = environment_snapshot(args.flutter)
    source, tree_id, file_count = materialize_authoritative_source(args.repository, args.materialization_root)
    write_source_metadata(args.evidence_dir, args.repository, source, tree_id, file_count, environment)
    commands = (
        ("flutter_pub_get_1.3.11+28.log", (args.flutter, "pub", "get")),
        ("flutter_analyze_1.3.11+28.log", (args.flutter, "analyze")),
        ("flutter_test_1.3.11+28.log", (args.flutter, "test")),
        ("build_android_1.3.11+28.log", (args.flutter, "build", "appbundle", "--release")),
        ("build_ios_1.3.11+28.log", (args.flutter, "build", "ipa", "--release")),
    )
    exit_codes = [write_command_log(args.evidence_dir / name, command, source, environment) for name, command in commands]
    summary = validate_evidence(args.evidence_dir)
    (args.evidence_dir / "verification_environment.json").write_text(
        json.dumps({"environment": environment, "metadata_validation": summary}, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return 0 if not any(exit_codes) and summary["valid"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
