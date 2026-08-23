#!/usr/bin/env python3
"""Focused regressions for Task 3 artifact generation and verification."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

from docx import Document

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_task3_release as builder
import verify_task3_artifacts as verifier


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class DependencyRecordTests(unittest.TestCase):
    def test_source_type_license_mapping(self) -> None:
        cases = [
            (
                "hosted_pkg",
                {"source": "hosted", "dependency": "direct main", "version": "1.0.0", "description": {"url": "https://pub.dev"}},
                "https://pub.dev/packages/hosted_pkg",
                "https://pub.dev/packages/hosted_pkg (License tab/package archive)",
            ),
            (
                "flutter",
                {"source": "sdk", "dependency": "direct main", "version": "0.0.0", "description": {"name": "flutter", "url": "flutter"}},
                "Flutter SDK",
                "Flutter SDK LICENSE and package source at the pinned toolchain version",
            ),
            (
                "git_pkg",
                {"source": "git", "dependency": "direct main", "version": "2.0.0", "description": {"url": "https://example.invalid/repo.git", "ref": "abc123", "path": "packages/git_pkg"}},
                "https://example.invalid/repo.git at abc123 (path packages/git_pkg)",
                "License file in https://example.invalid/repo.git at abc123 (path packages/git_pkg)",
            ),
            (
                "onnxruntime",
                {"source": "path", "dependency": "direct main", "version": "1.4.1", "description": {"path": "third_party/onnxruntime_16kb"}},
                "Repository path third_party/onnxruntime_16kb at authoritative commit",
                f"Git {builder.COMMIT}:third_party/onnxruntime_16kb/LICENSE",
            ),
            (
                "other_local",
                {"source": "path", "dependency": "direct dev", "version": "0.1.0", "description": {"path": "packages/other_local"}},
                "Repository path packages/other_local at authoritative commit",
                "License file under repository path packages/other_local; human verification required",
            ),
        ]
        for name, item, expected_url, expected_license_source in cases:
            with self.subTest(name=name):
                record = builder.dependency_record(name, item)
                self.assertEqual(record["source_url"], expected_url)
                self.assertEqual(record["license_text_source"], expected_license_source)
                if name != "onnxruntime":
                    self.assertNotIn("third_party/onnxruntime_16kb/LICENSE", record["license_text_source"])

    def test_transitive_scope_is_unresolved(self) -> None:
        record = builder.dependency_record(
            "transitive_pkg",
            {"source": "hosted", "dependency": "transitive", "version": "1.0.0", "description": {"url": "https://pub.dev"}},
        )
        self.assertEqual(record["classification"], "Unresolved - dependency graph review required")
        self.assertEqual(record["review_status"], "Human verification required")


class ArchiveExclusionTests(unittest.TestCase):
    def test_builder_excludes_nested_outputs_and_signing_material(self) -> None:
        denied = [
            "packages/example/build/output.bin",
            "packages/example/.dart_tool/package_config.json",
            "nested/vendor/generated/lib.a",
            "nested/cache/download.bin",
            "ios/signing/AuthKey_ABC123.p8",
            "android/release/upload.pfx",
            "android/app/key.properties",
            "ios/Profile.mobileprovision",
            "config/service-account.json",
        ]
        for path in denied:
            with self.subTest(path=path):
                self.assertTrue(builder.excluded(path))

    def test_verifier_uses_independent_path_and_content_denylist(self) -> None:
        self.assertIsNot(verifier.independent_archive_path_violation, builder.excluded)
        self.assertIsNotNone(verifier.independent_archive_path_violation("a/b/build/output.bin"))
        self.assertIsNotNone(verifier.independent_archive_path_violation("ios/key/AuthKey_TEST.p8"))
        self.assertIsNone(verifier.independent_archive_path_violation("lib/main.dart"))
        self.assertIsNotNone(
            verifier.secret_content_violation(
                "config.json",
                b'{"private_key":"-----BEGIN PRIVATE KEY-----\\nabc","client_email":"x@example.invalid"}',
            )
        )
        self.assertIsNone(verifier.secret_content_violation("docs/note.md", b"Signing ownership remains unverified."))


class FormulaExpectationTests(unittest.TestCase):
    def make_workbook(
        self,
        root: Path,
        *,
        formula: str = "SUM(A1:A2)",
        value: str | None = "3",
        relationship_target: str = "worksheets/sheet1.xml",
    ) -> Path:
        path = root / "formula.xlsx"
        value_xml = "" if value is None else f"<v>{value}</v>"
        with zipfile.ZipFile(path, "w") as package:
            package.writestr(
                "xl/workbook.xml",
                '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
                'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
                '<sheets><sheet name="Summary" sheetId="1" r:id="rId1"/></sheets></workbook>',
            )
            package.writestr(
                "xl/_rels/workbook.xml.rels",
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
                f'Target="{relationship_target}"/></Relationships>',
            )
            package.writestr(
                "xl/worksheets/sheet1.xml",
                '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
                f'<row r="5"><c r="B5" t="n"><f>{formula}</f>{value_xml}</c></row>'
                "</sheetData></worksheet>",
            )
        return path

    def test_expected_formula_and_cached_value_are_required(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            workbook = self.make_workbook(root)
            verifier.verify_xlsx_formula_expectations(
                workbook,
                {"Summary": {"B5": {"formula": "SUM(A1:A2)", "value": "3"}}},
            )
            with self.assertRaises(AssertionError):
                verifier.verify_xlsx_formula_expectations(
                    workbook,
                    {"Summary": {"B5": {"formula": "SUM(A1:A9)", "value": "3"}}},
                )
            with self.assertRaises(AssertionError):
                verifier.verify_xlsx_formula_expectations(
                    self.make_workbook(root, value=None),
                    {"Summary": {"B5": {"formula": "SUM(A1:A2)", "value": "3"}}},
                )

    def test_absolute_xlsx_relationship_target_is_normalized(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            workbook = self.make_workbook(Path(temp), relationship_target="/xl/worksheets/sheet1.xml")
            verifier.verify_xlsx_formula_expectations(
                workbook,
                {"Summary": {"B5": {"formula": "SUM(A1:A2)", "value": "3"}}},
            )


class VisualManifestTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "artifacts").mkdir()
        (self.root / "renders").mkdir()
        self.artifact = self.root / "artifacts" / "a.pdf"
        self.render = self.root / "renders" / "a-page-1.png"
        self.artifact.write_bytes(b"artifact")
        self.render.write_bytes(b"render")
        self.expected = {"artifacts/a.pdf": ["renders/a-page-1.png"]}

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_manifest(self, *, artifact_hash: str | None = None, renders: list[str] | None = None) -> None:
        render_paths = renders if renders is not None else self.expected["artifacts/a.pdf"]
        payload = {
            "schema_version": 1,
            "inspected_at": "2026-08-23T23:00:00+07:00",
            "reviewer_role": "Task 3 artifact QA reviewer",
            "status": "passed",
            "notes": "Inspected at 100%; no clipping or overlap.",
            "artifacts": [
                {
                    "path": "artifacts/a.pdf",
                    "sha256": artifact_hash or digest(self.artifact),
                    "status": "passed",
                    "notes": "legible",
                    "renders": [
                        {"path": value, "sha256": digest(self.root / value), "status": "passed", "notes": "clean"}
                        for value in render_paths
                    ],
                }
            ],
        }
        (self.root / "manifests").mkdir(exist_ok=True)
        (self.root / "manifests" / "task3_visual_qa_manifest.json").write_text(json.dumps(payload), encoding="utf-8")

    def test_absent_manifest_fails(self) -> None:
        with self.assertRaises(AssertionError):
            verifier.verify_visual_qa_manifest(self.root, self.expected)

    def test_stale_artifact_hash_fails(self) -> None:
        self.write_manifest(artifact_hash="0" * 64)
        with self.assertRaises(AssertionError):
            verifier.verify_visual_qa_manifest(self.root, self.expected)

    def test_missing_render_fails(self) -> None:
        self.write_manifest(renders=[])
        with self.assertRaises(AssertionError):
            verifier.verify_visual_qa_manifest(self.root, self.expected)


class TitleResidueTests(unittest.TestCase):
    def test_title_paragraph_border_is_rejected(self) -> None:
        xml = ET.fromstring(
            f'<w:document xmlns:w="{verifier.NS_W}"><w:body><w:p><w:pPr><w:pBdr>'
            '<w:bottom w:val="single" w:sz="6"/></w:pBdr></w:pPr><w:r><w:t>Title</w:t></w:r>'
            "</w:p></w:body></w:document>"
        )
        self.assertIn("title paragraph border", verifier.title_residue_violations(xml))


class RepositoryPaginationTests(unittest.TestCase):
    def test_final_deployment_bullet_has_explicit_safe_page_start(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "repository.docx"
            builder.build_repository_doc(
                output,
                Path(temp),
                {
                    "archive": "/tmp/SookTa-1.3.11+28-source-snapshot.tar.gz",
                    "file_count": 365,
                    "sha256": "0" * 64,
                },
            )
            document = Document(output)
            target = next(
                paragraph
                for paragraph in document.paragraphs
                if paragraph.text.startswith("Complete store metadata, privacy declarations")
            )
            self.assertIs(target.paragraph_format.page_break_before, True)
            self.assertIs(target.paragraph_format.keep_together, True)
            self.assertEqual(target.paragraph_format.space_before.pt, 6)


if __name__ == "__main__":
    unittest.main()
