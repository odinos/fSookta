from pathlib import Path
import unittest

from tools.recommendations.validate_sources import (
    validate_model_baseline,
    validate_registry,
)


class SourceRegistryTest(unittest.TestCase):
    def test_registered_sources_exist_and_match_sha256(self) -> None:
        errors = validate_registry(
            Path("data/recommendations/source_registry.json")
        )
        self.assertEqual(errors, [])

    def test_registered_model_artifacts_match_sha256(self) -> None:
        errors = validate_model_baseline(
            Path("data/recommendations/baseline_model_hashes.json")
        )
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
