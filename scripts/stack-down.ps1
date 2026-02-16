param(
  [switch]$Purge
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw "필수 명령어가 없습니다: docker"
}

$composeArgs = @("compose", "-f", "docker-compose.yml")

Write-Host "[PlayAsset] 스택 종료..." -ForegroundColor Cyan

$downArgs = @("down")
if ($Purge) {
  $downArgs += @("--volumes", "--remove-orphans")
}

& docker @composeArgs @downArgs

if ($Purge) {
  Write-Host "[PlayAsset] 종료 + 볼륨 정리 완료" -ForegroundColor Yellow
} else {
  Write-Host "[PlayAsset] 종료 완료 (데이터 볼륨 유지)" -ForegroundColor Green
}

