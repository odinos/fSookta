import tempfile
import unittest
from pathlib import Path

from tools.research_dataset.download_drive_media import (
    DriveMediaRow,
    sanitize_file_name,
    selected_rows,
    target_path,
)


class DownloadDriveMediaTest(unittest.TestCase):
    def test_sanitize_file_name_removes_path_separators(self):
        self.assertEqual(sanitize_file_name("../IMG  001.jpeg"), ".._IMG 001.jpeg")
        self.assertEqual(sanitize_file_name("foo\\bar.mov"), "foo_bar.mov")

    def test_target_path_uses_activity_and_session_layout(self):
        row = DriveMediaRow(
            activity="pruning",
            session_id="4.1",
            drive_file_id="abc",
            file_name="IMG_0666.jpeg",
            media_kind="image",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            path = target_path(Path(temp_dir), row)

        self.assertTrue(str(path).endswith("pruning/4.1/IMG_0666.jpeg"))

    def test_selected_rows_supports_images_only(self):
        rows = [
            DriveMediaRow("pruning", "4.1", "a", "a.jpeg", "image"),
            DriveMediaRow("pruning", "4.1", "b", "b.mov", "video"),
        ]
        args = type("Args", (), {"images_only": True, "videos_only": False, "limit": 0})()

        self.assertEqual([row.file_name for row in selected_rows(rows, args)], ["a.jpeg"])


if __name__ == "__main__":
    unittest.main()
