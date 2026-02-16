-- Admin(1999) realistic portfolio seed based on provided account snapshot.
-- Idempotent by deleting user-scoped rows and upserting reference data.

INSERT INTO assets (asset_id, symbol, name, market, currency, is_active, created_at, updated_at)
VALUES
  (5001, 'KODEX2040', 'KODEX TDF 2040', 'KRX', 'KRW', 1, NOW(), NOW()),
  (5002, 'KODEX2050', 'KODEX TDF 2050', 'KRX', 'KRW', 1, NOW(), NOW()),
  (5003, 'PLUS2060',  'PLUS TDF 2060',  'KRX', 'KRW', 1, NOW(), NOW()),
  (5004, 'BND',       'Vanguard Total Bond Market ETF', 'NYSEARCA', 'KRW', 1, NOW(), NOW()),
  (5005, 'DBMF',      'iMGP DBi Managed Futures Strategy ETF', 'NYSEARCA', 'KRW', 1, NOW(), NOW()),
  (5006, 'GLDM',      'SPDR Gold MiniShares Trust', 'NYSEARCA', 'KRW', 1, NOW(), NOW()),
  (5007, 'IEF',       'iShares 7-10 Year Treasury Bond ETF', 'NASDAQ', 'KRW', 1, NOW(), NOW()),
  (5008, 'QQQ',       'Invesco QQQ Trust', 'NASDAQ', 'KRW', 1, NOW(), NOW()),
  (5009, 'SCHD',      'Schwab U.S. Dividend Equity ETF', 'NYSEARCA', 'KRW', 1, NOW(), NOW()),
  (5010, 'SPY',       'SPDR S&P 500 ETF Trust', 'NYSEARCA', 'KRW', 1, NOW(), NOW()),
  (5011, 'SQQQ',      'ProShares UltraPro Short QQQ', 'NASDAQ', 'KRW', 1, NOW(), NOW()),
  (5012, 'USMV',      'iShares MSCI USA Min Vol Factor ETF', 'NYSEARCA', 'KRW', 1, NOW(), NOW()),
  (5013, 'VEA',       'Vanguard FTSE Developed Markets ETF', 'NYSEARCA', 'KRW', 1, NOW(), NOW()),
  (5014, 'VTIP',      'Vanguard Short-Term Inflation-Protected Securities ETF', 'NYSEARCA', 'KRW', 1, NOW(), NOW()),
  (5015, 'VWO',       'Vanguard FTSE Emerging Markets ETF', 'NYSEARCA', 'KRW', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  currency = VALUES(currency),
  is_active = VALUES(is_active),
  updated_at = NOW();

INSERT INTO user_preferences(
  user_id, timezone, locale, push_enabled, email_enabled,
  alert_level_low_enabled, alert_level_medium_enabled, alert_level_high_enabled,
  created_at, updated_at
)
VALUES (1999, 'Asia/Seoul', 'ko-KR', 1, 0, 1, 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  timezone = VALUES(timezone),
  locale = VALUES(locale),
  push_enabled = VALUES(push_enabled),
  email_enabled = VALUES(email_enabled),
  alert_level_low_enabled = VALUES(alert_level_low_enabled),
  alert_level_medium_enabled = VALUES(alert_level_medium_enabled),
  alert_level_high_enabled = VALUES(alert_level_high_enabled),
  updated_at = NOW();

DELETE ae FROM alert_events ae WHERE ae.user_id = 1999;
DELETE ar FROM alert_rules ar WHERE ar.user_id = 1999;
DELETE wi FROM watchlist_items wi JOIN watchlists w ON w.watchlist_id = wi.watchlist_id WHERE w.user_id = 1999;
DELETE w FROM watchlists w WHERE w.user_id = 1999;
DELETE pt FROM portfolio_transactions pt JOIN portfolio_accounts pa ON pa.account_id = pt.account_id JOIN portfolios pf ON pf.portfolio_id = pa.portfolio_id WHERE pf.user_id = 1999;
DELETE pp FROM portfolio_positions pp JOIN portfolio_accounts pa ON pa.account_id = pp.account_id JOIN portfolios pf ON pf.portfolio_id = pa.portfolio_id WHERE pf.user_id = 1999;
DELETE pa FROM portfolio_accounts pa JOIN portfolios pf ON pf.portfolio_id = pa.portfolio_id WHERE pf.user_id = 1999;
DELETE pf FROM portfolios pf WHERE pf.user_id = 1999;

INSERT INTO portfolios (portfolio_id, user_id, name, base_currency, created_at, updated_at)
VALUES (8901, 1999, 'Admin Consolidated Portfolio', 'KRW', NOW(), NOW());

INSERT INTO portfolio_accounts (account_id, portfolio_id, broker_name, account_label, created_at, updated_at)
VALUES (9901, 8901, 'BROKER-LIVE', 'Main Account', NOW(), NOW());

INSERT INTO portfolio_positions (account_id, asset_id, quantity, avg_cost, realized_pnl)
VALUES
  (9901, 5001, 68.000000,    14797.808824, 0),
  (9901, 5002, 64.000000,    15821.953125, 0),
  (9901, 5003, 64.000000,    16921.281250, 0),
  (9901, 5004, 60.683681,   105602.806132, 0),
  (9901, 5005, 94.001316,    39956.323590, 0),
  (9901, 5006, 35.314032,   114276.047550, 0),
  (9901, 5007, 52.607994,   138437.629840, 0),
  (9901, 5008,  0.110818,   882410.799690, 0),
  (9901, 5009, 98.347193,    38065.722933, 0),
  (9901, 5010,  0.089643,   991756.188436, 0),
  (9901, 5011,117.000000,    98505.811966, 0),
  (9901, 5012, 41.663622,   133923.882086, 0),
  (9901, 5013, 22.205250,    83555.555556, 0),
  (9901, 5014, 42.323366,    70750.847180, 0),
  (9901, 5015,  1.362840,    79238.942209, 0);

INSERT INTO market_price_candles (
  asset_id, interval_code, candle_time, open_price, high_price, low_price, close_price, volume
)
VALUES
  (5001, '1d', '2026-02-14 09:00:00', 14503.241412, 15017.48752, 14416.221964, 14927.92, 244800),
  (5001, '1d', '2026-02-15 09:00:00', 14651.233672, 15202.12876, 14563.32627, 15111.46, 212400),
  (5001, '1d', '2026-02-16 09:00:00', 14799.225931, 15386.77, 14710.430575, 15295, 180000),
  (5002, '1d', '2026-02-14 09:00:00', 15506.626969, 16176.0776, 15413.587207, 16079.6, 238000),
  (5002, '1d', '2026-02-15 09:00:00', 15664.857857, 16374.9638, 15570.868709, 16277.3, 206500),
  (5002, '1d', '2026-02-16 09:00:00', 15823.088744, 16573.85, 15728.150212, 16475, 175000),
  (5003, '1d', '2026-02-14 09:00:00', 16582.8877, 17398.48832, 16483.390374, 17294.72, 231200),
  (5003, '1d', '2026-02-15 09:00:00', 16752.10084, 17612.40416, 16651.588235, 17507.36, 200600),
  (5003, '1d', '2026-02-16 09:00:00', 16921.31398, 17826.32, 16819.786096, 17720, 170000),
  (5004, '1d', '2026-02-14 09:00:00', 103496.544029, 105953.051483, 102875.564765, 105321.124735, 122400),
  (5004, '1d', '2026-02-15 09:00:00', 104552.631213, 107255.752936, 103925.315426, 106616.056597, 106200),
  (5004, '1d', '2026-02-16 09:00:00', 105608.718397, 108558.454389, 104975.066087, 107910.988458, 90000),
  (5005, '1d', '2026-02-14 09:00:00', 39159.679269, 42988.521672, 38924.721193, 42732.128899, 149600),
  (5005, '1d', '2026-02-15 09:00:00', 39559.267833, 43517.06907, 39321.912226, 43257.523927, 129800),
  (5005, '1d', '2026-02-16 09:00:00', 39958.856397, 44045.616468, 39719.103259, 43782.918954, 110000),
  (5006, '1d', '2026-02-14 09:00:00', 111999.00462, 140937.162978, 111327.010592, 140096.583477, 95200),
  (5006, '1d', '2026-02-15 09:00:00', 113141.851606, 142669.996949, 112463.000496, 141819.082454, 82600),
  (5006, '1d', '2026-02-16 09:00:00', 114284.698592, 144402.83092, 113598.9904, 143541.581431, 70000),
  (5007, '1d', '2026-02-14 09:00:00', 135678.226692, 137525.626301, 134864.157332, 136705.393937, 115600),
  (5007, '1d', '2026-02-15 09:00:00', 137062.698393, 139216.515149, 136240.322203, 138386.197961, 100300),
  (5007, '1d', '2026-02-16 09:00:00', 138447.170094, 140907.403997, 137616.487073, 140067.001985, 85000),
  (5008, '1d', '2026-02-14 09:00:00', 864759.9476, 869948.507286, 842023.501164, 847106.137992, 40800),
  (5008, '1d', '2026-02-15 09:00:00', 873584.028698, 878825.53287, 852376.249129, 857521.377393, 35400),
  (5008, '1d', '2026-02-16 09:00:00', 882408.109796, 887702.558455, 862728.997094, 867936.616795, 30000),
  (5009, '1d', '2026-02-14 09:00:00', 37307.514917, 44726.719157, 37083.669827, 44459.959401, 163200),
  (5009, '1d', '2026-02-15 09:00:00', 37688.203844, 45276.637835, 37462.074621, 45006.598246, 141600),
  (5009, '1d', '2026-02-16 09:00:00', 38068.892772, 45826.556514, 37840.479415, 45553.237091, 120000),
  (5010, '1d', '2026-02-14 09:00:00', 971848.993183, 977680.087142, 953704.916793, 959461.686914, 34000),
  (5010, '1d', '2026-02-15 09:00:00', 981765.819644, 987656.414562, 965430.796917, 971258.346999, 29500),
  (5010, '1d', '2026-02-16 09:00:00', 991682.646105, 997632.741982, 977156.677041, 983055.007084, 25000),
  (5011, '1d', '2026-02-14 09:00:00', 96539.614051, 102873.995968, 95960.376367, 102260.433367, 176800),
  (5011, '1d', '2026-02-15 09:00:00', 97524.712153, 104138.84018, 96939.563881, 103517.733778, 153400),
  (5011, '1d', '2026-02-16 09:00:00', 98509.810256, 105403.684393, 97918.751394, 104775.034188, 130000),
  (5012, '1d', '2026-02-14 09:00:00', 131253.713406, 136104.872083, 130466.191125, 135293.113402, 119680),
  (5012, '1d', '2026-02-15 09:00:00', 132593.037012, 137778.292641, 131797.47879, 136956.553321, 103840),
  (5012, '1d', '2026-02-16 09:00:00', 133932.360618, 139451.713199, 133128.766454, 138619.99324, 88000),
  (5013, '1d', '2026-02-14 09:00:00', 81889.93732, 97338.219836, 81398.597696, 96757.673794, 103360),
  (5013, '1d', '2026-02-15 09:00:00', 82725.548926, 98535.001228, 82229.195632, 97947.317324, 89680),
  (5013, '1d', '2026-02-16 09:00:00', 83561.160531, 99731.782619, 83059.793568, 99136.960854, 76000),
  (5014, '1d', '2026-02-14 09:00:00', 69342.56998, 70432.636086, 68926.51456, 70012.560721, 88400),
  (5014, '1d', '2026-02-15 09:00:00', 70050.147224, 71298.61112, 69629.846341, 70873.370894, 76700),
  (5014, '1d', '2026-02-16 09:00:00', 70757.724469, 72164.586153, 70333.178122, 71734.181067, 65000),
  (5015, '1d', '2026-02-14 09:00:00', 77655.059058, 81762.256559, 77189.128704, 81274.608905, 73440),
  (5015, '1d', '2026-02-15 09:00:00', 78447.45762, 82767.530205, 77976.772874, 82273.886884, 63720),
  (5015, '1d', '2026-02-16 09:00:00', 79239.856182, 83772.803851, 78764.417045, 83273.164862, 54000)
ON DUPLICATE KEY UPDATE
  open_price = VALUES(open_price),
  high_price = VALUES(high_price),
  low_price = VALUES(low_price),
  close_price = VALUES(close_price),
  volume = VALUES(volume);

INSERT INTO watchlists (watchlist_id, user_id, name, is_default, created_at, updated_at)
VALUES (6901, 1999, 'Core Watchlist', 1, NOW(), NOW());

INSERT INTO watchlist_items (watchlist_id, asset_id, note, created_at)
VALUES
  (6901, 5006, 'Gold exposure and defense weighting check', NOW()),
  (6901, 5011, 'Hedge intensity monitor', NOW()),
  (6901, 5008, 'Growth beta exposure check', NOW()),
  (6901, 5009, 'Dividend quality core', NOW()),
  (6901, 5004, 'Bond duration stabilization', NOW()),
  (6901, 5013, 'Developed market diversification', NOW()),
  (6901, 5014, 'Inflation hedge sleeve', NOW()),
  (6901, 5015, 'Emerging market weight control', NOW());

INSERT INTO portfolio_transactions (account_id, asset_id, side, quantity, price, fee, tax, occurred_at, created_at)
VALUES
  (9901, 5001, 'BUY', 68.000000,   14797.808824, 0, 0, '2025-03-11 09:05:00', NOW()),
  (9901, 5002, 'BUY', 64.000000,   15821.953125, 0, 0, '2025-03-11 09:06:00', NOW()),
  (9901, 5003, 'BUY', 64.000000,   16921.281250, 0, 0, '2025-03-11 09:07:00', NOW()),
  (9901, 5004, 'BUY', 60.683681,  105602.806132, 0, 0, '2025-03-13 22:31:00', NOW()),
  (9901, 5005, 'BUY', 94.001316,   39956.323590, 0, 0, '2025-03-13 22:32:00', NOW()),
  (9901, 5006, 'BUY', 35.314032,  114276.047550, 0, 0, '2025-03-13 22:33:00', NOW()),
  (9901, 5007, 'BUY', 52.607994,  138437.629840, 0, 0, '2025-03-13 22:34:00', NOW()),
  (9901, 5008, 'BUY',  0.110818,  882410.799690, 0, 0, '2025-04-02 00:14:00', NOW()),
  (9901, 5009, 'BUY', 98.347193,   38065.722933, 0, 0, '2025-04-02 00:15:00', NOW()),
  (9901, 5010, 'BUY',  0.089643,  991756.188436, 0, 0, '2025-04-02 00:16:00', NOW()),
  (9901, 5011, 'BUY',117.000000,   98505.811966, 0, 0, '2025-05-21 21:08:00', NOW()),
  (9901, 5012, 'BUY', 41.663622,  133923.882086, 0, 0, '2025-05-21 21:09:00', NOW()),
  (9901, 5013, 'BUY', 22.205250,   83555.555556, 0, 0, '2025-05-21 21:10:00', NOW()),
  (9901, 5014, 'BUY', 42.323366,   70750.847180, 0, 0, '2025-05-21 21:11:00', NOW()),
  (9901, 5015, 'BUY',  1.362840,   79238.942209, 0, 0, '2025-05-21 21:12:00', NOW()),
  (9901, 5009, 'DIVIDEND', 0.000000, 126450.000000, 0, 15400, '2026-01-15 08:00:00', NOW()),
  (9901, 5004, 'DIVIDEND', 0.000000,  81420.000000, 0,  9870, '2026-01-31 08:00:00', NOW()),
  (9901, 5013, 'DIVIDEND', 0.000000,  57200.000000, 0,  6900, '2026-02-05 08:00:00', NOW());

INSERT INTO alert_rules (rule_id, user_id, asset_id, rule_type, threshold_json, is_enabled, created_at, updated_at)
VALUES
  (17991, 1999, 5011, 'PRICE_CHANGE', JSON_OBJECT('dailyChangePctGte', 5.0), 1, NOW(), NOW()),
  (17992, 1999, 5006, 'PRICE_CHANGE', JSON_OBJECT('dailyChangePctGte', 4.0), 1, NOW(), NOW()),
  (17993, 1999, 5008, 'PRICE_CHANGE', JSON_OBJECT('dailyChangePctLte', -2.0), 1, NOW(), NOW()),
  (17994, 1999, NULL, 'SENTIMENT', JSON_OBJECT('negativeMentionsGte', 3), 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  threshold_json = VALUES(threshold_json),
  is_enabled = VALUES(is_enabled),
  updated_at = NOW();

INSERT INTO alert_events (
  alert_event_id, rule_id, user_id, asset_id, event_type, title, message, severity, status, occurred_at, created_at
)
VALUES
  (18991, 17991, 1999, 5011, 'PRICE_SPIKE', 'SQQQ volatility expansion', 'SQQQ daily gain exceeded 6%; review hedge allocation intensity.', 'HIGH', 'PENDING', '2026-02-16 08:55:00', NOW()),
  (18992, 17992, 1999, 5006, 'PRICE_SPIKE', 'GLDM momentum extension', 'GLDM outperformed target band; evaluate partial profit-taking and rebalance.', 'MEDIUM', 'SENT', '2026-02-16 08:43:00', NOW()),
  (18993, 17993, 1999, 5008, 'PRICE_DROP', 'QQQ weakness alert', 'QQQ moved into a negative zone; growth sleeve risk check is recommended.', 'MEDIUM', 'READ', '2026-02-16 08:31:00', NOW()),
  (18994, 17994, 1999, NULL, 'SENTIMENT', 'Macro sentiment mixed', 'Last 24h macro news showed rising neutral/negative share.', 'LOW', 'PENDING', '2026-02-16 08:12:00', NOW()),
  (18995, 17992, 1999, 5004, 'YIELD_MOVE', 'Bond sleeve review', 'BND/IEF entered a rate-sensitive zone. Reassess duration balance.', 'LOW', 'SENT', '2026-02-15 16:18:00', NOW()),
  (18996, 17994, 1999, NULL, 'REBALANCE', 'Rebalance candidate detected', 'Top holding concentration is near threshold; check the advice card.', 'MEDIUM', 'PENDING', '2026-02-15 09:05:00', NOW())
ON DUPLICATE KEY UPDATE
  event_type = VALUES(event_type),
  title = VALUES(title),
  message = VALUES(message),
  severity = VALUES(severity),
  status = VALUES(status),
  occurred_at = VALUES(occurred_at);
