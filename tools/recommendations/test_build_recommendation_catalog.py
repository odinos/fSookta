from __future__ import annotations

import csv
from copy import deepcopy
import re
from pathlib import Path
import unittest

from tools.recommendations.build_recommendation_catalog import build_catalog
from tools.recommendations.build_recommendation_master import _context


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
        "record_type": "recommendation",
        "category": "posture",
        "activity": activity,
        "body_part": body_part,
        "risk_level": risk_level,
        "thai_source_text": "คำแนะนำทดสอบ",
        "source_id": "test_source",
        "source_page": "1",
        "catalog_version": "2026-07-29.1",
        "record_status": "source_verified",
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
        "english_draft": english_text or "Approved test advice.",
        "record_type": master["record_type"],
        "translation_style": "direct",
        "numbers_match": "pass",
        "units_match": "not_applicable",
        "timing_match": "pass",
        "urgency_match": "pass",
        "negation_match": "pass",
        "meaning_review": "pass",
        "approval_status": approval_status,
        "review_comment": "reviewer-only comment",
        "approved_by": "Reviewer Name",
        "approved_at": "2026-07-29T00:00:00+07:00",
        "translation_version": "1",
        "source_id": master["source_id"],
        "source_page": master["source_page"],
    }


class CatalogGeneratorTest(unittest.TestCase):
    def _build(
        self,
        master_rows: list[dict[str, str]],
        translation_rows: list[dict[str, str]],
        *,
        source_registry_version: str | None = None,
        conflict_rows: list[dict[str, str]] | None = None,
    ) -> str:
        kwargs: dict[str, object] = {
            "conflict_rows": conflict_rows or [],
        }
        if source_registry_version is not None:
            kwargs["source_registry_version"] = source_registry_version
        return build_catalog(master_rows, translation_rows, **kwargs)

    def test_generator_requires_explicit_conflict_report_rows(self) -> None:
        master = _master_row("act_test.01")

        with self.assertRaisesRegex(
            ValueError,
            "approved_conflict_report_missing",
        ):
            build_catalog([master], [_approved_row(master)])

    def test_generator_rejects_non_approved_rows(self) -> None:
        master = _master_row("act_test.01")

        with self.assertRaisesRegex(ValueError, "approved_status"):
            self._build(
                [master],
                [_approved_row(master, approval_status="pending")],
            )

    def test_generator_rejects_missing_approved_rows(self) -> None:
        first = _master_row("act_test.01")
        second = _master_row("act_test.02", display_order="2")

        with self.assertRaisesRegex(ValueError, "approved_review_missing"):
            self._build([first, second], [_approved_row(first)])

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
                    "approved_(master_)?thai_empty",
                ):
                    self._build([master], [translation])

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
            self._build([unsupported], [_approved_row(unsupported)])

    def test_generated_catalog_contains_approved_copy_without_review_metadata(
        self,
    ) -> None:
        master = _master_row("act_test.01")
        approved = _approved_row(
            master,
            english_text="Keep the farmer's wrist neutral.\nPause safely.",
        )

        dart = self._build([master], [approved])

        self.assertIn("คำแนะนำทดสอบ", dart)
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

        dart = self._build(rows, [_approved_row(row) for row in rows])

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

        dart = self._build([master], [_approved_row(master)])

        self.assertIn("'คำแนะนำเดิม': 'act_test'", dart)
        self.assertIn("'Previous recommendation': 'act_test'", dart)

    def test_checksum_covers_aliases_and_catalog_metadata(self) -> None:
        master = _master_row(
            "act_test.01",
            legacy_text_en="Previous recommendation",
        )
        approved = _approved_row(master)
        baseline = self._checksum(
            self._build(
                [master],
                [approved],
                source_registry_version="registry-v1",
            )
        )

        alias_changed = deepcopy(master)
        alias_changed["legacy_text_en"] = "Earlier recommendation"
        catalog_version_changed = deepcopy(master)
        catalog_version_changed["catalog_version"] = "2026-07-30.1"
        checksums = (
            self._checksum(
                self._build(
                    [alias_changed],
                    [_approved_row(alias_changed)],
                    source_registry_version="registry-v1",
                )
            ),
            self._checksum(
                self._build(
                    [catalog_version_changed],
                    [_approved_row(catalog_version_changed)],
                    source_registry_version="registry-v1",
                )
            ),
            self._checksum(
                self._build(
                    [master],
                    [approved],
                    source_registry_version="registry-v2",
                )
            ),
        )

        for checksum in checksums:
            self.assertNotEqual(checksum, baseline)

    def test_generator_emits_canonical_dart_formatting(self) -> None:
        master = _master_row("act_test.01")
        approved = _approved_row(
            master,
            english_text=(
                "Use a deliberately long approved recommendation sentence "
                "that requires a canonical Dart assignment wrap."
            ),
        )

        dart = self._build([master], [approved])

        self.assertIn(
            "    englishText:\n"
            "        'Use a deliberately long approved recommendation "
            "sentence that requires a canonical Dart assignment wrap.',",
            dart,
        )

    def test_real_inputs_regenerate_committed_file_byte_for_byte(self) -> None:
        master_rows = self._read_csv(
            Path("data/recommendations/recommendation_master.csv")
        )
        translation_rows = self._read_csv(
            Path("data/recommendations/translation_review.csv")
        )
        conflict_rows = self._read_csv(
            Path(
                "data/recommendations/reports/"
                "conflicts_missing_sources.csv"
            )
        )
        registry_version = (
            Path("data/recommendations/source_registry.json")
            .read_text(encoding="utf-8")
            .split('"registryVersion": "', maxsplit=1)[1]
            .split('"', maxsplit=1)[0]
        )

        generated = self._build(
            master_rows,
            translation_rows,
            source_registry_version=registry_version,
            conflict_rows=conflict_rows,
        )

        self.assertEqual(
            generated,
            Path(
                "lib/core/recommendations/"
                "generated_recommendation_catalog.dart"
            ).read_text(encoding="utf-8"),
        )

    def test_unlocated_recommendation_key_requires_explicit_provenance(
        self,
    ) -> None:
        with self.assertRaisesRegex(
            ValueError,
            "explicit source provenance required: act_new_unlocated",
        ):
            _context("act_new_unlocated")

    @staticmethod
    def _checksum(dart: str) -> str:
        match = re.search(
            r"recommendationCatalogChecksum\s*=\s*'([0-9a-f]+)'",
            dart,
        )
        if match is None:
            raise AssertionError("checksum constant missing")
        return match.group(1)

    @staticmethod
    def _read_csv(path: Path) -> list[dict[str, str]]:
        with path.open(encoding="utf-8-sig", newline="") as stream:
            return list(csv.DictReader(stream))


if __name__ == "__main__":
    unittest.main()
