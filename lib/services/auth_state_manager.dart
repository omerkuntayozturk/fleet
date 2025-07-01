import 'package:flutter/foundation.dart';

/// Manages global authentication state
class AuthStateManager {
  static bool _isLoggingOut = false;
  
  /// Get the current logging out state
  static bool get isLoggingOut => _isLoggingOut;
  
  /// Set the logging out state
  static void setLoggingOut(bool value) {
    _isLoggingOut = value;
    debugPrint('AuthStateManager: Logging out state set to $value');
  }
}
