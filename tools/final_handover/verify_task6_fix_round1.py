#!/usr/bin/env python3
"""Compatibility entrypoint for the independent canonical Task 6 verifier."""
import json
import os
from pathlib import Path

from verify_task6_artifacts import verify


if __name__ == "__main__":
    root = Path(os.environ.get("FSOOKTA_HANDOVER_ROOT", "/private/tmp/fsookta-final-handover"))
    print(json.dumps(verify(root), indent=2, sort_keys=True))
