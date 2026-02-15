class AppEnv {
  const AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '/api',
  );

  static const String externalMarketApiKey = String.fromEnvironment(
    'EXTERNAL_MARKET_API_KEY',
    defaultValue: '',
  );

  static const String externalNewsApiKey = String.fromEnvironment(
    'EXTERNAL_NEWS_API_KEY',
    defaultValue: '',
  );
}
