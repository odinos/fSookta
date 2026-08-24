#!/usr/bin/env python3
import hashlib,json,math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path('/private/tmp/fsookta-final-handover')
dirs=[ROOT/'renders/task6/fix_round1_algorithm',ROOT/'renders/task6/fix_round1_uat_doc',ROOT/'renders/task6/fix_round1_pdf_audit',ROOT/'renders/task6/fix_round1_pdf_master',ROOT/'renders/task6/fix_round1_pdf_uat']+sorted((ROOT/'renders/task6/fix_round1_sheets').iterdir())
images=[]
for d in dirs:
 for p in sorted(d.glob('*.png')): images.append(p)
rows=[{'path':str(p.relative_to(ROOT)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in images]
manifest=ROOT/'manifests/task6_fix_round1_expected_visual_renders.json'; manifest.write_text(json.dumps({'schema_version':1,'count':len(rows),'renders':rows},indent=2)+'\n')
out=ROOT/'renders/task6/fix_round1_contact_sheets'; out.mkdir(parents=True,exist_ok=True)
font=ImageFont.load_default(); per=12; sheets=[]
for page,start in enumerate(range(0,len(images),per),1):
 canvas=Image.new('RGB',(2400,3000),'white'); draw=ImageDraw.Draw(canvas)
 for j,p in enumerate(images[start:start+per]):
  im=Image.open(p).convert('RGB'); im.thumbnail((560,850)); x=(j%4)*600+20; y=(j//4)*980+45
  canvas.paste(im,(x,y)); label=str(p.relative_to(ROOT)); draw.text((x,y-30),label[:92],fill='black',font=font)
 dest=out/f'contact-{page:02d}.jpg'; canvas.save(dest,quality=88); sheets.append({'path':str(dest.relative_to(ROOT)),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
(ROOT/'manifests/task6_fix_round1_contact_sheets.json').write_text(json.dumps({'count':len(sheets),'sheets':sheets},indent=2)+'\n')
print(json.dumps({'renders':len(rows),'contact_sheets':len(sheets),'expected_manifest_sha256':hashlib.sha256(manifest.read_bytes()).hexdigest()}))
