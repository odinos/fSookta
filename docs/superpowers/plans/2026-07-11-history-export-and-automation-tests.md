# History Export and Automation Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete requirement 14 and 15 by exporting the currently selected history data and expanding automated coverage around history, export, and regression-critical flows.

**Architecture:** Reuse `AssessmentExportService` as the single CSV creation layer. Keep `HistoryTab` responsible only for current filters, UI labels, and share actions. Add widget/service tests before production changes and keep commits separated by requirement.

**Tech Stack:** Flutter, Dart widget tests, `shared_preferences` mock state, existing CSV export service, existing `share_plus` UI integration.

## Global Constraints

- Do not change persisted history schema unless a failing test proves it is required.
- Do not add a second export implementation; use `AssessmentExportService`.
- Keep Thai user-facing copy understandable for staff/farmer workflows.
- Test first, watch failure, implement minimal code, then run regression tests.

---

### Task 1: Requirement 14 - Filtered History Export

**Files:**
- Modify: `lib/screens/main/history_tab.dart`
- Test: `test/history_tab_filter_trend_test.dart`

**Interfaces:**
- Consumes: `_filteredHistory(List<EvaluationHistoryRecord>)`, `_HistorySummaryAndFilters`, `AssessmentExportService.exportAllHistoryCsv`.
- Produces: export button behavior that shares only the currently displayed history records.

- [ ] **Step 1: Write failing widget test**

Add a test that creates three records, applies the high-risk filter, and expects the export button tooltip/visible text to communicate the filtered export scope. The current code only says "ส่งออกทั้งหมด", so the test must fail before implementation.

- [ ] **Step 2: Run RED**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/history_tab_filter_trend_test.dart
```

Expected: FAIL because filtered export UI does not exist yet.

- [ ] **Step 3: Implement minimal UI and export behavior**

Update `HistoryTab` so the top export action receives `filteredHistory`, is disabled when the filtered list is empty, and shares only those records. The label/tooltip should say selected/filtered history when filters are active.

- [ ] **Step 4: Run GREEN and regression**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/history_tab_filter_trend_test.dart test/assessment_export_service_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit requirement 14**

```bash
git add lib/screens/main/history_tab.dart test/history_tab_filter_trend_test.dart
git commit -m "Export filtered history records"
```

### Task 2: Requirement 15 - Automated Critical Flow Tests

**Files:**
- Modify: `test/history_tab_filter_trend_test.dart`
- Modify if needed: `test/assessment_export_service_test.dart`

**Interfaces:**
- Consumes: saved history records, existing export service, existing widget tests.
- Produces: automated coverage for filtered export, no-match history state, and CSV history export expectations.

- [ ] **Step 1: Write failing/expanded tests**

Add focused tests for:
- no-match filtered state keeps export disabled and shows a clear empty message;
- all-history CSV preserves record selection and profile mapping for multiple farmers.

- [ ] **Step 2: Run RED where behavior is missing**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/history_tab_filter_trend_test.dart test/assessment_export_service_test.dart
```

Expected: tests for missing UI behavior fail before code is adjusted; service-only expectations may already pass if existing code is correct.

- [ ] **Step 3: Implement only required adjustments**

If a test exposes missing UI behavior, adjust `HistoryTab`. If service behavior already passes, keep production service unchanged.

- [ ] **Step 4: Run full relevant verification**

Run:

```bash
/Users/kpc/develop/flutter/bin/flutter test test/history_tab_filter_trend_test.dart test/assessment_export_service_test.dart test/app_state_evaluation_persistence_test.dart test/daily_prediction_screen_test.dart test/daily_injury_prediction_service_test.dart
/Users/kpc/develop/flutter/bin/flutter analyze lib test
```

Expected: PASS and no analyzer issues.

- [ ] **Step 5: Commit requirement 15**

```bash
git add test/history_tab_filter_trend_test.dart test/assessment_export_service_test.dart lib/screens/main/history_tab.dart
git commit -m "Expand critical history automation tests"
```
