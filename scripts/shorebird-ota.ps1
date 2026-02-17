param(
  [ValidateSet("release", "patch", "status", "doctor")]
  [string]$Mode = "status",
  [string]$BuildName = "0.01",
  [int]$BuildNumber = 1,
  [ValidateSet("aab", "apk")]
  [string]$Artifact = "aab",
  [string]$ReleaseVersion = "latest",
  [string]$Target = "android",
  [string]$Flavor = "",
  [string]$ApiBaseUrl = "",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ShorebirdCli = $null

function Resolve-ShorebirdCli {
  $candidateBat = "C:\Users\$env:USERNAME\.shorebird\bin\shorebird.bat"
  if (Test-Path $candidateBat) {
    return $candidateBat
  }

  $command = Get-Command "shorebird.bat" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $command = Get-Command "shorebird" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  throw "shorebird 실행 파일을 찾을 수 없습니다. Shorebird CLI 설치를 먼저 진행하세요."
}

function New-FlutterArgs {
  param(
    [string]$BuildName,
    [int]$BuildNumber,
    [string]$Artifact,
    [string]$Target,
    [string]$Flavor,
    [string]$ApiBaseUrl
  )

  $args = @(
    "--platforms=$Target",
    "--artifact=$Artifact",
    "--build-name=$BuildName",
    "--build-number=$BuildNumber",
    "--no-confirm"
  )

  if ($Flavor -ne "") {
    $args += "--flavor=$Flavor"
  }
  if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $args += "--dart-define=API_BASE_URL=$ApiBaseUrl"
  }
  if ($DryRun) {
    $args += "--dry-run"
  }
  return $args
}

function Resolve-ApiBaseUrl {
  param(
    [string]$InputValue
  )

  if (-not [string]::IsNullOrWhiteSpace($InputValue)) {
    return $InputValue.Trim()
  }

  if (-not [string]::IsNullOrWhiteSpace($env:PLAYASSET_API_BASE_URL)) {
    return $env:PLAYASSET_API_BASE_URL.Trim()
  }

  throw "API_BASE_URL이 비어 있습니다. -ApiBaseUrl 또는 PLAYASSET_API_BASE_URL 환경 변수를 지정하세요."
}

function Build-SideloadApk {
  param(
    [string]$ApiBaseUrl,
    [string]$Flavor
  )

  $flutterArgs = @(
    "build",
    "apk",
    "--release",
    "--dart-define=API_BASE_URL=$ApiBaseUrl"
  )
  if ($Flavor -ne "") {
    $flutterArgs += "--flavor=$Flavor"
  }
  Write-Host "== sideload apk build 시작 =="
  & flutter $flutterArgs
}

Set-Location -Path "c:\workspace\PlayAsset"
if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
  throw "명령어를 찾을 수 없습니다: flutter"
}
$ShorebirdCli = Resolve-ShorebirdCli

switch ($Mode) {
  "doctor" {
    Write-Host "== shorebird doctor =="
    & $ShorebirdCli doctor
    exit 0
  }
  "status" {
    Write-Host "== shorebird status =="
    & $ShorebirdCli doctor
    Write-Host ""
    Write-Host "패치/릴리즈 이력은 Shorebird Console에서 확인하세요."
    Write-Host "https://console.shorebird.dev"
    exit 0
  }
  "release" {
    Write-Host "== shorebird release 시작 =="
    Push-Location "UI/playasset_flutter"
    try {
      flutter pub get
      $resolvedApiBaseUrl = Resolve-ApiBaseUrl -InputValue $ApiBaseUrl
      Write-Host "API_BASE_URL=$resolvedApiBaseUrl"
      $releaseArgs = New-FlutterArgs -BuildName $BuildName -BuildNumber $BuildNumber -Artifact $Artifact -Target $Target -Flavor $Flavor -ApiBaseUrl $resolvedApiBaseUrl
      & $ShorebirdCli release $releaseArgs
      Build-SideloadApk -ApiBaseUrl $resolvedApiBaseUrl -Flavor $Flavor
    }
    finally {
      Pop-Location
    }
    exit 0
  }
  "patch" {
    Write-Host "== shorebird patch 시작 =="
    Push-Location "UI/playasset_flutter"
    try {
      flutter pub get
      $resolvedApiBaseUrl = Resolve-ApiBaseUrl -InputValue $ApiBaseUrl
      Write-Host "API_BASE_URL=$resolvedApiBaseUrl"
      $patchArgs = @(
        "--platforms=$Target",
        "--release-version=$ReleaseVersion",
        "--no-confirm",
        "--allow-asset-diffs",
        "--dart-define=API_BASE_URL=$resolvedApiBaseUrl"
      )
      if ($Flavor -ne "") {
        $patchArgs += "--flavor=$Flavor"
      }
      if ($DryRun) {
        $patchArgs += "--dry-run"
      }
      & $ShorebirdCli patch $patchArgs
    }
    finally {
      Pop-Location
    }
    exit 0
  }
}
