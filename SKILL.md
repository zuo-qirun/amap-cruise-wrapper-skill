---
name: patch-amap-cruise-wrapper
description: Patch AMap Auto / AutoNavi Android APKs so CameraLightInfoWrapper cruise traffic-light data is rebroadcast as AUTONAVI_STANDARD_BROADCAST_SEND with full lightsData JSON, lightsCount, clearLights signals, and compatibility extras. Use when modifying 高德地图车机版 APKs for AMap Companion cruise traffic-light countdown support, especially CameraLightInteract.smali / CameraLightInfoWrapper tasks.
---

# Patch AMap Cruise Wrapper

## Purpose

Patch an AMap Auto APK so `CameraLightInteract.notifyCameraLightInfosImpl(wrapper)` keeps the original in-car behavior and additionally broadcasts wrapper data for external receivers such as AMap Companion.

This workflow is based on community/third-party AMap repackaging approaches and the wrapper broadcast pattern observed in existing modified packages. The script in this skill packages the verified steps for this project; it does not claim the underlying wrapper-hook idea as original.

The preferred patch is a hybrid wrapper broadcast:

- `Action`: `AUTONAVI_STANDARD_BROADCAST_SEND`
- `KEY_TYPE`: `0xEAA9`
- `lightsData`: JSON array of every `CameraLightInfo` in `wrapper.a`
- `lightsCount`: wrapper list size
- `clearLights` and `EXTRA_CLEAR_LIGHTS`: `true` when wrapper/list is empty
- Compatibility extras from the first light: `trafficLightStatus`, `redLightCountDownSeconds`, `dir`, `waitRound`, `showType`

Do not replace AMap's internal behavior with a broadcast-only method. Keep the original in-car calls, add the full-list `lightsData` broadcast, add explicit clear signals, and keep first-light compatibility extras for older receivers.

## Quick Workflow

1. Work in an ASCII path when possible.
2. Prefer apktool `2.9.3`. Newer apktool versions such as `3.x` or `2.12.x` may change output size or trigger AMap Auto startup checks.
3. Decode with apktool using `-r` to avoid fragile resource rebuild failures.
4. Patch `smali/com/autonavi/amapauto/CameraLightInfo/CameraLightInteract.smali`.
5. Keep original calls to `CruiseTrafficLightVoice.setCameraLightInfoWrapper(wrapper)` and `vh0.e().a(wrapper)`.
6. Preserve any existing full-feature, startup-check, signature-check, or `ttsSettings.txt` modifications when patching an already-modified APK.
7. Pay special attention to AMap signature/startup checks, including known `b90` check code in some builds. Do not remove a third-party package's existing `b90` bypass or official-signature bypass while adding the wrapper patch.
8. Add helper methods:
   - `buildLightsJson(Ljava/util/List;)Ljava/lang/String;`
   - `sendAmapCompanionCruiseBroadcast(CameraLightInfoWrapper)`
9. Rebuild, zipalign, sign, and verify.

Prefer using `scripts/patch-amap-cruise-wrapper.ps1` for the full flow.

## Script Usage

```powershell
.\scripts\patch-amap-cruise-wrapper.ps1 `
  -InputApk "D:\path\高德地图.apk" `
  -OutputApk "D:\path\高德地图_cruise_lightsdata_clear_signed.apk" `
  -ApktoolJar "D:\path\apktool.jar"
```

Optional parameters:

- `-WorkDir`: temporary decode/build workspace.
- `-BuildToolsDir`: Android SDK build-tools directory containing `zipalign.exe` and `apksigner.bat`.
- `-Keystore`: signing keystore, default `$env:USERPROFILE\.android\debug.keystore`.
- `-KeyAlias`, `-StorePass`, `-KeyPass`: signing credentials.

## Smali Checks

After patching, verify the smali contains:

- `buildLightsJson`
- `sendAmapCompanionCruiseBroadcast`
- `lightsData`
- `lightsCount`
- `clearLights`
- `EXTRA_CLEAR_LIGHTS`
- `if-lt v4, v0, :loop_body` in the JSON loop

The JSON loop must not use the inverted bug `if-lt v4, v0, :loop_end`; that produces `[]` for non-empty lists.

## Validation

At minimum:

```powershell
java -jar apktool.jar b decoded_nores -o unsigned.apk
zipalign -p -f 4 unsigned.apk aligned.apk
apksigner sign --ks debug.keystore --out signed.apk aligned.apk
apksigner verify --verbose signed.apk
```

If installing on a device:

```powershell
adb install -r signed.apk
adb logcat -c
adb shell monkey -p com.autonavi.amapClone -c android.intent.category.LAUNCHER 1
```

Watch for:

- `VerifyError`
- `NoSuchMethodError`
- `ClassCastException`
- `AndroidRuntime`
- `CameraLightInteract`
- AMap Auto startup dialogs such as "please download the official version from amapauto.com"; this usually means the target APK has startup/signature checks that must be preserved or bypassed separately. In some known builds this logic is around `b90`, so inspect and preserve any existing `b90` bypass before rebuilding.

If the rebuilt APK is much larger than expected or fails at startup, retry with apktool `2.9.3` before changing the smali patch.

## Receiver Contract

Receivers should treat `clearLights=true` or `EXTRA_CLEAR_LIGHTS=true` as an immediate clear signal.

For non-empty `lightsData`, parse all entries. Wrapper status values are not always the same as standard navigation traffic-light broadcasts; normalize in the receiver if needed. In the tested Chery/AMap 9.1.0 flow, wrapper status behaved as `0=red`, `1=green`.
