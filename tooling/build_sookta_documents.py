"""Build the controlled Sookta 2.1.0 Word deliverables."""

from __future__ import annotations

import argparse
from pathlib import Path

from sookta_document_builder import BALANCED_PROFILE, DiagramSpec, build_docx


ROOT = Path(__file__).resolve().parents[1]
DELIVERABLE_DIR = ROOT / "docs" / "deliverables" / "sookta-2.1.0"

BALANCED_MARKDOWN = (
    DELIVERABLE_DIR
    / "Sookta_2.1.0_Application_Development_Workflow_Calculation_and_Guidelines_TH.md"
)
BALANCED_DOCX = (
    DELIVERABLE_DIR
    / "Sookta_2.1.0_Application_Development_Workflow_Calculation_and_Guidelines_TH.docx"
)


BALANCED_DIAGRAMS = {
    "development-lifecycle": DiagramSpec(
        title="วงจรการสร้าง Sookta Application",
        nodes=(
            ("requirements", "Requirement และ guideline"),
            ("design", "UX/UI และ data flow"),
            ("flutter", "Flutter implementation"),
            ("assessment", "Media, assessment และ ML"),
            ("data", "Persistence, history และ export"),
            ("tests", "Automated tests"),
            ("iphone", "UAT บน iPhone จริง"),
            ("android", "Android parity/UAT"),
            ("production", "Production configuration"),
            ("store", "Signed IPA/AAB และ Store validation"),
        ),
        edges=(
            ("requirements", "design", ""),
            ("design", "flutter", ""),
            ("flutter", "assessment", ""),
            ("assessment", "data", ""),
            ("data", "tests", ""),
            ("tests", "iphone", ""),
            ("iphone", "android", ""),
            ("android", "production", ""),
            ("production", "store", ""),
        ),
    ),
    "startup-decision": DiagramSpec(
        title="Startup decision",
        nodes=(
            ("open", "เปิด Application"),
            ("firebase", "เตรียม Firebase แบบ fail-safe"),
            ("restore", "Splash และ restore local state"),
            ("decision", "ตรวจ setupCompleted และภาษาที่เลือก"),
            ("destination", "Main Tabs หรือ Onboarding"),
        ),
        edges=(
            ("open", "firebase", ""),
            ("firebase", "restore", ""),
            ("restore", "decision", ""),
            ("decision", "destination", ""),
        ),
    ),
    "first-run": DiagramSpec(
        title="การเปิดใช้งานครั้งแรก",
        nodes=(
            ("language", "เลือกภาษา"),
            ("profile", "กรอกข้อมูลเกษตรกร"),
            ("bmi", "ตรวจ BMI preview"),
            ("avatar", "เลือกหรือถ่ายรูป Avatar"),
            ("complete", "บันทึก setupCompleted"),
            ("home", "เข้าสู่ Home"),
        ),
        edges=(
            ("language", "profile", ""),
            ("profile", "bmi", ""),
            ("bmi", "avatar", ""),
            ("avatar", "complete", ""),
            ("complete", "home", ""),
        ),
    ),
    "returning-user": DiagramSpec(
        title="การเปิดใช้งานครั้งต่อไป",
        nodes=(
            ("open", "เปิด Application"),
            ("restore", "Restore ภาษา เกษตรกร ประวัติ และแบบร่าง"),
            ("tabs", "Main Tabs"),
            ("home", "Home"),
            ("history", "History"),
            ("profile", "Profile และ Settings"),
            ("assessment", "เริ่มประเมิน"),
        ),
        edges=(
            ("open", "restore", ""),
            ("restore", "tabs", ""),
            ("tabs", "home", ""),
            ("tabs", "history", ""),
            ("tabs", "profile", ""),
            ("home", "assessment", ""),
        ),
    ),
    "assessment-e2e": DiagramSpec(
        title="Workflow การประเมินแบบ end-to-end",
        nodes=(
            ("farmer", "เลือกเกษตรกรปัจจุบัน"),
            ("activity", "เลือกกิจกรรม"),
            ("media", "เพิ่มภาพ 1–4 ภาพ หรือวิดีโอ"),
            ("gate", "ตรวจคุณภาพ จำนวนบุคคล และ pose"),
            ("calculate", "REBA และ ISO แบบประยุกต์"),
            ("guardrail", "XGBoost/ONNX guardrail"),
            ("before", "ผลความเสี่ยงก่อนปรับ"),
            ("actions", "เลือกวิธีลดความเสี่ยง 4 หมวด"),
            ("confirm", "ยืนยันข้อมูลก่อนบันทึก"),
            ("after", "ผลหลังปรับและบันทึก History"),
            ("followup", "แนวโน้มและ Export"),
        ),
        edges=(
            ("farmer", "activity", ""),
            ("activity", "media", ""),
            ("media", "gate", ""),
            ("gate", "calculate", "พร้อม"),
            ("calculate", "guardrail", ""),
            ("guardrail", "before", ""),
            ("before", "actions", ""),
            ("actions", "confirm", ""),
            ("confirm", "after", ""),
            ("after", "followup", ""),
        ),
    ),
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--font",
        type=Path,
        required=True,
        help="Path to Sarabun-Regular.ttf for diagram rendering.",
    )
    parser.add_argument(
        "--document",
        choices=("balanced",),
        default="balanced",
    )
    args = parser.parse_args()

    if args.document == "balanced":
        build_docx(
            BALANCED_MARKDOWN,
            BALANCED_DOCX,
            BALANCED_PROFILE,
            BALANCED_DIAGRAMS,
            args.font,
        )
        print(BALANCED_DOCX)


if __name__ == "__main__":
    main()
