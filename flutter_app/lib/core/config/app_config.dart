/// Application configuration and constants
class AppConfig {
  // API Configuration
  static const String productionApiBaseUrl =
      'https://travel-fleet.onrender.com/api';
  static const String apiVersion = 'v1';
  static const int apiTimeout = 45; // seconds (Render cold start friendly)
  static const int apiRetryCount = 2;
  static const int apiInitialRetryDelayMs = 1500;

  /// Single source of truth for API base URL.
  /// Optional override via --dart-define=API_BASE_URL for controlled deployments.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return fromEnv.isNotEmpty ? fromEnv : productionApiBaseUrl;
  }

  // App Information
  static const String appName = 'Travel Fleet';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Authentication
  static const String tokenExpiryDuration = '24h';
  static const String tokenRefreshBuffer = '5m';

  // Location Services
  static const int locationUpdateInterval = 5; // seconds
  static const int locationAccuracyThreshold = 10; // meters
  static const bool continuousLocationTracking = true;

  // UI Configuration
  static const int animationDurationMs = 300;
  static const double defaultBorderRadius = 16.0;
  static const double defaultPadding = 16.0;

  // Feature Flags
  static const bool enableGPS = true;
  static const bool enableNotifications = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = true;

  // Debugging
  static const bool debugMode = true;
  static const bool logApiRequests = true;
  static const bool logApiResponses = true;

  // Pagination
  static const int paginationPageSize = 20;
  static const int paginationMaxPages = 100;

  // Notifications
  static const int notificationCheckInterval = 60; // seconds
  static const int maxNotifications = 100;

  // Photo/Video Upload
  static const int maxUploadSize = 10; // MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];

  // Trip Configuration
  static const int maxTripsPerDay = 50;
  static const int tripHistoryDays = 90;

  // Driver Configuration
  static const int maxDriversPerOwner = 1000;
  static const double defaultBataRate = 300.0;
  static const double defaultSalaryPerDay = 1000.0;

  /// Get API endpoint
  static String getApiEndpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$apiBaseUrl/$normalizedPath';
  }

  /// Get API headers
  static Map<String, String> getApiHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

/// Environment-specific configuration
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.production;

  static Environment get currentEnvironment => _currentEnvironment;

  static String get baseUrl {
    return AppConfig.apiBaseUrl;
  }

  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  static bool get isDevelopment =>
      _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;
}
