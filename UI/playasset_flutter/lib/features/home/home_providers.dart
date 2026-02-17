import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/dashboard_models.dart';
import '../../core/network/api_client.dart';

class SessionState {
  const SessionState({
    required this.session,
    required this.isLoading,
    required this.isBootstrapping,
    required this.errorMessage,
  });

  const SessionState.bootstrapping()
      : session = null,
        isLoading = false,
        isBootstrapping = true,
        errorMessage = null;

  const SessionState.signedOut()
      : session = null,
        isLoading = false,
        isBootstrapping = false,
        errorMessage = null;

  final LoginSessionData? session;
  final bool isLoading;
  final bool isBootstrapping;
  final String? errorMessage;

  bool get isAuthenticated => session != null;
  bool get isAdmin => session?.isAdmin ?? false;
  int? get userId => session?.userId;

  SessionState copyWith({
    LoginSessionData? session,
    bool? isLoading,
    bool? isBootstrapping,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController() : super(const SessionState.bootstrapping()) {
    _restoreSession();
  }

  static const _sessionStorageKey = 'playasset.session.v1';

  Future<void> login({
    required String loginId,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = PlayAssetApiClient();
      final session = await api.login(loginId: loginId, password: password);
      state = SessionState(
        session: session,
        isLoading: false,
        isBootstrapping: false,
        errorMessage: null,
      );

      // Storage failure should not block current runtime login.
      try {
        await _saveSession(session);
      } catch (_) {
        // ignore
      }
    } catch (error) {
      state = state.copyWith(
          isLoading: false, errorMessage: _loginErrorMessage(error));
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
    await _clearSession();
    state = const SessionState.signedOut();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_sessionStorageKey);
      if (json == null || json.isEmpty) {
        state = const SessionState.signedOut();
        return;
      }

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final saved = LoginSessionData.fromJson(decoded);
      if (_isExpired(saved.expiresAt)) {
        await _clearSession();
        state = const SessionState.signedOut();
        return;
      }

      final me =
          await PlayAssetApiClient(accessToken: saved.accessToken).fetchMe();
      final restored = LoginSessionData(
        accessToken: saved.accessToken,
        tokenType: saved.tokenType,
        expiresAt: saved.expiresAt,
        userId: me.userId,
        loginId: me.loginId,
        displayName: me.displayName,
        roles: me.roles,
      );
      await _saveSession(restored);
      state = SessionState(
        session: restored,
        isLoading: false,
        isBootstrapping: false,
        errorMessage: null,
      );
    } catch (_) {
      await _clearSession();
      state = const SessionState.signedOut();
    }
  }

  bool _isExpired(String rawExpiresAt) {
    if (rawExpiresAt.isEmpty) return false;
    final parsed = DateTime.tryParse(rawExpiresAt);
    if (parsed == null) return false;
    return parsed.isBefore(DateTime.now().toUtc());
  }

  Future<void> _saveSession(LoginSessionData session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionStorageKey, jsonEncode(session.toJson()));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionStorageKey);
  }

  String _loginErrorMessage(Object error) {
    if (error is DioException) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        final message = payload['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return '서버에 연결할 수 없어요. 서버 상태를 확인해 주세요.';
      }
    }
    return '로그인에 실패했어요. 아이디/비밀번호를 다시 확인해 주세요.';
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController();
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.dark) {
    _restoreThemeMode();
  }

  static const _storageKey = 'playasset.theme_mode.v1';

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }

  Future<void> _restoreThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == ThemeMode.light.name) {
      state = ThemeMode.light;
      return;
    }
    state = ThemeMode.dark;
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});

final apiClientProvider = Provider<PlayAssetApiClient>((ref) {
  final token = ref.watch(sessionControllerProvider).session?.accessToken;
  return PlayAssetApiClient(accessToken: token);
});

final currentUserIdProvider = Provider<int>((ref) {
  final userId = ref.watch(sessionControllerProvider).userId;
  if (userId == null) {
    throw StateError('로그인이 필요해요.');
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

final alertPreferenceProvider =
    FutureProvider<AlertPreferenceData>((ref) async {
  final api = ref.watch(apiClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return api.fetchAlertPreference(userId);
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

final portfolioSimulationProvider =
    FutureProvider.family<PortfolioSimulationData, PortfolioSimulationQuery>(
        (ref, query) async {
  final api = ref.watch(apiClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return api.fetchPortfolioSimulation(
    userId,
    startDate: query.startDateText,
    endDate: query.endDateText,
  );
});

final paidServicePoliciesProvider =
    FutureProvider<List<PaidServicePolicyData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchPaidServicePolicies();
});

final adminUsersProvider = FutureProvider<List<AdminUserData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchAdminUsers();
});

final adminGroupsProvider = FutureProvider<List<AdminGroupData>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchAdminGroups();
});

final runtimeConfigsProvider =
    FutureProvider.family<List<RuntimeConfigData>, String?>(
        (ref, groupCode) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchRuntimeConfigs(groupCode: groupCode);
});

class InvestmentProfileController
    extends StateNotifier<InvestmentProfileData?> {
  InvestmentProfileController(this.ref, this.userId) : super(null) {
    _load();
  }

  final Ref ref;
  final int? userId;

  Future<void> save(InvestmentProfileData profile) async {
    final uid = userId;
    if (uid == null) {
      state = null;
      return;
    }
    final api = ref.read(apiClientProvider);
    final saved = await api.upsertInvestmentProfile(uid, profile);
    state = saved;
    ref.invalidate(advisorProvider);
  }

  Future<void> clear() async {
    final uid = userId;
    if (uid == null) {
      state = null;
      return;
    }
    final api = ref.read(apiClientProvider);
    await api.deleteInvestmentProfile(uid);
    state = null;
    ref.invalidate(advisorProvider);
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> _load() async {
    final uid = userId;
    if (uid == null) {
      state = null;
      return;
    }
    final api = ref.read(apiClientProvider);
    state = await api.fetchInvestmentProfile(uid);
  }
}

final investmentProfileProvider =
    StateNotifierProvider<InvestmentProfileController, InvestmentProfileData?>(
        (ref) {
  final userId = ref.watch(sessionControllerProvider).userId;
  return InvestmentProfileController(ref, userId);
});
