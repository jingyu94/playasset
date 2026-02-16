package com.assetinfo.playasset.api.v1.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.assetinfo.playasset.api.v1.auth.Authz;
import com.assetinfo.playasset.api.v1.dto.AdviceMetricsSnapshot;
import com.assetinfo.playasset.api.v1.dto.AlertPreferenceResponse;
import com.assetinfo.playasset.api.v1.dto.AlertResponse;
import com.assetinfo.playasset.api.v1.dto.AiInsightSnapshot;
import com.assetinfo.playasset.api.v1.dto.CreateTransactionRequest;
import com.assetinfo.playasset.api.v1.dto.CreateTransactionResponse;
import com.assetinfo.playasset.api.v1.dto.DashboardResponse;
import com.assetinfo.playasset.api.v1.dto.EtfRecommendationSnapshot;
import com.assetinfo.playasset.api.v1.dto.InvestmentProfileResponse;
import com.assetinfo.playasset.api.v1.dto.PortfolioAdviceResponse;
import com.assetinfo.playasset.api.v1.dto.PortfolioSimulationResponse;
import com.assetinfo.playasset.api.v1.dto.PositionSnapshot;
import com.assetinfo.playasset.api.v1.dto.RebalancingActionSnapshot;
import com.assetinfo.playasset.api.v1.dto.SimulationContributionSnapshot;
import com.assetinfo.playasset.api.v1.dto.SimulationPointSnapshot;
import com.assetinfo.playasset.api.v1.dto.UpdateAlertPreferenceRequest;
import com.assetinfo.playasset.api.v1.dto.UpsertInvestmentProfileRequest;
import com.assetinfo.playasset.api.v1.dto.WatchlistItemResponse;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.DailyPortfolioValuePoint;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.EtfCatalogRow;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.InvestmentProfileRow;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.PromptTemplateRow;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.SimulationDailyValuePoint;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.SimulationPositionContributionRow;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.SimulationSnapshotRow;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.SimulationSnapshotUpsertCommand;
import com.assetinfo.playasset.config.CacheNames;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class PlatformService {

    private final PlatformQueryRepository repository;
    private final PromptCachingService promptCachingService;
    private final RuntimeConfigService runtimeConfigService;
    private final ObjectMapper objectMapper;

    public PlatformService(
            PlatformQueryRepository repository,
            PromptCachingService promptCachingService,
            RuntimeConfigService runtimeConfigService,
            ObjectMapper objectMapper) {
        this.repository = repository;
        this.promptCachingService = promptCachingService;
        this.runtimeConfigService = runtimeConfigService;
        this.objectMapper = objectMapper;
    }

    @Cacheable(cacheNames = CacheNames.DASHBOARD, key = "#userId")
    public DashboardResponse getDashboard(long userId) {
        return repository.loadDashboard(userId);
    }

    @Cacheable(cacheNames = CacheNames.POSITIONS, key = "#userId")
    public List<PositionSnapshot> getPositions(long userId) {
        return repository.loadPositions(userId);
    }

    @Cacheable(cacheNames = CacheNames.WATCHLIST, key = "#userId")
    public List<WatchlistItemResponse> getWatchlist(long userId) {
        return repository.loadDefaultWatchlist(userId);
    }

    @Cacheable(cacheNames = CacheNames.ALERTS, key = "#userId + ':' + #limit")
    public List<AlertResponse> getAlerts(long userId, int limit) {
        return repository.loadRecentAlerts(userId, limit);
    }

    @Cacheable(cacheNames = CacheNames.ALERT_PREFERENCES, key = "#userId")
    public AlertPreferenceResponse getAlertPreference(long userId) {
        var row = repository.loadAlertPreference(userId);
        return new AlertPreferenceResponse(
                userId,
                row.lowEnabled(),
                row.mediumEnabled(),
                row.highEnabled());
    }

    @Caching(evict = {
            @CacheEvict(cacheNames = CacheNames.ALERT_PREFERENCES, key = "#userId"),
            @CacheEvict(cacheNames = CacheNames.ALERTS, allEntries = true),
            @CacheEvict(cacheNames = CacheNames.DASHBOARD, key = "#userId")
    })
    @Transactional
    public AlertPreferenceResponse updateAlertPreference(long userId, UpdateAlertPreferenceRequest request) {
        boolean lowEnabled = request.lowEnabled();
        boolean mediumEnabled = request.mediumEnabled();
        boolean highEnabled = request.highEnabled();
        if (!lowEnabled && !mediumEnabled && !highEnabled) {
            throw new IllegalArgumentException(simulationMessage("alert.error.at_least_one_enabled", "최소 1개 이상의 알림 레벨을 켜야 해요."));
        }
        repository.upsertAlertPreference(userId, lowEnabled, mediumEnabled, highEnabled);
        return getAlertPreference(userId);
    }

    @Cacheable(cacheNames = CacheNames.INVESTMENT_PROFILE, key = "#userId")
    public InvestmentProfileResponse getInvestmentProfile(long userId) {
        InvestmentProfileRow row = repository.loadInvestmentProfile(userId);
        return row == null ? null : toInvestmentProfileResponse(row);
    }

    @Caching(evict = {
            @CacheEvict(cacheNames = CacheNames.INVESTMENT_PROFILE, key = "#userId"),
            @CacheEvict(cacheNames = CacheNames.PORTFOLIO_ADVICE, key = "#userId")
    })
    @Transactional
    public InvestmentProfileResponse upsertInvestmentProfile(long userId, UpsertInvestmentProfileRequest request) {
        String updatedBy = Authz.requireAuthenticated().loginId();
        String answersJson = writeAnswersJson(request.answers());
        repository.upsertInvestmentProfile(
                userId,
                request.profileKey().trim().toUpperCase(Locale.ROOT),
                request.profileName().trim(),
                request.shortLabel().trim(),
                request.summary().trim(),
                request.score(),
                request.riskTier(),
                request.targetAllocationHint().trim(),
                answersJson,
                updatedBy == null || updatedBy.isBlank() ? "SYSTEM" : updatedBy);
        return getInvestmentProfile(userId);
    }

    @Caching(evict = {
            @CacheEvict(cacheNames = CacheNames.INVESTMENT_PROFILE, key = "#userId"),
            @CacheEvict(cacheNames = CacheNames.PORTFOLIO_ADVICE, key = "#userId")
    })
    @Transactional
    public boolean deleteInvestmentProfile(long userId) {
        repository.deleteInvestmentProfile(userId);
        return true;
    }

    @Cacheable(cacheNames = CacheNames.PORTFOLIO_ADVICE, key = "#userId")
    public PortfolioAdviceResponse getPortfolioAdvice(long userId) {
        List<PositionSnapshot> positions = repository.loadPositions(userId);
        if (positions.isEmpty()) {
            return normalizePortfolioAdviceTone(emptyAdvice(userId));
        }
        InvestmentProfileResponse investmentProfile = getInvestmentProfile(userId);
        int maxActionCount = advisorRuleInt("rebal.max_action_count", 6);
        int maxEtfCount = advisorRuleInt("etf.max_recommendation_count", 3);

        BigDecimal totalValue = positions.stream()
                .map(PositionSnapshot::valuation)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);

        double concentrationPct = computeConcentrationPct(positions, totalValue);
        double diversificationScore = computeDiversificationScore(positions, totalValue);
        List<DailyPortfolioValuePoint> dailyValues = repository.loadPortfolioDailyValues(userId, 180);

        AnalyticsMetrics metrics = computeAnalyticsMetrics(
                positions,
                dailyValues,
                totalValue.doubleValue(),
                concentrationPct,
                diversificationScore);

        List<RebalancingActionSnapshot> actions = buildRebalancingActions(
                positions,
                totalValue.doubleValue(),
                investmentProfile,
                maxActionCount);
        List<EtfRecommendationSnapshot> etfRecommendations = buildEtfRecommendations(
                repository.loadAdvisorEtfCatalog(),
                metrics.riskLevel(),
                concentrationPct,
                investmentProfile,
                maxEtfCount);

        AiInsightSnapshot insight = buildAiInsight(metrics, actions, etfRecommendations, investmentProfile);
        PromptTemplateRow promptTemplate = repository.loadPromptTemplate("PORTFOLIO_ADVICE");
        String promptVersion = promptTemplate == null ? "v1.0.0" : promptTemplate.promptVersion();
        String promptBody = promptTemplate == null
                ? "You are a portfolio advisory model. Use profile+metrics+positions to produce structured rebalancing and ETF recommendations. Response language must be Korean. Use casual polite Korean tone ending with '~요' for every human-readable sentence. Never use formal '-습니다' style. Return strict JSON only."
                : promptTemplate.promptTemplate();
        promptCachingService.cachePromptTemplate("PORTFOLIO_ADVICE", promptVersion, promptBody);
        String payloadJson = buildAdvicePromptPayloadJson(
                userId,
                investmentProfile,
                metrics,
                positions,
                actions,
                etfRecommendations,
                maxActionCount,
                maxEtfCount);
        String cacheKey = "portfolio_advice:" + userId + ":" + promptVersion + ":" + LocalDate.now();
        promptCachingService.cachePromptPayload(cacheKey, payloadJson);
        repository.insertPromptExecutionLog(
                "PORTFOLIO_ADVICE",
                promptVersion,
                userId,
                true,
                null,
                null,
                null,
                "CACHED",
                null);
        repository.insertPortfolioAdviceLog(
                userId,
                insight.headline(),
                metrics.riskLevel(),
                metrics.sharpeRatio(),
                metrics.concentrationPct(),
                LocalDateTime.now());

        AdviceMetricsSnapshot metricsSnapshot = new AdviceMetricsSnapshot(
                userId,
                LocalDate.now().toString(),
                metrics.totalValue(),
                metrics.expectedAnnualReturnPct(),
                metrics.annualVolatilityPct(),
                metrics.sharpeRatio(),
                metrics.maxDrawdownPct(),
                metrics.concentrationPct(),
                metrics.diversificationScore(),
                metrics.riskLevel());

        return normalizePortfolioAdviceTone(new PortfolioAdviceResponse(metricsSnapshot, actions, etfRecommendations, insight));
    }

    private String buildAdvicePromptPayloadJson(
            long userId,
            InvestmentProfileResponse investmentProfile,
            AnalyticsMetrics metrics,
            List<PositionSnapshot> positions,
            List<RebalancingActionSnapshot> actions,
            List<EtfRecommendationSnapshot> etfRecommendations,
            int maxActionCount,
            int maxEtfCount) {
        StringBuilder sb = new StringBuilder(1024);
        sb.append("{");
        sb.append("\"userId\":").append(userId).append(",");
        sb.append("\"riskProfile\":{")
                .append("\"profileKey\":\"")
                .append(escapeJson(investmentProfile == null ? "UNKNOWN" : investmentProfile.profileKey()))
                .append("\",")
                .append("\"profileName\":\"")
                .append(escapeJson(investmentProfile == null ? "UNSET" : investmentProfile.profileName()))
                .append("\",")
                .append("\"riskTier\":")
                .append(investmentProfile == null ? 0 : investmentProfile.riskTier())
                .append(",\"score\":")
                .append(investmentProfile == null ? 0 : investmentProfile.score())
                .append(",\"answers\":")
                .append(writeAnswersJson(investmentProfile == null ? Map.of() : investmentProfile.answers()))
                .append("},");
        sb.append("\"riskLevel\":\"").append(escapeJson(metrics.riskLevel())).append("\",");
        sb.append("\"metrics\":{")
                .append("\"expectedAnnualReturnPct\":").append(metrics.expectedAnnualReturnPct())
                .append(",\"annualVolatilityPct\":").append(metrics.annualVolatilityPct())
                .append(",\"sharpeRatio\":").append(metrics.sharpeRatio())
                .append(",\"maxDrawdownPct\":").append(metrics.maxDrawdownPct())
                .append(",\"concentrationPct\":").append(metrics.concentrationPct())
                .append(",\"diversificationScore\":").append(metrics.diversificationScore())
                .append("},");
        sb.append("\"positions\":[");
        for (int i = 0; i < positions.size(); i++) {
            PositionSnapshot position = positions.get(i);
            if (i > 0) {
                sb.append(",");
            }
            sb.append("{")
                    .append("\"symbol\":\"").append(escapeJson(position.symbol())).append("\",")
                    .append("\"assetName\":\"").append(escapeJson(position.assetName())).append("\",")
                    .append("\"valuation\":").append(position.valuation()).append(",")
                    .append("\"pnlRate\":").append(position.pnlRate())
                    .append("}");
        }
        sb.append("],");
        sb.append("\"rebalancingActions\":[");
        for (int i = 0; i < actions.size(); i++) {
            RebalancingActionSnapshot action = actions.get(i);
            if (i > 0) {
                sb.append(",");
            }
            sb.append("{")
                    .append("\"symbol\":\"").append(escapeJson(action.symbol())).append("\",")
                    .append("\"action\":\"").append(escapeJson(action.action())).append("\",")
                    .append("\"gapPct\":").append(action.gapPct()).append(",")
                    .append("\"suggestedAmount\":").append(action.suggestedAmount()).append(",")
                    .append("\"priority\":").append(action.priority())
                    .append("}");
        }
        sb.append("],");
        sb.append("\"etfRecommendations\":[");
        for (int i = 0; i < etfRecommendations.size(); i++) {
            EtfRecommendationSnapshot etf = etfRecommendations.get(i);
            if (i > 0) {
                sb.append(",");
            }
            sb.append("{")
                    .append("\"symbol\":\"").append(escapeJson(etf.symbol())).append("\",")
                    .append("\"riskBucket\":\"").append(escapeJson(etf.riskBucket())).append("\",")
                    .append("\"suggestedWeightPct\":").append(etf.suggestedWeightPct()).append(",")
                    .append("\"matchScore\":").append(etf.matchScore())
                    .append("}");
        }
        sb.append("],");
        sb.append("\"constraints\":{")
                .append("\"maxActions\":").append(maxActionCount).append(",")
                .append("\"maxEtfCandidates\":").append(maxEtfCount).append(",")
                .append("\"language\":\"ko-KR\",")
                .append("\"tone\":\"casual-polite\",")
                .append("\"sentenceEnding\":\"~요\",")
                .append("\"disallowFormalEnding\":\"-습니다\"")
                .append("}");
        sb.append("}");
        return sb.toString();
    }

    private PortfolioAdviceResponse normalizePortfolioAdviceTone(PortfolioAdviceResponse advice) {
        List<RebalancingActionSnapshot> actions = advice.rebalancingActions().stream()
                .map(action -> new RebalancingActionSnapshot(
                        action.assetId(),
                        action.symbol(),
                        action.assetName(),
                        action.action(),
                        action.currentWeightPct(),
                        action.targetWeightPct(),
                        action.gapPct(),
                        action.suggestedAmount(),
                        action.priority(),
                        toYoTone(action.reason())))
                .toList();

        List<EtfRecommendationSnapshot> etfs = advice.etfRecommendations().stream()
                .map(etf -> new EtfRecommendationSnapshot(
                        etf.etfId(),
                        etf.symbol(),
                        etf.name(),
                        etf.market(),
                        etf.focusTheme(),
                        etf.riskBucket(),
                        etf.expenseRatioPct(),
                        etf.suggestedWeightPct(),
                        etf.matchScore(),
                        toYoTone(etf.reason())))
                .toList();

        AiInsightSnapshot insight = advice.insight();
        AiInsightSnapshot normalizedInsight = new AiInsightSnapshot(
                toYoTone(insight.headline()),
                toYoTone(insight.summary()),
                insight.keyPoints().stream().map(this::toYoTone).toList(),
                insight.cautions().stream().map(this::toYoTone).toList(),
                insight.generatedAt(),
                insight.model());

        return new PortfolioAdviceResponse(advice.metrics(), actions, etfs, normalizedInsight);
    }

    private String toYoTone(String text) {
        if (text == null) {
            return "";
        }
        String normalized = text.trim();
        if (normalized.isEmpty()) {
            return normalized;
        }

        normalized = normalized
                .replace("있습니다.", "있어요.")
                .replace("없습니다.", "없어요.")
                .replace("필요합니다.", "필요해요.")
                .replace("권장합니다.", "권장해요.")
                .replace("주의합니다.", "주의해요.")
                .replace("유지합니다.", "유지해요.")
                .replace("진행합니다.", "진행해요.")
                .replace("가능합니다.", "가능해요.")
                .replace("됩니다.", "돼요.")
                .replace("입니다.", "이에요.")
                .replace("합니다.", "해요.")
                .replace("있습니다", "있어요")
                .replace("없습니다", "없어요")
                .replace("필요합니다", "필요해요")
                .replace("권장합니다", "권장해요")
                .replace("주의합니다", "주의해요")
                .replace("유지합니다", "유지해요")
                .replace("진행합니다", "진행해요")
                .replace("가능합니다", "가능해요")
                .replace("됩니다", "돼요")
                .replace("입니다", "이에요")
                .replace("합니다", "해요");

        if (normalized.endsWith("다.")) {
            normalized = normalized.substring(0, normalized.length() - 2) + "요.";
        } else if (normalized.endsWith("다")) {
            normalized = normalized.substring(0, normalized.length() - 1) + "요";
        }

        if (!(normalized.endsWith(".") || normalized.endsWith("!") || normalized.endsWith("?"))) {
            if (normalized.endsWith("요")) {
                return normalized + ".";
            }
            if (normalized.matches(".*[가-힣]$")) {
                return normalized + "요.";
            }
        }
        return normalized;
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    @Cacheable(
            cacheNames = CacheNames.PORTFOLIO_SIMULATION,
            key = "#userId + ':' + (#startDateText == null ? '' : #startDateText) + ':' + (#endDateText == null ? '' : #endDateText)")
    public PortfolioSimulationResponse getPortfolioSimulation(long userId, String startDateText, String endDateText) {
        LocalDate today = LocalDate.now();
        LocalDate endDate = parseDate(endDateText, today);
        if (endDate.isAfter(today)) {
            endDate = today;
        }

        LocalDate defaultStart = repository.findDefaultSimulationStartDate(userId);
        if (defaultStart == null) {
            defaultStart = endDate.minusMonths(6);
        }
        LocalDate startDate = parseDate(startDateText, defaultStart);
        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException(simulationMessage("simulation.error.invalid_date_range", "시작일은 기준일보다 이후일 수 없어요."));
        }

        int lookbackDays = Math.max(120, (int) ChronoUnit.DAYS.between(startDate, endDate) + 14);
        rebuildSimulationCacheForUser(userId, lookbackDays);

        List<SimulationSnapshotRow> rows = repository.loadSimulationSnapshots(userId, startDate, endDate);
        if (rows.isEmpty()) {
            return emptySimulation(userId, startDate, endDate);
        }

        BigDecimal startValue = rows.get(0).simulatedValue().setScale(2, RoundingMode.HALF_UP);
        BigDecimal endValue = rows.get(rows.size() - 1).simulatedValue().setScale(2, RoundingMode.HALF_UP);
        BigDecimal pnlAmount = endValue.subtract(startValue).setScale(2, RoundingMode.HALF_UP);
        BigDecimal pnlRate = ratioPercent(startValue, endValue).setScale(2, RoundingMode.HALF_UP);

        long dayGap = Math.max(1, ChronoUnit.DAYS.between(rows.get(0).snapshotDate(), rows.get(rows.size() - 1).snapshotDate()));
        BigDecimal annualizedReturnPct = dayGap < 90
                ? pnlRate
                : annualizedReturn(startValue, endValue, dayGap).setScale(2, RoundingMode.HALF_UP);
        BigDecimal maxDrawdownPct = rows.stream()
                .map(SimulationSnapshotRow::drawdownPct)
                .max(Comparator.naturalOrder())
                .orElse(BigDecimal.ZERO)
                .setScale(2, RoundingMode.HALF_UP);

        List<SimulationPointSnapshot> timeline = rows.stream()
                .map(row -> new SimulationPointSnapshot(
                        row.snapshotDate().toString(),
                        row.simulatedValue().setScale(2, RoundingMode.HALF_UP),
                        row.cumulativeReturnPct().setScale(2, RoundingMode.HALF_UP),
                        row.drawdownPct().setScale(2, RoundingMode.HALF_UP)))
                .toList();

        List<SimulationContributionSnapshot> contributions = repository
                .loadSimulationPositionContributions(userId, startDate, endDate)
                .stream()
                .sorted((a, b) -> b.pnlAmount().abs().compareTo(a.pnlAmount().abs()))
                .map(row -> new SimulationContributionSnapshot(
                        row.assetId(),
                        row.symbol(),
                        row.assetName(),
                        row.quantity().setScale(4, RoundingMode.HALF_UP),
                        row.startPrice().setScale(2, RoundingMode.HALF_UP),
                        row.endPrice().setScale(2, RoundingMode.HALF_UP),
                        row.pnlAmount().setScale(2, RoundingMode.HALF_UP),
                        row.pnlRate().setScale(2, RoundingMode.HALF_UP)))
                .toList();

        List<String> notes = List.of(
                simulationMessage("simulation.note.1", "실제 체결가와 세금/수수료를 반영하면 결과가 달라질 수 있어요."),
                simulationMessage("simulation.note.2", "조회 구간은 시작가(기준일)와 종료가(평가일) 기준이라 장중 체결가와 차이가 날 수 있어요."),
                dayGap < 90
                        ? simulationMessage("simulation.note.short_period", "조회 기간이 90일 미만이면 연환산 수익률은 참고 지표로 봐 주세요.")
                        : simulationMessage("simulation.note.long_period", "연환산 수익률은 장기 비교용으로 보고, 단기 성과는 누적 수익률과 함께 확인해 주세요."),
                simulationMessage("simulation.note.3", "종목 기여도는 현재 보유수량 기준 추정값이니 리밸런싱 계획과 같이 해석해 주세요."));

        return new PortfolioSimulationResponse(
                userId,
                rows.get(0).snapshotDate().toString(),
                rows.get(rows.size() - 1).snapshotDate().toString(),
                rows.size(),
                startValue,
                endValue,
                pnlAmount,
                pnlRate,
                annualizedReturnPct,
                maxDrawdownPct,
                timeline,
                contributions,
                notes);
    }

    @Transactional
    public int rebuildSimulationCacheForUser(long userId, int lookbackDays) {
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(Math.max(lookbackDays, 30));

        LocalDate buyStart = repository.findDefaultSimulationStartDate(userId);
        if (buyStart != null && buyStart.isAfter(startDate)) {
            startDate = buyStart;
        }

        List<SimulationDailyValuePoint> values = repository.loadCurrentPortfolioHistoricalValues(userId, startDate, endDate);
        if (values.isEmpty()) {
            return 0;
        }

        BigDecimal baseValue = values.get(0).simulatedValue().setScale(6, RoundingMode.HALF_UP);
        BigDecimal peakValue = baseValue;
        BigDecimal prevValue = null;
        List<SimulationSnapshotUpsertCommand> commands = new ArrayList<>();

        for (SimulationDailyValuePoint point : values) {
            BigDecimal currentValue = point.simulatedValue().setScale(6, RoundingMode.HALF_UP);
            if (currentValue.compareTo(peakValue) > 0) {
                peakValue = currentValue;
            }

            BigDecimal cumulativeReturnPct = ratioPercent(baseValue, currentValue).setScale(6, RoundingMode.HALF_UP);
            BigDecimal dailyReturnPct = prevValue == null
                    ? BigDecimal.ZERO.setScale(6, RoundingMode.HALF_UP)
                    : ratioPercent(prevValue, currentValue).setScale(6, RoundingMode.HALF_UP);
            BigDecimal drawdownPct = peakValue.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO.setScale(6, RoundingMode.HALF_UP)
                    : peakValue.subtract(currentValue)
                            .divide(peakValue, 8, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                            .setScale(6, RoundingMode.HALF_UP);

            commands.add(new SimulationSnapshotUpsertCommand(
                    point.snapshotDate(),
                    currentValue,
                    baseValue,
                    cumulativeReturnPct,
                    dailyReturnPct,
                    drawdownPct));
            prevValue = currentValue;
        }

        repository.batchUpsertSimulationSnapshots(userId, commands);
        return commands.size();
    }

    @Caching(evict = {
            @CacheEvict(cacheNames = CacheNames.DASHBOARD, key = "#userId"),
            @CacheEvict(cacheNames = CacheNames.POSITIONS, key = "#userId"),
            @CacheEvict(cacheNames = CacheNames.WATCHLIST, key = "#userId"),
            @CacheEvict(cacheNames = CacheNames.PORTFOLIO_ADVICE, key = "#userId"),
            @CacheEvict(cacheNames = CacheNames.ALERTS, allEntries = true),
            @CacheEvict(cacheNames = CacheNames.PORTFOLIO_SIMULATION, allEntries = true)
    })
    @Transactional
    public CreateTransactionResponse createTransaction(long userId, CreateTransactionRequest request) {
        if (!repository.isAccountOwnedByUser(userId, request.accountId())) {
            throw new IllegalArgumentException(simulationMessage("transaction.error.account_verify", "사용자 계좌 검증에 실패했어요."));
        }
        return repository.createTransaction(request);
    }

    private PortfolioAdviceResponse emptyAdvice(long userId) {
        String emptyRisk = advisorMessage("advice.empty.metrics_risk_level", "데이터가 아직 부족해요");
        String emptyHeadline = advisorMessage("advice.empty.headline", "포트폴리오 데이터가 더 필요해요");
        String emptySummary = advisorMessage("advice.empty.summary", "보유 자산 데이터가 아직 충분하지 않아서 정교한 진단이 어려워요.");
        String emptyKeyPoint = advisorMessage("advice.empty.key_point_1", "거래를 등록하면 샤프지수, 리스크, ETF 제안을 바로 보여드릴게요.");
        String emptyCaution = advisorMessage("advice.empty.caution_1", "데이터가 적은 구간의 추정값은 오차가 커질 수 있어요.");

        AdviceMetricsSnapshot metrics = new AdviceMetricsSnapshot(
                userId,
                LocalDate.now().toString(),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                emptyRisk);

        AiInsightSnapshot insight = new AiInsightSnapshot(
                emptyHeadline,
                emptySummary,
                List.of(emptyKeyPoint),
                List.of(emptyCaution),
                LocalDateTime.now().toString(),
                "advisor-rule-v1");
        return new PortfolioAdviceResponse(metrics, List.of(), List.of(), insight);
    }

    private PortfolioSimulationResponse emptySimulation(long userId, LocalDate startDate, LocalDate endDate) {
        List<String> notes = List.of(
                simulationMessage("simulation.empty.note.1", "선택한 기간에는 시뮬레이션에 필요한 가격 데이터가 부족해요."),
                simulationMessage("simulation.empty.note.2", "시작일을 최근으로 조정하거나 시세 배치 상태를 확인해 주세요."));
        return new PortfolioSimulationResponse(
                userId,
                startDate.toString(),
                endDate.toString(),
                0,
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP),
                List.of(),
                List.of(),
                notes);
    }

    private AnalyticsMetrics computeAnalyticsMetrics(
            List<PositionSnapshot> positions,
            List<DailyPortfolioValuePoint> dailyValues,
            double totalValue,
            double concentrationPct,
            double diversificationScore) {
        int tradingDays = advisorRuleInt("analytics.trading_days_per_year", 252);
        double riskFreeRatePct = advisorRuleDouble("analytics.risk_free_rate_pct", 3.0);
        double minAnnualVolatilityPct = advisorRuleDouble("analytics.min_annual_volatility_pct", 9.0);

        List<Double> dailyReturns = new ArrayList<>();
        for (int i = 1; i < dailyValues.size(); i++) {
            double prev = dailyValues.get(i - 1).portfolioValue().doubleValue();
            double current = dailyValues.get(i).portfolioValue().doubleValue();
            if (prev > 0) {
                dailyReturns.add((current - prev) / prev);
            }
        }

        double expectedDailyReturn = dailyReturns.isEmpty()
                ? estimateFallbackDailyReturn(positions, totalValue)
                : dailyReturns.stream().mapToDouble(v -> v).average().orElse(0.0);
        double expectedAnnualReturnPct = expectedDailyReturn * tradingDays * 100.0;

        double annualVolatilityPct;
        if (dailyReturns.size() >= 2) {
            annualVolatilityPct = standardDeviation(dailyReturns) * Math.sqrt(tradingDays) * 100.0;
        } else {
            annualVolatilityPct = Math.max(minAnnualVolatilityPct, standardDeviationFromPnL(positions));
        }

        double maxDrawdownPct = computeMaxDrawdownPct(dailyValues, concentrationPct);
        double sharpeRatio = annualVolatilityPct <= 0.001
                ? 0.0
                : (expectedAnnualReturnPct - riskFreeRatePct) / annualVolatilityPct;
        String riskLevel = resolveRiskLevel(annualVolatilityPct, maxDrawdownPct, concentrationPct);

        return new AnalyticsMetrics(
                round(totalValue, 2),
                round(expectedAnnualReturnPct, 2),
                round(annualVolatilityPct, 2),
                round(sharpeRatio, 2),
                round(maxDrawdownPct, 2),
                round(concentrationPct, 2),
                round(diversificationScore, 2),
                riskLevel);
    }

    private List<RebalancingActionSnapshot> buildRebalancingActions(
            List<PositionSnapshot> positions,
            double totalValue,
            InvestmentProfileResponse investmentProfile,
            int maxActionCount) {
        if (totalValue <= 0 || positions.isEmpty()) {
            return List.of();
        }

        int riskTier = investmentProfile == null ? 3 : investmentProfile.riskTier();
        double minWeight = riskTier <= 2
                ? advisorRuleDouble("rebal.min_weight_low_tier", 8.0)
                : 10.0;
        double maxWeight = riskTier >= 5
                ? advisorRuleDouble("rebal.max_weight_high_tier", 35.0)
                : riskTier >= 4
                        ? advisorRuleDouble("rebal.max_weight_mid_tier", 30.0)
                        : advisorRuleDouble("rebal.max_weight_low_tier", 24.0);
        double targetWeight = Math.max(minWeight, Math.min(maxWeight, 100.0 / positions.size()));
        double gapThreshold = riskTier <= 2
                ? advisorRuleDouble("rebal.gap_threshold_low_tier", 2.0)
                : riskTier >= 5
                        ? advisorRuleDouble("rebal.gap_threshold_high_tier", 3.0)
                        : advisorRuleDouble("rebal.gap_threshold_mid_tier", 2.5);
        String buyReasonTemplate = advisorMessage("rebal.reason.buy.template", "현재 비중 %.1f%%가 목표 %.1f%%보다 낮아서 분할 매수가 좋아요");
        String sellReasonTemplate = advisorMessage("rebal.reason.sell.template", "현재 비중 %.1f%%가 목표 %.1f%%를 넘어서 일부 축소가 좋아요");
        String profileSuffixTemplate = advisorMessage("rebal.reason.profile_suffix.template", " (%s 성향 반영)");

        List<RebalancingActionSnapshot> candidates = new ArrayList<>();
        for (PositionSnapshot position : positions) {
            double currentWeight = (position.valuation().doubleValue() / totalValue) * 100.0;
            double gap = targetWeight - currentWeight;
            if (Math.abs(gap) < gapThreshold) {
                continue;
            }

            boolean buy = gap > 0;
            double suggestedAmount = totalValue * Math.abs(gap) / 100.0;
            int priority = (int) Math.min(99, Math.round(Math.abs(gap) * 3 + (buy ? 5 : 15)));
            String reason = buy
                    ? String.format(Locale.KOREA, buyReasonTemplate, currentWeight, targetWeight)
                    : String.format(Locale.KOREA, sellReasonTemplate, currentWeight, targetWeight);

            if (investmentProfile != null) {
                reason += String.format(Locale.KOREA, profileSuffixTemplate, investmentProfile.shortLabel());
            }

            candidates.add(new RebalancingActionSnapshot(
                    position.assetId(),
                    position.symbol(),
                    position.assetName(),
                    buy ? "BUY" : "SELL",
                    round(currentWeight, 2),
                    round(targetWeight, 2),
                    round(gap, 2),
                    round(suggestedAmount, 0),
                    priority,
                    reason));
        }

        return candidates.stream()
                .sorted(Comparator
                        .comparingInt(RebalancingActionSnapshot::priority).reversed()
                        .thenComparing(action -> action.gapPct().abs(), Comparator.reverseOrder()))
                .limit(Math.max(1, maxActionCount))
                .toList();
    }

    private List<EtfRecommendationSnapshot> buildEtfRecommendations(
            List<EtfCatalogRow> etfCatalog,
            String riskLevel,
            double concentrationPct,
            InvestmentProfileResponse investmentProfile,
            int maxEtfCount) {
        if (etfCatalog.isEmpty()) {
            return List.of();
        }

        int riskTier = investmentProfile == null ? 3 : investmentProfile.riskTier();
        String preferredRiskBucket = preferredRiskBucket(riskTier);
        String etfReasonTemplate = advisorMessage("etf.reason.template", "%s 목적이고, 총보수는 %.4f%%예요");
        List<EtfRecommendationSnapshot> list = new ArrayList<>();
        for (EtfCatalogRow etf : etfCatalog) {
            int score = 50;
            if (concentrationPct >= 40 && etf.diversificationRole().contains("분산")) {
                score += 16;
            }
            if (etf.focusTheme().contains("미국")) {
                score += 6;
            }

            if (riskLevel.contains("높음")) {
                score += switch (etf.riskBucket()) {
                    case "LOW" -> 18;
                    case "MID" -> 9;
                    default -> -5;
                };
            } else if (riskLevel.contains("보통")) {
                score += switch (etf.riskBucket()) {
                    case "LOW" -> 10;
                    case "MID" -> 12;
                    default -> 4;
                };
            } else {
                score += switch (etf.riskBucket()) {
                    case "LOW" -> 2;
                    case "MID" -> 9;
                    default -> 14;
                };
            }
            if (preferredRiskBucket.equals(etf.riskBucket())) {
                score += 8;
            } else if ("MID".equals(preferredRiskBucket) && "HIGH".equals(etf.riskBucket())) {
                score += 2;
            } else {
                score -= 4;
            }

            score = Math.max(45, Math.min(99, score));
            double suggestedWeight = suggestedEtfWeight(
                    riskLevel,
                    etf.riskBucket(),
                    concentrationPct,
                    investmentProfile);
            String reason = String.format(
                    Locale.KOREA,
                    etfReasonTemplate,
                    etf.diversificationRole(),
                    etf.expenseRatioPct().doubleValue());

            list.add(new EtfRecommendationSnapshot(
                    etf.etfId(),
                    etf.symbol(),
                    etf.name(),
                    etf.market(),
                    etf.focusTheme(),
                    etf.riskBucket(),
                    etf.expenseRatioPct().setScale(4, RoundingMode.HALF_UP),
                    round(suggestedWeight, 1),
                    score,
                    reason));
        }

        return list.stream()
                .sorted(Comparator
                        .comparingInt(EtfRecommendationSnapshot::matchScore).reversed()
                        .thenComparing(EtfRecommendationSnapshot::expenseRatioPct))
                .limit(Math.max(1, maxEtfCount))
                .toList();
    }

    private AiInsightSnapshot buildAiInsight(
            AnalyticsMetrics metrics,
            List<RebalancingActionSnapshot> actions,
            List<EtfRecommendationSnapshot> etfRecommendations,
            InvestmentProfileResponse investmentProfile) {
        boolean stable = isStablePortfolio(metrics, actions);
        String headline = stable
                ? advisorMessage("insight.headline.stable", "지금 포트폴리오는 비교적 안정 구간이에요")
                : advisorMessage("insight.headline.adjust", "리밸런싱/분산 조정이 필요한 구간이에요");

        String stableSummaryTemplate = advisorMessage(
                "insight.summary.stable.template",
                "샤프 %.2f, 연환산 변동성 %.2f%%, 최대낙폭 %.2f%%, 최대 비중 %.2f%% 기준으로는 급격한 구조 변경보다 운영 전략 점검이 더 좋아요");
        String adjustSummaryTemplate = advisorMessage(
                "insight.summary.adjust.template",
                "샤프 %.2f, 연환산 변동성 %.2f%%, 최대낙폭 %.2f%%, 최대 비중 %.2f%% 기준으로 비중 조정 우선순위가 있어요");

        String summary = stable
                ? String.format(
                        Locale.KOREA,
                        stableSummaryTemplate,
                        metrics.sharpeRatio().doubleValue(),
                        metrics.annualVolatilityPct().doubleValue(),
                        metrics.maxDrawdownPct().doubleValue(),
                        metrics.concentrationPct().doubleValue())
                : String.format(
                        Locale.KOREA,
                        adjustSummaryTemplate,
                        metrics.sharpeRatio().doubleValue(),
                        metrics.annualVolatilityPct().doubleValue(),
                        metrics.maxDrawdownPct().doubleValue(),
                        metrics.concentrationPct().doubleValue());

        List<String> keyPoints = new ArrayList<>();
        if (stable) {
            keyPoints.add(advisorMessage("insight.keypoint.stable.default_1",
                    "지금은 구조를 크게 바꾸기보다 과도한 매매를 줄이고 운영 전략을 유지하는 편이 좋아요."));
            keyPoints.addAll(buildStableStrategy(metrics, etfRecommendations));
        } else {
            if (investmentProfile != null) {
                String profileMessageTemplate = advisorMessage("insight.keypoint.adjust.profile.template",
                        "현재 성향 %s(%d단계)을 기준으로 추천 우선순위를 개인화했어요.");
                keyPoints.add(String.format(
                        Locale.KOREA,
                        profileMessageTemplate,
                        investmentProfile.shortLabel(),
                        investmentProfile.riskTier()));
            }
            if (!actions.isEmpty()) {
                RebalancingActionSnapshot topAction = actions.get(0);
                String topActionTemplate = advisorMessage("insight.keypoint.adjust.top_action.template",
                        "우선 조정은 %s %s이고 권장 금액은 약 %,d원이에요.");
                keyPoints.add(String.format(
                        Locale.KOREA,
                        topActionTemplate,
                        topAction.assetName(),
                        "BUY".equals(topAction.action()) ? "비중 확대" : "비중 축소",
                        topAction.suggestedAmount().longValue()));
            } else {
                keyPoints.add(advisorMessage("insight.keypoint.adjust.no_action",
                        "즉시 체결이 필요한 조정은 없지만 정기 리밸런싱 점검은 계속 필요해요."));
            }

            if (!etfRecommendations.isEmpty()) {
                EtfRecommendationSnapshot topEtf = etfRecommendations.get(0);
                String topEtfTemplate = advisorMessage("insight.keypoint.adjust.top_etf.template",
                        "ETF 대안은 %s %s이고, 적합도 %d점 기준 권장 비중은 %.1f%%예요.");
                keyPoints.add(String.format(
                        Locale.KOREA,
                        topEtfTemplate,
                        topEtf.symbol(),
                        topEtf.name(),
                        topEtf.matchScore(),
                        topEtf.suggestedWeightPct().doubleValue()));
            }

            if (metrics.diversificationScore().doubleValue() < advisorRuleDouble("insight.low_diversification_threshold", 55.0)) {
                keyPoints.add(advisorMessage("insight.keypoint.adjust.low_diversification",
                        "분산 점수가 낮아서 섹터/시장 분산 비중을 더 늘리는 쪽이 좋아요."));
            } else {
                keyPoints.add(advisorMessage("insight.keypoint.adjust.high_diversification",
                        "분산은 비교적 유지되고 있으니 비중 조정은 분할 체결로 천천히 가는 편이 좋아요."));
            }
        }

        List<String> cautions = new ArrayList<>();
        cautions.add(advisorMessage("insight.caution.base",
                "이 진단은 규칙 기반 보조지표이고, 최종 투자 판단은 사용자에게 있어요."));
        if (stable) {
            cautions.add(advisorMessage("insight.caution.stable",
                    "운영 임계치는 변동성 20%, 최대낙폭 12%, 최대 비중 40% 수준으로 두는 걸 권장해요."));
        } else if (metrics.maxDrawdownPct().doubleValue() >= 12) {
            cautions.add(advisorMessage("insight.caution.high_drawdown",
                    "최대낙폭이 큰 구간이라면 현금 비중이나 방어자산 비중을 먼저 점검해 주세요."));
        } else {
            cautions.add(advisorMessage("insight.caution.default",
                    "변동성 확대 가능성을 고려해서 일괄 체결보다는 분할 리밸런싱이 더 안전해요."));
        }

        return new AiInsightSnapshot(
                headline,
                summary,
                keyPoints.stream().limit(4).toList(),
                cautions,
                LocalDateTime.now().toString(),
                "advisor-rule-v2");
    }

    private boolean isStablePortfolio(AnalyticsMetrics metrics, List<RebalancingActionSnapshot> actions) {
        double annualVolatilityMax = advisorRuleDouble("stability.annual_volatility_max_pct", 18.0);
        double maxDrawdownMax = advisorRuleDouble("stability.max_drawdown_max_pct", 10.0);
        double concentrationMax = advisorRuleDouble("stability.max_concentration_max_pct", 35.0);
        double diversificationMin = advisorRuleDouble("stability.min_diversification_score", 60.0);
        double maxGapPct = advisorRuleDouble("stability.max_gap_pct", 4.0);

        boolean riskBandStable = metrics.annualVolatilityPct().doubleValue() < annualVolatilityMax
                && metrics.maxDrawdownPct().doubleValue() < maxDrawdownMax
                && metrics.concentrationPct().doubleValue() < concentrationMax;
        boolean diversificationStable = metrics.diversificationScore().doubleValue() >= diversificationMin;
        boolean rebalancePressureLow = actions.isEmpty()
                || actions.stream().allMatch(action -> action.gapPct().abs().doubleValue() < maxGapPct);
        return riskBandStable && diversificationStable && rebalancePressureLow;
    }

    private List<String> buildStableStrategy(
            AnalyticsMetrics metrics,
            List<EtfRecommendationSnapshot> etfRecommendations) {
        List<String> strategies = new ArrayList<>();
        strategies.add(advisorMessage("stable.strategy.monthly_check",
                "운영전략 1) 월 1회 점검하고 허용오차(±3%)를 벗어날 때만 리밸런싱해요."));
        String diversificationTemplate = advisorMessage(
                "stable.strategy.diversification.template",
                "운영전략 2) 분산 점수 %.1f점을 유지 목표로 두고, 신규 자금으로 비중을 보정해요.");
        strategies.add(String.format(
                Locale.KOREA,
                diversificationTemplate,
                metrics.diversificationScore().doubleValue()));
        if (!etfRecommendations.isEmpty()) {
            EtfRecommendationSnapshot topEtf = etfRecommendations.get(0);
            String etfTemplate = advisorMessage(
                    "stable.strategy.etf.template",
                    "운영전략 3) %s(%s)는 즉시 교체보다 신규 매수분에서 점진 반영하는 편이 좋아요.");
            strategies.add(String.format(
                    Locale.KOREA,
                    etfTemplate,
                    topEtf.name(),
                    topEtf.symbol()));
        }
        return strategies;
    }

    private BigDecimal annualizedReturn(BigDecimal startValue, BigDecimal endValue, long days) {
        if (startValue.compareTo(BigDecimal.ZERO) <= 0 || endValue.compareTo(BigDecimal.ZERO) <= 0 || days <= 0) {
            return BigDecimal.ZERO;
        }
        double factor = endValue.divide(startValue, 10, RoundingMode.HALF_UP).doubleValue();
        double annualized = (Math.pow(factor, 365.0 / days) - 1.0) * 100.0;
        return round(annualized, 6);
    }

    private BigDecimal ratioPercent(BigDecimal base, BigDecimal current) {
        if (base.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        return current.subtract(base)
                .divide(base, 8, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100));
    }

    private LocalDate parseDate(String text, LocalDate defaultDate) {
        if (text == null || text.isBlank()) {
            return defaultDate;
        }
        return LocalDate.parse(text.trim());
    }

    private double suggestedEtfWeight(
            String riskLevel,
            String etfRiskBucket,
            double concentrationPct,
            InvestmentProfileResponse investmentProfile) {
        double base;
        if (riskLevel.contains("높음")) {
            base = switch (etfRiskBucket) {
                case "LOW" -> 14.0;
                case "MID" -> 9.0;
                default -> 5.0;
            };
        } else if (riskLevel.contains("보통")) {
            base = switch (etfRiskBucket) {
                case "LOW" -> 10.0;
                case "MID" -> 11.0;
                default -> 7.0;
            };
        } else {
            base = switch (etfRiskBucket) {
                case "LOW" -> 7.0;
                case "MID" -> 9.0;
                default -> 11.0;
            };
        }
        if (concentrationPct >= 45 && "LOW".equals(etfRiskBucket)) {
            base += 2.0;
        }
        if (investmentProfile != null) {
            if (investmentProfile.riskTier() <= 2 && "LOW".equals(etfRiskBucket)) {
                base += 1.5;
            } else if (investmentProfile.riskTier() >= 5 && "HIGH".equals(etfRiskBucket)) {
                base += 1.5;
            }
        }
        return Math.max(4.0, Math.min(18.0, base));
    }

    private String preferredRiskBucket(int riskTier) {
        if (riskTier <= 2) {
            return "LOW";
        }
        if (riskTier <= 4) {
            return "MID";
        }
        return "HIGH";
    }

    private String resolveRiskLevel(double annualVolatilityPct, double maxDrawdownPct, double concentrationPct) {
        double highVolatility = advisorRuleDouble("risk.high.annual_volatility_min_pct", 35.0);
        double highDrawdown = advisorRuleDouble("risk.high.max_drawdown_min_pct", 18.0);
        double highConcentration = advisorRuleDouble("risk.high.concentration_min_pct", 45.0);
        if (annualVolatilityPct >= highVolatility || maxDrawdownPct >= highDrawdown || concentrationPct >= highConcentration) {
            return "리스크 높음";
        }
        double mediumVolatility = advisorRuleDouble("risk.medium.annual_volatility_min_pct", 20.0);
        double mediumDrawdown = advisorRuleDouble("risk.medium.max_drawdown_min_pct", 10.0);
        double mediumConcentration = advisorRuleDouble("risk.medium.concentration_min_pct", 30.0);
        if (annualVolatilityPct >= mediumVolatility || maxDrawdownPct >= mediumDrawdown
                || concentrationPct >= mediumConcentration) {
            return "리스크 보통";
        }
        return "리스크 낮음";
    }

    private InvestmentProfileResponse toInvestmentProfileResponse(InvestmentProfileRow row) {
        return new InvestmentProfileResponse(
                row.profileKey(),
                row.profileName(),
                row.shortLabel(),
                row.profileSummary(),
                row.riskScore(),
                row.riskTier(),
                row.targetAllocationHint(),
                row.updatedAt(),
                readAnswersJson(row.answersJson()));
    }

    private Map<String, Integer> readAnswersJson(String answersJson) {
        if (answersJson == null || answersJson.isBlank()) {
            return Map.of();
        }
        try {
            return objectMapper.readValue(answersJson, new TypeReference<Map<String, Integer>>() {
            });
        } catch (JsonProcessingException e) {
            return Map.of();
        }
    }

    private String writeAnswersJson(Map<String, Integer> answers) {
        Map<String, Integer> normalized = answers == null ? Map.of() : answers;
        try {
            return objectMapper.writeValueAsString(normalized);
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }

    private double computeConcentrationPct(List<PositionSnapshot> positions, BigDecimal totalValue) {
        double total = totalValue.doubleValue();
        if (total <= 0) {
            return 0.0;
        }

        double maxWeight = 0.0;
        for (PositionSnapshot position : positions) {
            double weight = position.valuation().doubleValue() / total;
            if (weight > maxWeight) {
                maxWeight = weight;
            }
        }
        return maxWeight * 100.0;
    }

    private double computeDiversificationScore(List<PositionSnapshot> positions, BigDecimal totalValue) {
        if (positions.size() <= 1) {
            return 0.0;
        }

        double total = totalValue.doubleValue();
        if (total <= 0) {
            return 0.0;
        }

        double hhi = 0.0;
        for (PositionSnapshot position : positions) {
            double weight = position.valuation().doubleValue() / total;
            hhi += weight * weight;
        }

        double minHhi = 1.0 / positions.size();
        double normalized = (hhi - minHhi) / (1 - minHhi);
        double score = (1.0 - normalized) * 100.0;
        return Math.max(0.0, Math.min(100.0, score));
    }

    private double estimateFallbackDailyReturn(List<PositionSnapshot> positions, double totalValue) {
        if (positions.isEmpty() || totalValue <= 0) {
            return 0.0;
        }

        double weighted = 0.0;
        for (PositionSnapshot position : positions) {
            double weight = position.valuation().doubleValue() / totalValue;
            weighted += weight * (position.pnlRate().doubleValue() / 100.0);
        }
        return weighted / 20.0;
    }

    private double computeMaxDrawdownPct(List<DailyPortfolioValuePoint> dailyValues, double concentrationPct) {
        if (dailyValues.size() < 2) {
            double fallbackFloor = advisorRuleDouble("analytics.min_drawdown_fallback_pct", 4.0);
            double concentrationFactor = advisorRuleDouble("analytics.drawdown_concentration_factor", 0.25);
            return Math.max(fallbackFloor, concentrationPct * concentrationFactor);
        }

        double peak = Double.MIN_VALUE;
        double maxDrawdown = 0.0;
        for (DailyPortfolioValuePoint valuePoint : dailyValues) {
            double value = valuePoint.portfolioValue().doubleValue();
            if (value <= 0) {
                continue;
            }
            peak = Math.max(peak, value);
            if (peak > 0) {
                double drawdown = (peak - value) / peak;
                if (drawdown > maxDrawdown) {
                    maxDrawdown = drawdown;
                }
            }
        }
        return maxDrawdown * 100.0;
    }

    private double standardDeviationFromPnL(List<PositionSnapshot> positions) {
        if (positions.size() < 2) {
            return 12.0;
        }
        List<Double> pnlRates = positions.stream()
                .map(p -> p.pnlRate().doubleValue())
                .toList();
        return Math.max(advisorRuleDouble("analytics.min_stddev_from_pnl_pct", 8.0), standardDeviation(pnlRates));
    }

    private double standardDeviation(List<Double> values) {
        if (values.size() < 2) {
            return 0.0;
        }
        double mean = values.stream().mapToDouble(v -> v).average().orElse(0.0);
        double variance = values.stream()
                .mapToDouble(v -> Math.pow(v - mean, 2))
                .sum() / (values.size() - 1);
        return Math.sqrt(Math.max(variance, 0.0));
    }

    private BigDecimal round(double value, int scale) {
        if (!Double.isFinite(value)) {
            return BigDecimal.ZERO.setScale(scale, RoundingMode.HALF_UP);
        }
        return BigDecimal.valueOf(value).setScale(scale, RoundingMode.HALF_UP);
    }

    private int advisorRuleInt(String key, int defaultValue) {
        return runtimeConfigService.getInt(RuntimeConfigService.GROUP_ADVISOR_RULE, key, defaultValue);
    }

    private double advisorRuleDouble(String key, double defaultValue) {
        return runtimeConfigService.getDouble(RuntimeConfigService.GROUP_ADVISOR_RULE, key, defaultValue);
    }

    private String advisorMessage(String key, String defaultValue) {
        return runtimeConfigService.getString(RuntimeConfigService.GROUP_ADVISOR_MESSAGE, key, defaultValue);
    }

    private String simulationMessage(String key, String defaultValue) {
        return runtimeConfigService.getString(RuntimeConfigService.GROUP_SIMULATION_MESSAGE, key, defaultValue);
    }

    private record AnalyticsMetrics(
            BigDecimal totalValue,
            BigDecimal expectedAnnualReturnPct,
            BigDecimal annualVolatilityPct,
            BigDecimal sharpeRatio,
            BigDecimal maxDrawdownPct,
            BigDecimal concentrationPct,
            BigDecimal diversificationScore,
            String riskLevel) {
    }
}


