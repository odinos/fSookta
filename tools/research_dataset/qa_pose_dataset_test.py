import csv
import tempfile
import unittest
from pathlib import Path

from tools.research_dataset.qa_pose_dataset import (
    include_for_training,
    infer_feature_columns,
    label_template_rows,
    qa_flag,
    read_dataset,
    sample_id,
)


def dataset_fieldnames():
    features = []
    for index in range(51):
        features.append(f"feature_{index}")
    return [
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
        *features,
        "label_source",
        "pseudo_reba_score",
        "pseudo_risk_level",
    ]


def dataset_row(**overrides):
    row = {
        "activity_id": "4",
        "activity": "pruning",
        "session_id": "4.1",
        "source_path": "data/research/media/pruning/4.1/sample.jpeg",
        "source_kind": "image",
        "frame_timestamp_ms": "",
        "frame_index": "",
        "image_width": "100",
        "image_height": "200",
        "pose_score": "0.42",
        "pose_status": "ok",
        "error": "",
        "label_source": "pending_expert_label",
        "pseudo_reba_score": "",
        "pseudo_risk_level": "",
    }
    for index in range(51):
        row[f"feature_{index}"] = "0.1"
    row.update(overrides)
    return row


class QaPoseDatasetTest(unittest.TestCase):
    def test_infer_feature_columns_excludes_metadata_and_label_placeholders(self):
        columns = infer_feature_columns(dataset_fieldnames())

        self.assertEqual(len(columns), 51)
        self.assertEqual(columns[0], "feature_0")
        self.assertEqual(columns[-1], "feature_50")

    def test_sample_id_is_stable_for_same_source_frame(self):
        row = dataset_row()

        self.assertEqual(sample_id(row), sample_id(row))
        self.assertTrue(sample_id(row).startswith("pose_"))

    def test_training_inclusion_requires_ok_status_and_threshold(self):
        self.assertEqual(include_for_training(dataset_row(), 0.2), "yes")
        self.assertEqual(
            include_for_training(dataset_row(pose_status="low_confidence", pose_score="0.1"), 0.2),
            "no",
        )

    def test_qa_flag_reports_error_before_score(self):
        self.assertEqual(qa_flag(dataset_row(error="decode failed"), 0.2), "error")

    def test_label_template_contains_expert_columns(self):
        rows = label_template_rows([dataset_row()], 0.2)

        self.assertEqual(rows[0]["label_source"], "expert_pending")
        self.assertIn("expert_reba_score", rows[0])
        self.assertIn("treatment_cost_thb", rows[0])

    def test_read_dataset_validates_feature_count(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "dataset.csv"
            with path.open("w", newline="", encoding="utf-8") as handle:
                writer = csv.DictWriter(handle, fieldnames=dataset_fieldnames())
                writer.writeheader()
                writer.writerow(dataset_row())

            rows, fieldnames = read_dataset(path)

        self.assertEqual(len(rows), 1)
        self.assertEqual(len(infer_feature_columns(fieldnames)), 51)


if __name__ == "__main__":
    unittest.main()
