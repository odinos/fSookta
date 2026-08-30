#!/usr/bin/env node

import test from "node:test";
import assert from "node:assert/strict";

import {
  assertFormulaErrorScanClean,
  assertInspectionMatches,
} from "./build_task3_workbooks.mjs";


test("artifact-tool formula scan rejects any matched error", () => {
  assert.doesNotThrow(() => assertFormulaErrorScanClean('{"kind":"notice","message":"Cell search matched 0 entries."}'));
  assert.throws(
    () => assertFormulaErrorScanClean('{"kind":"match","sheet":"Summary","address":"B5","value":"#REF!"}'),
    /formula error scan matched/i,
  );
});

test("expected formula output mismatch fails", () => {
  const ndjson = '{"kind":"table","sheet":"Summary","address":"A4:B5","rows":2,"cols":2,"values":[["Metric","Count"],["Total",3]]}';
  assert.doesNotThrow(() => assertInspectionMatches(ndjson, { sheet: "Summary", address: "A4:B5", values: [["Metric", "Count"], ["Total", 3]] }));
  assert.throws(
    () => assertInspectionMatches(ndjson, { sheet: "Summary", address: "A4:B5", values: [["Metric", "Count"], ["Total", 4]] }),
    /inspection value mismatch/i,
  );
});
