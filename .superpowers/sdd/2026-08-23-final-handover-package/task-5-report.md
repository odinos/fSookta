# Task 5 Report — AI, Algorithms, and Data Management

## Outcome and authoritative basis

Generated the complete Task 5 AI/algorithm/data-management documentation set
from SookTa version `1.3.11+28`, authoritative commit
`bf8867a2083357cb9d60915bf6c2233801f923d8`, tree
`b4ed5fd0c061492c74dba356ed8a114b5f6621ba`. Task 1–4 staging artifacts were
preserved. No Task 5 artifact was uploaded to Google Drive in this task.

The independent verifier status is `passed_with_human_actions`. The package is
technically complete, while claims requiring owner, researcher, privacy, or
acceptance authority remain visibly pending.

## Artifact inventory

The ten primary artifacts under
`/private/tmp/fsookta-final-handover/artifacts/` comprise five editable/reference
pairs:

- `04_AI_Algorithm_and_Model_Technical_Report.docx` and its 8-page PDF;
- `04_Algorithm_Recommendation_and_Reference_Matrices.xlsx` and its 19-page
  PDF;
- `04_AI_Training_and_Non_Training_Statement.docx` and its 4-page PDF;
- `05_Local_Storage_and_Data_Management_Manual.docx` and its 5-page PDF;
- `05_Data_Dictionary_and_Export_Schema.xlsx` and its 14-page PDF.

The two workbooks contain 24 sheets in total: 15 algorithm/recommendation
sheets and 9 data-management/schema sheets. They contain 10 current, legacy,
and test-only model/algorithm roles, 3 training-evidence records, 26 exact
Thai-English recommendation pairs, 190 persisted top-level-key/nested-record
rows with record ownership preserved, and all 84 all-history CSV
columns in exact source order.

## Source-grounded model and algorithm boundaries

Only the bundled XGBoost ONNX advisory is classified as project-trained. Its
repository metadata records 388 total feature rows, a 298/90 train/holdout
split, holdout risk accuracy `0.6667`, and holdout MAE `0.8256`. The holdout
contains only `high` and `veryHigh` labels, the referenced raw metrics and
configured dataset files are absent, and no external or clinical validation
evidence is available. The source training script records
`GroupShuffleSplit(test_size=0.22, random_state=42)` plus the complete
`XGBRegressor` parameter set. Missing dataset evidence is tracked separately as
`Pending Researcher Evidence`; missing raw metrics remain `Pending Owner
Action`. The figures remain metadata-only internal evidence and do not assert
broad generalization, successful reproduction, or acceptance.

MoveNet Thunder and MultiPose are bundled pretrained assets and were not
fine-tuned by the project. MultiPose is the single-person eligibility gate: it
counts people and rejects the image unless exactly one person is eligible;
Thunder then estimates the assessment pose. Their upstream artifact
release/version is unavailable, so the package identifies binaries by path and
SHA-256 without inventing provenance. The daily logistic component contains
template coefficients, not a fitted outcome model. Its displayed runtime tier
uses the seven-record high-risk count (0–1 Low, 2–3 Watch, 4–5 High, 6–7
Critical); probability thresholds are loaded/helper metadata but are not used
by `predictForRecords`. REBA, ISO 11228
applicability/formulas, recommendation rules, and economic-impact calculations
are classified as deterministic or source/research-defined as appropriate.
The XGBoost signal remains advisory and cannot lower or replace deterministic
REBA/ISO results.

## Data-management boundaries

The package documents SharedPreferences schema version 2, local assessment
history/profile/draft serialization, application-document image and CSV paths,
migration behavior, explicit user-selected sharing, missing-value behavior,
enumerations, derivations, privacy classes, and compatibility limits. No
remote assessment database or assessment API schema was found. Optional
Firebase telemetry remains separate from assessment persistence and default
off unless enabled by the owner. The package enumerates all explicit wrapper
and generic `logEvent` call sites and fields found in source, `logAppOpen`, and
the parallel sanitized Crashlytics event context. It separately discloses that
`FirebaseAnalyticsObserver` may emit SDK-generated navigation/screen analytics
whose exact names and payloads are not enumerated by repository source.

The verifier checks all 190 documented persisted rows and all 84 export rows
against an independently reconstructed technical contract for the recorded
types, nullability, units, ranges, locations, fallback behavior, and privacy
labels. This proves consistency with the cited repository source; it does not
prove that the privacy classification is legally complete or approved. In
particular, lift frequency is stored in
lifts/minute and multiplied by 60 only for the per-hour export; lifting geometry
is in centimetres; push/pull forces are in newtons; `ErgoResult.limitValue` is
context-dependent (lifting RWL kg, push/pull force N, or encoded REBA limit);
annual income is THB/year; and profile location/annual income remain sensitive.
The export contract records BMI category as text, assessment time as HH:mm:ss,
and nullable time-on-task as integer seconds with a blank export fallback. The
formula-driven control summary now counts all 78 sensitive export fields rather
than relying on a retired privacy-label string. Round 4 replaces substring
classification with explicit container and owned-field rules. Draft/history/
migration-backup containers are labeled for their composite participant,
assessment, and financial payloads; timestamps such as `savedAt` remain
operational metadata; mirrored participant snapshots remain participant data.
Round 5 additionally classifies the demographic calculation input
`ErgoInputData.gender` as participant/profile data and independently verifies
that classification; an exact audit found no analogous demographic fallback
remaining in the documented persisted contract.

All examples in the schema workbook are visibly synthetic. No real participant
record, credential, token, secret, or private/raw evidence was included in the
artifacts, manifests, QA summary, or committed implementation files.

## Workbook, render, and visual QA

The workbooks were authored with `@oai/artifact-tool`. Ten exact formula
contracts cover both control summaries; cached values matched and the
artifact-tool formula-error scan found zero errors. Long dictionary and matrix
sheets fit to page width and paginate vertically instead of being truncated.

Google Docs-targeted DOCX files passed the deterministic title sanitizer.
Visual inspection covered all 74 final Task 5 render files: 17 DOCX/PDF pages,
33 workbook-PDF pages, and 24 workbook-sheet renders. Repairs made during QA
included separating document bullets, preventing the manual signature table
from splitting incorrectly, removing an orphan signature fragment and a blank
page, enabling vertical workbook pagination, and using a Thai-capable font
configuration for LibreOffice PDF conversion. Final surfaces are complete,
unclipped, non-overlapping, and legible at normal document or PDF zoom; Thai
and English glyphs render correctly.

The hash-bound visual-QA manifest is
`/private/tmp/fsookta-final-handover/manifests/task5_visual_qa_manifest.json`,
SHA-256
`e46d698d11ee59eac83ddcc4f0469372fee2b17158a560ec87556044eed8124e`.
It binds all ten primary artifacts to 91 render files. Round 4 directly
re-inspected the 9 affected workbook-sheet renders and 14 corresponding PDF
pages; unchanged surfaces retain their prior passed status and current hashes.

## Verification and checksum evidence

Verification results:

- Task 5 Python suite: 22 passed.
- Task 5 Node workbook suite: 12 passed.
- Python compilation and Node syntax checks: passed.
- Independent verifier: `passed_with_human_actions`; 10 primary artifacts, 17
  document pages, 24 workbook sheets, 33 workbook PDF pages, 10 formula
  contracts, 10 model/algorithm roles, 3 training-evidence records, 190
  persisted schema rows, 84 export schema rows, and zero formula errors.
- Citation resolution, controlled status vocabulary, claim-boundary guards,
  archive/XML secret and participant-data scans, editable/reference pairing,
  visual-manifest freshness, and cumulative checksum binding: passed.
- Cumulative checksum manifest: 50 entries; SHA-256
`b5ade5a1e9415f77c4a1121f69576aa8a619a159eec44ba7e0f9d5031781cc06`.

## Reproducible implementation

Safe repository changes consist of the Python document/evidence builder,
artifact-tool workbook builder, independent verifier, fail-closed visual-QA and
checksum recorder, Python/Node tests, QA summary, this report, and the execution
ledger update. Generated DOCX, XLSX, PDF, render, temporary font configuration,
and private/raw evidence files remain under the staging root and are not
committed.

TDD regressions now also cover source-exact 24-row recommendation key mapping,
daily count-tier behavior, XGBoost split/parameters and missing paths,
single-person gate authority, legacy/test-only asset hashes, Firebase fields,
record-owner duplicate preservation, semantic completeness, 26 bilingual
pairs, ISO-8601 text examples, independent Dart declaration/serializer
extraction, exact telemetry call-site discovery, documented-contract mutation
rejection across all persisted/export rows, source-grounded technical units,
privacy labels and fallbacks (without claiming legal privacy completeness),
compact non-splitting signature rows, and the absence of manual page breaks
that can create blank pages. The cumulative regression passed 66 Python and 18 Node tests; all
targeted tests are green after the fixes.

## Human actions and concerns

The following remain explicitly human-owned:

- owner approval of model/recommendation authority, scope, privacy disclosures,
  retention/deletion, and production-use boundaries;
- researcher provision of governed outcome labels, participant/annotation
  units, consent/ethics and de-identification evidence where applicable, and
  approved evaluation criteria;
- owner provision of the missing raw XGBoost metrics artifact or approval of
  the metadata-only limitation, plus a seeded/configured retraining run if
  reproducibility is required;
- researcher review of REBA/ISO mapping, project safety floors, bilingual
  recommendation wording, dataset-label provenance, and limitations;
- owner definition of backup/restore, secure export destination, access
  control, retention schedule, end-to-end deletion, and incident response;
- preparer, technical reviewer, owner, and researcher signatures and dates.

No research acceptance, model provenance, privacy/ethics completion, clinical
validation, external validity, production suitability, or final acceptance
claim was invented. These actions must remain pending until authorized evidence
exists.
