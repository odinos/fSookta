import tempfile
import unittest
from pathlib import Path

from tools.research_dataset.extract_pose_dataset import (
    SessionManifestRow,
    discover_media,
    feature_columns,
)


class ExtractPoseDatasetTest(unittest.TestCase):
    def test_feature_columns_match_movenet_schema_order(self):
        schema = {
            "landmarks": ["nose", "leftEye"],
            "components": ["x", "y", "score"],
        }

        self.assertEqual(
            feature_columns(schema),
            [
                "nose_x",
                "nose_y",
                "nose_score",
                "leftEye_x",
                "leftEye_y",
                "leftEye_score",
            ],
        )

    def test_discovers_activity_session_media_layout(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            media_dir = root / "pruning" / "4.1"
            media_dir.mkdir(parents=True)
            image_path = media_dir / "sample.jpg"
            video_path = media_dir / "clip.MOV"
            ignored_path = media_dir / "notes.txt"
            image_path.touch()
            video_path.touch()
            ignored_path.touch()

            sessions = [
                SessionManifestRow(
                    activity_id="4",
                    activity="pruning",
                    session_id="4.1",
                    folder_url="https://drive.google.com/example",
                    expected_total_files=2,
                )
            ]

            discovered = discover_media(root, sessions)

        self.assertEqual([item.path.name for item in discovered], ["clip.MOV", "sample.jpg"])
        self.assertEqual([item.kind for item in discovered], ["video", "image"])

    def test_discovers_recursive_session_folder_layout(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            media_dir = root / "4. Pruning (7)" / "4.3"
            media_dir.mkdir(parents=True)
            (media_dir / "still.png").touch()

            sessions = [
                SessionManifestRow(
                    activity_id="4",
                    activity="pruning",
                    session_id="4.3",
                    folder_url="https://drive.google.com/example",
                    expected_total_files=1,
                )
            ]

            discovered = discover_media(root, sessions)

        self.assertEqual(len(discovered), 1)
        self.assertEqual(discovered[0].path.name, "still.png")


if __name__ == "__main__":
    unittest.main()
