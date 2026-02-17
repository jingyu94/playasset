# PlayAsset Flutter 앱

## 실행 방법
1. Flutter SDK 설치 후 `flutter doctor`가 모두 통과되는지 확인합니다.
2. 프로젝트 경로로 이동합니다.
   - `cd UI/playasset_flutter`
3. 의존성을 설치합니다.
   - `flutter pub get`
4. 로컬 개발 서버 실행
   - 백엔드 직접 호출: `flutter run -d web-server --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8081/api`
   - Nginx 프록시 기준: `flutter run -d web-server --web-port 3000 --dart-define=API_BASE_URL=/api`

## 컨테이너 실행 (권장)
루트 경로에서 아래 명령으로 DB/백엔드/웹을 한 번에 실행합니다.
- `docker compose up -d --build`

접속 주소
- 웹: `http://localhost:3000`
- 백엔드 헬스체크: `http://localhost:8081/actuator/health`

## 환경 변수
- `API_BASE_URL` (기본값 `/api`)
- `EXTERNAL_MARKET_API_KEY` (기본값 빈 문자열)
- `EXTERNAL_NEWS_API_KEY` (기본값 빈 문자열)

외부 API 키는 코드에 넣지 말고 CI/CD 시크릿 또는 배포 환경 변수로 주입하세요.

도커 컴포즈 로컬 실행 시:
1. 루트에서 `.env.example`을 `.env`로 복사
2. `.env`에 실제 키 입력 (`EXTERNAL_MARKET_API_KEY`)
3. `docker compose up -d --build`

`.env`는 루트 `.gitignore`에 등록되어 커밋되지 않습니다.

### 배치 동기화 운영
- 시세 배치: 5분 간격 (`APP_BATCH_MARKET_REFRESH_MS`)
- 심볼 동기화 배치: 기본 `매일 07:30, 20:30 (Asia/Seoul)` (`APP_BATCH_SYMBOL_SYNC_CRON`)
- 국내(KR) 시세: 네이버 fchart 무료 소스(키 불필요)
- 미국(US) 시세: Twelve Data (`EXTERNAL_MARKET_API_KEY` 필요)
- 관리자 수동 실행 API:
  - `POST /api/v1/admin/jobs/symbol-sync?maxSymbols=3000`
  - `POST /api/v1/admin/jobs/market-refresh`
  - `POST /api/v1/admin/jobs/news-refresh`

## 버전 APK 빌드
루트 경로에서 버전/빌드번호를 지정해 APK를 생성할 수 있습니다.

- 기본(0.01+1):
  - `powershell -ExecutionPolicy Bypass -File scripts/build-apk-versioned.ps1`
- 예시(0.02+2):
  - `powershell -ExecutionPolicy Bypass -File scripts/build-apk-versioned.ps1 -BuildName 0.02 -BuildNumber 2`

생성 파일
- 기본 출력: `UI/playasset_flutter/build/app/outputs/flutter-apk/app-release.apk`
- 버전 라벨 출력: `UI/playasset_flutter/build/app/outputs/flutter-apk/app-release-v<버전>+<빌드번호>.apk`

## OTA 패치(Shorebird)
프로덕션에서 Dart 코드 변경을 APK 재설치 없이 배포하려면 OTA를 사용합니다.

사전 준비
- Shorebird CLI 설치/로그인
  - `shorebird --version`
  - `shorebird login`
- 앱 연결(최초 1회)
  - `shorebird init`

로컬 실행(루트 경로 기준)
- 상태 확인:
  - `powershell -ExecutionPolicy Bypass -File scripts/shorebird-ota.ps1 -Mode status`
- 기준 릴리즈:
  - `powershell -ExecutionPolicy Bypass -File scripts/shorebird-ota.ps1 -Mode release -ApiBaseUrl http://192.168.68.56:8081/api -BuildName 0.01 -BuildNumber 1`
- OTA 패치:
  - `powershell -ExecutionPolicy Bypass -File scripts/shorebird-ota.ps1 -Mode patch -ApiBaseUrl http://192.168.68.56:8081/api -ReleaseVersion latest`
- 사전 검증만 수행(dry-run):
  - `powershell -ExecutionPolicy Bypass -File scripts/shorebird-ota.ps1 -Mode patch -ApiBaseUrl http://192.168.68.56:8081/api -ReleaseVersion latest -DryRun`

주의
- 네이티브 변경(`android/`, 권한, 플러그인 바이너리)은 OTA 대상이 아니며 스토어 재배포가 필요합니다.
- 운영 상세 가이드는 `docs/rearchitecture/18_OTA_운영가이드_2026.md`를 참고하세요.
