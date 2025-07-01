import 'package:flutter/material.dart';
import '../views/login/membership_details_screen.dart';

/// Utility class for handling safe navigation and dialog showing
class NavigationHelper {
  /// Safely shows a dialog by checking if the context is still valid
  static Future<T?> safeShowDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return null;
    
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
  
  /// Safely navigate to the membership details screen
  static void navigateToMembershipDetails(BuildContext context, {required String membershipStatus}) {
    if (membershipStatus == 'free') {
      // Use a try-catch to handle any navigation errors
      try {
        MembershipDetailsScreen.show(context, membershipStatus: membershipStatus);
      } catch (e) {
        debugPrint('Error navigating to membership details: $e');
        
        // Fallback navigation method if the previous one fails
        try {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            '/membership_details',
            (route) => false,
          );
        } catch (e) {
          debugPrint('Even fallback navigation failed: $e');
        }
      }
    }
  }
}
