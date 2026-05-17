#!/usr/bin/env python3
"""Create QA reports and expert-label templates from extracted pose features."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


METADATA_COLUMNS = [
    "activity_id",
    "activity",
    "session_id",
    "source_path",
    "source_kind",
    "frame_timestamp_ms",
    "frame_index",
    "image_width",
    "image_height",
    "pose_score",
    "pose_status",
    "error",
]

LABEL_TEMPLATE_COLUMNS = [
    "sample_id",
    *METADATA_COLUMNS,
    "suggested_include_for_training",
    "qa_flag",
    "expert_reba_score",
    "expert_risk_level",
    "reba_trunk_posture_code",
    "reba_neck_posture_code",
    "reba_leg_posture_code",
    "reba_trunk_twist",
    "reba_trunk_side_flex",
    "reba_upper_arm_code",
    "reba_lower_arm_code",
    "reba_wrist_posture_code",
    "reba_wrist_twist",
    "reba_load_category",
    "reba_coupling_category",
    "reba_activity_category",
    "iso_load_weight_kg",
    "iso_lift_frequency_per_min",
    "iso_lift_duration_hours",
    "iso_vertical_position_cm",
    "iso_horizontal_distance_cm",
    "iso_rwl_kg",
    "iso_lifting_index",
    "push_initial_force_n",
    "push_sustained_force_n",
    "push_initial_limit_n",
    "push_sustained_limit_n",
    "primary_body_part",
    "secondary_body_part",
    "pain_score_0_10",
    "treatment_cost_thb",
    "lost_income_thb",
    "lost_work_days",
    "action_recommendation",
    "label_source",
    "labeler_id",
    "label_date",
    "label_notes",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate fSookta research dataset QA and labeling files.",
    )
    parser.add_argument(
        "--dataset",
        default="data/research/extracted/pose_feature_dataset.csv",
        help="Extracted MoveNet feature dataset CSV.",
    )
    parser.add_argument(
        "--output-dir",
        default="data/research/extracted/qa",
        help="Output directory for QA reports and label templates.",
    )
    parser.add_argument(
        "--min-pose-score",
        type=float,
        default=0.2,
        help="Pose score threshold used to recommend training inclusion.",
    )
    return parser.parse_args()


def read_dataset(path: Path) -> tuple[list[dict[str, str]], list[str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        fieldnames = reader.fieldnames or []
    if not rows:
        raise ValueError(f"Dataset is empty: {path}")
    validate_columns(fieldnames)
    return rows, fieldnames


def validate_columns(fieldnames: list[str]) -> None:
    missing = [column for column in METADATA_COLUMNS if column not in fieldnames]
    if missing:
        raise ValueError(f"Dataset missing required columns: {', '.join(missing)}")

    feature_columns = infer_feature_columns(fieldnames)
    if len(feature_columns) != 51:
        raise ValueError(f"Expected 51 feature columns, found {len(feature_columns)}.")


def infer_feature_columns(fieldnames: list[str]) -> list[str]:
    ignored = set(METADATA_COLUMNS) | {"label_source", "pseudo_reba_score", "pseudo_risk_level"}
    return [name for name in fieldnames if name not in ignored]


def pose_score(row: dict[str, str]) -> float:
    try:
        value = float(row["pose_score"])
    except (TypeError, ValueError):
        return 0.0
    if not math.isfinite(value):
        return 0.0
    return value


def sample_id(row: dict[str, str]) -> str:
    raw = "|".join([
        row.get("activity", ""),
        row.get("session_id", ""),
        row.get("source_path", ""),
        row.get("frame_timestamp_ms", ""),
        row.get("frame_index", ""),
    ])
    digest = hashlib.sha1(raw.encode("utf-8")).hexdigest()[:12]
    return f"pose_{digest}"


def qa_flag(row: dict[str, str], min_pose_score: float) -> str:
    if row.get("error"):
        return "error"
    if row.get("pose_status") != "ok":
        return row.get("pose_status") or "not_ok"
    if pose_score(row) < min_pose_score:
        return "below_threshold"
    return "ok"


def include_for_training(row: dict[str, str], min_pose_score: float) -> str:
    return "yes" if qa_flag(row, min_pose_score) == "ok" else "no"


def score_summary(scores: list[float]) -> dict[str, Any]:
    if not scores:
        return {
            "count": 0,
            "min": None,
            "mean": None,
            "median": None,
            "max": None,
        }
    sorted_scores = sorted(scores)
    return {
        "count": len(scores),
        "min": round(sorted_scores[0], 6),
        "mean": round(statistics.fmean(sorted_scores), 6),
        "median": round(statistics.median(sorted_scores), 6),
        "max": round(sorted_scores[-1], 6),
    }


def grouped_counts(rows: list[dict[str, str]], keys: list[str]) -> list[dict[str, Any]]:
    groups: dict[tuple[str, ...], list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        groups[tuple(row[key] for key in keys)].append(row)

    output: list[dict[str, Any]] = []
    for group_key, group_rows in sorted(groups.items()):
        statuses = Counter(row["pose_status"] for row in group_rows)
        kinds = Counter(row["source_kind"] for row in group_rows)
        scores = [pose_score(row) for row in group_rows]
        item = {key: value for key, value in zip(keys, group_key)}
        item.update({
            "row_count": len(group_rows),
            "image_rows": kinds.get("image", 0),
            "video_rows": kinds.get("video", 0),
            "ok_rows": statuses.get("ok", 0),
            "low_confidence_rows": statuses.get("low_confidence", 0),
            "failed_rows": sum(count for status, count in statuses.items() if status not in {"ok", "low_confidence"}),
            "pose_score_min": round(min(scores), 6),
            "pose_score_mean": round(statistics.fmean(scores), 6),
            "pose_score_median": round(statistics.median(scores), 6),
            "pose_score_max": round(max(scores), 6),
        })
        output.append(item)
    return output


def feature_quality(rows: list[dict[str, str]], feature_columns: list[str]) -> dict[str, Any]:
    non_finite = 0
    out_of_range = 0
    zero_feature_rows = 0
    for row in rows:
        values: list[float] = []
        for column in feature_columns:
            try:
                value = float(row[column])
            except (TypeError, ValueError):
                non_finite += 1
                continue
            if not math.isfinite(value):
                non_finite += 1
                continue
            if value < 0.0 or value > 1.0:
                out_of_range += 1
            values.append(value)
        if values and all(value == 0.0 for value in values):
            zero_feature_rows += 1
    return {
        "feature_column_count": len(feature_columns),
        "non_finite_feature_values": non_finite,
        "out_of_range_feature_values": out_of_range,
        "all_zero_feature_rows": zero_feature_rows,
    }


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})


def write_summary(output_dir: Path, rows: list[dict[str, str]], fieldnames: list[str], min_pose_score: float) -> dict[str, Any]:
    feature_columns = infer_feature_columns(fieldnames)
    statuses = Counter(row["pose_status"] for row in rows)
    kinds = Counter(row["source_kind"] for row in rows)
    activities = Counter(row["activity"] for row in rows)
    training_inclusion = Counter(include_for_training(row, min_pose_score) for row in rows)
    scores = [pose_score(row) for row in rows]
    summary = {
        "dataset_row_count": len(rows),
        "min_pose_score": min_pose_score,
        "source_kind_counts": dict(sorted(kinds.items())),
        "pose_status_counts": dict(sorted(statuses.items())),
        "activity_counts": dict(sorted(activities.items())),
        "training_inclusion_recommendation": dict(sorted(training_inclusion.items())),
        "pose_score": score_summary(scores),
        "feature_quality": feature_quality(rows, feature_columns),
        "generated_files": [
            "qa_summary.json",
            "qa_by_activity_session.csv",
            "low_confidence_review.csv",
            "expert_label_template.csv",
        ],
    }
    with (output_dir / "qa_summary.json").open("w", encoding="utf-8") as handle:
        json.dump(summary, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    return summary


def label_template_rows(rows: list[dict[str, str]], min_pose_score: float) -> list[dict[str, Any]]:
    output: list[dict[str, Any]] = []
    for row in rows:
        template = {column: row.get(column, "") for column in METADATA_COLUMNS}
        template.update({
            "sample_id": sample_id(row),
            "suggested_include_for_training": include_for_training(row, min_pose_score),
            "qa_flag": qa_flag(row, min_pose_score),
            "expert_reba_score": "",
            "expert_risk_level": "",
            "reba_trunk_posture_code": "",
            "reba_neck_posture_code": "",
            "reba_leg_posture_code": "",
            "reba_trunk_twist": "",
            "reba_trunk_side_flex": "",
            "reba_upper_arm_code": "",
            "reba_lower_arm_code": "",
            "reba_wrist_posture_code": "",
            "reba_wrist_twist": "",
            "reba_load_category": "",
            "reba_coupling_category": "",
            "reba_activity_category": "",
            "iso_load_weight_kg": "",
            "iso_lift_frequency_per_min": "",
            "iso_lift_duration_hours": "",
            "iso_vertical_position_cm": "",
            "iso_horizontal_distance_cm": "",
            "iso_rwl_kg": "",
            "iso_lifting_index": "",
            "push_initial_force_n": "",
            "push_sustained_force_n": "",
            "push_initial_limit_n": "",
            "push_sustained_limit_n": "",
            "primary_body_part": "",
            "secondary_body_part": "",
            "pain_score_0_10": "",
            "treatment_cost_thb": "",
            "lost_income_thb": "",
            "lost_work_days": "",
            "action_recommendation": "",
            "label_source": "expert_pending",
            "labeler_id": "",
            "label_date": "",
            "label_notes": "",
        })
        output.append(template)
    return output


def low_confidence_rows(rows: list[dict[str, str]], min_pose_score: float) -> list[dict[str, Any]]:
    flagged = [
        {
            "sample_id": sample_id(row),
            **{column: row.get(column, "") for column in METADATA_COLUMNS},
            "qa_flag": qa_flag(row, min_pose_score),
        }
        for row in rows
        if qa_flag(row, min_pose_score) != "ok"
    ]
    return sorted(flagged, key=lambda row: (row["activity"], row["session_id"], float(row["pose_score"] or 0)))


def main() -> int:
    args = parse_args()
    rows, fieldnames = read_dataset(Path(args.dataset))
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    summary = write_summary(output_dir, rows, fieldnames, args.min_pose_score)

    grouped = grouped_counts(rows, ["activity_id", "activity", "session_id"])
    write_csv(
        output_dir / "qa_by_activity_session.csv",
        [
            "activity_id",
            "activity",
            "session_id",
            "row_count",
            "image_rows",
            "video_rows",
            "ok_rows",
            "low_confidence_rows",
            "failed_rows",
            "pose_score_min",
            "pose_score_mean",
            "pose_score_median",
            "pose_score_max",
        ],
        grouped,
    )

    write_csv(
        output_dir / "low_confidence_review.csv",
        ["sample_id", *METADATA_COLUMNS, "qa_flag"],
        low_confidence_rows(rows, args.min_pose_score),
    )
    write_csv(
        output_dir / "expert_label_template.csv",
        LABEL_TEMPLATE_COLUMNS,
        label_template_rows(rows, args.min_pose_score),
    )

    print(f"rows={summary['dataset_row_count']}")
    print(f"ok={summary['pose_status_counts'].get('ok', 0)}")
    print(f"needs_review={summary['training_inclusion_recommendation'].get('no', 0)}")
    print(f"wrote={output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
