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
const workbook = await Workbook.fromCSV(translationCsv, {
  sheetName: "Translation Review",
});
const review = workbook.worksheets.getItem("Translation Review");
styleDataSheet(review, "A1:S176", "TranslationReviewTable");
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
review.getRange("Q:Q").format.columnWidth = 13;
review.getRange("R:R").format.columnWidth = 34;
review.getRange("S:S").format.columnWidth = 12;
review.getRange("N2:N176").dataValidation = {
  rule: {
    type: "list",
    values: ["pending", "needs_revision", "rejected", "approved"],
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
await workbook.fromCSV(conflictCsv, { sheetName: "Conflicts" });
const conflicts = workbook.worksheets.getItem("Conflicts");
styleDataSheet(conflicts, "A1:H5", "ConflictsTable");
conflicts.getRange("A2:H5").format.rowHeight = 72;
conflicts.getRange("C2:H5").format.wrapText = true;
conflicts.getRange("A:B").format.columnWidth = 28;
conflicts.getRange("C:C").format.columnWidth = 31;
conflicts.getRange("D:E").format.columnWidth = 38;
conflicts.getRange("F:F").format.columnWidth = 64;
conflicts.getRange("G:G").format.columnWidth = 54;
conflicts.getRange("H:H").format.columnWidth = 18;
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
coverage.getRange("A3:B10").values = [
  ["Metric", "Value"],
  ["Total review rows", null],
  ["Approved", null],
  ["Pending", null],
  ["Needs revision", null],
  ["Rejected", null],
  ["Approval coverage", null],
  ["Unresolved source conflicts", null],
];
styleHeader(coverage.getRange("A3:B3"));
coverage.getRange("B4:B10").formulas = [
  ["=COUNTA('Translation Review'!A2:A1000)"],
  ["=COUNTIF('Translation Review'!N2:N1000,\"approved\")"],
  ["=COUNTIF('Translation Review'!N2:N1000,\"pending\")"],
  ["=COUNTIF('Translation Review'!N2:N1000,\"needs_revision\")"],
  ["=COUNTIF('Translation Review'!N2:N1000,\"rejected\")"],
  ["=IF(B4=0,0,B5/B4)"],
  [
    "=COUNTIFS('Conflicts'!A2:A100,\"<>\",'Conflicts'!H2:H100,\"<>approved\")",
  ],
];
coverage.getRange("B9").format.numberFormat = "0.00%";
coverage.getRange("A12:B12").values = [["Development gate", null]];
coverage.getRange("B12").formulas = [
  ['=IF(AND(B9=100%,B6=0,B7=0,B8=0,B10=0),"READY","BLOCKED")'],
];
coverage.getRange("A12:B12").format = {
  fill: gray,
  font: { bold: true },
  borders: { preset: "outside", style: "medium", color: "#7F8C8D" },
};
coverage.getRange("B12").conditionalFormats.add("containsText", {
  text: "READY",
  format: { fill: green, font: { color: "#274E13", bold: true } },
});
coverage.getRange("B12").conditionalFormats.add("containsText", {
  text: "BLOCKED",
  format: { fill: red, font: { color: "#990000", bold: true } },
});
coverage.getRange("A:A").format.columnWidth = 35;
coverage.getRange("B:B").format.columnWidth = 20;
coverage.getRange("A3:B12").format.rowHeight = 26;
coverage.getRange("A4:B10").format.borders = {
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
  ["2. ตรวจว่าภาษาอังกฤษให้ความหมายตรงกัน อ่านเข้าใจง่าย และไม่เพิ่มคำแนะนำใหม่"],
  ["3. ตรวจตัวเลข ช่วงตัวเลข หน่วย เวลา ความเร่งด่วน และคำปฏิเสธ เช่น ห้าม/ไม่เกิน/ทันที"],
  ["4. หากต้องแก้ ให้แก้ english_draft ใส่ review_comment และเลือก needs_revision"],
  ["5. เมื่อข้อความถูกต้อง ให้ตั้ง meaning_review เป็น pass และ approval_status เป็น approved"],
  ["6. ใส่ชื่อผู้ตรวจใน approved_by และวันเวลาอนุมัติใน approved_at"],
  ["7. ตรวจชีต Conflicts ทั้ง 4 ประเด็น และอนุมัติแนวทางหรือระบุข้อความแก้ไข"],
  ["8. ระบบจะยังไม่เริ่มแก้โค้ดแอปจน Coverage เป็น 100% และ Development gate เป็น READY"],
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
instructions.getRange("A:F").format.columnWidth = 19;

await fs.mkdir(path.dirname(outputPath), { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

const checks = await workbook.inspect({
  kind: "table",
  range: "Coverage!A1:B12",
  include: "values,formulas",
  tableMaxRows: 20,
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
  ["Source Register", `A1:H${sourceRows.length + 1}`],
  ["Conflicts", "A1:H5"],
  ["Coverage", "A1:B12"],
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
  range: "Coverage!A1:B12",
  include: "values,formulas",
  tableMaxRows: 20,
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
