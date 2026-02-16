import 'package:dio/dio.dart';

import '../config/app_env.dart';
import '../models/dashboard_models.dart';

class PlayAssetApiClient {
  PlayAssetApiClient({String? accessToken})
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppEnv.apiBaseUrl,
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
            headers: accessToken == null ? null : {'Authorization': 'Bearer $accessToken'},
          ),
        );

  final Dio _dio;

  Future<LoginSessionData> login({
    required String loginId,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {
        'loginId': loginId,
        'password': password,
      },
    );
    return LoginSessionData.fromJson(_extractData(response.data));
  }

  Future<void> logout() async {
    await _dio.post<Map<String, dynamic>>('/v1/auth/logout');
  }

  Future<LoginSessionData> fetchMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/auth/me');
    final data = _extractData(response.data);
    return LoginSessionData(
      accessToken: '',
      tokenType: 'Bearer',
      expiresAt: '',
      userId: data['userId'] as int,
      loginId: data['loginId'] as String,
      displayName: data['displayName'] as String,
      roles: (data['roles'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Future<DashboardData> fetchDashboard(int userId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/users/$userId/dashboard');
    return DashboardData.fromJson(_extractData(response.data));
  }

  Future<List<WatchlistItemData>> fetchWatchlist(int userId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/users/$userId/watchlist');
    final payload = _extractListData(response.data);
    return payload.map(WatchlistItemData.fromJson).toList();
  }

  Future<List<PositionData>> fetchPositions(int userId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/users/$userId/portfolio/positions');
    final payload = _extractListData(response.data);
    return payload.map(PositionData.fromJson).toList();
  }

  Future<List<AlertData>> fetchAlerts(int userId, {int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/users/$userId/alerts',
      queryParameters: {'limit': limit},
    );
    final payload = _extractListData(response.data);
    return payload.map(AlertData.fromJson).toList();
  }

  Future<AlertPreferenceData> fetchAlertPreference(int userId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/users/$userId/alerts/preferences');
    return AlertPreferenceData.fromJson(_extractData(response.data));
  }

  Future<AlertPreferenceData> updateAlertPreference(
    int userId, {
    required bool lowEnabled,
    required bool mediumEnabled,
    required bool highEnabled,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/users/$userId/alerts/preferences',
      data: {
        'lowEnabled': lowEnabled,
        'mediumEnabled': mediumEnabled,
        'highEnabled': highEnabled,
      },
    );
    return AlertPreferenceData.fromJson(_extractData(response.data));
  }

  Future<PortfolioAdviceData> fetchPortfolioAdvice(int userId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/users/$userId/portfolio/advice');
    return PortfolioAdviceData.fromJson(_extractData(response.data));
  }

  Future<PortfolioSimulationData> fetchPortfolioSimulation(
    int userId, {
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/users/$userId/portfolio/simulation',
      queryParameters: query,
    );
    return PortfolioSimulationData.fromJson(_extractData(response.data));
  }

  Future<List<PaidServicePolicyData>> fetchPaidServicePolicies({String? date}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/admin/paid-services/policies',
      queryParameters: date == null ? null : {'date': date},
    );
    final payload = _extractListData(response.data);
    return payload.map(PaidServicePolicyData.fromJson).toList();
  }

  Future<PaidServicePolicyData> updatePaidServicePolicy({
    required String serviceKey,
    required String displayName,
    required int dailyLimit,
    required bool enabled,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/admin/paid-services/policies/$serviceKey',
      data: {
        'displayName': displayName,
        'dailyLimit': dailyLimit,
        'enabled': enabled,
      },
    );
    return PaidServicePolicyData.fromJson(_extractData(response.data));
  }

  Future<List<AdminUserData>> fetchAdminUsers() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/admin/users');
    final payload = _extractListData(response.data);
    return payload.map(AdminUserData.fromJson).toList();
  }

  Future<AdminUserData> updateUserRoles({
    required int userId,
    required List<String> roles,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/admin/users/$userId/roles',
      data: {'roles': roles},
    );
    return AdminUserData.fromJson(_extractData(response.data));
  }

  Map<String, dynamic> _extractData(Map<String, dynamic>? root) {
    if (root == null || root['success'] != true) {
      throw StateError('API 응답 형식이 올바르지 않습니다.');
    }
    return root['data'] as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _extractListData(Map<String, dynamic>? root) {
    if (root == null || root['success'] != true) {
      throw StateError('API 응답 형식이 올바르지 않습니다.');
    }
    return (root['data'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
  }
}
