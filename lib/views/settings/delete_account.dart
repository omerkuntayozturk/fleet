import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fleet/info_card.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountDialog {
  // Static method to show the delete account confirmation dialog
  static void showDeleteAccountDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final AuthService authService = AuthService();
    bool isLoading = false;
    bool isParentAccount = false;
    int subUserCount = 0;
    
    // Check if user has sub-users
    Future<Map<String, dynamic>> _checkForSubUsers() async {
      try {
        final currentUser = await authService.getCurrentUser();
        if (currentUser == null) {
          return {'isParent': false, 'subUserCount': 0};
        }
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          return {
            'isParent': userData['hasSubUsers'] as bool? ?? false,
            'subUserCount': userData['subUserCount'] as int? ?? 0
          };
        }
        return {'isParent': false, 'subUserCount': 0};
      } catch (e) {
        print('Error checking for sub-users: $e');
        return {'isParent': false, 'subUserCount': 0};
      }
    }
    
    // First show a loading dialog while we check
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 20),
              Flexible(child: Text(tr('checking_account_status'))),
            ],
          ),
        );
      },
    );
    
    // Check for sub-users
    _checkForSubUsers().then((result) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Get screen size for responsive layout
      final screenSize = MediaQuery.of(context).size;
      final isSmallScreen = screenSize.width < 600;
      
      // Now show the actual delete dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          isParentAccount = result['isParent'] as bool? ?? false;
          subUserCount = result['subUserCount'] as int? ?? 0;
          
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? screenSize.width * 0.9 : 500,
                    maxHeight: isSmallScreen ? screenSize.height * 0.8 : screenSize.height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title with responsive text size
                          Text(
                            tr('delete_account_title'),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          
                          // Main confirmation message
                          Text(
                            tr('delete_account_confirmation_message'),
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                            textAlign: TextAlign.center,
                          ),
                          
                          // Warning for parent accounts
                          if (isParentAccount) ...[
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.warning, 
                                          color: Colors.amber.shade800, 
                                          size: isSmallScreen ? 18 : 24),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tr('parent_account_warning'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 13 : 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    tr('sub_users_will_be_deleted')
                                        .replaceAll('{count}', subUserCount.toString()),
                                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          
                          // Password confirmation section
                          Text(
                            tr('delete_account_password_confirmation'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          
                          // Password field
                          TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: tr('password'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                            ),
                            obscureText: true,
                          ),
                          
                          SizedBox(height: isSmallScreen ? 20 : 28),
                          
                          // Action buttons - wrap for small screens
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              TextButton(
                                onPressed: isLoading ? null : () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 16,
                                    vertical: isSmallScreen ? 8 : 12,
                                  ),
                                ),
                                child: Text(
                                  tr('delete_account_cancel'),
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 16,
                                    vertical: isSmallScreen ? 8 : 12,
                                  ),
                                  minimumSize: Size(isSmallScreen ? 100 : 120, 0),
                                ),
                                onPressed: isLoading ? null : () async {
                                  if (passwordController.text.isEmpty) {
                                    InfoCard.showInfoCard(
                                      context,
                                      tr('password_required'),
                                      Colors.red,
                                      icon: Icons.error,
                                    );
                                    return;
                                  }
                                  
                                  setState(() {
                                    isLoading = true;
                                  });
                                  
                                  try {
                                    // Make sure the BuildContext is still active before proceeding
                                    if (!context.mounted) return;
                                    
                                    await authService.deleteUserAccount(
                                      password: passwordController.text,
                                    );
                                    
                                    // Make sure the BuildContext is still active after the async operation
                                    if (!context.mounted) return;
                                    
                                    // Close the dialog
                                    Navigator.of(context).pop();
                                    
                                    // Use Future.microtask to ensure the dialog is closed before showing info card
                                    Future.microtask(() {
                                      // Show success message only if context is still mounted
                                      if (context.mounted) {
                                        InfoCard.showInfoCard(
                                          context, 
                                          isParentAccount 
                                            ? tr('parent_account_deleted_successfully_sub_users_marked') 
                                            : tr('account_deleted_successfully'), 
                                          Colors.green,
                                          icon: Icons.check_circle,
                                          duration: Duration(seconds: isParentAccount ? 5 : 3),
                                        );
                                        
                                        // Safely navigate to login screen
                                        Navigator.of(context).pushNamedAndRemoveUntil(
                                          '/login',
                                          (route) => false,
                                        );
                                      }
                                    });
                                  } catch (e, stackTrace) {
                                    // Log the error with stack trace for debugging
                                    print('Error during account deletion: $e');
                                    print('Stack trace: $stackTrace');
                                    
                                    // Make sure the BuildContext is still active
                                    if (!context.mounted) return;
                                    
                                    // Close the dialog
                                    Navigator.of(context).pop();
                                    
                                    // Use Future.microtask to ensure dialog is closed before showing error
                                    Future.microtask(() {
                                      if (context.mounted) {
                                        // Show error message with simplified error message
                                        InfoCard.showInfoCard(
                                          context, 
                                          tr('delete_account_error') + ': ' + e.toString().split('\n')[0], 
                                          Colors.red,
                                          icon: Icons.error,
                                        );
                                      }
                                    });
                                  }
                                },
                                child: isLoading 
                                  ? SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    )
                                  : Text(
                                      tr('delete_account_confirm'),
                                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          );
        },
      );
    });
  }
}
