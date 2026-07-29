from __future__ import annotations

import unittest

from tools.recommendations.build_recommendation_catalog import build_catalog


def _master_row(
    recommendation_id: str,
    *,
    selection_key: str = "act_test",
    display_order: str = "1",
    activity: str = "any",
    body_part: str = "any",
    risk_level: str = "any",
    legacy_text_th: str = "",
    legacy_text_en: str = "",
) -> dict[str, str]:
    return {
        "recommendation_id": recommendation_id,
        "selection_key": selection_key,
        "display_order": display_order,
        "category": "posture",
        "activity": activity,
        "body_part": body_part,
        "risk_level": risk_level,
        "thai_source_text": f"คำแนะนำ {recommendation_id}",
        "source_id": "test_source",
        "source_page": "1",
        "catalog_version": "2026-07-29.1",
        "legacy_text_th": legacy_text_th,
        "legacy_text_en": legacy_text_en,
    }


def _approved_row(
    master: dict[str, str],
    *,
    approval_status: str = "approved",
    english_text: str | None = None,
) -> dict[str, str]:
    return {
        "recommendation_id": master["recommendation_id"],
        "selection_key": master["selection_key"],
        "thai_source_text": master["thai_source_text"],
        "english_draft": english_text or f"Advice {master['recommendation_id']}",
        "approval_status": approval_status,
        "review_comment": "reviewer-only comment",
        "approved_by": "Reviewer Name",
        "approved_at": "2026-07-29T00:00:00+07:00",
    }


class CatalogGeneratorTest(unittest.TestCase):
    def test_generator_rejects_non_approved_rows(self) -> None:
        master = _master_row("act_test.01")

        with self.assertRaisesRegex(ValueError, "approval coverage must be 100%"):
            build_catalog([master], [_approved_row(master, approval_status="pending")])

    def test_generator_rejects_missing_approved_rows(self) -> None:
        first = _master_row("act_test.01")
        second = _master_row("act_test.02", display_order="2")

        with self.assertRaisesRegex(ValueError, "approval coverage must be 100%"):
            build_catalog([first, second], [_approved_row(first)])

    def test_generator_rejects_blank_thai_in_master_or_translation(self) -> None:
        blank_master = _master_row("act_test.blank_master")
        blank_master["thai_source_text"] = "  "
        translation_for_blank_master = _approved_row(blank_master)
        translation_for_blank_master["thai_source_text"] = "คำแนะนำ"

        blank_translation_master = _master_row("act_test.blank_translation")
        blank_translation = _approved_row(blank_translation_master)
        blank_translation["thai_source_text"] = "\t"

        for master, translation in (
            (blank_master, translation_for_blank_master),
            (blank_translation_master, blank_translation),
        ):
            with self.subTest(recommendation_id=master["recommendation_id"]):
                with self.assertRaisesRegex(
                    ValueError,
                    "Thai text must be non-empty",
                ):
                    build_catalog([master], [translation])

    def test_generator_rejects_context_shapes_the_resolver_cannot_reach(
        self,
    ) -> None:
        unsupported = _master_row(
            "act_test.unsupported",
            activity="pruning",
            body_part="trunk",
            risk_level="any",
        )

        with self.assertRaisesRegex(ValueError, "unsupported context shape"):
            build_catalog([unsupported], [_approved_row(unsupported)])

    def test_generated_catalog_contains_approved_copy_without_review_metadata(
        self,
    ) -> None:
        master = _master_row("act_test.01")
        approved = _approved_row(
            master,
            english_text="Keep the farmer's wrist neutral.\nPause safely.",
        )

        dart = build_catalog([master], [approved])

        self.assertIn("คำแนะนำ act_test.01", dart)
        self.assertIn(r"Keep the farmer\'s wrist neutral.\nPause safely.", dart)
        for excluded in (
            "pending",
            "english_draft",
            "review_comment",
            "reviewer-only comment",
            "approved_by",
            "Reviewer Name",
            "approved_at",
        ):
            with self.subTest(excluded=excluded):
                self.assertNotIn(excluded, dart)

    def test_generator_sorts_by_key_specificity_then_display_order(self) -> None:
        rows = [
            _master_row(
                "act_z.global",
                selection_key="act_z",
                activity="any",
                body_part="any",
                risk_level="any",
            ),
            _master_row(
                "act_z.body_any_risk",
                selection_key="act_z",
                activity="any",
                body_part="trunk",
                risk_level="any",
            ),
            _master_row(
                "act_z.activity_any_risk",
                selection_key="act_z",
                activity="pruning",
                body_part="any",
                risk_level="any",
            ),
            _master_row(
                "act_z.body_risk",
                selection_key="act_z",
                activity="any",
                body_part="trunk",
                risk_level="high",
            ),
            _master_row(
                "act_z.activity_risk",
                selection_key="act_z",
                activity="pruning",
                body_part="any",
                risk_level="high",
            ),
            _master_row(
                "act_z.exact_second",
                selection_key="act_z",
                display_order="2",
                activity="pruning",
                body_part="trunk",
                risk_level="high",
            ),
            _master_row(
                "act_z.exact_first",
                selection_key="act_z",
                display_order="1",
                activity="pruning",
                body_part="trunk",
                risk_level="high",
            ),
            _master_row("act_a.global", selection_key="act_a"),
        ]

        dart = build_catalog(rows, [_approved_row(row) for row in rows])

        expected_ids = [
            "act_a.global",
            "act_z.exact_first",
            "act_z.exact_second",
            "act_z.activity_risk",
            "act_z.body_risk",
            "act_z.activity_any_risk",
            "act_z.body_any_risk",
            "act_z.global",
        ]
        positions = [dart.index(f"id: '{item_id}'") for item_id in expected_ids]
        self.assertEqual(positions, sorted(positions))

    def test_generator_emits_thai_and_english_legacy_aliases(self) -> None:
        master = _master_row(
            "act_test.01",
            legacy_text_th="คำแนะนำเดิม",
            legacy_text_en="Previous recommendation",
        )

        dart = build_catalog([master], [_approved_row(master)])

        self.assertIn("'คำแนะนำเดิม': 'act_test'", dart)
        self.assertIn("'Previous recommendation': 'act_test'", dart)


if __name__ == "__main__":
    unittest.main()
