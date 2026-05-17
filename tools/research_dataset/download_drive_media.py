#!/usr/bin/env python3
"""Download Google Drive media listed in a file-level research catalog."""

from __future__ import annotations

import argparse
import csv
import http.cookiejar
import re
import sys
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class DriveMediaRow:
    activity: str
    session_id: str
    drive_file_id: str
    file_name: str
    media_kind: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download fSookta Drive media.")
    parser.add_argument(
        "--catalog",
        default="data/research/drive_priority_file_catalog.csv",
        help="File-level Drive media catalog CSV.",
    )
    parser.add_argument(
        "--media-root",
        default="data/research/media",
        help="Local media root used by extract_pose_dataset.py.",
    )
    parser.add_argument(
        "--images-only",
        action="store_true",
        help="Download only image rows. Useful for quick first dataset extraction.",
    )
    parser.add_argument(
        "--videos-only",
        action="store_true",
        help="Download only video rows.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Optional maximum number of files to download.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace files that already exist.",
    )
    return parser.parse_args()


def read_catalog(path: Path) -> list[DriveMediaRow]:
    with path.open(newline="", encoding="utf-8") as handle:
        return [
            DriveMediaRow(
                activity=row["activity"],
                session_id=row["session_id"],
                drive_file_id=row["drive_file_id"],
                file_name=row["file_name"],
                media_kind=row["media_kind"],
            )
            for row in csv.DictReader(handle)
        ]


def selected_rows(rows: list[DriveMediaRow], args: argparse.Namespace) -> list[DriveMediaRow]:
    if args.images_only and args.videos_only:
        raise ValueError("Use only one of --images-only or --videos-only.")
    selected = rows
    if args.images_only:
        selected = [row for row in selected if row.media_kind == "image"]
    if args.videos_only:
        selected = [row for row in selected if row.media_kind == "video"]
    if args.limit > 0:
        selected = selected[: args.limit]
    return selected


def target_path(media_root: Path, row: DriveMediaRow) -> Path:
    file_name = sanitize_file_name(row.file_name)
    return media_root / row.activity / row.session_id / file_name


def sanitize_file_name(value: str) -> str:
    clean = value.replace("/", "_").replace("\\", "_").strip()
    clean = re.sub(r"\s+", " ", clean)
    if not clean or clean in {".", ".."}:
        raise ValueError(f"Invalid file name: {value!r}")
    return clean


def download_drive_file(file_id: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    cookie_jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookie_jar))
    base_url = "https://drive.google.com/uc?" + urllib.parse.urlencode({
        "export": "download",
        "id": file_id,
    })
    response = opener.open(base_url, timeout=120)
    data = response.read()

    confirm_url = confirmation_url(data, file_id)
    if confirm_url:
        response = opener.open(confirm_url, timeout=120)
        data = response.read()

    if looks_like_html(data):
        raise RuntimeError(
            f"Google Drive returned an HTML page for {file_id}; "
            "check sharing permissions or download the file manually."
        )

    destination.write_bytes(data)


def confirmation_url(data: bytes, file_id: str) -> str | None:
    text = data[:20000].decode("utf-8", errors="ignore")
    match = re.search(r'href="(\/uc\?export=download[^"]+confirm=[^"]+)"', text)
    if not match:
        return None
    href = match.group(1).replace("&amp;", "&")
    return "https://drive.google.com" + href if href.startswith("/") else href


def looks_like_html(data: bytes) -> bool:
    sample = data[:512].lstrip().lower()
    return sample.startswith(b"<!doctype html") or sample.startswith(b"<html")


def main() -> int:
    args = parse_args()
    catalog_rows = read_catalog(Path(args.catalog))
    rows = selected_rows(catalog_rows, args)
    media_root = Path(args.media_root)

    downloaded = 0
    skipped = 0
    failed = 0
    for row in rows:
        destination = target_path(media_root, row)
        if destination.exists() and not args.overwrite:
            skipped += 1
            print(f"skip {destination}", flush=True)
            continue
        try:
            print(f"download {row.drive_file_id} -> {destination}", flush=True)
            download_drive_file(row.drive_file_id, destination)
            downloaded += 1
        except Exception as error:  # noqa: BLE001 - visible CLI failure summary.
            failed += 1
            print(f"failed {row.drive_file_id} {row.file_name}: {error}", file=sys.stderr)

    print(f"downloaded={downloaded} skipped={skipped} failed={failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
