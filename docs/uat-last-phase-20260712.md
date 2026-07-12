# Sookta Last-Phase Physical UAT Report

Date: 2026-07-12  
App version: `1.3.6+21`  
Authoritative requirement matrix: `docs/last-phase-requirement-matrix-20260712.md`

## Executive Result

The code-level requirement audit covers all 19 source requirements. Static analysis passed and the full automated suite passed 102 tests. Portrait-only platform configuration and multiple-person photo rejection were added with regression coverage.

Physical-device UAT resumed on the connected iPhone. Signed Profile builds were installed and launched through CoreDevice. Orientation, two-farmer avatar isolation, draft/activity flows, four-photo handling, multi-person rejection, the assessment bypass used for uploaded-video UAT, and explicitly categorized short recommendations have been user-observed as passed. Android UAT has not started, as requested, and remaining iPhone listening/export/offline checks stay pending.

## Environment

| Item | Value |
| --- | --- |
| Flutter SDK | `/Users/kpc/develop/flutter` |
| App version | `1.3.6+21` |
| iPhone initially detected | iPhone, `00008030-0008788421F3802E`, iOS 26.5 |
| Physical Android | Not detected by ADB |
| Tablet | iPad simulator detected; no physical tablet connected |

## Automated and Build Evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Static analysis | PASS | `No issues found!` |
| Full Flutter tests | PASS | 102 tests |
| Focused last-phase suite | PASS | 25 tests |
| Portrait config tests | PASS | iOS and Android configuration assertions |
| Multi-person parser/asset tests | PASS | Model asset present; confidence and replacement rules verified |
| Android debug build | PARTIAL PASS | Fresh APK created; command did not return the normal completion line |
| Android APK portrait contract | PASS | APK manifest reports `screenOrientation="1"` |
| Android ML assets | PASS | APK contains MultiPose Lightning and SinglePose Thunder assets |
| iOS signed Profile build | PASS | Fresh `App.framework` built at 22:57:57 in `/private/tmp/fSookta-ios-uat-risk-groups`; signature verified, installed, and launched through CoreDevice |

## Physical UAT Checklist

| UAT step | iPhone | Android | Tablet |
| --- | --- | --- | --- |
| Install and launch current build | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Rotate both directions; app remains portrait | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Two farmers and avatar isolation | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Terminate/relaunch and resume correct draft | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Change activity and retain draft | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Select four photos; replace/remove one | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Reject real multi-person photo | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Final assessment button unobstructed | PASS (UAT bypass) | NOT AVAILABLE | NOT AVAILABLE |
| Farmer summary, four categorized action groups, and expandable staff detail | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Thai TTS listening quality | PASS — user reports pronunciation is much improved and acceptable | NOT AVAILABLE | NOT AVAILABLE |
| Filter month/activity and inspect export | PASS | NOT AVAILABLE | NOT AVAILABLE |
| Offline relaunch | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |

## Tooling Blockers

1. Android Gradle created a fresh APK but did not return its normal final completion message.
2. Incremental Xcode builds reused an older Flutter `App.framework`; the verified UAT build was rebuilt in a fresh derived-data directory before installation.
3. No Android physical device was visible through ADB, and no physical tablet was connected.

## Required Manual Continuation

Continue the final iPhone check for offline relaunch and persisted data. Start Android only after the iPhone checklist is complete and the user connects and authorizes an Android device through ADB.

The evidence summary is stored at `docs/uat_evidence_20260712_last_phase/device-and-build-summary.txt`.
