#!/bin/sh
set -eu

app_path="${1:-build/ios/iphoneos/Runner.app}"
frameworks_path="$app_path/Frameworks"
runner_path="$app_path/Runner"
integration_framework="$frameworks_path/integration_test.framework"

if [ ! -d "$app_path" ]; then
  echo "iOS artifact not found: $app_path" >&2
  exit 1
fi

echo "Inspecting iOS artifact: $app_path"
if [ -d "$integration_framework" ]; then
  echo "integration_test.framework: present"
  /usr/bin/du -sh "$integration_framework"
else
  echo "integration_test.framework: absent"
fi

if [ -f "$runner_path" ]; then
  echo "Runner dynamic dependencies mentioning integration_test:"
  /usr/bin/otool -L "$runner_path" |
    /usr/bin/grep -i integration_test || true
  echo "Runner undefined symbols mentioning IntegrationTest:"
  /usr/bin/nm -u "$runner_path" |
    /usr/bin/grep -i IntegrationTest || true
else
  echo "Runner executable not found: $runner_path" >&2
  exit 1
fi

echo "Inspection only: no framework was removed or modified."
