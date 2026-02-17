import 'package:dio/dio.dart';
import 'dart:typed_data';

import '../config/app_env.dart';
import '../models/dashboard_models.dart';

class PlayAssetApiClient {
  PlayAssetApiClient({String? accessToken})
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppEnv.apiBaseUrl,
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
            headers: accessToken == null
                ? null
                : {'Authorization': 'Bearer $accessToken'},
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
    final response =
        await _dio.get<Map<String, dynamic>>('/v1/users/$userId/dashboard');
    return DashboardData.fromJson(_extractData(response.data));
  }

  Future<List<WatchlistItemData>> fetchWatchlist(int userId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/v1/users/$userId/watchlist');
    final payload = _extractListData(response.data);
    return payload.map(WatchlistItemData.fromJson).toList();
  }

  Future<List<PositionData>> fetchPositions(int userId) async {
    final response = await _dio
        .get<Map<String, dynamic>>('/v1/users/$userId/portfolio/positions');
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
    final response = await _dio
        .get<Map<String, dynamic>>('/v1/users/$userId/alerts/preferences');
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
    final response = await _dio
        .get<Map<String, dynamic>>('/v1/users/$userId/portfolio/advice');
    return PortfolioAdviceData.fromJson(_extractData(response.data));
  }

  Future<InvestmentProfileData?> fetchInvestmentProfile(int userId) async {
    final response = await _dio
        .get<Map<String, dynamic>>('/v1/users/$userId/investment-profile');
    final data = _extractDataNullable(response.data);
    if (data == null) {
      return null;
    }
    return InvestmentProfileData.fromJson(data);
  }

  Future<InvestmentProfileData> upsertInvestmentProfile(
    int userId,
    InvestmentProfileData profile,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/users/$userId/investment-profile',
      data: {
        'profileKey': profile.profileKey,
        'profileName': profile.profileName,
        'shortLabel': profile.shortLabel,
        'summary': profile.summary,
        'score': profile.score,
        'riskTier': profile.riskTier,
        'targetAllocationHint': profile.targetAllocationHint,
        'answers': profile.answers,
      },
    );
    return InvestmentProfileData.fromJson(_extractData(response.data));
  }

  Future<void> deleteInvestmentProfile(int userId) async {
    await _dio
        .delete<Map<String, dynamic>>('/v1/users/$userId/investment-profile');
  }

  Future<PortfolioSimulationData> fetchPortfolioSimulation(
    int userId, {
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null && startDate.isNotEmpty) {
      query['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      query['endDate'] = endDate;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/users/$userId/portfolio/simulation',
      queryParameters: query,
    );
    return PortfolioSimulationData.fromJson(_extractData(response.data));
  }

  Future<List<PaidServicePolicyData>> fetchPaidServicePolicies(
      {String? date}) async {
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

  Future<List<AdminGroupData>> fetchAdminGroups() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/admin/groups');
    final payload = _extractListData(response.data);
    return payload.map(AdminGroupData.fromJson).toList();
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

  Future<AdminUserData> updateUserGroup({
    required int userId,
    required int groupId,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/admin/users/$userId/group',
      data: {'groupId': groupId},
    );
    return AdminUserData.fromJson(_extractData(response.data));
  }

  Future<AdminGroupData> updateGroupPermissions({
    required int groupId,
    required List<String> permissions,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/admin/groups/$groupId/permissions',
      data: {'permissions': permissions},
    );
    return AdminGroupData.fromJson(_extractData(response.data));
  }

  Future<List<RuntimeConfigData>> fetchRuntimeConfigs(
      {String? groupCode}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/admin/runtime-configs',
      queryParameters: groupCode == null || groupCode.isEmpty
          ? null
          : {'groupCode': groupCode},
    );
    final payload = _extractListData(response.data);
    return payload.map(RuntimeConfigData.fromJson).toList();
  }

  Future<RuntimeConfigData> updateRuntimeConfig({
    required String groupCode,
    required String configKey,
    required String configName,
    required String valueTypeCd,
    required String configValue,
    required String configDesc,
    required bool enabled,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/admin/runtime-configs/$groupCode/$configKey',
      data: {
        'configName': configName,
        'valueTypeCd': valueTypeCd,
        'configValue': configValue,
        'configDesc': configDesc,
        'enabled': enabled,
      },
    );
    return RuntimeConfigData.fromJson(_extractData(response.data));
  }

  Future<TransactionImportResultData> uploadTransactionExcel({
    required int userId,
    int? accountId,
    required String fileName,
    Uint8List? fileBytes,
    String? filePath,
  }) async {
    MultipartFile multipart;
    if (fileBytes != null) {
      multipart = MultipartFile.fromBytes(fileBytes, filename: fileName);
    } else if (filePath != null && filePath.isNotEmpty) {
      multipart = await MultipartFile.fromFile(filePath, filename: fileName);
    } else {
      throw StateError('No file payload');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/users/$userId/portfolio/transactions/upload',
      data: FormData.fromMap({
        if (accountId != null) 'accountId': accountId,
        'file': multipart,
      }),
    );
    return TransactionImportResultData.fromJson(_extractData(response.data));
  }

  Future<PositionData> updateHoldingPosition({
    required int userId,
    required int assetId,
    required double quantity,
    required double avgCost,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/users/$userId/portfolio/positions/$assetId',
      data: {
        'quantity': quantity,
        'avgCost': avgCost,
      },
    );
    return PositionData.fromJson(_extractData(response.data));
  }

  Map<String, dynamic> _extractData(Map<String, dynamic>? root) {
    if (root == null || root['success'] != true) {
      throw StateError('API 응답 형식이 올바르지 않습니다.');
    }
    return root['data'] as Map<String, dynamic>;
  }

  Map<String, dynamic>? _extractDataNullable(Map<String, dynamic>? root) {
    if (root == null || root['success'] != true) {
      throw StateError('API 응답 형식이 올바르지 않습니다.');
    }
    final data = root['data'];
    if (data == null) {
      return null;
    }
    return data as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _extractListData(Map<String, dynamic>? root) {
    if (root == null || root['success'] != true) {
      throw StateError('API 응답 형식이 올바르지 않습니다.');
    }
    return (root['data'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
