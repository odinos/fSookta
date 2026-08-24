#!/usr/bin/env node
import test from "node:test";
import assert from "node:assert/strict";
import { assertFormulaErrorScanClean, assertFormulaContract, countLocalStorageRows } from "./build_task4_workbook.mjs";

test("formula scan fails closed on matched or ambiguous output", () => {
  assert.doesNotThrow(() => assertFormulaErrorScanClean('{"kind":"notice","message":"Cell search matched 0 entries."}'));
  assert.throws(() => assertFormulaErrorScanClean('{"kind":"match","value":"#REF!"}'), /formula error/i);
  assert.throws(() => assertFormulaErrorScanClean(''), /empty|ambiguous/i);
});

test("summary formula contract requires exact formulas and values", () => {
  const expected = { formulas: [["=COUNTA('Modules'!A5:A18)"]], values: [[14]] };
  assert.doesNotThrow(() => assertFormulaContract(expected, expected, "Summary!B5"));
  assert.throws(() => assertFormulaContract({ formulas: [["=1"]], values: [[14]] }, expected, "Summary!B5"), /contract/i);
});

test("local storage/network summary counts only rows containing local", () => {
  const rows = [["Local device only"], ["Offline local inference"], ["No assessment network"], ["Device permission only"]];
  assert.equal(countLocalStorageRows(rows), 2);
});
