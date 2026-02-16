UPDATE TM_LLM_PROMPT_MAIN
SET use_yn = 0,
    updated_at = CURRENT_TIMESTAMP
WHERE prompt_key = 'PORTFOLIO_ADVICE';

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
  'v1.1.0',
  '포트폴리오 맞춤 리밸런싱/ETF 추천 (요 말투 기본)',
  'You are a portfolio advisory model. Use risk profile, current positions, metrics, and constraints to rank rebalancing actions and ETF candidates. Response language must be Korean. For every human-readable field (headline, summary, keyPoints, cautions, reason), use casual polite Korean style ending with "~요". Never use formal "-습니다" style. Return strict JSON only.',
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
