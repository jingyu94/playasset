-- Purge demo/synthetic data so runtime uses only real user/imported data.

-- 1) Notification/alert demo rows
DELETE nd
FROM notification_deliveries nd
JOIN alert_events ae ON ae.alert_event_id = nd.alert_event_id
WHERE ae.user_id IN (1001, 1999);

DELETE FROM alert_events WHERE user_id IN (1001, 1999);
DELETE FROM alert_rules WHERE user_id IN (1001, 1999);

-- 2) Watchlist demo rows
DELETE wi
FROM watchlist_items wi
JOIN watchlists w ON w.watchlist_id = wi.watchlist_id
WHERE w.user_id IN (1001, 1999);

DELETE FROM watchlists WHERE user_id IN (1001, 1999);

-- 3) Portfolio demo rows
DELETE pt
FROM portfolio_transactions pt
JOIN portfolio_accounts pa ON pa.account_id = pt.account_id
JOIN portfolios pf ON pf.portfolio_id = pa.portfolio_id
WHERE pf.user_id IN (1001, 1999);

DELETE pp
FROM portfolio_positions pp
JOIN portfolio_accounts pa ON pa.account_id = pp.account_id
JOIN portfolios pf ON pf.portfolio_id = pa.portfolio_id
WHERE pf.user_id IN (1001, 1999);

DELETE pa
FROM portfolio_accounts pa
JOIN portfolios pf ON pf.portfolio_id = pa.portfolio_id
WHERE pf.user_id IN (1001, 1999);

DELETE FROM portfolios WHERE user_id IN (1001, 1999);

-- 4) Seeded sample/synthetic news rows
DELETE ns
FROM news_sentiment_scores ns
JOIN news_articles na ON na.article_id = ns.article_id
JOIN news_sources src ON src.source_id = na.source_id
WHERE src.name IN ('sample-finance-wire', 'internal-simulator');

DELETE nam
FROM news_asset_mentions nam
JOIN news_articles na ON na.article_id = nam.article_id
JOIN news_sources src ON src.source_id = na.source_id
WHERE src.name IN ('sample-finance-wire', 'internal-simulator');

DELETE na
FROM news_articles na
JOIN news_sources src ON src.source_id = na.source_id
WHERE src.name IN ('sample-finance-wire', 'internal-simulator');

DELETE FROM news_sources WHERE name IN ('sample-finance-wire', 'internal-simulator');

-- 5) Seed-only batch logs
DELETE FROM ingestion_jobs
WHERE job_type = 'BOOTSTRAP_SAMPLE'
   OR source_key IN ('LOCAL_SEED', 'SYNTHETIC');

-- 6) Seeded candle rows tied to demo-only asset ids
DELETE FROM market_price_candles
WHERE asset_id BETWEEN 4001 AND 5015;
