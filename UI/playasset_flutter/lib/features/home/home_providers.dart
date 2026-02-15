import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/dashboard_models.dart';
import '../../core/network/api_client.dart';

const defaultUserId = 1001;

final apiClientProvider = Provider<PlayAssetApiClient>((ref) {
  return PlayAssetApiClient();
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchDashboard(defaultUserId);
});

final watchlistProvider = FutureProvider<List<WatchlistItemData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchWatchlist(defaultUserId);
});

final positionsProvider = FutureProvider<List<PositionData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchPositions(defaultUserId);
});

final alertsProvider = FutureProvider<List<AlertData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchAlerts(defaultUserId);
});

final advisorProvider = FutureProvider<PortfolioAdviceData>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchPortfolioAdvice(defaultUserId);
});

class PortfolioSimulationQuery {
  const PortfolioSimulationQuery({
    this.startDate,
    this.endDate,
  });

  final DateTime? startDate;
  final DateTime? endDate;

  String? get startDateText => _toDateString(startDate);
  String? get endDateText => _toDateString(endDate);

  static String? _toDateString(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  bool operator ==(Object other) {
    return other is PortfolioSimulationQuery &&
        other.startDateText == startDateText &&
        other.endDateText == endDateText;
  }

  @override
  int get hashCode => Object.hash(startDateText, endDateText);
}

final portfolioSimulationProvider = FutureProvider.family<PortfolioSimulationData, PortfolioSimulationQuery>((ref, query) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchPortfolioSimulation(
    defaultUserId,
    startDate: query.startDateText,
    endDate: query.endDateText,
  );
});
