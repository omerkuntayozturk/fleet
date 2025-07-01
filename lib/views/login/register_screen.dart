import 'package:fleet/core/app_colors.dart';
import 'package:fleet/core/routes.dart';
import 'package:fleet/info_card.dart';
import 'package:fleet/views/settings/cookies.dart';
import 'package:fleet/views/settings/kvkkk.dart';
import 'package:fleet/views/settings/privacy_policy.dart';
import 'package:fleet/views/settings/user_manuel.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  // Controllers & FormKey
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;

  // State variables
  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isHovering = false;
  
  // Password validation rules
  Map<String, bool> _passwordRules = {
    tr('register_password_rule_min_length'): false,
    tr('register_password_rule_uppercase'): false,
    tr('register_password_rule_number'): false,
    tr('register_password_rule_special'): false,
  };

  // Add new state variables to track individual agreement acceptances
  bool _privacyPolicyAccepted = false;
  bool _kvkkAccepted = false;
  bool _userManualAccepted = false;
  bool _cookiesAccepted = false; // Add new state variable for cookies acceptance

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showInfoCard(BuildContext context, String message, Color color, IconData icon) {
    try {
      InfoCard.showInfoCard(context, message, color, icon: icon);
    } catch (e, stackTrace) {
      print('Error in _showInfoCard: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _sendVerificationCode() async {
    try {
      if (!_formKey.currentState!.validate() || !_termsAccepted) {
        if (!_termsAccepted) {
          _showInfoCard(
            context,
            tr("register_accept_terms_warning"),
            Colors.orange,
            Icons.warning,
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        final functions = FirebaseFunctions.instance;
        
        // Wrap the function call in a try-catch block
        HttpsCallableResult result;
        try {
          result = await functions
              .httpsCallable('sendVerificationEmail')
              .call({'email': _emailController.text.trim()});
        } catch (e) {
          print('Direct Firebase function error: $e');
          throw Exception('Connection error');
        }
        
        // Explicitly handle the result as a Map
        bool success = false;
        String message = tr("register_verification_code_send_error");
        
        if (result.data is Map) {
          final data = result.data as Map;
          success = data['success'] == true;
          message = data['message']?.toString() ?? message;
        }

        if (success) {
          // Print detailed debug information before navigating
          print("AGREEMENT_DEBUG: Preparing to send agreement data to verification screen");
          print("AGREEMENT_DEBUG: _termsAccepted = $_termsAccepted (${_termsAccepted.runtimeType})");
          print("AGREEMENT_DEBUG: _privacyPolicyAccepted = $_privacyPolicyAccepted (${_privacyPolicyAccepted.runtimeType})");
          print("AGREEMENT_DEBUG: _kvkkAccepted = $_kvkkAccepted (${_kvkkAccepted.runtimeType})");
          print("AGREEMENT_DEBUG: _userManualAccepted = $_userManualAccepted (${_userManualAccepted.runtimeType})");
          print("AGREEMENT_DEBUG: _cookiesAccepted = $_cookiesAccepted (${_cookiesAccepted.runtimeType})");
        
          // Create agreement data map and explicitly convert to proper booleans
          final Map<String, dynamic> agreementData = {
            'terms': _termsAccepted == true,
            'privacyPolicy': _privacyPolicyAccepted == true,
            'kvkk': _kvkkAccepted == true,
            'userManual': _userManualAccepted == true,
            'cookies': _cookiesAccepted == true, // Add cookies to agreement data
          };
        
          print("AGREEMENT_DEBUG: Final agreement map being sent: $agreementData");

          // Navigate to verification screen with agreement status
          if (mounted) {
            AppRoutes.navigateTo(
              context, 
              AppRoutes.verification,
              arguments: {
                'email': _emailController.text.trim(),
                'password': _passwordController.text.trim(),
                'agreementsAccepted': agreementData,
              },
            );
          }
        } else {
          _showInfoCard(
            context,
            message,
            Colors.red,
            Icons.error,
          );
        }
      } catch (e) {
        print('Error in Firebase function call: $e');
        String errorMessage = tr("register_verification_code_send_error");
        
        // Simple error classification based on error message
        if (e.toString().contains('network')) {
          errorMessage = tr("errors_network_error");
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = tr("errors_permission_denied");
        } else if (e.toString().contains('not-found')) {
          errorMessage = tr("errors_service_not_available");
        }
        
        _showInfoCard(
          context,
          errorMessage,
          Colors.red,
          Icons.error,
        );
      }
    } catch (e) {
      print('Outer error in sending verification code: $e');
      _showInfoCard(
        context,
        tr("register_verification_code_send_error"),
        Colors.red,
        Icons.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Start the agreement flow by showing the Privacy Policy dialog first
  void _startAgreementFlow() {
    _showPrivacyPolicyDialog();
  }

  // Show the Privacy Policy dialog
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Use limited height to ensure it fits on screen
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: const PrivacyPolicyPage(isDialog: true),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text(tr("common_cancel"), 
                          style: TextStyle(color: Colors.grey[700])),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(tr("common_accept")),
                        onPressed: () {
                          setState(() {
                            _privacyPolicyAccepted = true;  // Track acceptance
                          });
                          Navigator.of(context).pop();
                          // Continue to the next agreement
                          _showKVKKDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show the KVKK agreement dialog
  void _showKVKKDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Use limited height to ensure it fits on screen
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: const KVKKPage(isDialog: true),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text(tr("common_cancel"), 
                          style: TextStyle(color: Colors.grey[700])),
                        onPressed: () {
                          // If canceled, reset the privacy policy acceptance
                          setState(() {
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(tr("common_accept")),
                        onPressed: () {
                          setState(() {
                            _kvkkAccepted = true;  // Track acceptance
                          });
                          Navigator.of(context).pop();
                          // Continue to the cookies agreement
                          _showCookiesDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show the Cookies agreement dialog
  void _showCookiesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Use limited height to ensure it fits on screen
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: const CookiesPage(isDialog: true),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text(tr("common_cancel"), 
                          style: TextStyle(color: Colors.grey[700])),
                        onPressed: () {
                          // If canceled, reset the previous acceptances
                          setState(() {
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(tr("common_accept")),
                        onPressed: () {
                          setState(() {
                            _cookiesAccepted = true;  // Track acceptance
                          });
                          Navigator.of(context).pop();
                          // Continue to the final agreement
                          _showUserManualDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show the User Manual dialog
  void _showUserManualDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Use limited height to ensure it fits on screen
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: const UserAgreementPage(isDialog: true),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text(tr("common_cancel"), 
                          style: TextStyle(color: Colors.grey[700])),
                        onPressed: () {
                          // If canceled, reset the previous acceptances
                          setState(() {
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(tr("common_accept")),
                        onPressed: () {
                          setState(() {
                            // Set the main checkbox to true only when all agreements are accepted
                            _termsAccepted = true;
                            _userManualAccepted = true;  // Track acceptance
                            
                            // More detailed debug log
                            print("AGREEMENT_DEBUG: All agreements accepted in dialog");
                            print("AGREEMENT_DEBUG: _termsAccepted = $_termsAccepted (${_termsAccepted.runtimeType})");
                            print("AGREEMENT_DEBUG: _privacyPolicyAccepted = $_privacyPolicyAccepted (${_privacyPolicyAccepted.runtimeType})");
                            print("AGREEMENT_DEBUG: _kvkkAccepted = $_kvkkAccepted (${_kvkkAccepted.runtimeType})");
                            print("AGREEMENT_DEBUG: _cookiesAccepted = $_cookiesAccepted (${_cookiesAccepted.runtimeType})");
                            print("AGREEMENT_DEBUG: _userManualAccepted = $_userManualAccepted (${_userManualAccepted.runtimeType})");
                          });
                          Navigator.of(context).pop();
                          
                          // Show a confirmation message
                          _showInfoCard(
                            context, 
                            tr("register_agreements_accepted"),
                            Colors.green, 
                            Icons.check_circle
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 1000;
    final isSmallScreen = screenHeight < 700;
    final isMobileScreen = screenWidth < 800;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // Make the entire screen scrollable to prevent overflows
      body: Container(
        height: double.infinity,  // Ensure container takes full height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundColor,
              AppColors.backgroundColor.withBlue(
                  (AppColors.backgroundColor.blue + 15).clamp(0, 255)),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? screenWidth * 0.08 : 16,
              vertical: isSmallScreen ? 16 : 24
            ),
            child: isMobileScreen
                // For mobile screens, keep the stacked layout
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(context, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 40),
                      _buildRegisterCard(context, isSmallScreen),
                      // Add some bottom padding to avoid content being cut off
                      SizedBox(height: 20),
                    ],
                  )
                // For desktop/tablet screens, use a row layout with proper sizing
                : SizedBox(
                    // Use specific height instead of constraints
                    height: screenHeight - 100,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      elevation: 10,
                      shadowColor: Colors.black.withOpacity(0.05),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,  // Change to stretch to fill height
                          children: [
                            // Register card on the left side
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: _buildRegisterCard(context, isSmallScreen),
                              ),
                            ),
                            
                            // Divider with gradient
                            Container(
                              width: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.primaryColor.withOpacity(0.3),
                                    AppColors.primaryColor.withOpacity(0.5),
                                    AppColors.primaryColor.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            
                            // Welcome content on the right side with background
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      AppColors.primaryColor.withOpacity(0.03),
                                      Colors.white.withOpacity(0.01),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: SingleChildScrollView(
                                  child: _buildHeaderForSideBySide(context, isSmallScreen),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Header for mobile layout
  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          )),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow effect
              Container(
                width: isSmallScreen ? 150 : 200,
                height: isSmallScreen ? 150 : 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Lottie animation
              Lottie.asset('assets/animations/register.json',
                  height: isSmallScreen ? 120 : 180),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
        
        // Password rules section (replacing welcome text with gradient)
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withBlue(
                  (AppColors.primaryColor.blue + 40).clamp(0, 255)),
            ],
          ).createShader(bounds),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
              ),
            ),
            child: Text(
                tr("register_password_rules_title"),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // This will be overridden by the gradient
                    fontSize: isSmallScreen ? 22 : null,
                  ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Password rules container (replacing manage_pet_description)
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _passwordRules.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 6),
                  child: Row(
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.cancel,
                        color: entry.value ? Colors.green : Colors.red[300],
                        size: isSmallScreen ? 16 : 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key, // Use the direct string instead of translation
                          style: TextStyle(
                            color: entry.value ? Colors.green : Colors.red[300],
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: entry.value ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Header for side-by-side layout
  Widget _buildHeaderForSideBySide(BuildContext context, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
              )),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background glow effect
                  Container(
                    width: isSmallScreen ? 250 : 300,
                    height: isSmallScreen ? 250 : 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Secondary glow effect
                  Container(
                    width: isSmallScreen ? 200 : 250,
                    height: isSmallScreen ? 200 : 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Lottie animation
                  Lottie.asset('assets/animations/register.json',
                          height: isSmallScreen ? 220 : 280),
                ],
             ),
             ), 
            ), 

          SizedBox(height: isSmallScreen ? 20 : 30),
          
          // Password rules title (replacing welcome text with gradient effect)
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withBlue(
                    (AppColors.primaryColor.blue + 40).clamp(0, 255)),
              ],
            ).createShader(bounds),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                ),
              ),
              child: Text(
                tr("register_password_rules_title"),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // This will be overridden by the gradient
                      fontSize: isSmallScreen ? 24 : 32,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Password rules container (replacing animated prompt text with container)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _passwordRules.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                    child: Row(
                      children: [
                        Icon(
                          entry.value ? Icons.check_circle : Icons.cancel,
                          color: entry.value ? Colors.green : Colors.red[300],
                          size: isSmallScreen ? 18 : 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: entry.value ? Colors.green : Colors.red[300],
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: entry.value ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard(BuildContext context, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileScreen = screenWidth < 800;
    
    // Adjust card width based on layout
    final cardWidth = isMobileScreen 
        ? (screenWidth > 600 ? 450.0 : screenWidth - 32)
        : double.infinity;
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
        ),
      ),
      // Replace MouseRegion with StatefulBuilder for hover effects
      child: StatefulBuilder(
        builder: (context, setState) {
          return GestureDetector(
            onTapDown: (_) => setState(() => _isHovering = true),
            onTapUp: (_) => setState(() => _isHovering = false),
            onTapCancel: () => setState(() => _isHovering = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: cardWidth,
              // Remove fixed constraints to allow content to determine size
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(_isHovering ? 0.25 : 0.15),
                    blurRadius: _isHovering ? 20 : 15,
                    offset: Offset(0, _isHovering ? 8 : 5),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 5,
                    offset: const Offset(-5, -5),
                    spreadRadius: -1,
                  ),
                ],
                border: Border.all(
                  color: _isHovering 
                    ? AppColors.primaryColor.withOpacity(0.3) 
                    : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.3, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                )),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  // Wrap content in SingleChildScrollView to handle potential overflow
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Modern title with icon
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryColor,
                                    AppColors.primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: isSmallScreen ? 18 : 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('register_create_account'),
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 16 : 20,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 2,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryColor,
                                          AppColors.primaryColor.withOpacity(0.4),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        _buildRegisterForm(isSmallScreen),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildRegisterForm(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email field
          Text(
            tr('register_email_label'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          TextFormField(
            controller: _emailController,
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            decoration: InputDecoration(
              hintText: tr('register_email_label'),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: isSmallScreen 
                  ? const EdgeInsets.symmetric(vertical: 10, horizontal: 12)
                  : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.email, color: AppColors.primaryColor, size: 18),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.5,
                ),
              ),
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: isSmallScreen ? 12 : 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr("validator_email_required");
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) {
                return tr("validator_email_invalid");
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Password field
          Text(
            tr('register_password_label'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            onChanged: (value) {
              setState(() {
                _passwordRules[tr('register_password_rule_min_length')] = value.length >= 8;
                _passwordRules[tr('register_password_rule_uppercase')] = RegExp(r'[A-Z]').hasMatch(value);
                _passwordRules[tr('register_password_rule_number')] = RegExp(r'[0-9]').hasMatch(value);
                _passwordRules[tr('register_password_rule_special')] = 
                  RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
              });
            },
            decoration: InputDecoration(
              hintText: tr('register_password_label'),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: isSmallScreen 
                  ? const EdgeInsets.symmetric(vertical: 10, horizontal: 12)
                  : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.lock, color: AppColors.primaryColor, size: 18),
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.5,
                ),
              ),
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: isSmallScreen ? 12 : 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr("validator_password_required");
              }
              if (!_passwordRules.values.every((rule) => rule)) {
                return tr("register_password_rules_not_met");
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Confirm Password field
          Text(
            tr('register_confirm_password_label'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            decoration: InputDecoration(
              hintText: tr('register_confirm_password_label'),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: isSmallScreen 
                  ? const EdgeInsets.symmetric(vertical: 10, horizontal: 12)
                  : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.lock_outline, color: AppColors.primaryColor, size: 18),
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.5,
                ),
              ),
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: isSmallScreen ? 12 : 14),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return tr("register_password_mismatch");
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Terms and conditions - updated to handle the sequential agreement flow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
              border: Border.all(
                color: _termsAccepted ? AppColors.primaryColor.withOpacity(0.3) : Colors.grey[200]!,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: isSmallScreen ? 4 : 6,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: Transform.scale(
                    scale: 0.8,
                    child: Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        if (value == true) {
                          // Start the sequential agreement flow
                          _startAgreementFlow();
                        } else {
                          setState(() {
                            _termsAccepted = false;
                          });
                        }
                      },
                      activeColor: AppColors.primaryColor,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _startAgreementFlow(),
                    child: Text(
                      tr("register_terms_accept_all"),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: isSmallScreen ? 11 : 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey[400],
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),

          // Register button with gradient
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 16
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey, Colors.grey.shade400]
                        : [
                            AppColors.primaryColor,
                            AppColors.primaryColor.withBlue(
                                (AppColors.primaryColor.blue + 40).clamp(0, 255)),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                            tr("register_send_verification_code"), // Use translation key for localization
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 14 : 18),

          // Sign‑up link with modern styling
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr("register_already_have_account"),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                  TextButton(
                    onPressed: () => AppRoutes.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 4 : 6,
                        vertical: 0,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      tr("register_sign_in"),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
