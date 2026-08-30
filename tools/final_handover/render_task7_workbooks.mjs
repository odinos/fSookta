import fs from 'node:fs/promises';
import path from 'node:path';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';
const ROOT=process.env.FSOOKTA_HANDOVER_ROOT || '/private/tmp/fsookta-final-handover';
for(const name of ['09_Security_and_Access_Control_Matrices.xlsx','11_Publication_Tables.xlsx']){
  const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(path.join(ROOT,'artifacts',name)));
  const out=path.join(ROOT,'renders','task7','sheets',path.parse(name).name);await fs.mkdir(out,{recursive:true});
  for(const [i,s] of wb.worksheets.items.entries()){
    const blob=await wb.render({sheetName:s.name,autoCrop:'all',scale:1,format:'png'});
    const safe=s.name.replace(/[^A-Za-z0-9_-]+/g,'_');
    await fs.writeFile(path.join(out,`${String(i+1).padStart(2,'0')}_${safe}.png`),new Uint8Array(await blob.arrayBuffer()));
  }
  console.log(JSON.stringify({workbook:name,sheets:wb.worksheets.items.length}));
}
