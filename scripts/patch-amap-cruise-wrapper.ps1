param(
    [Parameter(Mandatory = $true)]
    [string] $InputApk,

    [Parameter(Mandatory = $true)]
    [string] $OutputApk,

    [Parameter(Mandatory = $true)]
    [string] $ApktoolJar,

    [string] $WorkDir = (Join-Path $PWD "work"),
    [string] $BuildToolsDir = "",
    [string] $Keystore = (Join-Path $env:USERPROFILE ".android\debug.keystore"),
    [string] $KeyAlias = "androiddebugkey",
    [string] $StorePass = "android",
    [string] $KeyPass = "android"
)

$ErrorActionPreference = "Stop"

function Resolve-BuildToolsDir {
    param([string] $Explicit)
    if ($Explicit) {
        return (Resolve-Path -LiteralPath $Explicit).Path
    }
    $sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
    $root = Join-Path $sdk "build-tools"
    $latest = Get-ChildItem -LiteralPath $root -Directory |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if (!$latest) {
        throw "No Android build-tools found under $root"
    }
    return $latest.FullName
}

function Replace-Method {
    param(
        [string] $Text,
        [string] $MethodHeaderRegex,
        [string] $Replacement
    )
    $pattern = "(?s)$MethodHeaderRegex.*?\.end method"
    if ($Text -notmatch $pattern) {
        throw "Could not find method matching $MethodHeaderRegex"
    }
    return [regex]::Replace($Text, $pattern, $Replacement, 1)
}

function Insert-AfterConstructor {
    param([string] $Text, [string] $Insertion)
    if ($Text -match "buildLightsJson\(Ljava/util/List;\)Ljava/lang/String;") {
        return $Text
    }
    $pattern = "(?s)(\.method public constructor <init>\(\)V.*?\.end method)"
    if ($Text -notmatch $pattern) {
        throw "Could not find default constructor"
    }
    return [regex]::Replace($Text, $pattern, "`$1`r`n`r`n$Insertion", 1)
}

$buildTools = Resolve-BuildToolsDir $BuildToolsDir
$zipalign = Join-Path $buildTools "zipalign.exe"
$apksigner = Join-Path $buildTools "apksigner.bat"
foreach ($path in @($InputApk, $ApktoolJar, $zipalign, $apksigner, $Keystore)) {
    if (!(Test-Path -LiteralPath $path)) {
        throw "Required file not found: $path"
    }
}

$decoded = Join-Path $WorkDir "decoded_nores"
$unsigned = Join-Path $WorkDir "patched_unsigned.apk"
$aligned = Join-Path $WorkDir "patched_aligned.apk"

if (Test-Path -LiteralPath $WorkDir) {
    Remove-Item -LiteralPath $WorkDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

java -jar $ApktoolJar d -r -f $InputApk -o $decoded
if ($LASTEXITCODE -ne 0) { throw "apktool decode failed" }

$smaliPath = Join-Path $decoded "smali\com\autonavi\amapauto\CameraLightInfo\CameraLightInteract.smali"
if (!(Test-Path -LiteralPath $smaliPath)) {
    throw "CameraLightInteract.smali not found at $smaliPath"
}

$buildLightsJson = @'
.method private static buildLightsJson(Ljava/util/List;)Ljava/lang/String;
    .locals 8
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/List<",
            "Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;",
            ">;)",
            "Ljava/lang/String;"
        }
    .end annotation

    invoke-interface {p0}, Ljava/util/List;->size()I
    move-result v0
    mul-int/lit8 v1, v0, 0x50
    add-int/lit8 v1, v1, 0x2
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2, v1}, Ljava/lang/StringBuilder;-><init>(I)V
    const/16 v3, 0x5b
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;
    const/4 v4, 0x0

    :loop_start
    if-lt v4, v0, :loop_body
    goto :loop_end

    :loop_body
    if-eqz v4, :not_first
    const/16 v3, 0x2c
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    :not_first
    invoke-interface {p0, v4}, Ljava/util/List;->get(I)Ljava/lang/Object;
    move-result-object v5
    check-cast v5, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;
    const-string v6, "{\"status\":"
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget v7, v5, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->d:I
    invoke-virtual {v2, v7}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v6, ",\"countdown\":"
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget v7, v5, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->e:I
    invoke-virtual {v2, v7}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v6, ",\"dir\":"
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget v7, v5, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->c:I
    invoke-virtual {v2, v7}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v6, ",\"waitNum\":"
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget v7, v5, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->a:I
    invoke-virtual {v2, v7}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v6, ",\"showType\":"
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    iget v7, v5, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->f:I
    invoke-virtual {v2, v7}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const/16 v6, 0x7d
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;
    add-int/lit8 v4, v4, 0x1
    goto :loop_start

    :loop_end
    const/16 v3, 0x5d
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method
'@

$notifyMethod = @'
.method public static notifyCameraLightInfosImpl(Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfoWrapper;)V
    .locals 1

    invoke-static {p0}, Lfloatapp/trafficlight/CruiseTrafficLightVoice;->setCameraLightInfoWrapper(Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfoWrapper;)V
    invoke-static {p0}, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInteract;->sendAmapCompanionCruiseBroadcast(Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfoWrapper;)V
    invoke-static {}, Lvh0;->e()Lvh0;
    move-result-object v0
    invoke-virtual {v0, p0}, Lvh0;->a(Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfoWrapper;)V
    return-void
.end method
'@

$sendMethod = @'
.method private static sendAmapCompanionCruiseBroadcast(Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfoWrapper;)V
    .locals 8

    :try_start
    invoke-static {}, Landroid/app/ActivityThread;->currentApplication()Landroid/app/Application;
    move-result-object v1
    if-eqz v1, :return_void
    new-instance v2, Landroid/content/Intent;
    const-string v3, "AUTONAVI_STANDARD_BROADCAST_SEND"
    invoke-direct {v2, v3}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
    const-string v3, "KEY_TYPE"
    const v4, 0xeaa9
    invoke-virtual {v2, v3, v4}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    if-eqz p0, :send_clear
    iget-object v0, p0, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfoWrapper;->a:Ljava/util/List;
    if-eqz v0, :send_clear
    invoke-interface {v0}, Ljava/util/List;->isEmpty()Z
    move-result v3
    if-nez v3, :send_clear
    const/4 v3, 0x0
    invoke-interface {v0, v3}, Ljava/util/List;->get(I)Ljava/lang/Object;
    move-result-object v3
    check-cast v3, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;
    const-string v4, "trafficLightStatus"
    iget v5, v3, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->d:I
    invoke-virtual {v2, v4, v5}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    const-string v4, "redLightCountDownSeconds"
    iget v5, v3, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->e:I
    invoke-virtual {v2, v4, v5}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    const-string v4, "dir"
    iget v5, v3, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->c:I
    invoke-virtual {v2, v4, v5}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    const-string v4, "waitRound"
    iget v5, v3, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->a:I
    invoke-virtual {v2, v4, v5}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    const-string v4, "showType"
    iget v5, v3, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfo;->f:I
    invoke-virtual {v2, v4, v5}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    invoke-static {v0}, Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInteract;->buildLightsJson(Ljava/util/List;)Ljava/lang/String;
    move-result-object v6
    const-string v4, "lightsData"
    invoke-virtual {v2, v4, v6}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    const-string v4, "lightsCount"
    invoke-interface {v0}, Ljava/util/List;->size()I
    move-result v7
    invoke-virtual {v2, v4, v7}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    const-string v4, "clearLights"
    const/4 v7, 0x0
    invoke-virtual {v2, v4, v7}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;
    invoke-virtual {v1, v2}, Landroid/app/Application;->sendBroadcast(Landroid/content/Intent;)V
    goto :return_void

    :send_clear
    const-string v4, "lightsData"
    const-string v5, "[]"
    invoke-virtual {v2, v4, v5}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    const-string v4, "lightsCount"
    const/4 v7, 0x0
    invoke-virtual {v2, v4, v7}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    const-string v4, "clearLights"
    const/4 v7, 0x1
    invoke-virtual {v2, v4, v7}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;
    const-string v4, "EXTRA_CLEAR_LIGHTS"
    invoke-virtual {v2, v4, v7}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;
    invoke-virtual {v1, v2}, Landroid/app/Application;->sendBroadcast(Landroid/content/Intent;)V
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :catch_all
    goto :return_void

    :catch_all
    move-exception v0

    :return_void
    return-void
.end method
'@

$smali = [System.IO.File]::ReadAllText($smaliPath)
$smali = Insert-AfterConstructor $smali $buildLightsJson
$smali = Replace-Method $smali "\.method public static notifyCameraLightInfosImpl\(Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfoWrapper;\)V" $notifyMethod
if ($smali -notmatch "\.method private static sendAmapCompanionCruiseBroadcast\(Lcom/autonavi/amapauto/CameraLightInfo/CameraLightInfoWrapper;\)V") {
    $smali = $smali.TrimEnd() + "`r`n`r`n" + $sendMethod + "`r`n"
}
[System.IO.File]::WriteAllText($smaliPath, $smali, [System.Text.UTF8Encoding]::new($false))

java -jar $ApktoolJar b $decoded -o $unsigned
if ($LASTEXITCODE -ne 0) { throw "apktool build failed" }

& $zipalign -p -f 4 $unsigned $aligned
if ($LASTEXITCODE -ne 0) { throw "zipalign failed" }

& $apksigner sign --ks $Keystore --ks-key-alias $KeyAlias --ks-pass "pass:$StorePass" --key-pass "pass:$KeyPass" --out $OutputApk $aligned
if ($LASTEXITCODE -ne 0) { throw "apksigner sign failed" }

& $apksigner verify --verbose $OutputApk
if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed" }

Write-Host "Patched APK: $OutputApk"
