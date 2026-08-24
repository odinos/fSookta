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
  recommendationTriggerRows,
  syntheticExample,
} from "./build_task5_workbooks.mjs";

test("defines every required Task 5 workbook sheet", () => {
  assert.equal(algorithmSheetNames.length, 15);
  assert.equal(dataSheetNames.length, 9);
  assert.ok(algorithmSheetNames.includes("Recommendation Messages"));
  assert.ok(dataSheetNames.includes("Export Schema Order"));
});

test("data dictionary preserves ordered export headers and synthetic examples", () => {
  const facts = {
    export_schema_rows: [
      {field:"transaction_id",description:"Stable export transaction identifier",type:"text",nullable:"No",allowed:"Non-empty synthetic-safe identifier",unit:"N/A",source:"EvaluationHistoryRecord",derivation:"record.id",missing:"Blank only if source record is malformed",privacy:"Sensitive research linkage",persisted_location:"sookta.history[].id",export_location:"46: transaction_id",synthetic_example:"SYN-001",validation:"Must match source record identifier",version:"1.3.11+28",evidence:"lib/core/services/assessment_export_service.dart"},
      {field:"REBA_before",description:"Before-intervention REBA score",type:"integer",nullable:"No",allowed:"1..15",unit:"REBA score points",source:"EvaluationHistoryRecord",derivation:"record.scoreBefore",missing:"No fallback",privacy:"Sensitive research/health-adjacent",persisted_location:"sookta.history[].scoreBefore",export_location:"51: REBA_before",synthetic_example:6,validation:"Integer 1..15",version:"1.3.11+28",evidence:"lib/core/services/assessment_export_service.dart"},
      {field:"completion_status",description:"Research workflow completion status",type:"text",nullable:"Yes",allowed:"Source-captured text",unit:"N/A",source:"researchData",derivation:"record.researchData?.completionStatus",missing:"Blank",privacy:"Assessment/research data",persisted_location:"sookta.history[].researchData.completionStatus",export_location:"78: completion_status",synthetic_example:"complete",validation:"Preserve text or blank",version:"1.3.11+28",evidence:"lib/core/services/assessment_export_service.dart"},
    ],
  };
  const rows = dataDictionaryRows(facts);
  assert.deepEqual(rows.map((row) => row[0]), facts.export_schema_rows.map(r=>r.field));
  assert.ok(rows.every((row) => !["FSK-944631", "ddd"].includes(String(row[12]))));
  assert.ok(rows.some((row) => String(row[12]).startsWith("SYN-")));
});

test("persisted-key and record rows match the full data-dictionary contract", () => {
  const rows = persistedRows({
    persisted_schema_rows:[
      {field:"sookta.history",description:"History JSON array",type:"JSON array",nullable:"Yes",allowed:"EvaluationHistoryRecord objects",unit:"N/A",source:"SharedPreferences",derivation:"jsonEncode history",missing:"[]",privacy:"Sensitive research/health-adjacent",persisted_location:"SharedPreferences: sookta.history",export_location:"Multiple export fields",synthetic_example:"[]",validation:"Decode list; fail visibly",version:"1.3.11+28",evidence:"lib/app/app_state.dart"},
      {field:"scoreBefore",owner:"EvaluationHistoryRecord",description:"Before score",type:"integer",nullable:"No",allowed:"1..15",unit:"REBA score points",source:"EvaluationHistoryRecord",derivation:"toJson",missing:"Required",privacy:"Sensitive research/health-adjacent",persisted_location:"sookta.history[].scoreBefore",export_location:"REBA_before",synthetic_example:6,validation:"Integer 1..15",version:"1.3.11+28",evidence:"lib/core/models/evaluation_models.dart"},
    ],
  });
  assert.equal(rows.length, 2);
  assert.ok(rows.every((row) => row.length === 16));
});

test("recommendation trigger matrix uses source-exact keys", () => {
  const facts={recommendation_triggers:[
    {activity:"harvesting",risk_tier:"veryHigh",activity_key:"act_harvest_ref_high",weight_key:"N/A",manual_handling:false,source:"lib/core/services/risk_recommendation_service.dart"},
  ]};
  assert.deepEqual(recommendationTriggerRows(facts)[0].slice(0,4), ["harvesting","veryHigh","act_harvest_ref_high","N/A"]);
});

test("ISO timestamp examples remain text values", () => {
  assert.equal(typeof syntheticExample("expert_assessment_date", 82), "string");
  assert.match(syntheticExample("expert_assessment_date", 82), /^'/);
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
