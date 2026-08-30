"""Behavioral regression test for the final-handover inventory generator."""
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
GENERATOR = REPOSITORY_ROOT / "tools" / "final_handover" / "build_inventory.py"
REQUIRED_STAGING_DIRS = ("artifacts", "evidence", "renders", "archives", "manifests")


class BuildInventoryTest(unittest.TestCase):
    def test_clean_invocation_creates_all_required_staging_directories(self) -> None:
        """Catch removal/omission of any staging directory from generator setup."""
        output_dir = Path(tempfile.mkdtemp(prefix="fsookta-inventory-test-", dir="/private/tmp"))
        self.addCleanup(shutil.rmtree, output_dir, ignore_errors=True)

        result = subprocess.run(
            [sys.executable, str(GENERATOR), "--output-dir", str(output_dir), "--evidence-date", "2026-08-23"],
            cwd=REPOSITORY_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            {path.name for path in output_dir.iterdir() if path.is_dir()},
            set(REQUIRED_STAGING_DIRS),
        )
        sentinel = output_dir / "evidence" / "preserve-me.txt"
        sentinel.write_text("keep", encoding="utf-8")
        rerun = subprocess.run(
            [sys.executable, str(GENERATOR), "--output-dir", str(output_dir), "--evidence-date", "2026-08-23"],
            cwd=REPOSITORY_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(rerun.returncode, 0, rerun.stderr)
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "keep")


if __name__ == "__main__":
    unittest.main()
