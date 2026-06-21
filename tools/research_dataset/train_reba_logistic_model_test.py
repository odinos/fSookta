import unittest

from tools.research_dataset.train_reba_logistic_model import (
    ENGINEERED_FEATURE_NAMES,
    ExpertRebaLabel,
    build_training_label,
    derive_reba_label,
    document_guided_iso_label,
    feature_vector,
    iso_label_from_rows,
    probability_to_risk,
    risk_level_for_reba,
)


def base_pose_row(**overrides):
    row = {
        "activity": "harvesting",
        "pose_score": "0.5",
    }
    for landmark in [
        "nose",
        "leftEar",
        "rightEar",
        "leftShoulder",
        "rightShoulder",
        "leftElbow",
        "rightElbow",
        "leftWrist",
        "rightWrist",
        "leftHip",
        "rightHip",
        "leftKnee",
        "rightKnee",
        "leftAnkle",
        "rightAnkle",
    ]:
        row[f"{landmark}_x"] = "0.5"
        row[f"{landmark}_y"] = "0.5"
        row[f"{landmark}_score"] = "0.9"
    row.update(overrides)
    return row


class TrainRebaLogisticModelTest(unittest.TestCase):
    def test_reba_risk_bands_match_worksheet(self):
        self.assertEqual(risk_level_for_reba(1), "low")
        self.assertEqual(risk_level_for_reba(3), "low")
        self.assertEqual(risk_level_for_reba(4), "medium")
        self.assertEqual(risk_level_for_reba(7), "medium")
        self.assertEqual(risk_level_for_reba(8), "high")
        self.assertEqual(risk_level_for_reba(10), "high")
        self.assertEqual(risk_level_for_reba(11), "veryHigh")

    def test_probability_threshold_mapping(self):
        thresholds = {"medium": 0.272727, "high": 0.636364, "veryHigh": 0.909091}

        self.assertEqual(probability_to_risk(0.1, thresholds), "low")
        self.assertEqual(probability_to_risk(0.3, thresholds), "medium")
        self.assertEqual(probability_to_risk(0.7, thresholds), "high")
        self.assertEqual(probability_to_risk(0.95, thresholds), "veryHigh")

    def test_derive_reba_label_uses_activity_defaults(self):
        low_load = derive_reba_label(base_pose_row(activity="pruning"))
        high_load = derive_reba_label(base_pose_row(activity="on_farm_transport"))

        self.assertLess(low_load.load_score, high_load.load_score)
        self.assertGreaterEqual(high_load.score, low_load.score)

    def test_feature_vector_appends_reba_angle_features(self):
        features = feature_vector(base_pose_row())

        self.assertEqual(len(ENGINEERED_FEATURE_NAMES), 20)
        self.assertEqual(len(features), 71)

    def test_training_label_prefers_exact_expert_reba_score(self):
        row = base_pose_row(activity="custom_task", session_id="5.3")
        pseudo = derive_reba_label(row)

        label = build_training_label(
            row,
            pseudo,
            exact_expert_labels={
                ("custom_task", "5.3"): ExpertRebaLabel(
                    score=9,
                    risk_level="high",
                    label_source="research_team_reba2_summary",
                    matched_session_id="5.3",
                )
            },
            expert_labels=[],
            iso_labels=[],
            calibration_labels=[],
        )

        self.assertEqual(label.score, 9)
        self.assertEqual(label.risk_level, "high")
        self.assertEqual(label.match_type, "expert_exact")

    def test_training_label_combines_higher_iso_activity_risk(self):
        row = base_pose_row(activity="on_farm_transport", session_id="6.2")
        pseudo = derive_reba_label(row)

        label = build_training_label(
            row,
            pseudo,
            exact_expert_labels={},
            expert_labels=[],
            iso_labels=[
                {
                    "activity": "on_farm_transport",
                    "session_id": "6.1",
                    "iso11228_total_score": "18",
                    "risk_level_th": "สูง",
                    "label_source": "research_team_iso11228_workbook",
                }
            ],
            calibration_labels=[],
        )

        self.assertGreater(label.score, label.reba_score)
        self.assertEqual(label.risk_level, "veryHigh")
        self.assertIn("iso11228_activity_mean", label.match_type)
        self.assertEqual(label.iso_risk_level, "high")

    def test_document_guided_iso11228_3_label_for_repetitive_upper_limb(self):
        pseudo = derive_reba_label(base_pose_row(activity="pruning"))
        row = base_pose_row(activity="pruning")
        iso = document_guided_iso_label(row, pseudo)

        self.assertIsNotNone(iso)
        self.assertEqual(iso.match_type, "document_guided_iso11228_3")

    def test_iso_label_from_rows_prefers_exact_session(self):
        label = iso_label_from_rows(
            activity="fertilizing",
            session_id="2.2",
            iso_rows=[
                {
                    "activity": "fertilizing",
                    "session_id": "2.1",
                    "iso11228_total_score": "14",
                    "risk_level_th": "สูง",
                    "label_source": "research_team_iso11228_workbook",
                },
                {
                    "activity": "fertilizing",
                    "session_id": "2.2",
                    "iso11228_total_score": "15",
                    "risk_level_th": "สูง",
                    "label_source": "research_team_iso11228_workbook",
                },
            ],
        )

        self.assertIsNotNone(label)
        self.assertEqual(label.match_type, "iso11228_exact")
        self.assertEqual(label.total_score, 15)

    def test_calibration_label_overrides_activity_level_score(self):
        row = base_pose_row(activity="fertilizing", session_id="2.2")
        pseudo = derive_reba_label(row)

        label = build_training_label(
            row,
            pseudo,
            exact_expert_labels={},
            expert_labels=[],
            iso_labels=[
                {
                    "activity": "fertilizing",
                    "session_id": "2.2",
                    "iso11228_total_score": "15",
                    "risk_level_th": "สูง",
                    "label_source": "older_iso_workbook",
                }
            ],
            calibration_labels=[
                {
                    "activity": "fertilizing",
                    "session_id": "activity_level",
                    "reba_score": "9",
                    "reba_risk_level": "high",
                    "iso11228_total_score": "10",
                    "iso_risk_level_th": "ปานกลาง",
                    "label_source": "research_team_calibration_pdf_20260607",
                }
            ],
        )

        self.assertEqual(label.reba_score, 9)
        self.assertEqual(label.iso_total_score, 10)
        self.assertEqual(label.risk_level, "high")
        self.assertEqual(label.match_type, "calibration_activity_level")


if __name__ == "__main__":
    unittest.main()
