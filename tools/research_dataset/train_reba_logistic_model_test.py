import unittest

from tools.research_dataset.train_reba_logistic_model import (
    derive_reba_label,
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


if __name__ == "__main__":
    unittest.main()
