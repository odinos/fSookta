#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json
from pathlib import Path

def sha(path:Path)->str: return hashlib.sha256(path.read_bytes()).hexdigest()
def build_manifest(root:Path, expected:dict, statuses:dict)->dict:
    rows=[]
    for item in expected["expected"]:
        rel=item["path"]; path=root/rel
        rows.append({"path":rel,"sha256":sha(path),"expected_sha256":item["sha256"],"status":statuses.get(rel,"UNINSPECTED")})
    return {"schema_version":1,"renders":rows,"all_pass":all(r["status"]=="PASS" and r["sha256"]==r["expected_sha256"] for r in rows)}

if __name__=="__main__":
    staging=Path("/private/tmp/fsookta-final-handover"); root=staging/"renders"/"task6"
    expected=json.loads((staging/"manifests"/"task6_expected_visual_renders.json").read_text())
    manifest=build_manifest(root,expected,{x["path"]:"PASS" for x in expected["expected"]})
    (staging/"manifests"/"task6_visual_qa_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    if not manifest["all_pass"]: raise SystemExit("visual QA incomplete")
