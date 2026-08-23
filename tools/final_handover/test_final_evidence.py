"""Tests for final-version evidence capture helpers."""
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPOSITORY_ROOT / "tools" / "final_handover" / "final_evidence.py"
SPEC = importlib.util.spec_from_file_location("final_evidence", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
final_evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(final_evidence)


class FinalEvidenceTest(unittest.TestCase):
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
