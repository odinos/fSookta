from __future__ import annotations

from contextlib import redirect_stdout
import hashlib
import io
import json
import os
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
                local_path="lib/core/localization/sookta_strings.dart",
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
            original_directory = Path.cwd()
            try:
                os.chdir(root)
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
            finally:
                os.chdir(original_directory)

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

    def test_legacy_snapshot_policy_requires_the_canonical_repo_relative_path(
        self,
    ) -> None:
        invalid_paths = (
            "source.dart",
            "data/recommendations/recommendation_master.csv",
            None,
        )
        for invalid_path in invalid_paths:
            with self.subTest(local_path=invalid_path or "<absolute canonical>"):
                with tempfile.TemporaryDirectory() as temp_dir:
                    root = Path(temp_dir)
                    local_path = invalid_path or str(
                        root / "lib/core/localization/sookta_strings.dart"
                    )
                    registry_path = self._write_registry(
                        root,
                        hash_policy="legacy_baseline_snapshot",
                        local_path=local_path,
                    )

                    errors = self._validate_registry_from(root, registry_path)

                self.assertEqual(
                    errors,
                    [
                        "hash_policy_not_allowed:"
                        "current_app_recommendation_copy"
                    ],
                )

    def _write_registry(
        self,
        root: Path,
        *,
        hash_policy: str | None = None,
        source_id: str = "current_app_recommendation_copy",
        document_role: str = "legacy_copy_and_ui_migration_audit",
        local_path: str | None = None,
    ) -> Path:
        registry_local_path = local_path or str(root / "source.dart")
        candidate_path = Path(registry_local_path)
        source_path = (
            candidate_path
            if candidate_path.is_absolute()
            else root / candidate_path
        )
        source_path.parent.mkdir(parents=True, exist_ok=True)
        source_path.write_bytes(b"current")
        source = {
            "id": source_id,
            "title": "Legacy app recommendation copy",
            "language": "th,en",
            "localPath": registry_local_path,
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

    def _validate_registry_from(
        self,
        root: Path,
        registry_path: Path,
    ) -> list[str]:
        original_directory = Path.cwd()
        try:
            os.chdir(root)
            return validate_registry(registry_path)
        finally:
            os.chdir(original_directory)


if __name__ == "__main__":
    unittest.main()
