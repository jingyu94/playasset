import 'package:dio/dio.dart';

import '../config/app_env.dart';
import '../models/dashboard_models.dart';

class PlayAssetApiClient {
  PlayAssetApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppEnv.apiBaseUrl,
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );

  final Dio _dio;

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
