#!/usr/bin/env python3
"""Train the separate 7-transaction daily injury Logistic Regression model.

This trainer intentionally does not train REBA or ISO11228 posture risk. It
reads daily assessment transactions, aggregates every farmer's latest rolling
7-day windows, and trains a binary Logistic Regression model for the
`requires_medical_treatment_within_7_days` label.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable


FEATURES = [
    "avg_score_before_norm",
    "max_score_before_norm",
    "avg_score_after_norm",
    "high_or_above_days_norm",
    "very_high_days_norm",
    "no_improvement_days_norm",
    "trunk_high_days_norm",
    "neck_or_upper_limb_high_days_norm",
    "iso_days_norm",
    "avg_economic_loss_norm",
    "repeated_same_activity_norm",
    "recent_score_slope_norm",
]

RISK_ORDER = {
    "low": 0,
    "medium": 1,
    "high": 2,
    "veryHigh": 3,
    "very_high": 3,
    "very high": 3,
}


@dataclass(frozen=True)
class Transaction:
    farmer_id: str
    assessment_date: datetime
    activity: str
    score_before: int
    score_after: int
    risk_before: str
    trunk_risk: str
    neck_risk: str
    arms_risk: str
    wrists_risk: str
    iso11228_1_used: bool
    economic_loss_thb: float
    label: int


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default="data/research/templates/daily_injury_logistic_training_template.csv",
        help="CSV with one row per daily assessment transaction.",
    )
    parser.add_argument(
        "--output",
        default="assets/ml/daily_injury_logistic_model.json",
        help="Output JSON asset consumed by the Flutter app.",
    )
    parser.add_argument("--epochs", type=int, default=2500)
    parser.add_argument("--learning-rate", type=float, default=0.08)
    parser.add_argument("--l2", type=float, default=0.01)
    args = parser.parse_args()

    transactions = read_transactions(Path(args.input))
    windows = build_windows(transactions)
    if len(windows) < 4:
        raise SystemExit(
            "Need at least 4 labeled 7-transaction windows to train. "
            "Fill the template with research labels first."
        )
    labels = [label for _, label in windows]
    if len(set(labels)) < 2:
        raise SystemExit("Training labels must contain both 0 and 1.")

    intercept, coefficients = train_logistic(
        [features for features, _ in windows],
        labels,
        epochs=args.epochs,
        learning_rate=args.learning_rate,
        l2=args.l2,
    )
    metrics = evaluate([features for features, _ in windows], labels, intercept, coefficients)
    output = {
        "version": f"daily-injury-logistic-research-{datetime.now().date().isoformat()}",
        "source": "research_team_daily_treatment_labels",
        "description": (
            "Separate Logistic Regression model for seven-transaction daily "
            "injury/treatment follow-up prediction. Not used for REBA or ISO11228 scoring."
        ),
        "minTransactions": 7,
        "thresholds": {"watch": 0.45, "high": 0.65, "critical": 0.82},
        "features": FEATURES,
        "targetLabel": {
            "name": "requires_medical_treatment_within_7_days",
            "values": {
                "0": "No treatment-required MSD follow-up recorded in the assessment window",
                "1": "Treatment-required MSD follow-up or medical care recorded in the assessment window",
            },
        },
        "logisticRegression": {
            "intercept": round(intercept, 8),
            "coefficients": {name: round(coefficients[name], 8) for name in FEATURES},
        },
        "trainingStatus": {
            "readyForAppUse": True,
            "researchTrained": True,
            "sampleWindowCount": len(windows),
            "positiveWindowCount": sum(labels),
            "negativeWindowCount": len(labels) - sum(labels),
            "metrics": metrics,
        },
    }
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(output["trainingStatus"], ensure_ascii=False, indent=2))


def read_transactions(path: Path) -> list[Transaction]:
    rows: list[Transaction] = []
    with path.open(newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            farmer_id = row.get("farmer_id", "").strip()
            if not farmer_id or farmer_id.upper().startswith("FSK-EXAMPLE"):
                continue
            label_raw = row.get("requires_medical_treatment_within_7_days", "").strip()
            if label_raw not in {"0", "1"}:
                continue
            rows.append(
                Transaction(
                    farmer_id=farmer_id,
                    assessment_date=parse_date(row.get("assessment_date", "")),
                    activity=row.get("activity", "").strip(),
                    score_before=parse_int(row.get("score_before"), 0),
                    score_after=parse_int(row.get("score_after"), 0),
                    risk_before=row.get("risk_before", "low").strip(),
                    trunk_risk=row.get("trunk_risk", "low").strip(),
                    neck_risk=row.get("neck_risk", "low").strip(),
                    arms_risk=row.get("arms_risk", "low").strip(),
                    wrists_risk=row.get("wrists_risk", "low").strip(),
                    iso11228_1_used=parse_bool(row.get("iso11228_1_used")),
                    economic_loss_thb=parse_float(row.get("economic_loss_thb"), 0),
                    label=int(label_raw),
                )
            )
    return rows


def build_windows(transactions: Iterable[Transaction]) -> list[tuple[dict[str, float], int]]:
    by_farmer: dict[str, list[Transaction]] = defaultdict(list)
    for transaction in transactions:
        by_farmer[transaction.farmer_id].append(transaction)

    windows: list[tuple[dict[str, float], int]] = []
    for farmer_rows in by_farmer.values():
        ordered = sorted(farmer_rows, key=lambda item: item.assessment_date)
        for start in range(0, len(ordered) - 6):
            window = ordered[start : start + 7]
            label = 1 if any(row.label == 1 for row in window) else 0
            windows.append((window_features(window), label))
    return windows


def window_features(window: list[Transaction]) -> dict[str, float]:
    before = [row.score_before for row in window]
    after = [row.score_after for row in window]
    count = len(window)
    high_days = sum(1 for row in window if risk_rank(row.risk_before) >= 2)
    very_high_days = sum(1 for row in window if risk_rank(row.risk_before) >= 3)
    no_improvement = sum(1 for row in window if row.score_after >= row.score_before)
    trunk_high = sum(1 for row in window if risk_rank(row.trunk_risk) >= 2)
    neck_or_upper = sum(
        1
        for row in window
        if max(risk_rank(row.neck_risk), risk_rank(row.arms_risk), risk_rank(row.wrists_risk))
        >= 2
    )
    activity_counts = Counter(row.activity for row in window)
    return {
        "avg_score_before_norm": norm(sum(before) / count, 1, 9),
        "max_score_before_norm": norm(max(before), 1, 9),
        "avg_score_after_norm": norm(sum(after) / count, 1, 9),
        "high_or_above_days_norm": high_days / count,
        "very_high_days_norm": very_high_days / count,
        "no_improvement_days_norm": no_improvement / count,
        "trunk_high_days_norm": trunk_high / count,
        "neck_or_upper_limb_high_days_norm": neck_or_upper / count,
        "iso_days_norm": sum(1 for row in window if row.iso11228_1_used) / count,
        "avg_economic_loss_norm": bounded(
            sum(row.economic_loss_thb for row in window) / count / 40000
        ),
        "repeated_same_activity_norm": max(activity_counts.values()) / count,
        "recent_score_slope_norm": bounded(((before[-1] - before[0]) + 8) / 16),
    }


def train_logistic(
    rows: list[dict[str, float]],
    labels: list[int],
    *,
    epochs: int,
    learning_rate: float,
    l2: float,
) -> tuple[float, dict[str, float]]:
    intercept = 0.0
    coefficients = {name: 0.0 for name in FEATURES}
    n = len(rows)
    for _ in range(epochs):
        intercept_grad = 0.0
        grads = {name: 0.0 for name in FEATURES}
        for features, label in zip(rows, labels):
            prediction = sigmoid(intercept + sum(coefficients[name] * features[name] for name in FEATURES))
            error = prediction - label
            intercept_grad += error
            for name in FEATURES:
                grads[name] += error * features[name]
        intercept -= learning_rate * (intercept_grad / n)
        for name in FEATURES:
            penalty = l2 * coefficients[name]
            coefficients[name] -= learning_rate * ((grads[name] / n) + penalty)
    return intercept, coefficients


def evaluate(
    rows: list[dict[str, float]],
    labels: list[int],
    intercept: float,
    coefficients: dict[str, float],
) -> dict[str, float]:
    probs = [
        sigmoid(intercept + sum(coefficients[name] * row[name] for name in FEATURES))
        for row in rows
    ]
    predictions = [1 if prob >= 0.5 else 0 for prob in probs]
    accuracy = sum(1 for pred, label in zip(predictions, labels) if pred == label) / len(labels)
    brier = sum((prob - label) ** 2 for prob, label in zip(probs, labels)) / len(labels)
    return {
        "trainingAccuracy": round(accuracy, 4),
        "brierScore": round(brier, 4),
        "probabilityMean": round(sum(probs) / len(probs), 4),
    }


def parse_date(value: str) -> datetime:
    return datetime.fromisoformat(value.strip()[:10])


def parse_int(value: str | None, default: int) -> int:
    try:
        return int(float(value or ""))
    except ValueError:
        return default


def parse_float(value: str | None, default: float) -> float:
    try:
        return float(value or "")
    except ValueError:
        return default


def parse_bool(value: str | None) -> bool:
    return (value or "").strip().lower() in {"1", "true", "yes", "y"}


def risk_rank(value: str) -> int:
    return RISK_ORDER.get(value.strip(), RISK_ORDER.get(value.strip().lower(), 0))


def norm(value: float, lower: float, upper: float) -> float:
    if upper <= lower:
        return 0.0
    return bounded((value - lower) / (upper - lower))


def bounded(value: float) -> float:
    return max(0.0, min(1.0, value))


def sigmoid(value: float) -> float:
    return 1 / (1 + math.exp(-value))


if __name__ == "__main__":
    main()
