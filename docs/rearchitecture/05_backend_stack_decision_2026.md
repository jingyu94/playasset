# 백엔드 스택 결정 (2026-02-16)

## 결론
- 기본: `Spring MVC + Virtual Threads(JDK 21)`
- 선택: `WebFlux(reactive) 기능을 필요한 구간에서만 사용`

## 적용 이유
- 일반 업무 API는 동기 코드가 개발/운영 난이도가 낮다.
- VT를 통해 블로킹 I/O에서도 높은 동시성을 확보할 수 있다.
- 스트리밍/비동기 체인이 필요한 구간은 Mono/Flux로 별도 처리한다.

## 이번 셋업 반영 내용
- Java 21 / Spring Boot 3.3.x / Gradle 8.10.x
- MVC 서버(Tomcat) 기본 동작
- `spring.threads.virtual.enabled=true` 활성화
- JDBC(MySQL) 기반 DAO로 전환
- 함수형 라우팅 + 컨트롤러 동시 지원
- 리액티브 샘플 엔드포인트 추가
  - `/api/controller/system/reactive-probe`

## 주의사항
- 로컬에서 WSL 포트 포워딩(`wslrelay`)이 8080을 잡고 있으면,
  호스트 `localhost:8080` 요청이 Docker 컨테이너가 아니라 WSL 서비스로 갈 수 있다.
- 이 경우 컨테이너 내부 검증 또는 포트 충돌 해소 후 테스트해야 한다.

