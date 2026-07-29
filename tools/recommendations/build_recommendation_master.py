#!/usr/bin/env python3
"""Build the auditable Thai recommendation master from approved local sources."""

from __future__ import annotations

import csv
import re
from pathlib import Path


MASTER_COLUMNS = [
    "recommendation_id",
    "selection_key",
    "display_order",
    "record_type",
    "category",
    "activity",
    "body_part",
    "risk_level",
    "trigger_condition",
    "thai_source_text",
    "source_id",
    "source_page",
    "source_section",
    "source_priority",
    "catalog_version",
    "record_status",
    "legacy_text_th",
    "legacy_text_en",
]

UI_COPY = [
    ("ui.recommendations.heading", "คำแนะนำตามกิจกรรมและความเสี่ยง"),
    (
        "ui.recommendations.instruction",
        "เริ่มจากข้อที่ทำได้จริงในงานนี้ แล้วติดตามคะแนนครั้งถัดไป",
    ),
    ("ui.category.posture", "ท่าทางที่ควรปรับ"),
    ("ui.category.risk_reduction", "วิธีลดความเสี่ยง"),
    ("ui.category.rest_rotation", "การพักหรือสลับงาน"),
    ("ui.category.workload_support", "อุปกรณ์ช่วยลดภาระงาน"),
    ("ui.recommendations.empty", "ไม่มีคำแนะนำเพิ่มเติม"),
    ("ui.recommendations.full", "คำแนะนำฉบับเต็ม"),
    ("report.selected_recommendations", "คำแนะนำที่เลือก"),
    (
        "system.unmapped_saved_recommendation",
        "ไม่สามารถจับคู่คำแนะนำเดิมกับรายการปัจจุบันได้",
    ),
]

SOURCE_TEXT_OVERRIDES = {
    "act_avoid_bend": "ลดการก้มโดยยกพื้นที่ทำงานให้สูงขึ้น",
    "act_harvest_empty_often": "ลดการก้มโดยปรับความสูงตะกร้า",
}

SOURCE_ACTION_OVERRIDES = {
    "act_transplant_ref_high": [
        "ปรับปรุงทันทีโดยยกแปลงเพาะชำให้สูงระดับเอว",
        "ใช้อุปกรณ์นั่งยองหรือเก้าอี้เตี้ย",
        "พักทุก 15-20 นาที",
    ],
}

SOURCE_LOCATORS = {
    "act_reduce_weight": ("body_map_recommendations", "7-8", "Manual handling"),
    "act_iso_keep_load_close": (
        "ilo_ergonomic_checkpoints_agriculture",
        "51",
        "Checkpoint 12",
    ),
    "act_iso_lift_height": ("app_recommendations_v3", "4", "ISO 11228-1 mapping"),
    "act_iso_reduce_frequency": (
        "body_map_recommendations",
        "4,8",
        "Reduce repeated lifting",
    ),
    "act_iso_improve_grip": (
        "ilo_ergonomic_checkpoints_agriculture",
        "79",
        "Checkpoint 25",
    ),
    "act_iso_plan_recovery": (
        "ilo_ergonomic_checkpoints_agriculture",
        "243",
        "Checkpoint 99",
    ),
    "act_use_cart_distance": ("body_map_recommendations", "3,8", "Cart distance"),
    "act_check_wheels": (
        "ilo_ergonomic_checkpoints_agriculture",
        "37",
        "Checkpoint 5",
    ),
    "act_use_legs": ("app_recommendations_v3", "1,3", "Lifting posture"),
    "act_iso_push_smooth": ("app_recommendations_v3", "5", "ISO 11228-2 mapping"),
    "act_iso_push_handle_height": (
        "ilo_ergonomic_checkpoints_agriculture",
        "63",
        "Checkpoint 17",
    ),
    "act_iso_reduce_push_distance": (
        "app_recommendations_v3",
        "5",
        "ISO 11228-2 distance principle",
    ),
    "act_iso_floor_level": (
        "ilo_ergonomic_checkpoints_agriculture",
        "29,31",
        "Checkpoints 1-2",
    ),
    "act_iso_push_not_pull": (
        "app_recommendations_v3",
        "5",
        "ISO 11228-2 posture principle",
    ),
    "act_reduce_load_tool": ("body_map_recommendations", "4,8", "Mechanical aids"),
    "act_avoid_bend": ("body_map_recommendations", "2-3", "Neck and trunk"),
    "act_avoid_twist": ("body_map_recommendations", "2-3", "Avoid twisting"),
    "act_adj_eye_level": ("body_map_recommendations", "1-2", "Neck"),
    "act_reduce_arm_raise": ("body_map_recommendations", "4-5", "Shoulder and arm"),
    "act_adj_wrist": ("body_map_recommendations", "5-6", "Wrist and hand"),
    "act_rest_stretch": (
        "ilo_ergonomic_checkpoints_agriculture",
        "243",
        "Checkpoint 99",
    ),
    "act_iso_job_rotation": (
        "ilo_ergonomic_checkpoints_agriculture",
        "229",
        "Checkpoint 92",
    ),
    "act_iso_neutral_reach": (
        "ilo_ergonomic_checkpoints_agriculture",
        "51,65",
        "Checkpoints 12 and 18",
    ),
    "act_iso_tool_handle_fit": (
        "ilo_ergonomic_checkpoints_agriculture",
        "79",
        "Checkpoint 25",
    ),
    "act_transplant_raise_bed": ("app_recommendations_v3", "1", "Transplanting"),
    "act_transplant_low_stool": ("app_recommendations_v3", "1", "Transplanting"),
    "act_extra_spray_strap": ("app_recommendations_v3", "2", "Pesticide spraying"),
    "act_extra_spray_switch": ("app_recommendations_v3", "2", "Pesticide spraying"),
    "act_spray_extension": ("app_recommendations_v3", "2", "Pesticide spraying"),
    "act_extra_prune_ladder": ("app_recommendations_v3", "2", "Pruning"),
    "act_extra_prune_tool": ("app_recommendations_v3", "2", "Pruning"),
    "act_harvest_empty_often": ("app_recommendations_v3", "2", "Harvesting"),
    "act_harvest_move_closer": ("body_map_recommendations", "4", "Reach distance"),
    "act_extra_fert_cart": ("app_recommendations_v3", "2", "Fertilizing"),
    "act_fert_split_load": ("app_recommendations_v3", "2", "Fertilizing"),
    "act_transport_two_person": ("body_map_recommendations", "8", "Manual handling"),
    "act_transport_clear_path": (
        "ilo_ergonomic_checkpoints_agriculture",
        "29",
        "Checkpoint 1",
    ),
}

BODY_PAGES = {
    "neck": {"medium": "1", "high": "2", "very_high": "2"},
    "trunk": {"medium": "3", "high": "3", "very_high": "3-4"},
    "arms": {"medium": "4", "high": "4", "very_high": "4-5"},
    "wrists": {"medium": "5", "high": "5-6", "very_high": "6"},
    "legs": {"medium": "6", "high": "6-7", "very_high": "7"},
    "manual": {"medium": "7", "high": "7-8", "very_high": "8"},
}

ACTIVITY_PAGES = {
    "transplant": ("transplanting", "1"),
    "fert": ("fertilizing", "2"),
    "pesticide": ("pesticide", "2"),
    "pruning": ("pruning", "2"),
    "harvest": ("harvesting", "2"),
    "transport": ("transport", "3"),
}


def _dart_maps(path: Path) -> tuple[dict[str, str], dict[str, str]]:
    text = path.read_text(encoding="utf-8")
    en_block, th_block = text.split("static const _th", maxsplit=1)
    en_block = en_block.split("static const _en", maxsplit=1)[1]
    pattern = re.compile(r"'([^']+)'\s*:\s*'([^']*)'", re.MULTILINE)
    en = dict(pattern.findall(en_block))
    th = dict(pattern.findall(th_block))
    return th, en


def _split_actions(text: str) -> list[str]:
    boundary_verbs = (
        "ใช้|ลด|หลีกเลี่ยง|ปรับ|พัก|สลับ|จัด|วาง|ถือ|ลุก|เปลี่ยน|หมุน|"
        "ช่วยกัน|หัน|จำกัด|แบ่ง|ยก|ตรวจสอบ|คลาย|ไม่ควร|ทำงาน|สังเกต|"
        "ถ้า|หาก|หยุด|ออกแรง"
    )
    normalized = re.sub(r";\s*|,\s*", " | ", text)
    normalized = re.sub(
        rf"\s+(?=(?:และ)?(?:{boundary_verbs}))",
        " | ",
        normalized,
    )
    actions = []
    for item in normalized.split("|"):
        action = re.sub(r"^และ", "", item.strip()).strip()
        if action:
            actions.append(action)
    return actions


def _context(key: str) -> tuple[str, str, str, str, str, str, str]:
    body_match = re.fullmatch(
        r"act_body_(neck|trunk|arms|wrists|legs|manual)_(medium|high|very_high)",
        key,
    )
    if body_match:
        body, risk = body_match.groups()
        return (
            "posture",
            "any",
            body,
            risk,
            "body_part_risk_matches",
            "body_map_recommendations",
            BODY_PAGES[body][risk],
        )
    if key.startswith("act_ref_weight_"):
        risk = key.removeprefix("act_ref_weight_")
        return (
            "workloadSupport",
            "any",
            "manual",
            risk,
            "overall_risk_matches_and_manual_handling",
            "app_recommendations_v3",
            "1",
        )
    for prefix, (activity, page) in ACTIVITY_PAGES.items():
        marker = f"act_{prefix}_ref_"
        if key.startswith(marker):
            risk = key.removeprefix(marker)
            return (
                "riskReduction",
                activity,
                "any",
                risk,
                "activity_and_overall_risk_match",
                "app_recommendations_v3",
                page,
            )
    source, page, _ = SOURCE_LOCATORS.get(
        key,
        ("current_app_recommendation_copy", "", "Legacy recommendation copy"),
    )
    category = (
        "restRotation"
        if key in {"act_rest_stretch", "act_iso_job_rotation", "act_iso_plan_recovery"}
        else "workloadSupport"
        if any(token in key for token in ("tool", "cart", "wheel", "ladder", "strap"))
        else "posture"
    )
    return category, "any", "any", "any", "selection_key_selected", source, page


def build_rows(strings_path: Path) -> list[dict[str, str]]:
    thai, english = _dart_maps(strings_path)
    rows: list[dict[str, str]] = []
    for key in sorted(item for item in thai if item.startswith("act_")):
        category, activity, body, risk, trigger, source, page = _context(key)
        source_text = SOURCE_TEXT_OVERRIDES.get(key, thai[key])
        section = SOURCE_LOCATORS.get(key, (source, page, key))[2]
        actions = SOURCE_ACTION_OVERRIDES.get(key, _split_actions(source_text))
        for order, action in enumerate(actions, start=1):
            rows.append(
                {
                    "recommendation_id": f"{key}.{order:02d}",
                    "selection_key": key,
                    "display_order": str(order),
                    "record_type": "recommendation",
                    "category": category,
                    "activity": activity,
                    "body_part": body,
                    "risk_level": risk,
                    "trigger_condition": trigger,
                    "thai_source_text": action,
                    "source_id": source,
                    "source_page": page,
                    "source_section": section,
                    "source_priority": (
                        "1"
                        if source == "body_map_recommendations"
                        else "2"
                        if source == "app_recommendations_v3"
                        else "3"
                        if source == "ilo_ergonomic_checkpoints_agriculture"
                        else "90"
                    ),
                    "catalog_version": "2026-07-29.1",
                    "record_status": "source_verified",
                    "legacy_text_th": thai[key] if order == 1 else "",
                    "legacy_text_en": english.get(key, "") if order == 1 else "",
                }
            )
    for order, (key, text) in enumerate(UI_COPY, start=1):
        record_type = "system_message" if key.startswith("system.") else "ui_copy"
        rows.append(
            {
                "recommendation_id": key,
                "selection_key": key,
                "display_order": "1",
                "record_type": record_type,
                "category": "interface",
                "activity": "any",
                "body_part": "any",
                "risk_level": "any",
                "trigger_condition": "feature_surface_visible",
                "thai_source_text": text,
                "source_id": "current_app_recommendation_copy",
                "source_page": "",
                "source_section": "Existing recommendation UI or migration message",
                "source_priority": "90",
                "catalog_version": "2026-07-29.1",
                "record_status": "source_verified",
                "legacy_text_th": "",
                "legacy_text_en": "",
            }
        )
    return rows


def write_master(rows: list[dict[str, str]], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=MASTER_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)


def write_reports(
    rows: list[dict[str, str]],
    strings_path: Path,
    reports_dir: Path,
) -> None:
    thai, english = _dart_maps(strings_path)
    reports_dir.mkdir(parents=True, exist_ok=True)
    by_key: dict[str, list[str]] = {}
    for row in rows:
        if row["record_type"] == "recommendation":
            by_key.setdefault(row["selection_key"], []).append(
                row["thai_source_text"]
            )
    comparison_path = reports_dir / "current_app_comparison.csv"
    with comparison_path.open("w", encoding="utf-8-sig", newline="") as stream:
        columns = [
            "selection_key",
            "current_th",
            "current_en",
            "source_th",
            "comparison_status",
            "impact_on_selection",
            "review_note",
        ]
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        for key in sorted(by_key):
            changed = key in SOURCE_TEXT_OVERRIDES
            writer.writerow(
                {
                    "selection_key": key,
                    "current_th": thai.get(key, ""),
                    "current_en": english.get(key, ""),
                    "source_th": " | ".join(by_key[key]),
                    "comparison_status": (
                        "source_revision_proposed"
                        if changed
                        else "source_aligned_summary"
                    ),
                    "impact_on_selection": "none_key_unchanged",
                    "review_note": (
                        "Replace unsupported or indirect legacy wording with the employer-provided source wording."
                        if changed
                        else "Verify final atomic split and English meaning during review."
                    ),
                }
            )
    conflicts_path = reports_dir / "conflicts_missing_sources.csv"
    conflict_columns = [
        "recommendation_id",
        "selection_key",
        "issue_type",
        "source_a",
        "source_b",
        "conflicting_value",
        "proposed_action",
        "approval_status",
    ]
    conflicts = [
        {
            "recommendation_id": "act_ref_weight_high.01",
            "selection_key": "act_ref_weight_high",
            "issue_type": "overlapping_weight_limits",
            "source_a": "body_map_recommendations:p8",
            "source_b": "app_recommendations_v3:p1-3",
            "conflicting_value": "Body Map กำหนดน้ำหนักตามลักษณะงาน เช่น 10/20/25 กก. แต่เอกสาร V3 กำหนดต่างกันตามอายุและเพศ",
            "proposed_action": "คงคำแนะนำแยกตามบริบท และเมื่อมีหลายเกณฑ์ให้แสดงค่าที่เข้มงวดกว่าซึ่งตรงกับบริบทของผู้ใช้",
            "approval_status": "pending",
        },
        {
            "recommendation_id": "act_avoid_bend.01",
            "selection_key": "act_avoid_bend",
            "issue_type": "unsupported_legacy_clause",
            "source_a": "current_app_recommendation_copy",
            "source_b": "body_map_recommendations:p2-3",
            "conflicting_value": "ข้อความเดิมกล่าวถึงเข็มขัดพยุงหลัง แต่เอกสารหลักแนะนำให้ยกระดับงานและใช้อุปกรณ์ช่วยทำงานใกล้พื้น",
            "proposed_action": "ใช้ข้อความจาก Body Map และตัดข้อความเรื่องเข็มขัดพยุงหลังออก",
            "approval_status": "pending",
        },
        {
            "recommendation_id": "act_harvest_empty_often.01",
            "selection_key": "act_harvest_empty_often",
            "issue_type": "indirect_source_mapping",
            "source_a": "current_app_recommendation_copy",
            "source_b": "app_recommendations_v3:p2",
            "conflicting_value": "ข้อความเดิมให้เทตะกร้าบ่อยขึ้น แต่เอกสาร V3 ระบุโดยตรงให้ปรับตะกร้าให้สูงขึ้น",
            "proposed_action": "ใช้ข้อความตาม V3 ว่าให้ยกหรือปรับความสูงของตะกร้า",
            "approval_status": "pending",
        },
        {
            "recommendation_id": "act_ref_weight_low.01",
            "selection_key": "act_ref_weight_low",
            "issue_type": "project_specific_standard_adaptation",
            "source_a": "app_recommendations_v3:p1",
            "source_b": "reba_employee_assessment_worksheet:p1",
            "conflicting_value": "เกณฑ์อายุ/เพศ A-F และสัดส่วนการลดน้ำหนักเป็นการปรับใช้ในโครงการ ไม่ใช่สูตรที่ระบุใน REBA worksheet ที่ได้รับ",
            "proposed_action": "ระบุว่าเป็นแนวทางเฉพาะโครงการจากผู้ว่าจ้าง ไม่เรียกว่าเป็นสูตรมาตรฐาน ISO โดยตรง",
            "approval_status": "pending",
        },
    ]
    with conflicts_path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=conflict_columns)
        writer.writeheader()
        writer.writerows(conflicts)


def main() -> None:
    strings = Path("lib/core/localization/sookta_strings.dart")
    rows = build_rows(strings)
    write_master(
        rows,
        Path("data/recommendations/recommendation_master.csv"),
    )
    write_reports(rows, strings, Path("data/recommendations/reports"))
    print(f"master_rows={len(rows)}")


if __name__ == "__main__":
    main()
