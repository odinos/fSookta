#!/usr/bin/env python3
from __future__ import annotations
import hashlib,json,re,zipfile,subprocess
from pathlib import Path
from pypdf import PdfReader

STAGING=Path("/private/tmp/fsookta-final-handover")
PRIMARY=["06_Development_Audit_Trail.xlsx","06_Development_Audit_Trail.pdf","07_Master_Test_and_Verification_Package.xlsx","07_Master_Test_and_Verification_Package.pdf","07_Final_Algorithm_Verification_Report.docx","07_Final_Algorithm_Verification_Report.pdf","08_UAT_Field_Test_and_Usability_Package.xlsx","08_UAT_Field_Test_and_Usability_Package.pdf","08_UAT_and_Field_Test_Technical_Report.docx","08_UAT_and_Field_Test_Technical_Report.pdf"]
def sha(p:Path)->str:return hashlib.sha256(p.read_bytes()).hexdigest()
def assert_claim_boundaries(facts):
    assert facts["final_uat_status"]!="PASS" or facts["participant_count"]>0, "unsupported final UAT PASS"
    for r in facts.get("historical_uat",[]): assert r["evidence_layer"]=="Historical" and not r["final_baseline_pass"] and r["version"]!="1.3.11+28"
def _git_rows():
    raw=subprocess.run(["git","log","bf8867a2083357cb9d60915bf6c2233801f923d8","--date=iso-strict","--pretty=format:@@@%H%x09%aI%x09%s%x09%D","--name-only"],cwd=Path(__file__).resolve().parents[2],check=True,capture_output=True,text=True).stdout
    rows=[];current=None;paths=[]
    for line in raw.splitlines()+["@@@END\tEND\tEND\tEND"]:
        if line.startswith("@@@"):
            if current:
                current["changed_paths"]="; ".join(paths) if paths else "Merge/no path list";rows.append(current)
            p=line[3:].split("\t");current=None if p[0]=="END" else {"commit":p[0],"date":p[1],"subject":p[2],"refs":p[3] if len(p)>3 else ""};paths=[]
        elif line.strip():paths.append(line.strip())
    return rows
def assert_source_grounding(facts,source):
    assert facts["git_history"]==_git_rows(),"Git-derived audit rows differ from authoritative history"
    assert facts["baseline"]=={"version":"1.3.11+28","commit":"bf8867a2083357cb9d60915bf6c2233801f923d8","tree":"b4ed5fd0c061492c74dba356ed8a114b5f6621ba"}
    commands=facts["final_commands"]
    for key,row in commands.items():
        p=STAGING/row["path"]; assert p.is_file() and sha(p)==row["sha256"]
        text=p.read_text(encoding="utf-8",errors="replace");assert "Version: 1.3.11+28" in text and "Commit: bf8867a2083357cb9d60915bf6c2233801f923d8" in text and "Exit code: 0" in text
    assert "+135: All tests passed!" in (STAGING/commands["flutter_test"]["path"]).read_text(errors="replace")
    assert "No issues found!" in (STAGING/commands["analyze"]["path"]).read_text(errors="replace")
    assert len(facts["final_test_cases"])==135 and [r["case_id"] for r in facts["final_test_cases"]]==[f"AUTO-{i:03d}" for i in range(1,136)]
    for row in facts["final_test_cases"]:
        assert row["status"]=="PASS" and row["baseline"]=="1.3.11+28" and row["evidence_sha256"]==commands["flutter_test"]["sha256"] and row["evidence_path"]==commands["flutter_test"]["path"]
    required={str(x["requirement_id"]) for x in json.loads((STAGING/"requirements.json").read_text())["requirements"]}
    documented={str(x["requirement_id"]) for x in facts["requirements_traceability"]};assert documented==required
    for row in facts["historical_uat"]: assert sha(source/row["evidence_path"])==row["sha256"]
    assert {r["status"] for r in facts["final_hardware_actions"]}<={"Pending Owner Action","Pending Researcher Evidence","Complete - Pending Signature"}
def assert_visual_manifest(expected,manifest,root):
    assert {x["path"] for x in expected["expected"]}=={x["path"] for x in manifest["renders"]}
    for row in manifest["renders"]: assert row["status"]=="PASS" and row["sha256"]==row["expected_sha256"]==sha(root/row["path"])
def main():
    facts=json.loads((STAGING/"working"/"task6"/"task6_build_input.json").read_text()); assert_claim_boundaries(facts)
    source=next(p for p in sorted((STAGING/"authoritative-materializations").glob("source-*/source")) if (p/"pubspec.yaml").exists());assert_source_grounding(facts,source)
    for name in PRIMARY: assert (STAGING/"artifacts"/name).is_file() and (STAGING/"artifacts"/name).stat().st_size>1000
    summary=json.loads((STAGING/"manifests"/"task6_workbook_build_summary.json").read_text()); assert summary["formula_error_matches"]==0 and summary["sheets"]>=35
    expected=json.loads((STAGING/"manifests"/"task6_expected_visual_renders.json").read_text()); visual=json.loads((STAGING/"manifests"/"task6_visual_qa_manifest.json").read_text()); assert_visual_manifest(expected,visual,STAGING/"renders"/"task6")
    assert len(facts["final_test_cases"])==135 and len(facts["git_history"])==137
    text=""
    for name in PRIMARY:
        p=STAGING/"artifacts"/name
        if name.endswith(".pdf"): text+="\n".join((page.extract_text() or "") for page in PdfReader(p).pages)
        elif name.endswith((".docx",".xlsx")):
            with zipfile.ZipFile(p) as z:
                text+=" ".join(z.read(n).decode("utf-8","ignore") for n in z.namelist() if n.endswith(".xml"))
    secret=re.compile(r"(?:AIza[0-9A-Za-z_-]{20,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{20,})")
    assert not secret.search(text)
    checks=(STAGING/"manifests"/"SHA256SUMS.txt").read_text().splitlines(); listed={line.split("  ",1)[1] for line in checks if "  " in line}
    for name in PRIMARY: assert f"artifacts/{name}" in listed
    result={"status":"passed_with_human_actions","primary_artifacts":10,"workbook_sheets":summary["sheets"],"workbook_pdf_pages":sum(len(PdfReader(STAGING/"artifacts"/n).pages) for n in PRIMARY if n.endswith(".pdf") and ("Trail" in n or "Package" in n)),"document_pdf_pages":sum(len(PdfReader(STAGING/"artifacts"/n).pages) for n in PRIMARY if n.endswith(".pdf") and "Report" in n),"final_test_cases":len(facts["final_test_cases"]),"algorithm_cases":len(facts["algorithm_cases"]),"git_commits":len(facts["git_history"]),"historical_uat_records":len(facts["historical_uat"]),"formula_contracts":len(summary["formula_contracts"]),"formula_error_scan":"0 errors","render_count":len(expected["expected"]),"visual_manifest_sha256":sha(STAGING/"manifests"/"task6_visual_qa_manifest.json"),"checksum_entries":len(checks)}
    (STAGING/"manifests"/"task6_verification_summary.json").write_text(json.dumps(result,indent=2)+"\n"); print(json.dumps(result,indent=2))
if __name__=="__main__":main()
