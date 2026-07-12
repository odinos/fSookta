# Sookta Last-Phase Physical UAT Report

Date: 2026-07-12  
App version: `1.3.6+21`  
Authoritative requirement matrix: `docs/last-phase-requirement-matrix-20260712.md`

## Executive Result

The code-level requirement audit covers all 19 source requirements. Static analysis passed and the full automated suite passed 102 tests. Portrait-only platform configuration and multiple-person photo rejection were added with regression coverage.

Physical-device UAT could not be completed in this run. An iPhone was initially visible to Flutter, but iOS build/install tooling stalled and CoreDeviceService timed out; the phone was no longer visible through libimobiledevice after the attempt. No physical Android device or physical tablet was connected. Hardware-dependent rows therefore remain `BLOCKED`, `NOT AVAILABLE`, or `PENDING-MANUAL` and are not reported as passed.

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
| iOS no-codesign build | BLOCKED | No fresh artifact; Xcode/CoreDevice tooling stalled |

## Physical UAT Checklist

| UAT step | iPhone | Android | Tablet |
| --- | --- | --- | --- |
| Install and launch current build | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Rotate both directions; app remains portrait | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Two farmers and avatar isolation | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Terminate/relaunch and resume correct draft | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Change activity and retain draft | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Select four photos; replace/remove one | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Reject real multi-person photo | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Final assessment button unobstructed | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Farmer summary and expandable staff detail | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Thai TTS listening quality | PENDING-MANUAL | NOT AVAILABLE | NOT AVAILABLE |
| Filter month/activity and inspect export | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |
| Offline relaunch | BLOCKED | NOT AVAILABLE | NOT AVAILABLE |

## Tooling Blockers

1. Android Gradle created a fresh APK but did not return its normal final completion message.
2. iOS build did not produce a fresh `Runner.app` before the attempt was stopped.
3. `xcrun devicectl` timed out waiting for CoreDeviceService.
4. The iPhone install attempt reached `Installing com.kdev.sookta to iPhone...` but did not complete.
5. After the install attempt, `ideviceinfo` reported the iPhone as not found.
6. No Android physical device was visible through ADB, and no physical tablet was connected.

## Required Manual Continuation

Reconnect and unlock the iPhone, trust the Mac, keep the device awake, and confirm it appears in both Flutter and CoreDevice. Connect and authorize an Android device through ADB. Then repeat the physical checklist above, using a real single-person photo and a real multiple-person photo, listening to Thai TTS, inspecting the native share/export result, and rotating each device to verify portrait lock.

The evidence summary is stored at `docs/uat_evidence_20260712_last_phase/device-and-build-summary.txt`.
