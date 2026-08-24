import assert from "node:assert/strict";
import test from "node:test";

import {
  auditSheetNames,
  masterTestSheetNames,
  uatSheetNames,
  allowedStatuses,
  assertAllowedStatus,
  auditRows,
  masterCaseRows,
  historicalUatRows,
  susScoreFormula,
  formulaContracts,
  printFitToHeight,
  printTitleRows,
  printTitlesInsertionAnchor,
  susBlankRows,
  workbookFont,
} from "./build_task6_workbooks.mjs";

test("defines all required workbook surfaces", () => {
  assert.deepEqual(auditSheetNames, ["Control Summary","Timeline Milestones","Requirement Traceability","Version History","Feedback Modifications","Before After Evidence","Decisions Tradeoffs","Challenges Solutions","Effort Summary","Evidence Index","Human Actions"]);
  assert.ok(masterTestSheetNames.includes("Threshold Boundaries"));
  assert.ok(masterTestSheetNames.includes("Bugs Corrections Retest"));
  assert.ok(uatSheetNames.includes("SUS Response Form"));
  assert.ok(uatSheetNames.includes("Acceptance Signoff"));
});

test("status vocabulary is fail closed", () => {
  for (const status of allowedStatuses) assert.equal(assertAllowedStatus(status), status);
  assert.throws(() => assertAllowedStatus("Mostly pass"));
});

test("audit rows preserve source-derived git fields", () => {
  const rows = auditRows({git_history:[{commit:"a".repeat(40),date:"2026-01-01T00:00:00+07:00",subject:"subject",changed_paths:"lib/a.dart; test/a_test.dart",refs:"tag: v1"}]});
  assert.equal(rows[0][0], "a".repeat(40));
  assert.match(rows[0][3], /lib\/a.dart/);
});

test("master cases preserve complete evidence tuple", () => {
  const rows = masterCaseRows({final_test_cases:[{case_id:"AUTO-001",requirement_id:"7.1",category:"automated",precondition:"source",input:"command",expected:"pass",actual:"pass",status:"PASS",baseline:"1.3.11+28",tester_category:"Automated test runner",timestamp:"2026-08-23T14:00:00Z",method:"flutter test",evidence_path:"evidence/flutter_test.log",evidence_sha256:"b".repeat(64),limitations:"host runner"}]});
  assert.equal(rows[0].length, 15);
  assert.equal(rows[0][7], "PASS");
  assert.equal(rows[0][12], "b".repeat(64));
});

test("historical UAT retains version and bypass labels", () => {
  const rows = historicalUatRows({historical_uat:[{evidence_id:"H1",date:"2026-06-06",version:"1.1.2+10",device:"iPhone SE",platform:"iOS",method:"integration harness",result:"BLOCKED",bypass_status:"UAT bypass",limitations:"not production gate",evidence_path:"docs/uat.md",evidence_layer:"Historical"}]});
  assert.equal(rows[0][2], "1.1.2+10");
  assert.equal(rows[0][7], "UAT bypass");
  assert.equal(rows[0][9], "Historical");
});

test("SUS formula alternates odd and even items and returns blank until complete", () => {
  assert.match(susScoreFormula(6), /COUNTA\(C6:L6\)<>10/);
  assert.match(susScoreFormula(6), /C6-1/);
  assert.match(susScoreFormula(6), /5-D6/);
  assert.match(susScoreFormula(6), /\*2\.5/);
});

test("formula contracts cover all three workbooks", () => {
  const contracts = formulaContracts();
  assert.ok(contracts.some(row => row.workbook === "audit"));
  assert.ok(contracts.some(row => row.workbook === "master"));
  assert.ok(contracts.some(row => row.workbook === "uat"));
});

test("publication settings and bilingual font are fixed", () => {
  assert.equal(printFitToHeight, "0");
  assert.equal(printTitleRows, "$1:$4");
  assert.equal(printTitlesInsertionAnchor, "calcPr");
  assert.equal(susBlankRows, 10);
  assert.equal(workbookFont, "Thonburi");
});
