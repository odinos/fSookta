#!/usr/bin/env node
// Build Task 5 algorithm/recommendation and data-dictionary workbooks.
import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";
import JSZip from "jszip";

const VERSION = "1.3.11+28";
export const printFitToHeight = "0";
export const workbookFont = "Thonburi";
const COMMIT = "bf8867a2083357cb9d60915bf6c2233801f923d8";
const STAGING = "/private/tmp/fsookta-final-handover";
const allowedStatuses = new Set(["Complete", "Complete - Pending Signature", "Pending Owner Action", "Pending Researcher Evidence", "N/A with Rationale", "Exception Approval Required"]);
export const algorithmSheetNames = ["Control Summary", "Model Algorithm Inventory", "REBA Tables Thresholds", "ISO Formulas Applicability", "Boundary Decision Cases", "Image Pose Failure", "XGBoost Logistic IO", "Detected Risk Mapping", "Recommendation Triggers", "Priority Conflict Dedup", "Recommendation Messages", "Research Traceability", "Training Evaluation", "Limitations", "Human Actions"];
export const dataSheetNames = ["Control Summary", "Persisted Keys Records", "Export Schema Order", "Enumerations Values", "Derivations", "Privacy Retention", "Migration Compatibility", "Evidence Sources", "Human Actions"];

const colors = {navy:"#17365D", blue:"#D9EAF7", pale:"#F4F7FA", white:"#FFFFFF", ink:"#1F2937", gray:"#6B7280", line:"#CBD5E1", amber:"#FFF2CC", green:"#E2F0D9", red:"#FCE8E6"};

export function assertAllowedStatus(value) { if (!allowedStatuses.has(value)) throw new Error(`Unsupported status: ${value}`); return value; }

export function syntheticExample(field, index) {
  const key = field.toLowerCase();
  if (key.includes("generated") || key.includes("date") || key.includes("timestamp") || key.includes("time")) return "'2026-08-24T09:00:00+07:00";
  if (key.includes("id") || key.includes("code")) return `SYN-${String(index + 1).padStart(3,"0")}`;
  if (key.includes("risk") || key.includes("level")) return "Medium";
  if (key.includes("status")) return "complete";
  if (key.includes("score")) return 6;
  if (key.includes("weight")) return 8.5;
  if (key.includes("duration") || key.includes("distance") || key.includes("frequency")) return 10;
  if (key.includes("name")) return "Synthetic Farmer";
  return "Synthetic value";
}

function inferPrivacy(field) {
  const key = field.toLowerCase();
  if (/name|farmer|participant|profile|photo|image|msd|medical|gender|age|bmi|weight|expert/.test(key)) return "Sensitive research/health-adjacent";
  if (/path|timestamp|date|time|version|status|error/.test(key)) return "Operational metadata";
  return "Assessment/research data";
}

function inferType(field) {
  const key = field.toLowerCase();
  if (/score|cost|impact|weight|distance|frequency|duration|count|percent|age|height|bmi/.test(key)) return "number or source-defined text fallback";
  if (/date|time|timestamp/.test(key)) return "ISO-8601 text/date-time";
  return "text";
}

export function dataDictionaryRows(facts) {
  return facts.export_schema_rows.map(r => [r.field,r.description,r.type,r.nullable,r.allowed,r.unit,r.source,r.derivation,r.missing,r.privacy,r.persisted_location,r.export_location,r.synthetic_example,r.validation,r.version,r.evidence]);
}

export function formulaContracts() {
  return [
    {workbook:"algorithm", range:"Control Summary!B5", expectedFormula:"=COUNTA('Model Algorithm Inventory'!A5:A100)"},
    {workbook:"algorithm", range:"Control Summary!B6", expectedFormula:"=COUNTIF('Model Algorithm Inventory'!H5:H100,\"Project-trained\")"},
    {workbook:"algorithm", range:"Control Summary!B7", expectedFormula:"=COUNTA('Recommendation Messages'!A5:A100)"},
    {workbook:"algorithm", range:"Control Summary!B8", expectedFormula:"=COUNTA('Research Traceability'!A5:A100)"},
    {workbook:"algorithm", range:"Control Summary!B9", expectedFormula:"=COUNTIF('Human Actions'!D5:D100,\"Pending Owner Action\")+COUNTIF('Human Actions'!D5:D100,\"Pending Researcher Evidence\")"},
    {workbook:"data", range:"Control Summary!B5", expectedFormula:"=COUNTA('Persisted Keys Records'!A5:A500)"},
    {workbook:"data", range:"Control Summary!B6", expectedFormula:"=COUNTA('Export Schema Order'!A5:A200)"},
    {workbook:"data", range:"Control Summary!B7", expectedFormula:"=COUNTIF('Export Schema Order'!J5:J200,\"Sensitive research/health-adjacent\")"},
    {workbook:"data", range:"Control Summary!B8", expectedFormula:"=COUNTIF('Human Actions'!D5:D100,\"Pending Owner Action\")+COUNTIF('Human Actions'!D5:D100,\"Pending Researcher Evidence\")"},
    {workbook:"data", range:"Control Summary!B9", expectedFormula:"='Migration Compatibility'!B5"},
  ];
}

function colLetter(n) { let s=""; while(n>0){n--;s=String.fromCharCode(65+n%26)+s;n=Math.floor(n/26);} return s; }
function safe(name) { return name.replaceAll(/[^A-Za-z0-9]+/g,"_").replace(/^_+|_+$/g,""); }
function title(sheet, text, subtitle, last) {
  sheet.showGridLines=false; sheet.mergeCells(`A1:${last}1`); sheet.getRange("A1").values=[[text]];
  sheet.getRange(`A1:${last}1`).format={fill:colors.navy,font:{name:workbookFont,size:18,bold:true,color:colors.white},verticalAlignment:"center"}; sheet.getRange(`A1:${last}1`).format.rowHeight=30;
  sheet.mergeCells(`A2:${last}2`); sheet.getRange("A2").values=[[subtitle]]; sheet.getRange(`A2:${last}2`).format={fill:colors.pale,font:{name:workbookFont,size:10,color:colors.gray},wrapText:true}; sheet.getRange(`A2:${last}2`).format.rowHeight=32;
}
function header(range){ range.format={fill:colors.blue,font:{name:workbookFont,size:10,bold:true,color:colors.ink},wrapText:true,verticalAlignment:"center",borders:{preset:"all",style:"thin",color:colors.line}}; range.format.rowHeight=42; }
function body(range){ range.format={font:{name:workbookFont,size:9,color:colors.ink},wrapText:true,verticalAlignment:"top",borders:{insideHorizontal:{style:"thin",color:colors.line},bottom:{style:"thin",color:colors.line}}}; }
function matrix(sheet, name, subtitle, headers, rows, widths) {
  const last=colLetter(headers.length); title(sheet,name,`${subtitle} | ${VERSION} | Git ${COMMIT}`,last);
  sheet.getRange(`A4:${last}4`).values=[headers]; header(sheet.getRange(`A4:${last}4`));
  if(rows.length){sheet.getRange(`A5:${last}${rows.length+4}`).values=rows; body(sheet.getRange(`A5:${last}${rows.length+4}`)); sheet.getRange(`A5:${last}${rows.length+4}`).format.rowHeight=48;}
  widths.forEach((width,index)=>sheet.getRangeByIndexes(0,index,Math.max(rows.length+4,5),1).format.columnWidth=width); sheet.freezePanes.freezeRows(4);
}

async function applyPrintSettings(output) {
  const zip=await JSZip.loadAsync(await fs.readFile(output));
  for(const name of Object.keys(zip.files).filter(n=>/^xl\/worksheets\/sheet\d+\.xml$/.test(n))){
    let xml=await zip.file(name).async("string"); const prefix=xml.match(/<([A-Za-z0-9_]+:)?worksheet\b/)?.[1]??""; const tag=x=>`${prefix}${x}`;
    if(new RegExp(`<${tag("sheetPr")}\\b[^>]*\\/>`).test(xml)) xml=xml.replace(new RegExp(`<${tag("sheetPr")}\\b([^>]*)\\/>`),`<${tag("sheetPr")}$1><${tag("pageSetUpPr")} fitToPage="1"/></${tag("sheetPr")}>`);
    else if(new RegExp(`<${tag("sheetPr")}\\b`).test(xml)) xml=xml.replace(new RegExp(`</${tag("sheetPr")}>`),`<${tag("pageSetUpPr")} fitToPage="1"/></${tag("sheetPr")}>`);
    else xml=xml.replace(new RegExp(`(<${tag("worksheet")}\\b[^>]*>)`),`$1<${tag("sheetPr")}><${tag("pageSetUpPr")} fitToPage="1"/></${tag("sheetPr")}>`);
    for(const local of ["printOptions","pageMargins","pageSetup"]) xml=xml.replace(new RegExp(`<${tag(local)}\\b[^>]*\\/>`,"g"),"");
    xml=xml.replace(`</${tag("worksheet")}>`,`<${tag("printOptions")} horizontalCentered="1"/><${tag("pageMargins")} left="0.18" right="0.18" top="0.3" bottom="0.3" header="0.12" footer="0.12"/><${tag("pageSetup")} paperSize="8" orientation="landscape" fitToWidth="1" fitToHeight="${printFitToHeight}" horizontalDpi="300" verticalDpi="300"/></${tag("worksheet")}>`);
    zip.file(name,xml);
  }
  await fs.writeFile(output,await zip.generateAsync({type:"nodebuffer",compression:"DEFLATE",compressionOptions:{level:9}}));
}

export function recommendationTriggerRows(facts) {
  return facts.recommendation_triggers.map(r=>[r.activity,r.risk_tier,r.activity_key,r.weight_key,r.manual_handling?"Activity key + weight key":"Activity key only",r.source]);
}

export function rebaRows() {
  const tableA=[
    [[1,2,3,4],[2,3,4,5],[2,4,5,6],[3,5,6,7],[4,6,7,8]],
    [[1,2,3,4],[3,4,5,6],[4,5,6,7],[5,6,7,8],[6,7,8,9]],
    [[3,3,5,6],[4,5,6,7],[5,6,7,8],[6,7,8,9],[7,8,9,9]],
  ];
  const tableB=[
    [[1,2,2],[1,2,3],[3,4,5],[4,5,5],[6,7,8],[7,8,8]],
    [[1,2,3],[2,3,4],[4,5,5],[5,6,7],[7,8,8],[8,9,9]],
  ];
  const tableC=[[1,1,1,2,3,3,4,5,6,7,7,7],[1,2,2,3,4,4,5,6,6,7,7,8],[2,3,3,3,4,5,6,7,7,8,8,8],[3,4,4,4,5,6,7,8,8,9,9,9],[4,4,4,5,6,7,8,8,9,9,9,9],[6,6,6,7,8,8,9,9,10,10,10,10],[7,7,7,8,9,9,9,10,10,11,11,11],[8,8,8,9,10,10,10,10,10,11,11,11],[9,9,9,10,10,10,11,11,11,12,12,12],[10,10,10,11,11,11,11,12,12,12,12,12],[11,11,11,11,12,12,12,12,12,12,12,12],[12,12,12,12,12,12,12,12,12,12,12,12]];
  const rows=[["Risk tier","Score <=3","Low","_mapRebaToRiskLevel","lib/core/services/ergo_calculator.dart"],["Risk tier","4-7","Medium","_mapRebaToRiskLevel","lib/core/services/ergo_calculator.dart"],["Risk tier","8-10","High","_mapRebaToRiskLevel","lib/core/services/ergo_calculator.dart"],["Risk tier",">10","Very High","_mapRebaToRiskLevel","lib/core/services/ergo_calculator.dart"]];
  tableA.forEach((trunks,neckIndex)=>trunks.forEach((values,trunkIndex)=>rows.push(["Table A",`Neck ${neckIndex+1} / Trunk ${trunkIndex+1}`,values.join(", "),"Values are Legs 1..4","lib/core/services/ergo_calculator.dart:_rebaTableA"])));
  tableB.forEach((uppers,lowerIndex)=>uppers.forEach((values,upperIndex)=>rows.push(["Table B",`Lower arm ${lowerIndex+1} / Upper arm ${upperIndex+1}`,values.join(", "),"Values are Wrist 1..3","lib/core/services/ergo_calculator.dart:_rebaTableB"])));
  tableC.forEach((values,index)=>rows.push(["Table C",`Score A ${index+1}`,values.join(", "),"Columns are Score B 1..12","lib/core/services/ergo_calculator.dart:_rebaTableC"])); return rows;
}

function isoRows() { return [
  ["ISO 11228-1 lifting","Applicable to lifting/carrying tasks","refMass * VM * HM * FM * DM","male 25 kg; female 20 kg; minimum geometry multiplier 0.7","Lifting index = load/RWL","lib/core/services/ergo_calculator.dart"],
  ["Horizontal multiplier","Lifting","25 / max(horizontal distance cm,25), clamped 0.7..1","cm","Feeds RWL","lib/core/services/ergo_calculator.dart"],
  ["Vertical multiplier","Lifting","1 - 0.003 * abs(vertical height - 75), clamped 0.7..1","cm","Feeds RWL","lib/core/services/ergo_calculator.dart"],
  ["Frequency multiplier","Lifting","<=0.2:1; <=1:0.94; <=4:0.84; <=6:0.75; else 0.5","lifts/min","Feeds RWL","lib/core/services/ergo_calculator.dart"],
  ["Distance multiplier","Lifting/carrying","<=2m:1; <=10m:0.85; <=20m:0.75; else 0.6","m","Feeds RWL","lib/core/services/ergo_calculator.dart"],
  ["ISO 11228-2 push/pull","Applicable to push/pull tasks","max(initial/limitInitial, sustained/limitSustain)","male 25/15 N; female 20/12 N","Force ratio maps to risk","lib/core/services/ergo_calculator.dart"],
  ["Remote standard certification","All","N/A with Rationale","Implementation evidence is not ISO certification","Owner/researcher standards review required","data/research/reference_sources/training_reference_sources.json"],
]; }

function humanRows(facts) { return facts.human_actions.map((action,index)=>[`HA-${String(index+1).padStart(2,"0")}`,action,index<5?"Owner / Researcher":"Authorized signatories",index===1||index===3?"Pending Researcher Evidence":index===5?"Complete - Pending Signature":"Pending Owner Action","Required before claim/acceptance closure"]); }

async function renderWorkbook(workbook, stem, sheets) {
  const renderDir=path.join(STAGING,"renders","task5","xlsx"); await fs.mkdir(renderDir,{recursive:true}); const renders=[];
  for(const name of sheets){const preview=await workbook.render({sheetName:name,autoCrop:"all",scale:1.25,format:"png"}); const output=path.join(renderDir,`${stem}__${safe(name)}.png`); await fs.writeFile(output,new Uint8Array(await preview.arrayBuffer())); renders.push(output);}
  return renders;
}

async function inspectFormulaContract(workbook, contract, expectedValue) {
  const [sheetName,range]=contract.range.split("!"); const cell=workbook.worksheets.getItem(sheetName).getRange(range); const actualFormula=cell.formulas[0][0]; const actualValue=cell.values[0][0];
  if(actualFormula!==contract.expectedFormula || actualValue!==expectedValue) throw new Error(`Formula contract mismatch ${contract.range}: ${actualFormula}/${actualValue}, expected ${contract.expectedFormula}/${expectedValue}`);
  return {workbook:contract.workbook,range:contract.range,expected_formula:contract.expectedFormula,actual_formula:actualFormula,expected_value:expectedValue,actual_value:actualValue,status:"passed"};
}

async function buildAlgorithm(facts) {
  const wb=Workbook.create(); const sheets=Object.fromEntries(algorithmSheetNames.map(name=>[name,wb.worksheets.add(name)]));
  matrix(sheets["Model Algorithm Inventory"],"Model and Algorithm Inventory","Pretrained, project-trained, deterministic, template, advisory and legacy roles",["Role ID","Component","Identifier","Binary SHA-256","Runtime path","Input","Output","Training class","Authority","Current reference status","Fallback","Limitations","Citation"],facts.model_algorithm_inventory.map(r=>[r.role_id,r.component,r.identifier,r.binary_sha256,r.runtime_path,r.input,r.output,r.training_class,r.authority,r.current_reference_status,r.fallback,r.limitations,r.citation]),[20,27,38,34,35,34,28,28,25,34,38,55,48]);
  matrix(sheets["REBA Tables Thresholds"],"REBA Tables and Thresholds","Exact risk thresholds and complete source-controlled Tables A, B, and C",["Section","Input","Value(s)","Symbol / interpretation","Evidence"],rebaRows(),[22,24,62,45,52]);
  matrix(sheets["ISO Formulas Applicability"],"ISO 11228 Formulas and Applicability","Source-exact lifting and push/pull logic; not a standards certification",["Rule","Applicability","Formula / mapping","Constants / units","Output","Evidence"],isoRows(),[28,32,54,45,35,52]);
  matrix(sheets["Boundary Decision Cases"],"Boundary and Decision Cases","Representative exact decision boundaries grounded in source/tests",["Case","Input","Expected result","Authority","Evidence"],[
    ["REBA low upper bound","REBA 3","Low","Deterministic","lib/core/services/ergo_calculator.dart"],["REBA medium lower bound","REBA 4","Medium","Deterministic","test/ergo_calculator_test.dart"],["REBA high upper bound","REBA 10","High","Deterministic","lib/core/services/ergo_calculator.dart"],["REBA very high lower bound","REBA 11","Very High","Deterministic","lib/core/services/ergo_calculator.dart"],["Lifting index 1.0","LI <= 1.0","Low","Deterministic ISO-applicability logic","lib/core/services/ergo_calculator.dart"],["Lifting index 1.01","LI > 1.0 and <=3.0","Medium","Deterministic ISO-applicability logic","lib/core/services/ergo_calculator.dart"],["Force ratio 0.8","ratio >=0.8 and <=1.0","Medium","Deterministic ISO-applicability logic","lib/core/services/ergo_calculator.dart"],["Force ratio >1.0","ratio 1.01","High","Deterministic ISO-applicability logic","lib/core/services/ergo_calculator.dart"],["Combined result","REBA Medium; ISO High","High / higher user score","Primary deterministic","test/ergo_calculator_test.dart"],["XGBoost unavailable","Runtime unavailable","Advisory omitted; REBA/ISO retained","Advisory only","lib/core/models/ml_inference_status.dart"]
  ],[28,38,40,32,52]);
  matrix(sheets["Image Pose Failure"],"Image and Pose Failure Handling","No fabricated pose or advisory output",["Failure","Detection","Behavior","Fallback","Status / owner","Evidence"],[
    ["Unreadable image","Decode failure","Return unavailable","Request new media/manual input","Complete","lib/core/services/pose_estimation_service.dart"],["Low pose confidence","Keypoint/person confidence below source threshold","No reliable pose result","Request better capture/manual input","Complete","lib/core/services/pose_estimation_service.dart"],["No person / ambiguity","No valid pose or multi-person ambiguity","Do not invent joints","Recapture / select appropriate image","Complete","lib/core/services/multi_person_pose_detector.dart"],["Feature schema mismatch","Not exactly 51 features","XGBoost invalid input","Suppress advisory","Complete","lib/core/ergonomics_risk_prediction/"],["ONNX unavailable/runtime error","Loader/inference failure","REBA/ISO still returned","Advisory omitted with error code","Complete","lib/core/models/ml_inference_status.dart"],["Physical-device behavior","Permission/camera/gallery edge cases","Requires final device evidence","Owner/researcher protocol","Pending Researcher Evidence","docs/reviews/local-platform-ml-review-2026-07-29.md"]
  ],[31,38,38,38,30,52]);
  const ioRows=[]; for(const role of facts.model_algorithm_inventory.filter(r=>["xgboost_onnx","daily_logistic"].includes(r.role_id))) ioRows.push([role.component,role.identifier,role.input,role.output,role.authority,role.fallback,role.limitations,role.citation]);
  matrix(sheets["XGBoost Logistic IO"],"XGBoost and Logistic Inputs / Outputs","Separate project-trained advisory from template-coefficient daily prediction",["Component","Identifier","Input","Output","Authority","Fallback","Limitations","Evidence"],ioRows,[28,38,50,32,25,40,55,48]);
  matrix(sheets["Detected Risk Mapping"],"Detected-Risk Mapping","Deterministic result authority and optional advisory attachment",["Source","Input tier/value","Mapped output","Priority","Conflict rule","Evidence"],[
    ["REBA","1-3 / 4-7 / 8-10 / 11-15","Low / Medium / High / Very High",1,"Primary","lib/core/services/ergo_calculator.dart"],["Lifting index","<=1 / <=3 / >3","Low / Medium / High",1,"Applicable ISO risk combined by higher tier","lib/core/services/ergo_calculator.dart"],["Push/pull ratio","<0.8 / 0.8..1 / >1","Low / Medium / High",1,"Applicable ISO risk combined by higher tier","lib/core/services/ergo_calculator.dart"],["XGBoost","probability/risk signal","Advisory alert",2,"Cannot lower/replace REBA/ISO","assets/models/model_artifact_manifest.json"],["Daily runtime tier","0-1 / 2-3 / 4-5 / 6-7 high-risk records","Low / Watch / High / Critical",3,"predictForRecords uses count tiers, not probability thresholds","lib/core/services/daily_injury_prediction_service.dart"],["Daily probability thresholds","JSON thresholds and levelFor helper","Loaded/template metadata only",4,"Not used by predictForRecords tier assignment","assets/ml/daily_injury_logistic_model.json; lib/core/services/daily_injury_prediction_service.dart"]
  ],[24,34,35,15,48,55]);
  matrix(sheets["Recommendation Triggers"],"Recommendation Triggers","Exact activity/weight key mapping; High and VeryHigh collapse to high keys",["Activity","Tier","Activity key","Weight key","Behavior","Evidence"],recommendationTriggerRows(facts),[24,18,38,38,45,52]);
  matrix(sheets["Priority Conflict Dedup"],"Priority, Conflict, Deduplication, and Category Caps","Exact source behavior and interpretation boundary",["Rule","Exact behavior","Priority / cap","Fallback","Evidence"],[
    ["Base categories","Start with activity posture, risk reduction, rest/rotation, workload support","One each before body-risk addition","Always source-controlled","lib/core/services/risk_recommendation_service.dart"],["Body risk","Take first body part whose risk is not Low","At most one additional body-posture candidate","No body item when all Low","lib/core/services/risk_recommendation_service.dart"],["Deduplication","Unique by category.name + text","First occurrence wins","Duplicate omitted","lib/core/services/risk_recommendation_service.dart"],["Category cap","Maximum two items per category","count >=2 omitted","Base candidates retained by order","lib/core/services/risk_recommendation_service.dart"],["Very High activity tier","Activity rule collapses High and Very High to high key","Source-exact","Body mapping retains very_high tier","lib/core/services/risk_recommendation_service.dart"],["Research authority","Message wording/source mapping requires review","Pending researcher evidence","Do not claim researcher acceptance","data/research/reference_sources/training_reference_sources.json"]
  ],[30,62,34,40,52]);
  matrix(sheets["Recommendation Messages"],"Thai-English Recommendation Message Catalog","Exact bilingual pairs extracted from source",["Message ID","Thai","English","Source"],facts.recommendation_messages.map(r=>[r.message_id,r.thai,r.english,r.source]),[24,62,58,55]);
  matrix(sheets["Research Traceability"],"Research and Reference Traceability","Local reference registry; copyrighted standards are not redistributed",["Source ID","Title","Document type","Use","Model fields","App scope","SHA-256","Status"],facts.reference_sources.map(r=>[r.id,r.title,r.documentType,r.trainingUse,r.modelFields.join("; "),r.appScope.join("; "),r.sha256,"Pending Researcher Evidence"]),[25,58,32,60,58,42,34,30]);
  matrix(sheets["Training Evaluation"],"Training and Evaluation Evidence","Executable/current evidence separated from historical/template claims",["Evidence ID","Component","Dataset source","Total","Train","Holdout","Unit","Split","Preprocessing","Features","Labels","Seed","Class handling","Selection criteria","Holdout accuracy","Holdout MAE","Boundary","Raw metrics status","Raw metrics note","Research trained","Citation"],facts.training_evidence.map(r=>[r.evidence_id,r.component,r.dataset_source,r.total_samples,r.training_samples,r.holdout_samples,r.unit,r.split,r.preprocessing,r.features,r.labels,r.random_seed,r.class_handling,r.selection_criteria,r.holdout_risk_accuracy,r.holdout_mae,r.evaluation_boundary,r.raw_metrics_status,r.raw_metrics_note,r.research_trained,r.citation]),[24,36,52,12,12,12,22,38,38,12,60,30,40,42,18,18,62,28,55,18,50]);
  matrix(sheets["Limitations"],"Limitations and Prohibited Claims","Fail-closed interpretation boundaries",["ID","Limitation / prohibited claim","Impact","Status","Required action","Evidence"],[
    ["L-01","No clinical validation or external validity evidence","Do not describe clinical effectiveness","Pending Researcher Evidence","Research protocol and independent evidence","Governing design principles"],["L-02","XGBoost holdout has only high and veryHigh classes","Accuracy cannot establish broad generalization","Pending Researcher Evidence","Expand labels/classes and rerun evaluation","assets/models/xgboost_model_metadata.json"],["L-03","Raw metrics file referenced by metadata is absent","Reproduction evidence incomplete","Pending Owner Action","Provide artifact or approve limitation","assets/models/model_artifact_manifest.json"],["L-04","Daily logistic coefficients are templates","No fitted outcome model claim","Pending Researcher Evidence","Supply labels, fit, evaluate, approve","assets/ml/daily_injury_logistic_model.json"],["L-05","MoveNet upstream artifact version unavailable","Cannot assert upstream release provenance","Pending Owner Action","Supply authoritative provenance addendum","assets/models/joint_feature_schema.json"],["L-06","REBA safety floors are project-specific","Must be distinguished from original REBA","Pending Researcher Evidence","Review and approve interpretation","lib/core/services/ergo_calculator.dart"],["L-07","Consent, ethics, de-identification and acceptance not proven","No participant-governance completion claim","Pending Researcher Evidence","Provide signed evidence","Human-owned"]
  ],[18,68,50,30,58,52]);
  matrix(sheets["Human Actions"],"Human-Owned Actions","Missing facts remain visibly pending",["Action ID","Action","Owner","Status","Closure evidence"],humanRows(facts),[18,82,30,30,55]);
  const summary=sheets["Control Summary"]; matrix(summary,"Algorithm and Recommendation Control Summary","Formula-driven coverage and explicit status gates",["Metric","Value","Acceptance gate"],[
    ["Model/algorithm roles",null,"Must equal source-grounded inventory"],["Project-trained components",null,"XGBoost only"],["Recommendation messages",null,"Exact bilingual source pairs"],["Reference sources",null,"Registry entries"],["Pending owner/researcher actions",null,"Must remain visible"],["Overall technical status","Complete - Pending Signature","No unsupported claim; signatures pending"],["Clinical/external validity","N/A with Rationale","Not established by software evidence"]
  ],[42,24,72]);
  summary.getRange("B5").formulas=[["=COUNTA('Model Algorithm Inventory'!A5:A100)"]]; summary.getRange("B6").formulas=[["=COUNTIF('Model Algorithm Inventory'!H5:H100,\"Project-trained\")"]]; summary.getRange("B7").formulas=[["=COUNTA('Recommendation Messages'!A5:A100)"]]; summary.getRange("B8").formulas=[["=COUNTA('Research Traceability'!A5:A100)"]]; summary.getRange("B9").formulas=[["=COUNTIF('Human Actions'!D5:D100,\"Pending Owner Action\")+COUNTIF('Human Actions'!D5:D100,\"Pending Researcher Evidence\")"]];
  return wb;
}

export function persistedRows(facts) {
  return facts.persisted_schema_rows.map(r=>[r.field,r.description,r.type,r.nullable,r.allowed,r.unit,r.source,r.derivation,r.missing,r.privacy,r.persisted_location,r.export_location,r.synthetic_example,r.validation,r.version,r.evidence]);
}

async function buildData(facts) {
  const wb=Workbook.create(); const sheets=Object.fromEntries(dataSheetNames.map(name=>[name,wb.worksheets.add(name)]));
  matrix(sheets["Persisted Keys Records"],"Persisted Keys and Records","SharedPreferences top-level and nested record schema; examples are synthetic",["Field / variable","Description","Type","Nullable","Allowed values / range","Unit","Source","Derivation / formula","Missing code","Privacy class","Persisted location / key","CSV header / order","Synthetic example","Validation / fallback","Version introduced","Evidence path"],persistedRows(facts),[30,55,32,28,42,24,42,58,30,42,48,34,36,52,22,52]);
  const dictionary=dataDictionaryRows(facts); matrix(sheets["Export Schema Order"],"Data Dictionary and Export Schema Order",`All ${dictionary.length} ordered all-history columns; examples are synthetic and non-personal`,["Field / variable","Description","Type","Nullable","Allowed values / range","Unit","Source","Derivation / formula","Missing code","Privacy class","Persisted location / key","CSV header / order","Synthetic example","Validation / fallback","Version introduced","Evidence path"],dictionary,[30,55,32,28,42,24,42,58,30,42,48,34,36,52,22,52]);
  matrix(sheets["Enumerations Values"],"Enumerations and Allowed Values","Source-controlled enum/risk/status values",["Domain","Value","Meaning","Fallback","Evidence"],[
    ["RiskLevel","low","Low ergonomic risk","Source-specific","lib/core/models/evaluation_models.dart"],["RiskLevel","medium","Medium ergonomic risk","Source-specific","lib/core/models/evaluation_models.dart"],["RiskLevel","high","High ergonomic risk","Source-specific","lib/core/models/evaluation_models.dart"],["RiskLevel","veryHigh","Very high ergonomic risk","Source-specific","lib/core/models/evaluation_models.dart"],["Activity","transplanting; fertilizing; pesticide; pruning; harvesting; transport","Supported agricultural activities","No silent coercion","lib/core/models/assessment_session.dart"],["Completion status","source-captured text / blank","UAT/research field","Blank until captured","lib/core/services/assessment_export_service.dart"],["AI outcome","success; unavailable; invalidInput; runtimeError","Advisory inference state","Suppress advisory","lib/core/models/ml_inference_status.dart"],["Handover status",[...allowedStatuses].join("; "),"Controlled document status vocabulary","Reject unknown","Final handover design spec"]
  ],[28,60,50,42,55]);
  matrix(sheets["Derivations"],"Field Derivations and Formulas","Auditable calculations and exact source paths",["Output","Inputs","Formula / rule","Missing behavior","Unit","Evidence"],[
    ["BMI","weight kg; height cm","kg / (m * m)","null / '-' when invalid","kg/m2","lib/app/app_state.dart"],["REBA reduction","REBA_before; REBA_after","before - after","blank when either missing","score points","lib/core/services/assessment_export_service.dart"],["REBA reduction percent","before; reduction","reduction / before","blank if before <=0 or missing","ratio / formatted percent","lib/core/services/assessment_export_service.dart"],["Trend average","latest records","average scoreBefore","empty-window fallback encoded in source","score","lib/core/services/assessment_export_service.dart"],["After economic impact","before impact; score reduction","effectiveReduction=min(max(before-after,0),4); rate=min(1.0,0.28*effectiveReduction); after=round(before*(1-rate)) clamped 0..999999; saved clamped 0..999999","source numeric fallback","THB","lib/core/services/economic_impact_service.dart"],["Lifting index","load; RWL","load / RWL; 99 if RWL <=0","bounded source fallback","ratio","lib/core/services/ergo_calculator.dart"],["Combined risk","REBA; ISO","higher risk index and higher user score","REBA-only when ISO not applicable","tier / score","lib/core/services/ergo_calculator.dart"],["Daily logistic probability","26 normalized features","sigmoid(intercept + sum(beta*x)); clamp 0..1","template only / insufficient history","probability","assets/ml/daily_injury_logistic_model.json"],["Daily displayed tier","high/very-high record count","0-1 Low; 2-3 Watch; 4-5 High; 6-7 Critical","probability thresholds are not used by predictForRecords","tier","lib/core/services/daily_injury_prediction_service.dart"]
  ],[34,50,68,42,26,55]);
  matrix(sheets["Privacy Retention"],"Privacy, Retention, Backup, and Deletion","Source behavior separated from owner/research protocol",["Data class","Examples","Local behavior","Remote behavior","Retention/deletion","Status","Owner action","Evidence"],[
    ["Direct identifiers","name, farmer/participant/profile ID","SharedPreferences/history/export","No assessment backend; user-selected share may leave device","No complete end-to-end schedule in source","Pending Owner Action","Approve lawful basis, access, retention and deletion","lib/app/app_state.dart"],["Participant media linkage","image path, avatar, photo ID/timestamp","Copied to application documents / path persisted","No automatic cloud assessment store","Source does not prove cascading file deletion","Pending Owner Action","Define media custody and erasure verification","lib/core/services/local_image_store.dart"],["Sensitive research/health-adjacent","BMI, MSD placeholders, expert fields, ergonomic risk","Local record/export","Only explicit user share; telemetry separate/default off","Protocol required","Pending Researcher Evidence","Provide consent/ethics/de-identification evidence where applicable","lib/core/services/assessment_export_service.dart"],["Migration backup","sookta.latestBackup","Local pre-migration preference snapshot","N/A with Rationale","No remote disaster recovery","Pending Owner Action","Define backup custody/expiry/restore test","lib/app/app_state.dart"],["Remote database/server retention","N/A","No remote assessment database found","N/A with Rationale","N/A until introduced","N/A with Rationale","Reassess before cloud/API addition","03_API_Applicability_Statement.docx"],["Firebase telemetry","Optional quality events/crashes","Separate from assessment persistence; default off","Firebase only if owner enables","Privacy/store disclosure pending","Pending Owner Action","Approve configuration, ownership, disclosure","lib/core/services/firebase_telemetry_service.dart"]
  ],[34,48,58,45,50,30,58,55]);
  matrix(sheets["Migration Compatibility"],"Migration and Compatibility","Current schema version and fail-safe boundaries",["Control","Value","Behavior","Risk","Status","Evidence"],[
    ["Current data schema version",facts.data_schema_version,"Stored at sookta.dataSchemaVersion","Prior schema compatibility must be regression-tested","Complete","lib/app/app_state.dart"],["Legacy profile adoption","Enabled","Legacy profile is normalized and added to farmers list","Incorrect identity linkage if source data malformed","Complete","lib/app/app_state.dart"],["Legacy draft adoption","Enabled","Draft may be enriched with adopted profile ID","Review per-profile association","Complete","lib/app/app_state.dart"],["Pre-migration backup","sookta.latestBackup","Captures local payload before schema migration","Not complete device/cloud backup","Complete","lib/app/app_state.dart"],["Restore exception","Reset in-memory restored state","App hydrates with default state","Reset screen is not proof of deletion","Complete","lib/app/app_state.dart"],["Remote schema/API migration","Not present","N/A with Rationale","Must be designed before cloud introduction","N/A with Rationale","03_API_Applicability_Statement.docx"]
  ],[38,34,60,55,30,55]);
  matrix(sheets["Evidence Sources"],"Evidence Sources","Every cited source must resolve at authoritative baseline",["Path","Status","SHA-256","Use"],facts.source_citations.map(r=>[r.path,r.status,r.sha256,"Data/persistence/export contract evidence"]),[58,30,36,60]);
  matrix(sheets["Human Actions"],"Human-Owned Actions","Technical completeness does not imply governance acceptance",["Action ID","Action","Owner","Status","Closure evidence"],humanRows(facts),[18,82,30,30,55]);
  const summary=sheets["Control Summary"]; matrix(summary,"Data Management Control Summary","Formula-driven schema/privacy/migration gates",["Metric","Value","Acceptance gate"],[
    ["Persisted keys / record fields",null,"Matches source serialization maps"],["All-history export columns",null,"Exact source order"],["Sensitive export fields",null,"Privacy review required"],["Pending owner/researcher actions",null,"Must remain visible"],["Current schema version",null,"Must equal source constant"],["Remote database","N/A with Rationale","No remote assessment schema in source"],["Overall status","Complete - Pending Signature","Owner/researcher approval/signature pending"]
  ],[42,24,72]);
  summary.getRange("B5").formulas=[["=COUNTA('Persisted Keys Records'!A5:A500)"]]; summary.getRange("B6").formulas=[["=COUNTA('Export Schema Order'!A5:A200)"]]; summary.getRange("B7").formulas=[["=COUNTIF('Export Schema Order'!J5:J200,\"Sensitive research/health-adjacent\")"]]; summary.getRange("B8").formulas=[["=COUNTIF('Human Actions'!D5:D100,\"Pending Owner Action\")+COUNTIF('Human Actions'!D5:D100,\"Pending Researcher Evidence\")"]]; summary.getRange("B9").formulas=[["='Migration Compatibility'!B5"]];
  return {wb,dictionary};
}

async function build() {
  const facts=JSON.parse(await fs.readFile(path.join(STAGING,"working","task5","task5_build_input.json"),"utf8"));
  const algorithm=await buildAlgorithm(facts); const dataBuilt=await buildData(facts); const data=dataBuilt.wb;
  const contracts=[]; const expectedValues={
    "algorithm:Control Summary!B5":facts.model_algorithm_inventory.length,
    "algorithm:Control Summary!B6":facts.model_algorithm_inventory.filter(r=>r.training_class==="Project-trained").length,
    "algorithm:Control Summary!B7":facts.recommendation_messages.length,
    "algorithm:Control Summary!B8":facts.reference_sources.length,
    "algorithm:Control Summary!B9":humanRows(facts).filter(r=>["Pending Owner Action","Pending Researcher Evidence"].includes(r[3])).length,
    "data:Control Summary!B5":persistedRows(facts).length,
    "data:Control Summary!B6":facts.all_history_csv_headers.length,
    "data:Control Summary!B7":dataBuilt.dictionary.filter(r=>r[9]==="Sensitive research/health-adjacent").length,
    "data:Control Summary!B8":humanRows(facts).filter(r=>["Pending Owner Action","Pending Researcher Evidence"].includes(r[3])).length,
    "data:Control Summary!B9":facts.data_schema_version,
  };
  for(const contract of formulaContracts()){const wb=contract.workbook==="algorithm"?algorithm:data; contracts.push(await inspectFormulaContract(wb,contract,expectedValues[`${contract.workbook}:${contract.range}`]));}
  let errorMatches=0; const scans={}; for(const [name,wb] of [["algorithm",algorithm],["data",data]]){const scan=await wb.inspect({kind:"match",searchTerm:"#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",options:{useRegex:true,maxResults:300},summary:`${name} final formula error scan`,maxChars:10000}); scans[name]=scan.ndjson; const records=scan.ndjson.split(/\r?\n/).filter(x=>x.trim()).map(JSON.parse); if(!(records.length===1&&records[0].kind==="notice"&&/matched 0 entries/i.test(records[0].message??""))) throw new Error(`Formula error scan failed: ${scan.ndjson}`);}
  const outDir=path.join(STAGING,"artifacts"); await fs.mkdir(outDir,{recursive:true});
  const algoStem="04_Algorithm_Recommendation_and_Reference_Matrices"; const dataStem="05_Data_Dictionary_and_Export_Schema";
  const algoRenders=await renderWorkbook(algorithm,algoStem,algorithmSheetNames); const dataRenders=await renderWorkbook(data,dataStem,dataSheetNames);
  const algoPath=path.join(outDir,`${algoStem}.xlsx`); const dataPath=path.join(outDir,`${dataStem}.xlsx`);
  await (await SpreadsheetFile.exportXlsx(algorithm)).save(algoPath); await applyPrintSettings(algoPath);
  await (await SpreadsheetFile.exportXlsx(data)).save(dataPath); await applyPrintSettings(dataPath);
  const summary={status:"passed",sheets:algorithmSheetNames.length+dataSheetNames.length,algorithm_sheets:algorithmSheetNames.length,data_sheets:dataSheetNames.length,model_algorithm_records:facts.model_algorithm_inventory.length,persisted_schema_rows:persistedRows(facts).length,export_schema_rows:dataBuilt.dictionary.length,formula_contracts:contracts,formula_error_matches:errorMatches,formula_error_scans:scans,renders:[...algoRenders,...dataRenders]};
  await fs.writeFile(path.join(STAGING,"manifests","task5_workbook_build_summary.json"),JSON.stringify(summary,null,2)+"\n"); console.log(JSON.stringify(summary,null,2));
}

if(import.meta.url===pathToFileURL(process.argv[1]).href) build().catch(error=>{console.error(error);process.exitCode=1;});
