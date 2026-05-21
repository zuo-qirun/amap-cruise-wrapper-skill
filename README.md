# 高德巡航红绿灯 Wrapper 补丁 Skill

这个仓库是一个可移植的 AI Agent skill，用于修改高德地图车机版 / AMap Auto APK，让巡航红绿灯的 `CameraLightInfoWrapper` 数据可以被 AMap Companion 读取。

本方法参考了社区和第三方高德改包方案中的 wrapper 挂钩与广播思路。本仓库只是把已经在 AMap Companion 项目中验证过的具体流程整理、文档化并脚本化，不声明底层改包思路为原创。

## 给 AI 的提示词

在 Codex 或 Claude Code 中可以这样提示：

```text
Use $patch-amap-cruise-wrapper to patch this AMap Auto APK so AMap Companion can read cruise traffic-light wrapper data.
```

如果 AI 没有自动发现 skill，请把它指向本仓库路径，并要求读取 `SKILL.md`。

## 兼容性

本仓库同时兼容 Codex skill 和 Claude Code skill，因为 skill 文件位于仓库根目录，并使用标准 `SKILL.md` 布局。

Codex 使用方式：

- 将本仓库克隆或安装到 Codex skills 目录。
- 在任务中引用 `$patch-amap-cruise-wrapper`。

Claude Code 使用方式：

```text
~/.claude/skills/patch-amap-cruise-wrapper
<project>/.claude/skills/patch-amap-cruise-wrapper
```

Codex 和 Claude Code 都可以调用仓库内的 PowerShell 脚本：

```powershell
.\scripts\patch-amap-cruise-wrapper.ps1 `
  -InputApk "D:\path\高德地图.apk" `
  -OutputApk "D:\path\高德地图_cruise_lightsdata_clear_signed.apk" `
  -ApktoolJar "D:\path\apktool.jar"
```

## 原理

高德地图车机版在巡航时会通过 `CameraLightInfoWrapper` 接收红绿灯数据。原始流程通常只更新高德内部语音、车机 UI 或仪表相关组件，外部伴侣应用无法稳定读取完整的多方向红绿灯列表。

这个 skill 修改的核心文件是：

```text
com/autonavi/amapauto/CameraLightInfo/CameraLightInteract.smali
```

补丁会保留原始行为：

```text
CruiseTrafficLightVoice.setCameraLightInfoWrapper(wrapper)
vh0.e().a(wrapper)
```

同时额外发送广播：

```text
Action: AUTONAVI_STANDARD_BROADCAST_SEND
KEY_TYPE: 0xEAA9
lightsData: [{"status":0,"countdown":18,"dir":1,"waitNum":0,"showType":...}, ...]
lightsCount: 列表数量
clearLights / EXTRA_CLEAR_LIGHTS: wrapper 或 wrapper.a 为空时为 true
```

接收方解析 `lightsData` 中的每一项，就可以在同一路口同时显示左转、直行等多个方向的红绿灯。

## 下载

已验证的高德地图 9.1.0.600087 改包版本在 Release 中：

```text
https://github.com/zuo-qirun/amap-cruise-wrapper-skill/releases/tag/v20260519-cruise-wrapper
```

仓库 ZIP 镜像，适合 GitHub 访问不稳定地区下载 skill：

```text
https://gh-proxy.com/https://github.com/zuo-qirun/amap-cruise-wrapper-skill/archive/refs/heads/master.zip
```

已改高德 APK 原站：

```text
https://github.com/zuo-qirun/amap-cruise-wrapper-skill/releases/download/v20260519-cruise-wrapper/_9.1.0.600087_cruise_lightsdata_clear_signed.apk
```

已改高德 APK 镜像：

```text
https://gh.llkk.cc/https://github.com/zuo-qirun/amap-cruise-wrapper-skill/releases/download/v20260519-cruise-wrapper/_9.1.0.600087_cruise_lightsdata_clear_signed.apk
```

## 注意事项

- 建议在 ASCII 路径下解包、构建和签名，减少 apktool、build-tools 或脚本对中文路径的兼容问题。
- 本项目本地验证使用 `apktool 2.9.3`。如果使用 `apktool 3.x`、`2.12.x` 等版本后出现 APK 体积明显变大、安装后无法启动等问题，请先换回 `2.9.3` 重新解包和构建。
- 如果安装后弹出“应用出现异常错误，无法正常使用，请到 amapauto.com 官网下载使用正式版本重新安装”，通常说明目标高德 APK 存在启动校验或签名校验。此时需要先处理或保留原改版里的校验绕过逻辑，再叠加本 skill 的 wrapper 广播补丁。
- 修改 APK 前请自行确认授权、合规性和实际使用风险。
- 不同高德版本、车型包和 ROM 可能存在 smali 类名或字段差异；脚本适用于已验证的目标结构，遇到差异时需要人工复核。
- 对其它用户的“全功能改版”APK 叠加补丁时，要提醒 AI 保留原有全功能逻辑、`ttsSettings.txt` 行为、启动校验绕过和签名校验绕过，只新增巡航红绿灯 wrapper 广播逻辑。
- AMap Companion 侧应优先解析 `lightsData`，并把 `clearLights=true` 或 `EXTRA_CLEAR_LIGHTS=true` 当作立即清除旧倒计时的信号。
