param(
    [string]$ApiBaseUrl = "http://192.168.68.56:8081/api",
    [string]$BuildName = "0.01",
    [int]$BuildNumber = 1,
    [string]$ProjectDir = "UI/playasset_flutter"
)

$ErrorActionPreference = "Stop"

$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$appDir = Join-Path $rootDir $ProjectDir

if (!(Test-Path $appDir)) {
    throw "Flutter 프로젝트 경로를 찾을 수 없습니다: $appDir"
}

Push-Location $appDir
try {
    flutter pub get

    flutter build apk --release `
        --dart-define="API_BASE_URL=$ApiBaseUrl" `
        --build-name="$BuildName" `
        --build-number="$BuildNumber"

    $apkDir = Join-Path $appDir "build/app/outputs/flutter-apk"
    $apkSrc = Join-Path $apkDir "app-release.apk"
    if (!(Test-Path $apkSrc)) {
        throw "APK 빌드 결과를 찾을 수 없습니다: $apkSrc"
    }

    $safeVersion = ($BuildName -replace "[^0-9A-Za-z\.\-_]", "_")
    $apkVersioned = Join-Path $apkDir ("app-release-v{0}+{1}.apk" -f $safeVersion, $BuildNumber)
    Copy-Item $apkSrc $apkVersioned -Force

    Get-Item $apkSrc, $apkVersioned | Select-Object Name, FullName, Length, LastWriteTime
}
finally {
    Pop-Location
}
