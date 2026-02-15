import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/dashboard_models.dart';
import '../../core/network/api_client.dart';

class SessionState {
  const SessionState({
    required this.session,
    required this.isLoading,
    required this.errorMessage,
  });

  const SessionState.signedOut()
      : session = null,
        isLoading = false,
        errorMessage = null;

  final LoginSessionData? session;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => session != null;
  bool get isAdmin => session?.isAdmin ?? false;
  int? get userId => session?.userId;

  SessionState copyWith({
    LoginSessionData? session,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController() : super(const SessionState.signedOut());

  Future<void> login({
    required String loginId,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = PlayAssetApiClient();
      final session = await api.login(loginId: loginId, password: password);
      state = SessionState(session: session, isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '로그인에 실패했습니다. 아이디/비밀번호를 확인하세요.');
    }
  }

  Future<void> logout() async {
    final current = state.session;
    if (current != null) {
      try {
        await PlayAssetApiClient(accessToken: current.accessToken).logout();
      } catch (_) {
        // ignore logout network errors and clear local state
      }
    }
    state = const SessionState.signedOut();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final sessionControllerProvider = StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController();
});

final apiClientProvider = Provider<PlayAssetApiClient>((ref) {
  final token = ref.watch(sessionControllerProvider).session?.accessToken;
  return PlayAssetApiClient(accessToken: token);
});

final currentUserIdProvider = Provider<int>((ref) {
  final userId = ref.watch(sessionControllerProvider).userId;
  if (userId == null) {
    throw StateError('로그인이 필요합니다.');
  }
  return userId;
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return api.fetchDashboard(userId);
});

final watchlistProvider = FutureProvider<List<WatchlistItemData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return api.fetchWatchlist(userId);
});

final positionsProvider = FutureProvider<List<PositionData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return api.fetchPositions(userId);
});

final alertsProvider = FutureProvider<List<AlertData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return api.fetchAlerts(userId);
});

final advisorProvider = FutureProvider<PortfolioAdviceData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return api.fetchPortfolioAdvice(userId);
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
  final userId = ref.watch(currentUserIdProvider);
  return api.fetchPortfolioSimulation(
    userId,
    startDate: query.startDateText,
    endDate: query.endDateText,
  );
});

final paidServicePoliciesProvider = FutureProvider<List<PaidServicePolicyData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchPaidServicePolicies();
});

final adminUsersProvider = FutureProvider<List<AdminUserData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchAdminUsers();
});
