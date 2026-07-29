#!/usr/bin/env python3
"""Create complete English drafts for every recommendation review row."""

from __future__ import annotations

import csv
import re
from collections import Counter
from pathlib import Path

try:
    from tools.recommendations.build_recommendation_master import _dart_maps
except ModuleNotFoundError:
    from build_recommendation_master import _dart_maps


REVIEW_COLUMNS = [
    "recommendation_id",
    "selection_key",
    "record_type",
    "thai_source_text",
    "english_draft",
    "translation_style",
    "numbers_match",
    "units_match",
    "timing_match",
    "urgency_match",
    "negation_match",
    "meaning_review",
    "review_comment",
    "approval_status",
    "approved_by",
    "approved_at",
    "translation_version",
    "source_id",
    "source_page",
]

UI_ENGLISH = {
    "ui.recommendations.heading": "Recommendations by activity and risk",
    "ui.recommendations.instruction": (
        "Start with actions that fit this task, then compare the next result."
    ),
    "ui.category.posture": "Posture to adjust",
    "ui.category.risk_reduction": "Ways to reduce risk",
    "ui.category.rest_rotation": "Rest or task rotation",
    "ui.category.workload_support": "Tools or workload support",
    "ui.recommendations.empty": "No additional recommendation",
    "ui.recommendations.full": "Full recommendations",
    "report.selected_recommendations": "Selected recommendations",
    "system.unmapped_saved_recommendation": (
        "A saved recommendation could not be matched to the current approved catalog."
    ),
}

TRANSLATION_OVERRIDES = {
    "act_adj_eye_level": [
        "Adjust the work to eye level.",
        "Reduce neck bending.",
    ],
    "act_adj_wrist": ["Keep the wrist in a neutral position."],
    "act_avoid_bend": ["Reduce bending by raising the work area."],
    "act_harvest_empty_often": ["Raise the basket to reduce bending."],
    "act_body_arms_medium": [
        "Keep materials within 40 cm of the body.",
        "Put tools down when they are not in use.",
        "Rest the shoulders every 30 minutes and keep the work below shoulder height.",
    ],
    "act_body_legs_medium": [
        "Stand up or walk every 20 minutes.",
        "Use a squatting cushion or knee pad.",
        "Alternate between sitting, standing, and walking.",
    ],
    "act_body_manual_high": [
        "Limit each load to no more than 10 kg.",
        "Use a cart for distances over 10 m, and use 2-person lifting for loads over 20 kg.",
        "Avoid twisting while lifting.",
    ],
    "act_body_manual_medium": [
        "Divide materials into bags or containers weighing no more than 15 kg each.",
        "Keep the load close to the body.",
        "Lift with both hands.",
        "Avoid lifting above shoulder height.",
    ],
    "act_body_manual_very_high": [
        "Use a cart, trolley, or lifting aid.",
        "Avoid lifting more than 20 kg alone.",
        "Use at least two people to lift loads of 20-25 kg.",
        "Use lifting equipment for loads over 25 kg.",
    ],
    "act_body_neck_high": [
        "Raise the work area and stretch the neck every 15-20 minutes.",
        "Use a reaching aid.",
        "Avoid twisting or tilting the neck.",
    ],
    "act_body_neck_very_high": [
        "Change the work method immediately.",
        "Raise materials to waist height.",
        "Use long-handled tools.",
        "Change posture every 10-15 minutes.",
    ],
    "act_body_trunk_high": [
        "Avoid continuous bending for more than 10-15 minutes and stretch every 15 minutes.",
        "Face the material before lifting.",
        "Turn with the feet instead of twisting the waist.",
    ],
    "act_body_wrists_high": [
        "Rest the hands and wrists every 15-20 minutes.",
        "Rotate tasks every 20-30 minutes.",
        "Use suitable handles.",
        "Reduce gripping force when holding equipment.",
    ],
    "act_body_wrists_medium": [
        "Use handles that fit the hand.",
        "Relax the grip regularly.",
        "Rest the wrists every 30 minutes and stretch the fingers and wrists during breaks.",
    ],
    "act_fert_ref_low": [
        "Use a cart when fertilizer must be moved over a long distance, and change posture every 30 minutes."
    ],
    "act_extra_fert_cart": [
        "Use a cart to carry fertilizer sacks instead of carrying them on the body."
    ],
    "act_extra_prune_ladder": [
        "Use a stable ladder instead of reaching with the arm fully extended."
    ],
    "act_extra_spray_strap": [
        "Adjust the sprayer straps so they fit securely."
    ],
    "act_extra_spray_switch": [
        "Alternate the shoulder used to carry the tank to reduce pressure on one shoulder."
    ],
    "act_fert_ref_medium": [
        "Split fertilizer into smaller containers.",
        "Use a cart.",
        "Avoid twisting while lifting and wear non-slip footwear.",
    ],
    "act_harvest_ref_low": [
        "Alternate between standing and squatting every 20 minutes.",
        "Use soft gloves and place the basket on a raised stand.",
    ],
    "act_iso_floor_level": [
        "Keep the transport surface level, dry, non-slip, and clear of obstacles."
    ],
    "act_iso_push_smooth": [
        "Apply push or pull force smoothly without jerking."
    ],
    "act_iso_tool_handle_fit": [
        "Use non-slip handles that fit the hand.",
        "Reduce gripping force.",
    ],
    "act_pesticide_ref_high": [
        "If the sprayer tank exceeds the recommended weight, use a wheeled aid or a long-hose nozzle.",
        "Rotate tasks with a coworker every 30 minutes.",
    ],
    "act_pesticide_ref_medium": [
        "Limit continuous spraying to 1 hour, then rest for 15 minutes.",
        "Alternate the side holding the spray wand and wear non-slip footwear.",
    ],
    "act_pruning_ref_low": [
        "Use sharp, lightweight shears.",
        "Switch arms every 10-15 minutes and avoid keeping the arms above the head for long periods.",
    ],
    "act_pruning_ref_high": [
        "Use mechanically assisted pruning tools.",
        "When using shears, rest for 10 minutes every 20 minutes.",
        "Work as a team to rotate tasks.",
        "Avoid twisting while pruning.",
    ],
    "act_ref_weight_high": [
        "Reduce lifting weight immediately: men aged 20-45 years should lift no more than 13 kg.",
        "Men under 20 or over 45 years should lift no more than 10 kg.",
        "Women aged 20-45 years should lift no more than 10 kg.",
        "Women under 20 or over 45 years should lift no more than 8 kg.",
        "Use a handling aid if the load exceeds these limits.",
    ],
    "act_ref_weight_low": [
        "Check lifting weight: men aged 20-45 years should lift no more than 25 kg.",
        "Men under 20 or over 45 years should lift no more than 20 kg.",
        "Women aged 20-45 years should lift no more than 20 kg.",
        "Women under 20 or over 45 years should lift no more than 15 kg.",
    ],
    "act_ref_weight_medium": [
        "Reduce lifting weight: men aged 20-45 years should lift no more than 18 kg.",
        "Men under 20 or over 45 years should lift no more than 15 kg.",
        "Women aged 20-45 years should lift no more than 15 kg.",
        "Women under 20 or over 45 years should lift no more than 11 kg.",
    ],
    "act_transplant_ref_high": [
        "Improve the task immediately by raising the seedling bed to waist height.",
        "Use a squatting support or low stool.",
        "Take a break every 15-20 minutes.",
    ],
    "act_transplant_ref_low": [
        "The posture is acceptable; alternate between standing and squatting every 20 minutes.",
        "Check that the seedling bed is close to waist height.",
    ],
    "act_transplant_ref_medium": [
        "Raise the seedling bed to reduce bending.",
        "Use a squatting cushion or low stool.",
        "Change posture every 15 minutes and lift seedlings using the legs.",
    ],
    "act_transport_clear_path": [
        "Make the transport path level and clear of obstacles before moving materials."
    ],
    "act_transport_ref_high": [
        "Reduce sack weight.",
        "Use a wagon or large-wheel cart and provide a non-slip surface.",
        "Rest for 10-15 minutes every 30 minutes and practise correct team-lifting technique.",
    ],
    "act_transport_ref_low": [
        "Use a cart every time.",
        "Lift by bending the knees, keeping the back straight, avoiding twisting, and wearing non-slip footwear.",
    ],
    "act_reduce_load_tool": [
        "Reduce the load weight or use a handling aid."
    ],
    "act_use_legs": ["Use force from the legs, not the back."],
}


def _split_legacy_english(text: str) -> list[str]:
    normalized = re.sub(r";\s*|,\s*", " | ", text)
    normalized = normalized.replace(" and ", " | ")
    actions = []
    for item in normalized.split("|"):
        action = item.strip()
        if action:
            complete = action[0].upper() + action[1:]
            actions.append(complete.rstrip(".") + ".")
    return actions


def _numbers(text: str) -> Counter[str]:
    return Counter(re.findall(r"\d+(?:\.\d+)?", text))


def _units_match(thai: str, english: str) -> str:
    unit_pairs = {
        r"\d+\s*(?:กก\.?|กิโลกรัม)": r"\bkg\b",
        r"\d+\s*ซม\.?": r"\bcm\b",
        r"\d+\s*เมตร": r"\bm\b|met(?:er|re)s?",
        r"\d+\s*นาที": r"\bminutes?\b",
        r"ชั่วโมง": r"\bhours?\b",
        r"\d+\s*ปี": r"\byears?\b",
        r"\d+\s*คน": r"\bpeople\b|\bpersons?\b|\b\d+-person\b",
    }
    required = [
        pattern
        for thai_pattern, pattern in unit_pairs.items()
        if re.search(thai_pattern, thai)
    ]
    if not required:
        return "not_applicable"
    return (
        "pass"
        if all(re.search(pattern, english, re.IGNORECASE) for pattern in required)
        else "fail"
    )


def _english_by_id(master_rows: list[dict[str, str]]) -> dict[str, str]:
    _, legacy_english = _dart_maps(
        Path("lib/core/localization/sookta_strings.dart")
    )
    grouped: dict[str, list[dict[str, str]]] = {}
    for row in master_rows:
        if row["record_type"] == "recommendation":
            grouped.setdefault(row["selection_key"], []).append(row)
    translations: dict[str, str] = {}
    for key, rows in grouped.items():
        ordered = sorted(rows, key=lambda row: int(row["display_order"]))
        actions = TRANSLATION_OVERRIDES.get(key)
        if actions is None:
            actions = _split_legacy_english(legacy_english[key])
        if len(actions) != len(ordered):
            raise ValueError(
                f"translation_count:{key}:thai={len(ordered)}:english={len(actions)}"
            )
        for row, english in zip(ordered, actions):
            translations[row["recommendation_id"]] = english
    return translations


def build_review(master_path: Path, output_path: Path) -> None:
    with master_path.open(encoding="utf-8-sig", newline="") as stream:
        master_rows = list(csv.DictReader(stream))
    english_by_id = _english_by_id(master_rows)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=REVIEW_COLUMNS)
        writer.writeheader()
        for row in master_rows:
            english = (
                english_by_id[row["recommendation_id"]]
                if row["record_type"] == "recommendation"
                else UI_ENGLISH[row["selection_key"]]
            )
            writer.writerow(
                {
                    "recommendation_id": row["recommendation_id"],
                    "selection_key": row["selection_key"],
                    "record_type": row["record_type"],
                    "thai_source_text": row["thai_source_text"],
                    "english_draft": english,
                    "translation_style": (
                        "plain_english"
                        if row["selection_key"]
                        in {
                            "system.unmapped_saved_recommendation",
                            "act_iso_push_smooth",
                            "act_iso_push_not_pull",
                        }
                        else "direct"
                    ),
                    "numbers_match": (
                        "pass"
                        if _numbers(row["thai_source_text"]) == _numbers(english)
                        else "not_applicable"
                        if not _numbers(row["thai_source_text"])
                        and not _numbers(english)
                        else "fail"
                    ),
                    "units_match": _units_match(
                        row["thai_source_text"],
                        english,
                    ),
                    "timing_match": "pending_human_review",
                    "urgency_match": "pending_human_review",
                    "negation_match": "pending_human_review",
                    "meaning_review": "pending_human_review",
                    "review_comment": "",
                    "approval_status": "pending",
                    "approved_by": "",
                    "approved_at": "",
                    "translation_version": "1",
                    "source_id": row["source_id"],
                    "source_page": row["source_page"],
                }
            )


def main() -> None:
    master = Path("data/recommendations/recommendation_master.csv")
    output = Path("data/recommendations/translation_review.csv")
    build_review(master, output)
    print(f"translation_review={output}")


if __name__ == "__main__":
    main()
