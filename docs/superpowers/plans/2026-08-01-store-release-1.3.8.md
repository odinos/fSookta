# Sookta 1.3.8+25 Store Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce verified, signed iOS and Android Store artifacts for Sookta `1.3.8+25` from the approved Thai–English recommendation wording release.

**Architecture:** Treat `codex/recommendation-localization-review` as the immutable release lineage, synchronize the version in Flutter source and its regression test, then validate before producing each platform artifact. Store copy and the final verification record remain separate documentation units so marketing text can be copied without build-log details.

**Tech Stack:** Flutter/Dart, Gradle Android App Bundle, Xcode App Store archive/export, XCTest-compatible iOS signing tools, Markdown release metadata.

## Global Constraints

- Use branch `codex/recommendation-localization-review` as the release source.
- Change the Flutter version from `1.3.7+24` to exactly `1.3.8+25`.
- Include only behavior and wording present on this branch after commit `eb4cc87`.
- Do not merge Trend/ML training work from `codex/ios-real-integrations`.
- Do not change scoring formulas, data collection behavior, or add features.
- Store copy must be available in Thai and English and must not claim medical diagnosis or treatment.
- Put distributable artifacts under `outputs/store-builds/1.3.8+25/`.

## File Map

- Modify `pubspec.yaml`: Flutter marketing version and build number source.
- Modify `lib/app/build_info.dart`: in-app version label synchronized with Flutter metadata.
- Modify `test/store_release_version_test.dart`: regression contract for `1.3.8+25`.
- Create `docs/store-metadata-1.3.8+25-th-en.md`: copy-ready App Store and Play Store descriptions and release notes.
- Create `docs/store-release-verification-1.3.8+25-20260801.md`: evidence from tests, artifact metadata, signing, sizes, and hashes.
- Create ignored artifacts below `outputs/store-builds/1.3.8+25/`: signed `.aab`, mapping file when available, signed `.ipa`, export options, and Xcode distribution summary when available.

---

### Task 1: Synchronize the Store Version

**Files:**
- Modify: `test/store_release_version_test.dart`
- Modify: `pubspec.yaml`
- Modify: `lib/app/build_info.dart`

**Interfaces:**
- Consumes: Flutter's `version: <name>+<number>` convention.
- Produces: `SooktaBuildInfo.versionName == '1.3.8'`, `buildNumber == '25'`, and label `1.3.8+25`.

- [ ] **Step 1: Change the regression test first**

```dart
test('store release uses the new 1.3.8 train and synchronized build 25', () {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final buildInfo = File('lib/app/build_info.dart').readAsStringSync();

  expect(pubspec, contains('version: 1.3.8+25'));
  expect(buildInfo, contains("versionName = '1.3.8'"));
  expect(buildInfo, contains("buildNumber = '25'"));
});
```

- [ ] **Step 2: Run the version test and verify the red state**

Run:

```sh
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/store_release_version_test.dart
```

Expected: FAIL because source still contains `1.3.7+24`.

- [ ] **Step 3: Update both version sources**

Set `pubspec.yaml` to:

```yaml
version: 1.3.8+25
```

Set `lib/app/build_info.dart` constants to:

```dart
static const versionName = '1.3.8';
static const buildNumber = '25';
```

- [ ] **Step 4: Run the version test and verify the green state**

Run:

```sh
/Users/kpc/develop/flutter/bin/flutter test --no-pub test/store_release_version_test.dart
```

Expected: PASS with one passing test.

- [ ] **Step 5: Commit the synchronized version**

```sh
git add pubspec.yaml lib/app/build_info.dart test/store_release_version_test.dart
git commit -m "release: bump Sookta to 1.3.8+25"
```

### Task 2: Prepare Thai and English Store Copy

**Files:**
- Create: `docs/store-metadata-1.3.8+25-th-en.md`
- Reference: `docs/app-store-connect-v1-metadata.md`
- Reference: `docs/play-store-v1-metadata.md`

**Interfaces:**
- Consumes: existing verified feature descriptions and approved recommendation-localization scope.
- Produces: copy-ready Thai and English sections for both Store consoles.

- [ ] **Step 1: Write the App Store sections**

Create Thai and English subsections for app name, subtitle, promotional text, full description, keywords, and What's New. Preserve the existing feature inventory; describe this release as improving the clarity, naturalness, and consistency of ergonomic recommendations across Thai and English.

- [ ] **Step 2: Write the Play Store sections**

Create Thai and English subsections for app name, short description, full description, and What's New. Keep the short descriptions within 80 characters and reuse the same factual capability claims and safety notice as the App Store copy.

- [ ] **Step 3: Verify release wording and excluded claims**

Run:

```sh
rg -n "1\.3\.8|1\.3\.8\+25|Trend|เทรนด์|diagnos|วินิจฉัย|รักษา" docs/store-metadata-1.3.8+25-th-en.md
```

Expected: version references are `1.3.8`/`1.3.8+25`; Trend is not presented as new work; diagnosis/treatment words appear only in the safety disclaimer.

- [ ] **Step 4: Commit Store metadata**

```sh
git add docs/store-metadata-1.3.8+25-th-en.md
git commit -m "docs: prepare bilingual store copy for 1.3.8"
```

### Task 3: Run the Complete Pre-build Quality Gate

**Files:**
- Verify: all tracked Flutter/Dart source and tests.

**Interfaces:**
- Consumes: versioned release source and locked dependencies.
- Produces: fresh dependency resolution, analyzer result, and complete test result used by both platform builds.

- [ ] **Step 1: Resolve dependencies**

```sh
/Users/kpc/develop/flutter/bin/flutter pub get
```

Expected: exit code 0 with the lockfile remaining unchanged unless Flutter legitimately refreshes generated plugin files.

- [ ] **Step 2: Run static analysis**

```sh
/Users/kpc/develop/flutter/bin/flutter analyze --no-pub
```

Expected: exit code 0 and no issues.

- [ ] **Step 3: Run the complete Flutter test suite**

```sh
/Users/kpc/develop/flutter/bin/flutter test --no-pub
```

Expected: exit code 0 with zero failed tests.

- [ ] **Step 4: Confirm no Trend/ML release commits entered the lineage**

```sh
git merge-base --is-ancestor 4c14457 HEAD
```

Expected: non-zero exit status, proving the Trend/ML training commit is not an ancestor of this release.

### Task 4: Build and Verify the Signed Android App Bundle

**Files:**
- Read locally: `/Users/kpc/Documents/GitHub/fSookta/android/key.properties`
- Create ignored: `android/key.properties` symlink during build only.
- Create ignored: `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-release.aab`
- Create ignored when available: `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-mapping.txt`

**Interfaces:**
- Consumes: version `1.3.8+25` and existing Play upload-key configuration.
- Produces: signed AAB with package `com.kdev.sookta`, version name `1.3.8`, and version code `25`.

- [ ] **Step 1: Link the ignored signing configuration and build**

```sh
ln -s /Users/kpc/Documents/GitHub/fSookta/android/key.properties android/key.properties
/Users/kpc/develop/flutter/bin/flutter build appbundle --release --no-pub
```

Expected: exit code 0 and `build/app/outputs/bundle/release/app-release.aab` exists.

- [ ] **Step 2: Copy the release outputs and remove only the temporary link**

```sh
mkdir -p outputs/store-builds/1.3.8+25
cp build/app/outputs/bundle/release/app-release.aab outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-release.aab
test ! -f build/app/outputs/mapping/release/mapping.txt || cp build/app/outputs/mapping/release/mapping.txt outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-mapping.txt
unlink android/key.properties
```

Expected: the named AAB exists and no signing-secret file is added to Git.

- [ ] **Step 3: Verify Android manifest metadata**

```sh
/Users/kpc/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest application-id outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-release.aab
/Users/kpc/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest version-name outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-release.aab
/Users/kpc/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest version-code outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-android-release.aab
```

Expected: `com.kdev.sookta`, `1.3.8`, and `25`.

### Task 5: Build and Verify the Signed iOS App Store IPA

**Files:**
- Read locally: `/Users/kpc/Documents/GitHub/fSookta/outputs/store-builds/1.3.7+24/Sookta-1.3.7+24-ios-export-options.plist`
- Create ignored: `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-ios-export-options.plist`
- Create ignored: `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-ios-appstore.ipa`
- Create ignored when generated: `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-ios-distribution-summary.plist`

**Interfaces:**
- Consumes: committed release source, existing Apple Distribution certificate/profile, and prior verified export settings.
- Produces: signed App Store IPA with bundle ID `com.kdev.sookta`, version `1.3.8`, and build `25`.

- [ ] **Step 1: Copy the export options under the new release name**

```sh
cp /Users/kpc/Documents/GitHub/fSookta/outputs/store-builds/1.3.7+24/Sookta-1.3.7+24-ios-export-options.plist outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-ios-export-options.plist
```

- [ ] **Step 2: Create a clean temporary source tree**

```sh
release_tmp_dir="$(mktemp -d /private/tmp/sookta-1.3.8.XXXXXX)"
git archive HEAD | tar -x -C "$release_tmp_dir"
```

Expected: a tracked-only release tree outside the Documents/FileProvider path.

- [ ] **Step 3: Resolve dependencies and export the signed IPA**

```sh
cd "$release_tmp_dir"
/Users/kpc/develop/flutter/bin/flutter pub get
COPYFILE_DISABLE=1 /Users/kpc/develop/flutter/bin/flutter build ipa --release --no-pub --export-options-plist=/Users/kpc/Documents/GitHub/fSookta/.worktrees/recommendation-localization-review/outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-ios-export-options.plist
```

Expected: Xcode archive and App Store export both exit 0 with an IPA under `build/ios/ipa/`.

- [ ] **Step 4: Copy the IPA and Xcode summary into the delivery folder**

Copy the single generated `.ipa` to `outputs/store-builds/1.3.8+25/Sookta-1.3.8+25-ios-appstore.ipa`. If Xcode emits `DistributionSummary.plist`, copy it as `Sookta-1.3.8+25-ios-distribution-summary.plist`.

- [ ] **Step 5: Inspect the IPA metadata and signing**

Extract the IPA into a fresh temporary directory, then run:

```sh
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' Payload/Runner.app/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Payload/Runner.app/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Payload/Runner.app/Info.plist
codesign --verify --deep --strict --verbose=2 Payload/Runner.app
codesign -d --entitlements :- Payload/Runner.app
```

Expected: `com.kdev.sookta`, `1.3.8`, `25`, a distribution signature, `get-task-allow=false`, and no embedded `integration_test.framework` reported by `tooling/verify_ios_release_artifact.sh`.

### Task 6: Record Final Release Evidence

**Files:**
- Create: `docs/store-release-verification-1.3.8+25-20260801.md`
- Verify: `outputs/store-builds/1.3.8+25/*`

**Interfaces:**
- Consumes: fresh outputs from Tasks 3–5.
- Produces: auditable release record and final artifact inventory.

- [ ] **Step 1: Generate artifact hashes and sizes**

```sh
shasum -a 256 outputs/store-builds/1.3.8+25/*
du -h outputs/store-builds/1.3.8+25/*
```

Expected: hashes and non-zero sizes for the AAB and IPA, plus any mapping/export-summary files.

- [ ] **Step 2: Write the verification record from actual output**

Record the branch and commit, exact analyzer/test totals, Android package/version/target SDK/signing result, iOS bundle/version/deployment target/orientations/signing/profile result, hashes, and any server-side validation still requiring App Store Connect or Play Console.

- [ ] **Step 3: Re-run the release-critical verification gate**

```sh
/Users/kpc/develop/flutter/bin/flutter analyze --no-pub
/Users/kpc/develop/flutter/bin/flutter test --no-pub
git diff --check
git status --short
```

Expected: analyzer and tests exit 0, no whitespace errors, and Git shows only the new verification document before its commit.

- [ ] **Step 4: Commit the verification record**

```sh
git add docs/store-release-verification-1.3.8+25-20260801.md
git commit -m "docs: record Sookta 1.3.8 release verification"
```

- [ ] **Step 5: Final inventory check**

```sh
find outputs/store-builds/1.3.8+25 -maxdepth 1 -type f -print | sort
git log -4 --oneline
```

Expected: signed AAB, signed IPA, supporting files, and commits for version, Store copy, and release verification.
