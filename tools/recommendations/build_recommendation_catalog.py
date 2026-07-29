#!/usr/bin/env python3
"""Build the immutable Dart catalog from fully approved recommendation copy."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
from typing import Iterable, Mapping, Optional, Sequence

try:
    from tools.recommendations.validate_recommendations import (
        validate_approved_catalog_rows,
    )
except ModuleNotFoundError:
    from validate_recommendations import validate_approved_catalog_rows


MasterRow = Mapping[str, str]
TranslationRow = Mapping[str, str]
ConflictRow = Mapping[str, str]


def _specificity(row: MasterRow) -> int:
    exact_activity = row["activity"] != "any"
    exact_body_part = row["body_part"] != "any"
    exact_risk_level = row["risk_level"] != "any"
    rank = {
        (True, True, True): 0,
        (True, False, True): 1,
        (False, True, True): 2,
        (True, False, False): 3,
        (False, True, False): 4,
        (False, False, False): 5,
    }
    shape = (exact_activity, exact_body_part, exact_risk_level)
    if shape not in rank:
        raise ValueError(
            "unsupported context shape: "
            f"{row['recommendation_id']} "
            f"({row['activity']}, {row['body_part']}, {row['risk_level']})"
        )
    return rank[shape]


def _dart_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
    )
    return f"'{escaped}'"


def _catalog_payload(
    rows: Iterable[MasterRow],
    translations: Mapping[str, TranslationRow],
) -> list[dict[str, object]]:
    return [
        {
            "id": row["recommendation_id"],
            "selectionKey": row["selection_key"],
            "displayOrder": int(row["display_order"]),
            "category": row["category"],
            "activity": row["activity"],
            "bodyPart": row["body_part"],
            "riskLevel": row["risk_level"],
            "thaiText": row["thai_source_text"],
            "englishText": translations[row["recommendation_id"]]["english_draft"],
            "sourceId": row["source_id"],
            "sourcePage": row["source_page"],
        }
        for row in rows
    ]


def _legacy_aliases(rows: Iterable[MasterRow]) -> dict[str, str]:
    aliases: dict[str, str] = {}
    for row in rows:
        for column in ("legacy_text_th", "legacy_text_en"):
            alias = row.get(column, "").strip()
            if not alias:
                continue
            existing = aliases.get(alias)
            if existing is not None and existing != row["selection_key"]:
                raise ValueError(f"legacy alias maps to multiple keys: {alias}")
            aliases[alias] = row["selection_key"]
    return aliases


def _append_const(lines: list[str], name: str, value: str) -> None:
    encoded = _dart_string(value)
    line = f"const {name} = {encoded};"
    if len(line) <= 80:
        lines.append(line)
        return
    lines.extend(
        [
            f"const {name} =",
            f"    {encoded};",
        ]
    )


def _append_named_string(
    lines: list[str],
    name: str,
    value: str,
) -> None:
    encoded = _dart_string(value)
    line = f"    {name}: {encoded},"
    if len(line) <= 80:
        lines.append(line)
        return
    lines.extend(
        [
            f"    {name}:",
            f"        {encoded},",
        ]
    )


def _append_map_entry(
    lines: list[str],
    key: str,
    value: str,
) -> None:
    encoded_key = _dart_string(key)
    encoded_value = _dart_string(value)
    line = f"  {encoded_key}: {encoded_value},"
    if len(line) <= 80:
        lines.append(line)
        return
    lines.extend(
        [
            f"  {encoded_key}:",
            f"      {encoded_value},",
        ]
    )


def build_catalog(
    master_rows: Sequence[MasterRow],
    translation_rows: Sequence[TranslationRow],
    *,
    conflict_rows: Sequence[ConflictRow] | None = None,
    source_registry_version: Optional[str] = None,
) -> str:
    """Return deterministic Dart source for a fully approved catalog."""

    validation_errors = validate_approved_catalog_rows(
        master_rows,
        translation_rows,
        conflict_rows,
    )
    if validation_errors:
        raise ValueError(
            "approved catalog validation failed: "
            + "; ".join(validation_errors)
        )
    translations = {
        row["recommendation_id"]: row for row in translation_rows
    }
    versions = {row.get("catalog_version", "") for row in master_rows}
    if len(versions) != 1 or not next(iter(versions)):
        raise ValueError("catalog version must be present and consistent")
    catalog_version = next(iter(versions))
    registry_version = source_registry_version or catalog_version

    sorted_rows = sorted(
        master_rows,
        key=lambda row: (
            row["selection_key"],
            _specificity(row),
            int(row["display_order"]),
            row["recommendation_id"],
        ),
    )
    payload = _catalog_payload(sorted_rows, translations)
    aliases = _legacy_aliases(sorted_rows)
    canonical = json.dumps(
        {
            "catalogVersion": catalog_version,
            "sourceRegistryVersion": registry_version,
            "catalog": payload,
            "legacyAliases": aliases,
        },
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    checksum = hashlib.sha256(canonical).hexdigest()

    lines = [
        "// GENERATED CODE - DO NOT MODIFY BY HAND.",
        "// Built only from 100% approved recommendation translations.",
        "",
        "import 'recommendation_catalog_models.dart';",
        "",
    ]
    _append_const(lines, "recommendationCatalogVersion", catalog_version)
    _append_const(
        lines,
        "recommendationSourceRegistryVersion",
        registry_version,
    )
    _append_const(lines, "recommendationCatalogChecksum", checksum)
    lines.extend(
        [
            "",
            "const generatedRecommendationCatalog = "
            "<RecommendationCatalogItem>[",
        ]
    )
    for item in payload:
        lines.append("  RecommendationCatalogItem(")
        _append_named_string(lines, "id", str(item["id"]))
        _append_named_string(
            lines,
            "selectionKey",
            str(item["selectionKey"]),
        )
        lines.append(f"    displayOrder: {item['displayOrder']},")
        _append_named_string(lines, "category", str(item["category"]))
        _append_named_string(lines, "activity", str(item["activity"]))
        _append_named_string(lines, "bodyPart", str(item["bodyPart"]))
        _append_named_string(lines, "riskLevel", str(item["riskLevel"]))
        _append_named_string(lines, "thaiText", str(item["thaiText"]))
        _append_named_string(
            lines,
            "englishText",
            str(item["englishText"]),
        )
        _append_named_string(lines, "sourceId", str(item["sourceId"]))
        _append_named_string(lines, "sourcePage", str(item["sourcePage"]))
        lines.append("  ),")
    lines.extend(
        [
            "];",
            "",
            "const generatedRecommendationLegacyAliases = <String, String>{",
        ]
    )
    for alias, selection_key in sorted(aliases.items()):
        _append_map_entry(lines, alias, selection_key)
    lines.extend(["};", ""])
    return "\n".join(lines)


def _read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--master", type=Path, required=True)
    parser.add_argument("--translations", type=Path, required=True)
    parser.add_argument("--conflicts", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    registry_path = args.master.parent / "source_registry.json"
    conflict_path = args.conflicts or (
        args.master.parent / "reports" / "conflicts_missing_sources.csv"
    )
    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    dart = build_catalog(
        _read_csv(args.master),
        _read_csv(args.translations),
        conflict_rows=(
            _read_csv(conflict_path) if conflict_path.is_file() else None
        ),
        source_registry_version=registry["registryVersion"],
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(dart, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
