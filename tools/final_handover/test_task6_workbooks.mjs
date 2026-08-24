import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here=path.dirname(fileURLToPath(import.meta.url));
const root=process.env.FSOOKTA_HANDOVER_ROOT || "/private/tmp/fsookta-final-handover";
const expected=JSON.parse(await fs.readFile(path.join(here,"task6_expected_artifact_models.json"),"utf8"));
const payload=JSON.parse(await fs.readFile(path.join(root,"working/task6/task6_corrected_payload.json"),"utf8"));
const source=await fs.readFile(path.join(here,"build_task6_canonical_workbooks.mjs"),"utf8");
const printSource=await fs.readFile(path.join(here,"patch_task6_print_metadata.py"),"utf8");

test("defines all required workbook surfaces", () => {
  assert.deepEqual(expected.workbooks["06_Development_Audit_Trail.xlsx"].sheet_order,["Control Summary","Timeline Milestones","Requirement Traceability","Version History","Feedback Modifications","Before After Evidence","Decisions Tradeoffs","Challenges Solutions","Effort Summary","Evidence Index","Human Actions"]);
  assert.equal(Object.values(expected.workbooks).reduce((count,book)=>count+book.sheet_order.length,0),41);
  assert.ok(expected.workbooks["07_Master_Test_and_Verification_Package.xlsx"].sheet_order.includes("Threshold Boundaries"));
  assert.ok(expected.workbooks["08_UAT_Field_Test_and_Usability_Package.xlsx"].sheet_order.includes("Acceptance Signoff"));
});

test("status vocabulary is fail closed", () => {
  assert.equal(payload.result_rows.filter(row=>row.status==="PASS").length,136);
  assert.ok(payload.result_rows.find(row=>row.case_id==="FIREBASE-PLAN-001").status.startsWith("Not Executed"));
  assert.ok(!payload.result_rows.some(row=>row.status==="Mostly pass"));
});

test("audit rows preserve source-derived git fields", () => {
  assert.equal(payload.git_history.length,137);
  assert.equal(payload.git_history[0].commit,"bf8867a2083357cb9d60915bf6c2233801f923d8");
  assert.match(payload.git_history[0].changed_paths,/lib\/app\/build_info\.dart/);
  assert.ok(payload.git_history.every(row=>row.subject && row.changed_paths));
});

test("master cases preserve complete evidence tuple", () => {
  const required=["case_id","requirement_id","precondition_input","expected","actual","status","baseline","tester_category","timestamp","method","raw_path","sha256"];
  const pass=payload.result_rows.filter(row=>row.status==="PASS");
  assert.equal(pass.length,136);
  assert.ok(pass.every(row=>required.every(key=>key==="requirement_id" || row[key])));
  assert.ok(pass.every(row=>/^[0-9a-f]{64}$/.test(row.sha256)));
});

test("historical UAT retains version and bypass labels", () => {
  const h3=payload.historical_uat.find(row=>row.evidence_id==="H-UAT-003");
  const h7=payload.historical_uat.find(row=>row.evidence_id==="H-UAT-007");
  assert.deepEqual([h3.date,h3.round_revision,h3.version],["2026-06-06","r2","1.1.2+10"]);
  assert.equal(h7.version,"not stated");
  assert.ok(payload.historical_uat.every(row=>row.evidence_layer.startsWith("Historical")));
});

test("SUS formula alternates odd and even items and returns blank until complete", () => {
  assert.match(source,/COUNT\(D5:D14\)=10/);
  assert.match(source,/SUM\(D5,D7,D9,D11,D13\)-5\+25-SUM\(D6,D8,D10,D12,D14\)/);
  assert.match(source,/\*2\.5/);
  assert.match(source,/type:'whole',operator:'between',formula1:1,formula2:5/);
});

test("formula contracts cover all three workbooks", () => {
  assert.equal(Object.keys(expected.workbooks).length,3);
  assert.equal(Object.keys(expected.workbooks["08_UAT_Field_Test_and_Usability_Package.xlsx"].sheet_model_sha256).length,14);
  assert.match(expected.workbooks["08_UAT_Field_Test_and_Usability_Package.xlsx"].sheet_model_sha256["SUS Response Form"],/^[0-9a-f]{64}$/);
});

test("publication settings and governed font are fixed", () => {
  assert.match(source,/const font=\{name:'Arial',size:9,color:'#172033'\}/);
  assert.match(printSource,/'orientation':'landscape'/);
  assert.match(printSource,/'fitToWidth':'1'/);
  assert.match(printSource,/'fitToHeight':'0'/);
  assert.match(source,/A5:D14/);
});
