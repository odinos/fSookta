# Task 1 Report: Staging Workspace and Source Inventory

## Outcome

Created a reproducible, metadata-only inventory generator at
`tools/final_handover/build_inventory.py`.  Its runtime outputs are intentionally
outside Git at `/private/tmp/fsookta-final-handover/`:

- `requirements.json` - 155 normalized governing requirements.
- `evidence_map.json` - one status, source list, and required human action per requirement.
- `source_inventory.json` - repository baseline/source inventory.
- `drive_source_inventory.json` - Drive metadata inventory; no raw Drive content.
- `inventory_validation.json` - counts and validation result.

The bounded staging tree also exists with `artifacts/`, `evidence/`, `renders/`,
`archives/`, and `manifests/` directories.

## Governing Inputs

- Governing requirements PDF: Drive `1OVOS13DQCNxK2PjAnmk3CYckcf2KCH0N`,
  `SookTa_Final_Application_Handover_Requirements.pdf`, modified
  `2026-08-23T12:53:22.000Z`.
- Repository baseline: `bf8867a2083357cb9d60915bf6c2233801f923d8`, application
  version `1.3.11+28`.
- Existing Sookta source parent: Drive `1Stq-imQPq9lcM2Spdvqcfj4M80ERNZFt`.
- Final destination parent: Drive `1iAADHY0UN4DVmBydPPvYJqYJsP10A5Hk`.

## Requirement Coverage

All 102 numbered Section 4-15 requirements and all 53 Section 16-18 checklist
obligations are present (155 total).

| Section | Count |
|---|---:|
| 4 | 6 |
| 5 | 9 |
| 6 | 7 |
| 7 | 7 |
| 8 | 12 |
| 9 | 12 |
| 10 | 9 |
| 11 | 13 |
| 12 | 6 |
| 13 | 8 |
| 14 | 5 |
| 15 | 8 |
| 16 | 28 |
| 17 | 13 |
| 18 | 12 |

Status count: `Pending Owner Action` 137; `Pending Researcher Evidence` 6;
`Exception Approval Required` 12.  No status outside the binding terminal-status
set is emitted.  These are deliberately pending/exception statuses: the
inventory does not claim final build validation, signatures, account transfer,
participant evidence, or secret delivery.

## Evidence Sources Inventoried

Repository records cover source (`lib/`), README/docs, unit/integration tests,
research datasets/templates, screenshots, logs, manuals, bundled model assets,
and store metadata.  Each record carries the Git path, baseline commit,
application version, evidence date, artifact type, and relevance.

Drive source-parent metadata records direct children `Documents`, `doclasted`,
`Test dataset`, `develop`, `shared`, `Share`, `SourceCode`, `APK`, `Wireframe`,
`Final`, `Markdown`, and `task`.  Focused folder inventory identifies historical
contract/sign-off sources in `Documents`, historical sample exports in
`doclasted`, a participant/research-data CSV in `Test dataset` (metadata only),
and governing requirements in `Share`.  Historical APK and historical sign-off
sources are explicitly labelled historical and cannot support a final-version or
final-sign-off assertion.

## Validation

Commands run:

```text
python3 tools/final_handover/build_inventory.py --output-dir /private/tmp/fsookta-final-handover --evidence-date 2026-08-23
PYTHONPYCACHEPREFIX=/private/tmp/fsookta-final-handover/pycache python3 -m py_compile tools/final_handover/build_inventory.py
git diff --check
```

Exact generator result: 155 requirements; section counts `4:6, 5:9, 6:7, 7:7,
8:12, 9:12, 10:9, 11:13, 12:6, 13:8, 14:5, 15:8, 16:28, 17:13, 18:12`; status
counts `Exception Approval Required:12, Pending Owner Action:137, Pending
Researcher Evidence:6`; `validation_errors: []`.

Negative guard result: `negative historical-final-version guard: PASS`.  It
changes a synthetic map record into a final-version claim backed only by
historical evidence and verifies that validation rejects it.

## Self-review and Fixes

Initial generator validation produced zero errors.  Self-review added the full
direct-child metadata list for the Sookta Drive source parent, so the inventory
records the named existing folders rather than only selected evidence folders.
No raw Drive documents, participant data/media, secrets, or credentials were
written to the repository or staging JSON.

## Concerns

All handover evidence is intentionally unresolved at this stage.  In particular,
the existing Drive APKs, historic documents, and old sign-off must not be
represented as evidence for baseline `1.3.11+28`; owner action and researcher
evidence remain required for later tasks.

## Commit

`031a14b1062f515ec62b3cab7e52f0333acd64d7` — `docs: add final handover source inventory`.

## Fix Round 1/5: Required Staging Directories

### Changed files

- `tools/final_handover/build_inventory.py` now creates `artifacts/`,
  `evidence/`, `renders/`, `archives/`, and `manifests/` under every chosen
  output directory using idempotent `mkdir(exist_ok=True)` calls.  It has no
  deletion path.
- `tools/final_handover/test_build_inventory.py` runs the real generator against
  a fresh `/private/tmp` directory, asserts exactly the five required child
  directories, then reruns after adding a sentinel and asserts the sentinel is
  retained.

### Root cause and self-review

The original `main()` created only `args.output_dir`; it did not create the
five contract subdirectories.  The new behavioral regression test was first run
against that implementation and failed, reporting all five directories missing.
The minimal fix adds only the missing idempotent directory creation.  Self-review
confirmed the rerun preserves a pre-existing file and creates no extra directory
in a clean staging root.

### Commands and exact results

```text
PYTHONPYCACHEPREFIX=/private/tmp/fsookta-final-handover/pycache python3 -m unittest tools/final_handover/test_build_inventory.py
.
----------------------------------------------------------------------
Ran 1 test in 0.071s

OK
```

```text
staging_root=$(mktemp -d /private/tmp/fsookta-final-handover-fix-round-1.XXXXXX)
python3 tools/final_handover/build_inventory.py --output-dir "$staging_root" --evidence-date 2026-08-23
```

Result: fresh staging root `/private/tmp/fsookta-final-handover-fix-round-1.Y1yKkx`
contained exactly `archives`, `artifacts`, `evidence`, `manifests`, and
`renders` as child directories.  The normal inventory rerun reported 155
requirements and `validation_errors: []`.  `git diff --check` completed with no
output.

### Commit

`f47e8f002b0624d079185cf9acb89eafe2cf7872` — `fix: create handover staging directories`.
