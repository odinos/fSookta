# Recommendation Catalog and Approved Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** สร้างคลังคำแนะนำกลางและคำแปลอังกฤษที่ผ่านการอนุมัติครบ 100% แล้วเชื่อมกับหน้าจอ TTS ประวัติ รายงาน และไฟล์ส่งออก โดยไม่เปลี่ยนผลคำนวณหรือ ML

**Architecture:** ใช้ CSV ที่ตรวจสอบได้เป็น editorial source of truth และสร้าง immutable Dart Catalog จากเฉพาะแถวที่ได้รับอนุมัติแล้ว กฎเดิมยังเลือก `selection_key` และใช้ improvement effect เดิม ส่วน Catalog แปลง key กับบริบทเป็น display items ภาษาไทย/อังกฤษ จุดหยุดบังคับอยู่ก่อนงาน integration: ห้ามเริ่ม Task 5 จน Translation Review ผ่าน 100% และผู้ใช้อนุมัติ

**Tech Stack:** Flutter/Dart 3.4+, Python 3 standard library สำหรับ validation/generation, `@oai/artifact-tool` สำหรับ review workbook, Flutter widget/unit tests, local iOS Simulator และ Android build tools

## Global Constraints

- ขอบเขตรอบนี้คือ recommendation และ localization เท่านั้น
- ห้ามเปลี่ยนสูตร REBA, ISO 11228, combined risk, body-part risk, before/after score และ economic impact
- ห้ามเปลี่ยน XGBoost, ONNX, Daily Logistic, MoveNet หรือ feature schema
- ห้าม train ML
- Internal key, enum, field name และ research/training export schema คงภาษาอังกฤษ
- ข้อความไทยต้องตรวจสอบย้อนกลับถึงเอกสารผู้ว่าจ้าง
- English user-facing copy ในขอบเขตรอบนี้ต้องสมบูรณ์และ `approved` ครบ 100% ก่อนเริ่ม Task 5
- English mode ห้ามมี Thai fallback, draft, internal key หรือข้อความที่ยังไม่อนุมัติ
- หน้าจอ TTS รายงาน และ user-facing export ใช้ข้อความจาก Catalog ชุดเดียวกัน
- iOS และ Android ใช้ Catalog และ Dart selection logic ชุดเดียวกัน
- Selection key, selected-action persistence และ improvement effect เดิมต้องไม่เปลี่ยน
- App integration ใช้ generated immutable Dart Catalog เพื่อลดผลกระทบต่อ startup; CSV และ review workbook เป็นแหล่งตรวจแก้
- เอกสารต้นฉบับที่มีข้อจำกัดด้านลิขสิทธิ์ไม่ถูก commit

---

## File Structure

### Editorial and audit data

- Create: `data/recommendations/source_registry.json` — ทะเบียนเอกสาร path, SHA-256, page count และบทบาท
- Create: `data/recommendations/baseline_model_hashes.json` — baseline hashes ที่ห้ามเปลี่ยน
- Create: `data/recommendations/recommendation_master.csv` — Thai source text, context, source locator และ stable IDs
- Create: `data/recommendations/translation_review.csv` — bilingual review, automated checks และ approval status
- Create: `data/recommendations/reports/current_app_comparison.csv` — เทียบข้อความปัจจุบันกับต้นฉบับ
- Create: `data/recommendations/reports/conflicts_missing_sources.csv` — conflict และข้อความที่ไม่มีหลักฐาน
- Create: `docs/reviews/Sookta_Recommendation_Translation_Review_2026-07-29.xlsx` — เอกสารที่ผู้ใช้ตรวจ

### Offline tooling

- Create: `tools/recommendations/validate_sources.py` — ตรวจไฟล์ต้นทางและ hashes
- Create: `tools/recommendations/validate_recommendations.py` — ตรวจ schema, source coverage, translation parity และ approval gate
- Create: `tools/recommendations/build_translation_review_workbook.mjs` — สร้าง workbook สำหรับรีวิว
- Create: `tools/recommendations/build_recommendation_catalog.py` — สร้าง generated Dart Catalog หลังอนุมัติ
- Create: `tools/recommendations/test_validate_sources.py`
- Create: `tools/recommendations/test_validate_recommendations.py`
- Create: `tools/recommendations/test_build_recommendation_catalog.py`

### Runtime catalog

- Create: `lib/core/recommendations/recommendation_catalog_models.dart` — immutable catalog models และ language enum
- Create: `lib/core/recommendations/generated_recommendation_catalog.dart` — generated approved data, version และ checksum
- Create: `lib/core/services/recommendation_catalog_service.dart` — resolve key/context/language และ legacy aliases
- Create: `test/recommendation_catalog_service_test.dart`

### Existing application integration

- Modify: `lib/core/services/risk_recommendation_service.dart` — คง selection logic แต่เอา hard-coded display text ออก
- Modify: `lib/core/localization/sookta_strings.dart` — ให้ recommendation keys resolve ผ่าน Catalog และลบ duplicate action text
- Modify: `lib/screens/main/initial_risk_screen.dart` — ใช้ Catalog display items โดย checkbox ยังผูก selection key เดิม
- Modify: `lib/screens/main/final_result_screen.dart` — ใช้ approved copy, บันทึก keys และส่ง export ด้วย locale ที่เลือก
- Modify: `lib/screens/main/history_detail_screen.dart` — resolve selected keys/legacy aliases ตาม locale
- Modify: `lib/app/app_state.dart` — เพิ่ม optional `selectedSuggestionKeys` โดยคง legacy `selectedSuggestions`
- Modify: `lib/core/services/assessment_export_service.dart` — localize recommendation sections; ไม่เปลี่ยน numeric/research schema
- Modify: `test/risk_recommendation_service_test.dart`
- Modify: `test/final_result_farmer_summary_test.dart`
- Modify: `test/platform_ui_parity_test.dart`
- Create: `test/recommendation_history_localization_test.dart`
- Create: `test/recommendation_export_localization_test.dart`
- Create: `test/recommendation_core_regression_test.dart`

## Interfaces

```dart
enum RecommendationLanguage { th, en }

class RecommendationCatalogItem {
  const RecommendationCatalogItem({
    required this.id,
    required this.selectionKey,
    required this.displayOrder,
    required this.category,
    required this.activity,
    required this.bodyPart,
    required this.riskLevel,
    required this.thaiText,
    required this.englishText,
    required this.sourceId,
    required this.sourcePage,
  });
}

class RecommendationCatalogService {
  static List<RecommendationCatalogItem> resolve({
    required String selectionKey,
    required RecommendationLanguage language,
    String? activity,
    String? bodyPart,
    String? riskLevel,
  });

  static String joinedText({
    required String selectionKey,
    required RecommendationLanguage language,
    String? activity,
    String? bodyPart,
    String? riskLevel,
  });

  static String? tryJoinedText({
    required String selectionKey,
    required RecommendationLanguage language,
    String? activity,
    String? bodyPart,
    String? riskLevel,
  });

  static String? selectionKeyForLegacyText(String text);
}

extension EvaluationHistoryRecommendationLocalization
    on EvaluationHistoryRecord {
  List<String> localizedSelectedSuggestions(
    RecommendationLanguage language,
  );
}
```

`resolve` ต้องเลือก context ที่เฉพาะที่สุด เรียง `displayOrder` และคืนเฉพาะ
ข้อความที่มีไทยและอังกฤษอนุมัติครบแล้ว Generated Catalog ต้องไม่บรรจุ draft
หรือแถวที่ไม่ใช่ `approved`

---

### Task 1: Freeze Source and Model Integrity Baselines

**Files:**
- Create: `data/recommendations/source_registry.json`
- Create: `data/recommendations/baseline_model_hashes.json`
- Create: `tools/recommendations/validate_sources.py`
- Test: `tools/recommendations/test_validate_sources.py`

**Interfaces:**
- Consumes: เอกสารต้นทาง 5 ไฟล์ตาม design spec
- Produces: `validate_registry(registry_path: Path) -> list[str]`; empty list หมายถึงผ่าน

- [ ] **Step 1: Write the failing source-integrity test**

```python
from pathlib import Path
import unittest

from validate_sources import validate_registry


class SourceRegistryTest(unittest.TestCase):
    def test_registered_sources_exist_and_match_sha256(self):
        errors = validate_registry(
            Path("data/recommendations/source_registry.json")
        )
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test and verify it fails because the registry and validator do not exist**

Run:

```bash
python3 -m unittest tools/recommendations/test_validate_sources.py -v
```

Expected: FAIL with import/file-not-found error.

- [ ] **Step 3: Add the registry with the five approved source records**

Use these exact source IDs and hashes:

```json
{
  "registryVersion": "2026-07-29.1",
  "sources": [
    {
      "id": "body_map_recommendations",
      "localPath": "/Users/kpc/Documents/TestSookta/Calibtation/ชุดคำแนะนำตามความเสี่ยง Body map.pdf",
      "sha256": "fee5c283139b78f605edf18a40fd1d5b4a48893f8e0aa9b3a037630944cb4d2c",
      "pageCount": 8,
      "priority": 1
    },
    {
      "id": "app_recommendations_v3",
      "localPath": "/Users/kpc/Documents/Doc/fortrain/คำแนะนำแต่ละดับความเสี่ยงใน app Ref. ISO11228, REBA V3.pdf",
      "sha256": "ec80da8a80a4c9fee6255b2787ae86c79fdddef69b53574eab07bb43fcab87b5",
      "pageCount": 10,
      "priority": 2
    },
    {
      "id": "ilo_ergonomic_checkpoints_agriculture",
      "localPath": "/Users/kpc/Documents/Doc/fortrain/wcms_168042.pdf",
      "sha256": "3ca8a3c621ad6efb58e818de8c5d64ec257bb13c74f191e96c5f60d4d47acf8e",
      "pageCount": 261,
      "priority": 3
    },
    {
      "id": "reba_employee_assessment_worksheet",
      "localPath": "/Users/kpc/Documents/Doc/REBA.pdf",
      "sha256": "b23cf52703aacf6cd348f81044f91672cc7bf50f5273be82243d4a11a95155e8",
      "pageCount": 1,
      "priority": 4
    },
    {
      "id": "iso11228_pirawan_project_workbook",
      "localPath": "/Users/kpc/Documents/Doc/ISO11228 Pirawan.xlsx",
      "sha256": "980930d38680ffe215dda38cabe5985fe205b63ade112db63cd9a0a844b16342",
      "priority": 5
    }
  ]
}
```

Add `title`, `language`, `documentRole`, and
`copyrightOrDistributionNote` to every record before saving.

- [ ] **Step 4: Implement SHA-256 and existence validation**

```python
def validate_registry(registry_path: Path) -> list[str]:
    payload = json.loads(registry_path.read_text(encoding="utf-8"))
    errors: list[str] = []
    for source in payload["sources"]:
        path = Path(source["localPath"])
        if not path.is_file():
            errors.append(f"missing:{source['id']}")
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != source["sha256"]:
            errors.append(f"sha256:{source['id']}:{digest}")
    return errors
```

- [ ] **Step 5: Record model hashes without changing the artifacts**

Hash these files into `baseline_model_hashes.json`:

```text
assets/models/xgboost_model.onnx
assets/models/xgboost_model_metadata.json
assets/ml/daily_injury_logistic_model.json
assets/ml/movenet_thunder.tflite
assets/ml/movenet_multipose_lightning.tflite
```

- [ ] **Step 6: Run the tests**

```bash
python3 -m unittest tools/recommendations/test_validate_sources.py -v
```

Expected: PASS and no source/hash errors.

- [ ] **Step 7: Commit the audit baseline**

```bash
git add data/recommendations/source_registry.json data/recommendations/baseline_model_hashes.json tools/recommendations/validate_sources.py tools/recommendations/test_validate_sources.py
git commit -m "docs: register recommendation source baselines"
```

---

### Task 2: Build the Thai Recommendation Master and Comparison Reports

**Files:**
- Create: `data/recommendations/recommendation_master.csv`
- Create: `data/recommendations/reports/current_app_comparison.csv`
- Create: `data/recommendations/reports/conflicts_missing_sources.csv`
- Create: `tools/recommendations/validate_recommendations.py`
- Test: `tools/recommendations/test_validate_recommendations.py`

**Interfaces:**
- Consumes: `source_registry.json`, `RiskRecommendationService.allKeys`, current `act_*` strings
- Produces: `validate_master(master_path: Path, registry_path: Path) -> list[str]`

- [ ] **Step 1: Write failing schema and coverage tests**

```python
REQUIRED_MASTER_COLUMNS = {
    "recommendation_id",
    "selection_key",
    "display_order",
    "record_type",
    "category",
    "activity",
    "body_part",
    "risk_level",
    "trigger_condition",
    "thai_source_text",
    "source_id",
    "source_page",
    "source_section",
    "source_priority",
    "catalog_version",
    "record_status",
    "legacy_text_th",
    "legacy_text_en",
}


class RecommendationMasterTest(unittest.TestCase):
    def test_master_has_required_columns_and_source_for_every_row(self):
        errors = validate_master(
            Path("data/recommendations/recommendation_master.csv"),
            Path("data/recommendations/source_registry.json"),
        )
        self.assertEqual(errors, [])
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
python3 -m unittest tools/recommendations/test_validate_recommendations.py -v
```

Expected: FAIL because the master and validator are missing.

- [ ] **Step 3: Populate the master from the approved source hierarchy**

Use:

- Body Map PDF pages 1-8 for neck, trunk, arms, wrists, legs and manual handling
- V3 PDF pages 1-3 and 6-9 for six activities and source mapping
- ILO checkpoints 1, 4, 7, 12, 17, 18, 22, 24, 25, 28, 92 and 99 as evidence
- REBA worksheet only for risk-level provenance, not new advice

Rules:

```text
record_type = recommendation | ui_copy | system_message
activity = transplanting | fertilizing | pesticide | pruning | harvesting | transport | any
body_part = neck | trunk | arms | wrists | legs | manual | any
risk_level = low | medium | high | very_high | any
record_status = source_verified | conflict | missing_source
```

Split multi-action source paragraphs into ordered atomic display items while
keeping the existing `selection_key`. Use IDs such as
`act_body_neck_high.01`, `act_body_neck_high.02`; do not change the
selection key itself.

- [ ] **Step 4: Add every user-facing copy item touched by this feature**

Include category headings, recommendation-card instructions, empty/error
messages, TTS-visible text, report/export section labels, and the message
shown when an old persisted string cannot be mapped. Existing unrelated app
copy remains outside this feature scope.

- [ ] **Step 5: Implement master validation**

```python
def validate_master(master_path: Path, registry_path: Path) -> list[str]:
    rows = list(csv.DictReader(master_path.open(encoding="utf-8-sig")))
    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    source_ids = {item["id"] for item in registry["sources"]}
    errors: list[str] = []
    seen_ids: set[str] = set()
    seen_orders: set[tuple[str, str]] = set()
    for index, row in enumerate(rows, start=2):
        missing = REQUIRED_MASTER_COLUMNS - set(row)
        if missing:
            errors.append(f"columns:{sorted(missing)}")
            break
        if row["recommendation_id"] in seen_ids:
            errors.append(f"duplicate_id:{row['recommendation_id']}")
        seen_ids.add(row["recommendation_id"])
        order_key = (row["selection_key"], row["display_order"])
        if order_key in seen_orders:
            errors.append(f"duplicate_order:{order_key}")
        seen_orders.add(order_key)
        if row["source_id"] not in source_ids:
            errors.append(f"source:{index}:{row['source_id']}")
        if not row["thai_source_text"].strip():
            errors.append(f"thai:{index}")
    return errors
```

- [ ] **Step 6: Produce the comparison and conflict reports**

`current_app_comparison.csv` columns:

```text
selection_key,current_th,current_en,source_th,comparison_status,impact_on_selection,review_note
```

`conflicts_missing_sources.csv` columns:

```text
recommendation_id,selection_key,issue_type,source_a,source_b,conflicting_value,proposed_action,approval_status
```

Set `proposed_action=hold_from_catalog` for every unresolved conflict.

- [ ] **Step 7: Run validation**

```bash
python3 -m unittest tools/recommendations/test_validate_recommendations.py -v
python3 tools/recommendations/validate_recommendations.py --master data/recommendations/recommendation_master.csv --registry data/recommendations/source_registry.json
```

Expected: PASS for schema/source coverage; unresolved rows remain visible in
the report and are not eligible for the Catalog.

- [ ] **Step 8: Commit the Thai source audit**

```bash
git add data/recommendations/recommendation_master.csv data/recommendations/reports tools/recommendations/validate_recommendations.py tools/recommendations/test_validate_recommendations.py
git commit -m "docs: add source-backed Thai recommendation master"
```

---

### Task 3: Create the Complete English Translation Review

**Files:**
- Create: `data/recommendations/translation_review.csv`
- Create: `tools/recommendations/build_translation_review_workbook.mjs`
- Modify: `tools/recommendations/validate_recommendations.py`
- Modify: `tools/recommendations/test_validate_recommendations.py`
- Create: `docs/reviews/Sookta_Recommendation_Translation_Review_2026-07-29.xlsx`

**Interfaces:**
- Consumes: every source-verified master row
- Produces: `validate_translation_review(...) -> list[str]` and a visually reviewed workbook

- [ ] **Step 1: Write failing translation parity tests**

```python
class TranslationReviewTest(unittest.TestCase):
    def test_every_master_item_has_one_translation_review_row(self):
        errors = validate_translation_review(
            Path("data/recommendations/recommendation_master.csv"),
            Path("data/recommendations/translation_review.csv"),
            require_approved=False,
        )
        self.assertEqual(errors, [])

    def test_approval_gate_fails_while_any_row_is_pending(self):
        errors = validate_translation_review(
            Path("data/recommendations/recommendation_master.csv"),
            Path("data/recommendations/translation_review.csv"),
            require_approved=True,
        )
        self.assertIn("approval_coverage_below_100", errors)
```

- [ ] **Step 2: Run the tests and verify they fail**

```bash
python3 -m unittest tools/recommendations/test_validate_recommendations.py -v
```

Expected: FAIL because the review file is missing.

- [ ] **Step 3: Create one bilingual review row per master item**

Required columns:

```text
recommendation_id,selection_key,record_type,thai_source_text,english_draft,translation_style,numbers_match,units_match,timing_match,urgency_match,negation_match,meaning_review,review_comment,approval_status,approved_by,approved_at,translation_version,source_id,source_page
```

Use `direct` by default. Use `plain_english` only when a literal version is
hard to understand. Preserve every number, range, unit, prohibition and
urgency term.

- [ ] **Step 4: Implement automated parity checks**

```python
from collections import Counter

NUMBER_RE = re.compile(r"\d+(?:\.\d+)?")
UNIT_RE = re.compile(
    r"(กก\.|กิโลกรัม|kg|ซม\.|cm|เมตร|m|นาที|minute|ชั่วโมง|hour|องศา|degree)",
    re.IGNORECASE,
)


def normalized_numbers(text: str) -> list[str]:
    return NUMBER_RE.findall(text.replace("–", "-"))


def validate_pair(row: dict[str, str]) -> list[str]:
    errors: list[str] = []
    if Counter(normalized_numbers(row["thai_source_text"])) != Counter(
        normalized_numbers(row["english_draft"])
    ):
        errors.append(f"numbers:{row['recommendation_id']}")
    if not row["english_draft"].strip():
        errors.append(f"english:{row['recommendation_id']}")
    return errors
```

Record human checks separately for units, timing, urgency, negation and
meaning; automated checks do not mark those fields approved.

- [ ] **Step 5: Build the review workbook**

The workbook must contain:

- `Translation Review` — Thai and English side by side with filters
- `Source Register` — document roles and hashes
- `Conflicts` — held rows
- `Coverage` — formulas for total, approved, pending, rejected, needs revision and approval percentage
- `Instructions` — approval rules in Thai

Use formulas in `Coverage`, including:

```excel
=COUNTA('Translation Review'!A2:A1000)
=COUNTIF('Translation Review'!N2:N1000,"approved")
=IF(B2=0,0,B3/B2)
```

- [ ] **Step 6: Render every workbook sheet and inspect it**

Use the spreadsheet workflow to render all populated sheets. Verify:

- Thai and English are fully visible
- source page and status columns are visible
- approval percentage is formula-driven
- no formula errors
- no text is clipped

- [ ] **Step 7: Run pre-approval validation**

```bash
python3 tools/recommendations/validate_recommendations.py --master data/recommendations/recommendation_master.csv --translations data/recommendations/translation_review.csv
```

Expected: structural/parity checks PASS; approval gate intentionally remains
closed while rows are pending.

- [ ] **Step 8: Commit review artifacts without touching app code**

```bash
git add data/recommendations/translation_review.csv docs/reviews/Sookta_Recommendation_Translation_Review_2026-07-29.xlsx tools/recommendations/build_translation_review_workbook.mjs tools/recommendations/validate_recommendations.py tools/recommendations/test_validate_recommendations.py
git commit -m "docs: prepare complete recommendation translation review"
```

---

### Task 4: Mandatory Human Translation Approval Gate

**Files:**
- Modify: `data/recommendations/translation_review.csv`
- Regenerate: `docs/reviews/Sookta_Recommendation_Translation_Review_2026-07-29.xlsx`
- Modify when resolved: `data/recommendations/reports/conflicts_missing_sources.csv`

**Interfaces:**
- Consumes: complete bilingual review
- Produces: 100% approved English coverage; unlocks Task 5

- [ ] **Step 1: Deliver the workbook to the user and stop**

Do not create `generated_recommendation_catalog.dart`, do not modify `lib/`,
and do not start integration while waiting.

- [ ] **Step 2: Apply every user correction to both CSV and workbook**

For each approved row set:

```text
approval_status=approved
approved_by=ชื่อผู้ตรวจที่ผู้ใช้ระบุในรอบตรวจข้อความ
approved_at=วันและเวลาจริงของการอนุมัติในรูปแบบ ISO-8601 พร้อมเขตเวลา
translation_version=1
meaning_review=pass
```

Do not infer reviewer identity; use the name the user supplies at review time.

- [ ] **Step 3: Resolve or hold every conflict**

Rows still marked `conflict`, `missing_source`, `rejected`, `pending`, or
`needs_revision` must not progress. If any remain, return to the user with the
exact rows and keep the gate closed.

- [ ] **Step 4: Run the hard approval validator**

```bash
python3 tools/recommendations/validate_recommendations.py --master data/recommendations/recommendation_master.csv --translations data/recommendations/translation_review.csv --require-approved
```

Expected:

```text
approval_coverage=100.00%
pending=0
rejected=0
needs_revision=0
conflict=0
PASS
```

- [ ] **Step 5: Regenerate and visually inspect the final workbook**

The Coverage sheet must show 100%. Reopen the workbook and inspect all sheets
after regeneration.

- [ ] **Step 6: Ask the user for explicit final approval to start app development**

Task 5 remains blocked until the user explicitly approves the final bilingual
workbook after corrections.

- [ ] **Step 7: Commit the approved translation baseline**

```bash
git add data/recommendations/translation_review.csv data/recommendations/reports/conflicts_missing_sources.csv docs/reviews/Sookta_Recommendation_Translation_Review_2026-07-29.xlsx
git commit -m "docs: approve complete recommendation translations"
```

---

### Task 5: Generate the Immutable Runtime Catalog

**Precondition:** Task 4 approval coverage is 100% and the user explicitly approved development.

**Files:**
- Create: `lib/core/recommendations/recommendation_catalog_models.dart`
- Create: `lib/core/recommendations/generated_recommendation_catalog.dart`
- Create: `lib/core/services/recommendation_catalog_service.dart`
- Create: `tools/recommendations/build_recommendation_catalog.py`
- Test: `tools/recommendations/test_build_recommendation_catalog.py`
- Test: `test/recommendation_catalog_service_test.dart`

**Interfaces:**
- Consumes: approved master and translation CSV
- Produces: interfaces listed in the plan header

- [ ] **Step 1: Write failing generator tests**

```python
class CatalogGeneratorTest(unittest.TestCase):
    def test_generator_rejects_non_approved_rows(self):
        with self.assertRaisesRegex(ValueError, "approval coverage must be 100%"):
            build_catalog(master_rows, [{"approval_status": "pending"}])

    def test_generated_catalog_contains_no_pending_or_draft_text(self):
        dart = build_catalog(master_rows, approved_rows)
        self.assertNotIn("pending", dart)
        self.assertNotIn("english_draft", dart)
```

- [ ] **Step 2: Run the Python test and verify it fails**

```bash
python3 -m unittest tools/recommendations/test_build_recommendation_catalog.py -v
```

Expected: FAIL because the generator does not exist.

- [ ] **Step 3: Write failing Dart resolver tests**

```dart
test('resolves exact activity and risk context in both approved languages', () {
  final th = RecommendationCatalogService.resolve(
    selectionKey: 'act_rest_stretch',
    language: RecommendationLanguage.th,
    activity: 'pruning',
    riskLevel: 'high',
  );
  final en = RecommendationCatalogService.resolve(
    selectionKey: 'act_rest_stretch',
    language: RecommendationLanguage.en,
    activity: 'pruning',
    riskLevel: 'high',
  );

  expect(th, isNotEmpty);
  expect(en, hasLength(th.length));
  expect(en.every((item) => item.englishText.trim().isNotEmpty), isTrue);
});
```

- [ ] **Step 4: Run the Dart test and verify it fails**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/recommendation_catalog_service_test.dart
```

Expected: FAIL because catalog types/service do not exist.

- [ ] **Step 5: Implement immutable models**

Use the exact interfaces in the plan header. Add:

```dart
String text(RecommendationLanguage language) {
  return switch (language) {
    RecommendationLanguage.th => thaiText,
    RecommendationLanguage.en => englishText,
  };
}
```

- [ ] **Step 6: Implement the generator**

The generator must:

1. require 100% approval,
2. sort by `selection_key`, context specificity and `display_order`,
3. escape Dart strings,
4. emit catalog version and SHA-256 checksum,
5. emit legacy Thai/English aliases for history compatibility,
6. exclude review comments, drafts and reviewer notes.

- [ ] **Step 7: Implement context resolution**

Specificity order:

```text
exact activity + exact body_part + exact risk_level
exact activity + any body_part + exact risk_level
any activity + exact body_part + exact risk_level
exact activity + any body_part + any risk_level
any activity + exact body_part + any risk_level
all context fields = any
```

Return all rows at the best available specificity, ordered by
`displayOrder`. Do not merge lower-priority context rows.

- [ ] **Step 8: Generate and format the Catalog**

```bash
python3 tools/recommendations/build_recommendation_catalog.py --master data/recommendations/recommendation_master.csv --translations data/recommendations/translation_review.csv --output lib/core/recommendations/generated_recommendation_catalog.dart
/Users/kpc/develop/flutter/bin/dart format lib/core/recommendations
```

- [ ] **Step 9: Run generator and resolver tests**

```bash
python3 -m unittest tools/recommendations/test_build_recommendation_catalog.py -v
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/recommendation_catalog_service_test.dart
```

Expected: PASS.

- [ ] **Step 10: Commit the runtime Catalog**

```bash
git add lib/core/recommendations lib/core/services/recommendation_catalog_service.dart tools/recommendations/build_recommendation_catalog.py tools/recommendations/test_build_recommendation_catalog.py test/recommendation_catalog_service_test.dart
git commit -m "feat: add approved recommendation catalog"
```

---

### Task 6: Move Recommendation Display Text Behind the Catalog

**Files:**
- Modify: `lib/core/services/risk_recommendation_service.dart`
- Modify: `lib/core/localization/sookta_strings.dart`
- Modify: `lib/screens/main/initial_risk_screen.dart`
- Modify: `lib/screens/main/final_result_screen.dart`
- Modify: `test/risk_recommendation_service_test.dart`
- Modify: `test/final_result_farmer_summary_test.dart`

**Interfaces:**
- Consumes: `RecommendationCatalogService.resolve` and `joinedText`
- Produces: unchanged selection keys/categories/effects with approved display text

- [ ] **Step 1: Add a failing selection-regression test**

```dart
test('catalog migration preserves selection keys and category counts', () {
  final items = RiskRecommendationService.farmerRecommendations(
    activity: SooktaActivity.fertilizing,
    riskLevel: RiskLevel.high,
    bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
    thai: false,
  );

  expect(items.map((item) => item.sourceKey), containsAll(<String>[
    'act_use_legs',
    'act_fert_split_load',
    'act_rest_stretch',
    'act_extra_fert_cart',
  ]));
  expect(items.every((item) => item.text.trim().isNotEmpty), isTrue);
});
```

- [ ] **Step 2: Run focused tests and verify the new Catalog expectations fail**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/risk_recommendation_service_test.dart test/final_result_farmer_summary_test.dart
```

- [ ] **Step 3: Replace hard-coded recommendation text with Catalog resolution**

Keep the switches that choose `sourceKey`. Replace each text switch with:

```dart
final text = RecommendationCatalogService.joinedText(
  selectionKey: sourceKey,
  language: thai
      ? RecommendationLanguage.th
      : RecommendationLanguage.en,
  activity: activity.name,
  riskLevel: riskLevel.name,
);
```

For body-specific entries pass `bodyPart: part.name`. Deduplicate by
`category.name:sourceKey`, not localized text.

- [ ] **Step 4: Route legacy `SooktaStrings.get('act_*')` through the Catalog**

Before table fallback:

```dart
final catalogText = RecommendationCatalogService.tryJoinedText(
  selectionKey: key,
  language: locale == SooktaLocale.th
      ? RecommendationLanguage.th
      : RecommendationLanguage.en,
);
if (catalogText != null) return catalogText;
```

Remove duplicate `act_*` display strings only after every call site test
passes. Keep non-recommendation strings unchanged.

- [ ] **Step 5: Keep one checkbox per selection key**

If a key resolves to multiple atomic display items, render them as multiple
lines inside the same checkbox title. `selectedKeys`, `_actionFor`, and
score-reduction behavior continue to use `sourceKey`.

- [ ] **Step 6: Run focused tests**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/risk_recommendation_service_test.dart test/final_result_farmer_summary_test.dart test/initial_risk_confirmation_test.dart
```

Expected: PASS with unchanged selection keys and approved English text.

- [ ] **Step 7: Commit display migration**

```bash
git add lib/core/services/risk_recommendation_service.dart lib/core/localization/sookta_strings.dart lib/screens/main/initial_risk_screen.dart lib/screens/main/final_result_screen.dart test/risk_recommendation_service_test.dart test/final_result_farmer_summary_test.dart
git commit -m "feat: resolve recommendation copy from catalog"
```

---

### Task 7: Localize History, TTS, Reports, and User-Facing Exports

**Files:**
- Modify: `lib/app/app_state.dart`
- Modify: `lib/screens/main/final_result_screen.dart`
- Modify: `lib/screens/main/history_detail_screen.dart`
- Modify: `lib/core/services/assessment_export_service.dart`
- Create: `test/recommendation_history_localization_test.dart`
- Create: `test/recommendation_export_localization_test.dart`
- Modify: `test/tts_button_voice_quality_test.dart`

**Interfaces:**
- Consumes: Catalog resolver and legacy alias lookup
- Produces: optional persisted `selectedSuggestionKeys`; locale-correct history/TTS/export

- [ ] **Step 1: Write a failing backward-compatibility test**

```dart
test('old stored recommendation text resolves to approved English', () {
  final oldRecord = EvaluationHistoryRecord.fromJson(<String, Object?>{
    'id': 1,
    'activityName': 'การใส่ปุ๋ย',
    'dateTime': '2026-07-29T10:00:00+07:00',
    'scoreBefore': 8,
    'scoreAfter': 6,
    'riskBefore': 'high',
    'riskAfter': 'medium',
    'economicLoss': 1000,
    'moneySaved': 280,
    'selectedSuggestions': <String>['ลดน้ำหนักปุ๋ยต่อครั้ง'],
    'bodyPartRisks': <String, String>{'trunk': 'high'},
  });

  final texts = oldRecord.localizedSelectedSuggestions(
    RecommendationLanguage.en,
  );
  expect(texts, isNotEmpty);
  expect(texts.every((text) => !RegExp(r'[ก-๙]').hasMatch(text)), isTrue);
});
```

- [ ] **Step 2: Write a failing export-language test**

```dart
test('English user export contains approved English recommendations only', () {
  final csv = AssessmentExportService.buildHistoryRecordCsv(
    record: recordWithSelectionKeys,
    profile: const UserProfile(),
    thai: false,
  );
  expect(csv, contains('Selected recommendations'));
  expect(RegExp(r'[ก-๙]').hasMatch(csv), isFalse);
});
```

- [ ] **Step 3: Run the tests and verify they fail**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/recommendation_history_localization_test.dart test/recommendation_export_localization_test.dart
```

- [ ] **Step 4: Add optional key persistence without deleting legacy text**

Add:

```dart
final List<String> selectedSuggestionKeys;
```

to `EvaluationHistoryRecord`, defaulting to `const []` in `fromJson`. Write
`selectedSuggestionKeys` in `toJson`. Keep `selectedSuggestions` unchanged
for old data compatibility and research traceability.

Update `saveEvaluation` to accept both:

```dart
required List<String> selectedSuggestionKeys,
required List<String> selectedSuggestions,
```

New records persist keys plus current approved display text.

- [ ] **Step 5: Add localized history resolution**

Resolution order:

1. `selectedSuggestionKeys`,
2. exact legacy-text alias lookup,
3. approved `system_message.unmapped_saved_recommendation`.

Never display an unknown Thai legacy string in English mode.
Implement the exact
`EvaluationHistoryRecommendationLocalization.localizedSelectedSuggestions`
extension declared in the plan header; do not add a second localization path.

- [ ] **Step 6: Localize TTS from the same resolved list**

History and result TTS receive the exact strings rendered on screen and
`thai=false` in English mode. Do not modify voice-selection logic.

- [ ] **Step 7: Localize user-facing export and keep research schema unchanged**

Use Catalog resolution for:

- selected-recommendation section values,
- recommendation-related labels introduced or modified in this feature.

Do not change `_worksheetRows` technical field names, training exports,
numeric values, formulas, or column order.

- [ ] **Step 8: Run history/export/TTS tests**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/recommendation_history_localization_test.dart test/recommendation_export_localization_test.dart test/tts_button_voice_quality_test.dart
```

Expected: PASS; English output contains no Thai recommendation copy.

- [ ] **Step 9: Commit cross-surface localization**

```bash
git add lib/app/app_state.dart lib/screens/main/final_result_screen.dart lib/screens/main/history_detail_screen.dart lib/core/services/assessment_export_service.dart test/recommendation_history_localization_test.dart test/recommendation_export_localization_test.dart test/tts_button_voice_quality_test.dart
git commit -m "feat: localize recommendations across saved outputs"
```

---

### Task 8: Prove Core Regression and iOS/Android Parity

**Files:**
- Create: `test/recommendation_core_regression_test.dart`
- Modify: `test/platform_ui_parity_test.dart`
- Modify: `docs/reviews/local-platform-ml-remediation-result-2026-07-29.md`

**Interfaces:**
- Consumes: completed Catalog integration and baseline hashes
- Produces: numeric invariance, model integrity and cross-platform evidence

- [ ] **Step 1: Write a numeric regression test before final verification**

```dart
test('recommendation localization does not change calculation outputs', () {
  const rebaInput = RebaInputData(
    dailyIncome: 500,
    trunkScore: 5,
    neckScore: 2,
    legScore: 2,
    upperArmScore: 3,
    lowerArmScore: 2,
    wristScore: 2,
    loadScore: 2,
    couplingScore: 1,
    activityScore: 1,
  );
  const isoInput = ErgoInputData(
    jobType: JobType.lifting,
    loadWeight: 20,
    horizontalDist: 60,
    verticalHeight: 30,
    liftFrequency: 5,
    durationHours: 4,
    transportDistance: 12,
  );
  final before = ErgoCalculator.calculateRebaRisk(rebaInput);
  final iso = ErgoCalculator.calculateLiftingRisk(isoInput);

  RecommendationCatalogService.joinedText(
    selectionKey: 'act_rest_stretch',
    language: RecommendationLanguage.en,
    riskLevel: before.riskLevel.name,
  );

  final after = ErgoCalculator.calculateRebaRisk(rebaInput);
  final isoAfter = ErgoCalculator.calculateLiftingRisk(isoInput);

  expect(after.userScore, before.userScore);
  expect(after.riskLevel, before.riskLevel);
  expect(after.economicLoss, before.economicLoss);
  expect(isoAfter.userScore, iso.userScore);
  expect(isoAfter.riskLevel, iso.riskLevel);
});
```

These values intentionally duplicate the heavy-twist REBA and long-distance
lifting fixtures in `test/ergo_calculator_test.dart`, making the regression
test independently readable while preserving the existing expected inputs.

- [ ] **Step 2: Extend platform parity fixtures**

For Thai and English fixtures assert identical:

```text
selection keys
display-item IDs
category order
display text
TTS input
numeric scores
```

The expected English strings must come from the approved review baseline,
not be authored inside the test.

- [ ] **Step 3: Run all focused tests**

```bash
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/recommendation_catalog_service_test.dart test/risk_recommendation_service_test.dart test/recommendation_history_localization_test.dart test/recommendation_export_localization_test.dart test/recommendation_core_regression_test.dart test/platform_ui_parity_test.dart test/final_result_farmer_summary_test.dart test/ergo_calculator_test.dart test/daily_injury_prediction_service_test.dart test/ml_end_to_end_comprehensive_test.dart
```

Expected: PASS.

- [ ] **Step 4: Run static analysis**

```bash
/Users/kpc/develop/flutter/bin/flutter analyze --no-pub
```

Expected: no new errors or warnings.

- [ ] **Step 5: Recheck source and model hashes**

```bash
python3 tools/recommendations/validate_sources.py --registry data/recommendations/source_registry.json --model-baseline data/recommendations/baseline_model_hashes.json
```

Expected: all source and model hashes match; no ML artifact changed.

- [ ] **Step 6: Build both platforms locally**

```bash
/Users/kpc/develop/flutter/bin/flutter build apk --debug --no-pub
/Users/kpc/develop/flutter/bin/flutter build ios --simulator --debug --no-pub
```

Expected: both builds succeed with the same generated Catalog. If the local
sandbox blocks Flutter cache writes, rerun these exact commands with the
required local execution approval; do not change project dependencies to
work around the sandbox.

- [ ] **Step 7: Update the local review result**

Document:

- Translation approval coverage: 100%
- Thai/English Catalog row counts
- Core numeric regression results
- Model hash comparison
- iOS/Android build and parity results
- Explicit statement that no ML training occurred

- [ ] **Step 8: Run final diff-scope checks**

```bash
git diff --check
git diff --name-only
git status --short
```

Verify no model artifact, calculation service, native iOS file, or native
Android file changed.

- [ ] **Step 9: Commit verification evidence**

```bash
git add test/recommendation_core_regression_test.dart test/platform_ui_parity_test.dart docs/reviews/local-platform-ml-remediation-result-2026-07-29.md
git commit -m "test: verify recommendation localization parity"
```

---

## Final Acceptance Checklist

- [ ] Source Registry hashes pass
- [ ] Thai source coverage is complete
- [ ] Current-app comparison and conflicts are reviewed
- [ ] English copy is complete and approved at 100%
- [ ] User explicitly approved the final bilingual workbook before Task 5
- [ ] Generated Catalog contains no draft/pending/rejected text
- [ ] Selection keys and improvement effects are unchanged
- [ ] Existing history remains readable and English mode contains no Thai fallback
- [ ] Screen, TTS, report and user-facing export use the same approved copy
- [ ] Research/training export schema is unchanged
- [ ] REBA, ISO, economic impact and ML outputs are numerically unchanged
- [ ] Model artifact hashes are unchanged
- [ ] iOS and Android builds and parity tests pass
- [ ] No ML training occurred
