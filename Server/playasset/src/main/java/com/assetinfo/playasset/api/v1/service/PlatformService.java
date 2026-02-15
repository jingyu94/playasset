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

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.assetinfo.playasset.api.v1.dto.AdviceMetricsSnapshot;
import com.assetinfo.playasset.api.v1.dto.AlertResponse;
import com.assetinfo.playasset.api.v1.dto.AiInsightSnapshot;
import com.assetinfo.playasset.api.v1.dto.CreateTransactionRequest;
import com.assetinfo.playasset.api.v1.dto.CreateTransactionResponse;
import com.assetinfo.playasset.api.v1.dto.DashboardResponse;
import com.assetinfo.playasset.api.v1.dto.EtfRecommendationSnapshot;
import com.assetinfo.playasset.api.v1.dto.PortfolioAdviceResponse;
import com.assetinfo.playasset.api.v1.dto.PortfolioSimulationResponse;
import com.assetinfo.playasset.api.v1.dto.PositionSnapshot;
import com.assetinfo.playasset.api.v1.dto.RebalancingActionSnapshot;
import com.assetinfo.playasset.api.v1.dto.SimulationContributionSnapshot;
import com.assetinfo.playasset.api.v1.dto.SimulationPointSnapshot;
import com.assetinfo.playasset.api.v1.dto.WatchlistItemResponse;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.DailyPortfolioValuePoint;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.EtfCatalogRow;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.SimulationDailyValuePoint;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.SimulationPositionContributionRow;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.SimulationSnapshotRow;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository.SimulationSnapshotUpsertCommand;
import com.assetinfo.playasset.config.CacheNames;

@Service
public class PlatformService {

    private final PlatformQueryRepository repository;

    public PlatformService(PlatformQueryRepository repository) {
        this.repository = repository;
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

    @Cacheable(cacheNames = CacheNames.PORTFOLIO_ADVICE, key = "#userId")
    public PortfolioAdviceResponse getPortfolioAdvice(long userId) {
        List<PositionSnapshot> positions = repository.loadPositions(userId);
        if (positions.isEmpty()) {
            return emptyAdvice(userId);
        }

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

        List<RebalancingActionSnapshot> actions = buildRebalancingActions(positions, totalValue.doubleValue());
        List<EtfRecommendationSnapshot> etfRecommendations = buildEtfRecommendations(
                repository.loadAdvisorEtfCatalog(),
                metrics.riskLevel(),
                concentrationPct);

        AiInsightSnapshot insight = buildAiInsight(metrics, actions, etfRecommendations);
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

        return new PortfolioAdviceResponse(metricsSnapshot, actions, etfRecommendations, insight);
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
            throw new IllegalArgumentException("시뮬레이터 시작일은 기준일보다 이후일 수 없습니다.");
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
                "현재 보유 수량을 과거 종가에 대입한 데이터 기반 시뮬레이션입니다.",
                "시작일은 매수일 기준(또는 사용자가 선택한 날짜), 기준일은 선택 날짜 종가 기준입니다.",
                dayGap < 90 ? "기간이 90일 미만이면 연환산 수익률은 기간 수익률과 동일하게 표기합니다." : "연환산 수익률은 장기 구간에서 해석하는 것이 유효합니다.",
                "거래 수수료·세금·중간 리밸런싱은 반영하지 않은 비교용 백테스트입니다.");

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
            throw new IllegalArgumentException("사용자 계좌 검증에 실패했습니다.");
        }
        return repository.createTransaction(request);
    }

    private PortfolioAdviceResponse emptyAdvice(long userId) {
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
                "데이터 부족");

        AiInsightSnapshot insight = new AiInsightSnapshot(
                "포트폴리오 데이터가 부족합니다",
                "보유 자산 데이터가 없어 정량 진단을 수행할 수 없습니다.",
                List.of("거래를 등록하면 샤프/리스크/ETF 추천이 표시됩니다."),
                List.of("데이터가 없는 구간의 추정치는 신뢰도가 낮습니다."),
                LocalDateTime.now().toString(),
                "advisor-rule-v1");
        return new PortfolioAdviceResponse(metrics, List.of(), List.of(), insight);
    }

    private PortfolioSimulationResponse emptySimulation(long userId, LocalDate startDate, LocalDate endDate) {
        List<String> notes = List.of(
                "선택한 기간에 시뮬레이션 가능한 가격 데이터가 없습니다.",
                "시작일을 최근으로 조정하거나 시세 배치가 누락되지 않았는지 확인하세요.");
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
        double expectedAnnualReturnPct = expectedDailyReturn * 252.0 * 100.0;

        double annualVolatilityPct;
        if (dailyReturns.size() >= 2) {
            annualVolatilityPct = standardDeviation(dailyReturns) * Math.sqrt(252.0) * 100.0;
        } else {
            annualVolatilityPct = Math.max(9.0, standardDeviationFromPnL(positions));
        }

        double maxDrawdownPct = computeMaxDrawdownPct(dailyValues, concentrationPct);
        double sharpeRatio = annualVolatilityPct <= 0.001
                ? 0.0
                : (expectedAnnualReturnPct - 3.0) / annualVolatilityPct;
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

    private List<RebalancingActionSnapshot> buildRebalancingActions(List<PositionSnapshot> positions, double totalValue) {
        if (totalValue <= 0 || positions.isEmpty()) {
            return List.of();
        }

        double targetWeight = Math.max(10.0, Math.min(30.0, 100.0 / positions.size()));
        List<RebalancingActionSnapshot> candidates = new ArrayList<>();
        for (PositionSnapshot position : positions) {
            double currentWeight = (position.valuation().doubleValue() / totalValue) * 100.0;
            double gap = targetWeight - currentWeight;
            if (Math.abs(gap) < 2.5) {
                continue;
            }

            boolean buy = gap > 0;
            double suggestedAmount = totalValue * Math.abs(gap) / 100.0;
            int priority = (int) Math.min(99, Math.round(Math.abs(gap) * 3 + (buy ? 5 : 15)));
            String reason = buy
                    ? String.format(Locale.KOREA, "현재 비중 %.1f%%가 목표 %.1f%%보다 낮아 단계적 매수 권장", currentWeight, targetWeight)
                    : String.format(Locale.KOREA, "현재 비중 %.1f%%가 목표 %.1f%%를 초과해 일부 매도 권장", currentWeight, targetWeight);

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
                .limit(6)
                .toList();
    }

    private List<EtfRecommendationSnapshot> buildEtfRecommendations(
            List<EtfCatalogRow> etfCatalog,
            String riskLevel,
            double concentrationPct) {
        if (etfCatalog.isEmpty()) {
            return List.of();
        }

        List<EtfRecommendationSnapshot> list = new ArrayList<>();
        for (EtfCatalogRow etf : etfCatalog) {
            int score = 50;
            if (concentrationPct >= 40 && etf.diversificationRole().contains("완화")) {
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

            score = Math.max(45, Math.min(99, score));
            double suggestedWeight = suggestedEtfWeight(riskLevel, etf.riskBucket(), concentrationPct);
            String reason = String.format(
                    Locale.KOREA,
                    "%s 목적, 총보수 %.4f%%",
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
                .limit(3)
                .toList();
    }

    private AiInsightSnapshot buildAiInsight(
            AnalyticsMetrics metrics,
            List<RebalancingActionSnapshot> actions,
            List<EtfRecommendationSnapshot> etfRecommendations) {
        String headline = metrics.riskLevel().contains("높음")
                ? "집중 리스크 완화가 최우선입니다"
                : metrics.riskLevel().contains("보통")
                        ? "완만한 리밸런싱으로 안정 구간 진입이 가능합니다"
                        : "성장 노출을 늘릴 수 있는 안정 구간입니다";

        String summary = String.format(
                Locale.KOREA,
                "샤프 %.2f, 변동성 %.2f%%, 최대낙폭 %.2f%%, 최대보유비중 %.2f%% 기준으로 분석했습니다.",
                metrics.sharpeRatio().doubleValue(),
                metrics.annualVolatilityPct().doubleValue(),
                metrics.maxDrawdownPct().doubleValue(),
                metrics.concentrationPct().doubleValue());

        List<String> keyPoints = new ArrayList<>();
        if (!actions.isEmpty()) {
            RebalancingActionSnapshot topAction = actions.get(0);
            keyPoints.add(String.format(
                    Locale.KOREA,
                    "우선 조치: %s %s (권장 금액 약 %,d원)",
                    topAction.assetName(),
                    "BUY".equals(topAction.action()) ? "비중 확대" : "비중 축소",
                    topAction.suggestedAmount().longValue()));
        }
        if (!etfRecommendations.isEmpty()) {
            EtfRecommendationSnapshot topEtf = etfRecommendations.get(0);
            keyPoints.add(String.format(
                    Locale.KOREA,
                    "ETF 대안: %s %s (적합도 %d점, 권장 %.1f%%)",
                    topEtf.symbol(),
                    topEtf.name(),
                    topEtf.matchScore(),
                    topEtf.suggestedWeightPct().doubleValue()));
        }
        if (metrics.diversificationScore().doubleValue() < 55) {
            keyPoints.add("분산 점수가 낮아 업종/지역 분산 비중을 먼저 확대해야 합니다.");
        } else {
            keyPoints.add("분산 상태는 양호하므로 목표 수익률 기반의 미세조정이 유효합니다.");
        }

        List<String> cautions = new ArrayList<>();
        cautions.add("본 추천은 규칙 기반 보조지표이며, 투자판단과 손익 책임은 사용자에게 있습니다.");
        if (metrics.maxDrawdownPct().doubleValue() >= 12) {
            cautions.add("최근 최대 낙폭이 커 손절/현금비중 기준을 사전에 확정해 두는 것이 좋습니다.");
        } else {
            cautions.add("낙폭은 관리 가능한 수준이지만 단기 변동 구간 재진입 가능성을 고려해야 합니다.");
        }

        return new AiInsightSnapshot(
                headline,
                summary,
                keyPoints,
                cautions,
                LocalDateTime.now().toString(),
                "advisor-rule-v1");
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

    private double suggestedEtfWeight(String riskLevel, String etfRiskBucket, double concentrationPct) {
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
        return Math.max(4.0, Math.min(18.0, base));
    }

    private String resolveRiskLevel(double annualVolatilityPct, double maxDrawdownPct, double concentrationPct) {
        if (annualVolatilityPct >= 35 || maxDrawdownPct >= 18 || concentrationPct >= 45) {
            return "리스크 높음";
        }
        if (annualVolatilityPct >= 20 || maxDrawdownPct >= 10 || concentrationPct >= 30) {
            return "리스크 보통";
        }
        return "리스크 낮음";
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
            return Math.max(4.0, concentrationPct * 0.25);
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
        return Math.max(8.0, standardDeviation(pnlRates));
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
