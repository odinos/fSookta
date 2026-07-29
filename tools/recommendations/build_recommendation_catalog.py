#!/usr/bin/env python3
"""Build the immutable Dart catalog from fully approved recommendation copy."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
from typing import Iterable, Mapping, Optional, Sequence


MasterRow = Mapping[str, str]
TranslationRow = Mapping[str, str]


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
    return rank.get((exact_activity, exact_body_part, exact_risk_level), 6)


def _dart_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
    )
    return f"'{escaped}'"


def _approved_translations(
    master_rows: Sequence[MasterRow],
    translation_rows: Sequence[TranslationRow],
) -> dict[str, TranslationRow]:
    translations: dict[str, TranslationRow] = {}
    for row in translation_rows:
        item_id = row.get("recommendation_id", "")
        if not item_id or item_id in translations:
            raise ValueError("approval coverage must be 100%")
        translations[item_id] = row

    master_ids = [row.get("recommendation_id", "") for row in master_rows]
    if (
        not master_ids
        or any(not item_id for item_id in master_ids)
        or len(set(master_ids)) != len(master_ids)
        or set(master_ids) != set(translations)
        or any(row.get("approval_status") != "approved" for row in translation_rows)
    ):
        raise ValueError("approval coverage must be 100%")

    for master in master_rows:
        translation = translations[master["recommendation_id"]]
        if (
            translation.get("selection_key") != master.get("selection_key")
            or translation.get("thai_source_text") != master.get("thai_source_text")
            or not translation.get("english_draft", "").strip()
        ):
            raise ValueError("approved translation does not match master")
    return translations


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


def build_catalog(
    master_rows: Sequence[MasterRow],
    translation_rows: Sequence[TranslationRow],
    *,
    source_registry_version: Optional[str] = None,
) -> str:
    """Return deterministic Dart source for a fully approved catalog."""

    translations = _approved_translations(master_rows, translation_rows)
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
    canonical = json.dumps(
        payload,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    checksum = hashlib.sha256(canonical).hexdigest()
    aliases = _legacy_aliases(sorted_rows)

    lines = [
        "// GENERATED CODE - DO NOT MODIFY BY HAND.",
        "// Built only from 100% approved recommendation translations.",
        "",
        "import 'recommendation_catalog_models.dart';",
        "",
        f"const recommendationCatalogVersion = {_dart_string(catalog_version)};",
        (
            "const recommendationSourceRegistryVersion = "
            f"{_dart_string(registry_version)};"
        ),
        f"const recommendationCatalogChecksum = {_dart_string(checksum)};",
        "",
        "const generatedRecommendationCatalog = <RecommendationCatalogItem>[",
    ]
    for item in payload:
        lines.extend(
            [
                "  RecommendationCatalogItem(",
                f"    id: {_dart_string(str(item['id']))},",
                f"    selectionKey: {_dart_string(str(item['selectionKey']))},",
                f"    displayOrder: {item['displayOrder']},",
                f"    category: {_dart_string(str(item['category']))},",
                f"    activity: {_dart_string(str(item['activity']))},",
                f"    bodyPart: {_dart_string(str(item['bodyPart']))},",
                f"    riskLevel: {_dart_string(str(item['riskLevel']))},",
                f"    thaiText: {_dart_string(str(item['thaiText']))},",
                f"    englishText: {_dart_string(str(item['englishText']))},",
                f"    sourceId: {_dart_string(str(item['sourceId']))},",
                f"    sourcePage: {_dart_string(str(item['sourcePage']))},",
                "  ),",
            ]
        )
    lines.extend(
        [
            "];",
            "",
            "const generatedRecommendationLegacyAliases = <String, String>{",
        ]
    )
    for alias, selection_key in sorted(aliases.items()):
        lines.append(
            f"  {_dart_string(alias)}: {_dart_string(selection_key)},"
        )
    lines.extend(["};", ""])
    return "\n".join(lines)


def _read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--master", type=Path, required=True)
    parser.add_argument("--translations", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    registry_path = args.master.parent / "source_registry.json"
    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    dart = build_catalog(
        _read_csv(args.master),
        _read_csv(args.translations),
        source_registry_version=registry["registryVersion"],
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(dart, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
