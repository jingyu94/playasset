-- Legacy migration script: TM_* -> playasset_core
-- Precondition:
-- 1) legacy schema `playasset` exists with TM_USER/TM_STOCK/TM_MY_STOCK/TMP_NEWS_TITLE
-- 2) v2 schema from DDL_V2_20260216.sql already applied

START TRANSACTION;

-- 1) Users (if legacy table exists)
SET @has_tm_user = (
  SELECT COUNT(*)
  FROM information_schema.tables
  WHERE table_schema = 'playasset' AND table_name = 'TM_USER'
);

SET @sql_users = IF(
  @has_tm_user = 1,
  "INSERT INTO playasset_core.users (email, display_name, status, created_at, updated_at)
   SELECT CONCAT(LOWER(TRIM(u.USER_ID)), '@legacy.local'),
          COALESCE(NULLIF(TRIM(u.USER_NAME), ''), TRIM(u.USER_ID)),
          'ACTIVE', NOW(), NOW()
   FROM playasset.TM_USER u
   ON DUPLICATE KEY UPDATE display_name = VALUES(display_name), updated_at = NOW()",
  "SELECT 'SKIP: playasset.TM_USER not found' AS info"
);
PREPARE stmt_users FROM @sql_users;
EXECUTE stmt_users;
DEALLOCATE PREPARE stmt_users;

-- 2) Credentials
-- Legacy plaintext password is not migrated. Force reset by issuing random hash placeholder.
INSERT INTO playasset_core.user_auth_credentials (user_id, password_hash, hash_algorithm, created_at, updated_at)
SELECT
  nu.user_id,
  SHA2(CONCAT(UUID(), RAND()), 256) AS password_hash,
  'LEGACY_RESET_REQUIRED' AS hash_algorithm,
  NOW(),
  NOW()
FROM playasset_core.users nu
LEFT JOIN playasset_core.user_auth_credentials c ON c.user_id = nu.user_id
WHERE c.user_id IS NULL;

-- 3) Preferences
INSERT INTO playasset_core.user_preferences (user_id, timezone, locale, push_enabled, email_enabled, created_at, updated_at)
SELECT
  nu.user_id,
  'Asia/Seoul',
  'ko-KR',
  1,
  0,
  NOW(),
  NOW()
FROM playasset_core.users nu
LEFT JOIN playasset_core.user_preferences p ON p.user_id = nu.user_id
WHERE p.user_id IS NULL;

-- 4) Assets (if legacy table exists)
SET @has_tm_stock = (
  SELECT COUNT(*)
  FROM information_schema.tables
  WHERE table_schema = 'playasset' AND table_name = 'TM_STOCK'
);

SET @sql_assets = IF(
  @has_tm_stock = 1,
  "INSERT INTO playasset_core.assets (symbol, name, market, currency, is_active, created_at, updated_at)
   SELECT s.STOCK_ID, s.STOCK_NAME, 'KRX', 'KRW', 1, NOW(), NOW()
   FROM playasset.TM_STOCK s
   ON DUPLICATE KEY UPDATE name = VALUES(name), is_active = 1, updated_at = NOW()",
  "SELECT 'SKIP: playasset.TM_STOCK not found' AS info"
);
PREPARE stmt_assets FROM @sql_assets;
EXECUTE stmt_assets;
DEALLOCATE PREPARE stmt_assets;

-- 5) Default watchlist per user
INSERT INTO playasset_core.watchlists (user_id, name, is_default, created_at, updated_at)
SELECT
  nu.user_id,
  'Legacy Watchlist',
  1,
  NOW(),
  NOW()
FROM playasset_core.users nu
LEFT JOIN playasset_core.watchlists w
  ON w.user_id = nu.user_id AND w.is_default = 1
WHERE w.watchlist_id IS NULL;

-- 6) Legacy favorites (if legacy table exists)
SET @has_tm_my_stock = (
  SELECT COUNT(*)
  FROM information_schema.tables
  WHERE table_schema = 'playasset' AND table_name = 'TM_MY_STOCK'
);

SET @sql_watchlist_items = IF(
  @has_tm_my_stock = 1,
  "INSERT IGNORE INTO playasset_core.watchlist_items (watchlist_id, asset_id, note, created_at)
   SELECT w.watchlist_id, a.asset_id, 'migrated from TM_MY_STOCK', NOW()
   FROM playasset.TM_MY_STOCK ms
   JOIN playasset_core.users nu
     ON nu.email = CONCAT(LOWER(TRIM(ms.USER_ID)), '@legacy.local')
   JOIN playasset_core.assets a
     ON a.symbol = ms.STOCK_ID AND a.market = 'KRX'
   JOIN playasset_core.watchlists w
     ON w.user_id = nu.user_id AND w.is_default = 1",
  "SELECT 'SKIP: playasset.TM_MY_STOCK not found' AS info"
);
PREPARE stmt_watchlist_items FROM @sql_watchlist_items;
EXECUTE stmt_watchlist_items;
DEALLOCATE PREPARE stmt_watchlist_items;

-- 7) Temporary news titles -> article skeleton (if legacy table exists)
INSERT INTO playasset_core.news_sources (name, site_url, is_active, created_at)
VALUES ('legacy-tmp-news', 'https://legacy.local', 1, NOW())
ON DUPLICATE KEY UPDATE
  is_active = 1;

SET @legacy_source_id = (
  SELECT source_id
  FROM playasset_core.news_sources
  WHERE name = 'legacy-tmp-news'
  LIMIT 1
);

SET @has_tmp_news = (
  SELECT COUNT(*)
  FROM information_schema.tables
  WHERE table_schema = 'playasset' AND table_name = 'TMP_NEWS_TITLE'
);

SET @sql_news = IF(
  @has_tmp_news = 1,
  "INSERT INTO playasset_core.news_articles
     (source_id, external_id, title, body, language, published_at, ingested_at, created_at)
   SELECT @legacy_source_id, CONCAT('legacy-', t.idx), t.title, NULL, 'ko', NOW(), NOW(), NOW()
   FROM playasset.TMP_NEWS_TITLE t
   ON DUPLICATE KEY UPDATE title = VALUES(title)",
  "SELECT 'SKIP: playasset.TMP_NEWS_TITLE not found' AS info"
);
PREPARE stmt_news FROM @sql_news;
EXECUTE stmt_news;
DEALLOCATE PREPARE stmt_news;

COMMIT;
