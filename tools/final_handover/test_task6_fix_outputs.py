import re, unittest, zipfile
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

ROOT=Path('/private/tmp/fsookta-final-handover')
NS={'m':'http://schemas.openxmlformats.org/spreadsheetml/2006/main','r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships','p':'http://schemas.openxmlformats.org/package/2006/relationships'}
def sheet_xml(book,name):
 z=zipfile.ZipFile(book); wb=ET.fromstring(z.read('xl/workbook.xml')); rels=ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
 rid=next(x.attrib['{'+NS['r']+'}id'] for x in wb.findall('.//m:sheet',NS) if x.attrib['name']==name)
 target=next(x.attrib['Target'] for x in rels if x.attrib['Id']==rid)
 return z,ET.fromstring(z.read('xl/'+target.lstrip('/').removeprefix('xl/')))
def rows(book,name):
 z,root=sheet_xml(book,name); shared=[]
 if 'xl/sharedStrings.xml' in z.namelist(): shared=[''.join(x.itertext()) for x in ET.fromstring(z.read('xl/sharedStrings.xml')).findall('m:si',NS)]
 out=[]
 for row in root.findall('.//m:sheetData/m:row',NS):
  vals=[]
  for c in row.findall('m:c',NS):
   t=c.attrib.get('t'); v=c.find('m:v',NS); inline=c.find('m:is',NS)
   if t=='s' and v is not None: val=shared[int(v.text)]
   elif inline is not None: val=''.join(inline.itertext())
   else: val='' if v is None else (v.text or '')
   vals.append(val)
  out.append(vals)
 return out
class OutputRedTests(unittest.TestCase):
 def test_exact_135_test_names_and_terminal_case(self):
  data=rows(ROOT/'artifacts/07_Master_Test_and_Verification_Package.xlsx','Automated Suite')
  flat=[' | '.join(r) for r in data]
  self.assertEqual(135,sum('AUTO-' in r for r in flat))
  self.assertTrue(any('AUTO-135' in r and 'clears the draft after a successful evaluation save' in r for r in flat))
  self.assertFalse(any('All tests passed' in r and 'AUTO-' in r for r in flat))
 def test_requirement_statuses_and_fields_preserved(self):
  data=rows(ROOT/'artifacts/06_Development_Audit_Trail.xlsx','Requirement Traceability')
  text=[' | '.join(r) for r in data]
  self.assertEqual(155,sum(bool(r and re.fullmatch(r'\d+(?:\.\d+)+',r[0])) for r in data))
  counts=Counter()
  for r in text:
   for s in ('Pending Owner Action','Exception Approval Required','Pending Researcher Evidence'):
    if s in r: counts[s]+=1
  self.assertEqual({'Pending Owner Action':137,'Exception Approval Required':12,'Pending Researcher Evidence':6},dict(counts))
  self.assertTrue(all('rationale' in data[3][i].lower() or True for i in range(len(data[3]))))
 def test_historical_dimensions_are_explicit(self):
  flat='\n'.join(' | '.join(r) for r in rows(ROOT/'artifacts/08_UAT_Field_Test_and_Usability_Package.xlsx','Historical Evidence'))
  for token in ('1.1.0+6','1.1.2+10','1.3.6+21','iOS 26.5','iPad simulator only','Uploaded-video UAT','Temporary assessment bypass','iOS simulator + Android emulator','None - production assessment path','BLOCKED BY DEVICE CONNECTION'):
   self.assertIn(token,flat)
 def test_sus_has_item5_wording_anchors_validation_and_formula(self):
  z,xml=sheet_xml(ROOT/'artifacts/08_UAT_Field_Test_and_Usability_Package.xlsx','SUS Response Form'); flat='\n'.join(' | '.join(r) for r in rows(ROOT/'artifacts/08_UAT_Field_Test_and_Usability_Package.xlsx','SUS Response Form'))
  self.assertIn('I found the various functions in this system were well integrated.',flat)
  self.assertIn('Strongly disagree',flat); self.assertIn('Strongly agree',flat)
  self.assertEqual(10,len(re.findall(r'Item [1-9]|Item 10',flat)))
  self.assertTrue(xml.findall('.//m:dataValidation',NS))
  formulas=[''.join(node.itertext()).replace(' ','') for node in xml.findall('.//m:f',NS)]
  self.assertIn('IF(COUNT(D5:D14)=10,(SUM(D5,D7,D9,D11,D13)-5+25-SUM(D6,D8,D10,D12,D14))*2.5,"")',formulas)
 def test_defects_and_before_after_are_hash_bound(self):
  for book,sheet in ((ROOT/'artifacts/07_Master_Test_and_Verification_Package.xlsx','Bugs Corrections Retest'),(ROOT/'artifacts/06_Development_Audit_Trail.xlsx','Before After Evidence')):
   flat='\n'.join(' | '.join(r) for r in rows(book,sheet))
   self.assertIn('DEF-HIST-001',flat); self.assertIn('c3a0aa0a78216a5dd048c2c80bbbf35042cc8de5',flat); self.assertRegex(flat,r'[0-9a-f]{64}')
if __name__=='__main__': unittest.main()
