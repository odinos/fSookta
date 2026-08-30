#!/usr/bin/env python3
"""Scan final Task 7/package content without introducing a hash cycle."""
from __future__ import annotations

import hashlib
import json
import os
import re
import tarfile
import zipfile
from pathlib import Path


ROOT = Path(os.environ.get("SOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
ART = ROOT / "artifacts"
MAN = ROOT / "manifests"
OUTPUT = MAN / "task7_final_content_inspection.json"
VERSION = "1.3.11+28"
COMMIT = "bf8867a2083357cb9d60915bf6c2233801f923d8"

SECRET_PATTERNS = {
    "private_key_marker": re.compile(rb"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY"),
    "aws_access_key_marker": re.compile(rb"AKIA[0-9A-Z]{16}"),
    "github_token_marker": re.compile(rb"(?:ghp|github_pat)_[0-9A-Za-z_]{20,}"),
    "google_api_key_marker": re.compile(rb"AIza[0-9A-Za-z_-]{30,}"),
}
PARTICIPANT_PATTERNS = {
    "email_address": re.compile(rb"(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"),
    "thai_phone_number": re.compile(rb"(?<!\d)(?:\+66|0)[689]\d{8}(?!\d)"),
    "thai_national_id_shape": re.compile(rb"(?<!\d)\d{13}(?!\d)"),
    "participant_value_assignment": re.compile(rb"(?i)(?:participant|farmer|profile)[_-]?(?:id|name)\s*[:=]\s*[\"'][^\"']{2,}[\"']"),
}
BINARY_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".tflite", ".onnx", ".so", ".bin", ".a", ".apk", ".ipa"}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_root() -> Path:
    identity = json.loads((MAN / "task7_source_identity.json").read_text())
    candidates = []
    for source in sorted((ROOT / "authoritative-materializations").glob("source-*/source")):
        archive = source.parent / "authoritative-source.tar"
        if archive.is_file() and sha256(archive) == identity["authoritative_tar_sha256"]:
            candidates.append(source)
    if not candidates:
        raise FileNotFoundError("authoritative source matching Task 7 identity is absent")
    return candidates[0]


def participant_disposition(domain: str, logical_path: str, pattern: str):
    normalized = logical_path.split("::", 1)[-1]
    suffix = Path(normalized).suffix.lower()
    if domain == "office":
        return "office_content_identifier_candidate", "Current or prior Office content requires researcher review; no matched value retained", "Open - Pending Researcher"
    if domain == "manifests":
        return "manifest_identifier_candidate", "Manifest metadata/reference content requires researcher review; no matched value retained", "Open - Pending Researcher"
    if suffix in BINARY_SUFFIXES:
        return "binary_byte_coincidence", "Pattern occurs in binary bytes and is not interpreted as participant data", "Reviewed - False Positive"
    if normalized.startswith(("test/", "integration_test/")):
        return "nonproduction_test_fixture", "Literal occurs in a versioned automated-test fixture", "Reviewed - Test Fixture"
    if normalized == "pubspec.lock":
        return "dependency_metadata_numeric_token", "Thirteen-digit shape occurs in resolved dependency metadata", "Reviewed - Not Participant"
    if normalized in {"lib/screens/main/contact_screen.dart", "docs/user_manual_v1_1_1_android/screenshots/31_contact_screen_ui.xml"} and pattern in {"email_address", "thai_phone_number"}:
        return "public_project_contact", "Published project contact surface, not a participant record", "Reviewed - Public Contact"
    if normalized == "assets/models/logistic_weights.json" and pattern == "thai_phone_number":
        return "model_numeric_coefficients", "Numeric coefficient serialization coincides with phone-number shape", "Reviewed - Not Participant"
    if normalized.endswith("Contents.json") and "/Assets.xcassets/" in normalized:
        return "asset_filename_token", "Asset filename metadata coincides with email-address syntax", "Reviewed - Not Participant"
    if normalized.endswith(".podspec") and pattern == "email_address":
        return "public_dependency_maintainer_contact", "Package maintainer metadata, not a participant record", "Reviewed - Public Metadata"
    if normalized.endswith("project.pbxproj") and pattern == "thai_national_id_shape":
        return "xcode_build_identifier", "Xcode object identifier coincides with thirteen-digit shape", "Reviewed - Not Participant"
    if "launch_logcat_tail.txt" in normalized and pattern == "thai_national_id_shape":
        return "generated_runtime_numeric_token", "Runtime log numeric token; participant linkage is not established", "Open - Pending Researcher"
    if normalized == "lib/app/app_state.dart" and pattern == "participant_value_assignment":
        return "application_default_or_migration_literal", "Source literal is not a collected record, but researcher review remains fail-closed", "Open - Pending Researcher"
    return "unresolved_identifier_candidate", "Pattern shape alone cannot establish participant status; reviewer action retained", "Open - Pending Researcher"


def google_disposition(domain: str, logical_path: str):
    normalized = logical_path.split("::", 1)[-1]
    official = {"lib/firebase_options.dart", "ios/Runner/GoogleService-Info.plist", "android/app/google-services.json"}
    if domain == "source" and normalized in official:
        return "official_firebase_client_configuration", "Firebase client configuration identifier; project ownership, restriction and rotation review remains pending", "Open - Pending Owner"
    return "unresolved_google_marker", "Google-shaped marker requires owner validation; no matched value retained", "Open - Pending Owner"


def main():
    src = source_root()
    scope = {domain: {"content_items_scanned": 0, "bytes_scanned": 0, "skipped_items": 0} for domain in ("source", "source_archives", "office", "manifests")}
    participant_rows = []
    google_rows = []
    high_confidence_counts = {domain: {name: 0 for name in SECRET_PATTERNS} for domain in scope}

    def consume(domain: str, logical_path: str, data: bytes):
        scope[domain]["content_items_scanned"] += 1
        scope[domain]["bytes_scanned"] += len(data)
        for pattern_name, pattern in SECRET_PATTERNS.items():
            occurrences = len(pattern.findall(data))
            high_confidence_counts[domain][pattern_name] += occurrences
            if pattern_name == "google_api_key_marker" and occurrences:
                category, disposition, status = google_disposition(domain, logical_path)
                google_rows.append({"domain": domain, "path": logical_path, "occurrences": occurrences, "category": category, "disposition": disposition, "status": status})
        for pattern_name, pattern in PARTICIPANT_PATTERNS.items():
            occurrences = len(pattern.findall(data))
            if occurrences:
                category, disposition, status = participant_disposition(domain, logical_path, pattern_name)
                participant_rows.append({"domain": domain, "path": logical_path, "pattern": pattern_name, "occurrences": occurrences, "category": category, "disposition": disposition, "status": status})

    excluded = {".git", "build", "Pods", ".dart_tool"}
    for path in src.rglob("*"):
        if not path.is_file() or any(part in excluded for part in path.parts) or path.stat().st_size > 2_000_000:
            if path.is_file():
                scope["source"]["skipped_items"] += 1
            continue
        try:
            consume("source", path.relative_to(src).as_posix(), path.read_bytes())
        except OSError:
            scope["source"]["skipped_items"] += 1

    for archive_path in sorted((ROOT / "archives").glob("*")):
        if archive_path.name.endswith((".tar.gz", ".tgz", ".tar")):
            with tarfile.open(archive_path) as archive:
                for member in archive.getmembers():
                    if member.isfile():
                        consume("source_archives", f"{archive_path.name}::{member.name}", archive.extractfile(member).read())
                    else:
                        scope["source_archives"]["skipped_items"] += 1

    office_containers = []
    for office in sorted(ART.iterdir()):
        if office.suffix.lower() not in {".docx", ".xlsx", ".pptx"}:
            continue
        before_items = scope["office"]["content_items_scanned"]
        before_bytes = scope["office"]["bytes_scanned"]
        with zipfile.ZipFile(office) as archive:
            for name in archive.namelist():
                if name.endswith((".xml", ".rels", ".txt", ".csv")):
                    consume("office", f"{office.name}::{name}", archive.read(name))
                else:
                    scope["office"]["skipped_items"] += 1
        office_containers.append({"container": office.name, "sha256": sha256(office), "content_items_scanned": scope["office"]["content_items_scanned"] - before_items, "bytes_scanned": scope["office"]["bytes_scanned"] - before_bytes})

    task7_manifests = []
    for manifest in sorted(MAN.glob("*.json")):
        if manifest == OUTPUT:
            scope["manifests"]["skipped_items"] += 1
            continue
        data = manifest.read_bytes()
        consume("manifests", manifest.relative_to(ROOT).as_posix(), data)
        if manifest.name.startswith("task7_"):
            task7_manifests.append({"path": manifest.name, "sha256": hashlib.sha256(data).hexdigest(), "bytes_scanned": len(data)})

    participant_rows.sort(key=lambda row: (row["domain"], row["path"], row["pattern"]))
    google_rows.sort(key=lambda row: (row["domain"], row["path"]))
    report = {
        "schema_version": 1,
        "method": "final_content_read_only_regex_and_disposition",
        "version": VERSION,
        "source_commit": COMMIT,
        "self_exclusion": "Only manifests/task7_final_content_inspection.json is excluded; it cannot hash itself. No scanned artifact or manifest cites this output hash.",
        "scan_scope_counts": scope,
        "high_confidence_secret_marker_counts": high_confidence_counts,
        "google_api_key_marker_dispositions": google_rows,
        "participant_candidate_dispositions": participant_rows,
        "participant_candidate_total": sum(row["occurrences"] for row in participant_rows),
        "participant_candidates_pending_review": sum(row["occurrences"] for row in participant_rows if row["status"].startswith("Open - Pending")),
        "scanned_office_containers": office_containers,
        "scanned_task7_manifests": task7_manifests,
        "value_retention": "Matched values are never copied to this manifest; only domain, exact path/member, pattern, count, disposition and status are retained.",
        "conclusion_boundary": "This final-content inspection is a deterministic triage record, not proof of secret absence, participant-data absence, compliance, or vulnerability clearance.",
    }
    OUTPUT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"output": str(OUTPUT), "office_containers": len(office_containers), "task7_manifests": len(task7_manifests), "participant_candidates": report["participant_candidate_total"], "participant_pending": report["participant_candidates_pending_review"], "google_markers": sum(row["occurrences"] for row in google_rows)}, sort_keys=True))


if __name__ == "__main__":
    main()
