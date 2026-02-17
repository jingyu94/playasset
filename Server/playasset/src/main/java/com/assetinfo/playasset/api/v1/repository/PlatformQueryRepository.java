package com.assetinfo.playasset.api.v1.repository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import com.assetinfo.playasset.api.v1.dto.AlertResponse;
import com.assetinfo.playasset.api.v1.dto.CreateTransactionRequest;
import com.assetinfo.playasset.api.v1.dto.CreateTransactionResponse;
import com.assetinfo.playasset.api.v1.dto.DashboardResponse;
import com.assetinfo.playasset.api.v1.dto.MoverSnapshot;
import com.assetinfo.playasset.api.v1.dto.PositionSnapshot;
import com.assetinfo.playasset.api.v1.dto.SentimentSnapshot;
import com.assetinfo.playasset.api.v1.dto.WatchlistItemResponse;

@Repository
public class PlatformQueryRepository {

    private final JdbcTemplate jdbcTemplate;

    public PlatformQueryRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public DashboardResponse loadDashboard(long userId) {
        String summarySql = """
                SELECT
                    COALESCE(SUM(p.quantity * COALESCE(mc.close_price, p.avg_cost)), 0) AS portfolio_value,
                    COALESCE(SUM(p.quantity * (COALESCE(mc.close_price, p.avg_cost) - p.avg_cost)), 0) AS daily_pnl
                FROM portfolios pf
                JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                JOIN portfolio_positions p ON p.account_id = pa.account_id
                LEFT JOIN market_price_candles mc
                    ON mc.asset_id = p.asset_id
                   AND mc.interval_code = '1d'
                   AND mc.candle_time = (
                       SELECT MAX(c2.candle_time)
                       FROM market_price_candles c2
                       WHERE c2.asset_id = p.asset_id
                         AND c2.interval_code = '1d'
                   )
                WHERE pf.user_id = ?
                """;

        Map<String, Object> summary = jdbcTemplate.queryForMap(summarySql, userId);
        BigDecimal portfolioValue = getBigDecimal(summary.get("portfolio_value"));
        BigDecimal dailyPnl = getBigDecimal(summary.get("daily_pnl"));
        BigDecimal dailyPnlRate = BigDecimal.ZERO;
        if (portfolioValue.compareTo(BigDecimal.ZERO) > 0) {
            dailyPnlRate = dailyPnl.divide(portfolioValue, 6, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .setScale(2, RoundingMode.HALF_UP);
        }

        int watchlistCount = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM watchlists w
                JOIN watchlist_items wi ON wi.watchlist_id = w.watchlist_id
                WHERE w.user_id = ?
                """, Integer.class, userId);

        int unreadAlertCount = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM alert_events ae
                LEFT JOIN user_preferences up ON up.user_id = ae.user_id
                WHERE ae.user_id = ?
                  AND ae.status IN ('PENDING', 'SENT')
                  AND (
                      (ae.severity = 'LOW' AND COALESCE(up.alert_level_low_enabled, 1) = 1)
                      OR (ae.severity = 'MEDIUM' AND COALESCE(up.alert_level_medium_enabled, 1) = 1)
                      OR (ae.severity = 'HIGH' AND COALESCE(up.alert_level_high_enabled, 1) = 1)
                  )
                """, Integer.class, userId);

        SentimentSnapshot sentiment = loadSentimentSnapshot();
        List<PositionSnapshot> topPositions = loadPositions(userId).stream().limit(4).toList();
        List<MoverSnapshot> topMovers = loadTopMovers();

        return new DashboardResponse(
                userId,
                portfolioValue.setScale(2, RoundingMode.HALF_UP),
                dailyPnl.setScale(2, RoundingMode.HALF_UP),
                dailyPnlRate,
                watchlistCount,
                unreadAlertCount,
                sentiment,
                topPositions,
                topMovers);
    }

    public List<PositionSnapshot> loadPositions(long userId) {
        String sql = """
                SELECT
                    a.asset_id,
                    a.symbol,
                    a.name AS asset_name,
                    p.quantity,
                    p.avg_cost,
                    COALESCE(mc.close_price, p.avg_cost) AS current_price,
                    (p.quantity * COALESCE(mc.close_price, p.avg_cost)) AS valuation,
                    CASE
                      WHEN p.avg_cost = 0 THEN 0
                      ELSE ((COALESCE(mc.close_price, p.avg_cost) - p.avg_cost) / p.avg_cost) * 100
                    END AS pnl_rate
                FROM portfolios pf
                JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                JOIN portfolio_positions p ON p.account_id = pa.account_id
                JOIN assets a ON a.asset_id = p.asset_id
                LEFT JOIN market_price_candles mc
                    ON mc.asset_id = p.asset_id
                   AND mc.interval_code = '1d'
                   AND mc.candle_time = (
                       SELECT MAX(c2.candle_time)
                       FROM market_price_candles c2
                       WHERE c2.asset_id = p.asset_id
                         AND c2.interval_code = '1d'
                   )
                WHERE pf.user_id = ?
                ORDER BY valuation DESC
                """;
        return jdbcTemplate.query(sql, positionMapper(), userId);
    }

    public List<WatchlistItemResponse> loadDefaultWatchlist(long userId) {
        String sql = """
                SELECT
                    a.asset_id,
                    a.symbol,
                    a.name AS asset_name,
                    COALESCE(mc.close_price, 0) AS last_price,
                    CASE
                      WHEN COALESCE(mc.open_price, 0) = 0 THEN 0
                      ELSE ((mc.close_price - mc.open_price) / mc.open_price) * 100
                    END AS change_rate,
                    COALESCE(wi.note, '') AS note
                FROM watchlists w
                JOIN watchlist_items wi ON wi.watchlist_id = w.watchlist_id
                JOIN assets a ON a.asset_id = wi.asset_id
                LEFT JOIN market_price_candles mc
                    ON mc.asset_id = a.asset_id
                   AND mc.interval_code = '1d'
                   AND mc.candle_time = (
                       SELECT MAX(c2.candle_time)
                       FROM market_price_candles c2
                       WHERE c2.asset_id = a.asset_id
                         AND c2.interval_code = '1d'
                   )
                WHERE w.user_id = ?
                  AND w.is_default = 1
                ORDER BY ABS(change_rate) DESC, a.symbol
                """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> new WatchlistItemResponse(
                rs.getLong("asset_id"),
                rs.getString("symbol"),
                rs.getString("asset_name"),
                rs.getBigDecimal("last_price").setScale(2, RoundingMode.HALF_UP),
                rs.getBigDecimal("change_rate").setScale(2, RoundingMode.HALF_UP),
                rs.getString("note")), userId);
    }

    public List<AlertResponse> loadRecentAlerts(long userId, int limit) {
        String sql = """
                SELECT alert_event_id, event_type, title, message, severity, status, occurred_at
                FROM alert_events ae
                LEFT JOIN user_preferences up ON up.user_id = ae.user_id
                WHERE ae.user_id = ?
                  AND (
                      (ae.severity = 'LOW' AND COALESCE(up.alert_level_low_enabled, 1) = 1)
                      OR (ae.severity = 'MEDIUM' AND COALESCE(up.alert_level_medium_enabled, 1) = 1)
                      OR (ae.severity = 'HIGH' AND COALESCE(up.alert_level_high_enabled, 1) = 1)
                  )
                ORDER BY ae.occurred_at DESC
                LIMIT ?
                """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> new AlertResponse(
                rs.getLong("alert_event_id"),
                rs.getString("event_type"),
                rs.getString("title"),
                rs.getString("message"),
                rs.getString("severity"),
                rs.getString("status"),
                Objects.toString(rs.getTimestamp("occurred_at"), null)), userId, limit);
    }

    public AlertPreferenceRow loadAlertPreference(long userId) {
        String sql = """
                SELECT
                    COALESCE(alert_level_low_enabled, 1) AS low_enabled,
                    COALESCE(alert_level_medium_enabled, 1) AS medium_enabled,
                    COALESCE(alert_level_high_enabled, 1) AS high_enabled
                FROM user_preferences
                WHERE user_id = ?
                LIMIT 1
                """;
        List<AlertPreferenceRow> rows = jdbcTemplate.query(sql, (rs, rowNum) -> new AlertPreferenceRow(
                rs.getBoolean("low_enabled"),
                rs.getBoolean("medium_enabled"),
                rs.getBoolean("high_enabled")), userId);
        if (rows.isEmpty()) {
            return new AlertPreferenceRow(true, true, true);
        }
        return rows.get(0);
    }

    public void upsertAlertPreference(long userId, boolean lowEnabled, boolean mediumEnabled, boolean highEnabled) {
        jdbcTemplate.update("""
                INSERT INTO user_preferences(
                    user_id,
                    timezone,
                    locale,
                    push_enabled,
                    email_enabled,
                    alert_level_low_enabled,
                    alert_level_medium_enabled,
                    alert_level_high_enabled,
                    created_at,
                    updated_at
                )
                VALUES (?, 'Asia/Seoul', 'ko-KR', 1, 0, ?, ?, ?, NOW(), NOW())
                ON DUPLICATE KEY UPDATE
                    alert_level_low_enabled = VALUES(alert_level_low_enabled),
                    alert_level_medium_enabled = VALUES(alert_level_medium_enabled),
                    alert_level_high_enabled = VALUES(alert_level_high_enabled),
                    updated_at = NOW()
                """, userId, lowEnabled, mediumEnabled, highEnabled);
    }

    public InvestmentProfileRow loadInvestmentProfile(long userId) {
        String sql = """
                SELECT
                    profile_key,
                    profile_name,
                    short_label,
                    profile_summary,
                    risk_score,
                    risk_tier,
                    target_allocation_hint,
                    answers_json,
                    updated_at
                FROM TM_INVEST_PROFILE_MAIN
                WHERE user_id = ?
                LIMIT 1
                """;
        List<InvestmentProfileRow> rows = jdbcTemplate.query(sql, (rs, rowNum) -> new InvestmentProfileRow(
                rs.getString("profile_key"),
                rs.getString("profile_name"),
                rs.getString("short_label"),
                rs.getString("profile_summary"),
                rs.getInt("risk_score"),
                rs.getInt("risk_tier"),
                rs.getString("target_allocation_hint"),
                rs.getString("answers_json"),
                Objects.toString(rs.getTimestamp("updated_at"), null)), userId);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public void upsertInvestmentProfile(
            long userId,
            String profileKey,
            String profileName,
            String shortLabel,
            String profileSummary,
            int score,
            int riskTier,
            String targetAllocationHint,
            String answersJson,
            String updatedBy) {
        jdbcTemplate.update("""
                INSERT INTO TM_INVEST_PROFILE_MAIN(
                    user_id,
                    profile_key,
                    profile_name,
                    short_label,
                    profile_summary,
                    risk_score,
                    risk_tier,
                    target_allocation_hint,
                    answers_json,
                    updated_by,
                    created_at,
                    updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
                ON DUPLICATE KEY UPDATE
                    profile_key = VALUES(profile_key),
                    profile_name = VALUES(profile_name),
                    short_label = VALUES(short_label),
                    profile_summary = VALUES(profile_summary),
                    risk_score = VALUES(risk_score),
                    risk_tier = VALUES(risk_tier),
                    target_allocation_hint = VALUES(target_allocation_hint),
                    answers_json = VALUES(answers_json),
                    updated_by = VALUES(updated_by),
                    updated_at = NOW()
                """,
                userId,
                profileKey,
                profileName,
                shortLabel,
                profileSummary,
                score,
                riskTier,
                targetAllocationHint,
                answersJson,
                updatedBy);
    }

    public void deleteInvestmentProfile(long userId) {
        jdbcTemplate.update("DELETE FROM TM_INVEST_PROFILE_MAIN WHERE user_id = ?", userId);
    }

    public PromptTemplateRow loadPromptTemplate(String promptKey) {
        String sql = """
                SELECT prompt_key, prompt_version, prompt_template
                FROM TM_LLM_PROMPT_MAIN
                WHERE prompt_key = ?
                  AND use_yn = 1
                ORDER BY updated_at DESC, prompt_id DESC
                LIMIT 1
                """;
        List<PromptTemplateRow> rows = jdbcTemplate.query(sql, (rs, rowNum) -> new PromptTemplateRow(
                rs.getString("prompt_key"),
                rs.getString("prompt_version"),
                rs.getString("prompt_template")), promptKey);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Map<String, String> loadRuntimeConfigMap(String groupCode) {
        String sql = """
                SELECT config_key, config_value
                FROM TM_STD_RUNTIME_CONFIG_MAIN
                WHERE config_group_cd = ?
                  AND use_yn = 1
                ORDER BY sort_no, runtime_config_id
                """;
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, groupCode);
        Map<String, String> result = new java.util.LinkedHashMap<>();
        for (Map<String, Object> row : rows) {
            String key = Objects.toString(row.get("config_key"), "");
            String value = Objects.toString(row.get("config_value"), "");
            if (!key.isBlank()) {
                result.put(key, value);
            }
        }
        return result;
    }

    public List<MoverSnapshot> loadTopMovers() {
        String sql = """
                SELECT
                    a.symbol,
                    a.name AS asset_name,
                    mc.open_price,
                    mc.close_price,
                    CASE
                      WHEN mc.open_price = 0 THEN 0
                      ELSE ((mc.close_price - mc.open_price) / mc.open_price) * 100
                    END AS change_rate
                FROM assets a
                JOIN market_price_candles mc ON mc.asset_id = a.asset_id
                WHERE mc.interval_code = '1d'
                  AND mc.candle_time = (
                    SELECT MAX(c2.candle_time)
                    FROM market_price_candles c2
                    WHERE c2.asset_id = a.asset_id
                      AND c2.interval_code = '1d'
                  )
                ORDER BY ABS(change_rate) DESC
                LIMIT 4
                """;
        return jdbcTemplate.query(sql, moverMapper());
    }

    public SentimentSnapshot loadSentimentSnapshot() {
        String sql = """
                SELECT ns.sentiment_label, COUNT(*) AS cnt
                FROM news_sentiment_scores ns
                JOIN news_articles na ON na.article_id = ns.article_id
                WHERE na.published_at >= NOW() - INTERVAL 7 DAY
                GROUP BY ns.sentiment_label
                """;
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
        int positive = 0;
        int neutral = 0;
        int negative = 0;
        for (Map<String, Object> row : rows) {
            String label = Objects.toString(row.get("sentiment_label"), "NEUTRAL");
            int count = ((Number) row.get("cnt")).intValue();
            switch (label) {
                case "POSITIVE" -> positive = count;
                case "NEGATIVE" -> negative = count;
                default -> neutral = count;
            }
        }
        return new SentimentSnapshot(positive, neutral, negative);
    }

    public List<DailyPortfolioValuePoint> loadPortfolioDailyValues(long userId, int lookbackDays) {
        String sql = """
                SELECT
                    DATE(mc.candle_time) AS price_date,
                    COALESCE(SUM(p.quantity * mc.close_price), 0) AS portfolio_value
                FROM portfolios pf
                JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                JOIN portfolio_positions p ON p.account_id = pa.account_id
                JOIN market_price_candles mc
                    ON mc.asset_id = p.asset_id
                   AND mc.interval_code = '1d'
                WHERE pf.user_id = ?
                  AND mc.candle_time >= DATE_SUB(CURRENT_DATE, INTERVAL ? DAY)
                GROUP BY DATE(mc.candle_time)
                ORDER BY price_date
                """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> new DailyPortfolioValuePoint(
                rs.getDate("price_date").toLocalDate(),
                rs.getBigDecimal("portfolio_value").setScale(2, RoundingMode.HALF_UP)), userId, lookbackDays);
    }

    public List<EtfCatalogRow> loadAdvisorEtfCatalog() {
        String sql = """
                SELECT etf_id, symbol, name, market, focus_theme, risk_bucket, diversification_role, expense_ratio_pct
                FROM advisor_etf_catalog
                WHERE is_active = 1
                ORDER BY expense_ratio_pct ASC, symbol ASC
                """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> new EtfCatalogRow(
                rs.getLong("etf_id"),
                rs.getString("symbol"),
                rs.getString("name"),
                rs.getString("market"),
                rs.getString("focus_theme"),
                rs.getString("risk_bucket"),
                rs.getString("diversification_role"),
                rs.getBigDecimal("expense_ratio_pct").setScale(4, RoundingMode.HALF_UP)));
    }

    public void insertPortfolioAdviceLog(
            long userId,
            String adviceHeadline,
            String riskLevel,
            BigDecimal sharpeRatio,
            BigDecimal concentrationPct,
            LocalDateTime generatedAt) {
        jdbcTemplate.update("""
                INSERT INTO portfolio_advice_logs
                (user_id, advice_headline, risk_level, sharpe_ratio, concentration_pct, generated_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                userId,
                adviceHeadline,
                riskLevel,
                sharpeRatio,
                concentrationPct,
                Timestamp.valueOf(generatedAt));
    }

    public void insertPromptExecutionLog(
            String promptKey,
            String promptVersion,
            Long userId,
            boolean cacheHit,
            Integer tokenInCount,
            Integer tokenOutCount,
            Integer elapsedMs,
            String statusCode,
            String errorMessage) {
        jdbcTemplate.update("""
                INSERT INTO TX_LLM_PROMPT_EXEC_LOG(
                    prompt_key,
                    prompt_version,
                    user_id,
                    cache_hit_yn,
                    token_in_cnt,
                    token_out_cnt,
                    elapsed_ms,
                    status_cd,
                    error_message,
                    created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
                """,
                promptKey,
                promptVersion,
                userId,
                cacheHit ? 1 : 0,
                tokenInCount,
                tokenOutCount,
                elapsedMs,
                statusCode,
                errorMessage);
    }

    public List<Long> findUsersWithOpenPositions() {
        return jdbcTemplate.query("""
                SELECT DISTINCT pf.user_id
                FROM portfolios pf
                JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                JOIN portfolio_positions p ON p.account_id = pa.account_id
                WHERE p.quantity > 0
                ORDER BY pf.user_id
                """, (rs, rowNum) -> rs.getLong("user_id"));
    }

    public LocalDate findDefaultSimulationStartDate(long userId) {
        List<LocalDate> rows = jdbcTemplate.query("""
                SELECT DATE(MIN(pt.occurred_at)) AS start_date
                FROM portfolios pf
                JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                JOIN portfolio_positions p ON p.account_id = pa.account_id AND p.quantity > 0
                LEFT JOIN portfolio_transactions pt
                    ON pt.account_id = pa.account_id
                   AND pt.asset_id = p.asset_id
                   AND pt.side = 'BUY'
                WHERE pf.user_id = ?
                """, (rs, rowNum) -> {
                    Date date = rs.getDate("start_date");
                    return date == null ? null : date.toLocalDate();
                }, userId);

        if (rows.isEmpty() || rows.get(0) == null) {
            return null;
        }
        return rows.get(0);
    }

    public List<SimulationDailyValuePoint> loadCurrentPortfolioHistoricalValues(
            long userId,
            LocalDate startDate,
            LocalDate endDate) {
        String sql = """
                WITH latest_daily AS (
                    SELECT
                        asset_id,
                        DATE(candle_time) AS snapshot_date,
                        MAX(candle_time) AS latest_candle_time
                    FROM market_price_candles
                    WHERE interval_code = '1d'
                      AND DATE(candle_time) BETWEEN ? AND ?
                    GROUP BY asset_id, DATE(candle_time)
                )
                SELECT
                    ld.snapshot_date,
                    COALESCE(SUM(p.quantity * mc.close_price), 0) AS simulated_value
                FROM portfolios pf
                JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                JOIN portfolio_positions p ON p.account_id = pa.account_id
                JOIN latest_daily ld ON ld.asset_id = p.asset_id
                JOIN market_price_candles mc
                    ON mc.asset_id = ld.asset_id
                   AND mc.candle_time = ld.latest_candle_time
                   AND mc.interval_code = '1d'
                WHERE pf.user_id = ?
                  AND p.quantity > 0
                  AND ld.snapshot_date BETWEEN ? AND ?
                GROUP BY ld.snapshot_date
                ORDER BY snapshot_date
                """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> new SimulationDailyValuePoint(
                rs.getDate("snapshot_date").toLocalDate(),
                rs.getBigDecimal("simulated_value").setScale(6, RoundingMode.HALF_UP)),
                Date.valueOf(startDate),
                Date.valueOf(endDate),
                userId,
                Date.valueOf(startDate),
                Date.valueOf(endDate));
    }

    public void batchUpsertSimulationSnapshots(
            long userId,
            List<SimulationSnapshotUpsertCommand> commands) {
        if (commands.isEmpty()) {
            return;
        }
        jdbcTemplate.batchUpdate("""
                INSERT INTO portfolio_simulation_snapshots
                (user_id, snapshot_date, simulated_value, base_value, cumulative_return_pct, daily_return_pct, drawdown_pct)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    simulated_value = VALUES(simulated_value),
                    base_value = VALUES(base_value),
                    cumulative_return_pct = VALUES(cumulative_return_pct),
                    daily_return_pct = VALUES(daily_return_pct),
                    drawdown_pct = VALUES(drawdown_pct),
                    updated_at = CURRENT_TIMESTAMP
                """, commands, commands.size(), (ps, item) -> {
                    ps.setLong(1, userId);
                    ps.setDate(2, Date.valueOf(item.snapshotDate()));
                    ps.setBigDecimal(3, item.simulatedValue());
                    ps.setBigDecimal(4, item.baseValue());
                    ps.setBigDecimal(5, item.cumulativeReturnPct());
                    ps.setBigDecimal(6, item.dailyReturnPct());
                    ps.setBigDecimal(7, item.drawdownPct());
                });
    }

    public List<SimulationSnapshotRow> loadSimulationSnapshots(
            long userId,
            LocalDate startDate,
            LocalDate endDate) {
        String sql = """
                SELECT snapshot_date, simulated_value, cumulative_return_pct, daily_return_pct, drawdown_pct
                FROM portfolio_simulation_snapshots
                WHERE user_id = ?
                  AND snapshot_date BETWEEN ? AND ?
                ORDER BY snapshot_date
                """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> new SimulationSnapshotRow(
                rs.getDate("snapshot_date").toLocalDate(),
                rs.getBigDecimal("simulated_value").setScale(2, RoundingMode.HALF_UP),
                rs.getBigDecimal("cumulative_return_pct").setScale(4, RoundingMode.HALF_UP),
                rs.getBigDecimal("daily_return_pct").setScale(4, RoundingMode.HALF_UP),
                rs.getBigDecimal("drawdown_pct").setScale(4, RoundingMode.HALF_UP)),
                userId,
                Date.valueOf(startDate),
                Date.valueOf(endDate));
    }

    public List<SimulationPositionContributionRow> loadSimulationPositionContributions(
            long userId,
            LocalDate startDate,
            LocalDate endDate) {
        String sql = """
                SELECT
                    a.asset_id,
                    a.symbol,
                    a.name AS asset_name,
                    p.quantity,
                    COALESCE(
                        (
                            SELECT c1.close_price
                            FROM market_price_candles c1
                            WHERE c1.asset_id = p.asset_id
                              AND c1.interval_code = '1d'
                              AND DATE(c1.candle_time) <= ?
                            ORDER BY c1.candle_time DESC
                            LIMIT 1
                        ),
                        p.avg_cost
                    ) AS start_price,
                    COALESCE(
                        (
                            SELECT c2.close_price
                            FROM market_price_candles c2
                            WHERE c2.asset_id = p.asset_id
                              AND c2.interval_code = '1d'
                              AND DATE(c2.candle_time) <= ?
                            ORDER BY c2.candle_time DESC
                            LIMIT 1
                        ),
                        p.avg_cost
                    ) AS end_price
                FROM portfolios pf
                JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                JOIN portfolio_positions p ON p.account_id = pa.account_id
                JOIN assets a ON a.asset_id = p.asset_id
                WHERE pf.user_id = ?
                  AND p.quantity > 0
                ORDER BY p.quantity DESC
                """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            BigDecimal quantity = rs.getBigDecimal("quantity").setScale(6, RoundingMode.HALF_UP);
            BigDecimal startPrice = rs.getBigDecimal("start_price").setScale(2, RoundingMode.HALF_UP);
            BigDecimal endPrice = rs.getBigDecimal("end_price").setScale(2, RoundingMode.HALF_UP);
            BigDecimal pnlAmount = endPrice.subtract(startPrice).multiply(quantity).setScale(2, RoundingMode.HALF_UP);
            BigDecimal pnlRate = startPrice.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP)
                    : endPrice.subtract(startPrice)
                            .divide(startPrice, 8, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                            .setScale(2, RoundingMode.HALF_UP);
            return new SimulationPositionContributionRow(
                    rs.getLong("asset_id"),
                    rs.getString("symbol"),
                    rs.getString("asset_name"),
                    quantity,
                    startPrice,
                    endPrice,
                    pnlAmount,
                    pnlRate);
        }, Date.valueOf(startDate), Date.valueOf(endDate), userId);
    }

    public CreateTransactionResponse createTransaction(CreateTransactionRequest request) {
        LocalDateTime occurredAt = request.occurredAt() == null || request.occurredAt().isBlank()
                ? LocalDateTime.now()
                : LocalDateTime.parse(request.occurredAt());

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                    INSERT INTO portfolio_transactions
                    (account_id, asset_id, side, quantity, price, fee, tax, occurred_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, new String[] { "transaction_id" });
            ps.setLong(1, request.accountId());
            ps.setLong(2, request.assetId());
            ps.setString(3, request.side().toUpperCase());
            ps.setBigDecimal(4, request.quantity());
            ps.setBigDecimal(5, request.price());
            ps.setBigDecimal(6, request.fee());
            ps.setBigDecimal(7, request.tax());
            ps.setTimestamp(8, Timestamp.valueOf(occurredAt));
            return ps;
        }, keyHolder);

        PositionState state = findPositionState(request.accountId(), request.assetId());
        BigDecimal quantity = state.quantity();
        BigDecimal avgCost = state.avgCost();
        BigDecimal realizedPnl = state.realizedPnl();

        String side = request.side().toUpperCase();
        if ("BUY".equals(side)) {
            BigDecimal newQuantity = quantity.add(request.quantity());
            BigDecimal numerator = avgCost.multiply(quantity).add(request.price().multiply(request.quantity()));
            BigDecimal newAvgCost = newQuantity.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : numerator.divide(newQuantity, 6, RoundingMode.HALF_UP);
            upsertPosition(request.accountId(), request.assetId(), newQuantity, newAvgCost, realizedPnl);
            quantity = newQuantity;
            avgCost = newAvgCost;
        } else if ("SELL".equals(side)) {
            BigDecimal sellQty = request.quantity();
            BigDecimal sellable = quantity.min(sellQty);
            BigDecimal newQuantity = quantity.subtract(sellable).max(BigDecimal.ZERO);
            BigDecimal realizedDelta = request.price().subtract(avgCost).multiply(sellable)
                    .subtract(request.fee())
                    .subtract(request.tax());
            BigDecimal newRealized = realizedPnl.add(realizedDelta);
            BigDecimal newAvg = newQuantity.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ZERO : avgCost;
            upsertPosition(request.accountId(), request.assetId(), newQuantity, newAvg, newRealized);
            quantity = newQuantity;
            avgCost = newAvg;
            realizedPnl = newRealized;
        }

        Number generated = null;
        if (keyHolder.getKeys() != null) {
            generated = (Number) keyHolder.getKeys().get("transaction_id");
        }
        if (generated == null) {
            generated = keyHolder.getKey();
        }
        long transactionId = generated == null ? -1L : generated.longValue();

        return new CreateTransactionResponse(
                transactionId,
                request.accountId(),
                request.assetId(),
                side,
                request.quantity(),
                request.price(),
                quantity.setScale(6, RoundingMode.HALF_UP),
                avgCost.setScale(6, RoundingMode.HALF_UP),
                realizedPnl.setScale(6, RoundingMode.HALF_UP));
    }

    public boolean isAccountOwnedByUser(long userId, long accountId) {
        Integer count = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM portfolios pf
                JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                WHERE pf.user_id = ?
                  AND pa.account_id = ?
                """, Integer.class, userId, accountId);
        return count != null && count > 0;
    }

    public Long findAssetIdBySymbol(String symbol) {
        if (symbol == null || symbol.isBlank()) {
            return null;
        }
        List<Long> rows = jdbcTemplate.query(
                """
                        SELECT asset_id
                        FROM assets
                        WHERE UPPER(symbol) = UPPER(?)
                          AND is_active = 1
                        ORDER BY asset_id DESC
                        LIMIT 1
                        """,
                (rs, rowNum) -> rs.getLong("asset_id"),
                symbol.trim());
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Long findPrimaryAccountIdByUser(long userId) {
        List<Long> rows = jdbcTemplate.query(
                """
                        SELECT pa.account_id
                        FROM portfolios pf
                        JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                        WHERE pf.user_id = ?
                        ORDER BY pa.account_id
                        LIMIT 1
                        """,
                (rs, rowNum) -> rs.getLong("account_id"),
                userId);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Long findOwnedAccountIdByUserAndAsset(long userId, long assetId) {
        List<Long> rows = jdbcTemplate.query(
                """
                        SELECT p.account_id
                        FROM portfolios pf
                        JOIN portfolio_accounts pa ON pa.portfolio_id = pf.portfolio_id
                        JOIN portfolio_positions p ON p.account_id = pa.account_id
                        WHERE pf.user_id = ?
                          AND p.asset_id = ?
                        ORDER BY p.account_id
                        LIMIT 1
                        """,
                (rs, rowNum) -> rs.getLong("account_id"),
                userId,
                assetId);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public void upsertPositionByAccount(long accountId, long assetId, BigDecimal quantity, BigDecimal avgCost) {
        PositionState state = findPositionState(accountId, assetId);
        upsertPosition(accountId, assetId, quantity, avgCost, state.realizedPnl());
    }

    public List<Long> findAllAssetIds() {
        return jdbcTemplate.query("SELECT asset_id FROM assets WHERE is_active = 1 ORDER BY asset_id",
                (rs, rowNum) -> rs.getLong("asset_id"));
    }

    public List<AssetMarketSyncTarget> findAllAssetSyncTargets() {
        return jdbcTemplate.query("""
                SELECT asset_id, symbol, market, currency
                FROM assets
                WHERE is_active = 1
                ORDER BY
                    CASE WHEN currency = 'USD' THEN 0 ELSE 1 END,
                    asset_id
                """, (rs, rowNum) -> new AssetMarketSyncTarget(
                rs.getLong("asset_id"),
                rs.getString("symbol"),
                rs.getString("market"),
                rs.getString("currency")));
    }

    public void batchUpsertAssetCatalog(List<AssetCatalogUpsertCommand> commands) {
        if (commands == null || commands.isEmpty()) {
            return;
        }
        jdbcTemplate.batchUpdate("""
                INSERT INTO assets(symbol, name, market, currency, is_active, created_at, updated_at)
                VALUES (?, ?, ?, ?, 1, NOW(), NOW())
                ON DUPLICATE KEY UPDATE
                    name = VALUES(name),
                    currency = VALUES(currency),
                    is_active = 1,
                    updated_at = NOW()
                """, commands, commands.size(), (ps, item) -> {
                    ps.setString(1, item.symbol());
                    ps.setString(2, item.assetName());
                    ps.setString(3, item.market());
                    ps.setString(4, item.currency());
                });
    }

    public int countActiveAssetsByMarketPrefix(String marketPrefix) {
        Integer count = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM assets
                WHERE is_active = 1
                  AND market LIKE CONCAT(?, '%')
                """, Integer.class, marketPrefix);
        return count == null ? 0 : count;
    }

    public void batchUpsertDailyCandles(List<CandleUpsertCommand> commands) {
        if (commands.isEmpty()) {
            return;
        }

        jdbcTemplate.batchUpdate("""
                INSERT INTO market_price_candles
                (asset_id, interval_code, candle_time, open_price, high_price, low_price, close_price, volume)
                VALUES (?, '1d', ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    open_price = VALUES(open_price),
                    high_price = VALUES(high_price),
                    low_price = VALUES(low_price),
                    close_price = VALUES(close_price),
                    volume = VALUES(volume)
                """, commands, commands.size(), (ps, item) -> {
                    ps.setLong(1, item.assetId());
                    ps.setTimestamp(2, Timestamp.valueOf(item.candleTime()));
                    ps.setBigDecimal(3, item.openPrice());
                    ps.setBigDecimal(4, item.highPrice());
                    ps.setBigDecimal(5, item.lowPrice());
                    ps.setBigDecimal(6, item.closePrice());
                    ps.setBigDecimal(7, item.volume());
                });
    }

    public BigDecimal findLatestClosePrice(long assetId) {
        String sql = """
                SELECT close_price
                FROM market_price_candles
                WHERE asset_id = ?
                  AND interval_code = '1d'
                ORDER BY candle_time DESC
                LIMIT 1
                """;
        List<BigDecimal> values = jdbcTemplate.query(sql, (rs, rowNum) -> rs.getBigDecimal("close_price"), assetId);
        if (values.isEmpty()) {
            return BigDecimal.valueOf(10000);
        }
        return values.get(0);
    }

    public void insertIngestionJob(String jobType, String sourceKey, int recordsIn, int recordsOut, String status,
            String errorMessage, LocalDateTime startedAt, LocalDateTime finishedAt) {
        jdbcTemplate.update("""
                INSERT INTO ingestion_jobs
                (job_type, source_key, window_start, window_end, status, records_in, records_out, error_message, started_at, finished_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                jobType,
                sourceKey,
                Timestamp.valueOf(startedAt.toLocalDate().atStartOfDay()),
                Timestamp.valueOf(finishedAt),
                status,
                recordsIn,
                recordsOut,
                errorMessage,
                Timestamp.valueOf(startedAt),
                Timestamp.valueOf(finishedAt));
    }

    public long ensureInternalNewsSource() {
        jdbcTemplate.update("""
                INSERT INTO news_sources(name, site_url, is_active)
                VALUES ('internal-simulator', 'https://internal.local', 1)
                ON DUPLICATE KEY UPDATE is_active = 1
                """);
        return jdbcTemplate.queryForObject(
                "SELECT source_id FROM news_sources WHERE name = 'internal-simulator' LIMIT 1",
                Long.class);
    }

    public void insertSyntheticNews(long sourceId, long assetId, String title, String body, String sentimentLabel,
            BigDecimal sentimentScore, String externalId) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                    INSERT INTO news_articles
                    (source_id, external_id, title, body, language, published_at)
                    VALUES (?, ?, ?, ?, 'ko', ?)
                    ON DUPLICATE KEY UPDATE
                        title = VALUES(title),
                        body = VALUES(body),
                        published_at = VALUES(published_at)
                    """, new String[] { "article_id" });
            ps.setLong(1, sourceId);
            ps.setString(2, externalId);
            ps.setString(3, title);
            ps.setString(4, body);
            ps.setTimestamp(5, Timestamp.valueOf(LocalDateTime.now()));
            return ps;
        }, keyHolder);

        Number articleIdNumber = null;
        if (keyHolder.getKeys() != null) {
            articleIdNumber = (Number) keyHolder.getKeys().get("article_id");
        }
        if (articleIdNumber == null) {
            articleIdNumber = keyHolder.getKey();
        }
        long articleId;
        if (articleIdNumber == null) {
            articleId = jdbcTemplate.queryForObject("""
                    SELECT article_id
                    FROM news_articles
                    WHERE source_id = ?
                      AND external_id = ?
                    LIMIT 1
                    """, Long.class, sourceId, externalId);
        } else {
            articleId = articleIdNumber.longValue();
        }

        jdbcTemplate.update("""
                INSERT INTO news_asset_mentions(article_id, asset_id, confidence_score)
                VALUES (?, ?, 0.7500)
                ON DUPLICATE KEY UPDATE confidence_score = VALUES(confidence_score)
                """, articleId, assetId);

        jdbcTemplate.update("""
                INSERT INTO news_sentiment_scores(article_id, model_version, sentiment_label, sentiment_score)
                VALUES (?, 'sim-v1', ?, ?)
                ON DUPLICATE KEY UPDATE
                    sentiment_label = VALUES(sentiment_label),
                    sentiment_score = VALUES(sentiment_score)
                """, articleId, sentimentLabel, sentimentScore);
    }

    public String findAssetName(long assetId) {
        return jdbcTemplate.queryForObject("SELECT name FROM assets WHERE asset_id = ?", String.class, assetId);
    }

    public void insertAlertEvent(long ruleId, long userId, long assetId, String eventType, String title, String message,
            String severity, String status) {
        jdbcTemplate.update("""
                INSERT INTO alert_events(rule_id, user_id, asset_id, event_type, title, message, severity, status, occurred_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, ruleId, userId, assetId, eventType, title, message, severity, status, Timestamp.valueOf(LocalDateTime.now()));
    }

    private void upsertPosition(long accountId, long assetId, BigDecimal quantity, BigDecimal avgCost, BigDecimal realizedPnl) {
        int updated = jdbcTemplate.update("""
                UPDATE portfolio_positions
                SET quantity = ?, avg_cost = ?, realized_pnl = ?, updated_at = NOW()
                WHERE account_id = ? AND asset_id = ?
                """, quantity, avgCost, realizedPnl, accountId, assetId);

        if (updated == 0) {
            jdbcTemplate.update("""
                    INSERT INTO portfolio_positions(account_id, asset_id, quantity, avg_cost, realized_pnl)
                    VALUES (?, ?, ?, ?, ?)
                    """, accountId, assetId, quantity, avgCost, realizedPnl);
        }
    }

    private PositionState findPositionState(long accountId, long assetId) {
        String sql = """
                SELECT quantity, avg_cost, realized_pnl
                FROM portfolio_positions
                WHERE account_id = ? AND asset_id = ?
                LIMIT 1
                """;
        List<PositionState> states = jdbcTemplate.query(sql, (rs, rowNum) -> new PositionState(
                rs.getBigDecimal("quantity"),
                rs.getBigDecimal("avg_cost"),
                rs.getBigDecimal("realized_pnl")), accountId, assetId);

        if (states.isEmpty()) {
            return new PositionState(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO);
        }
        return states.get(0);
    }

    private BigDecimal getBigDecimal(Object value) {
        if (value == null) {
            return BigDecimal.ZERO;
        }
        if (value instanceof BigDecimal decimal) {
            return decimal;
        }
        return new BigDecimal(value.toString());
    }

    private RowMapper<PositionSnapshot> positionMapper() {
        return (rs, rowNum) -> new PositionSnapshot(
                rs.getLong("asset_id"),
                rs.getString("symbol"),
                rs.getString("asset_name"),
                rs.getBigDecimal("quantity").setScale(6, RoundingMode.HALF_UP),
                rs.getBigDecimal("avg_cost").setScale(2, RoundingMode.HALF_UP),
                rs.getBigDecimal("current_price").setScale(2, RoundingMode.HALF_UP),
                rs.getBigDecimal("valuation").setScale(2, RoundingMode.HALF_UP),
                rs.getBigDecimal("pnl_rate").setScale(2, RoundingMode.HALF_UP));
    }

    private RowMapper<MoverSnapshot> moverMapper() {
        return (rs, rowNum) -> new MoverSnapshot(
                rs.getString("symbol"),
                rs.getString("asset_name"),
                rs.getBigDecimal("open_price").setScale(2, RoundingMode.HALF_UP),
                rs.getBigDecimal("close_price").setScale(2, RoundingMode.HALF_UP),
                rs.getBigDecimal("change_rate").setScale(2, RoundingMode.HALF_UP));
    }

    public record CandleUpsertCommand(
            long assetId,
            LocalDateTime candleTime,
            BigDecimal openPrice,
            BigDecimal highPrice,
            BigDecimal lowPrice,
            BigDecimal closePrice,
            BigDecimal volume) {
    }

    public record AssetMarketSyncTarget(
            long assetId,
            String symbol,
            String market,
            String currency) {
    }

    public record AssetCatalogUpsertCommand(
            String symbol,
            String assetName,
            String market,
            String currency) {
    }

    public record DailyPortfolioValuePoint(
            LocalDate priceDate,
            BigDecimal portfolioValue) {
    }

    public record AlertPreferenceRow(
            boolean lowEnabled,
            boolean mediumEnabled,
            boolean highEnabled) {
    }

    public record InvestmentProfileRow(
            String profileKey,
            String profileName,
            String shortLabel,
            String profileSummary,
            int riskScore,
            int riskTier,
            String targetAllocationHint,
            String answersJson,
            String updatedAt) {
    }

    public record PromptTemplateRow(
            String promptKey,
            String promptVersion,
            String promptTemplate) {
    }

    public record EtfCatalogRow(
            long etfId,
            String symbol,
            String name,
            String market,
            String focusTheme,
            String riskBucket,
            String diversificationRole,
            BigDecimal expenseRatioPct) {
    }

    public record SimulationDailyValuePoint(
            LocalDate snapshotDate,
            BigDecimal simulatedValue) {
    }

    public record SimulationSnapshotUpsertCommand(
            LocalDate snapshotDate,
            BigDecimal simulatedValue,
            BigDecimal baseValue,
            BigDecimal cumulativeReturnPct,
            BigDecimal dailyReturnPct,
            BigDecimal drawdownPct) {
    }

    public record SimulationSnapshotRow(
            LocalDate snapshotDate,
            BigDecimal simulatedValue,
            BigDecimal cumulativeReturnPct,
            BigDecimal dailyReturnPct,
            BigDecimal drawdownPct) {
    }

    public record SimulationPositionContributionRow(
            long assetId,
            String symbol,
            String assetName,
            BigDecimal quantity,
            BigDecimal startPrice,
            BigDecimal endPrice,
            BigDecimal pnlAmount,
            BigDecimal pnlRate) {
    }

    private record PositionState(BigDecimal quantity, BigDecimal avgCost, BigDecimal realizedPnl) {
    }
}
