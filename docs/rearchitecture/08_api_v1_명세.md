# API v1 명세 (요약)

## 공통
- Base URL: `http://{host}:8080`
- 응답 래퍼
  - 성공: `{ "success": true, "timestamp": "...", "data": ... }`
  - 실패: `{ "success": false, "timestamp": "...", "error": "...", "message": "..." }`

## 1) 대시보드 조회
- `GET /api/v1/users/{userId}/dashboard`
- 설명
  - 포트폴리오 요약, 감성 집계, 상위 포지션/모버 조회

## 2) 포지션 조회
- `GET /api/v1/users/{userId}/portfolio/positions`
- 설명
  - 사용자 포지션 목록(평가금액 기준 정렬)

## 3) 관심종목 조회
- `GET /api/v1/users/{userId}/watchlist`
- 설명
  - 기본 워치리스트 종목/가격/변동률/메모 반환

## 4) 알림 조회
- `GET /api/v1/users/{userId}/alerts?limit=20`
- 설명
  - 최근 알림 이벤트 반환

## 5) 거래 등록
- `POST /api/v1/users/{userId}/portfolio/transactions`
- Request 예시
```json
{
  "accountId": 9001,
  "assetId": 4001,
  "side": "BUY",
  "quantity": 1,
  "price": 77000,
  "fee": 0,
  "tax": 0
}
```
- 설명
  - 거래 원장 등록 후 포지션 수량/평단/실현손익 자동 갱신

## 6) 운영 상태
- `GET /actuator/health`
- `GET /actuator/prometheus`
- `GET /api/controller/system/runtime-profile`
