import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";

import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const workbookPath = path.join(
  process.cwd(),
  "docs/reviews/Sookta_Recommendation_Translation_Review_2026-07-29.xlsx",
);

test("unit-bearing not_applicable review blocks the workbook gate", async () => {
  const input = await FileBlob.load(workbookPath);
  const workbook = await SpreadsheetFile.importXlsx(input);
  const review = workbook.worksheets.getItem("Translation Review");
  const gateAudit = workbook.worksheets.getItem("Gate Audit");
  const coverage = workbook.worksheets.getItem("Coverage");

  assert.equal(review.getRange("H2").values[0][0], "not_applicable");
  assert.equal(coverage.getRange("B27").values[0][0], "READY");

  review.getRange("H7").values = [["not_applicable"]];

  assert.equal(gateAudit.getRange("F7").values[0][0], 1);
  assert.equal(coverage.getRange("B18").values[0][0], 1);
  assert.equal(coverage.getRange("B27").values[0][0], "BLOCKED");
});
