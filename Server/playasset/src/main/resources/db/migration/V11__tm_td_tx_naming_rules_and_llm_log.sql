CREATE TABLE IF NOT EXISTS TM_DB_NAMING_RULE_MAIN (
  naming_rule_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  object_type_cd VARCHAR(40) NOT NULL,
  prefix_cd VARCHAR(20) NOT NULL,
  naming_pattern VARCHAR(200) NOT NULL,
  sample_name VARCHAR(120) NOT NULL,
  rule_description VARCHAR(800) NOT NULL,
  use_yn TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (naming_rule_id),
  UNIQUE KEY uq_tm_db_naming_rule_main_type (object_type_cd)
);

CREATE TABLE IF NOT EXISTS TX_LLM_PROMPT_EXEC_LOG (
  prompt_exec_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  prompt_key VARCHAR(80) NOT NULL,
  prompt_version VARCHAR(40) NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  cache_hit_yn TINYINT(1) NOT NULL DEFAULT 0,
  token_in_cnt INT NULL,
  token_out_cnt INT NULL,
  elapsed_ms INT NULL,
  status_cd VARCHAR(30) NOT NULL DEFAULT 'SUCCESS',
  error_message VARCHAR(1000) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (prompt_exec_id),
  KEY idx_tx_llm_prompt_exec_log_key_time (prompt_key, created_at),
  KEY idx_tx_llm_prompt_exec_log_user_time (user_id, created_at)
);

INSERT INTO TM_DB_NAMING_RULE_MAIN(
  object_type_cd,
  prefix_cd,
  naming_pattern,
  sample_name,
  rule_description,
  use_yn
)
VALUES
  ('TABLE_MAIN', 'TM', 'TM_{DOMAIN}_{ENTITY}_MAIN', 'TM_INVEST_PROFILE_MAIN', '기준정보/마스터 성격 테이블은 TM 접두어를 사용한다.', 1),
  ('TABLE_DETAIL', 'TD', 'TD_{DOMAIN}_{ENTITY}_DETAIL', 'TD_INVEST_PROFILE_ANSWER_DETAIL', '마스터 하위 다건 상세는 TD 접두어를 사용한다.', 1),
  ('TABLE_TRANSACTION', 'TX', 'TX_{DOMAIN}_{PROCESS}_LOG', 'TX_LLM_PROMPT_EXEC_LOG', '트랜잭션/로그성 적재는 TX 접두어를 사용한다.', 1),
  ('VIEW', 'VW', 'VW_{DOMAIN}_{PURPOSE}', 'VW_PORTFOLIO_DAILY_SNAPSHOT', '조회 전용 뷰는 VW 접두어를 사용한다.', 1),
  ('INDEX', 'IX', 'IX_{TABLE}_{COLS}', 'IX_TM_INVEST_PROFILE_MAIN_USER', '일반 인덱스는 IX 접두어를 사용한다.', 1),
  ('PRIMARY_KEY', 'PK', 'PK_{TABLE}', 'PK_TM_INVEST_PROFILE_MAIN', '기본키 제약조건은 PK 접두어를 사용한다.', 1),
  ('FOREIGN_KEY', 'FK', 'FK_{FROM}_{TO}', 'FK_TM_INVEST_PROFILE_MAIN_USER', '외래키 제약조건은 FK 접두어를 사용한다.', 1),
  ('UNIQUE_KEY', 'UK', 'UK_{TABLE}_{COLS}', 'UK_TM_LLM_PROMPT_MAIN_KEY_VER', '유니크 제약조건은 UK 접두어를 사용한다.', 1),
  ('COLUMN', 'COL', 'snake_case', 'risk_tier', '컬럼명은 snake_case + 의미 중심 명명으로 통일한다.', 1)
ON DUPLICATE KEY UPDATE
  prefix_cd = VALUES(prefix_cd),
  naming_pattern = VALUES(naming_pattern),
  sample_name = VALUES(sample_name),
  rule_description = VALUES(rule_description),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO TM_ONTOLOGY_TERM_MAIN(
  domain_cd,
  term_cd,
  term_nm,
  definition_txt,
  skos_pref_label,
  skos_alt_labels,
  related_term_cds,
  use_yn
)
VALUES
  ('LLM', 'PROMPT_TEMPLATE', '프롬프트 템플릿', 'LLM 호출 시 공통 지침/입출력 스키마를 포함한 기준 텍스트', 'Prompt Template', JSON_ARRAY('시스템 프롬프트', 'Prompt Baseline'), JSON_ARRAY('PROMPT_PAYLOAD', 'PROMPT_VERSION'), 1),
  ('LLM', 'PROMPT_PAYLOAD', '프롬프트 페이로드', '사용자/지표/제약조건 등 실행 시점 입력 JSON', 'Prompt Payload', JSON_ARRAY('입력 JSON', 'Structured Context'), JSON_ARRAY('PROMPT_TEMPLATE', 'RISK_PROFILE_CODE'), 1),
  ('PORTFOLIO', 'RISK_PROFILE_CODE', '투자성향 코드', '투자자 설문과 손실 감내 수준으로 결정되는 성향 분류 코드', 'Risk Profile Code', JSON_ARRAY('성향코드', 'Risk Bucket'), JSON_ARRAY('RISK_TIER', 'SHARPE_RATIO'), 1)
ON DUPLICATE KEY UPDATE
  term_nm = VALUES(term_nm),
  definition_txt = VALUES(definition_txt),
  skos_pref_label = VALUES(skos_pref_label),
  skos_alt_labels = VALUES(skos_alt_labels),
  related_term_cds = VALUES(related_term_cds),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;
