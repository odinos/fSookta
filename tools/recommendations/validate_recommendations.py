#!/usr/bin/env python3
"""Validate recommendation editorial data and source coverage."""

from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter
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

REQUIRED_TRANSLATION_COLUMNS = {
    "recommendation_id",
    "selection_key",
    "record_type",
    "thai_source_text",
    "english_draft",
    "translation_style",
    "numbers_match",
    "units_match",
    "timing_match",
    "urgency_match",
    "negation_match",
    "meaning_review",
    "review_comment",
    "approval_status",
    "approved_by",
    "approved_at",
    "translation_version",
    "source_id",
    "source_page",
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


def _numbers(text: str) -> Counter[str]:
    return Counter(re.findall(r"\d+(?:\.\d+)?", text))


def validate_translation_review(
    master_path: Path,
    translation_path: Path,
    require_approved: bool,
) -> list[str]:
    if not master_path.is_file():
        return [f"missing_master:{master_path}"]
    if not translation_path.is_file():
        return [f"missing_translations:{translation_path}"]
    with master_path.open(encoding="utf-8-sig", newline="") as stream:
        master_rows = {
            row["recommendation_id"]: row for row in csv.DictReader(stream)
        }
    with translation_path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames is None:
            return ["translation_header:missing"]
        missing_header = REQUIRED_TRANSLATION_COLUMNS - set(reader.fieldnames)
        if missing_header:
            return [f"translation_columns:{sorted(missing_header)}"]
        translation_rows = list(reader)
    errors: list[str] = []
    seen_ids: set[str] = set()
    for index, row in enumerate(translation_rows, start=2):
        item_id = row["recommendation_id"]
        if item_id in seen_ids:
            errors.append(f"translation_duplicate:{item_id}")
        seen_ids.add(item_id)
        master = master_rows.get(item_id)
        if master is None:
            errors.append(f"translation_unknown:{item_id}")
            continue
        if row["thai_source_text"] != master["thai_source_text"]:
            errors.append(f"translation_thai_changed:{item_id}")
        english = row["english_draft"].strip()
        if not english:
            errors.append(f"translation_english_empty:{item_id}")
        if re.search(r"[ก-๙]", english):
            errors.append(f"translation_english_contains_thai:{item_id}")
        if _numbers(row["thai_source_text"]) != _numbers(english):
            errors.append(f"translation_numbers:{item_id}")
        if row["numbers_match"] == "fail" or row["units_match"] == "fail":
            errors.append(f"translation_parity:{item_id}")
        if row["approval_status"] not in {
            "pending",
            "needs_revision",
            "rejected",
            "approved",
        }:
            errors.append(f"translation_status:{index}:{row['approval_status']}")
    missing_ids = set(master_rows) - seen_ids
    if missing_ids:
        errors.append(f"translation_missing:{len(missing_ids)}")
    if require_approved:
        approved = sum(
            row["approval_status"] == "approved" for row in translation_rows
        )
        if approved != len(master_rows) or len(translation_rows) != len(master_rows):
            errors.append("approval_coverage_below_100")
        if any(
            row["approval_status"] in {"pending", "needs_revision", "rejected"}
            for row in translation_rows
        ):
            errors.append("approval_rows_unresolved")
        conflict_path = master_path.parent / "reports" / "conflicts_missing_sources.csv"
        if conflict_path.is_file():
            with conflict_path.open(encoding="utf-8-sig", newline="") as stream:
                conflicts = list(csv.DictReader(stream))
            if any(row["approval_status"] != "approved" for row in conflicts):
                errors.append("conflict_rows_pending")
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
    parser.add_argument("--translations", type=Path)
    parser.add_argument("--require-approved", action="store_true")
    args = parser.parse_args()
    errors = validate_master(args.master, args.registry)
    if args.translations is not None:
        errors.extend(
            validate_translation_review(
                args.master,
                args.translations,
                require_approved=args.require_approved,
            )
        )
    if errors:
        for error in errors:
            print(error)
        return 1
    print("recommendation_master=PASS")
    if args.translations is not None:
        print("translation_review=PASS")
        if not args.require_approved:
            print("approval_gate=PENDING_USER_REVIEW")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
