#!/bin/sh
set -eu

artifact_path="${1:-build/ios/iphoneos/Runner.app}"
temporary_root=""

cleanup() {
  if [ -n "$temporary_root" ] && [ -d "$temporary_root" ]; then
    /bin/rm -rf "$temporary_root"
  fi
}
trap cleanup EXIT INT TERM

case "$artifact_path" in
  *.ipa)
    temporary_root="$(/usr/bin/mktemp -d /private/tmp/sookta-ios-verify.XXXXXX)"
    /usr/bin/unzip -q "$artifact_path" -d "$temporary_root"
    app_path="$(/usr/bin/find "$temporary_root/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
    ;;
  *.app)
    app_path="$artifact_path"
    ;;
  *)
    echo "Expected an .ipa or .app artifact: $artifact_path" >&2
    exit 1
    ;;
esac

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

echo "Checking code signature..."
signature_error="$(/usr/bin/codesign --verify "$app_path" 2>&1)" || {
  case "$signature_error" in
    *CSSMERR_TP_NOT_TRUSTED*)
      echo "WARNING: signature is intact, but its distribution certificate is not trusted by this local keychain."
      ;;
    *)
      printf '%s\n' "$signature_error" >&2
      exit 1
      ;;
  esac
}

echo "Checking every Mach-O slice for iPhoneOS compatibility..."
mach_o_count=0
while IFS= read -r binary_path; do
  file_description="$(/usr/bin/file -b "$binary_path")"
  case "$file_description" in
    *Mach-O*) ;;
    *) continue ;;
  esac

  mach_o_count=$((mach_o_count + 1))
  architectures="$(/usr/bin/lipo -archs "$binary_path")"
  for architecture in $architectures; do
    if [ "$architecture" = "x86_64" ]; then
      echo "Unsupported simulator architecture x86_64: $binary_path" >&2
      exit 1
    fi

    build_info="$(/usr/bin/xcrun vtool -show-build -arch "$architecture" "$binary_path")"
    platforms="$(printf '%s\n' "$build_info" | /usr/bin/awk '$1 == "platform" { print $2 }')"
    if [ -z "$platforms" ]; then
      echo "Missing Apple platform metadata: $binary_path ($architecture)" >&2
      exit 1
    fi
    for platform_name in $platforms; do
      if [ "$platform_name" = "IOSSIMULATOR" ] || [ "$platform_name" != "IOS" ]; then
        echo "Unsupported platform $platform_name: $binary_path ($architecture)" >&2
        exit 1
      fi
    done
  done
done <<EOF
$(/usr/bin/find "$app_path" -type f -print)
EOF

if [ "$mach_o_count" -eq 0 ]; then
  echo "No Mach-O executables found in $app_path" >&2
  exit 1
fi

echo "PASS: $mach_o_count Mach-O files contain only iPhoneOS slices."
echo "Inspection only: no framework was removed or modified."
