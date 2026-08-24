import assert from "node:assert/strict";
import test from "node:test";

import {
  algorithmSheetNames,
  dataSheetNames,
  dataDictionaryRows,
  assertAllowedStatus,
  formulaContracts,
  persistedRows,
  rebaRows,
  printFitToHeight,
  workbookFont,
} from "./build_task5_workbooks.mjs";

test("defines every required Task 5 workbook sheet", () => {
  assert.equal(algorithmSheetNames.length, 15);
  assert.equal(dataSheetNames.length, 9);
  assert.ok(algorithmSheetNames.includes("Recommendation Messages"));
  assert.ok(dataSheetNames.includes("Export Schema Order"));
});

test("data dictionary preserves ordered export headers and synthetic examples", () => {
  const facts = {
    all_history_csv_headers: ["transaction_id", "REBA_before", "completion_status"],
  };
  const rows = dataDictionaryRows(facts);
  assert.deepEqual(rows.map((row) => row[0]), facts.all_history_csv_headers);
  assert.ok(rows.every((row) => !["FSK-944631", "ddd"].includes(String(row[12]))));
  assert.ok(rows.some((row) => String(row[12]).startsWith("SYN-")));
});

test("persisted-key and record rows match the full data-dictionary contract", () => {
  const rows = persistedRows({
    preference_keys:["sookta.history"],
    persisted_record_fields:[{field:"scoreBefore",source:"lib/app/app_state.dart"}],
  });
  assert.equal(rows.length, 2);
  assert.ok(rows.every((row) => row.length === 16));
});

test("REBA matrix contains complete source-controlled tables A, B, and C", () => {
  const rows = rebaRows();
  assert.ok(rows.some((row) => row[0] === "Table A"));
  assert.ok(rows.some((row) => row[0] === "Table B"));
  assert.ok(rows.some((row) => row[0] === "Table C"));
  assert.equal(rows.filter((row) => row[0] === "Table A").length, 15);
  assert.equal(rows.filter((row) => row[0] === "Table B").length, 12);
  assert.equal(rows.filter((row) => row[0] === "Table C").length, 12);
});

test("status gate is fail closed", () => {
  assert.equal(assertAllowedStatus("Complete"), "Complete");
  assert.throws(() => assertAllowedStatus("Almost complete"));
});

test("formula contracts cover both workbook summaries", () => {
  const contracts = formulaContracts();
  assert.ok(contracts.length >= 10);
  assert.ok(contracts.some((row) => row.workbook === "algorithm"));
  assert.ok(contracts.some((row) => row.workbook === "data"));
});

test("publication PDF fits width but may paginate long sheets vertically", () => {
  assert.equal(printFitToHeight, "0");
});

test("workbook font covers both Thai and English catalog text", () => {
  assert.equal(workbookFont, "Thonburi");
});
