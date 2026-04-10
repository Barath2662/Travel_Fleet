import 'package:flutter/material.dart';

/// Global error handler for the application
class AppErrorHandler {
  static final AppErrorHandler _instance = AppErrorHandler._internal();

  factory AppErrorHandler() {
    return _instance;
  }

  AppErrorHandler._internal();

  /// Handle and display errors
  static void handleError(
    BuildContext context,
    dynamic error, {
    String title = 'Error',
    VoidCallback? onRetry,
  }) {
    final message = _getErrorMessage(error);
    
    _showErrorDialog(
      context,
      title: title,
      message: message,
      onRetry: onRetry,
    );
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') || errorString.contains('connection')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Your session has expired. Please login again.';
    }

    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'You do not have permission to perform this action.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('server error') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Show error dialog
  static void _showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (onRetry != null)
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('Retry'),
              ),
          ],
        );
      },
    );
  }

  /// Show snackbar message
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Log error to console for development
  static void logError(String tag, dynamic error, StackTrace stackTrace) {
    // Error logging disabled in production
    // To enable debugging, uncomment the lines below:
    // debugPrint('[$tag] Error: $error');
    // debugPrint('StackTrace: $stackTrace');
  }
}

/// Custom exceptions
class AppException implements Exception {
  final String message;
  final String? code;

  AppException({required this.message, this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({required super.message});
}

class AuthException extends AppException {
  AuthException({required super.message});
}

class ValidationException extends AppException {
  ValidationException({required super.message});
}

class PermissionException extends AppException {
  PermissionException({required super.message});
}
