#!/usr/bin/env node
// Build Task 4 stack/module workbook with @oai/artifact-tool.
import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";
import JSZip from "jszip";

const VERSION="1.3.11+28";
const COMMIT="bf8867a2083357cb9d60915bf6c2233801f923d8";
const STAGING="/private/tmp/fsookta-final-handover";
const colors={navy:"#17365D",blue:"#D9EAF7",pale:"#F4F7FA",white:"#FFFFFF",ink:"#1F2937",gray:"#6B7280",line:"#CBD5E1",amber:"#FFF2CC",green:"#E2F0D9"};

function parseNdjson(ndjson){const lines=ndjson.split(/\r?\n/).filter(x=>x.trim());if(!lines.length)throw new Error("Formula error scan empty or ambiguous");return lines.map(JSON.parse);}
export function assertFormulaErrorScanClean(ndjson){const rows=parseNdjson(ndjson);const notices=rows.filter(r=>r.kind==="notice"&&/matched 0 entries/i.test(r.message??""));const others=rows.filter(r=>!(r.kind==="notice"&&/matched 0 entries/i.test(r.message??"")));if(notices.length!==1||others.length)throw new Error(`Formula error scan failed or ambiguous: ${JSON.stringify(rows)}`);}
export function assertFormulaContract(actual,expected,label){if(JSON.stringify(actual.formulas)!==JSON.stringify(expected.formulas)||JSON.stringify(actual.values)!==JSON.stringify(expected.values))throw new Error(`Formula contract mismatch at ${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);}
export function countLocalStorageRows(rows){return rows.filter(row=>String(row[0]??"").toLowerCase().includes("local")).length;}

function title(sheet,title,subtitle,last){sheet.showGridLines=false;sheet.mergeCells(`A1:${last}1`);sheet.getRange("A1").values=[[title]];sheet.getRange(`A1:${last}1`).format={fill:colors.navy,font:{name:"Arial",size:18,bold:true,color:colors.white},verticalAlignment:"center"};sheet.getRange(`A1:${last}1`).format.rowHeight=30;sheet.mergeCells(`A2:${last}2`);sheet.getRange("A2").values=[[subtitle]];sheet.getRange(`A2:${last}2`).format={fill:colors.pale,font:{name:"Arial",size:10,color:colors.gray},wrapText:true};sheet.getRange(`A2:${last}2`).format.rowHeight=30;}
function header(range){range.format={fill:colors.blue,font:{name:"Arial",size:10,bold:true,color:colors.ink},wrapText:true,verticalAlignment:"center",borders:{preset:"outside",style:"thin",color:colors.line}};range.format.rowHeight=38;}
function body(range){range.format={font:{name:"Arial",size:9,color:colors.ink},wrapText:true,verticalAlignment:"top",borders:{insideHorizontal:{style:"thin",color:colors.line},bottom:{style:"thin",color:colors.line}}};}

async function applyPrintSettings(output){
 const zip=await JSZip.loadAsync(await fs.readFile(output));
 for(const name of Object.keys(zip.files).filter(n=>/^xl\/worksheets\/sheet\d+\.xml$/.test(n))){
  let xml=await zip.file(name).async("string");const prefix=xml.match(/<([A-Za-z0-9_]+:)?worksheet\b/)?.[1]??"";const tag=x=>`${prefix}${x}`;
  if(new RegExp(`<${tag("sheetPr")}\\b[^>]*\\/>`).test(xml))xml=xml.replace(new RegExp(`<${tag("sheetPr")}\\b([^>]*)\\/>`),`<${tag("sheetPr")}$1><${tag("pageSetUpPr")} fitToPage="1"/></${tag("sheetPr")}>`);
  else if(new RegExp(`<${tag("sheetPr")}\\b`).test(xml))xml=xml.replace(new RegExp(`</${tag("sheetPr")}>`),`<${tag("pageSetUpPr")} fitToPage="1"/></${tag("sheetPr")}>`);
  else xml=xml.replace(new RegExp(`(<${tag("worksheet")}\\b[^>]*>)`),`$1<${tag("sheetPr")}><${tag("pageSetUpPr")} fitToPage="1"/></${tag("sheetPr")}>`);
  for(const local of ["printOptions","pageMargins","pageSetup"])xml=xml.replace(new RegExp(`<${tag(local)}\\b[^>]*\\/>`,"g"),"");
  xml=xml.replace(`</${tag("worksheet")}>`,`<${tag("printOptions")} horizontalCentered="1"/><${tag("pageMargins")} left="0.2" right="0.2" top="0.35" bottom="0.35" header="0.15" footer="0.15"/><${tag("pageSetup")} paperSize="8" orientation="landscape" fitToWidth="1" fitToHeight="0" horizontalDpi="300" verticalDpi="300"/></${tag("worksheet")}>`);
  zip.file(name,xml);
 }
 await fs.writeFile(output,await zip.generateAsync({type:"nodebuffer",compression:"DEFLATE",compressionOptions:{level:9}}));
}

const modules=[
 ["App bootstrap and telemetry","App launch / build flag","Initialize Flutter; fail-safe Firebase; install handlers only when enabled","Running UI; optional quality telemetry","firebase_core / analytics / crashlytics","Network only if explicitly opted in","Missing config; Firebase unavailable","lib/main.dart; lib/core/services/firebase_telemetry_service.dart","Source inspection at final commit"],
 ["App state and profiles","Language, farmer profile, drafts, history","Serialize, migrate, backup and restore local state","Active state and persisted records","shared_preferences","Local device only","Malformed/legacy state; storage failure","lib/app/app_state.dart","Source + tests"],
 ["Onboarding and navigation","User selections and navigation","Route between setup, home, assessment, results, history, profile","Screen state","Flutter widgets","No assessment network","Invalid route; incomplete setup","lib/screens/onboarding/; lib/screens/main/","Source + widget tests"],
 ["Camera/gallery acquisition","Camera or gallery action","Capture/select local media","Local path / image bytes","camera; image_picker","Device media permission only","Permission denied; unreadable media","lib/screens/main/camera_capture_screen.dart","Source + device evidence pending"],
 ["Video frame extraction","Local video","Extract representative frames","Frame files and timestamps","video/platform tooling","Local file I/O","Unsupported/invalid video","lib/core/services/video_frame_extraction_service.dart","Source + tests"],
 ["Pose estimation","Decoded local image","Letterbox 256x256; local MoveNet inference; confidence threshold","17 keypoints or unavailable","tflite_flutter; movenet_thunder.tflite","Offline local inference","Decode failure; model unavailable; low confidence","lib/core/services/pose_estimation_service.dart; lib/core/services/pose_image_preprocessor.dart","Source + model tests"],
 ["Multi-person detection","Local image","Local multipose inference and person filtering","Detected people","movenet_multipose_lightning.tflite","Offline local inference","No person; ambiguity; low confidence","lib/core/services/multi_person_pose_detector.dart","Source + tests"],
 ["Ergonomic calculation","Pose-derived + manual task input","REBA tables; applied ISO lifting/push-pull; higher applicable risk","Score, tier, breakdown","Dart domain logic","Offline local calculation","Missing inputs; bounded/clamped values","lib/core/services/ergo_calculator.dart","Source + algorithm tests"],
 ["Advisory risk model","Joint features + deterministic result","Local ONNX advisory inference; attach alert separately","Advisory alert / fallback","onnxruntime; xgboost_model.onnx","Offline local inference","Model unavailable; schema mismatch","lib/core/services/risk_alert_model_service.dart; lib/core/services/xgboost_advisory_service.dart","Source + model metadata"],
 ["Daily prediction","Local history features","Apply JSON template coefficients","Advisory probability/context","daily_injury_logistic_model.json","Offline local calculation","Insufficient history; invalid model JSON","lib/core/services/daily_injury_prediction_service.dart","Source; not clinical validation"],
 ["Recommendations","Activity, tier, body-area risk","Map source keys; deduplicate; cap categories; localize","Bilingual action suggestions","Source-controlled rules","Offline local calculation","Missing catalog key; research wording approval pending","lib/core/services/risk_recommendation_service.dart","Source + tests"],
 ["Economic impact context","Risk, profile income, body areas","Estimate and compare configured cost context","Before/after context","Dart domain logic","Offline local calculation","Missing profile values; interpretive limits","lib/core/services/economic_impact_service.dart","Source + tests"],
 ["Local media store","Temporary/captured file","Copy into application documents when needed","Persistent local path","path_provider; path","Local file I/O","Missing source; copy failure","lib/core/services/local_image_store.dart","Source + persistence tests"],
 ["History and export","Assessment record and user action","Build CSV; write to app documents; invoke OS share","Local CSV / share sheet","path_provider; share_plus","No network unless user selects a share target","Write/share cancellation or platform error","lib/core/services/assessment_export_service.dart; lib/screens/main/history_tab.dart","Source + export tests"],
];

export function technologyStack(facts={}) {
 const resolved={
  camera:"0.11.4",image_picker:"1.2.2",tflite_flutter:"0.12.1",onnxruntime:"1.4.1",
  shared_preferences:"2.5.5",path_provider:"2.1.5",share_plus:"13.1.0",firebase_core:"4.10.0",
  firebase_analytics:"12.4.2",firebase_crashlytics:"5.2.2",flutter_tts:"4.2.5",
  ...(facts.resolved_packages??{}),
 };
 const models={
  xgboost:"reba-iso-xgboost-onnx-2026-06-07",
  daily_logistic:"daily-injury-logistic-template-2026-06-14",
  movenet_schema:"movenet-thunder-v1-17x3-normalized",
  movenet_schema_version:"2026-05-17",
  movenet_thunder_sha256:"8014d8fe22285265f52aa1cea84056b7704f75adf12341a7712d4cb28bd1d9b6",
  movenet_multipose_sha256:"d4489f89e6bd6777a8b9a1a16189832131f84ff90d82fae729e670b84d7948dd",
  ...(facts.model_versions??{}),
 };
 return [
 ["Flutter framework","3.41.9","Cross-platform UI/runtime","verification_environment.json"],
 ["Dart","3.11.5","Application language/runtime","verification_environment.json"],
 ["Application","1.3.11+28","Frozen deliverable baseline","pubspec.yaml"],
 ["camera",`${resolved.camera} (resolved)`,"Media capture","pubspec.lock"],
 ["image_picker",`${resolved.image_picker} (resolved)`,"Gallery acquisition","pubspec.lock"],
 ["tflite_flutter",`${resolved.tflite_flutter} (resolved)`,"Local MoveNet inference","pubspec.lock"],
 ["onnxruntime",`${resolved.onnxruntime} (resolved; local override source)`,"Local advisory ONNX inference","pubspec.lock; third_party/onnxruntime_16kb"],
 ["shared_preferences",`${resolved.shared_preferences} (resolved)`,"Local serialized state","pubspec.lock"],
 ["path_provider",`${resolved.path_provider} (resolved)`,"Application documents/temp paths","pubspec.lock"],
 ["share_plus",`${resolved.share_plus} (resolved)`,"User-initiated OS share","pubspec.lock"],
 ["flutter_tts",`${resolved.flutter_tts} (resolved)`,"On-device spoken output through platform plugin","pubspec.lock"],
 ["firebase_core",`${resolved.firebase_core} (resolved)`,"Optional telemetry bootstrap","pubspec.lock"],
 ["firebase_analytics",`${resolved.firebase_analytics} (resolved)`,"Optional opt-in product telemetry","pubspec.lock"],
 ["firebase_crashlytics",`${resolved.firebase_crashlytics} (resolved)`,"Optional opt-in crash telemetry","pubspec.lock"],
 ["MoveNet Thunder",`${models.movenet_schema} schema v${models.movenet_schema_version}; asset SHA-256 ${models.movenet_thunder_sha256}; upstream artifact release/version not recorded in repo`,"Local single-person pose; 256x256 / 17 landmarks","assets/ml/movenet_thunder.tflite; assets/models/joint_feature_schema.json"],
 ["MoveNet MultiPose Lightning",`asset SHA-256 ${models.movenet_multipose_sha256}; upstream artifact release/version not recorded in repo`,"Local multi-person detection","assets/ml/movenet_multipose_lightning.tflite"],
 ["XGBoost advisory",models.xgboost,"Advisory only; does not replace REBA/ISO","assets/models/xgboost_model.onnx; assets/models/xgboost_model_metadata.json"],
 ["Daily logistic template",models.daily_logistic,"Template coefficients; research-trained=false; advisory trend context only","assets/ml/daily_injury_logistic_model.json"],
 ];
}

async function build(){
 const buildInput=JSON.parse(await fs.readFile(path.join(STAGING,"working","task4","task4_build_input_summary.json"),"utf8"));
 const stack=technologyStack(buildInput.source_facts);
 const wb=Workbook.create();const summary=wb.worksheets.add("Summary");const mod=wb.worksheets.add("Modules");const tech=wb.worksheets.add("Technology Stack");const evidence=wb.worksheets.add("Evidence Sources");
 title(mod,"SookTa Technical Module Specification",`Final baseline ${VERSION} | Git ${COMMIT} | Source-grounded behavior and explicit failure boundaries`,"I");
 const mh=["Module","Input","Processing","Output","Dependencies","Storage / Network","Failure modes","Source path","Evidence basis"];mod.getRange("A4:I4").values=[mh];header(mod.getRange("A4:I4"));mod.getRange(`A5:I${modules.length+4}`).values=modules;body(mod.getRange(`A5:I${modules.length+4}`));mod.tables.add(`A4:I${modules.length+4}`,true,"ModuleSpecification").style="TableStyleMedium2";mod.freezePanes.freezeRows(4);[24,27,38,25,28,30,32,42,28].forEach((w,i)=>mod.getRangeByIndexes(0,i,modules.length+4,1).format.columnWidth=w);mod.getRange(`A5:I${modules.length+4}`).format.rowHeight=64;
 title(tech,"Technology and Model Stack",`Declared/resolved evidence for ${VERSION}; package-license conclusions remain in the Task 3 register`,"D");tech.getRange("A4:D4").values=[["Component","Version / identifier","Role","Evidence source"]];header(tech.getRange("A4:D4"));tech.getRange(`A5:D${stack.length+4}`).values=stack;body(tech.getRange(`A5:D${stack.length+4}`));tech.tables.add(`A4:D${stack.length+4}`,true,"TechnologyStack").style="TableStyleMedium2";tech.freezePanes.freezeRows(4);[30,34,48,55].forEach((w,i)=>tech.getRangeByIndexes(0,i,stack.length+4,1).format.columnWidth=w);tech.getRange(`A5:D${stack.length+4}`).format.rowHeight=32;tech.getRange("A19:D22").format.rowHeight=58;
 const sources=[["Source / evidence","Authority","Use","Status"],["pubspec.yaml; pubspec.lock","Final source","Version and dependency evidence","Complete"],["lib/app/; lib/core/; lib/screens/","Final source","Runtime architecture and module behavior","Complete"],["assets/ml/; assets/models/","Final source","Bundled model role/provenance paths","Complete"],["flutter_analyze_1.3.11+28.log","Reproduced final evidence","Static analysis","Complete"],["flutter_test_1.3.11+28.log","Reproduced final evidence","135-test automated result","Complete"],["build_android_1.3.11+28.log; build_ios_1.3.11+28.log","Reproduced technical build evidence","Platform build status; production signing not inferred","Pending Owner Action"],["Physical-device/UAT/performance evidence","Owner / researcher","Camera, gallery, TTS, share, inference, thresholds","Pending Researcher Evidence"],["Authorized acceptance/signatures","Owner / researcher","Final acceptance","Complete - Pending Signature"]];
 title(evidence,"Evidence Sources and Boundaries",`No clinical/external-validity claim; human-owned facts remain pending | ${COMMIT}`,"D");evidence.getRange(`A4:D${sources.length+3}`).values=sources;header(evidence.getRange("A4:D4"));body(evidence.getRange(`A5:D${sources.length+3}`));evidence.tables.add(`A4:D${sources.length+3}`,true,"EvidenceSources").style="TableStyleMedium2";[45,30,52,30].forEach((w,i)=>evidence.getRangeByIndexes(0,i,sources.length+3,1).format.columnWidth=w);evidence.getRange(`A5:D${sources.length+3}`).format.rowHeight=48;
 title(summary,"Architecture Coverage Summary",`Formula-driven control view for ${VERSION}; update Modules and Evidence Sources to refresh`,"D");summary.getRange("A4:B9").values=[["Metric","Value"],["Module records",null],["Modules with storage/network behavior documented",null],["Modules with explicit failure modes",null],["Evidence rows",null],["Outstanding human-action rows",null]];header(summary.getRange("A4:B4"));summary.getRange("B5").formulas=[[`=COUNTA('Modules'!A5:A18)`]];summary.getRange("B6").formulas=[[`=COUNTA('Modules'!F5:F18)`]];summary.getRange("B7").formulas=[[`=COUNTA('Modules'!G5:G18)`]];summary.getRange("B8").formulas=[[`=COUNTA('Evidence Sources'!A5:A12)`]];summary.getRange("B9").formulas=[[`=COUNTIF('Evidence Sources'!D5:D12,"Pending Owner Action")+COUNTIF('Evidence Sources'!D5:D12,"Pending Researcher Evidence")+COUNTIF('Evidence Sources'!D5:D12,"Complete - Pending Signature")`]];body(summary.getRange("A5:B9"));summary.getRange("A11:D15").values=[["Control","Result","Basis","Action"],["Backend assessment API","N/A with Rationale","No direct HTTP/Dio/GraphQL/WebSocket/Firebase DB client in final assessment source","Reassess if remote APIs are introduced"],["Telemetry","Optional; default off","SOOKTA_TELEMETRY_ENABLED defaultValue false","Owner approval before enabling"],["Remote database","N/A with Rationale","SharedPreferences/app documents are local","Define auth/schema/migration if cloud sync is introduced"],["Acceptance","Pending","Access, device/UAT evidence, legal review and signatures","Human-owned action"]];header(summary.getRange("A11:D11"));body(summary.getRange("A12:D15"));[34,24,60,45].forEach((w,i)=>summary.getRangeByIndexes(0,i,15,1).format.columnWidth=w);summary.getRange("A12:D15").format.rowHeight=55;
 const contracts=[];const formulaExpectations=[{range:"B5",formulas:[["=COUNTA('Modules'!A5:A18)"]],values:[[14]]},{range:"B6",formulas:[["=COUNTA('Modules'!F5:F18)"]],values:[[14]]},{range:"B7",formulas:[["=COUNTA('Modules'!G5:G18)"]],values:[[14]]},{range:"B8",formulas:[["=COUNTA('Evidence Sources'!A5:A12)"]],values:[[8]]},{range:"B9",formulas:[["=COUNTIF('Evidence Sources'!D5:D12,\"Pending Owner Action\")+COUNTIF('Evidence Sources'!D5:D12,\"Pending Researcher Evidence\")+COUNTIF('Evidence Sources'!D5:D12,\"Complete - Pending Signature\")"]],values:[[3]]}];
 for(const c of formulaExpectations){const r=summary.getRange(c.range);const actual={formulas:r.formulas,values:r.values};assertFormulaContract(actual,c,`Summary!${c.range}`);contracts.push({range:`Summary!${c.range}`,expected:c,actual,status:"passed"});}
 const scan=await wb.inspect({kind:"match",searchTerm:"#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",options:{useRegex:true,maxResults:300},summary:"final formula error scan",maxChars:10000});assertFormulaErrorScanClean(scan.ndjson);
 const outDir=path.join(STAGING,"artifacts");const renderDir=path.join(STAGING,"renders","task4","xlsx");await fs.mkdir(outDir,{recursive:true});await fs.mkdir(renderDir,{recursive:true});
 const renders=[];for(const name of ["Summary","Modules","Technology Stack","Evidence Sources"]){const preview=await wb.render({sheetName:name,autoCrop:"all",scale:1.35,format:"png"});const output=path.join(renderDir,`03_Technical_Stack_and_Module_Specification__${name.replaceAll(/[^A-Za-z0-9]+/g,"_")}.png`);await fs.writeFile(output,new Uint8Array(await preview.arrayBuffer()));renders.push(output);}
 const output=path.join(outDir,"03_Technical_Stack_and_Module_Specification.xlsx");const xlsx=await SpreadsheetFile.exportXlsx(wb);await xlsx.save(output);await applyPrintSettings(output);
 const result={status:"passed",workbook:output,sheets:4,module_records:14,stack_records:stack.length,formula_contracts:contracts,formula_error_scan:scan.ndjson,renders};await fs.writeFile(path.join(STAGING,"manifests","task4_workbook_build_summary.json"),JSON.stringify(result,null,2)+"\n");console.log(JSON.stringify(result,null,2));
}
if(import.meta.url===pathToFileURL(process.argv[1]).href)build().catch(e=>{console.error(e);process.exitCode=1;});
