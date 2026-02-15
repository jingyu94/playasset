# Flutter 앱 아키텍처

## 구조
- `lib/core`
  - `config/app_env.dart` 런타임 환경값
  - `network/api_client.dart` API 통신
  - `models/dashboard_models.dart` 모델
  - `theme/app_theme.dart` 공통 테마
- `lib/features/home`
  - `home_shell.dart` 탭 구조
  - `home_providers.dart` Riverpod 상태
  - `widgets/*` 각 탭/컴포넌트

## 화면 구성
- 대시보드
  - KPI 카드
  - 펄스 라인차트
  - 감성 파이차트
  - 상위 포지션
- 관심종목
  - 검색 + 리스트
- 알림
  - Severity 강조 카드
- 설정
  - API 엔드포인트/키 주입 상태

## 디자인 방향
- 밝은 톤 운영 콘솔 스타일
- 그래디언트 + 글로우 배경
- 목적성 있는 타이포(`Noto Sans KR`)
- 정보 밀도 높은 카드 UI

## 환경 주입
- `--dart-define=API_BASE_URL=...`
- `--dart-define=EXTERNAL_MARKET_API_KEY=...`
- `--dart-define=EXTERNAL_NEWS_API_KEY=...`
