CREATE TABLE IF NOT EXISTS user_roles (
  user_role_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  role_code VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_role_id),
  UNIQUE KEY uq_user_roles_user_role (user_id, role_code),
  KEY idx_user_roles_role_code (role_code),
  CONSTRAINT fk_user_roles_user_id FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS auth_sessions (
  session_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  session_token VARCHAR(120) NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (session_id),
  UNIQUE KEY uq_auth_sessions_token (session_token),
  KEY idx_auth_sessions_user_id (user_id),
  KEY idx_auth_sessions_expires_at (expires_at),
  CONSTRAINT fk_auth_sessions_user_id FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS paid_service_policies (
  policy_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  service_key VARCHAR(80) NOT NULL,
  display_name VARCHAR(120) NOT NULL,
  daily_limit INT NOT NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (policy_id),
  UNIQUE KEY uq_paid_service_policies_service_key (service_key)
);

CREATE TABLE IF NOT EXISTS paid_service_daily_usage (
  usage_date DATE NOT NULL,
  service_key VARCHAR(80) NOT NULL,
  used_count INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (usage_date, service_key),
  KEY idx_paid_service_daily_usage_service_key (service_key),
  CONSTRAINT fk_paid_service_daily_usage_service_key FOREIGN KEY (service_key)
    REFERENCES paid_service_policies (service_key)
);
