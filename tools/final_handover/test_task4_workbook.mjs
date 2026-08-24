#!/usr/bin/env node
import test from "node:test";
import assert from "node:assert/strict";
import { assertFormulaErrorScanClean, assertFormulaContract, countLocalStorageRows, technologyStack } from "./build_task4_workbook.mjs";

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

test("technology stack records exact resolved packages and model identifiers", () => {
  const rows = new Map(technologyStack().map(row => [row[0], row[1]]));
  assert.equal(rows.get("camera"), "0.11.4 (resolved)");
  assert.equal(rows.get("image_picker"), "1.2.2 (resolved)");
  assert.equal(rows.get("firebase_core"), "4.10.0 (resolved)");
  assert.equal(rows.get("shared_preferences"), "2.5.5 (resolved)");
  assert.equal(rows.get("XGBoost advisory"), "reba-iso-xgboost-onnx-2026-06-07");
  assert.equal(rows.get("Daily logistic template"), "daily-injury-logistic-template-2026-06-14");
  assert.match(rows.get("MoveNet Thunder"), /movenet-thunder-v1-17x3-normalized/);
  assert.match(rows.get("MoveNet MultiPose Lightning"), /upstream artifact release\/version not recorded in repo/i);
});
