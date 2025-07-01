import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fleet/info_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutDialog {
  // Show logout confirmation dialog
  static void showLogoutConfirmationDialog(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final double dialogWidth = screenSize.width > 600 ? 400 : screenSize.width * 0.9;
    
    // Adaptive padding based on screen size
    final EdgeInsets contentPadding = screenSize.width < 400 
        ? const EdgeInsets.all(16.0)
        : const EdgeInsets.all(24.0);
    
    // Adaptive icon size
    final double iconSize = screenSize.width < 360 ? 20.0 : 24.0;
    final double iconContainerSize = screenSize.width < 360 ? 40.0 : 48.0;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenSize.width < 400 ? 16 : 24, 
            vertical: screenSize.width < 400 ? 16 : 24
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxWidth: 450,
              minHeight: 180,
              maxHeight: screenSize.height * 0.8,
            ),
            padding: contentPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon - Made more responsive
                Flex(
                  direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: isSmallScreen 
                      ? CrossAxisAlignment.center 
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: iconContainerSize,
                      height: iconContainerSize,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.logout,
                          color: Colors.orange,
                          size: iconSize,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 0 : 16, height: isSmallScreen ? 16 : 0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isSmallScreen 
                            ? CrossAxisAlignment.center 
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('logout_title'),
                            textAlign: isSmallScreen ? TextAlign.center : TextAlign.start,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: screenSize.width < 360 ? 18 : null,
                            ),
                          ),
                          SizedBox(height: screenSize.width < 360 ? 2 : 4),
                          Text(
                            tr('logout_confirmation_question'),
                            textAlign: isSmallScreen ? TextAlign.center : TextAlign.start,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontSize: screenSize.width < 360 ? 13 : null,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenSize.width < 400 ? 16 : 24),
                
                // Warning message - Optimized for small screens
                Container(
                  padding: EdgeInsets.all(screenSize.width < 360 ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[700],
                        size: screenSize.width < 360 ? 16 : 20,
                      ),
                      SizedBox(width: screenSize.width < 360 ? 8 : 12),
                      Expanded(
                        child: Text(
                          tr('logout_warning_message'),
                          style: TextStyle(
                            fontSize: screenSize.width < 360 ? 12 : 14,
                            color: Colors.grey[700],
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenSize.width < 400 ? 16 : 24),
                
                // Buttons - Responsive layout (vertical on small screens)
                Flex(
                  direction: screenSize.width < 400 ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: screenSize.width < 400 
                      ? MainAxisAlignment.center 
                      : MainAxisAlignment.end,
                  crossAxisAlignment: screenSize.width < 400 
                      ? CrossAxisAlignment.stretch 
                      : CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: EdgeInsets.symmetric(
                          horizontal: 16, 
                          vertical: screenSize.width < 400 ? 10 : 12
                        ),
                      ),
                      child: Text(tr('logout_cancel')),
                    ),
                    SizedBox(
                      width: screenSize.width < 400 ? 0 : 12,
                      height: screenSize.width < 400 ? 8 : 0,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        performLogout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20, 
                          vertical: screenSize.width < 400 ? 10 : 12
                        ),
                      ),
                      child: Text(tr('logout_confirm')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Perform actual logout and navigation
  static Future<void> performLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Clear any cached user data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_permissions');
      
      // Important: Perform sign out last, after clearing any cached data
      await FirebaseAuth.instance.signOut();
      
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      // Navigate directly to login screen and remove all routes from stack
      // This ensures the app returns to the login screen without trying to access Firestore
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      debugPrint('Logout error: $e');
      
      // Show error message
      if (context.mounted) {
        InfoCard.showInfoCard(
          context,
          tr('logout_error'),
          Colors.red,
          icon: Icons.error,
        );
        
        // Even if there's an error, try to navigate to login
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      }
    }
  }
}
