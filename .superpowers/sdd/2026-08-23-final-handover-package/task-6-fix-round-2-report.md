# Task 6 Canonical Fix Round 2 Report

Status: **DONE_WITH_CONCERNS** — canonical builders, verifier, entrypoint tests, artifact mutations, visual inspection, and checksums pass. Remaining concerns are the same explicitly human-owned final-version evidence actions.

## Canonical pipeline corrections

- `build_task6_audit_test_uat.py` now delegates to one canonical source module and regenerates the controlled payload plus both DOCX reports.
- `build_task6_workbooks.mjs` invokes a from-scratch artifact-tool builder. It creates all 41 sheets without importing or patching an earlier workbook.
- The canonical truth set is exactly 135 ordered expanded-reporter tests. Category counts are 55 Algorithm/reference, 33 Functional/regression, 26 Data/persistence, 14 UI/regression, and 7 Invalid/boundary.
- Automated Suite, Integration Regression, Algorithm Reference, Threshold Boundaries, Invalid/Missing Inputs, Functional Cases, Evidence Index, Test Plan, and Network/Firebase surfaces are exact Case-ID joins to the canonical results.
- All 136 PASS records contain Case ID, requirement ID where applicable, precondition/input, expected, actual, status, baseline/version, tester category, timestamp/date, exact method/command, raw evidence path, and SHA-256. Firebase remains `Not Executed`.
- H-UAT-003 uses date `2026-06-06` with separate round/revision `r2`. H-UAT-007 version is `not stated` because its cited source does not state one.
- Historical defects are joined to 40-character before/after commit objects, source-controlled history order, changed-path evidence, retest paths, and SHA-256 evidence.
- The canonical visual recorder only consumes an external manual decision. It cannot author or infer PASS.

## Verification results

- 10 primary artifacts: 3 XLSX, 2 DOCX, and 5 PDF.
- 41 workbook sheets.
- 76 PDF pages: 58 workbook pages and 18 report pages.
- 117 changed renders manually inspected through 10 contact sheets.
- Canonical verifier: PASS across payload, all named workbook joins, both DOCX reports, five PDFs, git-history ancestry/changed paths, SUS formula/validation, defect joins, and external visual hashes.
- Targeted and copied-artifact mutation tests: 15/15 PASS.
- Clean-staging canonical entrypoint rebuild test: 1/1 PASS.
- Cumulative checksums: 70/70 PASS.
- Secret, formula-error, and phone-pattern scans: zero findings.

## Remaining human gaps

- Physical Android/iPhone camera and gallery permission/capture tests.
- Human listening assessment of Thai/English TTS.
- Physical-device assessment completion, native sharing, exported-file validation, and offline inference.
- Final supported Android and iPhone matrices; decide tablet scope and test if included.
- Approve performance thresholds and collect cold-start, inference, export, memory, and stability measurements.
- Obtain consent/ethics clearance and conduct participant-coded final-baseline UAT.
- Collect all ten SUS responses per participant and approve interpretation.
- Authorized representatives review the completed evidence and sign acceptance.

No participant, SUS-score, final physical-device, performance, Firebase runtime, or acceptance fact is invented.
