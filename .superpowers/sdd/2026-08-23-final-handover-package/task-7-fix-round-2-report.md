# Task 7 Fix Round 2 — Provisional Review Report

Status: **READY FOR INDEPENDENT RE-REVIEW**. The eight round-2 findings are corrected. All non-visual content, source-identity, scan, semantic-evidence, status, metadata, formula, archive, and mutation gates pass. External visual PASS remains intentionally absent until the independent reviewer clears this round.

## Corrected findings

1. The disclosed offline inspection now consumes content rather than counting containers: 619 eligible source files (62,856,796 bytes), all 365 source-snapshot regular members (50,950,815 bytes), 295 XML/relationship/text members from prior-package Office artifacts (10,044,097 bytes), and 33 non-Task7 manifests. Current Task7 Office/manifest outputs are explicitly excluded to avoid circular self-evidence. Secret-marker and potential participant-identifier patterns are counted per domain without retaining matched values. The independent verifier repeats the scan from source bytes and compares exact domain counts.
2. All 978 source generic secret-assignment signals are recorded in 32 deterministic per-file triage rows: 976 `password=false` Android UIAutomator boolean attributes and two `change-me` signing placeholders in `android/key.properties.example`. The two placeholders remain `Open - Pending Owner`; `pending_owner_review_occurrences` and `untriaged` both honestly remain 2.
3. Publication evidence is semantically bound. Paper 2 Methods has distinct exact/hash-bound rows for static analysis, automated tests, Android build, iOS build, and the master case matrix. Citation `CIT-04` binds the stable pubspec alias; `CIT-05` and final UAT/SUS gaps bind the UAT package. The verifier rejects a valid but semantically wrong replacement path.
4. Final workbook and slide citations contain no ephemeral `authoritative-materializations/source-*` paths. Nine stable `evidence/task7-source/` aliases retain exact source-relative path and SHA-256.
5. Source identity is independently proven from the Git archive: PAX commit `bf8867a2083357cb9d60915bf6c2233801f923d8`, recomputed Git tree `b4ed5fd0c061492c74dba356ed8a114b5f6621ba`, 602 tracked members, and byte equality between every archive member and selected materialization. A source-alias substitution mutation is rejected.
6. The controlled status vocabulary includes `Open - Pending Owner/Researcher`; every exact `Status` column is restricted to the seven controlled values and combined owner/researcher actions use the combined state.
7. DOCX, PPTX, and both XLSX files use neutral SookTa creator/application metadata and deterministic core timestamps. Generator/application values such as openpyxl, LibreOffice, Microsoft Excel, Walnut Exporter, and artifact-tool are rejected.
8. Mutation coverage now includes source substitution; archive, Office, and manifest secret/participant-shaped injection; uncontrolled status; XLSX metadata; and semantically wrong-but-valid evidence paths, in addition to the prior navigation, formula, hash, slide-note, typography, metadata, and scan-triage mutations.

## Provisional evidence

- Artifacts: 18 (nine editable and nine PDF).
- Documents: six DOCX / 20 pages.
- Workbooks: two XLSX / 24 sheets / 42 exact publication evidence rows / one controlled formula / zero formula errors.
- Deck: 14 slides / 14 exact `[Sources]` blocks.
- PDFs: 58 pages.
- Renders: 116 primary surfaces plus 34 contact sheets; changed full-size renders are visually clean locally.
- Expected-render manifest SHA-256: `7fce49b7a2fc11d4ab1f310dc52d0d3ef593ebc8f28b15bda18929e2c9663cdb`.
- Targeted and mutation tests: 31/31 PASS (17 substantive regressions, 14 artifact-copy mutation categories).
- Legacy suite: 5 PASS; one intentional block at `external visual decision absent`.
- Canonical verifier: all content/source/scan/metadata/formula/PDF/render-inventory prerequisites pass before the same intentional external-decision block.
- Final cumulative checksum manifest is not regenerated in this provisional round because the external visual decision and resulting visual manifest are pending.

## Preserved claim boundary

Potential identifier-shaped pattern counts do not establish that a match belongs to a participant. No matched value is stored. No security compliance, vulnerability absence, credential safety, participant fact, research result, owner policy, KT attendance/decision/recording, acceptance, or signature is asserted. No Google Drive access or upload occurred.
