#!/usr/bin/env python3
"""Run Android clean smoke and capture each validated screen via adb.

The integration smoke test prints ANDROID_SMOKE_CAPTURE_READY:<name> after each
screen passes its layout/runtime checks. This runner listens for those markers
and saves a real device screenshot for each one.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path


PACKAGE_ID = "com.kdev.sookta"
FLUTTER = "/Users/kpc/develop/flutter/bin/flutter"
ADB = "/Users/kpc/Library/Android/sdk/platform-tools/adb"
MARKER = "ANDROID_SMOKE_CAPTURE_READY:"


def run(args: list[str], *, cwd: Path | None = None, check: bool = True) -> str:
    result = subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    return result.stdout.strip()


def capture_png(serial: str, destination: Path) -> None:
    result = subprocess.run(
        [ADB, "-s", serial, "exec-out", "screencap", "-p"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    destination.write_bytes(result.stdout)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--serial", required=True)
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--out-dir")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = (
        Path(args.out_dir).resolve()
        if args.out_dir
        else repo / "build" / "qa" / f"android_clean_smoke_{timestamp}"
    )
    out_dir.mkdir(parents=True, exist_ok=True)
    log_path = out_dir / "smoke-test.log"

    device_props = {
        "serial": args.serial,
        "model": run([ADB, "-s", args.serial, "shell", "getprop", "ro.product.model"], check=False),
        "manufacturer": run([ADB, "-s", args.serial, "shell", "getprop", "ro.product.manufacturer"], check=False),
        "android_release": run([ADB, "-s", args.serial, "shell", "getprop", "ro.build.version.release"], check=False),
        "sdk": run([ADB, "-s", args.serial, "shell", "getprop", "ro.build.version.sdk"], check=False),
    }

    # Clean state for a first-run smoke. Some physical devices can reject a
    # direct uninstall while an instrumentation session is still settling, so we
    # force-stop first and always fall back to pm clear. The test itself also
    # clears SharedPreferences at launch.
    force_stop_output = run(
        [ADB, "-s", args.serial, "shell", "am", "force-stop", PACKAGE_ID],
        check=False,
    )
    clear_output = run(
        [ADB, "-s", args.serial, "shell", "pm", "clear", PACKAGE_ID],
        check=False,
    )
    uninstall_output = run([ADB, "-s", args.serial, "uninstall", PACKAGE_ID], check=False)

    command = [
        FLUTTER,
        "test",
        "--dart-define=SOOKTA_SMOKE_CAPTURE_PAUSE=true",
        "integration_test/ios_full_page_smoke_test.dart",
        "-d",
        args.serial,
    ]

    screenshots: list[dict[str, str | int]] = []
    env = os.environ.copy()
    env["COPYFILE_DISABLE"] = "1"
    start = time.time()
    with log_path.open("w", encoding="utf-8") as log_file:
        log_file.write(f"Device: {json.dumps(device_props, ensure_ascii=False)}\n")
        log_file.write(f"Clean force-stop: {force_stop_output}\n")
        log_file.write(f"Clean pm clear: {clear_output}\n")
        log_file.write(f"Clean uninstall: {uninstall_output}\n")
        log_file.write(f"Command: {' '.join(command)}\n\n")
        log_file.flush()

        process = subprocess.Popen(
            command,
            cwd=str(repo),
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=1,
        )
        assert process.stdout is not None
        for line in process.stdout:
            sys.stdout.write(line)
            log_file.write(line)
            log_file.flush()
            if MARKER in line:
                name = line.split(MARKER, 1)[1].strip()
                index = len(screenshots) + 1
                filename = f"{index:02d}_{name}.png"
                destination = out_dir / filename
                capture_png(args.serial, destination)
                screenshots.append(
                    {
                        "index": index,
                        "name": name,
                        "file": str(destination),
                    }
                )
                message = f"ANDROID_SMOKE_CAPTURE_SAVED: {filename}\n"
                sys.stdout.write(message)
                log_file.write(message)
                log_file.flush()

        return_code = process.wait()

    elapsed = round(time.time() - start, 2)
    summary = {
        "status": "pass" if return_code == 0 else "fail",
        "return_code": return_code,
        "started_at": timestamp,
        "elapsed_seconds": elapsed,
        "device": device_props,
        "package_id": PACKAGE_ID,
        "clean_force_stop": force_stop_output,
        "clean_pm_clear": clear_output,
        "clean_uninstall": uninstall_output,
        "command": command,
        "screenshot_count": len(screenshots),
        "screenshots": screenshots,
        "log": str(log_path),
    }
    summary_path = out_dir / "summary.json"
    summary_path.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"ANDROID_SMOKE_SUMMARY: {summary_path}")
    return return_code


if __name__ == "__main__":
    raise SystemExit(main())
