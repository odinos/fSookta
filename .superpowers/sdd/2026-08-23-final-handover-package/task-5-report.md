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

- `04_AI_Algorithm_and_Model_Technical_Report.docx` and its 7-page PDF;
- `04_Algorithm_Recommendation_and_Reference_Matrices.xlsx` and its 19-page
  PDF;
- `04_AI_Training_and_Non_Training_Statement.docx` and its 4-page PDF;
- `05_Local_Storage_and_Data_Management_Manual.docx` and its 5-page PDF;
- `05_Data_Dictionary_and_Export_Schema.xlsx` and its 13-page PDF.

The two workbooks contain 24 sheets in total: 15 algorithm/recommendation
sheets and 9 data-management/schema sheets. They contain 8 model/algorithm
roles, 3 training-evidence records, 26 exact Thai-English recommendation pairs,
173 persisted top-level-key/nested-record records, and all 84 all-history CSV
columns in exact source order.

## Source-grounded model and algorithm boundaries

Only the bundled XGBoost ONNX advisory is classified as project-trained. Its
repository metadata records 388 total feature rows, a 298/90 train/holdout
split, holdout risk accuracy `0.6667`, and holdout MAE `0.8256`. The holdout
contains only `high` and `veryHigh` labels, the referenced raw metrics artifact
is absent, the split seed/method is not recorded, and no external or clinical
validation evidence is available. The documents therefore preserve these
figures as metadata-only internal evidence and do not use them to assert broad
generalization, reproducibility, or acceptance.

MoveNet Thunder and MultiPose are bundled pretrained pose providers and were
not fine-tuned by the project. Their upstream artifact release/version is not
available in repository evidence, so the package identifies the binaries by
path and SHA-256 without inventing provenance. The daily logistic component
contains template coefficients, not a fitted outcome model. REBA, ISO 11228
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
off unless enabled by the owner.

All examples in the schema workbook are visibly synthetic. No real participant
record, credential, token, secret, or private/raw evidence was included in the
artifacts, manifests, QA summary, or committed implementation files.

## Workbook, render, and visual QA

The workbooks were authored with `@oai/artifact-tool`. Ten exact formula
contracts cover both control summaries; cached values matched and the
artifact-tool formula-error scan found zero errors. Long dictionary and matrix
sheets fit to page width and paginate vertically instead of being truncated.

Google Docs-targeted DOCX files passed the deterministic title sanitizer.
Visual inspection covered all 72 final Task 5 render files: 16 DOCX/PDF pages,
32 workbook-PDF pages, and 24 workbook-sheet renders. Repairs made during QA
included separating document bullets, preventing the manual signature table
from splitting incorrectly, enabling vertical workbook pagination, and using a
Thai-capable font configuration for LibreOffice PDF conversion. Final surfaces
are complete, unclipped, non-overlapping, and legible at normal document or PDF
zoom; Thai and English glyphs render correctly.

The hash-bound visual-QA manifest is
`/private/tmp/fsookta-final-handover/manifests/task5_visual_qa_manifest.json`,
SHA-256
`98b1250291a11e1fe605622da3a303276f9a087439e01980cd2da2892167f5a3`.
It binds all ten primary artifacts to the 72 inspected render files.

## Verification and checksum evidence

Verification results:

- Task 5 Python suite: 10 passed.
- Task 5 Node workbook suite: 8 passed.
- Python compilation and Node syntax checks: passed.
- Independent verifier: `passed_with_human_actions`; 10 primary artifacts, 16
  document pages, 24 workbook sheets, 32 workbook PDF pages, 10 formula
  contracts, 8 model/algorithm roles, 3 training-evidence records, 84 export
  dictionary records, and zero formula errors.
- Citation resolution, controlled status vocabulary, claim-boundary guards,
  archive/XML secret and participant-data scans, editable/reference pairing,
  visual-manifest freshness, and cumulative checksum binding: passed.
- Cumulative checksum manifest: 50 entries; SHA-256
  `ada6383d995234f940afac57b0941ebca2267f56499c14ebbd6cc441ecb49fc6`.

## Reproducible implementation

Safe repository changes consist of the Python document/evidence builder,
artifact-tool workbook builder, independent verifier, fail-closed visual-QA and
checksum recorder, Python/Node tests, QA summary, this report, and the execution
ledger update. Generated DOCX, XLSX, PDF, render, temporary font configuration,
and private/raw evidence files remain under the staging root and are not
committed.

TDD regressions covered complete REBA A/B/C matrices, the 16-column persisted
record schema, source-order export headers, negated prohibited-claim handling,
document bullet separation, workbook vertical pagination, Thai-capable fonts,
formula contracts, and fail-closed status gates. All targeted tests are green
after the fixes.

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
