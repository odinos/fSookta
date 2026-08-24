import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { Workbook, SpreadsheetFile } from '@oai/artifact-tool';

const ROOT=process.env.FSOOKTA_HANDOVER_ROOT || '/private/tmp/fsookta-final-handover';
const A=path.join(ROOT,'artifacts'), M=path.join(ROOT,'manifests');
const scan=JSON.parse(await fs.readFile(path.join(M,'task7_offline_security_inspection.json'),'utf8'));
const VERSION='1.3.11+28', COMMIT='bf8867a2083357cb9d60915bf6c2233801f923d8';
const STATUSES=['Implemented - Evidence Available','Partially Implemented','N/A with Rationale','Open - Pending Owner','Open - Pending Researcher','Open - Pending Owner/Researcher','Pending Signature'];
function col(n){let s='';while(n){n--;s=String.fromCharCode(65+n%26)+s;n=Math.floor(n/26)}return s;}
function wb(){return new Workbook({}, {sheets:[]});}
async function hash(relative){return crypto.createHash('sha256').update(await fs.readFile(path.join(ROOT,relative))).digest('hex');}
const SOURCE='evidence/task7-source';
async function evidence(relative,status=VERSION){return [relative,await hash(relative),status];}
function add(w,name,title,subtitle,headers,rows,widths=[]){
 const s=w.worksheets.add(name), end=col(headers.length), n=Math.max(4,rows.length+4); s.showGridLines=false;
 s.getRange(`A1:${end}1`).merge();s.getRange('A1').values=[[title]];
 s.getRange(`A2:${end}2`).merge();s.getRange('A2').values=[[subtitle]];
 s.getRange(`A4:${end}4`).values=[headers];if(rows.length)s.getRange(`A5:${end}${rows.length+4}`).values=rows;
 s.getRange(`A1:${end}${n}`).format={font:{name:'Arial',size:9,color:'#172033'},verticalAlignment:'top',wrapText:true};
 s.getRange(`A1:${end}1`).format={fill:'#000000',font:{name:'Arial',size:16,bold:true,color:'#FFFFFF'},rowHeight:28};
 s.getRange(`A2:${end}2`).format={fill:'#EDEDED',font:{name:'Arial',size:9,italic:true,color:'#333333'},rowHeight:30};
 s.getRange(`A4:${end}4`).format={fill:'#3D8DFF',font:{name:'Arial',size:9,bold:true,color:'#FFFFFF'},rowHeight:30,borders:{preset:'all',style:'thin',color:'#B8BCC4'}};
 if(rows.length)s.getRange(`A5:${end}${rows.length+4}`).format.borders={preset:'inside',style:'thin',color:'#DADCE0'};
 widths.forEach((v,i)=>s.getRange(`${col(i+1)}:${col(i+1)}`).format.columnWidth=v);s.freezePanes.freezeRows(4);return s;
}
async function save(w,name){const out=await SpreadsheetFile.exportXlsx(w);await out.save(path.join(A,name));}

async function security(){
 const w=wb();
 const summary=add(w,'Control Summary','Security and Access Control Matrices',`Baseline ${VERSION} | ${COMMIT} | offline source-backed fallback; not a sealed Codex Security report`,['Metric','Value / formula','Boundary'],[
 ['Control rows',15,'Source-backed controls and human actions'],['Open observations',scan.findings.filter(x=>x.status.startsWith('Open')).length,'Not vulnerability count'],['Compliance certification',0,'Not assessed'],['Live-service tests',0,'Not performed'],['Formula status','','Calculated from Risk Register']],[32,28,85]);
 summary.getRange('B9').formulas=[[`=IF(COUNTIF('Risk Register'!E5:E9,"Open*")>0,"OPEN ACTIONS","NO OPEN ROWS")`]];
 add(w,'Asset Data Inventory','Asset and Data Inventory','Data minimization, linkage and owner policy remain review gates',['Asset','Location','Data class','Owner','Retention / deletion','Evidence','Status'],[
 ['Profile/farmer JSON','SharedPreferences','Sensitive participant/profile','Researcher','Pending approved schedule','lib/app/app_state.dart','Partially Implemented'],
 ['History/draft JSON','SharedPreferences','Sensitive assessment/research','Researcher','Pending approved schedule','lib/app/app_state.dart','Partially Implemented'],
 ['Images/video/frame paths','Application documents / selected gallery/camera','Potentially identifying media','Researcher','Deletion beyond app not controlled','lib/core/services/local_image_store.dart','Partially Implemented'],
 ['CSV exports','Application documents then OS share','Sensitive disclosure artifact','Researcher','Approved destination/retention pending','assessment_export_service.dart','Open - Pending Researcher'],
 ['Bundled models','assets/models','Executable model asset','Owner','Version/hash controlled','Task 5 model inventory','Implemented - Evidence Available']],[30,42,38,28,55,45,38]);
 add(w,'Privacy Classes','Privacy Classification','Classification is technical and requires researcher policy approval',['Class','Examples','Handling control','Approval','Status'],[
 ['Public','App name/version, source paths','May be shared subject to IP/license terms','Owner','Partially Implemented'],
 ['Internal technical','Logs, hashes, build evidence','Approved repository/Drive only','Owner','Open - Pending Owner'],
 ['Sensitive profile','Coded ID, age, gender, location, role','Minimize; separate re-identification key','Researcher','Open - Pending Researcher'],
 ['Sensitive assessment','Images, pose points, scores, recommendations','Coded access; approved retention/transfer','Researcher','Open - Pending Researcher'],
 ['Secret/credential','Signing assets, API/service credentials','Secure channel; never document values','Owner','Open - Pending Owner']],[28,50,65,28,38]);
 add(w,'Data Flow Disclosure','Data Flow and Disclosure Boundary','Remote telemetry is optional/default-off; export/share is user-triggered',['From','Processing','To','Data','Trigger','Boundary','Evidence'],[
 ['Camera/gallery','Image/video selection and local processing','App local storage/inference','Potentially identifying media','User action','OS permission + app sandbox','evaluation_form_screen.dart'],
 ['App state','JSON serialization','SharedPreferences','Profile/history/drafts','Save/restore','Local device','app_state.dart'],
 ['History/result','CSV generation','Application documents → share sheet','Assessment/research fields','User export','External recipient policy','assessment_export_service.dart'],
 ['App events','Safe parameter normalization','Firebase Analytics/Crashlytics','Bounded event parameters','Build opt-in + Firebase config','Default-off; live retention not assessed','firebase_telemetry_service.dart']],[26,42,38,45,35,45,45]);
 add(w,'Permissions','Platform Permissions','Only manifest/plist declarations are asserted',['Platform','Permission / usage','Purpose','Runtime evidence','Status'],[
 ['Android','INTERNET','Optional Firebase/network capability','Not dynamically assessed','Implemented - Evidence Available'],['Android','CAMERA','Posture capture','Physical-device test pending','Open - Pending Owner'],['iOS','Camera','Posture photo/video','Physical-device test pending','Open - Pending Owner'],['iOS','Photo library read/add','Select or retain media','Physical-device test pending','Open - Pending Owner'],['iOS','Microphone','System camera video only; audio not scored','Physical-device test pending','Open - Pending Owner']],[22,38,55,42,38]);
 add(w,'Third Parties','Third Parties and Model Flows','No secret values or remote-console facts are recorded',['Component','Purpose','Data/network behavior','Evidence','Owner action','Status'],[
 ['Firebase Analytics/Crashlytics','Optional telemetry/crash logging','Remote only if build opt-in and initialized','firebase_telemetry_service.dart','Approve project/retention/consent','Open - Pending Owner'],['ONNX Runtime','Local model inference','Bundled local models','Task 5 hashes','Review advisories/licenses','Open - Pending Owner'],['Image Picker / Camera','Acquire media','OS platform boundary','pubspec.lock + platform config','Device permission test','Open - Pending Owner'],['Share Plus','Export/manual share','External destination chosen by user','assessment_export_service.dart','Approve recipient/destination policy','Open - Pending Researcher'],['Flutter TTS','Read guidance','Device speech service','tts_button.dart','Device/language privacy test','Open - Pending Owner']],[32,42,55,52,52,38]);
 add(w,'Access Applicability','Access-Control Applicability','N/A statuses require architecture rationale',['Control','Applicability','Rationale','Compensating owner control','Status'],[
 ['Application login','N/A','No login in final local client','Device access/OS screen lock policy','N/A with Rationale'],['Remote assessment DB roles','N/A','No remote assessment database','Local device custody','N/A with Rationale'],['Assessment API authentication','N/A','No assessment server/API','Source/release integrity controls','N/A with Rationale'],['Firebase console IAM','Applicable if telemetry enabled','Optional external console','Transfer named roles and review least privilege','Open - Pending Owner'],['Repository/store roles','Applicable','Delivery and release ownership','Transfer and evidence register','Open - Pending Owner']],[38,22,65,60,38]);
 add(w,'Retention Deletion Backup','Retention, Deletion and Backup','No approved schedule, secure erase or governed restore is asserted',['Data','Retention','Deletion','Backup/restore','Owner','Status'],[
 ['Local state references','Pending policy','Profile/draft/history reference operations exist; farmer removal leaves existing history; secure erasure unproven','No governed workflow evidenced','Researcher/Owner','Open - Pending Owner/Researcher'],['Local copied media/history files','Pending policy','No File.delete path; media/history file deletion and secure erase unproven','No governed workflow evidenced','Researcher/Owner','Open - Pending Owner/Researcher'],['CSV exports','Pending policy','Manual external deletion','Approved destination/restore test pending','Researcher','Open - Pending Researcher'],['Telemetry data','Console policy not assessed','Console deletion not assessed','Vendor/service policy not assessed','Owner','Open - Pending Owner']],[32,34,50,52,30,38]);
 add(w,'Control Test Evidence','Security Control and Test Evidence','Technical tests do not equal penetration/compliance testing',['Control','Method','Result','Evidence','Limitation','Status'],[
 ['Telemetry default','Static source inspection','defaultValue false','firebase_telemetry_service.dart:18-39','No live-console/runtime delivery assessment','Implemented - Evidence Available'],['Android permissions','Manifest inspection','INTERNET + CAMERA','AndroidManifest.xml','Runtime grant/deny pending','Partially Implemented'],['iOS usage descriptions','Plist inspection','Camera/photo/microphone text present','Info.plist','Runtime grant/deny pending','Partially Implemented'],['Secret marker triage','Offline bounded regex/count scan',JSON.stringify(scan.candidate_marker_counts),'task7_offline_security_inspection.json','Not proof of absence; no values retained','Partially Implemented'],['Final package content','Post-generation independent rescan','All current Task7 Office + non-self Task7 manifests','task7_final_content_inspection.json','Participant/owner dispositions remain open','Partially Implemented'],['Flutter suite','Reproduced tests','135 tests PASS','Task 2 raw log','Not security/penetration test','Implemented - Evidence Available']],[35,42,45,52,65,38]);
 add(w,'Risk Register','Risk and Observation Register','Observations require validation; not a claim of vulnerability absence',['ID','Severity','Observation','Evidence','Status','Owner / closure'],scan.findings.map(x=>[x.id,x.severity,x.observation,x.evidence,x.status,x.status.includes('Researcher')?'Researcher/Owner':'Owner validation and evidence']),[18,14,85,55,42,55]);
 add(w,'Credential Ownership','Credential and Ownership Checklist','Categories only; no secret values',['Category','Location / system','Current owner','Target owner','Transfer/rotation/revocation evidence','Status'],[
 ['GitHub Owner/Admin','GitHub repository','Pending confirmation','Researcher/Owner','Role screenshot/audit log','Open - Pending Owner'],['Firebase project/config','Firebase Console + platform config','Pending confirmation','Owner','IAM/readback + rotation decision','Open - Pending Owner'],['Apple signing/store','Apple Developer/App Store Connect','Pending confirmation','Owner','Role/certificate/profile evidence','Open - Pending Owner'],['Android signing/store','Upload keystore/Play Console','Pending confirmation','Owner','Secure transfer + role evidence','Open - Pending Owner']],[35,45,30,30,65,38]);
 add(w,'Incident Actions','Incident and Response Actions','Draft actions; no readiness/SLA claim',['Scenario','Immediate action','Escalation','Evidence to preserve','Status'],[
 ['Lost device','Stop collection; notify approved contact; assess remote/device controls','Owner + Research lead','Device/build, time, coded scope','Open - Pending Owner'],['Wrong recipient/export','Request containment; stop further sharing','Research lead + privacy owner','Hash, recipient, channel, time','Open - Pending Researcher'],['Credential/signing exposure','Revoke/rotate through authoritative console','System owner','Audit event and rotation proof','Open - Pending Owner'],['Unexpected telemetry','Disable governed build; preserve non-identifying logs','Firebase owner','Build define, project, event list','Open - Pending Owner']],[40,65,42,55,38]);
 add(w,'Compliance Mapping','Compliance and Policy Mapping','No compliance certification is asserted',['Topic','Technical evidence','Policy/authority needed','Status'],[
 ['Consent/ethics','Not derivable from source','Researcher approval/records','Open - Pending Researcher'],['Data minimization','Coded ID supported; sensitive fields persist/export','Researcher data management plan','Partially Implemented'],['Retention/deletion','Profile/draft/history reference operations are bounded; farmer removal leaves existing history; no File.delete path or secure erase proof','Owner/research policy','Open - Pending Researcher'],['Incident response','Draft register only','Approved plan/contact/SLA/exercise','Open - Pending Owner'],['Security testing','Offline source-backed fallback only','Authorized dynamic/advisory/penetration scope','Open - Pending Owner']],[35,75,65,38]);
 add(w,'Evidence Index','Security Evidence Index','Hashes identify source files without exposing values',['Path','Purpose','SHA-256','Exists'],scan.evidence.map(x=>[x.path,x.purpose,x.sha256||'Missing',x.exists]),[60,65,72,12]);
 add(w,'Human Actions','Security and Privacy Human Actions','Closure requires evidence; formulas do not auto-close human actions',['Action','Owner','Required evidence','Status'],[
 ['Approve telemetry/project/retention/consent boundary','Owner + Researcher','Signed decision and console readback','Open - Pending Owner/Researcher'],['Approve local data/media/export retention and deletion','Researcher + Owner','Policy plus execution/test evidence','Open - Pending Owner/Researcher'],['Transfer repository/store/Firebase/signing ownership','Owner','Role/audit/secure-transfer evidence','Open - Pending Owner'],['Validate device permissions, backup/restore, deletion and incident plan','Owner','Versioned test records','Open - Pending Owner'],['Sign non-retention/non-access statement','Authorized parties','Signed statement','Pending Signature']],[70,38,75,42]);
 await save(w,'09_Security_and_Access_Control_Matrices.xlsx');
}

async function publication(){
 const w=wb();
 const testEv=await evidence('evidence/flutter_test_1.3.11+28.log',VERSION);
 const analyzeEv=await evidence('evidence/flutter_analyze_1.3.11+28.log',VERSION);
 const androidBuildEv=await evidence('evidence/build_android_1.3.11+28.log','technical build log; signing boundary retained');
 const iosBuildEv=await evidence('evidence/build_ios_1.3.11+28.log','technical build log; signing boundary retained');
 const masterEv=await evidence('artifacts/07_Master_Test_and_Verification_Package.xlsx',VERSION);
 const uatEv=await evidence('artifacts/08_UAT_Field_Test_and_Usability_Package.xlsx','historical + pending');
 const aiEv=await evidence('artifacts/04_AI_Algorithm_and_Model_Technical_Report.docx','controlled technical report');
 const matrixEv=await evidence('artifacts/04_Algorithm_Recommendation_and_Reference_Matrices.xlsx','controlled technical matrix');
 const dataEv=await evidence('artifacts/05_Data_Dictionary_and_Export_Schema.xlsx',VERSION);
 const pubspecEv=await evidence(`${SOURCE}/pubspec.yaml`,VERSION);
 const secEv=await evidence('manifests/task7_offline_security_inspection.json','controlled draft');
 const pendingEv=await evidence('manifests/task6_verification_summary.json','pending human evidence');
 const cols=['Exact source path','SHA-256','Evidence version / provenance'];
 const sourced=(rows,ev)=>rows.map(row=>[...row,...ev]);
 add(w,'Control Summary','Publication Tables and Evidence Register',`Technical inputs only | ${VERSION} | Research conclusions remain pending`,['Metric','Available','Boundary'],[['Automated tests',135,'Final host/unit/widget evidence'],['Algorithm/reference cases',55,'Technical verification only'],['Boundary cases',7,'Technical verification only'],['Historical UAT records',7,'Historical versions only'],['Final participant/SUS rows',0,'Pending Researcher']],[35,18,85]);
 add(w,'Chapter 4 Tables','Chapter 4 Editable Tables','Every row is bound to one exact local source and hash',['Table ID','Proposed title','Variable / metric','Available value','Missing evidence / reviewer',...cols],[
   ...sourced([['T4-01','Final technical verification','Automated tests passed',135,'Environment interpretation — Researcher']],testEv),
   ...sourced([['T4-02','Algorithm/reference verification','Algorithm/reference cases',55,'Research validity interpretation — Researcher'],['T4-03','Boundary verification','Boundary cases',7,'Coverage interpretation — Researcher']],masterEv),
   ...sourced([['T4-04','Historical UAT evidence','Historical records',7,'Final participant evidence — Pending Researcher']],uatEv),
   ...sourced([['T4-05','SUS results','Participant/SUS result','','All responses, scoring and interpretation pending']],pendingEv)
  ],[18,50,38,20,55,78,70,32]);
 add(w,'Paper 2 Methods','Paper 2 Methods Inputs','Do not infer study design or ethics facts',['Methods field','Technical input','Researcher-owned completion','Status',...cols],[
  ...sourced([['Software version',`${VERSION}; ${COMMIT}`,'Confirm study deployment version','Implemented - Evidence Available']],pubspecEv),
  ...sourced([['Architecture','Flutter local client; local persistence/inference; optional default-off telemetry','Study environment and device allocation','Partially Implemented']],secEv),
  ...sourced([['Algorithms','REBA/ISO deterministic references + local model roles','Protocol applicability and validation framework','Partially Implemented']],aiEv),
  ...sourced([['Static analysis','flutter analyze log','Interpret environment and warnings','Implemented - Evidence Available']],analyzeEv),
  ...sourced([['Automated tests','flutter test expanded log','Statistical analysis plan is separate','Implemented - Evidence Available']],testEv),
  ...sourced([['Android build','Primary Android build log','Signing/production ownership remains pending','Partially Implemented']],androidBuildEv),
  ...sourced([['iOS build','Primary iOS build log','Signing/production ownership remains pending','Partially Implemented']],iosBuildEv),
  ...sourced([['Case matrices','Master test and verification package','Research-validity interpretation','Implemented - Evidence Available']],masterEv),
  ...sourced([['Participants/ethics','','Sample, recruitment, consent, ethics approval','Open - Pending Researcher']],uatEv)
 ],[38,65,60,28,78,70,32]);
 add(w,'Paper 2 Results','Paper 2 Results Inputs','No participant or research outcome is populated without raw evidence',['Result field','Available numeric fact','Limitation','Researcher input',...cols],[
  ...sourced([['Automated test execution',135,'Host/unit/widget; not UAT','Review wording']],testEv),
  ...sourced([['Algorithm/reference cases',55,'Technical case count; not external validity','Review interpretation'],['Boundary cases',7,'Technical boundary coverage','Review interpretation']],masterEv),
  ...sourced([['Final UAT participants','','No final participant evidence','Open - Pending Researcher'],['SUS score','','No final responses','Open - Pending Researcher']],uatEv),
  ...sourced([['Effect size/statistics','','No governed dataset/analysis','Open - Pending Researcher']],pendingEv)
 ],[42,28,62,42,78,70,32]);
 add(w,'Variable Definitions','Variable Definitions','Field contracts remain researcher-reviewed',['Variable group','Definition','Unit/type','Researcher review',...cols],[
  ...sourced([['App version','Semantic version and build number','string','Confirm deployed study build']],pubspecEv),
  ...sourced([['Assessment method','REBA / ISO 11228 method identifier','controlled string','Confirm protocol mapping'],['REBA score','Deterministic posture risk score','integer / source-defined','Confirm reporting convention'],['ISO result','Method-specific risk/limits','mixed / source-defined','Confirm units and applicability'],['Participant code','Pseudonymous code; not identity vault','string','Approve coding policy']],dataEv),
  ...sourced([['SUS score','Standard 0-100 derived score','number','Pending Researcher']],uatEv)
 ],[36,65,35,50,78,70,32]);
 add(w,'Citation Mapping','Citation and Reference Mapping','Bibliographic accuracy remains researcher review',['ID','Claim/topic','External reference','Status',...cols],[
  ...sourced([['CIT-01','REBA method','Hignett & McAtamney (2000)','Open - Pending Researcher'],['CIT-02','ISO 11228-1','ISO 11228-1:2021','Open - Pending Researcher'],['CIT-03','ISO 11228-2','ISO 11228-2:2007','Open - Pending Researcher']],matrixEv),
  ...sourced([['CIT-04','System/version','','Implemented - Evidence Available']],pubspecEv),
  ...sourced([['CIT-05','UAT/SUS interpretation','','Open - Pending Researcher']],uatEv)
 ],[18,45,55,42,78,70,32]);
 const figures=[
  ['FIG-01','System architecture','Draft','Pending Researcher','artifacts/diagrams/03_system_context.drawio'],
  ['FIG-02','Assessment workflow','Draft','Pending Researcher','artifacts/diagrams/03_user_navigation.drawio'],
  ['FIG-03','Local data/export flow','Draft','Pending Researcher','artifacts/diagrams/03_local_storage_and_export.drawio'],
  ['FIG-04','Model/algorithm flow','Draft','Pending Researcher','artifacts/diagrams/03_assessment_algorithm.drawio'],
  ['FIG-05','Verification evidence flow','Draft','Pending Researcher','artifacts/07_Master_Test_and_Verification_Package.xlsx']
 ];
 const figureRows=[];for(const [id,candidate,caption,approval,relative] of figures)figureRows.push([id,candidate,caption,approval,...await evidence(relative,VERSION)]);
 add(w,'Figure Registry','Publication Figure Registry','Each candidate resolves to one exact editable source',['Figure ID','Candidate','Caption state','Researcher approval',...cols],figureRows,[18,45,26,34,78,70,32]);
 add(w,'Evidence Index','Publication Evidence Index','Each row resolves to one exact artifact or evidence file',['Evidence group','Available','Missing / boundary',...cols],[
  ...sourced([['Source','Yes','Ownership/access evidence pending']],pubspecEv),
  ...sourced([['Build/test','Yes','Physical device/performance pending']],testEv),
  ...sourced([['Algorithms/models','Partial','Governed XGBoost dataset/raw metrics pending']],aiEv),
  ...sourced([['UAT/field/SUS','Partial','Final participant/SUS/acceptance pending']],uatEv),
  ...sourced([['Security/privacy','Partial','No sealed scan/compliance/dynamic test']],secEv),
  ...sourced([['Research results','No','Pending Researcher']],pendingEv)
 ],[28,20,70,78,70,32]);
 add(w,'Human Actions','Publication Human Actions','No blank is interpreted as zero or negative finding',['Action','Owner','Required input','Status'],[
 ['Supply ethics/consent and sample metadata','Researcher','Approved statements and coded summary','Open - Pending Researcher'],['Supply final UAT/SUS/field evidence','Researcher','Raw/derived evidence and interpretation','Open - Pending Researcher'],['Approve methods, statistics, results and conclusions','Researcher','Reviewed manuscript sections','Open - Pending Researcher'],['Approve figure/table captions and citations','Researcher','Numbering, wording and reference verification','Open - Pending Researcher'],['Approve repository/data availability and IP statement','Owner + Researcher','Signed publication/access decision','Open - Pending Owner/Researcher'],['Record submission/acceptance only after evidence','Researcher','Journal record/DOI/decision','Open - Pending Researcher']],[72,35,75,40]);
 await save(w,'11_Publication_Tables.xlsx');
}

await fs.mkdir(A,{recursive:true});await security();await publication();
console.log(JSON.stringify({status:'built',workbooks:2,sheets:24,status_vocabulary:STATUSES}));
