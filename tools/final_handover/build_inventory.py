#!/usr/bin/env python3
"""Build reproducible, non-sensitive handover requirement/evidence inventories.

The catalog below is a transcription of the governing Drive PDF.  It deliberately
does not promote historic artifacts into final-release evidence or invent
handover, signature, research-participant, account, or secret evidence.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path


BASELINE_COMMIT = "bf8867a2083357cb9d60915bf6c2233801f923d8"
BASELINE_VERSION = "1.3.11+28"
GOVERNING_PDF_ID = "1OVOS13DQCNxK2PjAnmk3CYckcf2KCH0N"
SOURCE_FOLDER_ID = "1Stq-imQPq9lcM2Spdvqcfj4M80ERNZFt"
FINAL_FOLDER_ID = "1iAADHY0UN4DVmBydPPvYJqYJsP10A5Hk"
TERMINAL_STATUSES = (
    "Complete",
    "Complete - Pending Signature",
    "Pending Owner Action",
    "Pending Researcher Evidence",
    "N/A with Rationale",
    "Exception Approval Required",
)
REQUIRED_STAGING_DIRS = ("artifacts", "evidence", "renders", "archives", "manifests")

# Each value is (deliverable/governing text, required format).  English wording
# and formatting are retained verbatim from the PDF's English table cells.
ROWS = {
    "4": [
        ("Final production build of SookTa with version number and release date", "APK/AAB/IPA/TestFlight/URL + Release Note"),
        ("Final feature list identifying every function in the live system", "Word/Excel"),
        ("Original-scope items not developed/changed, with reasons", "Change log / Scope closure table"),
        ("Features added later, with source of request and rationale", "Change log"),
        ("Known limitations and known bugs remaining, with user/research impact", "Word/Excel"),
        ("Final Release Notes and version freeze statement", "PDF + editable source"),
    ],
    "5": [
        ("Complete source code: mobile app, backend/API, web/admin, AI/image processing, recommendation engine", "Repository + archive"),
        ("Dependency/configuration/build files and environment setup files", "Repository"),
        ("README: how to install dependencies, run project, build and deploy", "README/Word"),
        ("Repository ownership transfer or Admin/Owner access for the researcher", "Repository access evidence"),
        ("Commit history, branches, tags and Final Version tag", "Repository"),
        ("Database migration/schema scripts", "Repository/SQL"),
        ("Third-party libraries/SDK/API and license for each", "Excel/Word"),
        ("Components owned by developer/third party or with use restrictions", "Word"),
        ("Confirmation of rights to use, modify, continue development and use for research/publication under the project agreement", "Signed PDF"),
    ],
    "6": [
        ("All hosting/cloud/database/storage/domain/API services", "Excel/Word"),
        ("Production architecture and environment information", "Diagram + Word"),
        ("Owner/Admin access transfer: cloud, Firebase, database, hosting, app store/play store, analytics/logging", "Access transfer checklist"),
        ("Billing account, recurring cost, subscription/license and expiry date", "Excel"),
        ("Domain, SSL, certificate and renewal information", "Word/Excel"),
        ("Credentials/secrets requiring handover through a secure channel", "Secure handover record"),
        ("Confirmation that no production dependency is tied to a developer personal account without researcher access", "Signed statement"),
    ],
    "7": [
        ("High-level System Architecture Diagram", "Editable diagram + PNG ≥300 dpi"),
        ("Data flow: App → Backend/API → Database/Storage → Result/Recommendation", "Editable diagram + PNG"),
        ("Image upload/storage/processing flow", "Editable diagram + PNG"),
        ("Authentication/user role flow (if applicable)", "Diagram + description"),
        ("Final technical stack: language, framework, backend, database, cloud, storage, AI/ML, API, logging with versions", "Table (Word/Excel)"),
        ("Module specification: input, processing, output, dependency for each module", "Technical specification"),
        ("API documentation: endpoint, method, request, response, authentication, error code", "API doc / Postman export if applicable"),
    ],
    "8": [
        ("Development timeline from requirement gathering to final production version", "Gantt/Timeline + editable source"),
        ("Milestones: wireframe, prototype, alpha, beta, field-test version, post-field revision, final release", "Timeline"),
        ("Development methodology/process actually used", "Technical report section"),
        ("Requirement Traceability Matrix: Requirement → Feature → Technical Implementation → Test → Result → Status", "Excel"),
        ("Complete version history with dates and changes", "Excel/Word"),
        ("Feedback-to-modification matrix identifying source: researcher/user/expert/field test/technical issue", "Excel"),
        ("Wireframes, prototype, intermediate UI and final UI", "Figma/export + PNG"),
        ("Before/After evidence of significant design changes with rationale", "Word/PPT/PNG"),
        ("Final user flow / screen flow / navigation map", "Editable diagram + PNG"),
        ("Development decision log and technical trade-offs", "Word/Excel"),
        ("Technical challenges: problem → root cause → options → selected solution → rationale → result → remaining limitation", "Word/Excel"),
        ("Development effort summary: duration, iterations, releases, test cycles, issues found/resolved (developer-hours if available)", "Word/Excel"),
    ],
    "9": [
        ("End-to-end ergonomic assessment workflow from input to output", "Flowchart + technical description"),
        ("Image acquisition specification: number/angles used and image acceptance criteria", "Technical spec + diagram"),
        ("Handling logic for incomplete, unclear, undetectable images or failed upload", "Decision table"),
        ("Name and version of AI/model/algorithm/computer vision actually used", "Technical report"),
        ("Clearly identify pretrained AI, fine-tuned/custom model, deterministic/rule-based logic, or researcher-defined rules", "Architecture/logic table"),
        ("If training/fine-tuning: dataset source, sample size, annotation, split, augmentation, hyperparameters, training procedure, model-selection criteria", "Model documentation + raw logs"),
        ("If no training/fine-tuning: statement of how pretrained model is used and that no project model-training claim is made", "Signed/technical statement"),
        ("Risk classification logic: formula, threshold, category, mapping, decision tree/pseudocode", "Editable algorithm specification"),
        ("Recommendation engine: Detected Risk → Risk Level → Recommendation → Source/Guideline → App Message", "Excel"),
        ("Trigger condition, priority logic and conflict handling when multiple risks occur", "Decision table"),
        ("Thai text displayed in app plus English equivalent for manuscript", "Excel/Word"),
        ("Reference/guideline/source used to set every ergonomic rule and recommendation", "Reference matrix"),
    ],
    "10": [
        ("ER Diagram / Database schema", "Editable diagram + PNG"),
        ("Data Dictionary: variable name, description, type, allowed value, unit, source, missing code", "Excel"),
        ("Raw database export and processed/research-ready export", "CSV/XLSX/SQL"),
        ("Assessment result data, recommendation data, image metadata, timestamp, status/error fields", "CSV/XLSX"),
        ("User/participant/session identifier mapping logic without disclosing more than necessary", "Technical note"),
        ("Data export procedure for researcher after closure", "Manual"),
        ("Data validation rules, duplicate prevention, missing-data handling, timestamp logic", "Technical specification"),
        ("Backup, restore, retention and deletion procedure", "Manual/Policy note"),
        ("Application/system/error logs relevant to testing and field-test period", "Exported logs"),
    ],
    "11": [
        ("Master Test Plan specifying test type, objective, scope, version, tester, date, acceptance criteria", "Word/Excel"),
        ("Functional test cases for every feature: expected result, actual result, pass/fail, evidence", "Excel + screenshots/logs"),
        ("Input validation tests: correct, invalid, missing, unsupported, duplicate, unexpected user action", "Excel + evidence"),
        ("Network/error handling tests: network interruption, timeout, failed upload, retry behavior", "Excel + logs"),
        ("Reference/algorithm verification cases: Reference/Expected Result vs App Result", "Excel + evidence"),
        ("Boundary tests around thresholds that change risk category", "Excel"),
        ("Unit testing / Integration testing / System testing / Regression testing (as actually used)", "Test report + raw output"),
        ("API/database testing (if applicable)", "Test report"),
        ("Device/OS/screen-size compatibility test matrix", "Excel"),
        ("Performance testing: startup, upload, processing, result/recommendation generation time", "Raw measurement + summary"),
        ("Bug log: severity, root cause, fix, retest, version, status", "Excel"),
        ("Final Algorithm Verification Report: number of tests, correct/incorrect result, discrepancy, correction, retest", "Report + raw cases"),
        ("All test evidence identifies the application version tested", "Mandatory metadata"),
    ],
    "12": [
        ("UAT protocol/scenario, user tasks, success criteria, result and sign-off", "Word/Excel"),
        ("Field-test application version, date, device, procedure, technical issues, error records", "Field test technical report"),
        ("Feedback received from field test and modifications made afterwards", "Feedback/modification matrix"),
        ("Recommendations not implemented, with reasons", "Decision log"),
        ("Technical data for SUS/usability evaluation: version, feature set, task flow, technical failures, incomplete sessions", "Word/Excel"),
        ("Application logs corresponding to usability/field-test period (if available and permitted to retain)", "Exported logs"),
    ],
    "13": [
        ("Security architecture and authentication/access-control mechanism", "Technical note/diagram"),
        ("Encryption in transit / at rest (if applicable) and image/data storage security", "Technical note"),
        ("User roles and permissions", "Access-control matrix"),
        ("Personal/research data stored by the system and third-party services receiving data", "Data flow/privacy table"),
        ("Participant/image linkage, storage location and authorised access", "Technical note"),
        ("Retention/deletion/backup procedure aligned to research protocol", "Procedure"),
        ("Security testing performed and remaining security limitations", "Test summary"),
        ("Confirmation of deletion/non-retention of unauthorised research-data copies after handover, where aligned with agreements and ethics", "Signed confirmation"),
    ],
    "14": [
        ("End-User Manual: install/login/upload/assessment/result/recommendation/error troubleshooting", "PDF + editable Word"),
        ("Administrator Manual: user/data management, export, backup, restore, logs, troubleshooting", "PDF + editable Word"),
        ("Developer Handover Manual: project structure, setup, build, deploy, DB migration, update, common errors", "PDF + editable Word"),
        ("Knowledge-transfer session covering architecture, code, database, algorithm, admin, export, backup, deploy, troubleshooting", "Recorded session/minutes + slides"),
        ("Technical contact / escalation information after handover according to agreed support period", "Contact sheet"),
    ],
    "15": [
        ("Final Technical Development Report complete to Section 16", "Word + PDF"),
        ("Thesis Chapter 4 data/tables: timeline, iterations, feature evolution, testing, UAT/field-test technical result", "Editable tables"),
        ("Thesis Chapter 5 data: feasibility, challenge, trade-off, limitations, scalability, maintainability, future development", "Technical discussion notes"),
        ("Paper 2 Methods data: development framework, architecture, stack, requirement translation, iterations", "Structured Word/Excel"),
        ("Paper 2 Results data: final features, technical verification, bugs/fixes, performance, UAT/field-test technical evidence", "Structured Word/Excel"),
        ("Editable publication figures: development process, architecture, app workflow, image processing, assessment algorithm, recommendation flow, database/data flow, prototype-to-final timeline, final screens", "Editable source + PNG ≥300 dpi"),
        ("Editable publication tables: requirements, features, technical stack, traceability, version history, feedback/modification, test results, algorithm verification, device compatibility, bug summary, challenges/solutions, limitations", "Excel/Word"),
        ("Raw evidence archive: requirements, meeting notes, Figma/design files, test scripts/output, bug tickets, screenshots, logs, Git history", "Organized folders"),
    ],
}

CHECKLISTS = {
    "16": [
        "Project background and objectives", "Original vs final requirements", "Development methodology/process", "Development timeline and milestones", "System architecture", "Technology stack", "Application modules and user workflow", "Image acquisition and processing workflow", "Ergonomic assessment algorithm", "AI/model description and role", "Recommendation engine and source of rules", "Database architecture and data flow", "Prototype development and iterative modifications", "Verification and testing methodology", "Functional test results", "Algorithm/reference verification", "Integration/system/regression tests", "Compatibility/device tests", "Performance tests", "UAT and field-test technical support", "Bugs, corrective actions and retesting", "Final application specification", "Security, privacy and data management", "Technical challenges and solutions", "Technical limitations and known issues", "Scalability/maintainability", "Future development recommendations", "Final acceptance and handover statement",
    ],
    "17": [
        "Application name and Final Version", "Development period", "Developer/Company", "Scope performed and scope not performed", "Technology used", "Confirmation of Final Version delivered", "Confirmation of Source Code and Repository Access handover", "Confirmation of Server/Cloud/Database/Admin Access handover", "Confirmation of Technical Documentation and Testing Evidence handover", "Confirmation of Research Data/Data Dictionary handover according to scope", "Known limitations and known bugs", "Confirmation that the handover package is sufficient for another developer to maintain the system", "Signer name, signature and date",
    ],
    "18": [
        "Final working application + final version freeze", "Complete source code + repository ownership/admin access", "Cloud/server/database/admin ownership/access transfer", "System architecture + technical stack documentation", "Ergonomic assessment algorithm + AI/model role + recommendation logic", "Complete development timeline + requirement traceability + version history", "Test plan + test cases + expected vs actual results + evidence + bug/retest records", "Database/data export + Data Dictionary", "Final Technical Development Report", "User/Admin/Developer manuals + Knowledge Transfer", "Research/publication package for Chapter 4, Chapter 5 and Paper 2", "Signed Final Developer Statement / Handover Sign-off",
    ],
}

DRIVE_FOLDERS = [
    ("Sookta", SOURCE_FOLDER_ID, "source parent"), ("Final", FINAL_FOLDER_ID, "destination parent"),
    ("Documents", "1p3Qa-OTjz0X1_IDYI_qCg4NvZSO_HZDh", "historic contracts, sign-off, and documents"),
    ("doclasted", "1a8LZxpmjlIOS-2JAFDunuZ4hQa9NcuWg", "historic data-dictionary/calculation exports"),
    ("Test dataset", "1170EJ6bMN_FE_kF2nIWlgTNvmm3Nk10k", "research/test dataset; never copy raw participant data"),
    ("develop", "12ekAaDaTgeonGvmGrTxTzPmYABo1xveF", "development/co-design source"),
    ("shared", "1EyisFY7BiUpgu4UXZkECvFsda8yiGhVy", "shared training documents"),
    ("Share", "1ZgdbYc6m-BdkVMMCva2p8gd5rkuqmL-u", "governing requirements and historical share area"),
    ("SourceCode", "1nc_vJEjxoZEYr1kLXN8zgg9Q8Ywh3VmZ", "empty at inventory time"),
    ("APK", "14Ua230hQ9LleHqynsZVJFT2NOLgi4rVn", "historic APKs only"),
    ("Wireframe", "1Y0FEQqVta4QV6dkHGwpE5KlOkJuus9z0", "empty at inventory time"),
]

# Direct children observed from the Sookta source parent.  This metadata-only
# list is deliberately separate from the curated evidence list below so later
# tasks can reproduce discovery without treating every item as proof.
SOURCE_PARENT_CHILDREN = [
    ("Final", FINAL_FOLDER_ID, "application/vnd.google-apps.folder"),
    ("shared", "1EyisFY7BiUpgu4UXZkECvFsda8yiGhVy", "application/vnd.google-apps.folder"),
    ("Test dataset", "1170EJ6bMN_FE_kF2nIWlgTNvmm3Nk10k", "application/vnd.google-apps.folder"),
    ("Markdown", "18qbQ2kBz9Gfye_SaVgoegRywi00pZvNk", "application/vnd.google-apps.folder"),
    ("task", "1wK7OG4ZKtF1yJWNjOHKj93t1AG_FFk5K", "application/vnd.google-apps.folder"),
    ("doclasted", "1a8LZxpmjlIOS-2JAFDunuZ4hQa9NcuWg", "application/vnd.google-apps.folder"),
    ("develop", "12ekAaDaTgeonGvmGrTxTzPmYABo1xveF", "application/vnd.google-apps.folder"),
    ("Wireframe", "1Y0FEQqVta4QV6dkHGwpE5KlOkJuus9z0", "application/vnd.google-apps.folder"),
    ("APK", "14Ua230hQ9LleHqynsZVJFT2NOLgi4rVn", "application/vnd.google-apps.folder"),
    ("Share", "1ZgdbYc6m-BdkVMMCva2p8gd5rkuqmL-u", "application/vnd.google-apps.folder"),
    ("SourceCode", "1nc_vJEjxoZEYr1kLXN8zgg9Q8Ywh3VmZ", "application/vnd.google-apps.folder"),
    ("Documents", "1p3Qa-OTjz0X1_IDYI_qCg4NvZSO_HZDh", "application/vnd.google-apps.folder"),
]

DRIVE_ITEMS = [
    ("Documents", "Sookta-SignOff 20250913.pdf", "1LPRM4KgC9uashkW32iRuASelutyeXtT9", "application/pdf", "historic sign-off; not final sign-off"),
    ("Documents", "สัญญาจ้างพัฒนาแอปพลิเคชัน สุขท่า Sookta 20250913 prove.docx", "1I5MmBhfyY72ePQYWILCVMDcEFZwx3rxq", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "historic contract source"),
    ("Documents", "Sookta TechDocument 1.0.pdf", "1xB-Bg-Wflz4M_rCqQv4_-5uh0meLXVXd", "application/pdf", "historic technical document"),
    ("doclasted", "sookta_research_sample_export_reba_iso_trend_20260625.csv", "18VkAR9sHN-Um5LNEoj2rd_2npVCTNmcQ", "text/csv", "historic sample export"),
    ("Test dataset", "sookta_all_farmers_2026-07-12T231820454786.csv", "18cGrLFz14oeIlNJR4NYt2oZTgQWgnzEB", "text/csv", "participant/research data; inventory metadata only"),
    ("develop", "Sookta_Phase_CoDesign", "1QuMMq0S2tq9_UOeLY-SmBxRsLNZJH2nv", "application/vnd.google-apps.folder", "development evidence folder"),
    ("shared", "docfortrain", "1Mm4MRrDQkMD5dY_R9a3FyftfB1LqpCmg", "application/vnd.google-apps.folder", "shared training source folder"),
    ("Share", "SookTa_Final_Application_Handover_Requirements.pdf", GOVERNING_PDF_ID, "application/pdf", "governing requirements"),
    ("APK", "sookta 1.04.apk", "1vsJOwIfbWUiONbusmiI3NzAiYXPVUc-y", "application/vnd.android.package-archive", "historic APK only; not final version"),
]

REPO_SOURCES = [
    ("source", "lib/", "Flutter application source; baseline evidence only"),
    ("docs", "README.md", "run/build documentation source"),
    ("tests", "test/ and integration_test/", "automated test source/evidence"),
    ("datasets", "data/research/", "research data templates/labels; check data governance before use"),
    ("screenshots", "docs/qa/ and docs/user_manual_v1_1_1_android/", "historic screenshots and QA renders"),
    ("logs", "docs/uat_evidence_*/", "historic device/log evidence"),
    ("manuals", "assets/documents/sookta_user_manual.pdf and docs/user_manual_v1_1_1_android/", "historic user-manual evidence"),
    ("models", "assets/ml/ and assets/models/", "bundled ML/model artifacts"),
    ("store metadata", "docs/app-store-*.md and docs/play-store-*.md", "store metadata source"),
]


def requirement_status(requirement_id: str) -> str:
    section = requirement_id.split(".")[0]
    if section == "12":
        return "Pending Researcher Evidence"
    if section == "18":
        return "Exception Approval Required"
    return "Pending Owner Action"


def is_critical(requirement_id: str) -> bool:
    section, number = requirement_id.split(".")
    if section in {"16", "17", "18"}:
        return True
    critical_numbers = {
        "4": {"1", "6"}, "5": {"1", "4"}, "6": {"3"}, "7": {"1", "5"},
        "8": {"1", "4", "5"}, "9": {"1", "4", "5", "8", "9"},
        "10": {"2", "3"}, "11": {"1", "2", "5", "6", "11", "13"},
        "14": {"1", "2", "3", "4"}, "15": set(map(str, range(1, 9))),
    }
    return number in critical_numbers.get(section, set())


def sources_for(requirement_id: str) -> list[dict]:
    section = requirement_id.split(".")[0]
    sources = [{"source_id": "governing_pdf", "authority": "governing", "kind": "requirements", "reference": f"Drive file {GOVERNING_PDF_ID}"}]
    if section in {"4", "5", "7", "8", "9", "11", "14", "15", "16"}:
        sources.append({"source_id": "repo_baseline", "authority": "baseline", "kind": "repository", "reference": f"Git {BASELINE_COMMIT}; version {BASELINE_VERSION}"})
    if section in {"10", "12", "13", "15"}:
        sources.append({"source_id": "drive_historic_data", "authority": "historic", "kind": "Drive inventory", "reference": "Test dataset/doclasted inventory metadata only"})
    if section in {"6", "17", "18"} or requirement_id in {"5.4", "5.9", "13.8", "14.4"}:
        sources.append({"source_id": "owner_action", "authority": "human", "kind": "handover action", "reference": "Must be evidenced by the responsible owner/signer; no inferred completion"})
    return sources


def build_requirements() -> list[dict]:
    items = []
    for section, rows in ROWS.items():
        for index, (text, fmt) in enumerate(rows, 1):
            rid = f"{section}.{index}"
            items.append({"requirement_id": rid, "section": section, "deliverable": text, "required_format": fmt, "critical_blocker": is_critical(rid), "governing_text": text})
    for section, obligations in CHECKLISTS.items():
        for index, text in enumerate(obligations, 1):
            rid = f"{section}.{index}"
            items.append({"requirement_id": rid, "section": section, "deliverable": text, "required_format": "Checklist obligation", "critical_blocker": True, "governing_text": text})
    return items


def build_repo_inventory(evidence_date: str) -> dict:
    return {"schema_version": 1, "baseline": {"commit": BASELINE_COMMIT, "application_version": BASELINE_VERSION, "evidence_date": evidence_date}, "records": [
        {"git_path": path, "commit": BASELINE_COMMIT, "application_version": BASELINE_VERSION, "evidence_date": evidence_date, "artifact_type": kind, "relevance": relevance}
        for kind, path, relevance in REPO_SOURCES
    ]}


def build_drive_inventory(evidence_date: str) -> dict:
    return {"schema_version": 1, "evidence_date": evidence_date, "governing_pdf": {"id": GOVERNING_PDF_ID, "title": "SookTa_Final_Application_Handover_Requirements.pdf", "mime_type": "application/pdf", "modified_time": "2026-08-23T12:53:22.000Z"}, "parents": {"source": SOURCE_FOLDER_ID, "destination_final": FINAL_FOLDER_ID}, "source_parent_children": [
        {"title": title, "id": folder_id, "mime_type": mime_type} for title, folder_id, mime_type in SOURCE_PARENT_CHILDREN
    ], "folders": [
        {"title": title, "id": folder_id, "inventory_scope": scope} for title, folder_id, scope in DRIVE_FOLDERS
    ], "selected_items": [
        {"folder": folder, "title": title, "id": item_id, "mime_type": mime_type, "relevance": relevance, "evidence_class": "governing" if item_id == GOVERNING_PDF_ID else "historic"}
        for folder, title, item_id, mime_type, relevance in DRIVE_ITEMS
    ], "safety_note": "Raw Drive documents, participant media/data, secrets, and credentials are not copied into this inventory."}


def build_evidence_map(requirements: list[dict]) -> dict:
    records = []
    for requirement in requirements:
        rid = requirement["requirement_id"]
        status = requirement_status(rid)
        records.append({
            "requirement_id": rid,
            "status": status,
            "authoritative_sources": sources_for(rid),
            "human_action": "Obtain, create, or verify final-version evidence with the responsible owner; do not rely on historic evidence alone.",
            "final_version_claim": False,
            "rationale": "The inventory records sources and outstanding action only. It does not assert completion, validation, signature, transfer, participant evidence, or secret delivery.",
        })
    return {"schema_version": 1, "terminal_statuses": list(TERMINAL_STATUSES), "records": records}


def validate(requirements: list[dict], evidence_map: dict) -> list[str]:
    errors = []
    requirement_ids = {r["requirement_id"] for r in requirements}
    mapping = {r["requirement_id"]: r for r in evidence_map["records"]}
    if len(requirement_ids) != len(requirements):
        errors.append("duplicate requirement IDs")
    missing = sorted(requirement_ids - mapping.keys())
    if missing:
        errors.append(f"unmapped requirements: {', '.join(missing)}")
    unexpected = sorted(mapping.keys() - requirement_ids)
    if unexpected:
        errors.append(f"unknown mapped requirements: {', '.join(unexpected)}")
    for rid, record in mapping.items():
        if record["status"] not in TERMINAL_STATUSES:
            errors.append(f"{rid}: unapproved terminal status {record['status']}")
        if not record["authoritative_sources"]:
            errors.append(f"{rid}: no mapped evidence sources")
        if not record["human_action"]:
            errors.append(f"{rid}: no human action")
        historic_only = all(source["authority"] == "historic" for source in record["authoritative_sources"])
        if record["final_version_claim"] and historic_only:
            errors.append(f"{rid}: final-version claim points only to historical evidence")
    if not any(record["human_action"] for record in mapping.values()):
        errors.append("human-action list is empty")
    expected_counts = {str(section): len(rows) for section, rows in ROWS.items()} | {str(section): len(rows) for section, rows in CHECKLISTS.items()}
    actual_counts = Counter(r["section"] for r in requirements)
    if dict(actual_counts) != expected_counts:
        errors.append(f"section counts differ: actual={dict(actual_counts)} expected={expected_counts}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--evidence-date", default="2026-08-23")
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for name in REQUIRED_STAGING_DIRS:
        (args.output_dir / name).mkdir(exist_ok=True)
    requirements = build_requirements()
    evidence_map = build_evidence_map(requirements)
    errors = validate(requirements, evidence_map)
    for name, value in (("requirements.json", {"schema_version": 1, "requirements": requirements}), ("source_inventory.json", build_repo_inventory(args.evidence_date)), ("drive_source_inventory.json", build_drive_inventory(args.evidence_date)), ("evidence_map.json", evidence_map)):
        (args.output_dir / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    summary = {"requirement_count": len(requirements), "by_section": dict(sorted(Counter(r["section"] for r in requirements).items(), key=lambda item: int(item[0]))), "by_status": dict(sorted(Counter(r["status"] for r in evidence_map["records"]).items())), "validation_errors": errors}
    (args.output_dir / "inventory_validation.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    if errors:
        print(json.dumps(summary, indent=2))
        return 1
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
