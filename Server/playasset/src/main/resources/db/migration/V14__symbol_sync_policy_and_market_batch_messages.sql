INSERT INTO paid_service_policies (service_key, display_name, daily_limit, is_enabled)
VALUES ('SYMBOL_CATALOG_SYNC', 'Symbol catalog sync batch', 20, 1)
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  daily_limit = VALUES(daily_limit),
  is_enabled = VALUES(is_enabled),
  updated_at = NOW();

INSERT INTO TM_STD_CODE_MAIN(code_group_cd, code_group_nm, code_group_desc, use_yn)
VALUES ('MARKET_BATCH_MESSAGE', 'Market batch messages', 'Runtime messages for market/news batch jobs', 1)
ON DUPLICATE KEY UPDATE
  code_group_nm = VALUES(code_group_nm),
  code_group_desc = VALUES(code_group_desc),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO TM_STD_RUNTIME_CONFIG_MAIN(
  config_group_cd, config_key, config_name, value_type_cd, config_value, config_desc, sort_no, editable_yn, use_yn
)
VALUES
  ('MARKET_BATCH_MESSAGE', 'news.synthetic.title.template', 'Synthetic news title template', 'STRING', '%s 관련 수급/모멘텀 업데이트', 'Title template for synthetic news item', 10, 1, 1),
  ('MARKET_BATCH_MESSAGE', 'news.synthetic.body.template', 'Synthetic news body template', 'STRING', '외부 뉴스 API 키가 없어 내부 샘플 데이터로 생성했어요.', 'Body template for synthetic news item', 20, 1, 1)
ON DUPLICATE KEY UPDATE
  config_name = VALUES(config_name),
  value_type_cd = VALUES(value_type_cd),
  config_value = VALUES(config_value),
  config_desc = VALUES(config_desc),
  sort_no = VALUES(sort_no),
  editable_yn = VALUES(editable_yn),
  use_yn = VALUES(use_yn),
  updated_at = CURRENT_TIMESTAMP;

