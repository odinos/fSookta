import fs from 'node:fs/promises'; import path from 'node:path';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const root='/private/tmp/fsookta-final-handover';
for(const file of ['06_Development_Audit_Trail.xlsx','07_Master_Test_and_Verification_Package.xlsx','08_UAT_Field_Test_and_Usability_Package.xlsx']){
 const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(path.join(root,'artifacts',file)));
 const out=path.join(root,'renders/task6/fix_round1_sheets',file.replace('.xlsx','')); await fs.mkdir(out,{recursive:true});
 let n=0; for(const sheet of wb.worksheets.items){n++; const blob=await wb.render({sheetName:sheet.name,autoCrop:'all',scale:1,format:'png'}); const safe=sheet.name.replace(/[^A-Za-z0-9_-]/g,'_'); await fs.writeFile(path.join(out,`${String(n).padStart(2,'0')}_${safe}.png`),new Uint8Array(await blob.arrayBuffer()));}
 console.log(`${file}: ${n}`);
}
