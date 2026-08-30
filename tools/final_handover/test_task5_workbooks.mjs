import assert from "node:assert/strict";
import test from "node:test";

import {
  algorithmSheetNames,
  dataSheetNames,
  dataDictionaryRows,
  assertAllowedStatus,
  formulaContracts,
  persistedRows,
  privacyRows,
  rebaRows,
  printFitToHeight,
  workbookFont,
  recommendationTriggerRows,
  syntheticExample,
  trainingEvaluationRows,
} from "./build_task5_workbooks.mjs";

test("privacy register enumerates explicit and SDK-generated Firebase paths", () => {
  const row = privacyRows({firebase_telemetry:{
    events:{app_start:["platform","build_mode"],pose_analysis_failed:["platform","error_code"]},
    log_app_open:true, analytics_observer_navigation:true,
  }}).find((candidate) => candidate[0] === "Firebase telemetry");
  assert.match(row[1], /app_start\(platform, build_mode\)/);
  assert.match(row[1], /pose_analysis_failed\(platform, error_code\)/);
  assert.match(row[3], /logAppOpen/);
  assert.match(row[3], /SDK-generated navigation\/screen/);
});

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

test("training evaluation exposes split, full parameters, and distinct missing evidence", () => {
  const facts={training_evidence:[{evidence_id:"xgboost_training",component:"xgb",dataset_source:"source",dataset_path:"data/research/extracted/reba_labeled_pose_dataset.csv",dataset_status:"Pending Researcher Evidence",total_samples:388,training_samples:298,holdout_samples:90,unit:"rows",split_method:"GroupShuffleSplit",test_size:.22,random_seed:42,xgb_parameters:{objective:"reg:squarederror",n_estimators:96,max_depth:3,learning_rate:.055,subsample:.88,colsample_bytree:.86,reg_lambda:1.4,reg_alpha:.02,min_child_weight:2,random_state:42,n_jobs:1,tree_method:"hist"},preprocessing:"raw",features:51,labels:"labels",class_handling:"classes",selection_criteria:"none",holdout_risk_accuracy:.6667,holdout_mae:.8256,evaluation_boundary:"internal",raw_metrics_path:"data/research/extracted/xgboost_onnx_metrics.json",raw_metrics_status:"Pending Owner Action",raw_metrics_note:"missing",research_trained:true,citation:"script"}]};
  const row=trainingEvaluationRows(facts)[0];
  assert.equal(row[3], "data/research/extracted/reba_labeled_pose_dataset.csv");
  assert.equal(row[4], "Pending Researcher Evidence");
  assert.equal(row[9], "GroupShuffleSplit");
  assert.equal(row[10], .22);
  assert.equal(row[11], 42);
  assert.match(row[12], /"n_estimators":96/);
  assert.equal(row[21], "data/research/extracted/xgboost_onnx_metrics.json");
  assert.equal(row[22], "Pending Owner Action");
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
  assert.equal(
    contracts.find((row) => row.range === "Control Summary!B7" && row.workbook === "data").expectedFormula,
    "=COUNTA('Export Schema Order'!J5:J200)-COUNTIF('Export Schema Order'!J5:J200,\"Operational metadata\")",
  );
});

test("publication PDF fits width but may paginate long sheets vertically", () => {
  assert.equal(printFitToHeight, "0");
});

test("workbook font covers both Thai and English catalog text", () => {
  assert.equal(workbookFont, "Thonburi");
});
