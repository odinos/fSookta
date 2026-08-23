"""Tests for final-version evidence capture helpers."""
from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPOSITORY_ROOT / "tools" / "final_handover" / "final_evidence.py"
SUMMARY_VERIFIER = REPOSITORY_ROOT / "tools" / "final_handover" / "verify_final_evidence_summary.py"
SPEC = importlib.util.spec_from_file_location("final_evidence", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
final_evidence = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = final_evidence
SPEC.loader.exec_module(final_evidence)


class FinalEvidenceTest(unittest.TestCase):
    def test_lockfile_fingerprint_detects_unchanged_and_changed_lockfiles(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            lockfile = Path(temporary_directory) / "pubspec.lock"
            lockfile.write_text("packages: {}\n", encoding="utf-8")
            before = final_evidence.file_fingerprint(lockfile)
            unchanged = final_evidence.file_fingerprint(lockfile)
            lockfile.write_text("packages: {camera: 1}\n", encoding="utf-8")
            changed = final_evidence.file_fingerprint(lockfile)

        self.assertFalse(final_evidence.lockfile_changed(before, unchanged))
        self.assertTrue(final_evidence.lockfile_changed(before, changed))

    def test_source_metadata_uses_executed_archive_command_and_timestamps(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            destination = final_evidence.write_source_metadata(
                evidence_dir=directory,
                source=directory / "source",
                tree_id="tree",
                file_count=1,
                environment={"tool": "test"},
                archive_command=("git", "archive", "--output", str(directory / "source.tar"), "commit"),
                started_at="2026-08-23T00:00:00Z",
                ended_at="2026-08-23T00:00:03Z",
                archive_stdout="archive stdout\n",
                archive_stderr="archive stderr\n",
                exit_code=0,
            )
            content = destination.read_text(encoding="utf-8")

        self.assertIn(f"Command: git archive --output {directory / 'source.tar'} commit", content)
        self.assertIn("Start timestamp (UTC): 2026-08-23T00:00:00Z", content)
        self.assertIn("End timestamp (UTC): 2026-08-23T00:00:03Z", content)
        self.assertIn("archive stdout", content)
        self.assertIn("archive stderr", content)

    def test_fallback_decision_requires_nonproduction_attempt_without_signing_proof(self) -> None:
        android = final_evidence.fallback_decision("android", production_signing_verified=False)
        ios = final_evidence.fallback_decision("ios", production_signing_verified=False)

        self.assertEqual(android.log_name, "build_android_fallback_debug_1.3.11+28.log")
        self.assertEqual(android.command[-2:], ("apk", "--debug"))
        self.assertIn("Non-production", android.classification)
        self.assertEqual(ios.log_name, "build_ios_fallback_no_codesign_1.3.11+28.log")
        self.assertEqual(ios.command[-1], "--no-codesign")
        self.assertIsNone(final_evidence.fallback_decision("android", production_signing_verified=True))

    def test_validation_file_and_safe_summary_match_runtime_hashes_and_sizes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            log = directory / "build_android_1.3.11+28.log"
            artifact = directory / "app-debug.apk"
            log.write_text("evidence\n", encoding="utf-8")
            artifact.write_bytes(b"artifact")
            summary = final_evidence.build_safe_summary(
                evidence_dir=directory,
                primary_logs=(log,),
                artifacts=((artifact, "Non-production test artifact."),),
                source_metadata={"commit": "commit"},
            )
            summary_path = directory / "safe_summary.json"
            summary_path.write_text(json.dumps(summary), encoding="utf-8")
            validation_path = final_evidence.write_validation_file(directory, {"valid": True})

            self.assertEqual(final_evidence.verify_runtime_summary(summary), [])
            self.assertEqual(summary["primary_logs"][0]["byte_size"], len(b"evidence\n"))
            self.assertEqual(summary["artifacts"][0]["byte_size"], len(b"artifact"))
            self.assertEqual(validation_path.name, "metadata_validation.json")

    def test_safe_summary_hashes_and_sizes_directory_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            archive = directory / "Runner.xcarchive"
            archive.mkdir()
            (archive / "Info.plist").write_bytes(b"archive data")
            summary = final_evidence.build_safe_summary(
                evidence_dir=directory,
                primary_logs=(),
                artifacts=((archive, "Non-production no-codesign archive."),),
                source_metadata={},
            )
            self.assertEqual(final_evidence.verify_runtime_summary(summary), [])
            self.assertEqual(summary["artifacts"][0]["byte_size"], len(b"archive data"))

    def test_standalone_summary_verifier_compares_hashes_and_sizes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            payload = directory / "payload.bin"
            payload.write_bytes(b"payload")
            fingerprint = final_evidence.file_fingerprint(payload)
            summary = directory / "summary.json"
            summary.write_text(json.dumps({"evidence": {"primary_logs": [{"path": str(payload), **fingerprint}], "fallback_logs": []}, "technical_artifacts": []}), encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(SUMMARY_VERIFIER), "--summary", str(summary)],
                cwd=REPOSITORY_ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("1 records matched", result.stdout)
    def test_validation_covers_every_created_text_evidence_log(self) -> None:
        self.assertEqual(
            final_evidence.EVIDENCE_LOG_NAMES,
            (
                "final_source_metadata.txt",
                "flutter_pub_get_1.3.11+28.log",
                "flutter_analyze_1.3.11+28.log",
                "flutter_test_1.3.11+28.log",
                "build_android_1.3.11+28.log",
                "build_ios_1.3.11+28.log",
            ),
        )

    def test_log_header_contains_auditable_required_metadata(self) -> None:
        header = final_evidence.render_log_header(
            command=("/Users/kpc/develop/flutter/bin/flutter", "test"),
            started_at="2026-08-23T00:00:00Z",
            environment={"flutter": "Flutter 3.x", "operating_system": "macOS"},
        )

        self.assertIn("Version: 1.3.11+28", header)
        self.assertIn("Commit: bf8867a2083357cb9d60915bf6c2233801f923d8", header)
        self.assertIn("Command: /Users/kpc/develop/flutter/bin/flutter test", header)
        self.assertIn("Start timestamp (UTC): 2026-08-23T00:00:00Z", header)
        self.assertIn("Environment:", header)

    def test_validate_log_reports_each_missing_required_field(self) -> None:
        errors = final_evidence.validate_log_text("Command: flutter test\n")

        self.assertEqual(
            errors,
            [
                "missing Version: 1.3.11+28",
                "missing Commit: bf8867a2083357cb9d60915bf6c2233801f923d8",
                "missing Start timestamp (UTC):",
                "missing End timestamp (UTC):",
                "missing Environment:",
                "missing Exit code:",
                "missing complete stdout/stderr marker",
            ],
        )

    def test_validate_log_requires_the_exact_command_metadata_field(self) -> None:
        complete_except_command = "\n".join(
            (
                "Version: 1.3.11+28",
                "Commit: bf8867a2083357cb9d60915bf6c2233801f923d8",
                "Start timestamp (UTC): 2026-08-23T00:00:00Z",
                "End timestamp (UTC): 2026-08-23T00:01:00Z",
                "Environment: {}",
                "Exit code: 0",
                "Complete stdout/stderr follows:",
            )
        )

        self.assertIn("missing Command:", final_evidence.validate_log_text(complete_except_command))

    def test_write_combined_log_marks_complete_output_and_exit_code(self) -> None:
        destination = REPOSITORY_ROOT / ".test-final-evidence.log"
        self.addCleanup(destination.unlink, missing_ok=True)

        final_evidence.write_combined_log(
            destination,
            ("flutter", "build", "appbundle", "--release"),
            "2026-08-23T00:00:00Z",
            "2026-08-23T00:01:00Z",
            {"flutter": "test"},
            1,
            "build output\n",
        )

        content = destination.read_text(encoding="utf-8")
        self.assertEqual(final_evidence.validate_log_text(content), [])
        self.assertIn("--- combined stdout/stderr ---", content)
        self.assertIn("Exit code: 1", content)


if __name__ == "__main__":
    unittest.main()
