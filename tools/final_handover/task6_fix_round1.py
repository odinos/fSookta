#!/usr/bin/env python3
"""Compatibility entrypoint retired in favour of the canonical Task 6 source."""
from task6_source import *  # noqa: F401,F403


if __name__ == "__main__":
    import json
    import os
    from pathlib import Path

    root = Path(os.environ.get("FSOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
    payload = build_corrected_payload(root)
    validate_payload(payload, root)
    output = root / "working/task6/task6_corrected_payload.json"
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(output)
