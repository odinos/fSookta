#!/usr/bin/env python3
"""Behavior-first tests for Task 4 architecture artifacts."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
from openpyxl import Workbook
from pypdf import PdfReader

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_task4_architecture as builder
import record_task4_visual_qa as recorder
import verify_task4_artifacts as verifier


class SourceGroundingTests(unittest.TestCase):
    def test_source_scan_extracts_resolved_packages_and_model_identifiers(self) -> None:
        root = Path("/private/tmp/fsookta-final-handover/authoritative-materializations/source-g6tsggy7/source")
        facts = builder.inspect_source(root)
        self.assertEqual(facts["resolved_packages"]["camera"], "0.11.4")
        self.assertEqual(facts["resolved_packages"]["image_picker"], "1.2.2")
        self.assertEqual(facts["resolved_packages"]["firebase_core"], "4.10.0")
        self.assertEqual(facts["resolved_packages"]["shared_preferences"], "2.5.5")
        self.assertEqual(facts["model_versions"]["xgboost"], "reba-iso-xgboost-onnx-2026-06-07")
        self.assertEqual(facts["model_versions"]["daily_logistic"], "daily-injury-logistic-template-2026-06-14")
        self.assertEqual(facts["model_versions"]["movenet_schema"], "movenet-thunder-v1-17x3-normalized")
        self.assertEqual(len(facts["model_versions"]["movenet_thunder_sha256"]), 64)

    def test_source_scan_distinguishes_local_assessment_from_optional_telemetry(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "lib/core/services").mkdir(parents=True)
            (root / "lib/core/services/local.dart").write_text(
                "import 'package:shared_preferences/shared_preferences.dart';\n"
                "final enabled = bool.fromEnvironment('SOOKTA_TELEMETRY_ENABLED', defaultValue: false);\n",
                encoding="utf-8",
            )
            (root / "pubspec.yaml").write_text(
                "version: 1.3.11+28\ndependencies:\n  firebase_analytics: ^12.4.2\n",
                encoding="utf-8",
            )
            facts = builder.inspect_source(root)
        self.assertFalse(facts["assessment_backend_api_present"])
        self.assertTrue(facts["telemetry_declared"])
        self.assertTrue(facts["telemetry_opt_in_default_off"])
        self.assertEqual(facts["api_status"], "N/A with Rationale")

    def test_direct_http_client_import_prevents_na_classification(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "lib").mkdir()
            (root / "lib/client.dart").write_text("import 'package:http/http.dart';\n", encoding="utf-8")
            (root / "pubspec.yaml").write_text("version: 1.3.11+28\n", encoding="utf-8")
            facts = builder.inspect_source(root)
        self.assertTrue(facts["assessment_backend_api_present"])
        self.assertNotEqual(facts["api_status"], "N/A with Rationale")


class ContentContractTests(unittest.TestCase):
    def test_verifier_rejects_constraint_or_wrong_package_versions(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "stack.xlsx"
            workbook = Workbook()
            sheet = workbook.active
            sheet.title = "Technology Stack"
            sheet.append(["Component", "Version / identifier"])
            sheet.append(["camera", "0.11.0+2 constraint"])
            workbook.save(path)
            with self.assertRaises(AssertionError):
                verifier.verify_technology_identifiers(path)

    def test_report_sections_consume_inspected_facts_and_resolve_citations(self) -> None:
        facts = builder.inspect_source(
            Path("/private/tmp/fsookta-final-handover/authoritative-materializations/source-g6tsggy7/source")
        )
        facts["scanned_dart_files"] = 999
        sections = builder.report_sections(facts)
        joined = "\n".join(item["body"] for item in sections)
        self.assertIn("999 Dart files", joined)
        self.assertNotIn("test/assessment_calculation_test.dart", joined)
        self.assertNotIn("docs/uat-test-plan.md", joined)
        self.assertNotIn("docs/uat-test-cases.md", joined)
        statuses = {record["status"] for item in sections for record in item["citation_records"]}
        self.assertIn("Resolved", statuses)
        self.assertIn("Pending future artifact", statuses)
        self.assertNotIn("Missing", statuses)

    def test_status_vocabulary_rejects_unapproved_workbook_value(self) -> None:
        verifier.verify_status_values(["Complete", "Pending Owner Action"])
        with self.assertRaises(AssertionError):
            verifier.verify_status_values(["Complete", "Almost complete"])

    def test_report_sections_are_exactly_the_governing_28_in_order(self) -> None:
        sections = builder.report_sections(builder.minimum_facts_fixture())
        self.assertEqual([item["heading"] for item in sections], builder.REPORT_HEADINGS)
        self.assertEqual(len(sections), 28)
        self.assertTrue(all(item["sources"] for item in sections))
        self.assertTrue(all("bf8867a2083357cb9d60915bf6c2233801f923d8" in item["body"] for item in sections))

    def test_diagram_catalog_has_eight_editable_png_pairs(self) -> None:
        specs = builder.diagram_specs()
        self.assertEqual(len(specs), 8)
        self.assertEqual(len({item["basename"] for item in specs}), 8)
        self.assertTrue(all(item["nodes"] and item["edges"] for item in specs))
        self.assertTrue(all(item["local_boundary"] for item in specs))

    def test_reviewed_diagram_semantics_match_source_data_flow(self) -> None:
        specs = {item["basename"]: item for item in builder.diagram_specs()}
        context = specs["03_system_context"]
        self.assertIn(context["nodes"].index("Optional Firebase telemetry (external)"), context["external_nodes"])

        storage = specs["03_local_storage_and_export"]
        storage_edges = {(storage["nodes"][a], storage["nodes"][b], label) for a, b, label in storage["edges"]}
        self.assertIn(("Temporary / captured image", "Persisted image in application documents", "copy file"), storage_edges)
        self.assertIn(("Assessment record", "CSV in application documents", "write CSV"), storage_edges)
        self.assertNotIn(("SharedPreferences", "CSV in application documents", "write CSV"), storage_edges)

        assessment = specs["03_assessment_algorithm"]
        assessment_edges = {(assessment["nodes"][a], assessment["nodes"][b], label) for a, b, label in assessment["edges"]}
        self.assertIn(("MoveNet 51 joint features", "XGBoost advisory inference", "raw joint features"), assessment_edges)
        self.assertIn(("XGBoost advisory inference", "Final result + advisory", "attach advisory"), assessment_edges)
        self.assertNotIn(("Deterministic score + risk tier", "XGBoost advisory inference", ""), assessment_edges)

    def test_drawio_xml_is_editable_and_source_grounded(self) -> None:
        xml = builder.drawio_xml(builder.diagram_specs()[0])
        self.assertIn("<mxGraphModel", xml)
        self.assertIn("1.3.11+28", xml)
        self.assertIn("bf8867a2083357cb9d60915bf6c2233801f923d8", xml)
        self.assertGreaterEqual(xml.count("vertex=\"1\""), 3)
        self.assertGreaterEqual(xml.count("edge=\"1\""), 2)

    def test_png_edges_terminate_at_node_boundaries_not_text_centers(self) -> None:
        source = (0, 0, 100, 50)
        target = (200, 0, 300, 50)
        start, end = builder.edge_boundary_points(source, target)
        self.assertEqual(start, (100, 25))
        self.assertEqual(end, (200, 25))


class VisualManifestTests(unittest.TestCase):
    def test_task4_visual_expectations_cover_all_22_primary_artifacts(self) -> None:
        expected = recorder.task4_visual_expectations()
        self.assertEqual(len(expected), 22)
        self.assertTrue(all(renders for renders in expected.values()))
        self.assertEqual(
            len([path for path in expected if path.endswith(".drawio")]),
            8,
        )

    def test_checksum_update_preserves_prior_entries_and_adds_task4_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "manifests").mkdir()
            (root / "artifacts").mkdir()
            prior = root / "artifacts/prior.txt"
            current = root / "artifacts/current.txt"
            prior.write_text("prior", encoding="utf-8")
            current.write_text("current", encoding="utf-8")
            checksum = root / "manifests/SHA256SUMS.txt"
            checksum.write_text(
                f"{hashlib.sha256(prior.read_bytes()).hexdigest()}  artifacts/prior.txt\n",
                encoding="ascii",
            )
            recorder.update_checksums(root, [current])
            entries = checksum.read_text(encoding="ascii")
            self.assertIn("artifacts/prior.txt", entries)
            self.assertIn("artifacts/current.txt", entries)

    def test_hash_bound_visual_manifest_rejects_changed_render(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "artifacts").mkdir()
            (root / "renders").mkdir()
            (root / "manifests").mkdir()
            artifact = root / "artifacts/a.pdf"
            render = root / "renders/a.png"
            artifact.write_bytes(b"artifact")
            render.write_bytes(b"render")
            payload = {
                "schema_version": 1,
                "status": "passed",
                "artifacts": [{
                    "path": "artifacts/a.pdf",
                    "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
                    "status": "passed",
                    "renders": [{"path": "renders/a.png", "sha256": hashlib.sha256(render.read_bytes()).hexdigest(), "status": "passed"}],
                }],
            }
            manifest = root / "manifests/visual.json"
            manifest.write_text(json.dumps(payload), encoding="utf-8")
            verifier.verify_visual_manifest(root, manifest, {"artifacts/a.pdf": ["renders/a.png"]})
            render.write_bytes(b"changed")
            with self.assertRaises(AssertionError):
                verifier.verify_visual_manifest(root, manifest, {"artifacts/a.pdf": ["renders/a.png"]})

    def test_workbook_reference_pdf_has_one_page_per_sheet(self) -> None:
        pdf = Path("/private/tmp/fsookta-final-handover/artifacts/03_Technical_Stack_and_Module_Specification.pdf")
        if not pdf.exists():
            self.skipTest("Task 4 workbook PDF not generated yet")
        self.assertEqual(len(PdfReader(pdf).pages), 4)


if __name__ == "__main__":
    unittest.main()
