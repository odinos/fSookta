#!/usr/bin/env python3
"""Build Task 7 narrative artifacts and disclosed offline security evidence."""
import hashlib
import json
import os
import re
import shutil
import tarfile
import zipfile
from pathlib import Path, PurePosixPath

from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

ROOT = Path(os.environ.get("FSOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
ART = ROOT / "artifacts"
MAN = ROOT / "manifests"
COMMIT = "bf8867a2083357cb9d60915bf6c2233801f923d8"
VERSION = "1.3.11+28"
INK = RGBColor(0, 0, 0)
MUTED = RGBColor(85, 85, 85)
TREE = "b4ed5fd0c061492c74dba356ed8a114b5f6621ba"
TASK7_EDITABLE = {
    "09_Security_Privacy_and_Data_Protection_Report.docx",
    "09_Security_and_Access_Control_Matrices.xlsx",
    "10_End_User_Manual.docx",
    "10_Research_Admin_Manual.docx",
    "10_Developer_Handover_Manual.docx",
    "10_Knowledge_Transfer_Deck.pptx",
    "10_Knowledge_Transfer_Minutes.docx",
    "11_Research_Publication_Package.docx",
    "11_Publication_Tables.xlsx",
}


def git_object(kind, body):
    return hashlib.sha1(f"{kind} {len(body)}\0".encode() + body).digest()


def authoritative_tar_identity(path):
    root = {}
    file_count = 0
    with tarfile.open(path) as archive:
        commit = archive.pax_headers.get("comment")
        for member in archive.getmembers():
            if member.isdir():
                continue
            if member.isfile():
                data = archive.extractfile(member).read()
                mode = "100755" if member.mode & 0o111 else "100644"
            elif member.issym():
                data = member.linkname.encode()
                mode = "120000"
            else:
                continue
            current = root
            parts = PurePosixPath(member.name).parts
            for part in parts[:-1]:
                current = current.setdefault(part, {})
            current[parts[-1]] = (mode, git_object("blob", data))
            file_count += 1

    def tree_id(node):
        entries = []
        ordered = sorted(node.items(), key=lambda item: (item[0] + ("/" if isinstance(item[1], dict) else "")).encode())
        for name, value in ordered:
            if isinstance(value, dict):
                mode, digest = "40000", tree_id(value)
            else:
                mode, digest = value
            entries.append(f"{mode} {name}".encode() + b"\0" + digest)
        return git_object("tree", b"".join(entries))

    return {"commit": commit, "git_tree_id": tree_id(root).hex(), "file_count": file_count}


def materialization_matches_tar(source, archive_path):
    with tarfile.open(archive_path) as archive:
        for member in archive.getmembers():
            target = source / member.name
            if member.isfile():
                if not target.is_file() or sha256(target) != hashlib.sha256(archive.extractfile(member).read()).hexdigest():
                    return False
            elif member.issym():
                if not target.is_symlink() or os.readlink(target) != member.linkname:
                    return False
    return True


def discover_source():
    override = os.environ.get("SOOKTA_AUTHORITATIVE_SOURCE")
    candidates = [Path(override)] if override else sorted((ROOT / "authoritative-materializations").glob("source-*/source"))
    valid = []
    for candidate in candidates:
        pubspec = candidate / "pubspec.yaml"
        source_tar = candidate.parent / "authoritative-source.tar"
        if not (pubspec.is_file() and source_tar.is_file() and f"version: {VERSION}" in pubspec.read_text(errors="ignore") and (candidate / "lib/app/app_state.dart").is_file()):
            continue
        identity = authoritative_tar_identity(source_tar)
        if identity == {"commit": COMMIT, "git_tree_id": TREE, "file_count": 602} and materialization_matches_tar(candidate, source_tar):
            valid.append(candidate)
    if not valid:
        raise FileNotFoundError("No authoritative source materialization matches the governed version")
    fingerprints = {sha256(path.parent / "authoritative-source.tar") for path in valid}
    if len(fingerprints) != 1:
        raise RuntimeError("Authoritative source candidates disagree")
    return valid[0]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


SRC = discover_source()


def prepare_source_identity():
    alias_relatives = [
        "pubspec.yaml",
        "lib/app/sookta_app.dart",
        "lib/app/app_state.dart",
        "lib/core/services/assessment_export_service.dart",
        "lib/core/services/firebase_telemetry_service.dart",
        "lib/core/services/local_image_store.dart",
        "lib/screens/main/profile_tab.dart",
        "lib/screens/main/history_tab.dart",
        "lib/screens/main/training_data_export_screen.dart",
    ]
    alias_root = ROOT / "evidence/task7-source"
    aliases = []
    for relative in alias_relatives:
        source = SRC / relative
        target = alias_root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        aliases.append({"source_relative_path": relative, "alias_path": target.relative_to(ROOT).as_posix(), "sha256": sha256(target)})
    source_tar = SRC.parent / "authoritative-source.tar"
    stable_record = ROOT / "manifests/source_snapshot_manifest.json"
    identity = {
        "schema_version": 1,
        "commit": COMMIT,
        "git_tree_id": TREE,
        "verification_method": "Git blob/tree object IDs recomputed from authoritative git-archive tar; every tracked tar member compared with the selected materialization",
        "authoritative_tar_sha256": sha256(source_tar),
        "authoritative_tar_file_count": 602,
        "stable_identity_record": stable_record.relative_to(ROOT).as_posix(),
        "stable_identity_record_sha256": sha256(stable_record),
        "stable_aliases": aliases,
    }
    MAN.mkdir(parents=True, exist_ok=True)
    (MAN / "task7_source_identity.json").write_text(json.dumps(identity, ensure_ascii=False, indent=2))
    return identity


SOURCE_IDENTITY = prepare_source_identity()


def inspect_security():
    evidence = []
    for rel, purpose in [
        ("lib/core/services/firebase_telemetry_service.dart", "default-off telemetry and event boundary"),
        ("lib/core/services/local_image_store.dart", "local image persistence"),
        ("lib/core/services/assessment_export_service.dart", "CSV export and share boundary"),
        ("lib/app/app_state.dart", "SharedPreferences persistence and deletion behavior"),
        ("android/app/src/main/AndroidManifest.xml", "Android permissions"),
        ("ios/Runner/Info.plist", "iOS usage descriptions"),
        ("pubspec.lock", "resolved dependency evidence"),
    ]:
        p = SRC / rel
        evidence.append({"path": rel, "purpose": purpose, "sha256": sha256(p) if p.exists() else None, "exists": p.exists()})
    config_categories = []
    for rel in ["android/app/google-services.json", "ios/Runner/GoogleService-Info.plist"]:
        p = SRC / rel
        if p.exists():
            config_categories.append({"path": rel, "category": "Firebase client configuration", "owner": "Pending Owner", "value_disclosed": False})
    candidate_patterns = {
        "private_key_marker": re.compile(rb"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY"),
        "aws_access_key_marker": re.compile(rb"AKIA[0-9A-Z]{16}"),
        "github_token_marker": re.compile(rb"(?:ghp|github_pat)_[0-9A-Za-z_]{20,}"),
        "google_api_key_marker": re.compile(rb"AIza[0-9A-Za-z_-]{30,}"),
        "generic_secret_assignment": re.compile(rb"(?i)(client_secret|password|private_key)\s*[:=]"),
    }
    participant_patterns = {
        "email_address": re.compile(rb"(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"),
        "thai_phone_number": re.compile(rb"(?<!\d)(?:\+66|0)[689]\d{8}(?!\d)"),
        "thai_national_id_shape": re.compile(rb"(?<!\d)\d{13}(?!\d)"),
        "participant_value_assignment": re.compile(rb"(?i)(?:participant|farmer|profile)[_-]?(?:id|name)\s*[:=]\s*[\"'][^\"']{2,}[\"']"),
    }
    counts = {k: 0 for k in candidate_patterns}
    domain_counts = {domain: {k: 0 for k in candidate_patterns} for domain in ("source", "source_archives", "office", "manifests")}
    participant_counts = {domain: {k: 0 for k in participant_patterns} for domain in domain_counts}
    scope = {domain: {"content_items_scanned": 0, "bytes_scanned": 0, "skipped_items": 0} for domain in domain_counts}
    assignment_paths = {}
    def scan_blob(domain, logical_path, data):
        scope[domain]["content_items_scanned"] += 1
        scope[domain]["bytes_scanned"] += len(data)
        for key, pattern in candidate_patterns.items():
            hits = len(pattern.findall(data))
            domain_counts[domain][key] += hits
            if domain == "source":
                counts[key] += hits
                if key == "generic_secret_assignment" and hits:
                    assignment_paths[logical_path] = hits
        for key, pattern in participant_patterns.items():
            participant_counts[domain][key] += len(pattern.findall(data))

    excluded = {".git", "build", "Pods", ".dart_tool"}
    for p in SRC.rglob("*"):
        if not p.is_file() or any(x in excluded for x in p.parts) or p.stat().st_size > 2_000_000:
            if p.is_file():
                scope["source"]["skipped_items"] += 1
            continue
        try:
            data = p.read_bytes()
        except OSError:
            scope["source"]["skipped_items"] += 1
            continue
        scan_blob("source", p.relative_to(SRC).as_posix(), data)

    for archive in sorted((ROOT / "archives").glob("*")):
        if archive.name.endswith((".tar.gz", ".tgz", ".tar")):
            with tarfile.open(archive) as tf:
                for member in tf.getmembers():
                    if member.isfile():
                        scan_blob("source_archives", f"{archive.name}::{member.name}", tf.extractfile(member).read())
                    else:
                        scope["source_archives"]["skipped_items"] += 1

    for manifest in sorted(MAN.glob("*.json")):
        if manifest.name.startswith("task7_"):
            continue
        scan_blob("manifests", manifest.relative_to(ROOT).as_posix(), manifest.read_bytes())

    for office in sorted(ART.glob("*")):
        if office.suffix.lower() not in {".docx", ".xlsx", ".pptx"}:
            continue
        if office.name in TASK7_EDITABLE:
            scope["office"]["skipped_items"] += 1
            continue
        with zipfile.ZipFile(office) as zf:
            for name in zf.namelist():
                if name.endswith((".xml", ".rels", ".txt", ".csv")):
                    scan_blob("office", f"{office.name}::{name}", zf.read(name))
                else:
                    scope["office"]["skipped_items"] += 1

    triage_files = []
    for relative, occurrences in sorted(assignment_paths.items()):
        if relative.startswith("docs/user_manual_v1_1_1_android/screenshots/") and relative.endswith("_ui.xml"):
            category = "android_ui_boolean_attribute"
            disposition = "False positive: Android UIAutomator password=false boolean attributes; no credential value"
            owner_review = False
        elif relative == "android/key.properties.example":
            category = "credential_placeholder_example"
            disposition = "Placeholder change-me values only; real signing values remain excluded and owner replacement/transfer review is pending"
            owner_review = True
        else:
            category = "unclassified_generic_assignment"
            disposition = "Pending Owner classification"
            owner_review = True
        triage_files.append({"path": relative, "occurrences": occurrences, "category": category, "disposition": disposition, "owner_review_required": owner_review})
    pending_occurrences = sum(row["occurrences"] for row in triage_files if row["owner_review_required"])
    findings = [
        {"id": "SEC-OBS-001", "severity": "High", "status": "Open - Pending Owner", "observation": "Release signing, store ownership, Firebase project ownership, credential transfer, rotation and revocation evidence were not supplied.", "evidence": "Task 3 access checklist; source configuration categories only", "limitation": "No credential values were inspected or recorded."},
        {"id": "SEC-OBS-002", "severity": "Medium", "status": "Open - Pending Owner/Researcher", "observation": "Telemetry is compile-time opt-in and default-off; no final owner approval, Firebase-console retention configuration, or research consent alignment is evidenced.", "evidence": "lib/core/services/firebase_telemetry_service.dart:18-39", "limitation": "No live Firebase project or runtime delivery was assessed."},
        {"id": "SEC-OBS-003", "severity": "Medium", "status": "Open - Pending Owner", "observation": "App data and copied media are local; the application adds no field-level encryption, secure-delete proof, approved retention schedule, or automated backup/restore workflow.", "evidence": "lib/app/app_state.dart; lib/core/services/local_image_store.dart", "limitation": "Platform sandbox and device encryption depend on OS/device policy and are not guaranteed here."},
        {"id": "SEC-OBS-004", "severity": "Medium", "status": "Open - Pending Researcher", "observation": "CSV export/share intentionally crosses the app sandbox and may contain coded profile, demographic, assessment, and research fields.", "evidence": "lib/core/services/assessment_export_service.dart; lib/screens/main/history_tab.dart", "limitation": "The approved destination, recipient controls, and deletion after transfer are researcher policy."},
        {"id": "SEC-OBS-005", "severity": "Low", "status": "N/A with Rationale", "observation": "Remote assessment database/server/API authentication and authorization controls are not implemented in the final source baseline.", "evidence": "Source architecture and API applicability statement", "limitation": "Firebase optional telemetry is not an assessment database or application login."},
    ]
    result = {
        "method": "offline_source_backed_fallback",
        "sealed_codex_security_report": False,
        "reason": "Desktop Codex Security Standard start call was terminated without authoritative scan context; no scan ID is asserted.",
        "source_commit": COMMIT,
        "version": VERSION,
        "scope": "Static read-only review of authoritative source/configuration and prior handover evidence; no live service, penetration, dynamic, dependency-advisory, or production-control assessment.",
        "files_scanned": scope["source"]["content_items_scanned"],
        "candidate_marker_counts": counts,
        "candidate_marker_counts_by_domain": domain_counts,
        "participant_identifier_counts": participant_counts,
        "participant_identifier_interpretation": "Identifier-shaped matches are review candidates only; the scan cannot determine participant status. No matched value is retained. Researcher review remains open.",
        "candidate_marker_interpretation": "Counts are triage signals only, not proof of exposure or absence. No matched values are stored.",
        "generic_secret_assignment_triage": {"matched_occurrences": counts["generic_secret_assignment"], "files_with_matches": len(assignment_paths), "files": triage_files, "pending_owner_review_occurrences": pending_occurrences, "untriaged": pending_occurrences, "status": "Open - Pending Owner"},
        "scan_scope_counts": scope,
        "scan_algorithm": {"source": "Read eligible files <=2 MB outside .git/build/Pods/.dart_tool and apply byte regexes", "source_archives": "Read every regular member from archives/*.tar[.gz]", "office": "Read XML, relationships, text and CSV members from non-Task7 Office artifacts; current Task7 editable artifacts are explicitly excluded to avoid self-referential evidence", "manifests": "Read every non-Task7 manifests/*.json; task7_*.json outputs are explicitly excluded to avoid self-referential evidence"},
        "source_identity_manifest": "manifests/task7_source_identity.json",
        "credential_categories": config_categories,
        "evidence": evidence,
        "findings": findings,
        "conclusion_boundary": "This fallback does not certify compliance, vulnerability absence, secure deletion, encryption, incident readiness, or production security.",
    }
    MAN.mkdir(parents=True, exist_ok=True)
    (MAN / "task7_offline_security_inspection.json").write_text(json.dumps(result, ensure_ascii=False, indent=2))
    return result


def setup(title, subtitle, status="Controlled Draft"):
    d = Document()
    d.core_properties.author = "SookTa Project"
    d.core_properties.last_modified_by = "SookTa Project"
    d.core_properties.title = title
    d.core_properties.subject = "Final handover documentation"
    s = d.sections[0]
    s.page_width, s.page_height = Inches(8.5), Inches(11)
    s.top_margin = s.bottom_margin = s.left_margin = s.right_margin = Inches(1)
    s.header_distance = s.footer_distance = Inches(.492)
    normal = d.styles["Normal"]
    normal.font.name = "Arial"; normal.font.size = Pt(11); normal.font.color.rgb = INK
    normal.paragraph_format.space_after = Pt(8); normal.paragraph_format.line_spacing = 1.15
    for name, size, before, after, color in [("Heading 1",20,20,6,INK),("Heading 2",16,18,6,INK),("Heading 3",14,16,4,MUTED)]:
        st = d.styles[name]; st.font.name="Arial"; st.font.size=Pt(size); st.font.bold=False; st.font.color.rgb=color
        st.paragraph_format.space_before=Pt(before); st.paragraph_format.space_after=Pt(after)
    p=d.add_paragraph(); p.paragraph_format.space_after=Pt(3); r=p.add_run(title); r.font.name="Arial"; r.font.size=Pt(26); r.font.color.rgb=INK
    p=d.add_paragraph(); r=p.add_run(subtitle); r.font.name="Arial"; r.font.size=Pt(12); r.font.color.rgb=MUTED
    table(d,["Control","Value"],[["Status",status],["Baseline",VERSION],["Authoritative commit",COMMIT],["Evidence hierarchy","Final source → reproduced evidence → versioned historical evidence → human confirmation"]],[1.65,4.85],8.5)
    return d


def shade(cell, fill):
    pr=cell._tc.get_or_add_tcPr(); shd=OxmlElement("w:shd"); shd.set(qn("w:fill"),fill); pr.append(shd)


def table(d, headers, rows, widths=None, size=8):
    t=d.add_table(rows=1, cols=len(headers)); t.style="Table Grid"; t.alignment=WD_TABLE_ALIGNMENT.LEFT; t.autofit=False
    for i,h in enumerate(headers):
        c=t.rows[0].cells[i]; c.text=str(h); shade(c,"F2F4F7"); c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
        for r in c.paragraphs[0].runs: r.font.name="Arial"; r.font.size=Pt(size); r.bold=True
    for row in rows:
        cells=t.add_row().cells
        for i,v in enumerate(row):
            cells[i].text="" if v is None else str(v); cells[i].vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.TOP
            for r in cells[i].paragraphs[0].runs: r.font.name="Arial"; r.font.size=Pt(size)
    if widths:
        for row in t.rows:
            for c,w in zip(row.cells,widths): c.width=Inches(w)
    return t


def para(d, text, bold=False):
    p=d.add_paragraph(); r=p.add_run(text); r.bold=bold; r.font.name="Arial"; r.font.size=Pt(11); return p


def bullets(d, items):
    for item in items:
        p=d.add_paragraph(style="List Bullet"); p.add_run(item)


def steps(d, items):
    for item in items:
        p=d.add_paragraph(style="List Number"); p.add_run(item)


def save(d, name):
    ART.mkdir(parents=True, exist_ok=True)
    d.save(ART/name)


def security_report(scan):
    d=setup("Security, Privacy and Data Protection Report","Source-backed control assessment and human-action register | Offline inspection fallback")
    d.add_heading("Assessment statement",1); para(d,scan["reason"]); para(d,scan["scope"]); para(d,scan["conclusion_boundary"],True)
    d.add_heading("Data inventory and flows",1)
    table(d,["Asset / flow","Current implementation","Classification / boundary","Evidence"],[
        ["Profile and farmer records","JSON in SharedPreferences; coded identifier is supported","Sensitive participant/profile data; local device","lib/app/app_state.dart"],
        ["Assessment history and drafts","JSON in SharedPreferences, including linked local media paths","Sensitive research/assessment data; local device","lib/app/app_state.dart"],
        ["Images/video frames","Copied/read from application documents directory for local processing","Potentially identifying media; linkage persists by path","lib/core/services/local_image_store.dart"],
        ["CSV exports","Written in application documents then shared through OS share sheet","Disclosure boundary: recipient/destination becomes external policy","lib/core/services/assessment_export_service.dart"],
        ["Firebase Analytics/Crashlytics","Optional build-time opt-in; disabled by default","Remote third party only when enabled and configured","lib/core/services/firebase_telemetry_service.dart"],
        ["Bundled ONNX models","Local inference; no model-upload path evidenced","Local executable asset","pubspec.yaml; Task 5 model hashes"],
    ],[1.1,2.1,1.7,1.6],7.2)
    d.add_heading("Permissions and third parties",1)
    bullets(d,["Android declares INTERNET and CAMERA; camera hardware is not required.","iOS declares camera, microphone, photo-library read and photo-library add usage descriptions. Microphone is described only for system video recording; audio is not used for ergonomic assessment.","Firebase Analytics and Crashlytics dependencies exist, but collection is explicitly default-off unless SOOKTA_TELEMETRY_ENABLED=true and Firebase is initialized.","OS share sheet, image picker, camera, TTS engine, path provider, SharedPreferences, and ONNX Runtime form platform/third-party boundaries; ownership and license evidence remain in the access/license registers."])
    d.add_heading("Access control and encryption applicability",1)
    para(d,"The app has no login, role-based access-control layer, remote assessment database, or custom assessment server/API. These controls are N/A with Rationale for the current local-only assessment architecture. Physical device access, OS application sandboxing, device encryption, screen lock, backups and share recipients remain platform/owner controls. No encryption guarantee, secure-delete proof or compliance certification is asserted.")
    d.add_heading("Retention, deletion, backup and incident boundary",1)
    table(d,["Control","Current evidence","Status / owner action"],[
        ["Retention schedule","No approved schedule encoded","Pending Researcher and Owner approval"],
        ["Reference operations","Profile/draft/history reference operations are source-evidenced; farmer removal leaves history; secure erasure is not demonstrated","Pending Owner/Researcher validation and policy"],
        ["Media/history deletion","No File.delete path is implemented; farmer removal leaves existing history; secure erase and deletion of media/history files are unproven","Pending Owner/Researcher workflow and evidence"],
        ["Backup/restore","No governed automated backup/restore workflow evidenced","Pending Owner procedure and validation"],
        ["Incident response","No approved contact tree, SLA, rehearsal or live monitoring evidence supplied","Pending Owner"],
        ["Unauthorized copies","Non-retention/non-access statement is a signature draft only","Pending Authorized Signature"],
    ],[1.35,3.0,2.15],8)
    d.add_page_break(); d.add_heading("Offline inspection observations",1)
    table(d,["ID","Severity","Observation","Status"],[[x["id"],x["severity"],x["observation"],x["status"]] for x in scan["findings"]],[.75,.7,4.1,.95],7.2)
    d.add_heading("Security tests and limitations",1)
    scopes=scan["scan_scope_counts"]
    bullets(d,[f"Read-only regex inspection consumed {scopes['source']['content_items_scanned']} source files, {scopes['source_archives']['content_items_scanned']} source-archive members, {scopes['office']['content_items_scanned']} prior-package Office XML/content members, and {scopes['manifests']['content_items_scanned']} manifests; byte counts and exclusions are in the inspection manifest.","A separate post-generation manifests/task7_final_content_inspection.json consumes every current Task7 DOCX/XLSX/PPTX and every non-self Task7 manifest. It is not cited by scanned outputs, so its hashes are acyclic.","The 978 source generic-assignment signals are deterministically triaged: 976 Android UI password=false attributes and two change-me signing placeholders. The two placeholders remain Open - Pending Owner; no matched value is copied into this report.","Identifier-shaped email/phone/national-ID/participant-field candidates are dispositioned per exact domain/path without retaining values. Pattern matches cannot establish participant status; unresolved candidates remain Open - Pending Researcher.","Reproduced Flutter analyze/test/build evidence is technical evidence, not penetration testing or dependency-vulnerability clearance.","No live Firebase console, network interception, dynamic device hardening, store signing, production IAM, backup restore, deletion forensics, or incident-response exercise was assessed.","Potential findings must be validated and closed by the named owner; this report does not establish absence of vulnerabilities."])
    d.add_heading("Draft non-retention / non-access statement",1)
    para(d,"I confirm that, after authorized handover and verification, I will not retain or access unauthorized copies of participant-identifying media, credentials, signing assets, research exports or production-console data, except where a separately approved written retention basis applies. This is a draft and is not effective until signed by authorized parties.")
    table(d,["Role","Name","Date","Signature","Status"],[["Developer / custodian","","","","Pending Signature"],["Owner / recipient","","","","Pending Signature"]],[1.35,1.5,1.0,1.55,1.1],8)
    d.add_heading("Evidence index",1); table(d,["Path","Purpose","SHA-256"],[[x["path"],x["purpose"],x["sha256"] or "Missing"] for x in scan["evidence"]],[2.3,2.3,1.9],7)
    save(d,"09_Security_Privacy_and_Data_Protection_Report.docx")


def end_user():
    d=setup("SookTa End-User Manual","Version 1.3.11+28 | Current source-driven procedures and privacy warnings")
    d.add_heading("Purpose and supported boundary",1); para(d,"SookTa supports ergonomic screening using REBA and ISO 11228 inputs with local pose/model assistance. Results are advisory and not a medical certificate, diagnosis, clinical validation or replacement for qualified professional judgement. Production-store signing and supported-device release approval remain owner-controlled.")
    d.add_heading("Install and start",1); steps(d,["Install only an owner-approved build for the intended Android or iOS device.","Open SookTa, choose Thai or English, and review the privacy/usage information.","Create or select a profile. Use a coded participant identifier; avoid unnecessary names or identifying notes.","Confirm camera/gallery permissions only when you intend to capture or select media."])
    d.add_heading("Manage farmers and privacy-safe profiles",1); bullets(d,["Use Profile > Manage Farmers (/farmers) to add, edit, select or remove a farmer from the picker. Farmer removal leaves existing history; it is not history/media deletion.","Keep the participant code separate from the re-identification key; the app does not provide a research identity vault.","Source: lib/screens/main/profile_tab.dart → FarmerManagerScreen.routeName; lib/screens/main/farmer_manager_screen.dart → deleteFarmer. No File.delete path or secure erase is implemented."])
    d.add_heading("Run an assessment",1); steps(d,["From Home, select the farmer/profile and choose the work activity and assessment method.","Complete required demographic and task inputs. Correct any missing or unsupported values shown by validation.","For image assessment, provide the required four-image flow. Capture with the camera or select from the gallery; keep only the intended participant in frame.","For video where the current screen offers it, capture/select a short posture video; the app evaluates sampled frames and does not use audio for ergonomic scoring.","If person-count, pose, file or quality checks fail, retake/select a clearer image with one visible person and retry. Do not interpret a failed inference as a low-risk result.","Review REBA/ISO results, risk level, body-area breakdown and recommendations before saving."])
    d.add_heading("Results, daily trend and history",1); bullets(d,["REBA and ISO 11228 outputs are deterministic reference-based assessments; model outputs are bounded technical aids described in the AI report.","Daily trend/prediction is advisory and depends on saved records; missing history can yield unavailable or limited output.","Use History filters to locate saved assessments. Verify profile, date, activity and app version before comparison.","TTS reads selected guidance through the device speech service. Confirm device volume, language voice availability and privacy in shared spaces."])
    d.add_heading("Export and share",1); steps(d,["History > per-record CSV uses exportHistoryRecordCsv from lib/screens/main/history_tab.dart or history_detail_screen.dart.","History > all-visible CSV uses exportAllHistoryCsv for the records currently visible after filtering.","Profile > Export Model Training Data opens /training-data-export and shares two CSV files: daily Logistic and XGBoost posture rows (lib/screens/main/profile_tab.dart; lib/screens/main/training_data_export_screen.dart).","Review recipient and destination in the OS share sheet; cancel if uncertain.","Store the shared file only in the researcher-approved destination and follow the approved retention/deletion policy."])
    d.add_heading("Offline behavior and recovery",1)
    table(d,["Symptom","Recovery","Escalate with"],[
        ["Camera/gallery denied","Open system settings, grant only required permission, return and retry","OS/device/build version and screenshot"],
        ["Pose/person-count failure","Use one person, full body, good light, less obstruction; retake","Non-identifying reproduction description and error code"],
        ["Cannot export/share","Check free storage and destination app; retry","Export type, timestamp, OS/build; never send participant data over unapproved channel"],
        ["No TTS sound","Check volume, speech engine and language voice","Device/OS/language"],
        ["Unexpected/missing local data","Stop use, preserve facts, notify owner/research lead","Coded record ID/time; no casual raw-data copies"],
    ],[1.45,3.0,2.05],7)
    d.add_heading("Limitations and support",1); bullets(d,["Core assessment/local inference can operate without a remote assessment service; optional Firebase telemetry is default-off and requires a governed build-time opt-in.","The app does not guarantee backup, secure deletion, encryption beyond platform controls, cross-device synchronization, or recovery after uninstall/device loss.","Escalation fields: owner contact — Pending Owner; technical maintainer — Pending Owner; privacy/research incident contact — Pending Researcher/Owner."])
    save(d,"10_End_User_Manual.docx")


def research_admin():
    d=setup("SookTa Research Administrator Manual","Coded-participant lifecycle, export reconciliation and policy boundaries")
    d.add_heading("Research boundary",1); para(d,"This manual supplies technical procedures, not consent language, ethics approval, research interpretation, recruitment policy or an approved transfer destination. Those items remain Pending Researcher.")
    d.add_heading("Before data collection",1); steps(d,["Confirm approved protocol, ethics/consent materials, device roster, build version, retention schedule, incident contact and transfer destination.","Assign a coded identifier outside SookTa and store any re-identification key separately under researcher policy.","Record study ID, session ID, device/OS/build, assessor, activity, date/time zone and evidence version in the study log.","Verify telemetry policy. Final source defaults it off; do not enable it without owner/research approval and Firebase ownership/configuration evidence."])
    d.add_heading("Local record lifecycle",1); bullets(d,["Profiles, history and drafts are serialized locally; linked image paths may point to copied application-document media.","Profile > Manage Farmers (/farmers) removes a profile reference from the picker, but farmer removal leaves existing history.","No File.delete path, media/history file deletion, or secure erase is proven; these remain Pending Owner/Researcher.","Validate selected participant, activity, assessment date, four-image/video provenance and app version before saving.","For duplicate records, retain both until a researcher documents which is canonical; do not silently overwrite evidence."])
    d.add_heading("CSV export and reconciliation",1); steps(d,["History > per-record CSV calls exportHistoryRecordCsv; History > all-visible CSV calls exportAllHistoryCsv for the current filtered list (lib/screens/main/history_tab.dart; lib/screens/main/history_detail_screen.dart).","Profile > Export Model Training Data (/training-data-export) shares two CSV files, daily Logistic and XGBoost posture data (lib/screens/main/profile_tab.dart; lib/screens/main/training_data_export_screen.dart).","Verify UTF-8/BOM-compatible opening, headers, coded participant ID, assessment identifiers, dates, methods, scores, units, version and missing-value representation against the data dictionary.","Hash the exported file, record its filename/size/timestamp/device/build and reconcile row counts with the in-app scope.","Transfer only to the researcher-approved secure destination; this destination is currently Pending Researcher policy."])
    d.add_heading("Researcher review gates",1)
    table(d,["Output","Required review","Current boundary"],[
        ["REBA / ISO","Check input completeness, reference mapping, units, activity applicability and discrepancies","Technical result; no clinical validity claim"],
        ["MoveNet / MultiPose","Check image quality, person-count eligibility, keypoint confidence and failed inference","Local model assistance; not external validation"],
        ["XGBoost advisory","Check source/training provenance, parameter record, dataset and raw metrics","Dataset and raw metrics Pending Researcher/Owner"],
        ["Daily advisory","Check minimum history and feature construction","Advisory; no injury prediction validity claim"],
        ["Historical UAT","Keep actual version/device/date labels","Cannot substitute for final-version participant evidence"],
    ],[1.4,3.1,2.0],8)
    d.add_heading("Backup, restore and incident handling",1); bullets(d,["No governed automated backup/restore flow is evidenced. Document any manual copy and perform a test restore before relying on it.","If a device is lost, data is shared incorrectly, participant linkage is exposed, or an export is corrupted: stop transfer, preserve facts, notify the approved incident contact, record timestamp/scope and follow the approved protocol.","Never include secrets or unnecessary identifiers in support tickets. Provide coded IDs, hashes and non-identifying reproduction details."])
    d.add_heading("Session close checklist",1); bullets(d,["□ Consent/ethics reference recorded (Pending Researcher)","□ Coded ID and session metadata reconciled","□ Row count and file hash recorded","□ Transfer receipt confirmed","□ Retention/deletion action recorded","□ Exceptions reviewed by researcher","□ Incident/escalation status recorded"])
    save(d,"10_Research_Admin_Manual.docx")


def developer_manual():
    d=setup("SookTa Developer Handover Manual","Repository, build, data, model, release and maintenance controls")
    d.add_heading("Repository authority and baseline",1); para(d,f"The authoritative deliverable is the full-history repository at commit {COMMIT}, version {VERSION}. The clean one-commit source archive is supplementary and must not replace the full-history repository, branches, tags or audit trail.")
    d.add_heading("Project map",1)
    table(d,["Area","Paths / responsibility"],[
        ["Application/navigation","lib/main.dart; lib/app/; lib/screens/; lib/widgets/"],
        ["Domain and persistence","lib/models/; lib/app/app_state.dart; lib/core/services/"],
        ["Algorithms/models","lib/core/services/*pose*; ergo/reba/iso services; assets/models/"],
        ["Platforms","android/; ios/; macos/; web/; windows/; linux/"],
        ["Tests","test/ and integration_test/"],
        ["Release evidence","Task 2 raw logs and verification_environment.json"],
    ],[2.0,4.5],8)
    d.add_heading("Governed environment",1)
    table(d,["Component","Exact reproduced value","Evidence"],[
        ["Flutter","Flutter 3.41.9 stable","evidence/verification_environment.json"],
        ["Dart","Dart 3.11.5","evidence/verification_environment.json"],
        ["Xcode","Xcode 26.6; build 17F113","evidence/verification_environment.json"],
        ["Host","macOS 26.6.2 arm64","evidence/verification_environment.json"],
    ],[1.2,2.7,2.6],8)
    d.add_heading("Environment and dependency setup",1); steps(d,["Checkout the full-history repository and verify git rev-parse HEAD against the intended commit.","Use the exact governed toolchain above; record any deviation before accepting new evidence.","Run flutter pub get without changing pubspec.lock; review any solver deviation before continuing.","Keep Firebase client configuration, signing files, provisioning profiles, upload keystore and credentials outside documentation and insecure channels."])
    d.add_heading("Build and test commands",1)
    table(d,["Purpose","Command","Boundary"],[
        ["Dependencies","flutter pub get","Do not update locks unintentionally"],
        ["Static analysis","flutter analyze","Technical evidence only"],
        ["Automated tests","flutter test","135 tests reproduced in Task 2; host/widget/unit coverage does not prove physical-device UAT"],
        ["Android release attempt","flutter build appbundle --release","Production upload signing remains unverified"],
        ["iOS release attempt","flutter build ipa --release","App Store distribution signing remains unverified"],
        ["Optional local telemetry","flutter run --dart-define=SOOKTA_TELEMETRY_ENABLED=true","Only after owner/research approval and Firebase configuration validation"],
    ],[1.2,2.4,2.9],8)
    d.add_heading("Persistence, export and migration controls",1); bullets(d,["SharedPreferences stores JSON containers for profile/farmers/history/drafts; local media is copied to application documents and referenced by path.","CSV services write to application documents before OS share. Validate schema against 05_Data_Dictionary_and_Export_Schema.xlsx after changes.","For schema changes: add backward-compatible fromJson defaults, migration tests, round-trip tests, export contract tests and a rollback plan. Never silently reinterpret old values."])
    d.add_heading("Bundled model/configuration inventory",1)
    table(d,["Exact path","SHA-256"],[
        ["assets/models/xgboost_model.onnx","dbedb2ab5ce57f3af0cd620e956f30ef34a64beaea493385afd3d27994002efc"],
        ["assets/models/xgboost_model_metadata.json","89db0df19fc6a4041a62fcd01e1155a288a19f243ed6908df5fdb03d9cbcb922"],
        ["assets/models/joint_feature_schema.json","bb7d0afb035d7ff11f1b573118563f3c3fa8cd667fda9446b1f8474b6769f963"],
        ["assets/models/logistic_weights.json","f90d054ec65d4b3e5c26e3ed9abd838a56a90ae78092d3a6ea8e04c780f80f8e"],
        ["assets/models/model_artifact_manifest.json","ef13040ca7baad38a8d0b88daf0162b451efb2b3d41501c41310888fad06fe4e"],
    ],[2.6,3.9],7)
    d.add_heading("Models and algorithm updates",1); steps(d,["Verify every exact path/hash above and pubspec.yaml asset mapping before build.","For replacement, retain source/training provenance, input/output tensor contract, preprocessing, thresholds, evaluation dataset, raw metrics and license evidence.","Run deterministic REBA/ISO/reference tests plus model-inference, person-count and failure-path tests.","Obtain researcher review before changing labels, interpretation, recommendation triggers or publication claims.","Preserve the prior known-good asset and code commit for rollback."])
    d.add_heading("Release, signing and ownership",1); bullets(d,["Technical builds are not production-store releases. Apple distribution certificates/profiles, Android upload keystore, store roles and signing attestations remain Pending Owner.","Firebase Analytics/Crashlytics are optional and default-off. Confirm project/package/bundle mapping and remote retention before opt-in.","Use semantic app version plus build number; tag only after full-history owner access, reproducible build evidence, physical-device gates, UAT decisions and release approval."])
    d.add_heading("Security and maintenance warnings",1); bullets(d,["Never commit or paste secrets, signing assets, participant media or real research exports.","Do not log participant identifiers or raw free text to telemetry. Review every new event parameter.","Dependencies require periodic owner-approved license/advisory review; this package is not a vulnerability-clearance certificate.","Rollback means restoring the governed Git commit/assets/configuration and rebuilding; user-local data compatibility must be tested before downgrade."])
    d.add_heading("Known gaps / handover actions",1); bullets(d,["GitHub Owner/Admin transfer — Pending Owner","Firebase/Apple/App Store Connect/Google Play ownership — Pending Owner","Production signing and release evidence — Pending Owner","Physical-device/UAT/performance evidence — Pending Owner/Researcher","Final security/privacy/retention/incident policies — Pending Owner/Researcher","Authorized acceptance and signatures — Pending Signature"])
    save(d,"10_Developer_Handover_Manual.docx")


def minutes():
    d=setup("SookTa Knowledge Transfer Minutes","Draft — Pending Meeting | Ready-to-use controlled record", "Draft — Pending Meeting")
    d.add_heading("Meeting control",1); table(d,["Field","Value"],[["Meeting date/time","Pending"],["Location / platform","Pending"],["Facilitator","Pending"],["Recorder","Pending"],["Recording link","Pending; create only with consent and approved storage"],["Meeting status","Draft — Pending Meeting"]],[2.0,4.5],9)
    d.add_heading("Attendees",1); table(d,["Attendee","Role","Organization","Attendance","Acknowledgement"],[["Pending Attendee","Owner / client","","Pending","Pending"],["Pending Attendee","Research lead","","Pending","Pending"],["Pending Attendee","Developer / maintainer","","Pending","Pending"]],[1.5,1.5,1.3,1.0,1.2],8)
    d.add_heading("Agenda and materials",1); table(d,["Agenda item","Materials / demonstration","Result"],[["Baseline and repository","KT deck; source/repository reports","Pending Meeting"],["Architecture, workflows and local data","Technical report; diagrams; data manual","Pending Meeting"],["Algorithms/models","AI report and matrices","Pending Meeting"],["Build/test/UAT/release","Raw logs; test/UAT package","Pending Meeting"],["Security/privacy/operations","Security report and manuals","Pending Meeting"],["Ownership, gaps and acceptance","Access/sign-off registers","Pending Meeting"]],[1.8,3.1,1.6],8)
    d.add_heading("Questions and answers",1); table(d,["ID","Question","Answer / evidence","Status"],[["Q-01","","","Pending Meeting"],["Q-02","","","Pending Meeting"]],[.65,2.15,2.9,.8],8)
    d.add_heading("Decisions and risks",1); table(d,["ID","Decision / risk","Rationale / impact","Owner","Status"],[["D-01","No decision recorded","Do not populate before meeting","Pending","Pending Meeting"],["R-01","","","Pending","Pending Meeting"]],[.65,2.1,2.1,.85,.8],8)
    d.add_heading("Actions",1); table(d,["ID","Action","Owner","Due","Status","Closure evidence"],[["A-01","","Pending","Pending","Pending Meeting",""],["A-02","","Pending","Pending","Pending Meeting",""]],[.55,2.3,.8,.75,.95,1.15],8)
    d.add_page_break(); d.add_heading("Acknowledgement and signatures",1); para(d,"Attendance, demonstrations, decisions, training completion, recording availability, knowledge acceptance and handover acceptance are not asserted by this draft.")
    table(d,["Role","Name","Decision / acknowledgement","Date","Signature"],[["Owner / authorized representative","","Pending","","Pending Signature"],["Research representative","","Pending","","Pending Signature"],["Developer / facilitator","","Pending","","Pending Signature"]],[1.45,1.25,1.65,.85,1.3],8)
    save(d,"10_Knowledge_Transfer_Minutes.docx")


def publication():
    d=setup("SookTa Research and Publication Package","Editable technical inputs for Chapter 4, Chapter 5 and Paper 2 | Researcher review required")
    d.add_heading("Use boundary",1); para(d,"This package provides source-backed technical inputs. Do not infer sample size, participant demographics, consent/ethics status, statistical tests, effect sizes, model validity, SUS results, qualitative themes, field outcomes, research conclusions or publication acceptance. All such content is Pending Researcher.")
    d.add_heading("System and Methods input",1); bullets(d,[f"System: SookTa {VERSION}, authoritative source commit {COMMIT}.","Architecture: Flutter multi-platform client; local SharedPreferences/app-document persistence; local deterministic REBA/ISO processing and bundled ONNX inference; optional Firebase telemetry default-off.","Workflow: coded profile → activity/method inputs → image/video eligibility and pose processing → reference-based score/advisory → local history → CSV export/share.","Reproducibility: source commit/tree, locked dependencies, model file hashes, commands, raw analyze/test/build logs, deterministic algorithm/reference cases and data dictionary are indexed in folders 01-07."])
    d.add_heading("Chapter 4 results-table inputs",1)
    table(d,["Table candidate","Available technical fact","Status / researcher field"],[
        ["Build/test baseline","Flutter analyze PASS; 135 automated tests PASS; Android/iOS technical build evidence with signing boundary","Available; describe environment and limitations"],
        ["Algorithm/reference verification","55 algorithm/reference cases and 7 boundary cases in final Task 6 package","Available technical verification; researcher interpretation pending"],
        ["Model inventory","10 model/algorithm roles; bundled model paths/hashes; XGBoost dataset/raw metrics missing","Partially available; Pending Researcher/Owner"],
        ["UAT/SUS","Seven version-labeled historical records; no final participant/SUS evidence","Historical only; Pending Researcher"],
        ["Security/privacy","Offline source-backed fallback observations and human actions","Technical assessment only; no compliance conclusion"],
    ],[1.55,3.35,1.6],8)
    d.add_heading("Chapter 5 technical discussion prompts",1); bullets(d,["Feasibility: local/offline assessment reduces dependence on a remote assessment service but shifts protection, backup and transfer responsibilities to the device and research process.","Trade-offs: deterministic reference rules improve traceability; model assistance adds image-quality, provenance and validation limitations.","Maintainability: source/history, locked dependencies, schema/model hashes and traceability support change control; production ownership/signing and final device evidence remain human gates.","Scalability: current local storage/export does not provide multi-user synchronization, centralized access control or server-side governance.","Future work: governed datasets/metrics, external/field validation, approved privacy controls, device matrix, final UAT/SUS and reproducible production release."])
    d.add_heading("Paper 2 Methods / Results skeleton",1); table(d,["Section","Source-backed input","Mandatory researcher completion"],[["Methods — software","Version, commit, architecture, algorithm/model roles, preprocessing, storage/export","Study design, recruitment, consent/ethics, sample, protocol"],["Methods — verification","Commands, environments, exact test cases and hashes","Statistical analysis plan and validity framework"],["Results — technical","Build/test counts and bounded algorithm/reference results","Participant/field outcomes, SUS, statistics, discrepancies"],["Discussion","Technical trade-offs and limitations","Research interpretation, comparison, conclusions"],["Availability","Source/archive/evidence identifiers subject to owner approval","Repository/data access statement and ethics constraints"]],[1.25,2.65,2.6],8)
    d.add_heading("Exact publication evidence contract",1)
    publication_sources = [
        ("evidence/flutter_test_1.3.11+28.log", "3960528c5719557c8f497682bb975de88f5be1765df2f387595b466ee38cc2f2", f"{VERSION}; available technical evidence"),
        ("artifacts/07_Master_Test_and_Verification_Package.xlsx", sha256(ROOT/"artifacts/07_Master_Test_and_Verification_Package.xlsx"), f"{VERSION}; available technical evidence"),
        ("artifacts/08_UAT_Field_Test_and_Usability_Package.xlsx", sha256(ROOT/"artifacts/08_UAT_Field_Test_and_Usability_Package.xlsx"), "historical + pending; final participant evidence pending"),
        ("artifacts/04_AI_Algorithm_and_Model_Technical_Report.docx", sha256(ROOT/"artifacts/04_AI_Algorithm_and_Model_Technical_Report.docx"), f"{VERSION}; governed dataset/raw metrics pending"),
        ("evidence/task7-source/pubspec.yaml", sha256(ROOT/"evidence/task7-source/pubspec.yaml"), f"{VERSION}; stable source alias"),
        ("artifacts/diagrams/03_system_context.drawio", sha256(ROOT/"artifacts/diagrams/03_system_context.drawio"), f"{VERSION}; draft caption pending"),
        ("manifests/task7_offline_security_inspection.json", sha256(MAN/"task7_offline_security_inspection.json"), f"{VERSION}; controlled draft; not sealed scan"),
    ]
    table(d,["Exact source path","SHA-256","Version / status"],publication_sources,[2.7,2.7,1.1],6.7)
    d.add_heading("Figure and evidence candidates",1); bullets(d,["Use only the exact diagram/source paths and hashes listed in the publication workbook; globs and folder labels are not evidence.","Final algorithm/test/UAT tables use exact artifact paths and hashes.","Security/data-flow figures must retain optional telemetry and export disclosure boundaries.","Every publication figure/table row records exact source path, artifact SHA-256, version/status, caption status and researcher approval."])
    d.add_heading("Researcher review checklist",1); bullets(d,["□ Confirm study/version boundary","□ Supply ethics/consent statement and sample metadata","□ Supply final UAT/SUS/field evidence","□ Review REBA/ISO/model interpretation","□ Approve statistical methods/results","□ Confirm table/figure numbering and citations","□ Approve limitations and conclusions","□ Approve repository/data availability text","□ Record manuscript/publication status without inventing acceptance"])
    save(d,"11_Research_Publication_Package.docx")


def main():
    scan=inspect_security(); security_report(scan); end_user(); research_admin(); developer_manual(); minutes(); publication()
    print(json.dumps({"status":"built","docx":6,"security_findings":len(scan["findings"]),"files_scanned":scan["files_scanned"]}))


if __name__ == "__main__":
    main()
