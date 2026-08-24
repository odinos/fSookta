#!/usr/bin/env python3
"""Canonical Task 6 data/report entrypoint."""
import json
import os
from pathlib import Path

from task6_source import build_corrected_payload, validate_payload

root = Path(os.environ.get('FSOOKTA_HANDOVER_ROOT', '/private/tmp/fsookta-final-handover'))
payload = build_corrected_payload(root)
validate_payload(payload, root)
out = root / 'working/task6/task6_corrected_payload.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + '\n')

# The document builder consumes only the canonical payload written above.
import build_task6_documents  # noqa: E402,F401

print(json.dumps({'status': 'canonical_task6_data_and_reports_built', 'tests': len(payload['tests']), 'requirements': len(payload['requirements'])}))
