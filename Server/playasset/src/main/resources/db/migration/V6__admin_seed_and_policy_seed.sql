INSERT INTO users (user_id, email, display_name, status, created_at, updated_at)
VALUES
  (1999, 'admin', 'Platform Admin', 'ACTIVE', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  status = VALUES(status),
  updated_at = NOW();

INSERT INTO user_auth_credentials (credential_id, user_id, password_hash, hash_algorithm, created_at, updated_at)
VALUES
  (2999, 1999, 'admin', 'PLAINTEXT', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  password_hash = VALUES(password_hash),
  hash_algorithm = VALUES(hash_algorithm),
  updated_at = NOW();

INSERT INTO user_roles (user_id, role_code)
VALUES
  (1999, 'ADMIN'),
  (1999, 'USER'),
  (1001, 'USER')
ON DUPLICATE KEY UPDATE
  role_code = VALUES(role_code);

INSERT INTO paid_service_policies (service_key, display_name, daily_limit, is_enabled)
VALUES
  ('DASHBOARD_READ', '대시보드 조회', 5000, 1),
  ('POSITIONS_READ', '보유자산 조회', 5000, 1),
  ('WATCHLIST_READ', '관심종목 조회', 5000, 1),
  ('ALERTS_READ', '알림 조회', 5000, 1),
  ('PORTFOLIO_ADVICE', 'AI 인사이트 생성', 1200, 1),
  ('PORTFOLIO_SIMULATION', '기간 수익 시뮬레이션', 1200, 1),
  ('MARKET_BATCH_REFRESH', '시세 갱신 배치', 1500, 1),
  ('NEWS_BATCH_REFRESH', '뉴스/감성 갱신 배치', 1500, 1)
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  daily_limit = VALUES(daily_limit),
  is_enabled = VALUES(is_enabled),
  updated_at = NOW();
