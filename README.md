# Patch AMap Cruise Wrapper Skill

This repository is a portable AI-agent skill for patching AMap Auto / AutoNavi APKs so cruise traffic-light wrapper data can be consumed by AMap Companion.

The wrapper patching method is based on community/third-party AMap repackaging approaches. This repository documents and automates the specific implementation verified for AMap Companion: broadcasting `CameraLightInfoWrapper` as `lightsData` JSON plus clear signals.

## AI Prompt

Use this prompt with Codex or Claude Code:

```text
Use $patch-amap-cruise-wrapper to patch this AMap Auto APK so AMap Companion can read cruise traffic-light wrapper data.
```

If the agent does not auto-discover the skill, point it at this repository path and ask it to read `SKILL.md`.

## Compatibility

This repository is both Codex-skill and Claude Code-skill compatible because the skill lives at the repository root and uses the standard `SKILL.md` layout.

For Codex, clone or install this folder as a Codex skill.

For Claude Code, clone it into one of these locations:

```text
~/.claude/skills/patch-amap-cruise-wrapper
<project>/.claude/skills/patch-amap-cruise-wrapper
```

Claude Code and Codex can both use the bundled PowerShell script:

```powershell
.\scripts\patch-amap-cruise-wrapper.ps1 `
  -InputApk "D:\path\高德地图.apk" `
  -OutputApk "D:\path\高德地图_cruise_lightsdata_clear_signed.apk" `
  -ApktoolJar "D:\path\apktool.jar"
```

## Principle

AMap Auto receives cruise traffic-light data through `CameraLightInfoWrapper`. The original flow updates internal car UI components, but external companion apps usually cannot read the full wrapper list.

This skill patches:

```text
com/autonavi/amapauto/CameraLightInfo/CameraLightInteract.smali
```

The patched method keeps original behavior:

```text
CruiseTrafficLightVoice.setCameraLightInfoWrapper(wrapper)
vh0.e().a(wrapper)
```

It also sends:

```text
Action: AUTONAVI_STANDARD_BROADCAST_SEND
KEY_TYPE: 0xEAA9
lightsData: [{"status":0,"countdown":18,"dir":1,"waitNum":0,"showType":...}, ...]
lightsCount: list size
clearLights / EXTRA_CLEAR_LIGHTS: true when wrapper or wrapper.a is empty
```

Receivers can parse every item in `lightsData`, so left-turn and straight lights at the same junction can be displayed at the same time.

## Download

The verified patched AMap 9.1.0.600087 build is attached to the release:

```text
https://github.com/zuo-qirun/amap-cruise-wrapper-skill/releases/tag/v20260519-cruise-wrapper
```

Repository mirror/proxy for regions where GitHub is unstable:

```text
https://gh.llkk.cc/https://github.com/zuo-qirun/amap-cruise-wrapper-skill
```

Direct APK:

```text
https://github.com/zuo-qirun/amap-cruise-wrapper-skill/releases/download/v20260519-cruise-wrapper/_9.1.0.600087_cruise_lightsdata_clear_signed.apk
```

Mirror/proxy direct APK for regions where GitHub is unstable:

```text
https://gh.llkk.cc/https://github.com/zuo-qirun/amap-cruise-wrapper-skill/releases/download/v20260519-cruise-wrapper/_9.1.0.600087_cruise_lightsdata_clear_signed.apk
```
