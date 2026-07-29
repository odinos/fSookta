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

EXPECTED_SOURCE_IDS = {
    "body_map_recommendations",
    "app_recommendations_v3",
    "ilo_ergonomic_checkpoints_agriculture",
    "reba_employee_assessment_worksheet",
    "iso11228_pirawan_project_workbook",
    "current_app_recommendation_copy",
}

EXPECTED_MODEL_PATHS = {
    "assets/models/xgboost_model.onnx",
    "assets/models/xgboost_model_metadata.json",
    "assets/ml/daily_injury_logistic_model.json",
    "assets/ml/movenet_thunder.tflite",
    "assets/ml/movenet_multipose_lightning.tflite",
}


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

    def test_registry_rejects_deletion_of_any_required_source(self) -> None:
        payload = json.loads(
            Path("data/recommendations/source_registry.json").read_text(
                encoding="utf-8"
            )
        )
        for source_id in sorted(EXPECTED_SOURCE_IDS):
            with self.subTest(source_id=source_id):
                mutated = dict(payload)
                mutated["sources"] = [
                    source
                    for source in payload["sources"]
                    if source["id"] != source_id
                ]
                with tempfile.TemporaryDirectory() as temp_dir:
                    registry_path = Path(temp_dir) / "registry.json"
                    registry_path.write_text(
                        json.dumps(mutated),
                        encoding="utf-8",
                    )

                    errors = validate_registry(registry_path)

                self.assertIn(f"required_source_missing:{source_id}", errors)

    def test_registry_rejects_unexpected_source_ids(self) -> None:
        payload = json.loads(
            Path("data/recommendations/source_registry.json").read_text(
                encoding="utf-8"
            )
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            extra_path = Path(temp_dir) / "extra-source.bin"
            extra_path.write_bytes(b"extra")
            extra_source = dict(payload["sources"][0])
            extra_source.update(
                {
                    "id": "unexpected_source",
                    "localPath": str(extra_path),
                    "sha256": hashlib.sha256(b"extra").hexdigest(),
                }
            )
            payload["sources"].append(extra_source)
            registry_path = Path(temp_dir) / "registry.json"
            registry_path.write_text(
                json.dumps(payload),
                encoding="utf-8",
            )

            errors = validate_registry(registry_path)

        self.assertIn("unexpected_source_id:unexpected_source", errors)

    def test_model_baseline_rejects_deletion_of_any_required_path(self) -> None:
        payload = json.loads(
            Path("data/recommendations/baseline_model_hashes.json").read_text(
                encoding="utf-8"
            )
        )
        for model_path in sorted(EXPECTED_MODEL_PATHS):
            with self.subTest(model_path=model_path):
                mutated = dict(payload)
                mutated["artifacts"] = [
                    artifact
                    for artifact in payload["artifacts"]
                    if artifact["path"] != model_path
                ]
                with tempfile.TemporaryDirectory() as temp_dir:
                    baseline_path = Path(temp_dir) / "baseline.json"
                    baseline_path.write_text(
                        json.dumps(mutated),
                        encoding="utf-8",
                    )

                    errors = validate_model_baseline(baseline_path)

                self.assertIn(f"required_model_missing:{model_path}", errors)

    def test_model_baseline_rejects_unexpected_paths(self) -> None:
        payload = json.loads(
            Path("data/recommendations/baseline_model_hashes.json").read_text(
                encoding="utf-8"
            )
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            extra_path = Path(temp_dir) / "extra-model.bin"
            extra_path.write_bytes(b"extra")
            payload["artifacts"].append(
                {
                    "path": str(extra_path),
                    "sha256": hashlib.sha256(b"extra").hexdigest(),
                }
            )
            baseline_path = Path(temp_dir) / "baseline.json"
            baseline_path.write_text(
                json.dumps(payload),
                encoding="utf-8",
            )

            errors = validate_model_baseline(baseline_path)

        self.assertIn(f"unexpected_model_path:{extra_path}", errors)

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
            model_baseline_path = root / "model_baseline.json"
            artifacts = []
            for model_path_value in sorted(EXPECTED_MODEL_PATHS):
                model_path = root / model_path_value
                model_path.parent.mkdir(parents=True, exist_ok=True)
                model_path.write_bytes(b"model")
                artifacts.append(
                    {
                        "path": model_path_value,
                        "sha256": hashlib.sha256(b"model").hexdigest(),
                    }
                )
            model_baseline_path.write_text(
                json.dumps({"artifacts": artifacts}),
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
        sources = []
        for required_source_id in sorted(EXPECTED_SOURCE_IDS):
            is_target = required_source_id == source_id
            candidate_local_path = (
                registry_local_path
                if is_target
                else str(root / f"{required_source_id}.source")
            )
            candidate_path = Path(candidate_local_path)
            source_path = (
                candidate_path
                if candidate_path.is_absolute()
                else root / candidate_path
            )
            source_path.parent.mkdir(parents=True, exist_ok=True)
            source_path.write_bytes(b"current")
            source = {
                "id": required_source_id,
                "title": f"Source {required_source_id}",
                "language": "th,en",
                "localPath": candidate_local_path,
                "sha256": hashlib.sha256(
                    b"original" if is_target else b"current"
                ).hexdigest(),
                "priority": 90,
                "documentRole": (
                    document_role
                    if is_target
                    else "supporting_ergonomic_evidence"
                ),
                "copyrightOrDistributionNote": "Internal snapshot.",
            }
            if is_target and hash_policy is not None:
                source["hashPolicy"] = hash_policy
            sources.append(source)
        registry_path = root / "source_registry.json"
        registry_path.write_text(
            json.dumps({"registryVersion": "test", "sources": sources}),
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
