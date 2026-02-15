# 목표 아키텍처 (2026)

## 1. 아키텍처 전략
- 전환 방향: `모듈형 모놀리스 -> 마이크로서비스`
- 이유
  - 초기에는 개발 속도 확보
  - 계약(API/Event) 안정화 후 도메인 단위 분리

## 2. 논리 토폴로지
```text
[모바일/웹 BFF]
       |
 [API Gateway]
   |    |    |
   |    |    +----------------------+
   |    |                           |
[Identity] [Portfolio] [Insight] [Notification]
              |          ^
              v          |
            [Market]   [News]
                 \      /
                [Event Bus]
```

## 3. 1차 서비스 분리안
- `identity-service`
  - 회원가입/로그인/토큰/권한/환경설정
- `portfolio-service`
  - 포트폴리오/계좌/포지션/거래
- `market-service`
  - 종목마스터/캔들/장 상태
- `news-service`
  - 기사 수집/종목 매핑/감성분석
- `insight-service`
  - 시그널 점수화/알림 규칙 평가
- `notification-service`
  - 인앱/이메일 발송, 재시도, 결과저장
- `api-gateway` 또는 `bff-service`
  - 인증 전파, 응답 조합

## 4. 데이터 소유 원칙
- 프로덕션 목표는 서비스별 독립 스키마.
- 서비스 간 테이블 직접 조회 금지.
- 교차 접근은 다음만 허용.
  - 동기 API 조회
  - 이벤트 구독 기반 상태 반영

## 5. 최소 이벤트 계약
- `portfolio.transaction.created`
- `market.price.updated`
- `news.article.analyzed`
- `insight.signal.created`
- `notification.delivery.requested`
- 공통 Envelope
  - `event_id`, `event_type`, `occurred_at`, `producer`, `version`, `payload`

## 6. API/통신 원칙
- 외부: REST + JSON
- 내부 비동기: Kafka/Redpanda
- 멱등성: 쓰기 API에 `Idempotency-Key`
- 버전: `/api/v1/...` URI 버전 고정

## 7. 보안 기준
- OAuth2.1/OIDC 기반 인증
- 비밀번호 해시: Argon2id 또는 BCrypt
- 서비스 간 인증: 단기 JWT 또는 mTLS
- 비밀값: 코드 저장소 보관 금지

## 8. 관측성 기준
- OpenTelemetry 추적
- Prometheus 메트릭
- 요청 상관관계 ID 기반 중앙 로그
- SLO 대시보드
  - API p95, 에러율, 컨슈머 랙, 알림 발송 성공률

## 9. 권장 기술 스택
- Java 21 + Spring Boot 3.x
- 동기 기본(MVC + VT), 스트림 구간은 Reactive 선택
- MySQL 8 (트랜잭션 저장소)
- Redis (캐시/세션/레이트리밋)
- Kafka/Redpanda (이벤트 파이프라인)

