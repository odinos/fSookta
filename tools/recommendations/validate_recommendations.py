#!/usr/bin/env python3
"""Validate recommendation editorial data and source coverage."""

from __future__ import annotations

import argparse
import csv
from datetime import datetime
import json
import re
from collections import Counter
from pathlib import Path
from typing import Mapping, Sequence


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

REQUIRED_CONFLICT_COLUMNS = {
    "recommendation_id",
    "selection_key",
    "issue_type",
    "source_a",
    "source_b",
    "conflicting_value",
    "proposed_action",
    "approval_status",
}

REQUIRED_CONFLICT_RECOMMENDATION_IDS = frozenset(
    {
        "act_ref_weight_high.01",
        "act_avoid_bend.01",
        "act_harvest_empty_often.01",
        "act_ref_weight_low.01",
    }
)

APPROVED_IDENTITY_FIELDS = (
    "selection_key",
    "record_type",
    "thai_source_text",
    "source_id",
    "source_page",
)

REVIEW_CHECK_FIELDS = (
    "numbers_match",
    "units_match",
    "timing_match",
    "urgency_match",
    "negation_match",
    "meaning_review",
)

_ISO_TIMESTAMP_WITH_TIMEZONE = re.compile(
    r"^\d{4}-\d{2}-\d{2}T"
    r"\d{2}:\d{2}:\d{2}(?:\.\d+)?"
    r"(?:Z|[+-]\d{2}:\d{2})$"
)

_THAI_UNIT_MARKERS = re.compile(
    r"(?:"
    r"\d+\s*(?:กก\.?|กิโลกรัม|ซม\.?|เมตร|นาที|ปี|คน)"
    r"|ชั่วโมง"
    r")"
)

_TIMING_MARKERS = re.compile(
    r"(?:"
    r"นาที|ชั่วโมง|ทุกวัน|รายวัน|สัปดาห์|เดือน|ปี"
    r"|\b(?:minutes?|hours?|daily|weekly|monthly|yearly|years?|"
    r"every|continuous(?:ly)?)\b"
    r")",
    re.IGNORECASE,
)

_URGENCY_MARKERS = re.compile(
    r"(?:"
    r"ทันที|เร่งด่วน|หยุดงาน|หยุดทันที"
    r"|\b(?:immediately|urgent(?:ly)?|stop work|stop immediately)\b"
    r")",
    re.IGNORECASE,
)

_NEGATION_MARKERS = re.compile(
    r"(?:"
    r"ไม่|ห้าม|หลีกเลี่ยง|อย่า"
    r"|\b(?:no|not|never|avoid|without|do not|should not|must not)\b"
    r")",
    re.IGNORECASE,
)


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


def _valid_not_applicable(
    field: str,
    thai_text: str,
    english_text: str,
) -> bool:
    combined = f"{thai_text}\n{english_text}"
    if field == "numbers_match":
        return not _numbers(thai_text) and not _numbers(english_text)
    if field == "units_match":
        return _THAI_UNIT_MARKERS.search(thai_text) is None
    if field == "timing_match":
        return _TIMING_MARKERS.search(combined) is None
    if field == "urgency_match":
        return _URGENCY_MARKERS.search(combined) is None
    if field == "negation_match":
        return _NEGATION_MARKERS.search(combined) is None
    return False


def _valid_approval_timestamp(value: str) -> bool:
    if _ISO_TIMESTAMP_WITH_TIMEZONE.fullmatch(value) is None:
        return False
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return parsed.utcoffset() is not None


def validate_approved_catalog_rows(
    master_rows: Sequence[Mapping[str, str]],
    translation_rows: Sequence[Mapping[str, str]],
    conflict_rows: Sequence[Mapping[str, str]] | None,
) -> list[str]:
    """Fail closed unless every artifact is ready for approved generation."""

    errors: list[str] = []
    master_by_id: dict[str, Mapping[str, str]] = {}
    for row in master_rows:
        item_id = row.get("recommendation_id", "")
        if not item_id:
            errors.append("approved_master_id_empty")
            continue
        if item_id in master_by_id:
            errors.append(f"approved_master_duplicate:{item_id}")
            continue
        master_by_id[item_id] = row
        status = row.get("record_status", "")
        if status != "source_verified":
            errors.append(f"approved_master_status:{item_id}:{status}")
        if not row.get("thai_source_text", "").strip():
            errors.append(f"approved_master_thai_empty:{item_id}")

    if not master_by_id:
        errors.append("approved_master_empty")

    translations_by_id: dict[str, Mapping[str, str]] = {}
    for row in translation_rows:
        item_id = row.get("recommendation_id", "")
        if not item_id:
            errors.append("approved_review_id_empty")
            continue
        if item_id in translations_by_id:
            errors.append(f"approved_review_duplicate:{item_id}")
            continue
        translations_by_id[item_id] = row
        master = master_by_id.get(item_id)
        if master is None:
            errors.append(f"approved_review_unknown:{item_id}")
            continue

        for field in APPROVED_IDENTITY_FIELDS:
            if row.get(field, "") != master.get(field, ""):
                errors.append(f"approved_identity:{item_id}:{field}")

        thai_text = row.get("thai_source_text", "")
        english_text = row.get("english_draft", "")
        if not thai_text.strip():
            errors.append(f"approved_thai_empty:{item_id}")
        if not english_text.strip():
            errors.append(f"approved_english_empty:{item_id}")
        if re.search(r"[ก-๙]", english_text):
            errors.append(f"approved_english_contains_thai:{item_id}")
        if _numbers(thai_text) != _numbers(english_text):
            errors.append(f"approved_number_content_mismatch:{item_id}")

        if row.get("translation_style", "") not in {
            "direct",
            "plain_english",
        }:
            errors.append(f"approved_translation_style:{item_id}")

        for field in REVIEW_CHECK_FIELDS:
            result = row.get(field, "")
            if result == "pass":
                continue
            if result == "not_applicable":
                if not _valid_not_applicable(field, thai_text, english_text):
                    errors.append(
                        f"approved_not_applicable_invalid:{item_id}:{field}"
                    )
                continue
            errors.append(
                f"approved_review_unresolved:{item_id}:{field}:{result}"
            )

        approval_status = row.get("approval_status", "")
        if approval_status != "approved":
            errors.append(
                f"approved_status:{item_id}:{approval_status}"
            )
        if not row.get("approved_by", "").strip():
            errors.append(f"approved_by_empty:{item_id}")
        if not _valid_approval_timestamp(row.get("approved_at", "")):
            errors.append(f"approved_at_invalid:{item_id}")
        version = row.get("translation_version", "")
        if re.fullmatch(r"[1-9]\d*", version) is None:
            errors.append(
                f"approved_translation_version:{item_id}:{version}"
            )

    missing_reviews = sorted(set(master_by_id) - set(translations_by_id))
    for item_id in missing_reviews:
        errors.append(f"approved_review_missing:{item_id}")

    if conflict_rows is None:
        errors.append("approved_conflict_report_missing")
        return errors

    expected_conflicts = (
        REQUIRED_CONFLICT_RECOMMENDATION_IDS & set(master_by_id)
    )
    seen_conflicts: set[str] = set()
    for row in conflict_rows:
        item_id = row.get("recommendation_id", "")
        if not item_id:
            errors.append("approved_conflict_id_empty")
            continue
        if item_id in seen_conflicts:
            errors.append(f"approved_conflict_duplicate:{item_id}")
            continue
        seen_conflicts.add(item_id)
        master = master_by_id.get(item_id)
        if master is None or item_id not in expected_conflicts:
            errors.append(f"approved_conflict_unknown:{item_id}")
            continue
        if row.get("selection_key", "") != master.get("selection_key", ""):
            errors.append(
                f"approved_conflict_identity:{item_id}:selection_key"
            )
        for field in (
            "issue_type",
            "source_a",
            "source_b",
            "conflicting_value",
            "proposed_action",
        ):
            if not row.get(field, "").strip():
                errors.append(
                    f"approved_conflict_metadata:{item_id}:{field}"
                )
        approval_status = row.get("approval_status", "")
        if approval_status != "approved":
            errors.append(
                f"approved_conflict_status:{item_id}:{approval_status}"
            )

    for item_id in sorted(expected_conflicts - seen_conflicts):
        errors.append(f"approved_conflict_coverage_missing:{item_id}")
    return errors


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
        master_row_list = list(csv.DictReader(stream))
        master_rows: dict[str, dict[str, str]] = {}
        for row in master_row_list:
            master_rows.setdefault(row["recommendation_id"], row)
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
        conflict_path = master_path.parent / "reports" / "conflicts_missing_sources.csv"
        conflict_rows: list[dict[str, str]] | None = None
        if conflict_path.is_file():
            with conflict_path.open(encoding="utf-8-sig", newline="") as stream:
                conflict_reader = csv.DictReader(stream)
                if conflict_reader.fieldnames is None:
                    errors.append("approved_conflict_header_missing")
                    conflict_rows = []
                else:
                    missing_conflict_columns = (
                        REQUIRED_CONFLICT_COLUMNS
                        - set(conflict_reader.fieldnames)
                    )
                    if missing_conflict_columns:
                        errors.append(
                            "approved_conflict_columns:"
                            f"{sorted(missing_conflict_columns)}"
                        )
                    conflict_rows = list(conflict_reader)
        errors.extend(
            validate_approved_catalog_rows(
                master_row_list,
                translation_rows,
                conflict_rows,
            )
        )
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
