from __future__ import annotations

import csv
from copy import deepcopy
from pathlib import Path
import tempfile
import unittest

from tools.recommendations.validate_recommendations import (
    extract_current_recommendation_keys,
    validate_master,
    validate_translation_review,
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


class TranslationReviewTest(unittest.TestCase):
    def test_every_master_item_has_one_translation_review_row(self) -> None:
        errors = validate_translation_review(
            Path("data/recommendations/recommendation_master.csv"),
            Path("data/recommendations/translation_review.csv"),
            require_approved=False,
        )
        self.assertEqual(errors, [])

    def test_approval_gate_accepts_the_approved_translation_baseline(self) -> None:
        errors = validate_translation_review(
            Path("data/recommendations/recommendation_master.csv"),
            Path("data/recommendations/translation_review.csv"),
            require_approved=True,
        )
        self.assertEqual(errors, [])


class ApprovedCatalogGateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.master_rows = self._read_csv(
            Path("data/recommendations/recommendation_master.csv")
        )
        self.translation_rows = self._read_csv(
            Path("data/recommendations/translation_review.csv")
        )
        self.conflict_rows = self._read_csv(
            Path(
                "data/recommendations/reports/"
                "conflicts_missing_sources.csv"
            )
        )

    def test_approved_gate_requires_source_verified_master_rows(self) -> None:
        master_rows = deepcopy(self.master_rows)
        item_id = master_rows[0]["recommendation_id"]
        master_rows[0]["record_status"] = "conflict"

        errors = self._validate(master_rows=master_rows)

        self.assertIn(f"approved_master_status:{item_id}:conflict", errors)

    def test_approved_gate_requires_exact_review_identity(self) -> None:
        mutations = {
            "selection_key": "act_different",
            "record_type": "ui_copy",
            "thai_source_text": "ข้อความภาษาไทยที่เปลี่ยนไป",
            "source_id": "different_source",
            "source_page": "different_page",
        }
        for field, replacement in mutations.items():
            with self.subTest(field=field):
                translation_rows = deepcopy(self.translation_rows)
                item_id = translation_rows[0]["recommendation_id"]
                translation_rows[0][field] = replacement

                errors = self._validate(
                    translation_rows=translation_rows,
                )

                self.assertIn(
                    f"approved_identity:{item_id}:{field}",
                    errors,
                )

    def test_approved_gate_rejects_blank_approved_text(self) -> None:
        cases = (
            ("master_thai", "approved_master_thai_empty"),
            ("review_thai", "approved_thai_empty"),
            ("review_english", "approved_english_empty"),
        )
        for target, error_prefix in cases:
            with self.subTest(target=target):
                master_rows = deepcopy(self.master_rows)
                translation_rows = deepcopy(self.translation_rows)
                item_id = master_rows[0]["recommendation_id"]
                if target == "master_thai":
                    master_rows[0]["thai_source_text"] = " "
                elif target == "review_thai":
                    translation_rows[0]["thai_source_text"] = " "
                else:
                    translation_rows[0]["english_draft"] = " "

                errors = self._validate(
                    master_rows=master_rows,
                    translation_rows=translation_rows,
                )

                self.assertIn(f"{error_prefix}:{item_id}", errors)

    def test_approved_gate_rejects_duplicate_master_ids(self) -> None:
        master_rows = deepcopy(self.master_rows)
        item_id = master_rows[0]["recommendation_id"]
        master_rows.append(deepcopy(master_rows[0]))

        errors = self._validate(master_rows=master_rows)

        self.assertIn(f"approved_master_duplicate:{item_id}", errors)

    def test_approved_gate_rejects_duplicate_review_ids(self) -> None:
        translation_rows = deepcopy(self.translation_rows)
        item_id = translation_rows[0]["recommendation_id"]
        translation_rows.append(deepcopy(translation_rows[0]))

        errors = self._validate(translation_rows=translation_rows)

        self.assertIn(f"approved_review_duplicate:{item_id}", errors)

    def test_approved_gate_rejects_missing_or_extra_master_review_ids(
        self,
    ) -> None:
        missing_review_rows = deepcopy(self.translation_rows)
        missing_review_id = missing_review_rows.pop()["recommendation_id"]
        errors = self._validate(translation_rows=missing_review_rows)
        self.assertIn(
            f"approved_review_missing:{missing_review_id}",
            errors,
        )

        extra_review_rows = deepcopy(self.translation_rows)
        extra_review = deepcopy(extra_review_rows[0])
        extra_review["recommendation_id"] = "act_unexpected.01"
        extra_review_rows.append(extra_review)
        errors = self._validate(translation_rows=extra_review_rows)
        self.assertIn(
            "approved_review_unknown:act_unexpected.01",
            errors,
        )

        missing_master_rows = deepcopy(self.master_rows)
        missing_master_id = missing_master_rows.pop()["recommendation_id"]
        errors = self._validate(master_rows=missing_master_rows)
        self.assertIn(
            f"approved_review_unknown:{missing_master_id}",
            errors,
        )

        extra_master_rows = deepcopy(self.master_rows)
        extra_master = deepcopy(extra_master_rows[0])
        extra_master["recommendation_id"] = "act_new_master.01"
        extra_master_rows.append(extra_master)
        errors = self._validate(master_rows=extra_master_rows)
        self.assertIn(
            "approved_review_missing:act_new_master.01",
            errors,
        )

    def test_approved_gate_rejects_unresolved_review_checks(self) -> None:
        review_fields = (
            "numbers_match",
            "units_match",
            "timing_match",
            "urgency_match",
            "negation_match",
            "meaning_review",
        )
        for field in review_fields:
            with self.subTest(field=field):
                translation_rows = deepcopy(self.translation_rows)
                item_id = translation_rows[0]["recommendation_id"]
                translation_rows[0][field] = "pending_human_review"

                errors = self._validate(
                    translation_rows=translation_rows,
                )

                self.assertIn(
                    "approved_review_unresolved:"
                    f"{item_id}:{field}:pending_human_review",
                    errors,
                )

    def test_approved_gate_rejects_semantically_invalid_not_applicable(
        self,
    ) -> None:
        cases = (
            ("numbers_match", "act_body_arms_high.01"),
            ("units_match", "act_body_arms_high.01"),
            ("timing_match", "act_body_arms_high.01"),
            ("urgency_match", "act_transplant_ref_high.01"),
            ("negation_match", "act_body_arms_high.01"),
            ("meaning_review", "act_adj_eye_level.01"),
        )
        for field, item_id in cases:
            with self.subTest(field=field):
                translation_rows = deepcopy(self.translation_rows)
                row = next(
                    item
                    for item in translation_rows
                    if item["recommendation_id"] == item_id
                )
                row[field] = "not_applicable"

                errors = self._validate(
                    translation_rows=translation_rows,
                )

                self.assertIn(
                    f"approved_not_applicable_invalid:{item_id}:{field}",
                    errors,
                )

    def test_approved_gate_accepts_valid_not_applicable_reviews(self) -> None:
        translation_rows = deepcopy(self.translation_rows)
        item_id = "act_adj_eye_level.01"
        row = next(
            item
            for item in translation_rows
            if item["recommendation_id"] == item_id
        )
        for field in (
            "numbers_match",
            "units_match",
            "timing_match",
            "urgency_match",
            "negation_match",
        ):
            row[field] = "not_applicable"

        errors = self._validate(translation_rows=translation_rows)

        self.assertEqual(errors, [])

    def test_approved_gate_requires_review_style(self) -> None:
        translation_rows = deepcopy(self.translation_rows)
        item_id = translation_rows[0]["recommendation_id"]
        translation_rows[0]["translation_style"] = " "

        errors = self._validate(translation_rows=translation_rows)

        self.assertIn(f"approved_translation_style:{item_id}", errors)

    def test_approved_gate_requires_nonempty_approver(self) -> None:
        translation_rows = deepcopy(self.translation_rows)
        item_id = translation_rows[0]["recommendation_id"]
        translation_rows[0]["approved_by"] = " "

        errors = self._validate(translation_rows=translation_rows)

        self.assertIn(f"approved_by_empty:{item_id}", errors)

    def test_approved_gate_requires_timezone_aware_iso_timestamp(self) -> None:
        invalid_timestamps = (
            "",
            "2026-07-29T00:00:00",
            "not-a-timestamp",
        )
        for timestamp in invalid_timestamps:
            with self.subTest(timestamp=timestamp):
                translation_rows = deepcopy(self.translation_rows)
                item_id = translation_rows[0]["recommendation_id"]
                translation_rows[0]["approved_at"] = timestamp

                errors = self._validate(
                    translation_rows=translation_rows,
                )

                self.assertIn(f"approved_at_invalid:{item_id}", errors)

    def test_approved_gate_requires_positive_integer_translation_version(
        self,
    ) -> None:
        invalid_versions = ("", "0", "-1", "1.5", "version-one")
        for version in invalid_versions:
            with self.subTest(version=version):
                translation_rows = deepcopy(self.translation_rows)
                item_id = translation_rows[0]["recommendation_id"]
                translation_rows[0]["translation_version"] = version

                errors = self._validate(
                    translation_rows=translation_rows,
                )

                self.assertIn(
                    f"approved_translation_version:{item_id}:{version}",
                    errors,
                )

    def test_approved_gate_requires_conflict_report(self) -> None:
        errors = self._validate(write_conflicts=False)

        self.assertIn("approved_conflict_report_missing", errors)

    def test_approved_gate_requires_complete_conflict_coverage(self) -> None:
        conflict_rows = deepcopy(self.conflict_rows)
        missing_id = conflict_rows.pop()["recommendation_id"]

        errors = self._validate(conflict_rows=conflict_rows)

        self.assertIn(
            f"approved_conflict_coverage_missing:{missing_id}",
            errors,
        )

    def test_approved_gate_requires_every_conflict_to_be_approved(
        self,
    ) -> None:
        conflict_rows = deepcopy(self.conflict_rows)
        item_id = conflict_rows[0]["recommendation_id"]
        conflict_rows[0]["approval_status"] = "pending"

        errors = self._validate(conflict_rows=conflict_rows)

        self.assertIn(
            f"approved_conflict_status:{item_id}:pending",
            errors,
        )

    def test_approved_gate_requires_exact_conflict_identity(self) -> None:
        conflict_rows = deepcopy(self.conflict_rows)
        item_id = conflict_rows[0]["recommendation_id"]
        conflict_rows[0]["selection_key"] = "act_different"

        errors = self._validate(conflict_rows=conflict_rows)

        self.assertIn(
            f"approved_conflict_identity:{item_id}:selection_key",
            errors,
        )

    def test_approved_gate_rejects_duplicate_conflict_rows(self) -> None:
        conflict_rows = deepcopy(self.conflict_rows)
        item_id = conflict_rows[0]["recommendation_id"]
        conflict_rows.append(deepcopy(conflict_rows[0]))

        errors = self._validate(conflict_rows=conflict_rows)

        self.assertIn(f"approved_conflict_duplicate:{item_id}", errors)

    def _validate(
        self,
        *,
        master_rows: list[dict[str, str]] | None = None,
        translation_rows: list[dict[str, str]] | None = None,
        conflict_rows: list[dict[str, str]] | None = None,
        write_conflicts: bool = True,
    ) -> list[str]:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            master_path = root / "recommendation_master.csv"
            translation_path = root / "translation_review.csv"
            self._write_csv(
                master_path,
                master_rows or self.master_rows,
            )
            self._write_csv(
                translation_path,
                translation_rows or self.translation_rows,
            )
            if write_conflicts:
                self._write_csv(
                    root / "reports" / "conflicts_missing_sources.csv",
                    (
                        self.conflict_rows
                        if conflict_rows is None
                        else conflict_rows
                    ),
                )
            return validate_translation_review(
                master_path,
                translation_path,
                require_approved=True,
            )

    @staticmethod
    def _read_csv(path: Path) -> list[dict[str, str]]:
        with path.open(encoding="utf-8-sig", newline="") as stream:
            return list(csv.DictReader(stream))

    @staticmethod
    def _write_csv(
        path: Path,
        rows: list[dict[str, str]],
    ) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8-sig", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)


if __name__ == "__main__":
    unittest.main()
