import unittest

from tools.research_dataset.train_reba_logistic_model import (
    ENGINEERED_FEATURE_NAMES,
    ExpertRebaLabel,
    build_training_label,
    derive_reba_label,
    feature_vector,
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
        row = base_pose_row(activity="harvesting", session_id="5.3")
        pseudo = derive_reba_label(row)

        label = build_training_label(
            row,
            pseudo,
            exact_expert_labels={
                ("harvesting", "5.3"): ExpertRebaLabel(
                    score=9,
                    risk_level="high",
                    label_source="research_team_reba2_summary",
                    matched_session_id="5.3",
                )
            },
            expert_labels=[],
        )

        self.assertEqual(label.score, 9)
        self.assertEqual(label.risk_level, "high")
        self.assertEqual(label.match_type, "expert_exact")


if __name__ == "__main__":
    unittest.main()
