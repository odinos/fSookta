#!/usr/bin/env python3
"""Independent fail-closed verification for Task 4 artifacts."""
from __future__ import annotations
import hashlib, json, re, zipfile
from pathlib import Path
from xml.etree import ElementTree as ET
from docx import Document
from openpyxl import load_workbook
from PIL import Image
from pypdf import PdfReader

VERSION="1.3.11+28"; COMMIT="bf8867a2083357cb9d60915bf6c2233801f923d8"
ALLOWED_STATUSES={
    "Complete", "Complete - Pending Signature", "Pending Owner Action",
    "Pending Researcher Evidence", "N/A with Rationale",
    "Exception Approval Required",
}

def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def verify_visual_manifest(root: Path, manifest: Path, expected: dict[str,list[str]]):
    data=json.loads(manifest.read_text(encoding="utf-8")); assert data.get("status")=="passed"
    rows={r["path"]:r for r in data.get("artifacts",[])}; assert set(rows)==set(expected)
    for artifact,renders in expected.items():
        row=rows[artifact]; path=root/artifact; assert path.is_file() and digest(path)==row["sha256"] and row["status"]=="passed"
        rr={r["path"]:r for r in row["renders"]}; assert set(rr)==set(renders)
        for render in renders:
            p=root/render; assert p.is_file() and digest(p)==rr[render]["sha256"] and rr[render]["status"]=="passed"

def doc_text(path):
    d=Document(path); return "\n".join(p.text for p in d.paragraphs)

def archive_text(path: Path) -> str:
    with zipfile.ZipFile(path) as archive:
        return "\n".join(
            archive.read(name).decode("utf-8", errors="ignore")
            for name in archive.namelist()
            if name.endswith((".xml", ".rels"))
        )

def verify_docx_preset(path: Path):
    with zipfile.ZipFile(path) as archive:
        root=ET.fromstring(archive.read("word/document.xml"))
    ns={"w":"http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
    assert not root.findall(".//w:pPr/w:pBdr",ns),f"title paragraph border/rule residue: {path}"

def verify_workbook_summary(path: Path):
    data=json.loads(path.read_text(encoding="utf-8"))
    assert data["status"]=="passed" and data["sheets"]==4
    assert data["module_records"]==14 and data["stack_records"]==17
    contracts=data["formula_contracts"]; assert len(contracts)==5
    for contract in contracts:
        assert contract["status"]=="passed"
        assert contract["expected"]["formulas"]==contract["actual"]["formulas"]
        assert contract["expected"]["values"]==contract["actual"]["values"]
    assert "matched 0 entries" in data["formula_error_scan"]
    return data

def verify_status_values(values):
    normalized=[str(value).strip() for value in values if value is not None and str(value).strip()]
    assert normalized and all(value in ALLOWED_STATUSES for value in normalized),normalized
    return normalized

def verify_checksums(staging: Path, required: list[Path]):
    manifest=staging/"manifests/SHA256SUMS.txt"; rows={}
    for line in manifest.read_text(encoding="ascii").splitlines():
        checksum,relative=line.split("  ",1); rows[relative]=checksum
    for relative,checksum in rows.items():
        path=staging/relative; assert path.is_file(),relative; assert digest(path)==checksum,relative
    for path in required:
        relative=path.relative_to(staging).as_posix()
        assert rows.get(relative)==digest(path),relative
    return len(rows)

def verify(staging: Path):
    artifacts=staging/"artifacts"; diagrams=artifacts/"diagrams"; manifests=staging/"manifests"
    report=artifacts/"03_Final_Technical_Development_Report.docx"; api=artifacts/"03_API_Applicability_Statement.docx"; xlsx=artifacts/"03_Technical_Stack_and_Module_Specification.xlsx"
    pdfs=[artifacts/"03_Final_Technical_Development_Report.pdf",artifacts/"03_API_Applicability_Statement.pdf",artifacts/"03_Technical_Stack_and_Module_Specification.pdf"]
    for p in [report,api,xlsx,*pdfs]: assert p.is_file() and p.stat().st_size>1000,p
    verify_docx_preset(report); verify_docx_preset(api)
    rt=doc_text(report); at=doc_text(api)
    import build_task4_architecture as builder
    positions=[]
    for i,h in enumerate(builder.REPORT_HEADINGS,1):
        token=f"{i}. {h}"; assert rt.count(token)==1,token; positions.append(rt.index(token))
    assert positions==sorted(positions) and VERSION in rt and COMMIT in rt
    assert all(x in at for x in ["N/A with Rationale","SOOKTA_TELEMETRY_ENABLED","defaultValue false","no direct HTTP","Pending Owner Action",VERSION,COMMIT])
    assert [len(PdfReader(p).pages) for p in pdfs]==[10,2,4]
    workbook_summary=verify_workbook_summary(manifests/"task4_workbook_build_summary.json")
    workbook=load_workbook(xlsx,read_only=True,data_only=False)
    status_values=verify_status_values(
        workbook["Evidence Sources"].cell(row=row,column=4).value for row in range(5,13)
    )
    workbook.close()
    observed_statuses=set(status_values)
    assert {
        "Complete", "Pending Owner Action", "Pending Researcher Evidence",
        "Complete - Pending Signature",
    }.issubset(observed_statuses)
    pairs=[]
    for spec in builder.diagram_specs():
        d=diagrams/f"{spec['basename']}.drawio"; p=diagrams/f"{spec['basename']}.png"; assert d.is_file() and p.is_file()
        root=ET.parse(d).getroot(); assert root.tag=="mxfile" and root.attrib["applicationVersion"]==VERSION and root.attrib["authoritativeCommit"]==COMMIT
        vertices=root.findall(".//mxCell[@vertex='1']"); edges=root.findall(".//mxCell[@edge='1']"); assert len(vertices)>=len(spec["nodes"])+2 and len(edges)==len(spec["edges"])
        with Image.open(p) as im: assert im.width>=2800 and im.height>=1800 and im.info.get("dpi",(0,0))[0]>=299
        pairs.append(spec["basename"])
    expected=json.loads((manifests/"task4_expected_visual_renders.json").read_text(encoding="utf-8"))
    assert len(expected)==22
    verify_visual_manifest(staging,manifests/"task4_visual_qa_manifest.json",expected)
    required=[report,api,xlsx,*pdfs,*[diagrams/f"{b}.{ext}" for b in pairs for ext in ("drawio","png")]]
    checksum_entries=verify_checksums(staging,required)
    forbidden=re.compile(r"(?i)(-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|AIza[0-9A-Za-z_-]{20,}|password\s*[:=]\s*\S+|api[_-]?key\s*[:=]\s*\S+)")
    for p in [report,api,xlsx,*pdfs,*diagrams.glob("*.drawio")]:
        content=archive_text(p) if p.suffix in {".docx",".xlsx"} else p.read_text(encoding="utf-8",errors="ignore")
        assert not forbidden.search(content),p
    return {
        "status":"passed_with_human_actions", "report_headings":28,
        "diagram_pairs":8, "primary_artifacts":22, "pdf_pages":16,
        "workbook_sheets":workbook_summary["sheets"],
        "formula_contracts":len(workbook_summary["formula_contracts"]),
        "formula_error_scan":"0 errors", "checksum_entries":checksum_entries,
        "visual_manifest":digest(manifests/"task4_visual_qa_manifest.json"),
        "human_actions":json.loads((staging/"working/task4/task4_build_input_summary.json").read_text())["human_actions"],
    }

if __name__=="__main__":
    import argparse
    p=argparse.ArgumentParser(); p.add_argument("--staging",type=Path,default=Path("/private/tmp/fsookta-final-handover")); p.add_argument("--summary",type=Path,required=True); a=p.parse_args(); result=verify(a.staging); a.summary.write_text(json.dumps(result,indent=2)+"\n"); print(json.dumps(result,indent=2))
