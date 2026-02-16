SET @has_low := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_preferences'
    AND COLUMN_NAME = 'alert_level_low_enabled'
);
SET @sql_low := IF(
  @has_low = 0,
  'ALTER TABLE user_preferences ADD COLUMN alert_level_low_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER email_enabled',
  'SELECT 1'
);
PREPARE stmt_low FROM @sql_low;
EXECUTE stmt_low;
DEALLOCATE PREPARE stmt_low;

SET @has_medium := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_preferences'
    AND COLUMN_NAME = 'alert_level_medium_enabled'
);
SET @sql_medium := IF(
  @has_medium = 0,
  'ALTER TABLE user_preferences ADD COLUMN alert_level_medium_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER alert_level_low_enabled',
  'SELECT 1'
);
PREPARE stmt_medium FROM @sql_medium;
EXECUTE stmt_medium;
DEALLOCATE PREPARE stmt_medium;

SET @has_high := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_preferences'
    AND COLUMN_NAME = 'alert_level_high_enabled'
);
SET @sql_high := IF(
  @has_high = 0,
  'ALTER TABLE user_preferences ADD COLUMN alert_level_high_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER alert_level_medium_enabled',
  'SELECT 1'
);
PREPARE stmt_high FROM @sql_high;
EXECUTE stmt_high;
DEALLOCATE PREPARE stmt_high;

UPDATE user_preferences
SET alert_level_low_enabled = COALESCE(alert_level_low_enabled, 1),
    alert_level_medium_enabled = COALESCE(alert_level_medium_enabled, 1),
    alert_level_high_enabled = COALESCE(alert_level_high_enabled, 1);
