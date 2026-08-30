#!/usr/bin/env python3
"""Patch unsupported OOXML print metadata after artifact-tool authoring."""
from pathlib import Path
import os
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile
import xml.etree.ElementTree as ET

NS='http://schemas.openxmlformats.org/spreadsheetml/2006/main'
ET.register_namespace('',NS)
Q=lambda tag:f'{{{NS}}}{tag}'
def patch_xml(data):
 root=ET.fromstring(data)
 sheet_pr=root.find(Q('sheetPr'))
 if sheet_pr is None:
  sheet_pr=ET.Element(Q('sheetPr')); root.insert(0,sheet_pr)
 page_pr=sheet_pr.find(Q('pageSetUpPr'))
 if page_pr is None: page_pr=ET.SubElement(sheet_pr,Q('pageSetUpPr'))
 page_pr.set('fitToPage','1'); page_pr.set('autoPageBreaks','0')
 margins=root.find(Q('pageMargins'))
 if margins is None: margins=ET.SubElement(root,Q('pageMargins'))
 for key,val in {'left':'0.25','right':'0.25','top':'0.45','bottom':'0.45','header':'0.2','footer':'0.2'}.items(): margins.set(key,val)
 setup=root.find(Q('pageSetup'))
 if setup is None: setup=ET.SubElement(root,Q('pageSetup'))
 for key,val in {'paperSize':'1','orientation':'landscape','fitToWidth':'1','fitToHeight':'0','horizontalDpi':'300','verticalDpi':'300'}.items(): setup.set(key,val)
 return ET.tostring(root,encoding='utf-8',xml_declaration=True)
def patch(path):
 path=Path(path)
 with ZipFile(path) as src, NamedTemporaryFile(dir=path.parent,suffix='.xlsx',delete=False) as tmp:
  temp=Path(tmp.name)
  with ZipFile(tmp,'w',ZIP_DEFLATED) as dst:
   for info in src.infolist():
    data=src.read(info.filename)
    if info.filename.startswith('xl/worksheets/sheet') and info.filename.endswith('.xml'): data=patch_xml(data)
    dst.writestr(info,data)
 temp.replace(path)
root=Path(os.environ.get('FSOOKTA_HANDOVER_ROOT','/private/tmp/fsookta-final-handover'))
for name in ('06_Development_Audit_Trail.xlsx','07_Master_Test_and_Verification_Package.xlsx','08_UAT_Field_Test_and_Usability_Package.xlsx'): patch(root/'artifacts'/name)
print('print metadata patched: 3 workbooks')
