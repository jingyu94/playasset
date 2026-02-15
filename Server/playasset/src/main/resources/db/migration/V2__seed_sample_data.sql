INSERT INTO users (user_id, email, display_name, status, created_at, updated_at)
VALUES
  (1001, 'demo@playasset.ai', '데모 투자자', 'ACTIVE', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  status = VALUES(status),
  updated_at = NOW();

INSERT INTO user_auth_credentials (credential_id, user_id, password_hash, hash_algorithm, created_at, updated_at)
VALUES
  (2001, 1001, '$2a$10$replace.with.real.hash.in.production', 'BCRYPT', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  password_hash = VALUES(password_hash),
  updated_at = NOW();

INSERT INTO user_preferences (preference_id, user_id, timezone, locale, push_enabled, email_enabled, created_at, updated_at)
VALUES
  (3001, 1001, 'Asia/Seoul', 'ko-KR', 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  timezone = VALUES(timezone),
  locale = VALUES(locale),
  updated_at = NOW();

INSERT INTO assets (asset_id, symbol, name, market, currency, is_active, created_at, updated_at)
VALUES
  (4001, '005930', '삼성전자', 'KRX', 'KRW', 1, NOW(), NOW()),
  (4002, '000660', 'SK하이닉스', 'KRX', 'KRW', 1, NOW(), NOW()),
  (4003, '035420', 'NAVER', 'KRX', 'KRW', 1, NOW(), NOW()),
  (4004, '051910', 'LG화학', 'KRX', 'KRW', 1, NOW(), NOW()),
  (4005, '035720', '카카오', 'KRX', 'KRW', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  is_active = VALUES(is_active),
  updated_at = NOW();

INSERT INTO asset_aliases (alias_id, asset_id, alias, created_at)
VALUES
  (5001, 4001, '삼성', NOW()),
  (5002, 4002, '하이닉스', NOW()),
  (5003, 4003, '네이버', NOW()),
  (5004, 4004, '엘지화학', NOW()),
  (5005, 4005, '카카오', NOW())
ON DUPLICATE KEY UPDATE
  alias = VALUES(alias);

INSERT INTO watchlists (watchlist_id, user_id, name, is_default, created_at, updated_at)
VALUES
  (6001, 1001, '핵심 관심종목', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  is_default = VALUES(is_default),
  updated_at = NOW();

INSERT INTO watchlist_items (watchlist_item_id, watchlist_id, asset_id, note, created_at)
VALUES
  (7001, 6001, 4001, 'AI 서버 수요 모니터링', NOW()),
  (7002, 6001, 4002, 'HBM 공급 확장 체크', NOW()),
  (7003, 6001, 4003, '광고/커머스 성장 확인', NOW()),
  (7004, 6001, 4004, '배터리 수요 관찰', NOW())
ON DUPLICATE KEY UPDATE
  note = VALUES(note);

INSERT INTO portfolios (portfolio_id, user_id, name, base_currency, created_at, updated_at)
VALUES
  (8001, 1001, '실전 계좌', 'KRW', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  updated_at = NOW();

INSERT INTO portfolio_accounts (account_id, portfolio_id, broker_name, account_label, created_at, updated_at)
VALUES
  (9001, 8001, '샘플증권', '국내주식', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  broker_name = VALUES(broker_name),
  account_label = VALUES(account_label),
  updated_at = NOW();

INSERT INTO portfolio_positions (position_id, account_id, asset_id, quantity, avg_cost, realized_pnl, updated_at)
VALUES
  (10001, 9001, 4001, 22.000000, 75400.000000, 0.000000, NOW()),
  (10002, 9001, 4002, 14.000000, 173500.000000, 0.000000, NOW()),
  (10003, 9001, 4003, 18.000000, 224000.000000, 215000.000000, NOW())
ON DUPLICATE KEY UPDATE
  quantity = VALUES(quantity),
  avg_cost = VALUES(avg_cost),
  realized_pnl = VALUES(realized_pnl),
  updated_at = NOW();

INSERT INTO portfolio_transactions (transaction_id, account_id, asset_id, side, quantity, price, fee, tax, occurred_at, created_at)
VALUES
  (11001, 9001, 4001, 'BUY', 15.000000, 74800.000000, 3000.000000, 0.000000, NOW() - INTERVAL 18 DAY, NOW()),
  (11002, 9001, 4001, 'BUY', 7.000000, 76600.000000, 1800.000000, 0.000000, NOW() - INTERVAL 8 DAY, NOW()),
  (11003, 9001, 4002, 'BUY', 14.000000, 173500.000000, 4200.000000, 0.000000, NOW() - INTERVAL 12 DAY, NOW()),
  (11004, 9001, 4003, 'BUY', 20.000000, 220000.000000, 3800.000000, 0.000000, NOW() - INTERVAL 20 DAY, NOW()),
  (11005, 9001, 4003, 'SELL', 2.000000, 235000.000000, 1600.000000, 1500.000000, NOW() - INTERVAL 2 DAY, NOW())
ON DUPLICATE KEY UPDATE
  occurred_at = VALUES(occurred_at);

INSERT INTO market_price_candles (
  candle_id, asset_id, interval_code, candle_time, open_price, high_price, low_price, close_price, volume, created_at
)
VALUES
  (12001, 4001, '1d', TIMESTAMP(CURRENT_DATE), 75900.000000, 77200.000000, 75300.000000, 76800.000000, 14893000.000000, NOW()),
  (12002, 4002, '1d', TIMESTAMP(CURRENT_DATE), 171000.000000, 178400.000000, 169800.000000, 177100.000000, 6321000.000000, NOW()),
  (12003, 4003, '1d', TIMESTAMP(CURRENT_DATE), 226000.000000, 229500.000000, 223000.000000, 227500.000000, 3124000.000000, NOW()),
  (12004, 4004, '1d', TIMESTAMP(CURRENT_DATE), 396000.000000, 402500.000000, 390200.000000, 400100.000000, 824000.000000, NOW()),
  (12005, 4005, '1d', TIMESTAMP(CURRENT_DATE), 52800.000000, 54200.000000, 52100.000000, 53800.000000, 12430000.000000, NOW())
ON DUPLICATE KEY UPDATE
  open_price = VALUES(open_price),
  high_price = VALUES(high_price),
  low_price = VALUES(low_price),
  close_price = VALUES(close_price),
  volume = VALUES(volume);

INSERT INTO news_sources (source_id, name, site_url, is_active, created_at)
VALUES
  (13001, 'sample-finance-wire', 'https://sample.local', 1, NOW())
ON DUPLICATE KEY UPDATE
  is_active = VALUES(is_active);

INSERT INTO news_articles (
  article_id, source_id, external_id, title, body, language, published_at, ingested_at, created_at
)
VALUES
  (14001, 13001, 'wire-001', '반도체 랠리 재점화, 외국인 매수 확대', '수출 지표 개선과 AI 수요 확대로 반도체 대표주의 실적 기대가 높아졌다.', 'ko', NOW() - INTERVAL 6 HOUR, NOW(), NOW()),
  (14002, 13001, 'wire-002', '인터넷 플랫폼 광고 회복세 지속', '디지털 광고 단가 안정화와 커머스 전환율 개선으로 플랫폼 실적 전망이 상향됐다.', 'ko', NOW() - INTERVAL 4 HOUR, NOW(), NOW()),
  (14003, 13001, 'wire-003', '2차전지 밸류체인 조정 후 반등 시도', '원재료 가격 안정과 수요 정상화 기대가 반영되며 주가 변동성이 확대됐다.', 'ko', NOW() - INTERVAL 3 HOUR, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  body = VALUES(body),
  published_at = VALUES(published_at);

INSERT INTO news_asset_mentions (mention_id, article_id, asset_id, confidence_score, created_at)
VALUES
  (15001, 14001, 4001, 0.9200, NOW()),
  (15002, 14001, 4002, 0.9500, NOW()),
  (15003, 14002, 4003, 0.9100, NOW()),
  (15004, 14003, 4004, 0.8800, NOW()),
  (15005, 14003, 4005, 0.8600, NOW())
ON DUPLICATE KEY UPDATE
  confidence_score = VALUES(confidence_score);

INSERT INTO news_sentiment_scores (score_id, article_id, model_version, sentiment_label, sentiment_score, created_at)
VALUES
  (16001, 14001, 'sent-v1', 'POSITIVE', 0.87200, NOW()),
  (16002, 14002, 'sent-v1', 'POSITIVE', 0.73100, NOW()),
  (16003, 14003, 'sent-v1', 'NEUTRAL', 0.52200, NOW())
ON DUPLICATE KEY UPDATE
  sentiment_label = VALUES(sentiment_label),
  sentiment_score = VALUES(sentiment_score);

INSERT INTO alert_rules (rule_id, user_id, asset_id, rule_type, threshold_json, is_enabled, created_at, updated_at)
VALUES
  (17001, 1001, 4001, 'PRICE_CHANGE', JSON_OBJECT('period', '1d', 'threshold', 2.5), 1, NOW(), NOW()),
  (17002, 1001, 4002, 'VOLUME_SPIKE', JSON_OBJECT('period', '1d', 'threshold', 1.8), 1, NOW(), NOW()),
  (17003, 1001, NULL, 'SENTIMENT', JSON_OBJECT('negative_threshold', 0.65), 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  threshold_json = VALUES(threshold_json),
  is_enabled = VALUES(is_enabled),
  updated_at = NOW();

INSERT INTO alert_events (alert_event_id, rule_id, user_id, asset_id, event_type, title, message, severity, status, occurred_at, created_at)
VALUES
  (18001, 17001, 1001, 4001, 'PRICE_BREAKOUT', '삼성전자 변동성 확대', '전일 대비 +2.9% 상승으로 설정 임계치를 초과했습니다.', 'MEDIUM', 'SENT', NOW() - INTERVAL 1 HOUR, NOW()),
  (18002, 17002, 1001, 4002, 'VOLUME_SPIKE', 'SK하이닉스 거래량 급증', '평균 대비 1.9배 거래량이 발생했습니다.', 'HIGH', 'PENDING', NOW() - INTERVAL 35 MINUTE, NOW()),
  (18003, 17003, 1001, NULL, 'SENTIMENT_SHIFT', '시장 뉴스 감성 모니터링', '최근 24시간 기준 중립/긍정 비중이 상승했습니다.', 'LOW', 'READ', NOW() - INTERVAL 20 MINUTE, NOW())
ON DUPLICATE KEY UPDATE
  message = VALUES(message),
  status = VALUES(status),
  occurred_at = VALUES(occurred_at);

INSERT INTO notification_deliveries (delivery_id, alert_event_id, channel, status, failure_reason, attempted_at, created_at)
VALUES
  (19001, 18001, 'IN_APP', 'SENT', NULL, NOW() - INTERVAL 55 MINUTE, NOW()),
  (19002, 18002, 'PUSH', 'PENDING', NULL, NULL, NOW()),
  (19003, 18003, 'EMAIL', 'SENT', NULL, NOW() - INTERVAL 15 MINUTE, NOW())
ON DUPLICATE KEY UPDATE
  status = VALUES(status),
  attempted_at = VALUES(attempted_at);

INSERT INTO ingestion_jobs (
  job_id, job_type, source_key, window_start, window_end, status, records_in, records_out, error_message, started_at, finished_at, created_at
)
VALUES
  (20001, 'BOOTSTRAP_SAMPLE', 'LOCAL_SEED', NOW() - INTERVAL 1 DAY, NOW(), 'SUCCEEDED', 23, 23, NULL, NOW() - INTERVAL 10 MINUTE, NOW() - INTERVAL 9 MINUTE, NOW())
ON DUPLICATE KEY UPDATE
  status = VALUES(status),
  records_in = VALUES(records_in),
  records_out = VALUES(records_out),
  finished_at = VALUES(finished_at);
