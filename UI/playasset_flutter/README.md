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
