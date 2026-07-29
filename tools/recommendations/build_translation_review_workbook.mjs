import fs from "node:fs/promises";
import path from "node:path";
import {
  FileBlob,
  SpreadsheetFile,
  Workbook,
} from "@oai/artifact-tool";

const root = process.cwd();
const translationPath = path.join(
  root,
  "data/recommendations/translation_review.csv",
);
const masterPath = path.join(
  root,
  "data/recommendations/recommendation_master.csv",
);
const conflictPath = path.join(
  root,
  "data/recommendations/reports/conflicts_missing_sources.csv",
);
const sourcePath = path.join(
  root,
  "data/recommendations/source_registry.json",
);
const outputPath = path.join(
  root,
  "docs/reviews/Sookta_Recommendation_Translation_Review_2026-07-29.xlsx",
);
const previewDir = path.join(root, "tmp/recommendation-review-previews");

const navy = "#17365D";
const blue = "#D9EAF7";
const paleBlue = "#EEF5FB";
const green = "#D9EAD3";
const amber = "#FFF2CC";
const red = "#F4CCCC";
const gray = "#E7E6E6";

function withoutBom(text) {
  return text.replace(/^\uFEFF/, "");
}

function parseCsvRows(text) {
  const rows = [];
  let row = [];
  let field = "";
  let quoted = false;

  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];
    if (quoted) {
      if (character === '"' && text[index + 1] === '"') {
        field += '"';
        index += 1;
      } else if (character === '"') {
        quoted = false;
      } else {
        field += character;
      }
    } else if (character === '"') {
      quoted = true;
    } else if (character === ",") {
      row.push(field);
      field = "";
    } else if (character === "\n") {
      row.push(field.replace(/\r$/, ""));
      rows.push(row);
      row = [];
      field = "";
    } else {
      field += character;
    }
  }

  if (field.length > 0 || row.length > 0) {
    row.push(field.replace(/\r$/, ""));
    rows.push(row);
  }
  return rows;
}

function styleHeader(range) {
  range.format = {
    fill: navy,
    font: { bold: true, color: "#FFFFFF" },
    wrapText: true,
    verticalAlignment: "center",
    horizontalAlignment: "center",
    borders: {
      bottom: { style: "medium", color: "#8EA9C1" },
    },
  };
  range.format.rowHeight = 34;
}

function styleDataSheet(sheet, usedRange, tableName) {
  sheet.showGridLines = false;
  sheet.freezePanes.freezeRows(1);
  sheet.freezePanes.freezeColumns(4);
  styleHeader(sheet.getRange(`A1:${usedRange.split(":")[1].replace(/\d+/, "1")}`));
  const table = sheet.tables.add(usedRange, true, tableName);
  table.showFilterButton = true;
  table.showBandedRows = true;
  sheet.getRange(usedRange).format.verticalAlignment = "top";
}

const translationCsv = withoutBom(
  await fs.readFile(translationPath, "utf8"),
);
const masterCsv = withoutBom(await fs.readFile(masterPath, "utf8"));
const rawTranslationRows = parseCsvRows(translationCsv);
if (rawTranslationRows.length !== 176) {
  throw new Error(
    `Expected 176 translation CSV rows, got ${rawTranslationRows.length}`,
  );
}
const workbook = Workbook.create();
const review = workbook.worksheets.add("Translation Review");
review.getRange("A1:S176").values = rawTranslationRows.map((row, index) =>
  index === 0
    ? row
    : row.map((value, column) => {
        if (column === 15) {
          // Prevent the spreadsheet engine from converting the timezone-bearing
          // ISO string to a timezone-less Excel serial date. The leading word
          // joiner is invisible but keeps the approval evidence as text.
          return `\u2060${value}`;
        }
        return column === 16 ? Number(value) : value;
      }),
);
styleDataSheet(review, "A1:S176", "TranslationReviewTable");
review.getRange("P2:P176").format.numberFormat = "@";
review.getRange("Q2:Q176").format.numberFormat = "0";
review.getRange("A2:S176").format.rowHeight = 48;
review.getRange("D2:E176").format.wrapText = true;
review.getRange("M2:M176").format.wrapText = true;
review.getRange("A:A").format.columnWidth = 29;
review.getRange("B:B").format.columnWidth = 28;
review.getRange("C:C").format.columnWidth = 17;
review.getRange("D:D").format.columnWidth = 48;
review.getRange("E:E").format.columnWidth = 55;
review.getRange("F:L").format.columnWidth = 18;
review.getRange("M:M").format.columnWidth = 34;
review.getRange("N:N").format.columnWidth = 17;
review.getRange("O:P").format.columnWidth = 22;
review.getRange("Q:Q").format.columnWidth = 22;
review.getRange("R:R").format.columnWidth = 34;
review.getRange("S:S").format.columnWidth = 12;
review.getRange("N2:N176").dataValidation = {
  rule: {
    type: "list",
    values: ["pending", "needs_revision", "rejected", "approved"],
  },
};
review.getRange("F2:F176").dataValidation = {
  rule: {
    type: "list",
    values: ["direct", "plain_english"],
  },
};
review.getRange("L2:L176").dataValidation = {
  rule: {
    type: "list",
    values: ["pending_human_review", "pass", "needs_revision"],
  },
};
review.getRange("N2:N176").conditionalFormats.add("containsText", {
  text: "approved",
  format: { fill: green, font: { color: "#274E13", bold: true } },
});
review.getRange("N2:N176").conditionalFormats.add("containsText", {
  text: "pending",
  format: { fill: amber, font: { color: "#7F6000" } },
});
review.getRange("N2:N176").conditionalFormats.add("containsText", {
  text: "needs_revision",
  format: { fill: red, font: { color: "#990000", bold: true } },
});
review.getRange("N2:N176").conditionalFormats.add("containsText", {
  text: "rejected",
  format: { fill: red, font: { color: "#990000", bold: true } },
});

const rawMasterRows = parseCsvRows(masterCsv);
if (rawMasterRows.length !== 176) {
  throw new Error(`Expected 176 master CSV rows, got ${rawMasterRows.length}`);
}
const master = workbook.worksheets.add("Master Catalog");
master.getRange("A1:R176").values = rawMasterRows.map((row, index) =>
  index === 0
    ? row
    : row.map((value, column) =>
        column === 2 || column === 13 ? Number(value) : value,
      ),
);
styleDataSheet(master, "A1:R176", "MasterCatalogTable");
master.getRange("A2:R176").format.rowHeight = 48;
master.getRange("E2:J176").format.wrapText = true;
master.getRange("M2:R176").format.wrapText = true;
master.getRange("A:B").format.columnWidth = 29;
master.getRange("C:C").format.columnWidth = 12;
master.getRange("D:D").format.columnWidth = 17;
master.getRange("E:E").format.columnWidth = 18;
master.getRange("F:I").format.columnWidth = 17;
master.getRange("J:J").format.columnWidth = 55;
master.getRange("K:K").format.columnWidth = 34;
master.getRange("L:L").format.columnWidth = 13;
master.getRange("M:M").format.columnWidth = 30;
master.getRange("N:P").format.columnWidth = 18;
master.getRange("Q:R").format.columnWidth = 45;

const sourceRegistry = JSON.parse(await fs.readFile(sourcePath, "utf8"));
const sourceSheet = workbook.worksheets.add("Source Register");
const sourceHeaders = [
  "Source ID",
  "Title",
  "Language",
  "Priority",
  "Role",
  "SHA-256",
  "Local path",
  "Distribution note",
];
const sourceRows = sourceRegistry.sources.map((source) => [
  source.id,
  source.title,
  source.language,
  source.priority,
  source.documentRole,
  source.sha256,
  source.localPath,
  source.copyrightOrDistributionNote,
]);
sourceSheet.getRange(`A1:H${sourceRows.length + 1}`).values = [
  sourceHeaders,
  ...sourceRows,
];
styleDataSheet(
  sourceSheet,
  `A1:H${sourceRows.length + 1}`,
  "SourceRegisterTable",
);
sourceSheet.getRange(`A2:H${sourceRows.length + 1}`).format.rowHeight = 56;
sourceSheet.getRange(`B2:H${sourceRows.length + 1}`).format.wrapText = true;
sourceSheet.getRange("A:A").format.columnWidth = 34;
sourceSheet.getRange("B:B").format.columnWidth = 38;
sourceSheet.getRange("C:D").format.columnWidth = 12;
sourceSheet.getRange("E:E").format.columnWidth = 34;
sourceSheet.getRange("F:F").format.columnWidth = 67;
sourceSheet.getRange("G:G").format.columnWidth = 65;
sourceSheet.getRange("H:H").format.columnWidth = 58;

const conflictCsv = withoutBom(await fs.readFile(conflictPath, "utf8"));
const rawConflictRows = parseCsvRows(conflictCsv);
if (rawConflictRows.length !== 5) {
  throw new Error(
    `Expected 5 conflict CSV rows, got ${rawConflictRows.length}`,
  );
}
const conflicts = workbook.worksheets.add("Conflicts");
conflicts.getRange("A1:I5").values = rawConflictRows.map((row, index) => [
  ...row,
  index === 0 ? "blank_metadata_fields" : null,
]);
conflicts.getRange("I2:I5").formulas = rawConflictRows
  .slice(1)
  .map((_, index) => {
    const row = index + 2;
    return [
      `=IF(LEN(TRIM(C${row}))=0,1,0)+IF(LEN(TRIM(D${row}))=0,1,0)+IF(LEN(TRIM(E${row}))=0,1,0)+IF(LEN(TRIM(F${row}))=0,1,0)+IF(LEN(TRIM(G${row}))=0,1,0)`,
    ];
  });
styleDataSheet(conflicts, "A1:I5", "ConflictsTable");
conflicts.getRange("A2:I5").format.rowHeight = 72;
conflicts.getRange("C2:I5").format.wrapText = true;
conflicts.getRange("A:B").format.columnWidth = 28;
conflicts.getRange("C:C").format.columnWidth = 31;
conflicts.getRange("D:E").format.columnWidth = 38;
conflicts.getRange("F:F").format.columnWidth = 64;
conflicts.getRange("G:G").format.columnWidth = 54;
conflicts.getRange("H:H").format.columnWidth = 18;
conflicts.getRange("I:I").format.columnWidth = 24;
conflicts.getRange("H2:H5").dataValidation = {
  rule: {
    type: "list",
    values: ["pending", "needs_revision", "rejected", "approved"],
  },
};
conflicts.getRange("H2:H5").conditionalFormats.add("containsText", {
  text: "pending",
  format: { fill: amber, font: { color: "#7F6000" } },
});
conflicts.getRange("H2:H5").conditionalFormats.add("containsText", {
  text: "approved",
  format: { fill: green, font: { color: "#274E13", bold: true } },
});
conflicts.getRange("C2:G5").conditionalFormats.add("containsBlanks", {
  format: { fill: red, font: { color: "#990000", bold: true } },
});
conflicts.getRange("I2:I5").conditionalFormats.add("cellIs", {
  operator: "greaterThan",
  formula: 0,
  format: { fill: red, font: { color: "#990000", bold: true } },
});

const gateAudit = workbook.worksheets.add("Gate Audit");
gateAudit.getRange("A1:E176").values = [
  [
    "recommendation_id",
    "english_contains_thai",
    "invalid_translation_style",
    "invalid_approved_at",
    "invalid_translation_version",
  ],
  ...rawTranslationRows
    .slice(1)
    .map((row) => [row[0], null, null, null, null]),
];
gateAudit.getRange("B2:E176").formulas = rawTranslationRows
  .slice(1)
  .map((_, index) => {
    const row = index + 2;
    const english = `'Translation Review'!E${row}`;
    const translationStyle = `'Translation Review'!F${row}`;
    const timestamp = `'Translation Review'!P${row}`;
    const version = `'Translation Review'!Q${row}`;
    const year = `VALUE(MID(${timestamp},2,4))`;
    const month = `VALUE(MID(${timestamp},7,2))`;
    const day = `VALUE(MID(${timestamp},10,2))`;
    const hour = `VALUE(MID(${timestamp},13,2))`;
    const minute = `VALUE(MID(${timestamp},16,2))`;
    const second = `VALUE(MID(${timestamp},19,2))`;
    const timezoneHour = `VALUE(MID(${timestamp},22,2))`;
    const timezoneMinute = `VALUE(MID(${timestamp},25,2))`;
    const lastDay =
      `CHOOSE(${month},31,` +
      `IF(AND(MOD(${year},4)=0,OR(MOD(${year},100)<>0,MOD(${year},400)=0)),29,28),` +
      "31,30,31,30,31,31,30,31,30,31)";
    return [
      `=IFERROR(IF(REGEXTEST(${english},"[ก-๙]"),1,0),1)`,
      `=IF(OR(${translationStyle}="direct",${translationStyle}="plain_english"),0,1)`,
      `=IFERROR(IF(AND(OR(LEN(${timestamp})=21,LEN(${timestamp})=26),MID(${timestamp},6,1)="-",MID(${timestamp},9,1)="-",MID(${timestamp},12,1)="T",MID(${timestamp},15,1)=":",MID(${timestamp},18,1)=":",${month}>=1,${month}<=12,${day}>=1,${day}<=${lastDay},${hour}>=0,${hour}<=23,${minute}>=0,${minute}<=59,${second}>=0,${second}<=59,OR(AND(LEN(${timestamp})=21,RIGHT(${timestamp},1)="Z"),AND(LEN(${timestamp})=26,OR(MID(${timestamp},21,1)="+",MID(${timestamp},21,1)="-"),MID(${timestamp},24,1)=":",${timezoneHour}>=0,${timezoneHour}<=23,${timezoneMinute}>=0,${timezoneMinute}<=59))),0,1),1)`,
      `=IF(AND(ISNUMBER(${version}),${version}>0,${version}=INT(${version})),0,1)`,
    ];
  });
styleDataSheet(gateAudit, "A1:E176", "GateAuditTable");
gateAudit.getRange("A:A").format.columnWidth = 34;
gateAudit.getRange("B:E").format.columnWidth = 28;
gateAudit.getRange("A2:E176").format.rowHeight = 24;
gateAudit.getRange("B2:E176").conditionalFormats.add("cellIs", {
  operator: "greaterThan",
  formula: 0,
  format: { fill: red, font: { color: "#990000", bold: true } },
});

const coverage = workbook.worksheets.add("Coverage");
coverage.showGridLines = false;
coverage.getRange("A1:B1").merge();
coverage.getRange("A1").values = [["Translation Approval Coverage"]];
coverage.getRange("A1:B1").format = {
  fill: navy,
  font: { bold: true, color: "#FFFFFF", size: 16 },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
coverage.getRange("A1:B1").format.rowHeight = 38;
coverage.getRange("A3:B25").values = [
  ["Metric", "Value"],
  ["Total master rows", null],
  ["Total review rows", null],
  ["Approved", null],
  ["Pending", null],
  ["Needs revision", null],
  ["Rejected", null],
  ["Approval coverage", null],
  ["Master/review identity mismatches", null],
  ["Duplicate or blank review IDs", null],
  ["Master rows not source_verified", null],
  ["Blank Thai source text", null],
  ["Blank English draft", null],
  ["English draft contains Thai", null],
  ["Invalid translation style", null],
  ["Unresolved or invalid review checks", null],
  ["Blank approved_by", null],
  ["Invalid approved_at timezone", null],
  ["Invalid translation version", null],
  ["Conflict report rows", null],
  ["Missing, duplicate, or unexpected conflicts", null],
  ["Blank conflict metadata fields", null],
  ["Unapproved conflicts", null],
];
styleHeader(coverage.getRange("A3:B3"));
coverage.getRange("B4:B25").formulas = [
  ["=COUNTA('Master Catalog'!A2:A176)"],
  ["=COUNTA('Translation Review'!A2:A1000)"],
  ["=COUNTIF('Translation Review'!N2:N1000,\"approved\")"],
  ["=COUNTIF('Translation Review'!N2:N1000,\"pending\")"],
  ["=COUNTIF('Translation Review'!N2:N1000,\"needs_revision\")"],
  ["=COUNTIF('Translation Review'!N2:N1000,\"rejected\")"],
  ["=IF(B5=0,0,B6/B5)"],
  [
    "=SUMPRODUCT(--('Translation Review'!A2:A176<>'Master Catalog'!A2:A176))+SUMPRODUCT(--('Translation Review'!B2:B176<>'Master Catalog'!B2:B176))+SUMPRODUCT(--('Translation Review'!C2:C176<>'Master Catalog'!D2:D176))+SUMPRODUCT(--('Translation Review'!D2:D176<>'Master Catalog'!J2:J176))+SUMPRODUCT(--('Translation Review'!R2:R176<>'Master Catalog'!K2:K176))+SUMPRODUCT(--('Translation Review'!S2:S176<>'Master Catalog'!L2:L176))",
  ],
  [
    "=COUNTBLANK('Translation Review'!A2:A176)+SUMPRODUCT(--(COUNTIF('Translation Review'!A2:A176,'Translation Review'!A2:A176)>1))",
  ],
  [
    "=COUNTIFS('Master Catalog'!A2:A176,\"<>\",'Master Catalog'!P2:P176,\"<>source_verified\")",
  ],
  ["=COUNTBLANK('Translation Review'!D2:D176)"],
  ["=COUNTBLANK('Translation Review'!E2:E176)"],
  ["=SUM('Gate Audit'!B2:B176)"],
  ["=SUM('Gate Audit'!C2:C176)"],
  [
    "=COUNTIF('Translation Review'!G2:G176,\"<>pass\")+COUNTIFS('Translation Review'!H2:H176,\"<>pass\",'Translation Review'!H2:H176,\"<>not_applicable\")+COUNTIF('Translation Review'!I2:I176,\"<>pass\")+COUNTIF('Translation Review'!J2:J176,\"<>pass\")+COUNTIF('Translation Review'!K2:K176,\"<>pass\")+COUNTIF('Translation Review'!L2:L176,\"<>pass\")",
  ],
  ["=COUNTBLANK('Translation Review'!O2:O176)"],
  ["=SUM('Gate Audit'!D2:D176)"],
  ["=SUM('Gate Audit'!E2:E176)"],
  ["=COUNTA('Conflicts'!A2:A100)"],
  [
    "=ABS(COUNTA('Conflicts'!A2:A100)-4)+ABS(COUNTIFS('Conflicts'!A2:A100,\"act_ref_weight_high.01\",'Conflicts'!B2:B100,\"act_ref_weight_high\")-1)+ABS(COUNTIFS('Conflicts'!A2:A100,\"act_avoid_bend.01\",'Conflicts'!B2:B100,\"act_avoid_bend\")-1)+ABS(COUNTIFS('Conflicts'!A2:A100,\"act_harvest_empty_often.01\",'Conflicts'!B2:B100,\"act_harvest_empty_often\")-1)+ABS(COUNTIFS('Conflicts'!A2:A100,\"act_ref_weight_low.01\",'Conflicts'!B2:B100,\"act_ref_weight_low\")-1)",
  ],
  ["=SUM('Conflicts'!I2:I5)"],
  [
    "=COUNTIFS('Conflicts'!A2:A100,\"<>\",'Conflicts'!H2:H100,\"<>approved\")",
  ],
];
coverage.getRange("B10").format.numberFormat = "0.00%";
coverage.getRange("A27:B27").values = [["Development gate", null]];
coverage.getRange("B27").formulas = [
  [
    '=IF(AND(B4>0,B4=B5,B10=100%,B7=0,B8=0,B9=0,B11=0,B12=0,B13=0,B14=0,B15=0,B16=0,B17=0,B18=0,B19=0,B20=0,B21=0,B22=4,B23=0,B24=0,B25=0),"READY","BLOCKED")',
  ],
];
coverage.getRange("A27:B27").format = {
  fill: gray,
  font: { bold: true },
  borders: { preset: "outside", style: "medium", color: "#7F8C8D" },
};
coverage.getRange("B27").conditionalFormats.add("containsText", {
  text: "READY",
  format: { fill: green, font: { color: "#274E13", bold: true } },
});
coverage.getRange("B27").conditionalFormats.add("containsText", {
  text: "BLOCKED",
  format: { fill: red, font: { color: "#990000", bold: true } },
});
coverage.getRange("A:A").format.columnWidth = 47;
coverage.getRange("B:B").format.columnWidth = 20;
coverage.getRange("A3:B27").format.rowHeight = 26;
coverage.getRange("A4:B25").format.borders = {
  insideHorizontal: { style: "thin", color: "#D9E2F3" },
  bottom: { style: "thin", color: "#D9E2F3" },
};

const instructions = workbook.worksheets.add("Instructions");
instructions.showGridLines = false;
instructions.getRange("A1:F1").merge();
instructions.getRange("A1").values = [["วิธีตรวจคำแปลก่อนนำขึ้นแอป"]];
instructions.getRange("A1:F1").format = {
  fill: navy,
  font: { bold: true, color: "#FFFFFF", size: 16 },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
instructions.getRange("A1:F1").format.rowHeight = 40;
instructions.getRange("A3:F12").merge(true);
instructions.getRange("A3:A12").values = [
  ["1. ตรวจข้อความไทยเทียบกับเอกสารและเลขหน้าในคอลัมน์ source_id / source_page"],
  ["2. ตรวจว่าภาษาอังกฤษไม่มีอักษรไทย ให้ความหมายตรงกัน อ่านเข้าใจง่าย และไม่เพิ่มคำแนะนำใหม่"],
  ["3. ตรวจตัวเลข ช่วงตัวเลข หน่วย เวลา ความเร่งด่วน และคำปฏิเสธ เช่น ห้าม/ไม่เกิน/ทันที"],
  ["4. หากต้องแก้ ให้แก้ english_draft ใส่ review_comment และเลือก needs_revision"],
  ["5. เมื่อข้อความถูกต้อง ให้ตั้ง translation_style เป็น direct หรือ plain_english, meaning_review เป็น pass และ approval_status เป็น approved"],
  ["6. ใส่ชื่อผู้ตรวจใน approved_by และวันเวลาอนุมัติใน approved_at"],
  ["7. ตรวจชีต Conflicts ทั้ง 4 ประเด็น ให้ issue/source/value/action ครบ และอนุมัติแนวทางหรือระบุข้อความแก้ไข"],
  ["8. Development gate จะเป็น READY เมื่อ identity, source_verified, English-only text, translation style, review/approval metadata และ Conflicts ครบและ approved ทั้งหมด"],
  ["9. คีย์ภายในและ schema งานวิจัยยังคงภาษาอังกฤษ และไม่ต้องแปล"],
  ["10. รอบนี้ไม่มีการแก้สูตรคำนวณ ไม่มีการเปลี่ยนโมเดล และไม่มีการ train ML"],
];
instructions.getRange("A3:F12").format = {
  fill: paleBlue,
  wrapText: true,
  verticalAlignment: "center",
  borders: { preset: "all", style: "thin", color: "#B4C7E7" },
};
instructions.getRange("A3:F12").format.rowHeight = 46;
instructions.getRange("A7:F7").format.rowHeight = 60;
instructions.getRange("A9:F10").format.rowHeight = 60;
instructions.getRange("A:F").format.columnWidth = 19;

await fs.mkdir(path.dirname(outputPath), { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

const checks = await workbook.inspect({
  kind: "table",
  range: "Coverage!A1:B27",
  include: "values,formulas",
  tableMaxRows: 30,
  tableMaxCols: 4,
});
console.log(checks.ndjson);
const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "final formula error scan",
});
console.log(errors.ndjson);

const previewRanges = [
  ["Translation Review", "A1:S22"],
  ["Master Catalog", "A1:R22"],
  ["Source Register", `A1:H${sourceRows.length + 1}`],
  ["Conflicts", "A1:I5"],
  ["Gate Audit", "A1:E22"],
  ["Coverage", "A1:B27"],
  ["Instructions", "A1:F12"],
];
for (const [sheetName, range] of previewRanges) {
  const preview = await workbook.render({
    sheetName,
    range,
    scale: 1.2,
    format: "png",
  });
  const bytes = new Uint8Array(await preview.arrayBuffer());
  await fs.writeFile(
    path.join(previewDir, `${sheetName.replaceAll(" ", "_")}.png`),
    bytes,
  );
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
const savedBlob = await FileBlob.load(outputPath);
const savedWorkbook = await SpreadsheetFile.importXlsx(savedBlob);
const savedCoverage = await savedWorkbook.inspect({
  kind: "table",
  range: "Coverage!A1:B27",
  include: "values,formulas",
  tableMaxRows: 30,
  tableMaxCols: 4,
});
console.log(savedCoverage.ndjson);
const savedErrors = await savedWorkbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "saved workbook formula error scan",
});
console.log(savedErrors.ndjson);
console.log(`workbook=${outputPath}`);
