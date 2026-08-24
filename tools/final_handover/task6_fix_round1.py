#!/usr/bin/env python3
from __future__ import annotations
import copy, hashlib, json, re
from pathlib import Path

BASELINE="1.3.11+28"; COMMIT="bf8867a2083357cb9d60915bf6c2233801f923d8"
RX=re.compile(r"^\d\d:\d\d \+(\d+)(?: -\d+)?: (.*)$")
def digest(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def category(path,name):
 v=(path+" "+name).lower()
 if any(x in v for x in ("algorithm","reba","iso11228","pose","xgboost","logistic")): return "Algorithm / reference"
 if any(x in v for x in ("invalid","required","malformed","missing","zero-height","error")): return "Invalid / boundary"
 if any(x in v for x in ("capture","screen","layout","responsive","widget","navigation")): return "UI / regression"
 if any(x in v for x in ("persist","draft","export","history","storage")): return "Data / persistence"
 return "Functional / regression"
def parse_flutter_expanded(text):
 out=[]; done=0; pending=None
 for line in text.splitlines():
  m=RX.match(line)
  if not m: continue
  n=int(m.group(1)); display=m.group(2).strip()
  if n>done:
   if n!=done+1 or pending is None: raise ValueError(f"bad reporter transition {done}->{n}")
   path,name=pending; out.append({"case_id":f"AUTO-{n:03d}","ordinal":n,"source_path":path,"name":name,"category":category(path,name)}); done=n
  if display=="All tests passed!" or display.startswith("loading "): continue
  full,name=display.rsplit(".dart: ",1); pending=(full.rsplit("/source/",1)[-1]+".dart",name)
 if len(out)!=135 or done!=135: raise ValueError("expected exact 135 tests")
 return out
def source_root(s): return sorted((Path(s)/"authoritative-materializations").glob("source-*/source"))[0]
HIST=[
 ("H-UAT-001","2026-05-26","1.1.0+6","docs/uat-report-20260526.md","iPhone install/launch evidence; Android human UAT pending","Tooling/clean archive","Clean archive build path workaround","None stated","CoreDevice/Flutter launch-attach blocker","Automated readiness only; hardware UAT remained open"),
 ("H-UAT-002","2026-06-06","1.1.2+10","docs/uat-full-system-20260606.md","iPhone SE; Android unauthorized","Integration harness","Temporary clean build path","None stated","Device authorization/runner blockers","Attempt did not complete camera/gallery/audio/export"),
 ("H-UAT-003","2026-06-06-r2","1.1.2+10","docs/uat-full-system-20260606-r2-android-ios.md","Samsung SM-S918B + iPhone SE iOS 26.5","ADB automation + iOS tooling","Clean temporary worktree for iOS build","None - clean worktree is a build workaround only","ADB disconnect and iOS screenshot service blocker","Build/install/launch observed; not full functional UAT"),
 ("H-UAT-004","2026-06-07","1.1.2+10","docs/uat-smoke-checklist-model-20260607.md","Samsung SM-S918B + iPhone SE iOS 26.5","Android integration runner + iOS device runner","Clean local iOS build tree","None stated","Android assembleDebug and iOS VM Service/LLDB attach blockers","Host tests/builds passed; device flows incomplete"),
 ("H-UAT-005","2026-07-07","1.3.6+21","docs/qa/sookta_req_1_5_real_device_qa_2026-07-07.md","Physical iPhone SE iOS 26.5","devicectl install/launch + host acceptance runner","Manual sign/install after stripping xattrs","None stated","Physical-device automated runner CodeSign blocker","Release installed/launched; no full manual tap-through"),
 ("H-UAT-006","2026-07-12","1.3.6+21","docs/uat-last-phase-20260712.md","Physical iPhone SE iOS 26.5","No physical Android detected; iPad simulator only","Uploaded-video UAT","Temporary assessment bypass","Offline relaunch pending; simulator runner idle","User-observed iPhone checks; historical only"),
 ("H-UAT-007","2026-07-19","1.3.6+21","docs/uat-production-platform-parity-20260719.md","iPhone SE connected/paired but unavailable","iOS simulator + Android emulator","Separate /private/tmp iOS build directory for FileProvider metadata","None - production assessment path","BLOCKED BY DEVICE CONNECTION","Production-path MoveNet/TFLite passed on simulator/emulator; physical iPhone remained blocked"),
]
def historical(staging):
 root=source_root(staging); keys=("evidence_id","date","version","evidence_path","device","runner_harness","build_workaround","assessment_bypass","blocker","observation")
 return [{**dict(zip(keys,row)),"sha256":digest(root/row[3]),"evidence_layer":"Historical - not final baseline"} for row in HIST]
def evidence_tuple(cid,ts,method,path,sha): return {"case_id":cid,"baseline":BASELINE,"timestamp":ts,"method":method,"raw_path":path,"sha256":sha}
def defects(staging):
 root=source_root(staging); ep="docs/uat-production-platform-parity-20260719.md"; h=digest(root/ep)
 raw=[
  ("DEF-HIST-001","Production assessment temporary bypass","c3a0aa0a78216a5dd048c2c80bbbf35042cc8de5","f2262aa68665697d0b51df7dea0b4d63608cfeb6","lib/core/services/assessment_readiness.dart","Production gate regression and simulator/emulator production-path UAT"),
  ("DEF-HIST-002","Android zero-height warm-up frame","2c74db530c31567ebeb49f0926383d7e1e78fe5c","8b009dfaee30883ae77c11752a63c61c4fc463f8","lib/screens/main/evaluation_menu_screen.dart","responsive_list_view_zero_height_test.dart"),
  ("DEF-HIST-003","Android/iPhone final-result score layout parity","2c74db530c31567ebeb49f0926383d7e1e78fe5c","8b009dfaee30883ae77c11752a63c61c4fc463f8","lib/screens/main/final_result_screen.dart","390/412 width regression plus iOS/Android screenshots"),]
 d=[{"defect_id":i,"description":desc,"before_commit":b,"after_commit":a,"source_path":p,"fix":f"Corrected in {a}","retest":r,"evidence_path":ep,"sha256":h,"version":"1.3.6+21","status":"Historical correction/retest - not final device evidence"} for i,desc,b,a,p,r in raw]
 ba=[{"change_id":x["defect_id"],"before_commit":x["before_commit"],"after_commit":x["after_commit"],"source_path":x["source_path"],"before":x["description"],"after":x["fix"],"evidence_path":x["evidence_path"],"sha256":x["sha256"]} for x in d]
 return d,ba
def build_corrected_payload(staging):
 staging=Path(staging); meta=json.loads((staging/"working/task6/task6_build_input.json").read_text()); raw=staging/"evidence/flutter_test_1.3.11+28.log"; tests=parse_flutter_expanded(raw.read_text()); logsha=digest(raw)
 req=[]
 for r in json.loads((staging/"evidence_map.json").read_text())["records"]:
  x=copy.deepcopy(r); x["task2_evidence"]={"baseline":BASELINE,"commit":COMMIT,"path":"evidence/final_evidence_metadata.json","sha256":digest(staging/"evidence/final_evidence_metadata.json"),"claim":"Technical baseline metadata only; source status remains authoritative"}; x["task6_evidence"]={"path":"working/task6/task6_corrected_payload.json","claim":"Traceability layer; source status not overwritten"}; req.append(x)
 counts={}
 for r in req: counts[r["status"]]=counts.get(r["status"],0)+1
 ts=meta["final_commands"]["flutter_test"]["timestamp"]
 results=[{**t,"status":"PASS","evidence_tuple":evidence_tuple(t["case_id"],ts,"/Users/kpc/develop/flutter/bin/flutter test --reporter expanded","evidence/flutter_test_1.3.11+28.log",logsha),"actual":f"Reporter increment +{t['ordinal']} proves the preceding displayed test completed","limitations":"Host/unit/widget only; not device/UAT/audio/permission/performance/Firebase/acceptance proof"} for t in tests]
 a=meta["final_commands"]["analyze"]; results.append({"case_id":"STATIC-001","name":"Final flutter analyze","category":"Static analysis","status":"PASS","evidence_tuple":evidence_tuple("STATIC-001",a["timestamp"],a["command"],a["path"],a["sha256"]),"actual":"No issues found","limitations":"Static analysis only"})
 results += [{"case_id":"FIREBASE-PLAN-001","name":"Firebase runtime delivery","category":"Test plan","status":"Not Executed - Human/Runtime Evidence Required","evidence_tuple":{},"actual":"No final-version runtime delivery evidence","limitations":"Historical HTTP/log observations are not final proof"},{"case_id":"DEVICE-PLAN-001","name":"Physical-device acceptance plan","category":"Test plan","status":"Not Executed - Human Action Required","evidence_tuple":{},"actual":"Protocol prepared; no final participant/device execution","limitations":"Owner/researcher execution required"}]
 d,ba=defects(staging)
 wording=["I think that I would like to use this system frequently.","I found the system unnecessarily complex.","I thought the system was easy to use.","I think that I would need the support of a technical person to use this system.","I found the various functions in this system were well integrated.","I thought there was too much inconsistency in this system.","I would imagine that most people would learn to use this system very quickly.","I found the system very cumbersome to use.","I felt very confident using the system.","I needed to learn a lot of things before I could get going with this system."]
 return {"schema_version":2,"baseline":{"version":BASELINE,"commit":COMMIT},"tests":tests,"requirements":req,"requirement_status_counts":counts,"historical_uat":historical(staging),"result_rows":results,"defects":d,"before_after":ba,"sus":{"instrument":"System Usability Scale (SUS), standard 10-item controlled instrument","items":[{"item":i,"wording":w} for i,w in enumerate(wording,1)],"anchors":{"1":"Strongly disagree","5":"Strongly agree"},"validation":{"type":"whole","minimum":1,"maximum":5},"score_formula_contract":"=(SUM(odd_items-1)+SUM(5-even_items))*2.5"},"human_gaps":meta["final_hardware_actions"],"claim_boundary":"Final automated baseline is separate from historical, simulated, build-workaround, bypass-assisted, participant, usability, device, performance, and acceptance evidence."}
def validate_payload(p,staging):
 expected=parse_flutter_expanded((Path(staging)/"evidence/flutter_test_1.3.11+28.log").read_text())
 if [(x["source_path"],x["name"],x["category"]) for x in p["tests"]] != [(x["source_path"],x["name"],x["category"]) for x in expected]: raise ValueError("tests")
 src=json.loads((Path(staging)/"evidence_map.json").read_text())["records"]; preserve=("requirement_id","status","authoritative_sources","human_action","final_version_claim","rationale")
 if len(p["requirements"])!=155: raise ValueError("requirements")
 for a,b in zip(src,p["requirements"],strict=True):
  if any(a[k]!=b.get(k) for k in preserve) or "task2_evidence" not in b or "task6_evidence" not in b: raise ValueError("requirement mutation")
 if p["requirement_status_counts"]!={"Pending Owner Action":137,"Exception Approval Required":12,"Pending Researcher Evidence":6}: raise ValueError("status counts")
 if p["historical_uat"]!=historical(staging): raise ValueError("historical")
 if [x["item"] for x in p["sus"]["items"]]!=list(range(1,11)) or p["sus"]["anchors"]!={"1":"Strongly disagree","5":"Strongly agree"}: raise ValueError("SUS")
 required={"case_id","baseline","timestamp","method","raw_path","sha256"}
 for r in p["result_rows"]:
  if r["status"]=="PASS":
   e=r.get("evidence_tuple",{}); path=Path(staging)/e.get("raw_path","")
   if not required<=set(e) or not re.fullmatch(r"[0-9a-f]{64}",e.get("sha256","")) or not path.is_file() or digest(path)!=e["sha256"]: raise ValueError("PASS tuple")
def validate_visual_decisions(expected,decisions,root):
 if len(expected)!=len(decisions): raise ValueError("manual decisions required")
 by={x.get("path"):x for x in decisions}
 for e in expected:
  h=digest(Path(root)/e["path"]); d=by.get(e["path"])
  if h!=e["sha256"] or not d or d.get("sha256")!=h or d.get("decision")!="PASS" or not d.get("inspector") or not d.get("inspected_at"): raise ValueError("unbound/failed visual decision")
if __name__=="__main__":
 S=Path("/private/tmp/fsookta-final-handover"); p=build_corrected_payload(S); validate_payload(p,S); out=S/"working/task6/task6_corrected_payload.json"; out.write_text(json.dumps(p,indent=2,ensure_ascii=False)+"\n"); print(json.dumps({"status":"payload_valid","tests":len(p["tests"]),"requirements":len(p["requirements"]),"results":len(p["result_rows"])}))
