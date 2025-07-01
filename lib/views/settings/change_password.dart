import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleet/info_card.dart';
import '../../services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class PasswordChangeDialog extends StatefulWidget {
  const PasswordChangeDialog({Key? key}) : super(key: key);

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  // Controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // UI state
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  // Password validation rules - same as register screen
  final Map<String, bool> _passwordRules = {
    'password_rule_min_length': false,
    'password_rule_uppercase': false,
    'password_rule_number': false,
    'password_rule_special': false,
  };

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Validate the password against all rules
  void _validatePassword(String password) {
    setState(() {
      _passwordRules['password_rule_min_length'] = password.length >= 8;
      _passwordRules['password_rule_uppercase'] = 
          RegExp(r'[A-Z]').hasMatch(password);
      _passwordRules['password_rule_number'] = 
          RegExp(r'[0-9]').hasMatch(password);
      _passwordRules['password_rule_special'] = 
          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });
  }
  
  // Check if all password rules are satisfied
  bool get _isPasswordValid => _passwordRules.values.every((rule) => rule);
  
  // Handle password change submission using AuthService
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Show loading state
    setState(() => _isLoading = true);
    
    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      
      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();
      
        // Show success message
        InfoCard.showInfoCard(
          context,
          tr('password_change_success'),
          Colors.green,
          icon: Icons.check_circle,
          duration: const Duration(seconds: 3),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle auth exceptions with appropriate error messages
      String errorMessage;
      
      switch (e.code) {
        case 'wrong-password':
          errorMessage = tr('password_change_error_wrong_password');
          break;
        case 'user-not-found':
          errorMessage = tr('user_not_found');
          break;
        case 'requires-recent-login':
          errorMessage = tr('password_change_error_relogin');
          break;
        case 'weak-password':
          errorMessage = tr('password_validation_rules');
          break;
        case 'network-request-failed':
          errorMessage = tr('password_change_error_network');
          break;
        default:
          errorMessage = e.message ?? tr('password_change_error_default');
      }
      
      InfoCard.showInfoCard(
        context,
        errorMessage,
        Colors.red,
        icon: Icons.error,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      // Handle other errors
      InfoCard.showInfoCard(
        context,
        tr('password_change_error_default'),
        Colors.red,
        icon: Icons.error,
        duration: const Duration(seconds: 4),
      );
    } finally {
      // Reset loading state if dialog is still showing
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on a mobile device or small screen
        final isMobile = constraints.maxWidth < 600;
        final isSmallHeight = constraints.maxHeight < 500;
        
        // Adjust padding based on screen size
        final dialogPadding = isMobile 
            ? const EdgeInsets.all(16.0)
            : const EdgeInsets.all(24.0);
            
        // Adjust font sizes based on screen width
        final titleSize = isMobile ? 18.0 : 22.0;
        final subtitleSize = isMobile ? 12.0 : 14.0;
        final bodyTextSize = isMobile ? 13.0 : 14.0;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: dialogPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Responsive header with title and close button
                _buildResponsiveHeader(context, isMobile, titleSize, subtitleSize),
                
                const Divider(height: 30),
                
                // Form and password rules - responsive layout
                Expanded(
                  child: isMobile
                      // Mobile layout - stack vertically
                      ? _buildMobileLayout(bodyTextSize, isSmallHeight)
                      // Desktop layout - side by side
                      : _buildDesktopLayout(bodyTextSize),
                ),
                
                // Action buttons
                const SizedBox(height: 10),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 20, 
                            vertical: isMobile ? 8 : 12
                          ),
                        ),
                        child: Text(tr('password_change_cancel')),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 20, 
                            vertical: isMobile ? 8 : 12
                          ),
                          disabledBackgroundColor: Colors.amber.withOpacity(0.5),
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
                            : Text(tr('password_change_submit')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildResponsiveHeader(BuildContext context, bool isMobile, double titleSize, double subtitleSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon - responsive size
        Container(
          width: isMobile ? 40 : 50,
          height: isMobile ? 40 : 50,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.lock,
              size: isMobile ? 20 : 24,
              color: Colors.amber,
            ),
          ),
        ),
        SizedBox(width: isMobile ? 12 : 20),
        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('password_change_title'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleSize,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                tr('password_change_subtitle'),
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Close button
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.close, size: isMobile ? 20 : 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: Colors.grey[600],
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout(double textSize, bool isSmallHeight) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form first
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: tr('password_current'),
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  toggleObscure: () {
                    setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                  },
                  icon: Icons.lock_outline,
                  isMobile: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('password_validation_current_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  label: tr('password_new'),
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  toggleObscure: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                  icon: Icons.lock,
                  isMobile: true,
                  onChanged: _validatePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('password_validation_new_required');
                    }
                    if (!_isPasswordValid) {
                      return tr('password_validation_rules');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  label: tr('password_confirm'),
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  toggleObscure: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  icon: Icons.lock_reset,
                  isMobile: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return tr('password_validation_confirm_required');
                    }
                    if (value != _newPasswordController.text) {
                      return tr('password_validation_match');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Then password rules
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('password_rules_title'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: textSize + 2,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Responsive layout for rules - grid for landscape, column for portrait
                isSmallHeight 
                    ? _buildPasswordRulesGrid(textSize)
                    : _buildPasswordRulesList(textSize),
                
                const SizedBox(height: 12),
                
                // Info tip
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                        size: textSize + 2,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('password_rules_tip'),
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: textSize - 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDesktopLayout(double textSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form fields - left side
        Expanded(
          flex: 3,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: tr('password_current'),
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    toggleObscure: () {
                      setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                    },
                    icon: Icons.lock_outline,
                    isMobile: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr('password_validation_current_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    label: tr('password_new'),
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    toggleObscure: () {
                      setState(() => _obscureNewPassword = !_obscureNewPassword);
                    },
                    icon: Icons.lock,
                    isMobile: false,
                    onChanged: _validatePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr('password_validation_new_required');
                      }
                      if (!_isPasswordValid) {
                        return tr('password_validation_rules');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    label: tr('password_confirm'),
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    toggleObscure: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                    icon: Icons.lock_reset,
                    isMobile: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr('password_validation_confirm_required');
                      }
                      if (value != _newPasswordController.text) {
                        return tr('password_validation_match');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Password rules - right side
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('password_rules_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Rules list
                ..._passwordRules.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          entry.value ? Icons.check_circle : Icons.cancel,
                          color: entry.value ? Colors.green : Colors.red[300],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr(entry.key),
                            style: TextStyle(
                              color: entry.value ? Colors.green : Colors.red[300],
                              fontSize: textSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const Spacer(),
                
                // Info tip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('password_rules_tip'),
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: textSize - 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Create a 2x2 grid for password rules (for landscape mode on mobile)
  Widget _buildPasswordRulesGrid(double textSize) {
    final entries = _passwordRules.entries.toList();
    
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        return SizedBox(
          width: 150,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry.value ? Icons.check_circle : Icons.cancel,
                color: entry.value ? Colors.green : Colors.red[300],
                size: textSize + 2,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tr(entry.key),
                  style: TextStyle(
                    color: entry.value ? Colors.green : Colors.red[300],
                    fontSize: textSize - 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
  
  // Create a vertical list for password rules
  Widget _buildPasswordRulesList(double textSize) {
    return Column(
      children: _passwordRules.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                entry.value ? Icons.check_circle : Icons.cancel,
                color: entry.value ? Colors.green : Colors.red[300],
                size: textSize + 2,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(entry.key),
                  style: TextStyle(
                    color: entry.value ? Colors.green : Colors.red[300],
                    fontSize: textSize,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required Function() toggleObscure,
    required IconData icon,
    required bool isMobile,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    // Adjust UI for mobile
    final fontSize = isMobile ? 13.0 : 14.0;
    final verticalPadding = isMobile ? 12.0 : 15.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          style: TextStyle(fontSize: fontSize),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.amber, size: isMobile ? 18 : 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[600],
                size: isMobile ? 18 : 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: toggleObscure,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.amber, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 15, 
              vertical: verticalPadding
            ),
            // Make error text smaller on mobile
            errorStyle: TextStyle(fontSize: isMobile ? 10 : 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
