#!/usr/bin/env python3
"""Normalize Task 7 OOXML metadata without changing document content."""
import os, tempfile, zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT=Path(os.environ.get('SOOKTA_HANDOVER_ROOT','/private/tmp/fsookta-final-handover'))
ART=ROOT/'artifacts'
NAMES=['09_Security_Privacy_and_Data_Protection_Report.docx','09_Security_and_Access_Control_Matrices.xlsx','10_End_User_Manual.docx','10_Research_Admin_Manual.docx','10_Developer_Handover_Manual.docx','10_Knowledge_Transfer_Deck.pptx','10_Knowledge_Transfer_Minutes.docx','11_Research_Publication_Package.docx','11_Publication_Tables.xlsx']
DC='{http://purl.org/dc/elements/1.1/}';DCT='{http://purl.org/dc/terms/}';CP='{http://schemas.openxmlformats.org/package/2006/metadata/core-properties}';AP='{http://schemas.openxmlformats.org/officeDocument/2006/extended-properties}'
def patch_xml(name,data):
 root=ET.fromstring(data)
 if name=='docProps/core.xml':
  for tag,value in [(DC+'creator','SookTa Project'),(CP+'lastModifiedBy','SookTa Project'),(DC+'title','SookTa Final Handover'),(DC+'description','SookTa project handover artifact')]:
   node=root.find(tag)
   if node is None: node=ET.SubElement(root,tag)
   node.text=value
  for tag in (DCT+'created',DCT+'modified'):
   node=root.find(tag)
   if node is not None:node.text='2026-08-24T00:00:00Z'
 elif name=='docProps/app.xml':
  node=root.find(AP+'Application')
  if node is None: node=ET.SubElement(root,AP+'Application')
  node.text='SookTa Project'
 return ET.tostring(root,encoding='utf-8',xml_declaration=True)
def normalize(path):
 fd,tmp=tempfile.mkstemp(suffix=path.suffix,dir=path.parent);os.close(fd);tmp=Path(tmp)
 try:
  with zipfile.ZipFile(path) as src,zipfile.ZipFile(tmp,'w',zipfile.ZIP_DEFLATED) as dst:
   for item in src.infolist():
    data=src.read(item.filename)
    if item.filename in {'docProps/core.xml','docProps/app.xml'}:data=patch_xml(item.filename,data)
    dst.writestr(item,data)
  tmp.replace(path)
 finally:
  if tmp.exists():tmp.unlink()
for name in NAMES:normalize(ART/name)
print(f'normalized={len(NAMES)}')
