from pathlib import Path
import unittest

from tools.recommendations.validate_recommendations import (
    extract_current_recommendation_keys,
    validate_master,
)


class RecommendationMasterTest(unittest.TestCase):
    def test_master_has_required_columns_and_source_for_every_row(self) -> None:
        errors = validate_master(
            Path("data/recommendations/recommendation_master.csv"),
            Path("data/recommendations/source_registry.json"),
        )
        self.assertEqual(errors, [])

    def test_every_current_recommendation_key_is_audited(self) -> None:
        current_keys = extract_current_recommendation_keys(
            Path("lib/core/localization/sookta_strings.dart")
        )
        master_text = Path(
            "data/recommendations/recommendation_master.csv"
        ).read_text(encoding="utf-8-sig")
        for key in current_keys:
            with self.subTest(key=key):
                self.assertIn(key, master_text)


if __name__ == "__main__":
    unittest.main()
