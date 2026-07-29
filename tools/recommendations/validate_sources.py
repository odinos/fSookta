#!/usr/bin/env python3
"""Validate local recommendation sources and protected ML model artifacts."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


REQUIRED_SOURCE_FIELDS = {
    "id",
    "title",
    "language",
    "localPath",
    "sha256",
    "priority",
    "documentRole",
    "copyrightOrDistributionNote",
}


def _load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_registry(registry_path: Path) -> list[str]:
    if not registry_path.is_file():
        return [f"missing_registry:{registry_path}"]
    payload = _load_json(registry_path)
    errors: list[str] = []
    sources = payload.get("sources")
    if not isinstance(sources, list) or not sources:
        return ["sources:must_be_non_empty_list"]
    seen_ids: set[str] = set()
    for index, source in enumerate(sources, start=1):
        if not isinstance(source, dict):
            errors.append(f"source:{index}:must_be_object")
            continue
        missing_fields = REQUIRED_SOURCE_FIELDS - set(source)
        if missing_fields:
            errors.append(f"source:{index}:fields:{sorted(missing_fields)}")
            continue
        source_id = str(source["id"])
        if source_id in seen_ids:
            errors.append(f"duplicate_source_id:{source_id}")
        seen_ids.add(source_id)
        path = Path(str(source["localPath"]))
        if not path.is_file():
            errors.append(f"missing:{source_id}")
            continue
        digest = _sha256(path)
        if digest != source["sha256"]:
            errors.append(f"sha256:{source_id}:{digest}")
    return errors


def validate_model_baseline(baseline_path: Path) -> list[str]:
    if not baseline_path.is_file():
        return [f"missing_model_baseline:{baseline_path}"]
    payload = _load_json(baseline_path)
    errors: list[str] = []
    artifacts = payload.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        return ["artifacts:must_be_non_empty_list"]
    seen_paths: set[str] = set()
    for index, artifact in enumerate(artifacts, start=1):
        if not isinstance(artifact, dict):
            errors.append(f"artifact:{index}:must_be_object")
            continue
        artifact_path = str(artifact.get("path", ""))
        expected_hash = str(artifact.get("sha256", ""))
        if not artifact_path or not expected_hash:
            errors.append(f"artifact:{index}:path_and_sha256_required")
            continue
        if artifact_path in seen_paths:
            errors.append(f"duplicate_artifact_path:{artifact_path}")
        seen_paths.add(artifact_path)
        path = Path(artifact_path)
        if not path.is_file():
            errors.append(f"missing_model:{artifact_path}")
            continue
        digest = _sha256(path)
        if digest != expected_hash:
            errors.append(f"model_sha256:{artifact_path}:{digest}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--registry",
        type=Path,
        default=Path("data/recommendations/source_registry.json"),
    )
    parser.add_argument(
        "--model-baseline",
        type=Path,
        default=Path("data/recommendations/baseline_model_hashes.json"),
    )
    args = parser.parse_args()
    errors = [
        *validate_registry(args.registry),
        *validate_model_baseline(args.model_baseline),
    ]
    if errors:
        for error in errors:
            print(error)
        return 1
    print("source_registry=PASS")
    print("model_baseline=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
