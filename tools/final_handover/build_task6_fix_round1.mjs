import fs from 'node:fs/promises';
import path from 'node:path';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const ROOT='/private/tmp/fsookta-final-handover';
const A=path.join(ROOT,'artifacts');
const payload=JSON.parse(await fs.readFile(path.join(ROOT,'working/task6/task6_corrected_payload.json'),'utf8'));
const font={name:'Arial',size:9,color:'#172033'};
function matrix(rows){return rows.map(r=>r.map(v=>v===undefined||v===null?'':typeof v==='object'?JSON.stringify(v):v));}
function reset(sheet){const used=sheet.getUsedRange(); if(used) used.clear({applyTo:'all'}); sheet.showGridLines=false;}
function renderTable(sheet,title,subtitle,headers,rows,widths=[]){
 reset(sheet); const cols=headers.length; const end=colName(cols);
 sheet.getRange(`A1:${end}1`).merge(); sheet.getRange('A1').values=[[title]];
 sheet.getRange(`A2:${end}2`).merge(); sheet.getRange('A2').values=[[subtitle]];
 sheet.getRange(`A4:${end}4`).values=[headers];
 if(rows.length) sheet.getRange(`A5:${end}${rows.length+4}`).values=matrix(rows);
 sheet.getRange(`A1:${end}${rows.length+4}`).format={font,verticalAlignment:'top',wrapText:true};
 sheet.getRange(`A1:${end}1`).format={fill:'#17365D',font:{name:'Arial',size:16,bold:true,color:'#FFFFFF'},rowHeight:28};
 sheet.getRange(`A2:${end}2`).format={fill:'#D9EAF7',font:{name:'Arial',size:9,italic:true,color:'#17365D'},rowHeight:30};
 sheet.getRange(`A4:${end}4`).format={fill:'#2F75B5',font:{name:'Arial',size:9,bold:true,color:'#FFFFFF'},rowHeight:30,borders:{preset:'all',style:'thin',color:'#9FBAD0'}};
 if(rows.length) sheet.getRange(`A5:${end}${rows.length+4}`).format.borders={preset:'inside',style:'thin',color:'#D9E2F3'};
 widths.forEach((w,i)=>sheet.getRange(`${colName(i+1)}:${colName(i+1)}`).format.columnWidth=w);
 sheet.freezePanes.freezeRows(4);
}
function colName(n){let s=''; while(n){n--;s=String.fromCharCode(65+n%26)+s;n=Math.floor(n/26)}return s;}
function reqRows(){return payload.requirements.map(r=>[r.requirement_id,r.status,JSON.stringify(r.authoritative_sources),r.human_action,r.rationale,String(r.final_version_claim),JSON.stringify(r.task2_evidence),JSON.stringify(r.task6_evidence)]);}
function passTuple(r){const e=r.evidence_tuple||{};return [r.case_id,r.name,r.category,r.status,e.baseline||'',e.timestamp||'',e.method||'',e.raw_path||'',e.sha256||'',r.actual||'',r.limitations||'',r.source_path||''];}
async function load(file){return SpreadsheetFile.importXlsx(await FileBlob.load(file));}
async function save(wb,file){const out=await SpreadsheetFile.exportXlsx(wb);await out.save(file);}

async function audit(){
 const file=path.join(A,'06_Development_Audit_Trail.xlsx'); console.log('audit=load'); const wb=await load(file); console.log('audit=loaded');
 renderTable(wb.worksheets.getItem('Control Summary'),'Development Audit Trail - Corrected Evidence Model',payload.claim_boundary,['Metric','Value','Control'],[
  ['Requirements',155,'All evidence_map.records preserved'],['Pending Owner Action',137,'Source status'],['Exception Approval Required',12,'Source status'],['Pending Researcher Evidence',6,'Source status'],['Historical defects',payload.defects.length,'Exact commits/paths/hashes'],['Before/After rows',payload.before_after.length,'Resolvable evidence only']],[28,18,70]);
 console.log('audit=summary');
 renderTable(wb.worksheets.getItem('Requirement Traceability'),'Requirement Traceability - Source Status Preserved','155 governing records; terminal status counts 137 / 12 / 6',['Requirement ID','Source status','Authoritative sources','Human action','Rationale','Final claim','Task 2 evidence layer','Task 6 evidence layer'],reqRows(),[14,24,65,55,58,12,55,55]);
 console.log('audit=req'); renderTable(wb.worksheets.getItem('Before After Evidence'),'Before / After Evidence - Historical Corrections','Exact commits, source paths, evidence paths and hashes; no generic placeholders',['Change ID','Before commit','After commit','Source path','Before','After','Evidence path','SHA-256'],payload.before_after.map(r=>[r.change_id,r.before_commit,r.after_commit,r.source_path,r.before,r.after,r.evidence_path,r.sha256]),[16,42,42,45,45,45,50,68]);
 console.log('audit=beforeafter'); await save(wb,file); console.log('audit=saved');
}
async function master(){
 const file=path.join(A,'07_Master_Test_and_Verification_Package.xlsx'); const wb=await load(file);
 const cats={}; for(const t of payload.tests) cats[t.category]=(cats[t.category]||0)+1;
 renderTable(wb.worksheets.getItem('Control Summary'),'Master Test and Verification Package - Corrected',payload.claim_boundary,['Metric','Value','Control'],[['Exact automated cases',135,'Stateful expanded-reporter reconstruction'],...Object.entries(cats),['PASS evidence rows',payload.result_rows.filter(r=>r.status==='PASS').length,'Every PASS is hash-bound'],['Firebase final runtime','Not Executed','No unsupported PASS'],['Physical-device acceptance','Not Executed','Human action']],[34,22,70]);
 renderTable(wb.worksheets.getItem('Test Plan'),'Final Test Plan','Plans are not results; Firebase/device rows stay non-result until exact evidence exists',['Case ID','Plan / test','Category','Status','Baseline','Timestamp','Method','Raw path','SHA-256','Actual','Limitations','Source path'],payload.result_rows.filter(r=>!r.case_id.startsWith('AUTO-')).map(passTuple),[18,52,24,34,18,24,55,45,68,48,60,45]);
 const autoRows=payload.result_rows.filter(r=>r.case_id.startsWith('AUTO-')).map(passTuple);
 renderTable(wb.worksheets.getItem('Automated Suite'),'Final Automated Suite - Exact 135 Completed Tests','+N attributes completion to the preceding displayed test; +135 All tests passed is terminal proof, not a test',['Case ID','Test name','Category','Status','Baseline','Timestamp','Method','Raw path','SHA-256','Actual','Limitations','Source path'],autoRows,[16,70,26,12,18,24,55,45,68,48,65,52]);
 renderTable(wb.worksheets.getItem('Functional Cases'),'Functional / Regression Categories','Category membership reconstructed from exact source path and test name',['Case ID','Test name','Category','Status','Source path'],payload.result_rows.filter(r=>r.case_id.startsWith('AUTO-')).map(r=>[r.case_id,r.name,r.category,r.status,r.source_path]),[16,75,28,12,52]);
 renderTable(wb.worksheets.getItem('Integration Regression'),'Integration / Regression Evidence','Exact order retained; category does not change PASS evidence tuple',['Case ID','Ordinal','Test name','Category','Raw path','SHA-256'],payload.result_rows.filter(r=>r.case_id.startsWith('AUTO-')).map(r=>[r.case_id,r.ordinal,r.name,r.category,r.evidence_tuple.raw_path,r.evidence_tuple.sha256]),[16,10,75,28,48,68]);
 renderTable(wb.worksheets.getItem('Requirement Test Trace'),'Requirement Status and Test-Evidence Boundary','Governing terminal statuses preserved; automated evidence does not close owner/researcher/exception actions',['Requirement ID','Source status','Human action','Rationale','Task 2 evidence','Task 6 evidence'],payload.requirements.map(r=>[r.requirement_id,r.status,r.human_action,r.rationale,JSON.stringify(r.task2_evidence),JSON.stringify(r.task6_evidence)]),[14,26,58,60,58,58]);
 renderTable(wb.worksheets.getItem('Bugs Corrections Retest'),'Historical Bugs / Corrections / Retest','Exact historical fixes; not final physical-device evidence',['Defect ID','Version','Description','Before commit','After commit','Source path','Fix','Retest','Evidence path','SHA-256','Status'],payload.defects.map(r=>[r.defect_id,r.version,r.description,r.before_commit,r.after_commit,r.source_path,r.fix,r.retest,r.evidence_path,r.sha256,r.status]),[18,16,50,42,42,48,45,55,50,68,40]);
 renderTable(wb.worksheets.getItem('Evidence Index'),'Hash-bound PASS Evidence Index','Every PASS row has case ID, baseline, timestamp, method, raw path and SHA-256',['Case ID','Status','Baseline','Timestamp','Method','Raw path','SHA-256'],payload.result_rows.filter(r=>r.status==='PASS').map(r=>[r.case_id,r.status,r.evidence_tuple.baseline,r.evidence_tuple.timestamp,r.evidence_tuple.method,r.evidence_tuple.raw_path,r.evidence_tuple.sha256]),[18,12,18,24,58,48,68]);
 await save(wb,file);
}
async function uat(){
 const file=path.join(A,'08_UAT_Field_Test_and_Usability_Package.xlsx'); const wb=await load(file);
 renderTable(wb.worksheets.getItem('Control Summary'),'UAT, Field Test, and Usability Package - Controlled',payload.claim_boundary,['Metric','Value','Control'],[['Final participants',0,'Pending Researcher Evidence'],['Historical records',7,'Never promoted to final baseline'],['SUS item count',10,'Controlled wording'],['SUS response input range','D5:D14','Includes row 5; whole numbers 1-5'],['SUS anchors','1 / 5','Strongly disagree / Strongly agree'],['Acceptance','Pending','Authorized human signature required']],[34,24,70]);
 renderTable(wb.worksheets.getItem('Historical Evidence'),'Historical UAT Evidence - Exact Metadata','Device, runner/harness, build workaround, assessment bypass, blocker and observation remain distinct',['Evidence ID','Date','Version','Device','Runner / harness','Build workaround','Assessment bypass','Blocker','Observation','Evidence path','SHA-256','Layer'],payload.historical_uat.map(r=>[r.evidence_id,r.date,r.version,r.device,r.runner_harness,r.build_workaround,r.assessment_bypass,r.blocker,r.observation,r.evidence_path,r.sha256,r.evidence_layer]),[18,18,16,50,50,50,42,52,58,50,68,34]);
 renderTable(wb.worksheets.getItem('Issues Retest'),'Historical Issues and Retest','Exact corrections remain historical; final device/UAT gaps stay open',['Defect ID','Version','Description','Fix','Retest','Evidence path','SHA-256','Status'],payload.defects.map(r=>[r.defect_id,r.version,r.description,r.fix,r.retest,r.evidence_path,r.sha256,r.status]),[18,16,52,48,55,50,68,42]);
 const s=wb.worksheets.getItem('SUS Response Form'); reset(s);
 s.getRange('A1:D1').merge(); s.getRange('A1').values=[['System Usability Scale (SUS) - Controlled Instrument']];
 s.getRange('A2:D2').merge(); s.getRange('A2').values=[[payload.sus.instrument+' | 1 = Strongly disagree | 5 = Strongly agree']];
 s.getRange('A4:D4').values=[['Item','Approved item wording','Scale anchors','Response']];
 s.getRange('A5:D14').values=payload.sus.items.map(x=>[`Item ${x.item}`,x.wording,'1 Strongly disagree / 5 Strongly agree','']);
 s.getRange('C16').values=[['SUS score']]; s.getRange('D16').formulas=[['=IF(COUNT(D5:D14)=10,(SUM(D5,D7,D9,D11,D13)-5+25-SUM(D6,D8,D10,D12,D14))*2.5,"")']];
 s.getRange('A18:D18').merge(); s.getRange('A18').values=[['Formula contract: (odd items - 1 + 5 - even items) *2.5; blank until all 10 responses exist']];
 s.getRange('D5:D14').dataValidation={rule:{type:'whole',operator:'between',formula1:1,formula2:5}};
 s.getRange('A1:D18').format={font,wrapText:true,verticalAlignment:'top'}; s.getRange('A1:D1').format={fill:'#17365D',font:{name:'Arial',size:16,bold:true,color:'#FFFFFF'},rowHeight:28}; s.getRange('A2:D2').format={fill:'#D9EAF7',font:{name:'Arial',size:9,italic:true,color:'#17365D'},rowHeight:28}; s.getRange('A4:D4').format={fill:'#2F75B5',font:{name:'Arial',size:9,bold:true,color:'#FFFFFF'},rowHeight:28}; s.getRange('A5:D14').format.borders={preset:'inside',style:'thin',color:'#D9E2F3'}; ['A','B','C','D'].forEach((c,i)=>s.getRange(`${c}:${c}`).format.columnWidth=[14,85,38,16][i]); s.freezePanes.freezeRows(4);
 renderTable(wb.worksheets.getItem('Observations Results'),'Final UAT Observations / Results','No participant, usability, device, performance or acceptance result is asserted without human evidence',['Case ID','Activity','Status','Required evidence'],[['UAT-FINAL-001','Participant-coded final UAT','Pending Researcher Evidence','Consent, protocol execution, coded observations'],['DEVICE-FINAL-001','Physical Android/iPhone/tablet matrix','Not Executed - Human Action Required','Device/build IDs, timestamps, logs/screenshots/hashes'],['PERF-FINAL-001','Performance thresholds and measurements','Not Executed - Owner Action Required','Thresholds plus raw device measurements'],['ACCEPT-FINAL-001','Authorized acceptance','Pending Authorized Signature','Signed acceptance record']],[20,52,38,75]);
 await save(wb,file);
}
try {
 console.log('stage=audit'); await audit();
 console.log('stage=master'); await master();
 console.log('stage=uat'); await uat();
 console.log(JSON.stringify({status:'workbooks_corrected',sheets:41,tests:payload.tests.length,requirements:payload.requirements.length,historical:payload.historical_uat.length}));
} catch (error) {
 console.error(JSON.stringify({status:'error',name:error?.name,message:error?.message}));
 process.exitCode=1;
}
