# SookTa Final Handover Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, upload, and verify a source-grounded final SookTa handover package under Google Drive `Work/Sookta/Final`.

**Architecture:** Use an auditable local staging workspace to generate polished editable artifacts, raw verification evidence, diagrams, archives, and a machine-readable manifest. Import editable artifacts into native Google Workspace files, upload reference exports and evidence, then verify the Drive tree against a requirement-level compliance matrix and repair only failed checks.

**Tech Stack:** Git, Flutter, Dart tests, shell verification, bundled Documents/Spreadsheets/Presentations runtimes, Google Drive/Docs/Sheets/Slides connector tools, Draw.io XML, PDF/PNG renderers, SHA-256 manifests.

**Spec:** `docs/superpowers/specs/2026-08-23-final-handover-package-design.md`

## Global Constraints

- Final application baseline is `1.3.11+28` at commit `bf8867a2083357cb9d60915bf6c2233801f923d8`.
- Governing requirements file ID is `1OVOS13DQCNxK2PjAnmk3CYckcf2KCH0N`.
- Destination folder ID is `1iAADHY0UN4DVmBydPPvYJqYJsP10A5Hk`.
- Historical evidence retains its actual version and date.
- No clinical-validation or external-validity claim may be introduced.
- No secrets, private signing assets, participant-identifying raw media, or credentials may be uploaded.
- Every Section 4-18 requirement receives evidence, `N/A with Rationale`, or an explicit human-action status.
- Editable/reference format pairs are mandatory where required.
- The full-history repository is authoritative; the one-commit branch is a supplementary snapshot.
- Google Workspace writes must use the relevant Google Drive/Docs/Sheets/Slides skill route and live readback.

---

### Task 1: Establish Staging Workspace and Source Inventory

**Files:**
- Create: `/private/tmp/fsookta-final-handover/source_inventory.json`
- Create: `/private/tmp/fsookta-final-handover/drive_source_inventory.json`
- Create: `/private/tmp/fsookta-final-handover/requirements.json`
- Create: `/private/tmp/fsookta-final-handover/evidence_map.json`

**Interfaces:**
- Consumes: governing PDF, repository tree, Git history, existing Sookta Drive folders.
- Produces: normalized requirement and evidence records consumed by every later task.

- [ ] **Step 1: Create the bounded staging tree**

Run:

```bash
mkdir -p /private/tmp/fsookta-final-handover/{artifacts,evidence,renders,archives,manifests}
```

- [ ] **Step 2: Extract all Section 4-18 requirement rows**

Create `requirements.json` with fields `requirement_id`, `section`, `deliverable`, `required_format`, `critical_blocker`, and `governing_text`. Include each numbered row 4.1-15.8 plus Sections 16-18 checklist obligations.

- [ ] **Step 3: Inventory repository evidence**

Record Git path, commit, application version, evidence date, artifact type, and relevance for source, docs, tests, datasets, screenshots, logs, manuals, models, and store metadata.

- [ ] **Step 4: Inventory existing Drive evidence**

List and record metadata for `Work/Sookta` children including `Documents`, `doclasted`, `Test dataset`, `develop`, `shared`, and the original contract/sign-off sources.

- [ ] **Step 5: Build the evidence map**

Map every requirement to one or more authoritative sources and one terminal status from the design spec. Mark unsupported claims as human-owned actions rather than deriving values from old documents.

- [ ] **Step 6: Validate inventory completeness**

Run a script that fails when a requirement has no mapped evidence/status or when a final-version claim points only to historical evidence.

Expected: zero unmapped requirements and a non-empty human-action list.

---

### Task 2: Reproduce Final-Version Technical Evidence

**Files:**
- Create: `/private/tmp/fsookta-final-handover/evidence/final_source_metadata.txt`
- Create: `/private/tmp/fsookta-final-handover/evidence/flutter_analyze_1.3.11+28.log`
- Create: `/private/tmp/fsookta-final-handover/evidence/flutter_test_1.3.11+28.log`
- Create: `/private/tmp/fsookta-final-handover/evidence/build_android_1.3.11+28.log`
- Create: `/private/tmp/fsookta-final-handover/evidence/build_ios_1.3.11+28.log`
- Create: `/private/tmp/fsookta-final-handover/evidence/verification_environment.json`

**Interfaces:**
- Consumes: full-history source commit and Flutter toolchain.
- Produces: raw final-version evidence used in folders 01 and 07.

- [ ] **Step 1: Materialize the authoritative commit into a temporary checkout**

Use `git archive bf8867a2083357cb9d60915bf6c2233801f923d8` and record SHA, tree ID, version, file count, toolchain, operating system, and timestamp.

- [ ] **Step 2: Resolve dependencies without changing locked versions**

Run `/Users/kpc/develop/flutter/bin/flutter pub get` and preserve output.

- [ ] **Step 3: Run static analysis**

Run `/Users/kpc/develop/flutter/bin/flutter analyze` and capture the complete output and exit code.

- [ ] **Step 4: Run the complete automated test suite**

Run `/Users/kpc/develop/flutter/bin/flutter test` and capture complete output, test count, failures, and duration.

- [ ] **Step 5: Attempt final Android release build**

Run `flutter build appbundle --release`; if upload signing is unavailable, retain the exact failure and separately produce a debug/profile artifact only as technical evidence, never label it production.

- [ ] **Step 6: Attempt final iOS release build**

Run `flutter build ipa --release`; if distribution signing is unavailable, retain the exact failure and create a signed local/profile build only when available, clearly classified as non-App-Store evidence.

- [ ] **Step 7: Verify evidence metadata**

Check every new log contains version `1.3.11+28`, commit SHA, command, timestamp, environment, and exit code.

---

### Task 3: Generate Source, Repository, and Release Artifacts

**Files:**
- Create: `/private/tmp/fsookta-final-handover/archives/SookTa-1.3.11+28-source-snapshot.tar.gz`
- Create: `/private/tmp/fsookta-final-handover/manifests/SHA256SUMS.txt`
- Create: `/private/tmp/fsookta-final-handover/artifacts/01_Final_Release_and_Scope_Closure.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/02_Repository_Ownership_and_IP_Handover.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/02_Third_Party_License_Register.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/02_Repository_Access_Checklist.xlsx`

**Interfaces:**
- Consumes: source inventory, Git history, pubspec.lock, Podfile.lock, Gradle configuration, build evidence.
- Produces: folder 01 and 02 primary artifacts.

- [ ] **Step 1: Create a deterministic source archive**

Archive the final source paths without build outputs, Pods, secrets, research media, or local configuration. Generate SHA-256 and record the Git tree ID.

- [ ] **Step 2: Generate final release and scope-closure document**

Include version freeze, release date basis, final feature list, original-scope closure, later additions with request source, known limitations, known bugs, build status, and release notes. Use human-action status for unsupported scope-contract facts.

- [ ] **Step 3: Generate repository/IP handover document**

Include authoritative repository, full-history branch, clean snapshot role, branches, proposed final tag, setup/build/deploy instructions, component ownership, modification/research/publication rights statement, and signature blocks.

- [ ] **Step 4: Generate third-party register**

List dependency name, resolved version, purpose, source URL, license identifier/text source, platform, runtime/development classification, and restriction notes.

- [ ] **Step 5: Generate access checklist**

Include GitHub, Firebase, Apple Developer, App Store Connect, Google Play Console, analytics/logging, signing assets, owner, transfer evidence, and status; include no secret values.

- [ ] **Step 6: Render and inspect**

Render both DOCX files and every workbook sheet. Repair clipped tables, missing headings, broken page breaks, formula errors, and inconsistent status values.

---

### Task 4: Generate Architecture, Technical Report, and Diagrams

**Files:**
- Create: `/private/tmp/fsookta-final-handover/artifacts/03_Final_Technical_Development_Report.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/03_Technical_Stack_and_Module_Specification.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/03_API_Applicability_Statement.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/diagrams/*.drawio`
- Create: `/private/tmp/fsookta-final-handover/artifacts/diagrams/*.png`

**Interfaces:**
- Consumes: source code, README, technical docs, source inventory, final evidence.
- Produces: folder 03 report and publication-ready diagrams.

- [ ] **Step 1: Author all 28 report sections**

Cover every Section 16 heading in order, citing repository paths and evidence artifact names. Distinguish current behavior, historical evolution, limitations, and recommended future work.

- [ ] **Step 2: Build stack and module workbook**

For each module record input, processing, output, dependency, storage/network behavior, failure modes, and source path. Include exact Flutter/Dart/package/model versions.

- [ ] **Step 3: Document API applicability**

Prove from source that the production assessment flow is offline and has no backend API. Record Firebase opt-in telemetry separately and mark endpoint documentation N/A with rationale.

- [ ] **Step 4: Create editable diagrams**

Create system context, runtime data flow, image-processing flow, assessment algorithm, recommendation flow, local-storage/data-export flow, user navigation, and module/dependency diagrams as Draw.io XML.

- [ ] **Step 5: Export high-resolution PNGs**

Render diagrams at print-quality dimensions suitable for at least 300 dpi placement and verify text remains legible at intended publication size.

- [ ] **Step 6: Perform report and diagram QA**

Verify all 28 headings, diagram references, versions, path references, N/A rationale, figure titles, and editable/PNG pairs.

---

### Task 5: Generate AI, Algorithm, Recommendation, and Data Artifacts

**Files:**
- Create: `/private/tmp/fsookta-final-handover/artifacts/04_AI_Algorithm_and_Model_Technical_Report.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/04_Algorithm_Recommendation_and_Reference_Matrices.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/04_AI_Training_and_Non_Training_Statement.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/05_Local_Storage_and_Data_Management_Manual.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/05_Data_Dictionary_and_Export_Schema.xlsx`

**Interfaces:**
- Consumes: model metadata, training scripts/metrics, REBA/ISO logic, bilingual catalog, export service, existing research datasets.
- Produces: folders 04 and 05.

- [ ] **Step 1: Document model roles and provenance**

Separate MoveNet pretrained inference, deterministic REBA/ISO, advisory XGBoost, daily logistic template coefficients, researcher-defined rules, economic-impact layer, and legacy artifacts.

- [ ] **Step 2: Document training evidence**

Record dataset source, sample counts, annotations, split, preprocessing, hyperparameters available from scripts, model-selection criteria, metrics, limitations, and raw evidence paths without overstating validation.

- [ ] **Step 3: Build algorithm/recommendation workbook**

Create sheets for thresholds/formulas, decision cases, image-failure handling, detected-risk mapping, trigger/priority/conflict logic, Thai-English messages, and source/reference traceability.

- [ ] **Step 4: Create signed technical-statement draft**

State which components were not trained/fine-tuned, which use template coefficients, which are advisory only, and what claims are prohibited; include signature/date blocks.

- [ ] **Step 5: Build local-storage and data manual**

Document SharedPreferences/app-file storage, identifiers, image linkage, export, validation, duplicates, missing values, timestamps, backup, restore, retention, and deletion. Mark remote DB/schema/migration as N/A with evidence.

- [ ] **Step 6: Build Data Dictionary workbook**

Include variable, description, type, allowed value, unit, source, missing code, privacy class, export location, and derivation for assessment, recommendation, image metadata, timestamp, status, and error fields.

- [ ] **Step 7: Verify content and formulas**

Cross-check representative thresholds and fields against source code, scan spreadsheet formula errors, render all sheets, and review every claim involving training or validation.

---

### Task 6: Generate Development, Testing, and UAT Artifacts

**Files:**
- Create: `/private/tmp/fsookta-final-handover/artifacts/06_Development_Audit_Trail.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/07_Master_Test_and_Verification_Package.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/07_Final_Algorithm_Verification_Report.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/08_UAT_Field_Test_and_Usability_Package.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/08_UAT_and_Field_Test_Technical_Report.docx`

**Interfaces:**
- Consumes: Git log, requirements, tests, screenshots, raw logs, historical UAT, final-version verification.
- Produces: folders 06-08.

- [ ] **Step 1: Build development audit workbook**

Create timeline, milestones, requirement traceability, version history, feedback/modification, before/after evidence, decisions/trade-offs, challenges/solutions, and effort-summary sheets.

- [ ] **Step 2: Build master test workbook**

Create test plan, functional cases, invalid/missing/unsupported inputs, network/error applicability, algorithm/reference cases, threshold boundaries, automated suite, device compatibility, performance, bug/retest, and evidence-index sheets.

- [ ] **Step 3: Populate final-version results only from raw evidence**

Expected/actual, pass/fail, version, tester category, date, command, and evidence link must be present. Unsupported physical-device checks remain pending rather than passing.

- [ ] **Step 4: Generate algorithm-verification report**

Summarize case counts, correct/incorrect results, discrepancies, corrections, retests, limitations, and raw-case references.

- [ ] **Step 5: Build UAT package**

Preserve historical iPhone/Android evidence with actual versions; include protocol, tasks, success criteria, results, sign-off, field-test versions/devices/issues, feedback, unresolved recommendations, SUS technical context, and logs.

- [ ] **Step 6: Verify matrices and evidence linkage**

Check every claimed pass links to raw evidence, every historical row has its original version, and every unavailable UAT observation has the correct researcher/owner action.

---

### Task 7: Generate Security, Manuals, Knowledge Transfer, and Research Package

**Files:**
- Create: `/private/tmp/fsookta-final-handover/artifacts/09_Security_Privacy_and_Data_Protection_Report.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/09_Security_and_Access_Control_Matrices.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/10_End_User_Manual.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/10_Research_Admin_Manual.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/10_Developer_Handover_Manual.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/10_Knowledge_Transfer_Deck.pptx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/10_Knowledge_Transfer_Minutes.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/11_Research_Publication_Package.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/11_Publication_Tables.xlsx`

**Interfaces:**
- Consumes: privacy/store docs, source behavior, screenshots, all prior artifacts and evidence.
- Produces: folders 09-11.

- [ ] **Step 1: Create security/privacy package**

Document local storage, Firebase opt-in telemetry, third-party flows, access-control N/A rationale, encryption context, participant/image linkage, retention/deletion/backup, security tests, limitations, secure credential categories, and signed non-retention confirmation.

- [ ] **Step 2: Update end-user manual**

Cover install, onboarding, profile/farmer management, image/video assessment, results, recommendations, history, export, TTS, errors, privacy, and limitations for `1.3.11+28` using current screenshots where available.

- [ ] **Step 3: Create research-admin manual**

Cover local data management, export, backup/restore, record interpretation, version tracking, logs, troubleshooting, and privacy-safe research workflow.

- [ ] **Step 4: Create developer manual**

Cover project structure, environment setup, dependencies, build/deploy, signing boundaries, Firebase configuration, local schema, model updates, testing, release process, common errors, and maintenance warnings.

- [ ] **Step 5: Create knowledge-transfer deck and minutes**

Build a concise editable deck covering architecture, code, data, algorithms, export, backup, builds, troubleshooting, ownership transfer, and open actions. Minutes include agenda, attendance, decisions, questions, action owners, and recording-link field.

- [ ] **Step 6: Create research/publication package**

Provide Chapter 4 tables, Chapter 5 technical discussion, Paper 2 Methods/Results inputs, editable figure/table index, raw evidence index, limitations, and mandatory researcher-review boundaries.

- [ ] **Step 7: Render and visually inspect every artifact**

Inspect all document pages, workbook sheets, and slides; repair clipping, overflow, low-resolution figures, inconsistent version labels, and accidental placeholders.

---

### Task 8: Generate Sign-off and Master Compliance Artifacts

**Files:**
- Create: `/private/tmp/fsookta-final-handover/artifacts/12_Final_Developer_Statement_and_Signoff.docx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/12_Final_Acceptance_and_Exceptions.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/00_Final_Handover_File_Index.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/00_Requirement_Compliance_Matrix.xlsx`
- Create: `/private/tmp/fsookta-final-handover/artifacts/00_Final_Package_QA_Report.docx`

**Interfaces:**
- Consumes: every artifact manifest, evidence map, and human-action record.
- Produces: folder 00 and 12 control artifacts.

- [ ] **Step 1: Create developer statement**

Include application/version, development period evidence, developer/company field, completed/uncompleted scope, technology, source/access/document/data handover assertions, known limitations/bugs, maintainability statement, and signature/date blocks.

- [ ] **Step 2: Create acceptance and exception workbook**

Include access transfers, outstanding items, proposed substitutions, written approvals, critical blockers, developer/researcher sign-off, and Accepted/Accepted with Conditions/Not Accepted states.

- [ ] **Step 3: Build File Index from the manifest**

List every deliverable with folder, version, date, editable/reference/raw format, purpose, source authority, checksum where applicable, and Drive link field.

- [ ] **Step 4: Build requirement compliance workbook**

Create one row per governing requirement with required format, evidence, status, owner, blocker class, N/A rationale, exception approval, and verification note.

- [ ] **Step 5: Generate preliminary QA report**

Report structural coverage, format pairing, versions, evidence quality, privacy scan, link readiness, human actions, and the 12 critical blocker states without claiming final acceptance.

- [ ] **Step 6: Run pre-upload completeness checks**

Fail if any requirement row is absent, any primary editable artifact lacks its required export, any artifact has a placeholder token, or any final test claim lacks raw evidence metadata.

---

### Task 9: Create Google Drive Tree and Upload/Import Artifacts

**Files:**
- Create: `/private/tmp/fsookta-final-handover/manifests/drive_manifest.json`

**Interfaces:**
- Consumes: verified local artifacts and destination folder ID.
- Produces: native/editable Drive package and stable Drive IDs/URLs.

- [ ] **Step 1: Create the 13 top-level folders**

Create `00` through `12` folders under destination ID `1iAADHY0UN4DVmBydPPvYJqYJsP10A5Hk`, plus only the evidence subfolders required by the artifact manifest.

- [ ] **Step 2: Import DOCX files as native Google Docs**

Use the Google Docs import route, verify the destination parent and native MIME type, then export/upload a PDF reference copy into the same functional folder.

- [ ] **Step 3: Import XLSX files as native Google Sheets**

Use native Google Sheets import, verify sheet names/ranges/formatting, then retain the XLSX or PDF reference version when required.

- [ ] **Step 4: Import the PPTX as native Google Slides**

Verify slide count/content and upload PDF reference export.

- [ ] **Step 5: Upload diagrams, evidence, archives, and checksums**

Upload Draw.io/PNG pairs, logs, screenshots, raw CSV/JSON, source archive, and checksum manifest to their mapped folders.

- [ ] **Step 6: Record every Drive ID and URL**

Populate `drive_manifest.json` and update the native File Index/Compliance Matrix links using canonical Workspace URLs.

- [ ] **Step 7: Verify access and parent placement**

Read metadata for every primary artifact and list each destination folder to prove MIME type, parent folder, title, and link.

---

### Task 10: Final Drive QA and Targeted Repair

**Files:**
- Modify: native File Index, Compliance Matrix, and QA Report in Drive.
- Create: `/private/tmp/fsookta-final-handover/manifests/final_drive_audit.json`

**Interfaces:**
- Consumes: live Drive tree and completed artifact set.
- Produces: final audit result and repaired package.

- [ ] **Step 1: Audit folder structure**

Require all 13 top-level folders, expected primary artifacts, and evidence subfolders. Detect duplicate, misplaced, or missing artifacts.

- [ ] **Step 2: Audit requirement coverage**

Reconcile every Section 4-18 row against live Drive evidence. No blank status, evidence, N/A rationale, or owner-action field is allowed.

- [ ] **Step 3: Audit formats and visual quality**

Verify editable/reference pairs, export every native primary artifact, render it, and inspect every page/sheet/slide/diagram. Collect all defects before repair.

- [ ] **Step 4: Audit facts, versions, and evidence**

Cross-check source paths, Git SHA, version labels, test outputs, dataset counts, model roles, limitations, and historical-version metadata.

- [ ] **Step 5: Audit privacy and secrets**

Scan uploaded text/config/archive manifests for private keys, signing secrets, passwords, tokens, unnecessary participant names, and local absolute paths that should not be exposed.

- [ ] **Step 6: Repair failed checks**

Update only artifacts with concrete defects, rerun the failed gate, and preserve Drive IDs when editing existing native files.

- [ ] **Step 7: Finalize master controls**

Update File Index links, compliance statuses, exception/human-action register, critical-blocker summary, and final QA report from live readback.

- [ ] **Step 8: Verify completion state**

Report technical package completion separately from final acceptance. Final acceptance remains pending while signatures, ownership transfers, physical-device evidence, or researcher approvals are outstanding.

