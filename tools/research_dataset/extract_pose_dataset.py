#!/usr/bin/env python3
"""Extract MoveNet joint-feature datasets from local research media.

The script reads the session manifest in data/research/drive_media_catalog.csv,
finds locally downloaded images/videos, samples video frames, runs the same
MoveNet TFLite model used by the Flutter app, and writes a canonical CSV with
51 feature values matching assets/models/joint_feature_schema.json.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".heic", ".heif", ".webp"}
VIDEO_EXTENSIONS = {".mov", ".mp4", ".m4v", ".avi"}


@dataclass(frozen=True)
class SessionManifestRow:
    activity_id: str
    activity: str
    session_id: str
    folder_url: str
    expected_total_files: int


@dataclass(frozen=True)
class MediaFile:
    session: SessionManifestRow
    path: Path
    kind: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract fSookta research pose features from local media.",
    )
    parser.add_argument(
        "--manifest",
        default="data/research/drive_media_catalog.csv",
        help="Session-level Drive catalog CSV.",
    )
    parser.add_argument(
        "--media-root",
        default="data/research/media",
        help=(
            "Local media root. Supported layouts include "
            "<activity>/<session_id>/*, <session_id>/*, and recursive session "
            "folder names such as 4.1 or pruning/4.1."
        ),
    )
    parser.add_argument(
        "--output-dir",
        default="data/research/extracted",
        help="Directory for extracted dataset CSVs and reports.",
    )
    parser.add_argument(
        "--model",
        default="assets/ml/movenet_thunder.tflite",
        help="MoveNet Thunder TFLite model path.",
    )
    parser.add_argument(
        "--schema",
        default="assets/models/joint_feature_schema.json",
        help="Canonical 51-feature schema JSON.",
    )
    parser.add_argument(
        "--frame-interval-sec",
        type=float,
        default=1.0,
        help="Video frame sampling interval in seconds.",
    )
    parser.add_argument(
        "--min-pose-score",
        type=float,
        default=0.2,
        help="Rows below this average pose confidence are marked low_confidence.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only inventory local media and missing sessions; no TFLite inference.",
    )
    return parser.parse_args()


def read_manifest(path: Path) -> list[SessionManifestRow]:
    with path.open(newline="", encoding="utf-8") as handle:
        return [
            SessionManifestRow(
                activity_id=row["activity_id"],
                activity=row["activity"],
                session_id=row["session_id"],
                folder_url=row["folder_url"],
                expected_total_files=int(row["total_files"]),
            )
            for row in csv.DictReader(handle)
        ]


def load_schema(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        schema = json.load(handle)
    if schema.get("featureCount") != 51:
        raise ValueError(f"Expected 51 schema features, got {schema.get('featureCount')}.")
    if len(schema.get("landmarks", [])) != 17:
        raise ValueError("Expected 17 MoveNet landmarks in schema.")
    return schema


def feature_columns(schema: dict[str, Any]) -> list[str]:
    columns: list[str] = []
    for landmark in schema["landmarks"]:
        for component in schema["components"]:
            columns.append(f"{landmark}_{component}")
    return columns


def discover_media(media_root: Path, sessions: Iterable[SessionManifestRow]) -> list[MediaFile]:
    files: list[MediaFile] = []
    for session in sessions:
        for path in find_session_files(media_root, session):
            kind = media_kind(path)
            if kind:
                files.append(MediaFile(session=session, path=path, kind=kind))
    return sorted(files, key=lambda item: (item.session.activity_id, item.session.session_id, str(item.path)))


def find_session_files(media_root: Path, session: SessionManifestRow) -> list[Path]:
    if not media_root.exists():
        return []

    candidates = [
        media_root / session.activity / session.session_id,
        media_root / session.session_id,
        media_root / session.activity_id / session.session_id,
    ]

    seen: set[Path] = set()
    results: list[Path] = []
    for candidate in candidates:
        if candidate.exists():
            for path in media_files_under(candidate):
                resolved = path.resolve()
                if resolved not in seen:
                    seen.add(resolved)
                    results.append(path)

    if results:
        return results

    # Fallback for human-created folders such as "4. Pruning (7)/4.1".
    for folder in media_root.rglob("*"):
        if folder.is_dir() and folder.name == session.session_id:
            for path in media_files_under(folder):
                resolved = path.resolve()
                if resolved not in seen:
                    seen.add(resolved)
                    results.append(path)
    return results


def media_files_under(folder: Path) -> list[Path]:
    return [
        path
        for path in folder.rglob("*")
        if path.is_file() and media_kind(path) is not None
    ]


def media_kind(path: Path) -> str | None:
    suffix = path.suffix.lower()
    if suffix in IMAGE_EXTENSIONS:
        return "image"
    if suffix in VIDEO_EXTENSIONS:
        return "video"
    return None


class MoveNetExtractor:
    def __init__(self, model_path: Path, schema: dict[str, Any]) -> None:
        self.schema = schema
        self.interpreter = self._create_interpreter(model_path)
        self.input_details = self.interpreter.get_input_details()[0]
        self.output_details = self.interpreter.get_output_details()[0]
        self.interpreter.allocate_tensors()

    def _create_interpreter(self, model_path: Path) -> Any:
        try:
            from tflite_runtime.interpreter import Interpreter
        except ImportError:
            try:
                import tensorflow as tf
            except ImportError as error:
                raise RuntimeError(
                    "Install TensorFlow or tflite_runtime before inference. "
                    "Run: python3 -m pip install -r tools/research_dataset/requirements.txt"
                ) from error
            return tf.lite.Interpreter(model_path=str(model_path))
        return Interpreter(model_path=str(model_path))

    def predict_features(self, rgb_image: Any) -> tuple[list[float], float]:
        resized = self._resize_for_model(rgb_image)
        self.interpreter.set_tensor(self.input_details["index"], resized)
        self.interpreter.invoke()
        output = self.interpreter.get_tensor(self.output_details["index"])
        keypoints = output.reshape(17, 3)

        # Data preprocessing before writing ML rows:
        # MoveNet emits each landmark as y, x, score in normalized image
        # coordinates. The app's offline models require x, y, score in landmark
        # index order, clipped to 0..1 so Logistic Regression and XGBoost receive
        # the same stable dense vector on every platform.
        features: list[float] = []
        total_score = 0.0
        for point in keypoints:
            y_value, x_value, score = point
            features.extend([
                bounded(float(x_value)),
                bounded(float(y_value)),
                bounded(float(score)),
            ])
            total_score += bounded(float(score))

        if len(features) != self.schema["featureCount"]:
            raise RuntimeError(f"Extracted {len(features)} features; expected 51.")
        return features, total_score / 17.0

    def _resize_for_model(self, rgb_image: Any) -> Any:
        import cv2
        import numpy as np

        target_height = int(self.input_details["shape"][1])
        target_width = int(self.input_details["shape"][2])
        resized = cv2.resize(rgb_image, (target_width, target_height), interpolation=cv2.INTER_LINEAR)
        dtype = self.input_details["dtype"]
        tensor = resized.astype(dtype)
        if np.issubdtype(dtype, np.floating):
            tensor = tensor.astype(np.float32)
        return np.expand_dims(tensor, axis=0)


def bounded(value: float) -> float:
    if not math.isfinite(value):
        return 0.0
    return float(min(max(value, 0.0), 1.0))


def write_inventory(output_dir: Path, media_files: list[MediaFile]) -> None:
    inventory_path = output_dir / "media_inventory.csv"
    with inventory_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "activity_id",
                "activity",
                "session_id",
                "kind",
                "path",
            ],
        )
        writer.writeheader()
        for media_file in media_files:
            writer.writerow({
                "activity_id": media_file.session.activity_id,
                "activity": media_file.session.activity,
                "session_id": media_file.session.session_id,
                "kind": media_file.kind,
                "path": str(media_file.path),
            })


def write_missing_sessions(
    output_dir: Path,
    sessions: list[SessionManifestRow],
    media_files: list[MediaFile],
) -> None:
    discovered = {(item.session.activity, item.session.session_id) for item in media_files}
    missing_path = output_dir / "missing_media_sessions.csv"
    with missing_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "activity_id",
                "activity",
                "session_id",
                "expected_total_files",
                "folder_url",
            ],
        )
        writer.writeheader()
        for session in sessions:
            key = (session.activity, session.session_id)
            if session.expected_total_files > 0 and key not in discovered:
                writer.writerow({
                    "activity_id": session.activity_id,
                    "activity": session.activity,
                    "session_id": session.session_id,
                    "expected_total_files": session.expected_total_files,
                    "folder_url": session.folder_url,
                })


def extract_dataset(
    output_dir: Path,
    media_files: list[MediaFile],
    extractor: MoveNetExtractor,
    schema: dict[str, Any],
    frame_interval_sec: float,
    min_pose_score: float,
) -> dict[str, int]:
    import cv2

    dataset_path = output_dir / "pose_feature_dataset.csv"
    columns = [
        "activity_id",
        "activity",
        "session_id",
        "source_path",
        "source_kind",
        "frame_timestamp_ms",
        "frame_index",
        "image_width",
        "image_height",
        "pose_score",
        "pose_status",
        "error",
        *feature_columns(schema),
        "label_source",
        "pseudo_reba_score",
        "pseudo_risk_level",
    ]
    counts = {
        "images_seen": 0,
        "videos_seen": 0,
        "rows_written": 0,
        "ok_rows": 0,
        "low_confidence_rows": 0,
        "failed_rows": 0,
    }

    with dataset_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for media_file in media_files:
            if media_file.kind == "image":
                counts["images_seen"] += 1
                row = extract_image_row(cv2, media_file, extractor, min_pose_score)
                writer.writerow(expand_row(row, schema))
                update_counts(counts, row["pose_status"])
            else:
                counts["videos_seen"] += 1
                for row in extract_video_rows(cv2, media_file, extractor, frame_interval_sec, min_pose_score):
                    writer.writerow(expand_row(row, schema))
                    update_counts(counts, row["pose_status"])
    return counts


def extract_image_row(cv2: Any, media_file: MediaFile, extractor: MoveNetExtractor, min_pose_score: float) -> dict[str, Any]:
    image = cv2.imread(str(media_file.path), cv2.IMREAD_COLOR)
    if image is None:
        return base_row(media_file, None, None, 0, 0, "read_failed", "Could not decode image.", [])
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    height, width = rgb_image.shape[:2]
    return infer_row(media_file, extractor, rgb_image, None, None, width, height, min_pose_score)


def extract_video_rows(
    cv2: Any,
    media_file: MediaFile,
    extractor: MoveNetExtractor,
    frame_interval_sec: float,
    min_pose_score: float,
) -> Iterable[dict[str, Any]]:
    capture = cv2.VideoCapture(str(media_file.path))
    if not capture.isOpened():
        yield base_row(media_file, None, None, 0, 0, "read_failed", "Could not open video.", [])
        return

    fps = float(capture.get(cv2.CAP_PROP_FPS) or 0.0)
    next_timestamp_ms = 0.0
    frame_interval_ms = max(frame_interval_sec, 0.1) * 1000.0
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        timestamp_ms = float(capture.get(cv2.CAP_PROP_POS_MSEC))
        frame_index = int(capture.get(cv2.CAP_PROP_POS_FRAMES)) - 1
        if timestamp_ms <= 0.0 and frame_index > 0 and fps > 0.0:
            timestamp_ms = (frame_index / fps) * 1000.0
        if timestamp_ms + 1e-3 < next_timestamp_ms:
            continue
        next_timestamp_ms = timestamp_ms + frame_interval_ms
        rgb_image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        height, width = rgb_image.shape[:2]
        yield infer_row(
            media_file,
            extractor,
            rgb_image,
            int(timestamp_ms),
            frame_index,
            width,
            height,
            min_pose_score,
        )
    capture.release()


def infer_row(
    media_file: MediaFile,
    extractor: MoveNetExtractor,
    rgb_image: Any,
    frame_timestamp_ms: int | None,
    frame_index: int | None,
    image_width: int,
    image_height: int,
    min_pose_score: float,
) -> dict[str, Any]:
    try:
        features, pose_score = extractor.predict_features(rgb_image)
    except Exception as error:  # noqa: BLE001 - stored in CSV for research QA.
        return base_row(
            media_file,
            frame_timestamp_ms,
            frame_index,
            image_width,
            image_height,
            "inference_failed",
            str(error),
            [],
        )

    status = "ok" if pose_score >= min_pose_score else "low_confidence"
    return base_row(
        media_file,
        frame_timestamp_ms,
        frame_index,
        image_width,
        image_height,
        status,
        "",
        features,
        pose_score,
    )


def base_row(
    media_file: MediaFile,
    frame_timestamp_ms: int | None,
    frame_index: int | None,
    image_width: int,
    image_height: int,
    pose_status: str,
    error: str,
    features: list[float],
    pose_score: float = 0.0,
) -> dict[str, Any]:
    return {
        "activity_id": media_file.session.activity_id,
        "activity": media_file.session.activity,
        "session_id": media_file.session.session_id,
        "source_path": str(media_file.path),
        "source_kind": media_file.kind,
        "frame_timestamp_ms": "" if frame_timestamp_ms is None else frame_timestamp_ms,
        "frame_index": "" if frame_index is None else frame_index,
        "image_width": image_width,
        "image_height": image_height,
        "pose_score": round(pose_score, 6),
        "pose_status": pose_status,
        "error": error,
        "features": features,
        "label_source": "pending_expert_label",
        "pseudo_reba_score": "",
        "pseudo_risk_level": "",
    }


def expand_row(row: dict[str, Any], schema: dict[str, Any]) -> dict[str, Any]:
    expanded = dict(row)
    features = expanded.pop("features")
    padded_features = [*features, *([0.0] * (schema["featureCount"] - len(features)))]
    for column, value in zip(feature_columns(schema), padded_features):
        expanded[column] = round(float(value), 8)
    return expanded


def update_counts(counts: dict[str, int], pose_status: str) -> None:
    counts["rows_written"] += 1
    if pose_status == "ok":
        counts["ok_rows"] += 1
    elif pose_status == "low_confidence":
        counts["low_confidence_rows"] += 1
    else:
        counts["failed_rows"] += 1


def write_report(
    output_dir: Path,
    args: argparse.Namespace,
    sessions: list[SessionManifestRow],
    media_files: list[MediaFile],
    extraction_counts: dict[str, int] | None,
) -> None:
    report = {
        "manifest": args.manifest,
        "media_root": args.media_root,
        "model": args.model,
        "schema": args.schema,
        "frame_interval_sec": args.frame_interval_sec,
        "min_pose_score": args.min_pose_score,
        "dry_run": args.dry_run,
        "session_count": len(sessions),
        "local_media_count": len(media_files),
        "local_image_count": sum(1 for item in media_files if item.kind == "image"),
        "local_video_count": sum(1 for item in media_files if item.kind == "video"),
        "extraction": extraction_counts or {},
    }
    with (output_dir / "dataset_extraction_report.json").open("w", encoding="utf-8") as handle:
        json.dump(report, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def main() -> int:
    args = parse_args()
    manifest_path = Path(args.manifest)
    media_root = Path(args.media_root)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    sessions = read_manifest(manifest_path)
    schema = load_schema(Path(args.schema))
    media_files = discover_media(media_root, sessions)
    write_inventory(output_dir, media_files)
    write_missing_sessions(output_dir, sessions, media_files)

    extraction_counts = None
    if not args.dry_run:
        extractor = MoveNetExtractor(Path(args.model), schema)
        extraction_counts = extract_dataset(
            output_dir=output_dir,
            media_files=media_files,
            extractor=extractor,
            schema=schema,
            frame_interval_sec=args.frame_interval_sec,
            min_pose_score=args.min_pose_score,
        )

    write_report(output_dir, args, sessions, media_files, extraction_counts)
    print(f"Sessions: {len(sessions)}")
    print(f"Local media files: {len(media_files)}")
    print(f"Wrote: {output_dir}")
    if args.dry_run:
        print("Dry run complete. Install requirements and rerun without --dry-run for TFLite inference.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
