#!/usr/bin/env python3
"""Validate recommendation editorial data and source coverage."""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path


REQUIRED_MASTER_COLUMNS = {
    "recommendation_id",
    "selection_key",
    "display_order",
    "record_type",
    "category",
    "activity",
    "body_part",
    "risk_level",
    "trigger_condition",
    "thai_source_text",
    "source_id",
    "source_page",
    "source_section",
    "source_priority",
    "catalog_version",
    "record_status",
    "legacy_text_th",
    "legacy_text_en",
}


def extract_current_recommendation_keys(strings_path: Path) -> set[str]:
    text = strings_path.read_text(encoding="utf-8")
    return set(re.findall(r"'(act_[a-z0-9_]+)'\s*:", text))


def validate_master(master_path: Path, registry_path: Path) -> list[str]:
    if not master_path.is_file():
        return [f"missing_master:{master_path}"]
    if not registry_path.is_file():
        return [f"missing_registry:{registry_path}"]
    with master_path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames is None:
            return ["master_header:missing"]
        missing_header = REQUIRED_MASTER_COLUMNS - set(reader.fieldnames)
        if missing_header:
            return [f"columns:{sorted(missing_header)}"]
        rows = list(reader)
    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    source_ids = {item["id"] for item in registry["sources"]}
    errors: list[str] = []
    seen_ids: set[str] = set()
    seen_orders: set[tuple[str, str]] = set()
    for index, row in enumerate(rows, start=2):
        recommendation_id = row["recommendation_id"].strip()
        if not recommendation_id:
            errors.append(f"id:{index}")
        elif recommendation_id in seen_ids:
            errors.append(f"duplicate_id:{recommendation_id}")
        seen_ids.add(recommendation_id)
        order_key = (row["selection_key"], row["display_order"])
        if order_key in seen_orders:
            errors.append(f"duplicate_order:{order_key}")
        seen_orders.add(order_key)
        if row["source_id"] not in source_ids:
            errors.append(f"source:{index}:{row['source_id']}")
        if not row["thai_source_text"].strip():
            errors.append(f"thai:{index}")
        if row["record_status"] not in {
            "source_verified",
            "conflict",
            "missing_source",
        }:
            errors.append(f"status:{index}:{row['record_status']}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--master",
        type=Path,
        default=Path("data/recommendations/recommendation_master.csv"),
    )
    parser.add_argument(
        "--registry",
        type=Path,
        default=Path("data/recommendations/source_registry.json"),
    )
    args = parser.parse_args()
    errors = validate_master(args.master, args.registry)
    if errors:
        for error in errors:
            print(error)
        return 1
    print("recommendation_master=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
