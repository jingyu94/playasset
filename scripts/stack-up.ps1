param(
  [switch]$NoBuild,
  [switch]$Pull
)

$ErrorActionPreference = "Stop"

function Assert-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "필수 명령어가 없습니다: $Name"
  }
}

Write-Host "[PlayAsset] 스택 기동 시작..." -ForegroundColor Cyan

Assert-Command "docker"

try {
  docker info *> $null
} catch {
  throw "Docker Desktop(또는 Docker Engine)이 실행 중이 아닙니다."
}

$composeArgs = @("compose", "-f", "docker-compose.yml")

if ($Pull) {
  Write-Host "[PlayAsset] 이미지 Pull..." -ForegroundColor Yellow
  & docker @composeArgs pull
}

$upArgs = @("up", "-d")
if (-not $NoBuild) {
  $upArgs += "--build"
}

Write-Host "[PlayAsset] 컨테이너 기동..." -ForegroundColor Yellow
& docker @composeArgs @upArgs

Write-Host ""
Write-Host "[PlayAsset] 기동 완료" -ForegroundColor Green
Write-Host " - Web       : http://localhost:3000"
Write-Host " - API       : http://localhost:8081"
Write-Host " - Kafka UI  : http://localhost:9090"
Write-Host " - MySQL     : localhost:3306"
Write-Host " - Redis     : localhost:6379"
Write-Host ""
Write-Host "상태 확인: docker compose ps"

