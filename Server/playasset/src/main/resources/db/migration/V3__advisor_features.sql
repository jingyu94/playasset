CREATE TABLE IF NOT EXISTS asset_classifications (
  classification_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  asset_id BIGINT UNSIGNED NOT NULL,
  category_code VARCHAR(40) NOT NULL,
  category_name VARCHAR(80) NOT NULL,
  risk_bucket ENUM('LOW', 'MID', 'HIGH') NOT NULL DEFAULT 'MID',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (classification_id),
  UNIQUE KEY uq_asset_classifications_asset_id (asset_id),
  KEY idx_asset_classifications_category_code (category_code),
  CONSTRAINT fk_asset_classifications_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS advisor_etf_catalog (
  etf_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  symbol VARCHAR(32) NOT NULL,
  name VARCHAR(120) NOT NULL,
  market VARCHAR(32) NOT NULL,
  focus_theme VARCHAR(120) NOT NULL,
  risk_bucket ENUM('LOW', 'MID', 'HIGH') NOT NULL DEFAULT 'MID',
  diversification_role VARCHAR(255) NOT NULL,
  expense_ratio_pct DECIMAL(8,4) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (etf_id),
  UNIQUE KEY uq_advisor_etf_catalog_symbol_market (symbol, market),
  KEY idx_advisor_etf_catalog_risk_bucket (risk_bucket),
  KEY idx_advisor_etf_catalog_focus_theme (focus_theme)
);

CREATE TABLE IF NOT EXISTS portfolio_advice_logs (
  advice_log_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  advice_headline VARCHAR(255) NOT NULL,
  risk_level VARCHAR(40) NOT NULL,
  sharpe_ratio DECIMAL(12,4) NOT NULL DEFAULT 0,
  concentration_pct DECIMAL(12,4) NOT NULL DEFAULT 0,
  generated_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (advice_log_id),
  KEY idx_portfolio_advice_logs_user_generated_at (user_id, generated_at),
  CONSTRAINT fk_portfolio_advice_logs_user_id FOREIGN KEY (user_id) REFERENCES users (user_id)
);

INSERT INTO asset_classifications (asset_id, category_code, category_name, risk_bucket)
SELECT asset_id, 'KR_SEMICONDUCTOR', '국내 반도체 대형주', 'HIGH'
FROM assets
WHERE symbol = '005930'
ON DUPLICATE KEY UPDATE
  category_code = VALUES(category_code),
  category_name = VALUES(category_name),
  risk_bucket = VALUES(risk_bucket),
  updated_at = NOW();

INSERT INTO asset_classifications (asset_id, category_code, category_name, risk_bucket)
SELECT asset_id, 'KR_SEMICONDUCTOR', '국내 반도체 대형주', 'HIGH'
FROM assets
WHERE symbol = '000660'
ON DUPLICATE KEY UPDATE
  category_code = VALUES(category_code),
  category_name = VALUES(category_name),
  risk_bucket = VALUES(risk_bucket),
  updated_at = NOW();

INSERT INTO asset_classifications (asset_id, category_code, category_name, risk_bucket)
SELECT asset_id, 'KR_PLATFORM', '국내 플랫폼/인터넷', 'HIGH'
FROM assets
WHERE symbol = '035420'
ON DUPLICATE KEY UPDATE
  category_code = VALUES(category_code),
  category_name = VALUES(category_name),
  risk_bucket = VALUES(risk_bucket),
  updated_at = NOW();

INSERT INTO asset_classifications (asset_id, category_code, category_name, risk_bucket)
SELECT asset_id, 'KR_BATTERY', '국내 2차전지', 'HIGH'
FROM assets
WHERE symbol = '051910'
ON DUPLICATE KEY UPDATE
  category_code = VALUES(category_code),
  category_name = VALUES(category_name),
  risk_bucket = VALUES(risk_bucket),
  updated_at = NOW();

INSERT INTO asset_classifications (asset_id, category_code, category_name, risk_bucket)
SELECT asset_id, 'KR_PLATFORM', '국내 플랫폼/인터넷', 'HIGH'
FROM assets
WHERE symbol = '035720'
ON DUPLICATE KEY UPDATE
  category_code = VALUES(category_code),
  category_name = VALUES(category_name),
  risk_bucket = VALUES(risk_bucket),
  updated_at = NOW();

INSERT INTO advisor_etf_catalog
  (symbol, name, market, focus_theme, risk_bucket, diversification_role, expense_ratio_pct, is_active)
VALUES
  ('069500', 'KODEX 200', 'KRX', '국내 대형주 분산', 'MID', '국내 주식 단일종목 집중 완화', 0.1500, 1),
  ('360750', 'TIGER 미국S&P500', 'KRX', '미국 대형주 분산', 'MID', '국내 편중 완화 및 통화 분산', 0.0700, 1),
  ('133690', 'TIGER 미국나스닥100', 'KRX', '미국 성장주', 'HIGH', '성장 팩터 보강', 0.0900, 1),
  ('114260', 'KODEX 국고채3년', 'KRX', '국내 중기채권', 'LOW', '변동성 완충 및 방어 자산', 0.0500, 1),
  ('305080', 'TIGER 미국채10년선물', 'KRX', '미국 장기채권', 'LOW', '주식 하락 구간 헤지', 0.2500, 1),
  ('381170', 'TIGER 미국테크TOP10 INDXX', 'KRX', '미국 빅테크', 'HIGH', '기술주 성장 노출 확대', 0.4900, 1)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  focus_theme = VALUES(focus_theme),
  risk_bucket = VALUES(risk_bucket),
  diversification_role = VALUES(diversification_role),
  expense_ratio_pct = VALUES(expense_ratio_pct),
  is_active = VALUES(is_active),
  updated_at = NOW();

INSERT INTO market_price_candles
  (asset_id, interval_code, candle_time, open_price, high_price, low_price, close_price, volume)
WITH RECURSIVE seq AS (
  SELECT 1 AS day_offset
  UNION ALL
  SELECT day_offset + 1
  FROM seq
  WHERE day_offset < 90
),
seed AS (
  SELECT
    a.asset_id,
    a.symbol,
    CASE a.symbol
      WHEN '005930' THEN 72000.0
      WHEN '000660' THEN 165000.0
      WHEN '035420' THEN 210000.0
      WHEN '051910' THEN 395000.0
      WHEN '035720' THEN 50000.0
      ELSE 100000.0
    END AS base_price,
    CASE a.symbol
      WHEN '005930' THEN 0.00035
      WHEN '000660' THEN 0.00055
      WHEN '035420' THEN 0.00030
      WHEN '051910' THEN 0.00015
      WHEN '035720' THEN 0.00045
      ELSE 0.00025
    END AS trend,
    CASE a.symbol
      WHEN '005930' THEN 13000000.0
      WHEN '000660' THEN 6200000.0
      WHEN '035420' THEN 3400000.0
      WHEN '051910' THEN 820000.0
      WHEN '035720' THEN 11800000.0
      ELSE 5000000.0
    END AS base_volume
  FROM assets a
  WHERE a.symbol IN ('005930', '000660', '035420', '051910', '035720')
),
series AS (
  SELECT
    s.asset_id,
    seq.day_offset,
    s.base_volume,
    (s.base_price * (1 + s.trend * seq.day_offset + 0.015 * SIN(seq.day_offset / 5))) AS core_price
  FROM seed s
  JOIN seq
)
SELECT
  series.asset_id,
  '1d',
  TIMESTAMP(DATE_SUB(CURRENT_DATE, INTERVAL series.day_offset DAY)),
  ROUND(series.core_price * 0.998, 6) AS open_price,
  ROUND(
    GREATEST(
      series.core_price * 0.998,
      series.core_price * (1 + 0.002 * COS(series.day_offset / 4))
    ) * 1.006,
    6
  ) AS high_price,
  ROUND(
    LEAST(
      series.core_price * 0.998,
      series.core_price * (1 + 0.002 * COS(series.day_offset / 4))
    ) * 0.994,
    6
  ) AS low_price,
  ROUND(series.core_price * (1 + 0.002 * COS(series.day_offset / 4)), 6) AS close_price,
  ROUND(series.base_volume * (1 + 0.25 * ABS(SIN(series.day_offset / 3))), 6) AS volume
FROM series
ON DUPLICATE KEY UPDATE
  open_price = VALUES(open_price),
  high_price = VALUES(high_price),
  low_price = VALUES(low_price),
  close_price = VALUES(close_price),
  volume = VALUES(volume);
