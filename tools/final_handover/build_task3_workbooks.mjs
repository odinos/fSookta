#!/usr/bin/env node
// Build and visually render Task 3 XLSX artifacts with @oai/artifact-tool.

import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";
import JSZip from "jszip";

const VERSION = "1.3.11+28";
const COMMIT = "bf8867a2083357cb9d60915bf6c2233801f923d8";
const STAGING = "/private/tmp/fsookta-final-handover";
const artifactsDir = path.join(STAGING, "artifacts");
const renderDir = path.join(STAGING, "renders", "task3", "xlsx");
const dependencyPath = path.join(STAGING, "working", "task3", "dependencies.json");
const ZIP_DATE = new Date("2026-08-23T00:00:00Z");

const colors = {
  navy: "#17365D", blue: "#D9EAF7", pale: "#F4F7FA", white: "#FFFFFF",
  ink: "#1F2937", gray: "#6B7280", amber: "#FFF2CC", green: "#E2F0D9", red: "#FCE8E6",
  line: "#CBD5E1",
};

function titleBand(sheet, title, subtitle, cols) {
  sheet.mergeCells(`A1:${cols}1`);
  sheet.getRange("A1").values = [[title]];
  sheet.getRange(`A1:${cols}1`).format = {
    fill: colors.navy,
    font: { name: "Arial", size: 18, bold: true, color: colors.white },
    verticalAlignment: "center",
  };
  sheet.getRange(`A1:${cols}1`).format.rowHeight = 30;
  sheet.mergeCells(`A2:${cols}2`);
  sheet.getRange("A2").values = [[subtitle]];
  sheet.getRange(`A2:${cols}2`).format = {
    fill: colors.pale,
    font: { name: "Arial", size: 10, color: colors.gray },
    verticalAlignment: "center",
  };
  sheet.getRange(`A2:${cols}2`).format.rowHeight = 24;
}

function styleHeader(range) {
  range.format = {
    fill: colors.blue,
    font: { name: "Arial", size: 10, bold: true, color: colors.ink },
    wrapText: true,
    verticalAlignment: "center",
    borders: { preset: "outside", style: "thin", color: colors.line },
  };
  range.format.rowHeight = 36;
}

function styleBody(range) {
  range.format = {
    font: { name: "Arial", size: 9, color: colors.ink },
    wrapText: true,
    verticalAlignment: "top",
    borders: {
      insideHorizontal: { style: "thin", color: colors.line },
      bottom: { style: "thin", color: colors.line },
    },
  };
}

async function renderSheets(workbook, stem, sheets) {
  const outputs = [];
  for (const sheetName of sheets) {
    const preview = await workbook.render({ sheetName, autoCrop: "all", scale: 1.35, format: "png" });
    const safe = sheetName.replaceAll(/[^A-Za-z0-9]+/g, "_");
    const output = path.join(renderDir, `${stem}__${safe}.png`);
    await fs.writeFile(output, new Uint8Array(await preview.arrayBuffer()));
    outputs.push(output);
  }
  return outputs;
}

function parseNdjson(ndjson) {
  const records = ndjson.split(/\r?\n/).filter((line) => line.trim()).map((line) => JSON.parse(line));
  if (records.length === 0) throw new Error("artifact-tool inspection output is empty");
  return records;
}

export function assertFormulaErrorScanClean(ndjson) {
  const records = parseNdjson(ndjson);
  const cleanNotices = records.filter((record) => record.kind === "notice" && /matched 0 entries/i.test(record.message ?? ""));
  const matches = records.filter((record) => !(record.kind === "notice" && /matched 0 entries/i.test(record.message ?? "")));
  if (cleanNotices.length !== 1 || matches.length !== 0) {
    throw new Error(`Formula error scan matched cells or returned an ambiguous result: ${JSON.stringify(records)}`);
  }
}

export function assertInspectionMatches(ndjson, expected) {
  const records = parseNdjson(ndjson);
  const table = records.find((record) => record.kind === "table");
  if (!table) throw new Error(`Expected artifact-tool table inspection is missing: ${expected.sheet}!${expected.address}`);
  if (table.sheet !== expected.sheet || table.address !== expected.address) {
    throw new Error(`Inspection range mismatch: expected ${expected.sheet}!${expected.address}, got ${table.sheet}!${table.address}`);
  }
  if (JSON.stringify(table.values) !== JSON.stringify(expected.values)) {
    throw new Error(`Inspection value mismatch for ${expected.sheet}!${expected.address}`);
  }
  return table;
}

function splitRange(reference) {
  const separator = reference.indexOf("!");
  if (separator < 1) throw new Error(`Invalid sheet range: ${reference}`);
  return [reference.slice(0, separator), reference.slice(separator + 1)];
}

function assertMatrix(actual, expected, label) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${label} mismatch: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

async function inspectAndScan(workbook, workbookName, checks) {
  const results = [];
  for (const check of checks) {
    const inspected = await workbook.inspect({
      kind: "table",
      range: check.range,
      include: "values,formulas",
      tableMaxRows: check.rows ?? 20,
      tableMaxCols: check.cols ?? 12,
      maxChars: 12000,
    });
    const [sheetName, address] = splitRange(check.range);
    const table = assertInspectionMatches(inspected.ndjson, { sheet: sheetName, address, values: check.expectedValues });
    const formulaChecks = [];
    for (const formulaCheck of check.formulaChecks ?? []) {
      const [formulaSheetName, formulaAddress] = splitRange(formulaCheck.range);
      const range = workbook.worksheets.getItem(formulaSheetName).getRange(formulaAddress);
      const inspectedFormulas = range.formulas;
      const inspectedValues = range.values;
      assertMatrix(inspectedFormulas, formulaCheck.expectedFormulas, `Expected formulas for ${formulaCheck.range}`);
      assertMatrix(inspectedValues, formulaCheck.expectedValues, `Expected cached/calculated values for ${formulaCheck.range}`);
      formulaChecks.push({
        range: formulaCheck.range,
        expected_formulas: formulaCheck.expectedFormulas,
        inspected_formulas: inspectedFormulas,
        expected_values: formulaCheck.expectedValues,
        inspected_values: inspectedValues,
        status: "passed",
      });
    }
    results.push({
      range: check.range,
      ndjson: inspected.ndjson,
      expected_values: check.expectedValues,
      inspected_values: table.values,
      formula_checks: formulaChecks,
      status: "passed",
    });
  }
  const errors = await workbook.inspect({
    kind: "match",
    searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
    options: { useRegex: true, maxResults: 300 },
    summary: "final formula error scan",
    maxChars: 12000,
  });
  assertFormulaErrorScanClean(errors.ndjson);
  const contractChecks = results.flatMap((result) => [
    {
      range: result.range,
      expected_values: result.expected_values,
      inspected_values: result.inspected_values,
      expected_formulas: [],
      inspected_formulas: [],
      status: "passed",
    },
    ...result.formula_checks,
  ]);
  const output = {
    workbook: workbookName,
    inspections: results,
    formula_error_scan: errors.ndjson,
    inspection_contract: { status: "passed", formula_error_matches: 0, checks: contractChecks },
  };
  await fs.writeFile(path.join(renderDir, `${workbookName}__inspection.json`), JSON.stringify(output, null, 2));
  return output;
}

async function applyPrintSettings(output, firstSheetName, paperSize) {
  const zip = await JSZip.loadAsync(await fs.readFile(output));
  const worksheetNames = Object.keys(zip.files).filter((name) => /^xl\/worksheets\/sheet\d+\.xml$/.test(name));
  for (const name of worksheetNames) {
    let xml = await zip.file(name).async("string");
    const prefix = xml.match(/<([A-Za-z0-9_]+:)?worksheet\b/)?.[1] ?? "";
    const tag = (local) => `${prefix}${local}`;
    const sheetPr = tag("sheetPr");
    if (new RegExp(`<${sheetPr}\\b[^>]*\\/>`).test(xml)) {
      xml = xml.replace(new RegExp(`<${sheetPr}\\b([^>]*)\\/>`), `<${sheetPr}$1><${tag("pageSetUpPr")} fitToPage="1"/></${sheetPr}>`);
    } else if (new RegExp(`<${sheetPr}\\b`).test(xml)) {
      xml = xml.replace(new RegExp(`</${sheetPr}>`), `<${tag("pageSetUpPr")} fitToPage="1"/></${sheetPr}>`);
    } else {
      xml = xml.replace(new RegExp(`(<${tag("worksheet")}\\b[^>]*>)`), `$1<${sheetPr}><${tag("pageSetUpPr")} fitToPage="1"/></${sheetPr}>`);
    }
    xml = xml.replace(new RegExp(`<${tag("printOptions")}\\b[^>]*\\/>`, "g"), "");
    xml = xml.replace(new RegExp(`<${tag("pageMargins")}\\b[^>]*\\/>`, "g"), "");
    xml = xml.replace(new RegExp(`<${tag("pageSetup")}\\b[^>]*\\/>`, "g"), "");
    xml = xml.replace(
      `</${tag("worksheet")}>`,
      `<${tag("printOptions")} horizontalCentered="1"/><${tag("pageMargins")} left="0.25" right="0.25" top="0.5" bottom="0.5" header="0.2" footer="0.2"/><${tag("pageSetup")} paperSize="${paperSize}" orientation="landscape" fitToWidth="1" fitToHeight="0" pageOrder="downThenOver" horizontalDpi="300" verticalDpi="300"/></${tag("worksheet")}>`,
    );
    zip.file(name, xml, { date: ZIP_DATE });
  }
  const workbookXmlName = "xl/workbook.xml";
  let workbookXml = await zip.file(workbookXmlName).async("string");
  const workbookPrefix = workbookXml.match(/<([A-Za-z0-9_]+:)?workbook\b/)?.[1] ?? "";
  const escapedSheetName = firstSheetName.replaceAll("&", "&amp;").replaceAll("'", "&apos;");
  workbookXml = workbookXml.replace(
    `</${workbookPrefix}workbook>`,
    `<${workbookPrefix}definedNames><${workbookPrefix}definedName name="_xlnm.Print_Titles" localSheetId="0">'${escapedSheetName}'!$4:$4</${workbookPrefix}definedName></${workbookPrefix}definedNames></${workbookPrefix}workbook>`,
  );
  zip.file(workbookXmlName, workbookXml, { date: ZIP_DATE });
  for (const entry of Object.values(zip.files)) entry.date = ZIP_DATE;
  await fs.writeFile(output, await zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE", compressionOptions: { level: 9 } }));
}

async function buildLicenseRegister(records) {
  const workbook = Workbook.create();
  const register = workbook.worksheets.add("License Register");
  const summary = workbook.worksheets.add("Review Summary");
  const sources = workbook.worksheets.add("Sources & Notes");
  register.showGridLines = false; summary.showGridLines = false; sources.showGridLines = false;

  titleBand(register, "SookTa Third-Party License Register", `Resolved baseline ${VERSION} | Git ${COMMIT} | License conclusions remain subject to owner/legal review`, "L");
  const headers = ["Dependency", "Resolved Version", "Purpose", "Source URL", "License Identifier", "License Text Source", "Platform", "Runtime / Development", "Dependency Scope", "Restriction Notes", "Evidence Source", "Review Status"];
  register.getRange("A4:L4").values = [headers]; styleHeader(register.getRange("A4:L4"));
  const rows = records.map((r) => [r.dependency, r.resolved_version, r.purpose, r.source_url, r.license_identifier, r.license_text_source, r.platform, r.classification, r.dependency_scope, r.restriction_notes, r.evidence_source, null]);
  const endRow = rows.length + 4;
  register.getRange(`A5:L${endRow}`).values = rows;
  register.getRange("L5").formulas = [["=IF(E5=\"Human verification required\",\"Pending legal review\",\"Recorded\")"]];
  register.getRange(`L5:L${endRow}`).fillDown();
  styleBody(register.getRange(`A5:L${endRow}`));
  register.getRange(`D5:F${endRow}`).format.font = { name: "Arial", size: 8, color: "#1155CC" };
  register.getRange(`L5:L${endRow}`).format.fill = colors.amber;
  register.freezePanes.freezeRows(4);
  const widths = [24, 16, 31, 34, 22, 36, 18, 18, 20, 34, 31, 22];
  widths.forEach((width, i) => register.getRangeByIndexes(0, i, endRow, 1).format.columnWidth = width);
  register.getRange(`A5:L${endRow}`).format.rowHeight = 42;
  register.tables.add(`A4:L${endRow}`, true, "ThirdPartyLicenseRegister").style = "TableStyleMedium2";

  titleBand(summary, "License Review Summary", "Formula-driven counts from the License Register; resolve pending rows before distribution", "D");
  summary.getRange("A4:B8").values = [
    ["Metric", "Count"], ["Total dependency records", null], ["Pending legal review", null], ["Recorded license identifier", null], ["Runtime-classified records", null],
  ];
  summary.getRange("B5").formulas = [[`=COUNTA('License Register'!A5:A${endRow})`]];
  summary.getRange("B6").formulas = [[`=COUNTIF('License Register'!L5:L${endRow},\"Pending legal review\")`]];
  summary.getRange("B7").formulas = [[`=COUNTIF('License Register'!L5:L${endRow},\"Recorded\")`]];
  summary.getRange("B8").formulas = [[`=COUNTIF('License Register'!H5:H${endRow},\"Runtime\")`]];
  styleHeader(summary.getRange("A4:B4")); styleBody(summary.getRange("A5:B8"));
  summary.getRange("A10:D15").values = [
    ["Review gate", "Owner", "Required evidence", "Status"],
    ["Resolve license identifiers", "Owner / legal reviewer", "Package/pod license text and SPDX-compatible identifier", "Pending Owner Action"],
    ["Confirm notice obligations", "Release owner", "NOTICE/attribution inventory included with distribution", "Pending Owner Action"],
    ["Review model terms", "Researcher / owner", "MoveNet, TensorFlow Lite, XGBoost/ONNX model and dataset provenance", "Pending Owner Action"],
    ["Approve distribution", "Authorized owner", "Signed/recorded approval after restrictions are resolved", "Pending Owner Action"],
    ["Archive review evidence", "Handover administrator", "Dated review record and reviewer identity", "Pending Owner Action"],
  ];
  styleHeader(summary.getRange("A10:D10")); styleBody(summary.getRange("A11:D15"));
  summary.getRange("A1:D15").format.columnWidth = 22;
  summary.getRange("A:A").format.columnWidth = 28; summary.getRange("C:C").format.columnWidth = 48; summary.getRange("D:D").format.columnWidth = 25;
  summary.getRange("A11:D15").format.rowHeight = 38;

  titleBand(sources, "Sources and Review Notes", "Technical inventory is complete; legal/license determinations are deliberately not inferred", "C");
  sources.getRange("A4:C10").values = [
    ["Source", "Baseline", "Use / caveat"],
    ["pubspec.lock", COMMIT, "Resolved Dart/Flutter package names, versions, dependency scope, and hosted source."],
    ["ios/Podfile.lock", COMMIT, "Resolved CocoaPods names and versions. Podspec/license text must be reviewed separately."],
    ["android/settings.gradle", COMMIT, "Resolved Android build-plugin versions."],
    ["pubspec.yaml", COMMIT, "Direct dependency intent and local onnxruntime override."],
    ["third_party/onnxruntime_16kb/LICENSE", COMMIT, "Tracked MIT license for the local wrapper override; retain the notice."],
    ["Human action", "Open", "Replace every Human verification required identifier only after inspecting authoritative license text."],
  ];
  styleHeader(sources.getRange("A4:C4")); styleBody(sources.getRange("A5:C10"));
  sources.getRange("A:A").format.columnWidth = 38; sources.getRange("B:B").format.columnWidth = 46; sources.getRange("C:C").format.columnWidth = 70;
  sources.getRange("A5:C10").format.rowHeight = 42;

  const output = path.join(artifactsDir, "02_Third_Party_License_Register.xlsx");
  const pendingCount = records.filter((record) => record.license_identifier === "Human verification required").length;
  const recordedCount = records.length - pendingCount;
  const runtimeCount = records.filter((record) => record.classification === "Runtime").length;
  const statusFormulas = records.map((_, index) => [`=IF(E${index + 5}="Human verification required","Pending legal review","Recorded")`]);
  const statusValues = records.map((record) => [record.license_identifier === "Human verification required" ? "Pending legal review" : "Recorded"]);
  const summaryValues = [
    ["Metric", "Count"],
    ["Total dependency records", records.length],
    ["Pending legal review", pendingCount],
    ["Recorded license identifier", recordedCount],
    ["Runtime-classified records", runtimeCount],
  ];
  const previewFiles = await renderSheets(workbook, "02_Third_Party_License_Register", ["License Register", "Review Summary", "Sources & Notes"]);
  const inspection = await inspectAndScan(workbook, "02_Third_Party_License_Register", [
    {
      range: "Review Summary!A4:B8",
      rows: 10,
      cols: 4,
      expectedValues: summaryValues,
      formulaChecks: [{
        range: "Review Summary!B5:B8",
        expectedFormulas: [
          [`=COUNTA('License Register'!A5:A${endRow})`],
          [`=COUNTIF('License Register'!L5:L${endRow},"Pending legal review")`],
          [`=COUNTIF('License Register'!L5:L${endRow},"Recorded")`],
          [`=COUNTIF('License Register'!H5:H${endRow},"Runtime")`],
        ],
        expectedValues: [[records.length], [pendingCount], [recordedCount], [runtimeCount]],
      }],
    },
    {
      range: `License Register!A4:L${Math.min(endRow, 12)}`,
      rows: 12,
      cols: 12,
      expectedValues: [headers, ...rows.slice(0, 8).map((row, index) => [...row.slice(0, 11), statusValues[index][0]])],
      formulaChecks: [{
        range: `License Register!L5:L${endRow}`,
        expectedFormulas: statusFormulas,
        expectedValues: statusValues,
      }],
    },
  ]);
  const blob = await SpreadsheetFile.exportXlsx(workbook); await blob.save(output); await applyPrintSettings(output, "License Register", 8);
  return { output, sheets: 3, records: records.length, previewFiles, inspection };
}

async function buildAccessChecklist() {
  const workbook = Workbook.create();
  const checklist = workbook.worksheets.add("Access Checklist");
  const summary = workbook.worksheets.add("Status Summary");
  const notes = workbook.worksheets.add("Secure Handover Notes");
  checklist.showGridLines = false; summary.showGridLines = false; notes.showGridLines = false;

  const items = [
    ["GitHub repository", "Owner/Admin role and repository transfer or collaborator evidence", "Repository owner / administrator", "Invitation/role screenshot or audit event; recipient acceptance", "Pending Owner Action", "No token or password"],
    ["GitHub branch/tag protection", `Protect ${COMMIT}; approve/create proposed tag sookta-v${VERSION}`, "Repository owner", "Remote ref, annotated tag object, protection settings", "Pending Owner Action", "Full history remains authoritative"],
    ["Firebase project", "Project Owner/Editor access; Analytics/Crashlytics configuration", "Firebase project owner", "Membership/role evidence and project identifier", "Pending Owner Action", "Do not include service-account keys"],
    ["Apple Developer", "Team role, certificates, identifiers, devices, provisioning profiles", "Apple Developer Account Holder", "Accepted invitation and role; signing custody record", "Pending Owner Action", "Distribution signing ownership unverified"],
    ["App Store Connect", "App Manager/Admin access for com.kdev.sookta", "Account Holder/Admin", "Accepted invitation, app access, agreement/tax/banking owner confirmation", "Pending Owner Action", "No production delivery claim"],
    ["Google Play Console", "Admin/Release Manager access and app ownership", "Play Console account owner", "Accepted invitation, app role, release-track access", "Pending Owner Action", "Upload-key ownership unverified"],
    ["Android upload key", "Custody, alias, recovery/Play App Signing relationship", "Signing asset owner", "Secure-channel receipt acknowledgment and signer fingerprint", "Pending Owner Action", "Never place key/password in workbook"],
    ["iOS distribution signing", "Certificate/private-key custody and provisioning-profile control", "Apple Account Holder/signing owner", "Secure-channel receipt acknowledgment and certificate metadata", "Pending Owner Action", "Never place private key/profile in workbook"],
    ["Analytics / logging", "Telemetry enablement decision, Firebase access, retention/export settings", "Researcher and Firebase owner", "Written decision and role evidence", "Pending Owner Action", "Telemetry disabled by default in baseline"],
    ["Privacy / store declarations", "App Privacy, Data Safety, PrivacyInfo.xcprivacy, consent alignment", "Release owner / researcher", "Approved declarations matching final behavior", "Pending Owner Action", "Review again if telemetry changes"],
    ["Billing / subscriptions", "Cloud/store billing owner, recurring costs, renewal dates", "Institution/account owner", "Billing role and non-secret account record", "Pending Owner Action", "No billing evidence available"],
    ["Domain / SSL / external API", "Confirm whether any production dependency exists; record N/A with rationale if none", "Technical owner", "Inventory/attestation or exception approval", "Pending Owner Action", "Primary assessment is offline-first"],
    ["Secure secret handover", "Inventory credential categories and recovery controls only", "Security owner", "Dated secure-channel acknowledgment; no values", "Pending Owner Action", "Secrets intentionally excluded"],
    ["No personal-account dependency", "Confirm no production service remains tied only to a developer personal account", "Authorized owner", "Signed attestation or approved exception", "Pending Owner Action", "Cannot infer from source"],
  ];
  titleBand(checklist, "SookTa Repository and Service Access Checklist", `Baseline ${VERSION} | No secret values | Every open field requires owner evidence`, "F");
  checklist.getRange("A4:F4").values = [["System / Asset", "Required Access / Transfer", "Owner", "Transfer Evidence", "Status", "Security / Scope Note"]];
  styleHeader(checklist.getRange("A4:F4"));
  const endRow = items.length + 4;
  checklist.getRange(`A5:F${endRow}`).values = items; styleBody(checklist.getRange(`A5:F${endRow}`));
  checklist.getRange(`E5:E${endRow}`).dataValidation = { rule: { type: "list", values: ["Pending Owner Action", "Pending Researcher Evidence", "Exception Approval Required", "Completed - Evidence Attached", "N/A - Approved Rationale"] } };
  checklist.getRange(`E5:E${endRow}`).format.fill = colors.amber;
  [25, 44, 28, 46, 25, 39].forEach((width, i) => checklist.getRangeByIndexes(0, i, endRow, 1).format.columnWidth = width);
  checklist.getRange(`A5:F${endRow}`).format.rowHeight = 54;
  checklist.freezePanes.freezeRows(4);
  checklist.tables.add(`A4:F${endRow}`, true, "RepositoryAccessChecklist").style = "TableStyleMedium2";

  titleBand(summary, "Access Status Summary", "Formula-driven rollup from the Access Checklist", "D");
  summary.getRange("A4:B9").values = [
    ["Status", "Count"], ["Total checklist items", null], ["Pending Owner Action", null], ["Pending Researcher Evidence", null], ["Exception Approval Required", null], ["Completed - Evidence Attached", null],
  ];
  summary.getRange("B5").formulas = [[`=COUNTA('Access Checklist'!A5:A${endRow})`]];
  summary.getRange("B6").formulas = [[`=COUNTIF('Access Checklist'!E5:E${endRow},\"Pending Owner Action\")`]];
  summary.getRange("B7").formulas = [[`=COUNTIF('Access Checklist'!E5:E${endRow},\"Pending Researcher Evidence\")`]];
  summary.getRange("B8").formulas = [[`=COUNTIF('Access Checklist'!E5:E${endRow},\"Exception Approval Required\")`]];
  summary.getRange("B9").formulas = [[`=COUNTIF('Access Checklist'!E5:E${endRow},\"Completed - Evidence Attached\")`]];
  styleHeader(summary.getRange("A4:B4")); styleBody(summary.getRange("A5:B9"));
  summary.getRange("A11:D16").values = [
    ["Release gate", "Current classification", "Completion criterion", "Human action"],
    ["Android", "Technical AAB passed; non-production", "Upload signing ownership and Play Console access evidenced", "Owner provides secure signing/access evidence"],
    ["iOS", "Technical IPA passed; non-production", "Distribution signing and App Store Connect access evidenced", "Account Holder provides access/signing evidence"],
    ["Repository", "Full history present locally", "Researcher accepts Owner/Admin role and final tag is approved", "Repository administrator records transfer"],
    ["Telemetry", "Opt-in; disabled by default", "Owner/researcher decision matches privacy/store declarations", "Record dated enable/disable decision"],
    ["Acceptance", "Not signed", "Authorized parties sign final acceptance and rights statement", "Collect signatures without backdating"],
  ];
  styleHeader(summary.getRange("A11:D11")); styleBody(summary.getRange("A12:D16"));
  summary.getRange("A:A").format.columnWidth = 28; summary.getRange("B:B").format.columnWidth = 35; summary.getRange("C:C").format.columnWidth = 52; summary.getRange("D:D").format.columnWidth = 45;
  summary.getRange("A12:D16").format.rowHeight = 48;

  titleBand(notes, "Secure Handover Notes", "Use this workbook to record status and evidence references only - never credentials or signing material", "C");
  notes.getRange("A4:C11").values = [
    ["Rule", "Allowed record", "Never record here"],
    ["Credentials", "Credential category, custodian, delivery date, secure-channel receipt ID", "Passwords, API keys, recovery codes, private keys"],
    ["Signing", "Certificate/keystore owner, non-secret fingerprint, expiry, receipt acknowledgment", "Keystore/private-key bytes, passwords, profiles containing sensitive data"],
    ["Access", "Platform role, invitation date, accepted date, evidence filename/URL", "Session cookies, OAuth tokens, personal recovery details"],
    ["Status", "Use only the approved status list", "Unsupported claims such as transferred/verified without evidence"],
    ["Exceptions", "Approver, rationale, approval date, review date", "Silent N/A or omitted control"],
    ["Production", "Technical build evidence plus separate signing/store evidence", "Calling technical builds production-ready"],
    ["Retention", "Store evidence in the institution-approved secure location", "Participant data or research media in this handover workbook"],
  ];
  styleHeader(notes.getRange("A4:C4")); styleBody(notes.getRange("A5:C11"));
  notes.getRange("A:A").format.columnWidth = 25; notes.getRange("B:B").format.columnWidth = 62; notes.getRange("C:C").format.columnWidth = 62;
  notes.getRange("A5:C11").format.rowHeight = 46;

  const output = path.join(artifactsDir, "02_Repository_Access_Checklist.xlsx");
  const previewFiles = await renderSheets(workbook, "02_Repository_Access_Checklist", ["Access Checklist", "Status Summary", "Secure Handover Notes"]);
  const inspection = await inspectAndScan(workbook, "02_Repository_Access_Checklist", [
    {
      range: "Status Summary!A4:B9",
      rows: 10,
      cols: 4,
      expectedValues: [
        ["Status", "Count"],
        ["Total checklist items", items.length],
        ["Pending Owner Action", items.length],
        ["Pending Researcher Evidence", 0],
        ["Exception Approval Required", 0],
        ["Completed - Evidence Attached", 0],
      ],
      formulaChecks: [{
        range: "Status Summary!B5:B9",
        expectedFormulas: [
          [`=COUNTA('Access Checklist'!A5:A${endRow})`],
          [`=COUNTIF('Access Checklist'!E5:E${endRow},"Pending Owner Action")`],
          [`=COUNTIF('Access Checklist'!E5:E${endRow},"Pending Researcher Evidence")`],
          [`=COUNTIF('Access Checklist'!E5:E${endRow},"Exception Approval Required")`],
          [`=COUNTIF('Access Checklist'!E5:E${endRow},"Completed - Evidence Attached")`],
        ],
        expectedValues: [[items.length], [items.length], [0], [0], [0]],
      }],
    },
    {
      range: `Access Checklist!A4:F${Math.min(endRow, 10)}`,
      rows: 10,
      cols: 6,
      expectedValues: [
        ["System / Asset", "Required Access / Transfer", "Owner", "Transfer Evidence", "Status", "Security / Scope Note"],
        ...items.slice(0, 6),
      ],
    },
  ]);
  const blob = await SpreadsheetFile.exportXlsx(workbook); await blob.save(output); await applyPrintSettings(output, "Access Checklist", 9);
  return { output, sheets: 3, items: items.length, previewFiles, inspection };
}

async function main() {
  await fs.mkdir(artifactsDir, { recursive: true }); await fs.mkdir(renderDir, { recursive: true });
  const dependencies = JSON.parse(await fs.readFile(dependencyPath, "utf8"));
  const license = await buildLicenseRegister(dependencies.records);
  const access = await buildAccessChecklist();
  const summary = { schema_version: 1, baseline: { version: VERSION, commit: COMMIT }, license, access };
  await fs.writeFile(path.join(STAGING, "manifests", "task3_workbook_build_summary.json"), JSON.stringify(summary, null, 2));
  process.stdout.write(JSON.stringify(summary, null, 2) + "\n");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
