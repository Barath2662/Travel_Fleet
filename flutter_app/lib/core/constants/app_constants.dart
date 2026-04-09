import 'package:flutter/foundation.dart';

class AppConstants {
  static const appName = 'Travel Fleet';
  
  /// Production backend URL (Render deployment)
  static const String productionBaseUrl = 'https://travel-fleet.onrender.com/api';
  
  /// Local development backend URL
  static const String developmentBaseUrl = 'http://localhost:3000/api';
  
  /// Android emulator workaround for localhost
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000/api';

  /// Determines the API base URL based on environment and platform
  /// Priority: Environment variable > Platform detection > Default
  static final String baseUrl = () {
    // First check if API_BASE_URL is provided as environment variable at build time
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      // Special handling for Android emulator - replace 10.0.2.2 for non-Android platforms
      if (defaultTargetPlatform != TargetPlatform.android && fromEnv.contains('10.0.2.2')) {
        return fromEnv.replaceFirst('10.0.2.2', '127.0.0.1');
      }
      return fromEnv;
    }

    // Return production URL by default for APK builds
    // Override with --dart-define=API_BASE_URL= for local development
    return productionBaseUrl;
  }();
}

