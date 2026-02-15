CREATE TABLE IF NOT EXISTS portfolio_simulation_snapshots (
  snapshot_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  snapshot_date DATE NOT NULL,
  simulated_value DECIMAL(24,6) NOT NULL DEFAULT 0,
  base_value DECIMAL(24,6) NOT NULL DEFAULT 0,
  cumulative_return_pct DECIMAL(12,6) NOT NULL DEFAULT 0,
  daily_return_pct DECIMAL(12,6) NOT NULL DEFAULT 0,
  drawdown_pct DECIMAL(12,6) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (snapshot_id),
  UNIQUE KEY uq_portfolio_simulation_user_date (user_id, snapshot_date),
  KEY idx_portfolio_simulation_user_date (user_id, snapshot_date),
  CONSTRAINT fk_portfolio_simulation_user_id FOREIGN KEY (user_id) REFERENCES users (user_id)
);
