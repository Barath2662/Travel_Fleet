import '../config/app_config.dart';

class AppConstants {
  static const appName = 'Travel Fleet';

  /// Backward-compatible mirror for legacy references.
  /// Canonical source: AppConfig.apiBaseUrl.
  static String get baseUrl => AppConfig.apiBaseUrl;
}
