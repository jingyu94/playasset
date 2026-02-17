import 'package:flutter/foundation.dart';

class AppEnv {
  const AppEnv._();

  static const String _compiledApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Mobile sideload baseline fallback for local LAN testing.
  static const String _defaultMobileApiBaseUrl = String.fromEnvironment(
    'PLAYASSET_DEFAULT_MOBILE_API_BASE_URL',
    defaultValue: 'http://192.168.68.58:8081/api',
  );

  static String get apiBaseUrl {
    if (_compiledApiBaseUrl.isNotEmpty) {
      return _compiledApiBaseUrl;
    }
    if (kIsWeb) {
      return '/api';
    }
    return _defaultMobileApiBaseUrl;
  }

  static const String externalMarketApiKey = String.fromEnvironment(
    'EXTERNAL_MARKET_API_KEY',
    defaultValue: '',
  );

  static const String externalNewsApiKey = String.fromEnvironment(
    'EXTERNAL_NEWS_API_KEY',
    defaultValue: '',
  );
}
