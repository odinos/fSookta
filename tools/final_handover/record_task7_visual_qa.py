#!/usr/bin/env python3
"""Bind Task 7 renders to an externally authored manual visual decision."""
from __future__ import annotations
import hashlib, json, os
from pathlib import Path

ROOT=Path(os.environ.get('SOOKTA_HANDOVER_ROOT','/private/tmp/fsookta-final-handover'))
R=ROOT/'renders'/'task7'; M=ROOT/'manifests'
EXTERNAL=ROOT/'manual-decisions'/'task7_external_visual_decision.json'
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def rel(p): return Path(p).relative_to(ROOT).as_posix()
def main():
 surfaces=[]
 for kind,base,pattern in [('docx_page',R/'docs','*.png'),('workbook_sheet',R/'sheets','*.png'),('pptx_slide',R/'deck','slide-*.png'),('pdf_page',R/'pdf','*.png')]:
  for p in sorted(base.rglob(pattern)): surfaces.append({'kind':kind,'path':rel(p),'sha256':sha(p)})
 counts={kind:sum(x['kind']==kind for x in surfaces) for kind in ('docx_page','workbook_sheet','pptx_slide','pdf_page')}
 expected={'schema_version':2,'task':7,'source_commit':'bf8867a2083357cb9d60915bf6c2233801f923d8','count':len(surfaces),'counts':counts,'renders':surfaces}
 M.mkdir(parents=True,exist_ok=True); ep=M/'task7_expected_visual_renders.json';ep.write_text(json.dumps(expected,indent=2)+'\n')
 if not EXTERNAL.is_file(): raise FileNotFoundError(f'external visual decision required: {EXTERNAL}')
 decision=json.loads(EXTERNAL.read_text()); expected_hash=sha(ep)
 assert decision['expected_manifest_sha256']==expected_hash
 assert decision['decision'].upper()=='PASS'
 assert set(decision['inspected_paths'])=={x['path'] for x in surfaces}
 record={'schema_version':2,'task':7,'source':'external manual decision','decision':decision['decision'].upper(),'expected_manifest_sha256':expected_hash,'external_decision_path':str(EXTERNAL),'external_decision_sha256':sha(EXTERNAL),'renders':surfaces,'inspection_scope':decision['inspection_scope'],'limitations':decision['limitations']}
 (M/'task7_visual_qa_manifest.json').write_text(json.dumps(record,indent=2)+'\n')
 print(json.dumps({'renders':len(surfaces),'counts':counts,'external_decision_sha256':sha(EXTERNAL)},sort_keys=True))
if __name__=='__main__':main()
