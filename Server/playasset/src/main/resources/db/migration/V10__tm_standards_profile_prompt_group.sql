CREATE TABLE IF NOT EXISTS TM_STD_CODE_MAIN (
  code_group_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code_group_cd VARCHAR(80) NOT NULL,
  code_group_nm VARCHAR(120) NOT NULL,
  code_group_desc VARCHAR(500) NULL,
  use_yn TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (code_group_id),
  UNIQUE KEY uq_tm_std_code_main_group_cd (code_group_cd)
);

CREATE TABLE IF NOT EXISTS TM_STD_CODE_ITEM_MAIN (
  code_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code_group_cd VARCHAR(80) NOT NULL,
  code_cd VARCHAR(80) NOT NULL,
  code_nm VARCHAR(120) NOT NULL,
  code_desc VARCHAR(500) NULL,
  sort_no INT NOT NULL DEFAULT 100,
  use_yn TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (code_item_id),
  UNIQUE KEY uq_tm_std_code_item_main_group_code (code_group_cd, code_cd),
  KEY idx_tm_std_code_item_main_group_sort (code_group_cd, sort_no),
  CONSTRAINT fk_tm_std_code_item_main_group
    FOREIGN KEY (code_group_cd) REFERENCES TM_STD_CODE_MAIN (code_group_cd)
);

CREATE TABLE IF NOT EXISTS TM_ONTOLOGY_TERM_MAIN (
  ontology_term_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  domain_cd VARCHAR(80) NOT NULL,
  term_cd VARCHAR(80) NOT NULL,
  term_nm VARCHAR(120) NOT NULL,
  definition_txt VARCHAR(1000) NOT NULL,
  skos_pref_label VARCHAR(200) NULL,
  skos_alt_labels JSON NULL,
  related_term_cds JSON NULL,
  use_yn TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (ontology_term_id),
  UNIQUE KEY uq_tm_ontology_term_main_domain_term (domain_cd, term_cd)
);

CREATE TABLE IF NOT EXISTS TM_AUTH_GROUP_MAIN (
  group_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_key VARCHAR(80) NOT NULL,
  group_name VARCHAR(120) NOT NULL,
  group_desc VARCHAR(500) NULL,
  use_yn TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (group_id),
  UNIQUE KEY uq_tm_auth_group_main_group_key (group_key)
);

CREATE TABLE IF NOT EXISTS TM_AUTH_GROUP_PERMISSION_MAP (
  group_permission_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id BIGINT UNSIGNED NOT NULL,
  permission_code VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (group_permission_id),
  UNIQUE KEY uq_tm_auth_group_permission_map_group_perm (group_id, permission_code),
  KEY idx_tm_auth_group_permission_map_perm (permission_code),
  CONSTRAINT fk_tm_auth_group_permission_map_group
    FOREIGN KEY (group_id) REFERENCES TM_AUTH_GROUP_MAIN (group_id)
);

CREATE TABLE IF NOT EXISTS TM_AUTH_GROUP_USER_MAP (
  group_user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  group_id BIGINT UNSIGNED NOT NULL,
  use_yn TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (group_user_id),
  UNIQUE KEY uq_tm_auth_group_user_map_user (user_id),
  KEY idx_tm_auth_group_user_map_group (group_id),
  CONSTRAINT fk_tm_auth_group_user_map_user
    FOREIGN KEY (user_id) REFERENCES users (user_id),
  CONSTRAINT fk_tm_auth_group_user_map_group
    FOREIGN KEY (group_id) REFERENCES TM_AUTH_GROUP_MAIN (group_id)
);

CREATE TABLE IF NOT EXISTS TM_INVEST_PROFILE_MAIN (
  profile_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  profile_key VARCHAR(80) NOT NULL,
  profile_name VARCHAR(120) NOT NULL,
  short_label VARCHAR(60) NOT NULL,
  profile_summary VARCHAR(800) NOT NULL,
  risk_score INT NOT NULL,
  risk_tier INT NOT NULL,
  target_allocation_hint VARCHAR(400) NOT NULL,
  answers_json JSON NULL,
  updated_by VARCHAR(80) NOT NULL DEFAULT 'SYSTEM',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (profile_id),
  UNIQUE KEY uq_tm_invest_profile_main_user (user_id),
  KEY idx_tm_invest_profile_main_profile (profile_key, risk_tier),
  CONSTRAINT fk_tm_invest_profile_main_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS TM_LLM_PROMPT_MAIN (
  prompt_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  prompt_key VARCHAR(80) NOT NULL,
  prompt_version VARCHAR(40) NOT NULL,
  prompt_name VARCHAR(120) NOT NULL,
  prompt_template MEDIUMTEXT NOT NULL,
  input_schema_json JSON NULL,
  output_schema_json JSON NULL,
  use_yn TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (prompt_id),
  UNIQUE KEY uq_tm_llm_prompt_main_key_version (prompt_key, prompt_version),
  KEY idx_tm_llm_prompt_main_key_use (prompt_key, use_yn)
);

INSERT INTO TM_STD_CODE_MAIN(code_group_cd, code_group_nm, code_group_desc, use_yn)
VALUES
  ('RISK_PROFILE', '투자성향 코드', '투자성향 표준 코드셋', 1),
  ('AUTH_PERMISSION', '권한 코드', '역할/권한 코드셋', 1),
  ('LLM_PROMPT_KEY', 'LLM 프롬프트 키', '추천/진단 프롬프트 식별 코드', 1)
ON DUPLICATE KEY UPDATE
  code_group_nm = VALUES(code_group_nm),
  code_group_desc = VALUES(code_group_desc),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO TM_STD_CODE_ITEM_MAIN(code_group_cd, code_cd, code_nm, code_desc, sort_no, use_yn)
VALUES
  ('RISK_PROFILE', 'CAPITAL_PRESERVER', '안정형', '원금 보전 중심', 10, 1),
  ('RISK_PROFILE', 'INCOME_FOCUSED', '안정추구형', '손실 제한 + 완만한 성장', 20, 1),
  ('RISK_PROFILE', 'BALANCED', '균형형', '수익/안정 균형', 30, 1),
  ('RISK_PROFILE', 'GROWTH', '성장형', '중장기 성장 우선', 40, 1),
  ('RISK_PROFILE', 'AGGRESSIVE', '공격형', '고수익 추구 + 변동성 감수', 50, 1),
  ('RISK_PROFILE', 'MAD_MAX', '리스크 매드맥스형', '초고위험/초고변동 감수', 60, 1),
  ('AUTH_PERMISSION', 'USER', '일반 사용자', '기본 사용자 권한', 10, 1),
  ('AUTH_PERMISSION', 'OPERATOR', '운영자', '운영 권한', 20, 1),
  ('AUTH_PERMISSION', 'ADMIN', '관리자', '관리자 권한', 30, 1),
  ('LLM_PROMPT_KEY', 'PORTFOLIO_ADVICE', '포트폴리오 추천', '포트폴리오 맞춤 추천 프롬프트', 10, 1)
ON DUPLICATE KEY UPDATE
  code_nm = VALUES(code_nm),
  code_desc = VALUES(code_desc),
  sort_no = VALUES(sort_no),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO TM_AUTH_GROUP_MAIN(group_key, group_name, group_desc, use_yn)
VALUES
  ('GRP_ADMIN_CORE', '관리자 기본그룹', '관리자 및 운영 권한 묶음', 1),
  ('GRP_OPERATOR_CORE', '운영자 기본그룹', '운영 권한 묶음', 1),
  ('GRP_USER_CORE', '일반사용자 기본그룹', '일반 사용자 권한 묶음', 1)
ON DUPLICATE KEY UPDATE
  group_name = VALUES(group_name),
  group_desc = VALUES(group_desc),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO TM_AUTH_GROUP_PERMISSION_MAP(group_id, permission_code)
SELECT g.group_id, x.permission_code
FROM (
  SELECT 'GRP_ADMIN_CORE' AS group_key, 'ADMIN' AS permission_code UNION ALL
  SELECT 'GRP_ADMIN_CORE', 'OPERATOR' UNION ALL
  SELECT 'GRP_ADMIN_CORE', 'USER' UNION ALL
  SELECT 'GRP_OPERATOR_CORE', 'OPERATOR' UNION ALL
  SELECT 'GRP_OPERATOR_CORE', 'USER' UNION ALL
  SELECT 'GRP_USER_CORE', 'USER'
) x
JOIN TM_AUTH_GROUP_MAIN g ON g.group_key = x.group_key
ON DUPLICATE KEY UPDATE permission_code = VALUES(permission_code);

INSERT INTO TM_AUTH_GROUP_USER_MAP(user_id, group_id, use_yn)
SELECT u.user_id, g.group_id, 1
FROM users u
JOIN TM_AUTH_GROUP_MAIN g ON g.group_key =
  CASE
    WHEN u.user_id = 1999 THEN 'GRP_ADMIN_CORE'
    ELSE 'GRP_USER_CORE'
  END
ON DUPLICATE KEY UPDATE
  group_id = VALUES(group_id),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO TM_LLM_PROMPT_MAIN(
  prompt_key,
  prompt_version,
  prompt_name,
  prompt_template,
  input_schema_json,
  output_schema_json,
  use_yn
)
VALUES (
  'PORTFOLIO_ADVICE',
  'v1.0.0',
  '포트폴리오 맞춤 리밸런싱/ETF 추천',
  'You are a portfolio advisory model. Use risk profile, current positions, metrics, and constraints to rank rebalancing actions and ETF candidates. Return strict JSON only.',
  JSON_OBJECT(
    'type', 'object',
    'required', JSON_ARRAY('riskProfile', 'positions', 'metrics', 'constraints'),
    'properties', JSON_OBJECT(
      'riskProfile', JSON_OBJECT('type', 'object'),
      'positions', JSON_OBJECT('type', 'array'),
      'metrics', JSON_OBJECT('type', 'object'),
      'constraints', JSON_OBJECT('type', 'object')
    )
  ),
  JSON_OBJECT(
    'type', 'object',
    'required', JSON_ARRAY('recommendedActions', 'recommendedEtfs', 'insight'),
    'properties', JSON_OBJECT(
      'recommendedActions', JSON_OBJECT('type', 'array'),
      'recommendedEtfs', JSON_OBJECT('type', 'array'),
      'insight', JSON_OBJECT('type', 'object')
    )
  ),
  1
)
ON DUPLICATE KEY UPDATE
  prompt_name = VALUES(prompt_name),
  prompt_template = VALUES(prompt_template),
  input_schema_json = VALUES(input_schema_json),
  output_schema_json = VALUES(output_schema_json),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO TM_ONTOLOGY_TERM_MAIN(
  domain_cd, term_cd, term_nm, definition_txt, skos_pref_label, skos_alt_labels, related_term_cds, use_yn
)
VALUES
  ('PORTFOLIO', 'SHARPE_RATIO', '샤프지수', '위험 대비 초과수익 효율을 나타내는 지표', 'Sharpe Ratio', JSON_ARRAY('위험대비수익률'), JSON_ARRAY('ANNUAL_VOLATILITY', 'EXPECTED_ANNUAL_RETURN'), 1),
  ('PORTFOLIO', 'MAX_DRAWDOWN', '최대낙폭', '관측기간 내 고점 대비 최대 하락률', 'Maximum Drawdown', JSON_ARRAY('MDD', '최대손실구간'), JSON_ARRAY('ANNUAL_VOLATILITY'), 1),
  ('PORTFOLIO', 'ANNUAL_VOLATILITY', '연환산변동성', '일별 수익률 표준편차를 연 기준으로 환산한 위험지표', 'Annualized Volatility', JSON_ARRAY('변동성'), JSON_ARRAY('SHARPE_RATIO', 'MAX_DRAWDOWN'), 1),
  ('PORTFOLIO', 'RISK_TIER', '리스크등급', '투자성향 점수 기반 위험 감수 수준 등급', 'Risk Tier', JSON_ARRAY('성향등급'), JSON_ARRAY('RISK_PROFILE_CODE'), 1)
ON DUPLICATE KEY UPDATE
  term_nm = VALUES(term_nm),
  definition_txt = VALUES(definition_txt),
  skos_pref_label = VALUES(skos_pref_label),
  skos_alt_labels = VALUES(skos_alt_labels),
  related_term_cds = VALUES(related_term_cds),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;
