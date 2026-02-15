INSERT INTO user_auth_credentials (credential_id, user_id, password_hash, hash_algorithm, created_at, updated_at)
VALUES
  (2001, 1001, 'demo1234', 'PLAINTEXT', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  password_hash = VALUES(password_hash),
  hash_algorithm = VALUES(hash_algorithm),
  updated_at = NOW();
