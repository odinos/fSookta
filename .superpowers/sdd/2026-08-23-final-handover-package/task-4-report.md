# Task 4 Report — Architecture and Technical Documentation

## Outcome and authoritative basis

Generated the complete Task 4 technical-documentation set from SookTa version
`1.3.11+28`, authoritative commit
`bf8867a2083357cb9d60915bf6c2233801f923d8`, tree
`b4ed5fd0c061492c74dba356ed8a114b5f6621ba`. Source inspection covered 72
Dart files from the authoritative materialization. Task 1–3 staging artifacts
were preserved; no Task 4 artifact was uploaded to Google Drive in this task.

The final status is `passed_with_human_actions`. This reflects unresolved
owner/researcher/legal actions, not a technical defect in the generated files.

## Artifact inventory

The 22 primary artifacts under
`/private/tmp/fsookta-final-handover/artifacts/` comprise:

- `03_Final_Technical_Development_Report.docx` and its 11-page PDF reference;
- `03_Technical_Stack_and_Module_Specification.xlsx` and its 4-page A3
  landscape PDF reference;
- `03_API_Applicability_Statement.docx` and its 2-page PDF reference;
- eight editable Draw.io sources and eight paired 2800x1800 PNG exports with
  at least 300-dpi metadata: system context, runtime data flow, image
  processing, assessment algorithm, recommendation flow, local storage/data
  export, user navigation, and module dependencies.

The report contains the governing 28 headings exactly once and in the required
order. Every section includes source paths or evidence artifact names and
labels current behavior, limitations, future recommendations, and human-owned
acceptance without converting missing evidence into completed claims.

## Source-grounded findings

The production assessment path is local/offline. The scan found no direct
assessment backend HTTP client, while `lib/main.dart` and
`lib/core/services/firebase_telemetry_service.dart` show optional Firebase
Analytics/Crashlytics controlled by `SOOKTA_TELEMETRY_ENABLED` with
`defaultValue: false`. The API statement therefore classifies backend endpoint
documentation as `N/A with Rationale` and separately records the future
evidence required if a remote API is introduced.

Architecture and module claims cite `lib/app/`, `lib/core/`, `lib/screens/`,
`pubspec.yaml`, model manifests/assets, and Task 1–3 evidence. The workbook
contains 14 module records and 18 stack/version records. Each module records
input, processing, output, dependencies, storage/network behavior, failure
modes, source path, and evidence basis.

## Workbook, render, and visual QA

The workbook was authored with `@oai/artifact-tool`. It contains four sheets
and five exact formula contracts. Expected formulas and cached values matched;
the artifact-tool formula-error search matched zero cells. The final PDF has
one page per sheet.

Documents used the Google Docs-targeted preset and were sanitized before final
render. Independent OOXML checks found no title paragraph border/rule residue.
Visual inspection covered 29 unique files: 11 report pages, 2 API pages, 4
workbook-sheet renders, 4 workbook-PDF pages, and 8 diagram PNGs. The final
renders have no clipping, overlap, broken glyphs, truncated tables, or obscured
connectors. Diagram labels, local/offline boundaries, arrow direction, version,
commit, legend, and source evidence are visible and consistent.

The hash-bound visual-QA manifest is
`/private/tmp/fsookta-final-handover/manifests/task4_visual_qa_manifest.json`,
SHA-256
`3739dfd430b0060eabec89f6766a8ca1ec1cd1474b923d9728611bc3c68cd02f`.
It binds 22 artifact entries to 29 unique inspected render files. The expected
render map is stored beside it as `task4_expected_visual_renders.json`.

## Verification and checksum evidence

Verification results:

- Combined Python regression suite: 43 passed.
- Task 4 Node workbook unit suite: 4 passed.
- Task 3 Node workbook regression suite: 2 passed.
- Independent Task 4 verifier: `passed_with_human_actions`; 28 report headings,
  8 diagram pairs, 22 primary artifacts, 17 PDF pages, 4 workbook sheets, 5
  formula contracts, 18 exact technology/model identifiers, 72 citation
  records, and zero formula errors.
- DOCX preset/title sanitization, PDF page counts, Draw.io XML editability,
  PNG dimensions/DPI, status vocabulary, archive/XML privacy scan, visual
  manifest freshness, and artifact checksum binding: passed.
- `shasum -a 256 -c manifests/SHA256SUMS.txt`: all 37 entries passed.

The shared checksum manifest SHA-256 is
`b135f9fc87e38cf868a9c647466f3a73be43e0993368f357df32bc6721bbb02a`.
It preserves prior Task 1–3 entries and adds all Task 4 primary artifacts and
safe QA manifests.

## Reproducible implementation

Safe repository changes consist of the Python document/diagram builder,
artifact-tool workbook builder, independent verifier, explicit visual-QA and
checksum recorder, Python/Node tests, and this safe QA summary/report. Generated
DOCX, XLSX, PDF, Draw.io, PNG, render, and private evidence files remain under
the staging root and are not committed.

TDD evidence includes initial failing imports for the missing builders, a
failing 5-page workbook-PDF regression corrected to 4 pages, a failing diagram
edge-boundary test corrected by terminating connectors at node boundaries, and
a failing recorder import corrected by adding the fail-closed recorder. All
targeted and regression tests are green after the fixes.

## Human actions and concerns

The following remain explicitly human-owned:

- owner/researcher confirmation of contract scope and historical milestone
  approvals;
- final physical-device compatibility and performance evidence for
  `1.3.11+28`;
- final UAT/SUS evidence and researcher interpretation;
- Firebase/store ownership and production privacy-disclosure approval;
- production Android/iOS signing, store submission, and store acceptance;
- third-party license and legal review;
- authorized final acceptance and signatures.

No contract scope, production signing, store publication, UAT/performance
outcome, clinical validation, or external-validity claim was invented. These
actions must remain pending until authorized evidence exists.

## Independent review fix round 1

All Important findings and the practical Minor finding from review round 1
were corrected. The workbook now reads exact resolved package versions from
`pubspec.lock`, including camera `0.11.4`, image_picker `1.2.2`, firebase_core
`4.10.0`, and shared_preferences `2.5.5`. It records the exact XGBoost model ID
`reba-iso-xgboost-onnx-2026-06-07`, daily logistic template ID
`daily-injury-logistic-template-2026-06-14`, MoveNet schema ID/version, and
SHA-256 fingerprints for both bundled MoveNet assets. Because no upstream
MoveNet artifact release/version is present in repository evidence, both model
rows say this explicitly rather than inventing provenance. Row height and
column width were increased so those limits and hashes remain legible in both
the workbook-sheet render and A3 PDF.

The system-context diagram now places Firebase and the other external actors
outside the local/offline boundary. Local persistence is split into three
source-grounded paths: profiles/drafts serialize to SharedPreferences;
captured images are copied into application documents; and assessment records
are written as CSV in application documents before an explicit user-selected
OS share. The assessment diagram now shows the XGBoost advisory consuming the
51 MoveNet joint features independently and attaching only after the
deterministic REBA/ISO primary result. The corrected connectors, labels, and
arrow directions were checked in Draw.io XML and final PNGs.

Nonexistent report references were replaced with
`test/assessment_readiness_test.dart`, `docs/uat-last-phase-20260712.md`, and
`docs/uat-production-platform-parity-20260719.md`. The builder now resolves all
72 report citation records against the authoritative source or staging tree,
fails on missing references, and explicitly labels the two future UAT/signoff
artifacts as pending. Report sections now consume inspected source facts rather
than hard-coding mutable counts and API/telemetry state.

TDD RED evidence in this round included missing exact package/model records,
stale citation and diagram contracts, the hard-coded report-facts check, and a
real verifier failure on an artifact-tool sparse worksheet row. GREEN evidence
is 43/43 combined Python tests, 4/4 Task 4 Node tests, 2/2 Task 3 Node
regressions, Python compilation, and both Node syntax checks. The independent
verifier passed with human actions: 28 headings, 8 diagram pairs, 22 primary
artifacts, 17 PDF pages, 4 workbook sheets, 18 technology/model identifiers,
72 citation records, 5 formula contracts, zero formula errors, and 37 checksum
entries. `shasum -a 256 -c manifests/SHA256SUMS.txt` passed 37/37.

Changed-render inspection covered all eight final diagram PNGs, report pages
2–11, the Technology Stack sheet render, and workbook PDF page 3; the complete
hash-bound manifest covers all 29 unique Task 4 renders. No upload to Google
Drive occurred during this task or fix round. Human-action classifications
listed above remain unchanged.

## Independent review fix round 2

Review round 2 confirmed every original finding was resolved and identified
one verifier-only regression: the Technology Stack header (`Component`) was
included in the returned row map, so the QA summary reported 19 identifiers
although the workbook contains 18 data records. A focused TDD regression first
failed because no header-excluding reader existed; the verifier now reads only
component data rows and the test proves a header plus two data rows returns
exactly two identifiers.

The refreshed QA summary reports 18 technology/model identifiers. The
independent verifier again passed with human actions: 28 headings, 8 diagram
pairs, 22 primary artifacts, 17 PDF pages, 4 workbook sheets, 72 citation
records, 5 formula contracts, zero formula errors, and 37 checksum entries.
The complete Python regression suite passed 44/44 and Python compilation
passed; `shasum -a 256 -c manifests/SHA256SUMS.txt` passed 37/37.
No generated artifact, render, visual manifest, or checksum-bound file changed,
so artifact regeneration and additional visual inspection were not applicable;
the prior 29-render hash-bound inspection remains current. Drive was not
accessed and all human-action classifications remain unchanged.
