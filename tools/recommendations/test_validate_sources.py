from __future__ import annotations

from contextlib import redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from tools.recommendations.validate_sources import (
    main,
    validate_model_baseline,
    validate_registry,
)


class SourceRegistryTest(unittest.TestCase):
    def test_registered_sources_exist_and_match_sha256(self) -> None:
        errors = validate_registry(
            Path("data/recommendations/source_registry.json")
        )
        self.assertEqual(errors, [])

    def test_registered_model_artifacts_match_sha256(self) -> None:
        errors = validate_model_baseline(
            Path("data/recommendations/baseline_model_hashes.json")
        )
        self.assertEqual(errors, [])

    def test_unmarked_source_hash_mismatch_still_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            registry_path = self._write_registry(root)

            errors = validate_registry(registry_path)

        self.assertEqual(
            errors,
            [
                "sha256:current_app_recommendation_copy:"
                f"{hashlib.sha256(b'current').hexdigest()}"
            ],
        )

    def test_explicit_legacy_snapshot_policy_reports_drift_without_failure(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            registry_path = self._write_registry(
                root,
                hash_policy="legacy_baseline_snapshot",
            )
            model_path = root / "model.bin"
            model_path.write_bytes(b"model")
            model_baseline_path = root / "model_baseline.json"
            model_baseline_path.write_text(
                json.dumps(
                    {
                        "artifacts": [
                            {
                                "path": str(model_path),
                                "sha256": hashlib.sha256(b"model").hexdigest(),
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            output = io.StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    [
                        "validate_sources.py",
                        "--registry",
                        str(registry_path),
                        "--model-baseline",
                        str(model_baseline_path),
                    ],
                ),
                redirect_stdout(output),
            ):
                exit_code = main()

        self.assertEqual(exit_code, 0)
        self.assertIn(
            "legacy_baseline_drift:current_app_recommendation_copy:"
            f"{hashlib.sha256(b'original').hexdigest()}:"
            f"{hashlib.sha256(b'current').hexdigest()}",
            output.getvalue(),
        )

    def test_legacy_snapshot_policy_is_rejected_for_authoritative_sources(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            registry_path = self._write_registry(
                root,
                hash_policy="legacy_baseline_snapshot",
                source_id="body_map_recommendations",
                document_role="primary_recommendation_copy",
            )

            errors = validate_registry(registry_path)

        self.assertEqual(
            errors,
            ["hash_policy_not_allowed:body_map_recommendations"],
        )

    def _write_registry(
        self,
        root: Path,
        *,
        hash_policy: str | None = None,
        source_id: str = "current_app_recommendation_copy",
        document_role: str = "legacy_copy_and_ui_migration_audit",
    ) -> Path:
        source_path = root / "source.dart"
        source_path.write_bytes(b"current")
        source = {
            "id": source_id,
            "title": "Legacy app recommendation copy",
            "language": "th,en",
            "localPath": str(source_path),
            "sha256": hashlib.sha256(b"original").hexdigest(),
            "priority": 90,
            "documentRole": document_role,
            "copyrightOrDistributionNote": "Internal snapshot.",
        }
        if hash_policy is not None:
            source["hashPolicy"] = hash_policy
        registry_path = root / "source_registry.json"
        registry_path.write_text(
            json.dumps({"registryVersion": "test", "sources": [source]}),
            encoding="utf-8",
        )
        return registry_path


if __name__ == "__main__":
    unittest.main()
