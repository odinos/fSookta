#!/usr/bin/env python3
"""Canonical Task 6 data/report entrypoint."""
import json
import os
from pathlib import Path

from task6_source import build_corrected_payload, validate_payload

STAGING = Path(os.environ.get('FSOOKTA_HANDOVER_ROOT', '/private/tmp/fsookta-final-handover'))


def main(root: Path = STAGING) -> dict:
    payload = build_corrected_payload(root)
    validate_payload(payload, root)
    out = root / 'working/task6/task6_corrected_payload.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + '\n')
    import build_task6_documents
    build_task6_documents.main()
    return {'status': 'canonical_task6_data_and_reports_built', 'tests': len(payload['tests']), 'requirements': len(payload['requirements'])}


if __name__ == '__main__':
    print(json.dumps(main()))
