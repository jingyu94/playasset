CREATE TABLE IF NOT EXISTS users (
  user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  display_name VARCHAR(80) NOT NULL,
  status ENUM('ACTIVE', 'SUSPENDED', 'DELETED') NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_users_email (email)
);

CREATE TABLE IF NOT EXISTS user_auth_credentials (
  credential_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  hash_algorithm VARCHAR(40) NOT NULL DEFAULT 'BCRYPT',
  password_updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (credential_id),
  UNIQUE KEY uq_user_auth_credentials_user_id (user_id),
  CONSTRAINT fk_user_auth_credentials_user_id FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS user_preferences (
  preference_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Seoul',
  locale VARCHAR(16) NOT NULL DEFAULT 'ko-KR',
  push_enabled TINYINT(1) NOT NULL DEFAULT 1,
  email_enabled TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (preference_id),
  UNIQUE KEY uq_user_preferences_user_id (user_id),
  CONSTRAINT fk_user_preferences_user_id FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS assets (
  asset_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  symbol VARCHAR(32) NOT NULL,
  name VARCHAR(120) NOT NULL,
  market VARCHAR(32) NOT NULL,
  currency VARCHAR(8) NOT NULL DEFAULT 'KRW',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (asset_id),
  UNIQUE KEY uq_assets_symbol_market (symbol, market),
  KEY idx_assets_name (name)
);

CREATE TABLE IF NOT EXISTS asset_aliases (
  alias_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  asset_id BIGINT UNSIGNED NOT NULL,
  alias VARCHAR(120) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (alias_id),
  UNIQUE KEY uq_asset_aliases_asset_alias (asset_id, alias),
  KEY idx_asset_aliases_alias (alias),
  CONSTRAINT fk_asset_aliases_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS watchlists (
  watchlist_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(80) NOT NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (watchlist_id),
  KEY idx_watchlists_user_id (user_id),
  CONSTRAINT fk_watchlists_user_id FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS watchlist_items (
  watchlist_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  watchlist_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NOT NULL,
  note VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (watchlist_item_id),
  UNIQUE KEY uq_watchlist_items_watchlist_asset (watchlist_id, asset_id),
  KEY idx_watchlist_items_asset_id (asset_id),
  CONSTRAINT fk_watchlist_items_watchlist_id FOREIGN KEY (watchlist_id) REFERENCES watchlists (watchlist_id),
  CONSTRAINT fk_watchlist_items_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS portfolios (
  portfolio_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(80) NOT NULL,
  base_currency VARCHAR(8) NOT NULL DEFAULT 'KRW',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (portfolio_id),
  KEY idx_portfolios_user_id (user_id),
  CONSTRAINT fk_portfolios_user_id FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS portfolio_accounts (
  account_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  portfolio_id BIGINT UNSIGNED NOT NULL,
  broker_name VARCHAR(80) NOT NULL,
  account_label VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (account_id),
  KEY idx_portfolio_accounts_portfolio_id (portfolio_id),
  CONSTRAINT fk_portfolio_accounts_portfolio_id FOREIGN KEY (portfolio_id) REFERENCES portfolios (portfolio_id)
);

CREATE TABLE IF NOT EXISTS portfolio_positions (
  position_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NOT NULL,
  quantity DECIMAL(20,6) NOT NULL DEFAULT 0,
  avg_cost DECIMAL(20,6) NOT NULL DEFAULT 0,
  realized_pnl DECIMAL(20,6) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (position_id),
  UNIQUE KEY uq_portfolio_positions_account_asset (account_id, asset_id),
  KEY idx_portfolio_positions_asset_id (asset_id),
  CONSTRAINT fk_portfolio_positions_account_id FOREIGN KEY (account_id) REFERENCES portfolio_accounts (account_id),
  CONSTRAINT fk_portfolio_positions_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS portfolio_transactions (
  transaction_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NOT NULL,
  side ENUM('BUY', 'SELL', 'DIVIDEND', 'FEE', 'DEPOSIT', 'WITHDRAW') NOT NULL,
  quantity DECIMAL(20,6) NOT NULL DEFAULT 0,
  price DECIMAL(20,6) NOT NULL DEFAULT 0,
  fee DECIMAL(20,6) NOT NULL DEFAULT 0,
  tax DECIMAL(20,6) NOT NULL DEFAULT 0,
  occurred_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (transaction_id),
  KEY idx_portfolio_transactions_account_id (account_id),
  KEY idx_portfolio_transactions_asset_id (asset_id),
  KEY idx_portfolio_transactions_occurred_at (occurred_at),
  CONSTRAINT fk_portfolio_transactions_account_id FOREIGN KEY (account_id) REFERENCES portfolio_accounts (account_id),
  CONSTRAINT fk_portfolio_transactions_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS market_price_candles (
  candle_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  asset_id BIGINT UNSIGNED NOT NULL,
  interval_code ENUM('1m', '5m', '15m', '1h', '1d') NOT NULL,
  candle_time DATETIME NOT NULL,
  open_price DECIMAL(20,6) NOT NULL,
  high_price DECIMAL(20,6) NOT NULL,
  low_price DECIMAL(20,6) NOT NULL,
  close_price DECIMAL(20,6) NOT NULL,
  volume DECIMAL(20,6) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (candle_id),
  UNIQUE KEY uq_market_price_candles_asset_interval_time (asset_id, interval_code, candle_time),
  KEY idx_market_price_candles_candle_time (candle_time),
  CONSTRAINT fk_market_price_candles_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS news_sources (
  source_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  site_url VARCHAR(255) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (source_id),
  UNIQUE KEY uq_news_sources_name (name)
);

CREATE TABLE IF NOT EXISTS news_articles (
  article_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  source_id BIGINT UNSIGNED NOT NULL,
  external_id VARCHAR(255) NULL,
  title VARCHAR(500) NOT NULL,
  body MEDIUMTEXT NULL,
  language VARCHAR(12) NOT NULL DEFAULT 'ko',
  published_at DATETIME NOT NULL,
  ingested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (article_id),
  UNIQUE KEY uq_news_articles_source_external_id (source_id, external_id),
  KEY idx_news_articles_published_at (published_at),
  FULLTEXT KEY ftx_news_articles_title_body (title, body),
  CONSTRAINT fk_news_articles_source_id FOREIGN KEY (source_id) REFERENCES news_sources (source_id)
);

CREATE TABLE IF NOT EXISTS news_asset_mentions (
  mention_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  article_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NOT NULL,
  confidence_score DECIMAL(5,4) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (mention_id),
  UNIQUE KEY uq_news_asset_mentions_article_asset (article_id, asset_id),
  KEY idx_news_asset_mentions_asset_id (asset_id),
  CONSTRAINT fk_news_asset_mentions_article_id FOREIGN KEY (article_id) REFERENCES news_articles (article_id),
  CONSTRAINT fk_news_asset_mentions_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS news_sentiment_scores (
  score_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  article_id BIGINT UNSIGNED NOT NULL,
  model_version VARCHAR(40) NOT NULL,
  sentiment_label ENUM('POSITIVE', 'NEUTRAL', 'NEGATIVE') NOT NULL,
  sentiment_score DECIMAL(6,5) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (score_id),
  UNIQUE KEY uq_news_sentiment_scores_article_model (article_id, model_version),
  CONSTRAINT fk_news_sentiment_scores_article_id FOREIGN KEY (article_id) REFERENCES news_articles (article_id)
);

CREATE TABLE IF NOT EXISTS alert_rules (
  rule_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NULL,
  rule_type ENUM('PRICE_CHANGE', 'NEWS_KEYWORD', 'SENTIMENT', 'VOLUME_SPIKE') NOT NULL,
  threshold_json JSON NOT NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (rule_id),
  KEY idx_alert_rules_user_id (user_id),
  KEY idx_alert_rules_asset_id (asset_id),
  CONSTRAINT fk_alert_rules_user_id FOREIGN KEY (user_id) REFERENCES users (user_id),
  CONSTRAINT fk_alert_rules_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS alert_events (
  alert_event_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rule_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  asset_id BIGINT UNSIGNED NULL,
  event_type VARCHAR(64) NOT NULL,
  title VARCHAR(200) NOT NULL,
  message VARCHAR(1000) NOT NULL,
  severity ENUM('LOW', 'MEDIUM', 'HIGH') NOT NULL DEFAULT 'MEDIUM',
  status ENUM('PENDING', 'SENT', 'READ', 'FAILED') NOT NULL DEFAULT 'PENDING',
  occurred_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (alert_event_id),
  KEY idx_alert_events_user_status (user_id, status),
  KEY idx_alert_events_occurred_at (occurred_at),
  CONSTRAINT fk_alert_events_rule_id FOREIGN KEY (rule_id) REFERENCES alert_rules (rule_id),
  CONSTRAINT fk_alert_events_user_id FOREIGN KEY (user_id) REFERENCES users (user_id),
  CONSTRAINT fk_alert_events_asset_id FOREIGN KEY (asset_id) REFERENCES assets (asset_id)
);

CREATE TABLE IF NOT EXISTS notification_deliveries (
  delivery_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  alert_event_id BIGINT UNSIGNED NOT NULL,
  channel ENUM('IN_APP', 'EMAIL', 'PUSH') NOT NULL,
  status ENUM('PENDING', 'SENT', 'FAILED') NOT NULL DEFAULT 'PENDING',
  failure_reason VARCHAR(255) NULL,
  attempted_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (delivery_id),
  KEY idx_notification_deliveries_event_channel (alert_event_id, channel),
  CONSTRAINT fk_notification_deliveries_alert_event_id FOREIGN KEY (alert_event_id) REFERENCES alert_events (alert_event_id)
);

CREATE TABLE IF NOT EXISTS ingestion_jobs (
  job_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  job_type VARCHAR(64) NOT NULL,
  source_key VARCHAR(128) NOT NULL,
  window_start DATETIME NOT NULL,
  window_end DATETIME NOT NULL,
  status ENUM('RUNNING', 'SUCCEEDED', 'FAILED') NOT NULL,
  records_in INT NOT NULL DEFAULT 0,
  records_out INT NOT NULL DEFAULT 0,
  error_message VARCHAR(1000) NULL,
  started_at DATETIME NOT NULL,
  finished_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (job_id),
  KEY idx_ingestion_jobs_type_status_started_at (job_type, status, started_at)
);
