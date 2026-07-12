# Explicit Recommendation Groups Design

## Goal

Make farmer recommendations visibly separated into four stable categories, with one short action per row, while preserving the original detailed recommendations for staff.

## Approved Presentation

The farmer result page always presents these four category cards in this order:

1. Posture to adjust (`ท่าทางที่ควรปรับ`)
2. Ways to reduce risk (`วิธีลดความเสี่ยง`)
3. Rest or task rotation (`การพักหรือสลับงาน`)
4. Tools or workload support (`อุปกรณ์ช่วยลดภาระงาน`)

Each card has its own heading, icon, border, and spacing. Each recommendation row contains exactly one concise action. Categories are assigned explicitly by recommendation data and must never be inferred from localized text.

## Data Design

Introduce a farmer-facing recommendation model containing a category and concise Thai/English text. `RiskRecommendationService` derives this structured list from activity, overall risk, body-part risks, and manual-handling requirements. Existing localization keys and detailed recommendation strings remain unchanged for the staff expansion.

The farmer view limits each category to the highest-priority two actions and removes duplicates. Empty categories remain visible with a short `ไม่มีคำแนะนำเพิ่มเติม` / `No additional action` message so the grouping is always apparent.

## Constraints

- Do not change REBA, ISO, risk scoring, or activity selection logic.
- Do not remove detailed weight limits or technical recommendations.
- Keep Thai and English behavior equivalent.
- Keep portrait-only behavior and the compile-time UAT bypass unchanged.
- Test on the connected iPhone before continuing Android UAT.

## Acceptance Criteria

- All four category headings are visible on the farmer result page.
- Every visible recommendation belongs to exactly one explicit category.
- No farmer-facing recommendation row combines multiple actions.
- Each category shows at most two actions.
- Detailed original recommendations remain available in staff details.
- Focused widget/service tests pass and static analysis is clean.
- The updated UAT build installs and launches on the connected iPhone.
