import json
import tempfile
import unittest
from pathlib import Path

from openpyxl import Workbook

from tools.research_dataset.convert_daily_outcome_labels import (
    FEATURE_COLUMNS,
    TARGET_COLUMN,
    convert_workbook,
    write_csv,
    write_json,
)


HEADERS = [
    "row_type",
    "window_id",
    "farmer_id",
    "participant_code",
    "window_start_date",
    "window_end_date",
    "transaction_count",
    "transaction_ids",
    "activity_summary",
    "assessment_methods",
    *FEATURE_COLUMNS,
    TARGET_COLUMN,
    "medical_visit_within_7_days",
    "treatment_required_within_7_days",
    "msd_symptom_present",
    "msd_symptom_location",
    "msd_symptom_severity",
    "lost_workdays_7d",
    "direct_medical_cost_thb",
    "productivity_loss_thb",
    "label_confidence",
    "outcome_source",
    "reviewer_id",
    "reviewed_at",
    "notes",
]


class ConvertDailyOutcomeLabelsTest(unittest.TestCase):
    def test_converts_valid_workbook_to_csv_and_json_fixture(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            workbook_path = Path(temp_dir) / "labels.xlsx"
            output_csv = Path(temp_dir) / "labels.csv"
            output_json = Path(temp_dir) / "labels.json"
            _write_workbook(workbook_path, [_valid_row()])

            dataset = convert_workbook(workbook_path, include_examples=True)
            write_csv(dataset.rows, output_csv)
            write_json(dataset.rows, output_json)

            self.assertEqual(dataset.errors, [])
            self.assertEqual(len(dataset.rows), 1)
            self.assertEqual(dataset.rows[0][TARGET_COLUMN], 1)
            self.assertEqual(dataset.rows[0]["transaction_count"], 7)
            self.assertTrue(output_csv.read_text(encoding="utf-8-sig").startswith("row_type"))
            payload = json.loads(output_json.read_text(encoding="utf-8"))
            self.assertEqual(payload["schema"], "sookta_daily_injury_outcome_labels_v1")
            self.assertEqual(payload["rowCount"], 1)

    def test_skips_example_rows_by_default(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            workbook_path = Path(temp_dir) / "labels.xlsx"
            _write_workbook(workbook_path, [_valid_row(row_type="example")])

            dataset = convert_workbook(workbook_path)

            self.assertEqual(dataset.errors, [])
            self.assertEqual(dataset.rows, [])

    def test_rejects_invalid_transaction_count_and_feature_range(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            workbook_path = Path(temp_dir) / "labels.xlsx"
            row = _valid_row(transaction_count=6)
            row["avg_score_before_norm"] = 1.2
            _write_workbook(workbook_path, [row])

            dataset = convert_workbook(workbook_path, include_examples=True)

            self.assertEqual(len(dataset.errors), 1)
            self.assertIn("transaction_count must be 7", dataset.errors[0])


def _valid_row(**overrides):
    row = {
        "row_type": "research",
        "window_id": "FSK-001_2026-06-01_2026-06-07",
        "farmer_id": "FSK-001",
        "participant_code": "P001",
        "window_start_date": "2026-06-01",
        "window_end_date": "2026-06-07",
        "transaction_count": 7,
        "transaction_ids": "1,2,3,4,5,6,7",
        "activity_summary": "transplanting",
        "assessment_methods": "REBA",
        "avg_score_before_norm": 0.75,
        "max_score_before_norm": 1.0,
        "avg_score_after_norm": 0.65,
        "high_or_above_days_norm": 1.0,
        "very_high_days_norm": 0.25,
        "no_improvement_days_norm": 0.1,
        "trunk_high_days_norm": 1.0,
        "neck_or_upper_limb_high_days_norm": 0.5,
        "iso_days_norm": 0.0,
        "avg_economic_loss_norm": 0.45,
        "repeated_same_activity_norm": 1.0,
        "recent_score_slope_norm": 0.6,
        TARGET_COLUMN: 1,
        "medical_visit_within_7_days": 1,
        "treatment_required_within_7_days": 1,
        "msd_symptom_present": 1,
        "msd_symptom_location": "lower_back",
        "msd_symptom_severity": "severe",
        "lost_workdays_7d": 2,
        "direct_medical_cost_thb": 800,
        "productivity_loss_thb": 1200,
        "label_confidence": "high",
        "outcome_source": "research_follow_up",
        "reviewer_id": "R001",
        "reviewed_at": "2026-06-08",
        "notes": "Unit test row",
    }
    row.update(overrides)
    return row


def _write_workbook(path: Path, rows):
    workbook = Workbook()
    sheet = workbook.active
    sheet.title = "Training_Data"
    sheet.append(HEADERS)
    for row in rows:
        sheet.append([row.get(header, "") for header in HEADERS])
    workbook.save(path)


if __name__ == "__main__":
    unittest.main()
