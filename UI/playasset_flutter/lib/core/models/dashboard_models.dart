class DashboardData {
  DashboardData({
    required this.userId,
    required this.portfolioValue,
    required this.dailyPnl,
    required this.dailyPnlRate,
    required this.watchlistCount,
    required this.unreadAlertCount,
    required this.sentiment,
    required this.topPositions,
    required this.topMovers,
  });

  final int userId;
  final double portfolioValue;
  final double dailyPnl;
  final double dailyPnlRate;
  final int watchlistCount;
  final int unreadAlertCount;
  final SentimentData sentiment;
  final List<PositionData> topPositions;
  final List<MoverData> topMovers;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      userId: json['userId'] as int,
      portfolioValue: (json['portfolioValue'] as num).toDouble(),
      dailyPnl: (json['dailyPnl'] as num).toDouble(),
      dailyPnlRate: (json['dailyPnlRate'] as num).toDouble(),
      watchlistCount: json['watchlistCount'] as int,
      unreadAlertCount: json['unreadAlertCount'] as int,
      sentiment:
          SentimentData.fromJson(json['sentiment'] as Map<String, dynamic>),
      topPositions: (json['topPositions'] as List<dynamic>)
          .map((e) => PositionData.fromJson(e as Map<String, dynamic>))
          .toList(),
      topMovers: (json['topMovers'] as List<dynamic>)
          .map((e) => MoverData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PositionData {
  PositionData({
    required this.assetId,
    required this.symbol,
    required this.assetName,
    required this.quantity,
    required this.avgCost,
    required this.currentPrice,
    required this.valuation,
    required this.pnlRate,
  });

  final int assetId;
  final String symbol;
  final String assetName;
  final double quantity;
  final double avgCost;
  final double currentPrice;
  final double valuation;
  final double pnlRate;

  factory PositionData.fromJson(Map<String, dynamic> json) {
    return PositionData(
      assetId: json['assetId'] as int,
      symbol: json['symbol'] as String,
      assetName: json['assetName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      avgCost: (json['avgCost'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      valuation: (json['valuation'] as num).toDouble(),
      pnlRate: (json['pnlRate'] as num).toDouble(),
    );
  }
}

class MoverData {
  MoverData({
    required this.symbol,
    required this.assetName,
    required this.openPrice,
    required this.closePrice,
    required this.changeRate,
  });

  final String symbol;
  final String assetName;
  final double openPrice;
  final double closePrice;
  final double changeRate;

  factory MoverData.fromJson(Map<String, dynamic> json) {
    return MoverData(
      symbol: json['symbol'] as String,
      assetName: json['assetName'] as String,
      openPrice: (json['openPrice'] as num).toDouble(),
      closePrice: (json['closePrice'] as num).toDouble(),
      changeRate: (json['changeRate'] as num).toDouble(),
    );
  }
}

class SentimentData {
  SentimentData({
    required this.positive,
    required this.neutral,
    required this.negative,
  });

  final int positive;
  final int neutral;
  final int negative;

  int get total => positive + neutral + negative;

  factory SentimentData.fromJson(Map<String, dynamic> json) {
    return SentimentData(
      positive: json['positive'] as int,
      neutral: json['neutral'] as int,
      negative: json['negative'] as int,
    );
  }
}

class WatchlistItemData {
  WatchlistItemData({
    required this.assetId,
    required this.symbol,
    required this.assetName,
    required this.lastPrice,
    required this.changeRate,
    required this.note,
  });

  final int assetId;
  final String symbol;
  final String assetName;
  final double lastPrice;
  final double changeRate;
  final String note;

  factory WatchlistItemData.fromJson(Map<String, dynamic> json) {
    return WatchlistItemData(
      assetId: json['assetId'] as int,
      symbol: json['symbol'] as String,
      assetName: json['assetName'] as String,
      lastPrice: (json['lastPrice'] as num).toDouble(),
      changeRate: (json['changeRate'] as num).toDouble(),
      note: json['note'] as String? ?? '',
    );
  }
}

class AlertData {
  AlertData({
    required this.alertEventId,
    required this.eventType,
    required this.title,
    required this.message,
    required this.severity,
    required this.status,
    required this.occurredAt,
  });

  final int alertEventId;
  final String eventType;
  final String title;
  final String message;
  final String severity;
  final String status;
  final String occurredAt;

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      alertEventId: json['alertEventId'] as int,
      eventType: json['eventType'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      occurredAt: json['occurredAt'] as String,
    );
  }
}

class AlertPreferenceData {
  AlertPreferenceData({
    required this.userId,
    required this.lowEnabled,
    required this.mediumEnabled,
    required this.highEnabled,
  });

  final int userId;
  final bool lowEnabled;
  final bool mediumEnabled;
  final bool highEnabled;

  factory AlertPreferenceData.fromJson(Map<String, dynamic> json) {
    return AlertPreferenceData(
      userId: json['userId'] as int,
      lowEnabled: json['lowEnabled'] as bool,
      mediumEnabled: json['mediumEnabled'] as bool,
      highEnabled: json['highEnabled'] as bool,
    );
  }

  AlertPreferenceData copyWith({
    bool? lowEnabled,
    bool? mediumEnabled,
    bool? highEnabled,
  }) {
    return AlertPreferenceData(
      userId: userId,
      lowEnabled: lowEnabled ?? this.lowEnabled,
      mediumEnabled: mediumEnabled ?? this.mediumEnabled,
      highEnabled: highEnabled ?? this.highEnabled,
    );
  }
}

class PortfolioAdviceData {
  PortfolioAdviceData({
    required this.metrics,
    required this.rebalancingActions,
    required this.etfRecommendations,
    required this.insight,
  });

  final AdviceMetricsData metrics;
  final List<RebalancingActionData> rebalancingActions;
  final List<EtfRecommendationData> etfRecommendations;
  final AiInsightData insight;

  factory PortfolioAdviceData.fromJson(Map<String, dynamic> json) {
    return PortfolioAdviceData(
      metrics:
          AdviceMetricsData.fromJson(json['metrics'] as Map<String, dynamic>),
      rebalancingActions: (json['rebalancingActions'] as List<dynamic>)
          .map((e) => RebalancingActionData.fromJson(e as Map<String, dynamic>))
          .toList(),
      etfRecommendations: (json['etfRecommendations'] as List<dynamic>)
          .map((e) => EtfRecommendationData.fromJson(e as Map<String, dynamic>))
          .toList(),
      insight: AiInsightData.fromJson(json['insight'] as Map<String, dynamic>),
    );
  }
}

class AdviceMetricsData {
  AdviceMetricsData({
    required this.userId,
    required this.asOfDate,
    required this.totalValue,
    required this.expectedAnnualReturnPct,
    required this.annualVolatilityPct,
    required this.sharpeRatio,
    required this.maxDrawdownPct,
    required this.concentrationPct,
    required this.diversificationScore,
    required this.riskLevel,
  });

  final int userId;
  final String asOfDate;
  final double totalValue;
  final double expectedAnnualReturnPct;
  final double annualVolatilityPct;
  final double sharpeRatio;
  final double maxDrawdownPct;
  final double concentrationPct;
  final double diversificationScore;
  final String riskLevel;

  factory AdviceMetricsData.fromJson(Map<String, dynamic> json) {
    return AdviceMetricsData(
      userId: json['userId'] as int,
      asOfDate: json['asOfDate'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      expectedAnnualReturnPct:
          (json['expectedAnnualReturnPct'] as num).toDouble(),
      annualVolatilityPct: (json['annualVolatilityPct'] as num).toDouble(),
      sharpeRatio: (json['sharpeRatio'] as num).toDouble(),
      maxDrawdownPct: (json['maxDrawdownPct'] as num).toDouble(),
      concentrationPct: (json['concentrationPct'] as num).toDouble(),
      diversificationScore: (json['diversificationScore'] as num).toDouble(),
      riskLevel: json['riskLevel'] as String,
    );
  }
}

class RebalancingActionData {
  RebalancingActionData({
    required this.assetId,
    required this.symbol,
    required this.assetName,
    required this.action,
    required this.currentWeightPct,
    required this.targetWeightPct,
    required this.gapPct,
    required this.suggestedAmount,
    required this.priority,
    required this.reason,
  });

  final int assetId;
  final String symbol;
  final String assetName;
  final String action;
  final double currentWeightPct;
  final double targetWeightPct;
  final double gapPct;
  final double suggestedAmount;
  final int priority;
  final String reason;

  factory RebalancingActionData.fromJson(Map<String, dynamic> json) {
    return RebalancingActionData(
      assetId: json['assetId'] as int,
      symbol: json['symbol'] as String,
      assetName: json['assetName'] as String,
      action: json['action'] as String,
      currentWeightPct: (json['currentWeightPct'] as num).toDouble(),
      targetWeightPct: (json['targetWeightPct'] as num).toDouble(),
      gapPct: (json['gapPct'] as num).toDouble(),
      suggestedAmount: (json['suggestedAmount'] as num).toDouble(),
      priority: json['priority'] as int,
      reason: json['reason'] as String,
    );
  }
}

class EtfRecommendationData {
  EtfRecommendationData({
    required this.etfId,
    required this.symbol,
    required this.name,
    required this.market,
    required this.focusTheme,
    required this.riskBucket,
    required this.expenseRatioPct,
    required this.suggestedWeightPct,
    required this.matchScore,
    required this.reason,
  });

  final int etfId;
  final String symbol;
  final String name;
  final String market;
  final String focusTheme;
  final String riskBucket;
  final double expenseRatioPct;
  final double suggestedWeightPct;
  final int matchScore;
  final String reason;

  factory EtfRecommendationData.fromJson(Map<String, dynamic> json) {
    return EtfRecommendationData(
      etfId: json['etfId'] as int,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      market: json['market'] as String,
      focusTheme: json['focusTheme'] as String,
      riskBucket: json['riskBucket'] as String,
      expenseRatioPct: (json['expenseRatioPct'] as num).toDouble(),
      suggestedWeightPct: (json['suggestedWeightPct'] as num).toDouble(),
      matchScore: json['matchScore'] as int,
      reason: json['reason'] as String,
    );
  }
}

class AiInsightData {
  AiInsightData({
    required this.headline,
    required this.summary,
    required this.keyPoints,
    required this.cautions,
    required this.generatedAt,
    required this.model,
  });

  final String headline;
  final String summary;
  final List<String> keyPoints;
  final List<String> cautions;
  final String generatedAt;
  final String model;

  factory AiInsightData.fromJson(Map<String, dynamic> json) {
    return AiInsightData(
      headline: json['headline'] as String,
      summary: json['summary'] as String,
      keyPoints:
          (json['keyPoints'] as List<dynamic>).map((e) => e as String).toList(),
      cautions:
          (json['cautions'] as List<dynamic>).map((e) => e as String).toList(),
      generatedAt: json['generatedAt'] as String,
      model: json['model'] as String,
    );
  }
}

class PortfolioSimulationData {
  PortfolioSimulationData({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.simulationDays,
    required this.startValue,
    required this.endValue,
    required this.pnlAmount,
    required this.pnlRate,
    required this.annualizedReturnPct,
    required this.maxDrawdownPct,
    required this.timeline,
    required this.contributions,
    required this.notes,
  });

  final int userId;
  final String startDate;
  final String endDate;
  final int simulationDays;
  final double startValue;
  final double endValue;
  final double pnlAmount;
  final double pnlRate;
  final double annualizedReturnPct;
  final double maxDrawdownPct;
  final List<SimulationPointData> timeline;
  final List<SimulationContributionData> contributions;
  final List<String> notes;

  factory PortfolioSimulationData.fromJson(Map<String, dynamic> json) {
    return PortfolioSimulationData(
      userId: json['userId'] as int,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      simulationDays: json['simulationDays'] as int,
      startValue: (json['startValue'] as num).toDouble(),
      endValue: (json['endValue'] as num).toDouble(),
      pnlAmount: (json['pnlAmount'] as num).toDouble(),
      pnlRate: (json['pnlRate'] as num).toDouble(),
      annualizedReturnPct: (json['annualizedReturnPct'] as num).toDouble(),
      maxDrawdownPct: (json['maxDrawdownPct'] as num).toDouble(),
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => SimulationPointData.fromJson(e as Map<String, dynamic>))
          .toList(),
      contributions: (json['contributions'] as List<dynamic>)
          .map((e) =>
              SimulationContributionData.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: (json['notes'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}

class SimulationPointData {
  SimulationPointData({
    required this.date,
    required this.simulatedValue,
    required this.cumulativeReturnPct,
    required this.drawdownPct,
  });

  final String date;
  final double simulatedValue;
  final double cumulativeReturnPct;
  final double drawdownPct;

  factory SimulationPointData.fromJson(Map<String, dynamic> json) {
    return SimulationPointData(
      date: json['date'] as String,
      simulatedValue: (json['simulatedValue'] as num).toDouble(),
      cumulativeReturnPct: (json['cumulativeReturnPct'] as num).toDouble(),
      drawdownPct: (json['drawdownPct'] as num).toDouble(),
    );
  }
}

class SimulationContributionData {
  SimulationContributionData({
    required this.assetId,
    required this.symbol,
    required this.assetName,
    required this.quantity,
    required this.startPrice,
    required this.endPrice,
    required this.pnlAmount,
    required this.pnlRate,
  });

  final int assetId;
  final String symbol;
  final String assetName;
  final double quantity;
  final double startPrice;
  final double endPrice;
  final double pnlAmount;
  final double pnlRate;

  factory SimulationContributionData.fromJson(Map<String, dynamic> json) {
    return SimulationContributionData(
      assetId: json['assetId'] as int,
      symbol: json['symbol'] as String,
      assetName: json['assetName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      startPrice: (json['startPrice'] as num).toDouble(),
      endPrice: (json['endPrice'] as num).toDouble(),
      pnlAmount: (json['pnlAmount'] as num).toDouble(),
      pnlRate: (json['pnlRate'] as num).toDouble(),
    );
  }
}

class LoginSessionData {
  LoginSessionData({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.userId,
    required this.loginId,
    required this.displayName,
    required this.roles,
  });

  final String accessToken;
  final String tokenType;
  final String expiresAt;
  final int userId;
  final String loginId;
  final String displayName;
  final List<String> roles;

  bool get isAdmin => roles.contains('ADMIN');

  factory LoginSessionData.fromJson(Map<String, dynamic> json) {
    return LoginSessionData(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresAt: json['expiresAt'] as String,
      userId: json['userId'] as int,
      loginId: json['loginId'] as String,
      displayName: json['displayName'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'expiresAt': expiresAt,
      'userId': userId,
      'loginId': loginId,
      'displayName': displayName,
      'roles': roles,
    };
  }
}

class InvestmentProfileData {
  InvestmentProfileData({
    required this.profileKey,
    required this.profileName,
    required this.shortLabel,
    required this.summary,
    required this.score,
    required this.riskTier,
    required this.targetAllocationHint,
    required this.updatedAt,
    required this.answers,
  });

  final String profileKey;
  final String profileName;
  final String shortLabel;
  final String summary;
  final int score;
  final int riskTier;
  final String targetAllocationHint;
  final String updatedAt;
  final Map<String, int> answers;

  factory InvestmentProfileData.fromJson(Map<String, dynamic> json) {
    final rawAnswers = (json['answers'] as Map<String, dynamic>? ?? {});
    return InvestmentProfileData(
      profileKey: json['profileKey'] as String,
      profileName: json['profileName'] as String,
      shortLabel: json['shortLabel'] as String? ?? '',
      summary: json['summary'] as String,
      score: json['score'] as int,
      riskTier: json['riskTier'] as int,
      targetAllocationHint: json['targetAllocationHint'] as String,
      updatedAt: json['updatedAt'] as String,
      answers: rawAnswers.map((key, value) => MapEntry(key, value as int)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileKey': profileKey,
      'profileName': profileName,
      'shortLabel': shortLabel,
      'summary': summary,
      'score': score,
      'riskTier': riskTier,
      'targetAllocationHint': targetAllocationHint,
      'updatedAt': updatedAt,
      'answers': answers,
    };
  }
}

class PaidServicePolicyData {
  PaidServicePolicyData({
    required this.serviceKey,
    required this.displayName,
    required this.dailyLimit,
    required this.enabled,
    required this.usedToday,
    required this.remainingToday,
  });

  final String serviceKey;
  final String displayName;
  final int dailyLimit;
  final bool enabled;
  final int usedToday;
  final int remainingToday;

  factory PaidServicePolicyData.fromJson(Map<String, dynamic> json) {
    return PaidServicePolicyData(
      serviceKey: json['serviceKey'] as String,
      displayName: json['displayName'] as String,
      dailyLimit: json['dailyLimit'] as int,
      enabled: json['enabled'] as bool,
      usedToday: json['usedToday'] as int,
      remainingToday: json['remainingToday'] as int,
    );
  }
}

class AdminUserData {
  AdminUserData({
    required this.userId,
    required this.loginId,
    required this.displayName,
    required this.status,
    required this.groupId,
    required this.groupName,
    required this.roles,
  });

  final int userId;
  final String loginId;
  final String displayName;
  final String status;
  final int? groupId;
  final String? groupName;
  final List<String> roles;

  bool get isAdmin => roles.contains('ADMIN');

  factory AdminUserData.fromJson(Map<String, dynamic> json) {
    return AdminUserData(
      userId: json['userId'] as int,
      loginId: json['loginId'] as String,
      displayName: json['displayName'] as String,
      status: json['status'] as String,
      groupId: json['groupId'] as int?,
      groupName: json['groupName'] as String?,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}

class AdminGroupData {
  AdminGroupData({
    required this.groupId,
    required this.groupKey,
    required this.groupName,
    required this.groupDesc,
    required this.enabled,
    required this.memberCount,
    required this.permissions,
  });

  final int groupId;
  final String groupKey;
  final String groupName;
  final String groupDesc;
  final bool enabled;
  final int memberCount;
  final List<String> permissions;

  factory AdminGroupData.fromJson(Map<String, dynamic> json) {
    return AdminGroupData(
      groupId: json['groupId'] as int,
      groupKey: json['groupKey'] as String,
      groupName: json['groupName'] as String,
      groupDesc: json['groupDesc'] as String? ?? '',
      enabled: json['enabled'] as bool,
      memberCount: json['memberCount'] as int,
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

class RuntimeConfigData {
  RuntimeConfigData({
    required this.runtimeConfigId,
    required this.configGroupCd,
    required this.configKey,
    required this.configName,
    required this.valueTypeCd,
    required this.configValue,
    required this.configDesc,
    required this.sortNo,
    required this.editable,
    required this.enabled,
    required this.updatedAt,
  });

  final int runtimeConfigId;
  final String configGroupCd;
  final String configKey;
  final String configName;
  final String valueTypeCd;
  final String configValue;
  final String configDesc;
  final int sortNo;
  final bool editable;
  final bool enabled;
  final String updatedAt;

  factory RuntimeConfigData.fromJson(Map<String, dynamic> json) {
    return RuntimeConfigData(
      runtimeConfigId: json['runtimeConfigId'] as int,
      configGroupCd: json['configGroupCd'] as String,
      configKey: json['configKey'] as String,
      configName: json['configName'] as String,
      valueTypeCd: json['valueTypeCd'] as String,
      configValue: json['configValue'] as String,
      configDesc: json['configDesc'] as String? ?? '',
      sortNo: json['sortNo'] as int,
      editable: json['editable'] as bool,
      enabled: json['enabled'] as bool,
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class TransactionImportResultData {
  TransactionImportResultData({
    required this.totalRows,
    required this.importedRows,
    required this.failedRows,
    required this.errors,
  });

  final int totalRows;
  final int importedRows;
  final int failedRows;
  final List<String> errors;

  factory TransactionImportResultData.fromJson(Map<String, dynamic> json) {
    return TransactionImportResultData(
      totalRows: json['totalRows'] as int? ?? 0,
      importedRows: json['importedRows'] as int? ?? 0,
      failedRows: json['failedRows'] as int? ?? 0,
      errors: (json['errors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
