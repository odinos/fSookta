#!/usr/bin/env python3
import math, os
from pathlib import Path
from PIL import Image, ImageDraw

root=Path(os.environ.get('FSOOKTA_HANDOVER_ROOT','/private/tmp/fsookta-final-handover'))
src=root/'renders'/'task7'; out=src/'contact_sheets';out.mkdir(parents=True,exist_ok=True)
groups=[]
for kind,base,pattern,chunk in [
 ('docs',src/'docs','*.png',4),('sheets',src/'sheets','*.png',4),('pdf',src/'pdf','*.png',4),('deck',src/'deck','slide-*.png',4)]:
 for folder in sorted([p for p in base.rglob('*') if p.is_dir()] if kind!='deck' else [base]):
  files=sorted(folder.glob(pattern))
  for i in range(0,len(files),chunk):groups.append((kind,folder.name,i//chunk+1,files[i:i+chunk]))
for kind,name,part,files in groups:
 thumbs=[]
 for f in files:
  im=Image.open(f).convert('RGB');im.thumbnail((700,850));thumbs.append((f,im.copy()))
 w=1440;h=920*math.ceil(len(thumbs)/2);canvas=Image.new('RGB',(w,h),'#d8d8d8');draw=ImageDraw.Draw(canvas)
 for idx,(f,im) in enumerate(thumbs):
  x=(idx%2)*720+(720-im.width)//2;y=(idx//2)*920+40
  canvas.paste(im,(x,y));draw.text((idx%2*720+16,idx//2*920+10),f.name,fill='black')
 target=out/f'{kind}__{name}__{part:02d}.jpg';canvas.save(target,quality=88)
print(f'contact_sheets={len(groups)}')
