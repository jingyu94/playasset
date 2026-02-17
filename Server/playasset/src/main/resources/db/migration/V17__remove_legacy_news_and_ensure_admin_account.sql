-- Remove remaining legacy demo-news rows and ensure admin can import real data.

DELETE ns
FROM news_sentiment_scores ns
JOIN news_articles na ON na.article_id = ns.article_id
JOIN news_sources src ON src.source_id = na.source_id
WHERE src.name = 'legacy-tmp-news';

DELETE nam
FROM news_asset_mentions nam
JOIN news_articles na ON na.article_id = nam.article_id
JOIN news_sources src ON src.source_id = na.source_id
WHERE src.name = 'legacy-tmp-news';

DELETE na
FROM news_articles na
JOIN news_sources src ON src.source_id = na.source_id
WHERE src.name = 'legacy-tmp-news';

DELETE FROM news_sources WHERE name = 'legacy-tmp-news';

-- Keep admin user, but ensure there is at least one empty account for excel import.
INSERT INTO portfolios (user_id, name, base_currency, created_at, updated_at)
SELECT 1999, 'Default Portfolio', 'KRW', NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM portfolios WHERE user_id = 1999
);

INSERT INTO portfolio_accounts (portfolio_id, broker_name, account_label, created_at, updated_at)
SELECT pf.portfolio_id, 'MANUAL', 'Default Account', NOW(), NOW()
FROM portfolios pf
WHERE pf.user_id = 1999
  AND NOT EXISTS (
    SELECT 1 FROM portfolio_accounts pa WHERE pa.portfolio_id = pf.portfolio_id
  );
