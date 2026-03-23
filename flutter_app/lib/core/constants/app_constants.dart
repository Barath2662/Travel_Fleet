import 'package:flutter/foundation.dart';

class AppConstants {
  static const appName = 'Travel Fleet';

  // Production backend URL
  static const String productionBaseUrl = 'https://travel-fleet.onrender.com/api';

  static final String baseUrl = () {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      // 10.0.2.2 works only for Android emulator.
      if (defaultTargetPlatform != TargetPlatform.android && fromEnv.contains('10.0.2.2')) {
        return fromEnv.replaceFirst('10.0.2.2', '127.0.0.1');
      }
      return fromEnv;
    }

    // Use production URL by default for APK builds
    return productionBaseUrl;
  }();
}
