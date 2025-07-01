import 'package:cloud_functions/cloud_functions.dart';
import 'package:fleet/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleet/info_card.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  bool _isLoading = false;
  bool _resetEmailSent = false;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Updated to use only cloud functions for password reset
  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    
    try {
      // Use exclusively the dedicated cloud function for password reset
      final result = await _functions
          .httpsCallable('sendPasswordResetEmail')
          .call({
            'email': email,
          });

      // Check if the function executed successfully
      if (result.data['success'] == true) {
        setState(() => _resetEmailSent = true);
        
        // Log the action in Firestore for analytics
        await FirebaseFirestore.instance.collection('EmailLogs').add({
          'type': 'password_reset_request',
          'email': email,
          'timestamp': FieldValue.serverTimestamp(),
          'success': true,
          'method': 'cloud_function',
        });
        
        InfoCard.showInfoCard(
          context,
          tr('forgot_password_email_sent'),
          Colors.green,
          icon: Icons.check_circle,
        );
      } else {
        // Handle specific error messages from the cloud function
        String errorMessage = result.data['message'] ?? tr('forgot_password_error');
        
        if (errorMessage.contains('user-not-found') || 
            errorMessage.contains('No user found')) {
          errorMessage = tr('forgot_password_no_user');
        } else if (errorMessage.contains('invalid-email')) {
          errorMessage = tr('validator_email_invalid');
        }
        
        InfoCard.showInfoCard(
          context,
          errorMessage,
          Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      // Log the error
      await FirebaseFirestore.instance.collection('EmailLogs').add({
        'type': 'password_reset_request',
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'success': false,
        'error': e.toString(),
      });
      
      String errorMessage = tr('forgot_password_error');
      
      // Try to extract more specific error message if available
      if (e is FirebaseFunctionsException) {
        if (e.code == 'not-found' || e.message?.contains('user-not-found') == true) {
          errorMessage = tr('forgot_password_no_user');
        } else if (e.code == 'invalid-argument' || e.message?.contains('invalid-email') == true) {
          errorMessage = tr('validator_email_invalid');
        }
      }
      
      InfoCard.showInfoCard(
        context,
        errorMessage,
        Colors.red,
        icon: Icons.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Responsive width based on screen size
            maxWidth: screenSize.width > 600 ? 450 : screenSize.width * 0.95,
            // Allow height to adjust based on content
            minHeight: 100,
          ),
          child: _buildDialogContent(context, isSmallScreen),
        ),
      ),
    );
  }
  
  Widget _buildDialogContent(BuildContext context, bool isSmallScreen) {
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button - responsive layout
            _buildResponsiveHeader(context, isSmallScreen),
            
            const Divider(height: 30),
            
            // Form or success message
            _resetEmailSent
                ? _buildSuccessContent()
                : _buildResetForm(isSmallScreen),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResponsiveHeader(BuildContext context, bool isSmallScreen) {
    if (isSmallScreen) {
      // Vertical layout for small screens
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button at top right
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: Colors.grey[600],
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          
          // Icon and title in a row
          Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _resetEmailSent ? Icons.mark_email_read : Icons.lock_reset,
                    size: 24,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Text(
                  _resetEmailSent
                      ? tr('forgot_password_check_email')
                      : tr('forgot_password_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          
          // Instructions with proper padding
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              _resetEmailSent
                  ? tr('forgot_password_email_instructions')
                  : tr('forgot_password_instructions'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    } else {
      // Horizontal layout for larger screens
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                _resetEmailSent ? Icons.mark_email_read : Icons.lock_reset,
                size: 24,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resetEmailSent
                      ? tr('forgot_password_check_email')
                      : tr('forgot_password_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _resetEmailSent
                      ? tr('forgot_password_email_instructions')
                      : tr('forgot_password_instructions'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Colors.grey[600],
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }
  }
  
  Widget _buildSuccessContent() {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.email, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('forgot_password_email_sent_to', args: [_emailController.text.trim()]),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(tr('dialog_close')),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResetForm(bool isSmallScreen) {
    return FadeTransition(
      opacity: _animationController,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('login_email_label'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: tr('login_email_hint'),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12, 
                  horizontal: isSmallScreen ? 12 : 16
                ),
                prefixIcon: Icon(
                  Icons.email,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.5,
                  ),
                ),
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr('validator_email_required');
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return tr('validator_email_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Info box to provide additional guidance
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('forgot_password_email_info'),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider and action buttons
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildResponsiveButtons(isSmallScreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveButtons(bool isSmallScreen) {
    if (isSmallScreen) {
      // Stack buttons vertically on small screens
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Send button
          ElevatedButton(
            onPressed: _isLoading ? null : _sendPasswordResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(tr('forgot_password_send_button')),
          ),
          const SizedBox(height: 10),
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: Text(tr('dialog_cancel')),
          ),
        ],
      );
    } else {
      // Keep buttons in row for larger screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: Text(tr('dialog_cancel')),
          ),
          const SizedBox(width: 12),
          // Send button
          ElevatedButton(
            onPressed: _isLoading ? null : _sendPasswordResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(tr('forgot_password_send_button')),
          ),
        ],
      );
    }
  }
}
