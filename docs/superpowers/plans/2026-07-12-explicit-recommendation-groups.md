# Explicit Recommendation Groups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render four stable farmer recommendation groups using structured category data rather than localized-text inference.

**Architecture:** Add a typed farmer recommendation category and item to `RiskRecommendationService`. Generate prioritized concise actions from the assessment inputs, pass them directly to the result card, and retain existing localized detailed strings for the staff expansion.

**Tech Stack:** Dart, Flutter Material, flutter_test, signed iOS Profile build.

## Global Constraints

- Do not change ergonomic scoring or risk classification.
- Show all four groups in the approved order, including empty groups.
- Show at most two short actions per group and one action per row.
- Preserve full recommendations under staff details.
- Keep UAT bypass enabled only through the existing compile-time flag.

---

### Task 1: Structured Farmer Recommendation Data

**Files:**
- Modify: `lib/core/services/risk_recommendation_service.dart`
- Test: `test/risk_recommendation_service_test.dart`

**Interfaces:**
- Consumes: `SooktaActivity`, `RiskLevel`, and `Map<BodyPart, RiskLevel>`.
- Produces: `FarmerRecommendationCategory`, `FarmerRecommendation`, and `RiskRecommendationService.farmerRecommendations(...)`.

- [ ] **Step 1: Write a failing service test**

Assert that fertilizing/high/trunk-high returns explicit posture, risk reduction, rest, and tool items; each item has a single category and text no longer than 70 characters.

- [ ] **Step 2: Run the focused test and verify RED**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/risk_recommendation_service_test.dart
```

Expected: failure because the structured API does not exist.

- [ ] **Step 3: Implement the structured recommendation API**

Add the enum/model and deterministic activity, risk-tier, body-part, rest, and tool mappings in Thai and English. Deduplicate by category/text and retain at most two items per category.

- [ ] **Step 4: Run the focused service test and verify GREEN**

Run the Step 2 command. Expected: all service tests pass.

### Task 2: Four Clearly Separated Result Groups

**Files:**
- Modify: `lib/screens/main/final_result_screen.dart`
- Test: `test/final_result_farmer_summary_test.dart`

**Interfaces:**
- Consumes: `List<FarmerRecommendation>` from Task 1.
- Produces: four always-visible category cards with one item per row.

- [ ] **Step 1: Write a failing widget test**

Assert that all four headings exist inside separate keyed group containers, every rendered item is a descendant of exactly one group, and long staff text is absent until staff details are expanded.

- [ ] **Step 2: Run the widget test and verify RED**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/final_result_farmer_summary_test.dart
```

Expected: failure because the current view infers groups from strings and hides empty groups.

- [ ] **Step 3: Render typed groups directly**

Remove clause splitting and keyword classification. Render the four enum values in order, use stable keys per group, and show the localized empty-state message when needed. Continue passing original detailed recommendation strings to `_TechnicalDetailsSection`.

- [ ] **Step 4: Verify focused tests and analysis**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/final_result_farmer_summary_test.dart test/risk_recommendation_service_test.dart
/Users/kpc/develop/flutter/bin/flutter analyze --no-pub lib/core/services/risk_recommendation_service.dart lib/screens/main/final_result_screen.dart test/risk_recommendation_service_test.dart test/final_result_farmer_summary_test.dart
```

Expected: all tests pass and analyzer reports no issues.

### Task 3: iPhone UAT Build

**Files:**
- Modify: `docs/uat-last-phase-20260712.md`

**Interfaces:**
- Consumes: verified Flutter implementation and existing UAT bypass flag.
- Produces: installed/launchable signed Profile build on the connected iPhone.

- [ ] **Step 1: Build the signed iOS Profile app with UAT bypass**

Use the established Xcode workspace, team `RN66WU3W56`, derived-data path `/private/tmp/fSookta-ios-uat-profile`, and the existing encoded `SOOKTA_UAT_BYPASS=true` define. Expected: build exits 0.

- [ ] **Step 2: Install and launch on the connected iPhone**

Use device `ABD658CA-9FDE-5F6E-8228-CFE6D830F4AE` and bundle `com.kdev.sookta`. Expected: install and launch succeed.

- [ ] **Step 3: Record user-observed UAT result**

Verify four distinct groups, one short action per row, readable spacing, and the full text under staff details. Record PASS or the exact remaining failure without starting Android UAT.
