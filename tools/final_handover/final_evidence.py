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
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Mapping, Sequence


AUTHORITATIVE_COMMIT = "bf8867a2083357cb9d60915bf6c2233801f923d8"
AUTHORITATIVE_VERSION = "1.3.11+28"
EVIDENCE_LOG_NAMES = (
    "final_source_metadata.txt",
    "flutter_pub_get_1.3.11+28.log",
    "flutter_analyze_1.3.11+28.log",
    "flutter_test_1.3.11+28.log",
    "build_android_1.3.11+28.log",
    "build_ios_1.3.11+28.log",
)
METADATA_VALIDATION_NAME = "metadata_validation.json"
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


@dataclass(frozen=True)
class ArchiveEvidence:
    source: Path
    tree_id: str
    file_count: int
    command: tuple[str, ...]
    started_at: str
    ended_at: str
    stdout: str
    stderr: str
    exit_code: int


@dataclass(frozen=True)
class FallbackDecision:
    log_name: str
    command: tuple[str, ...]
    classification: str


def file_fingerprint(path: Path) -> dict[str, object]:
    """Return a non-sensitive immutable file identity without reading secrets."""
    if not path.exists():
        return {"exists": False, "sha256": None, "byte_size": None}
    if path.is_dir():
        members = tuple(sorted(member for member in path.rglob("*") if member.is_file()))
        return {
            "exists": True,
            "sha256": sha256(path),
            "byte_size": sum(member.stat().st_size for member in members),
        }
    return {"exists": True, "sha256": sha256(path), "byte_size": path.stat().st_size}


def lockfile_changed(before: Mapping[str, object], after: Mapping[str, object]) -> bool:
    return dict(before) != dict(after)


def fallback_decision(platform_name: str, production_signing_verified: bool) -> FallbackDecision | None:
    """Select a non-production fallback whenever production signing is unverified."""
    if production_signing_verified:
        return None
    if platform_name == "android":
        return FallbackDecision(
            "build_android_fallback_debug_1.3.11+28.log",
            ("flutter", "build", "apk", "--debug"),
            "Non-production Android debug fallback; upload signing is not verified.",
        )
    if platform_name == "ios":
        return FallbackDecision(
            "build_ios_fallback_no_codesign_1.3.11+28.log",
            ("flutter", "build", "ipa", "--release", "--no-codesign"),
            "Non-production iOS no-codesign fallback; distribution/App Store ownership is not verified.",
        )
    raise ValueError(f"unsupported platform for fallback: {platform_name}")


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
    path: Path,
    command: Sequence[str],
    cwd: Path,
    environment: Mapping[str, str],
    trailing_metadata: Sequence[str] = (),
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
        for line in trailing_metadata:
            handle.write(f"{line}\n")
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
    trailing_metadata: Sequence[str] = (),
) -> None:
    """Write an auditable log from a completed background command's output."""
    with path.open("w", encoding="utf-8") as handle:
        handle.write(render_log_header(command, started_at, environment))
        handle.write("--- combined stdout/stderr ---\n")
        handle.write(combined_output)
        if combined_output and not combined_output.endswith("\n"):
            handle.write("\n")
        for line in trailing_metadata:
            handle.write(f"{line}\n")
        handle.write(f"End timestamp (UTC): {ended_at}\n")
        handle.write(f"Exit code: {exit_code}\n")


def write_build_log(
    path: Path,
    command: Sequence[str],
    cwd: Path,
    environment: Mapping[str, str],
    classification: str,
) -> int:
    """Run a long build and preserve its complete combined output in one log."""
    started_at = utc_now()
    exit_code, stdout, stderr = run_output(command, cwd)
    ended_at = utc_now()
    combined = f"{stdout}--- stderr ---\n{stderr}"
    write_combined_log(
        path, command, started_at, ended_at, environment, exit_code, combined,
        trailing_metadata=(f"Classification: {classification}",),
    )
    return exit_code


def git_value(repository: Path, *args: str) -> str:
    exit_code, stdout, stderr = run_output(("git", "-C", str(repository), *args))
    if exit_code:
        raise RuntimeError(f"git {' '.join(args)} failed: {stderr.strip()}")
    return stdout.strip()


def materialize_authoritative_source(repository: Path, output_root: Path) -> ArchiveEvidence:
    """Archive the exact commit into a fresh temporary directory and verify it."""
    output_root.mkdir(parents=True, exist_ok=True)
    materialization = Path(tempfile.mkdtemp(prefix="source-", dir=output_root))
    archive_path = materialization / "authoritative-source.tar"
    archive_command = (
        "git", "-C", str(repository), "archive", "--format=tar", "--output",
        str(archive_path), AUTHORITATIVE_COMMIT,
    )
    started_at = utc_now()
    exit_code, stdout, stderr = run_output(archive_command)
    ended_at = utc_now()
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
    return ArchiveEvidence(
        source=source,
        tree_id=tree_id,
        file_count=file_count,
        command=archive_command,
        started_at=started_at,
        ended_at=ended_at,
        stdout=stdout,
        stderr=stderr,
        exit_code=exit_code,
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    if path.is_dir():
        for member in sorted(candidate for candidate in path.rglob("*") if candidate.is_file()):
            digest.update(str(member.relative_to(path)).encode("utf-8"))
            digest.update(b"\0")
            digest.update(sha256(member).encode("ascii"))
            digest.update(b"\n")
        return digest.hexdigest()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def runtime_file_record(path: Path, classification: str | None = None) -> dict[str, object]:
    record: dict[str, object] = {"path": str(path), **file_fingerprint(path)}
    if classification is not None:
        record["classification"] = classification
    return record


def build_safe_summary(
    evidence_dir: Path,
    primary_logs: Sequence[Path],
    artifacts: Sequence[tuple[Path, str]],
    source_metadata: Mapping[str, object],
) -> dict[str, object]:
    """Build a secret-free runtime manifest with sizes and checksums."""
    return {
        "schema_version": 2,
        "evidence_directory": str(evidence_dir),
        "authoritative_source": dict(source_metadata),
        "primary_logs": [runtime_file_record(path) for path in primary_logs],
        "additional_logs": [
            runtime_file_record(path) for path in sorted(evidence_dir.glob("build_*_fallback_*.log"))
        ],
        "artifacts": [runtime_file_record(path, classification) for path, classification in artifacts],
    }


def verify_runtime_summary(summary: Mapping[str, object]) -> list[str]:
    errors = []
    for collection_name in ("primary_logs", "additional_logs", "artifacts"):
        for record in summary.get(collection_name, []):
            assert isinstance(record, Mapping)
            path = Path(str(record["path"]))
            actual = file_fingerprint(path)
            for field_name in ("exists", "sha256", "byte_size"):
                if actual[field_name] != record.get(field_name):
                    errors.append(f"{collection_name}:{path}:{field_name} mismatch")
    return errors


def write_validation_file(evidence_dir: Path, summary: Mapping[str, object]) -> Path:
    path = evidence_dir / METADATA_VALIDATION_NAME
    path.write_text(json.dumps(dict(summary), ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def write_source_metadata(
    evidence_dir: Path,
    source: Path,
    tree_id: str,
    file_count: int,
    environment: Mapping[str, str],
    archive_command: Sequence[str],
    started_at: str,
    ended_at: str,
    archive_stdout: str,
    archive_stderr: str,
    exit_code: int,
) -> Path:
    path = evidence_dir / "final_source_metadata.txt"
    metadata = [
        "SookTa authoritative final-source metadata",
        f"Version: {AUTHORITATIVE_VERSION}",
        f"Commit: {AUTHORITATIVE_COMMIT}",
        f"Tree ID: {tree_id}",
        f"Materialized source: {source}",
        f"File count: {file_count}",
        f"Command: {command_text(archive_command)}",
        f"Start timestamp (UTC): {started_at}",
        "Environment:",
        json.dumps(dict(environment), ensure_ascii=False, indent=2, sort_keys=True),
        "Complete stdout/stderr follows:",
        "--- stdout ---",
        archive_stdout,
        "--- stderr ---",
        archive_stderr,
        f"End timestamp (UTC): {ended_at}",
        f"Exit code: {exit_code}",
        "",
    ]
    path.write_text("\n".join(metadata), encoding="utf-8")
    return path


def validate_evidence(evidence_dir: Path) -> dict[str, object]:
    records = []
    fallback_log_names = tuple(sorted(path.name for path in evidence_dir.glob("build_*_fallback_*.log")))
    for name in EVIDENCE_LOG_NAMES + fallback_log_names:
        path = evidence_dir / name
        errors = ["missing file"] if not path.exists() else validate_log_text(path.read_text(encoding="utf-8"))
        records.append({**runtime_file_record(path), "errors": errors})
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
    parser.add_argument("--safe-summary-output", type=Path)
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
    archive = materialize_authoritative_source(args.repository, args.materialization_root)
    write_source_metadata(
        args.evidence_dir, archive.source, archive.tree_id, archive.file_count, environment,
        archive.command, archive.started_at, archive.ended_at, archive.stdout, archive.stderr, archive.exit_code,
    )

    lockfile = archive.source / "pubspec.lock"
    lock_before = file_fingerprint(lockfile)
    pub_command = (args.flutter, "pub", "get")
    pub_started_at = utc_now()
    pub_exit_code, pub_stdout, pub_stderr = run_output(pub_command, archive.source)
    pub_ended_at = utc_now()
    lock_after = file_fingerprint(lockfile)
    changed_lockfile = lockfile_changed(lock_before, lock_after)
    write_combined_log(
        args.evidence_dir / "flutter_pub_get_1.3.11+28.log", pub_command, pub_started_at, pub_ended_at,
        environment, pub_exit_code, f"{pub_stdout}--- stderr ---\n{pub_stderr}",
        trailing_metadata=(
            f"Lockfile before: {json.dumps(lock_before, sort_keys=True)}",
            f"Lockfile after: {json.dumps(lock_after, sort_keys=True)}",
            f"Lockfile changed: {str(changed_lockfile).lower()}",
            "Classification: dependency lock unchanged; later evidence remains attributable to the authoritative source."
            if not changed_lockfile else
            "Classification: dependency lock changed; later analysis/test/build evidence is not run.",
        ),
    )

    exit_codes = [pub_exit_code]
    if not changed_lockfile:
        exit_codes.extend((
            write_command_log(args.evidence_dir / "flutter_analyze_1.3.11+28.log", (args.flutter, "analyze"), archive.source, environment),
            write_command_log(args.evidence_dir / "flutter_test_1.3.11+28.log", (args.flutter, "test"), archive.source, environment),
            write_build_log(
                args.evidence_dir / "build_android_1.3.11+28.log",
                (args.flutter, "build", "appbundle", "--release"), archive.source, environment,
                "Technical release-build evidence only; production upload signing is not verified.",
            ),
            write_build_log(
                args.evidence_dir / "build_ios_1.3.11+28.log",
                (args.flutter, "build", "ipa", "--release"), archive.source, environment,
                "Technical release-build evidence only; distribution/App Store ownership is not verified.",
            ),
        ))
        android_fallback = fallback_decision("android", (archive.source / "android" / "key.properties").is_file())
        ios_fallback = fallback_decision("ios", production_signing_verified=False)
        for decision in (android_fallback, ios_fallback):
            assert decision is not None
            command = (args.flutter, *decision.command[1:])
            write_build_log(args.evidence_dir / decision.log_name, command, archive.source, environment, decision.classification)

    summary = validate_evidence(args.evidence_dir)
    write_validation_file(args.evidence_dir, summary)
    artifacts = (
        (archive.source / "build/app/outputs/bundle/release/app-release.aab", "Technical release build only; Android upload signing is not verified."),
        (archive.source / "build/app/outputs/flutter-apk/app-debug.apk", "Non-production Android debug fallback."),
        (archive.source / "build/ios/ipa/Sookta.ipa", "Technical release build only; iOS distribution/App Store ownership is not verified."),
        (archive.source / "build/ios/archive/Runner.xcarchive", "Non-production iOS no-codesign fallback output, when created by the toolchain."),
    )
    existing_artifacts = tuple((path, classification) for path, classification in artifacts if path.exists())
    safe_summary = build_safe_summary(
        args.evidence_dir,
        tuple(args.evidence_dir / name for name in EVIDENCE_LOG_NAMES),
        existing_artifacts,
        {
            "commit": AUTHORITATIVE_COMMIT,
            "tree_id": archive.tree_id,
            "version": AUTHORITATIVE_VERSION,
            "file_count": archive.file_count,
            "archive_command": command_text(archive.command),
            "archive_started_at_utc": archive.started_at,
            "archive_ended_at_utc": archive.ended_at,
            "lockfile_before": lock_before,
            "lockfile_after": lock_after,
            "lockfile_changed": changed_lockfile,
        },
    )
    safe_summary_output = args.safe_summary_output or args.evidence_dir / "final_evidence_safe_summary.json"
    safe_summary_output.write_text(json.dumps(safe_summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    runtime_summary_errors = verify_runtime_summary(safe_summary)
    (args.evidence_dir / "verification_environment.json").write_text(
        json.dumps(
            {
                "environment": environment,
                "metadata_validation": summary,
                "runtime_summary": str(safe_summary_output),
                "runtime_summary_errors": runtime_summary_errors,
            },
            ensure_ascii=False, indent=2, sort_keys=True,
        ) + "\n",
        encoding="utf-8",
    )
    return 0 if not any(exit_codes) and not changed_lockfile and summary["valid"] and not runtime_summary_errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
