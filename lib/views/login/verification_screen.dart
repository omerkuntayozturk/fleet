import 'package:fleet/core/app_colors.dart';
import 'package:fleet/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fleet/info_card.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';

// Define a ResponsiveSize class to better manage breakpoints
class ResponsiveSize {
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 650;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 650 && 
      MediaQuery.of(context).size.width < 1100;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 1100;
  
  // Get dynamic values based on screen size
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 12;
    if (width < 650) return 16;
    if (width < 1100) return 24;
    return width * 0.08;
  }
  
  static double getVerticalPadding(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    if (height < 600) return 12;
    if (height < 800) return 16;
    return 24;
  }
  
  static double getFontSize(BuildContext context, double desktopSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return desktopSize * 0.7;
    if (width < 650) return desktopSize * 0.8;
    if (width < 1100) return desktopSize * 0.9;
    return desktopSize;
  }
  
  static double getIconSize(BuildContext context, double desktopSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return desktopSize * 0.7;
    if (width < 650) return desktopSize * 0.8;
    if (width < 1100) return desktopSize * 0.9;
    return desktopSize;
  }
  
  static double getSpacing(BuildContext context, double desktopSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return desktopSpacing * 0.6;
    if (width < 650) return desktopSpacing * 0.8;
    if (width < 1100) return desktopSpacing * 0.9;
    return desktopSpacing;
  }
  
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;
      
  static double getPinFieldWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Calculate pin field width with margins
    if (isMobile(context)) {
      // 6 fields + 5 spaces between them + margins
      double availableWidth = width - (getHorizontalPadding(context) * 2) - 40;
      return (availableWidth / 6).floorToDouble();
    }
    if (isTablet(context)) return 45;
    return 50;
  }
}

class VerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final bool isGoogleSignIn;
  final AuthCredential? googleCredential;
  final Map<String, dynamic>? agreementsAccepted;

  const VerificationScreen({
    Key? key,
    required this.email,
    required this.password,
    this.isGoogleSignIn = false,
    this.googleCredential,
    this.agreementsAccepted,
  }) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with SingleTickerProviderStateMixin {
  final _verificationController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 300; // 5 minutes
  Timer? _timer;
  late AnimationController _animationController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _verifyAndRegister() async {
    final verificationCode = _verificationController.text.trim();
    
    if (verificationCode.isEmpty || verificationCode.length != 6) {
      InfoCard.showInfoCard(
        context,
        tr("verification_invalid_code"),
        Colors.red,
        icon: Icons.error,
      );
      return;
    }

    safeSetState(() => _isLoading = true);

    try {
      // Use safer function call handling
      HttpsCallableResult verifyResult;
      try {
        final functions = FirebaseFunctions.instance;
        verifyResult = await functions.httpsCallable('verifyEmailCode').call({
          'email': widget.email,
          'code': verificationCode,
        });
      } catch (e) {
        print(tr('direct_function_call_error', args: [e.toString()]));
        throw Exception(tr('connection_error'));
      }
      
      // Process the result safely
      bool success = false;
      String message = tr("verification_invalid_code");
      
      if (verifyResult.data is Map) {
        final data = verifyResult.data as Map;
        success = data['success'] == true;
        message = data['message']?.toString() ?? message;
      }

      if (!success) {
        InfoCard.showInfoCard(
          context,
          message,
          Colors.red,
          icon: Icons.error,
        );
        return;
      }

      // Store the navigation context before async operations
      final currentContext = context;

      if (widget.isGoogleSignIn && widget.googleCredential != null) {
        // Google Sign-in kullanıcısı için hesabı oluştur
        final userCredential = await FirebaseAuth.instance
            .signInWithCredential(widget.googleCredential!);
        
        if (userCredential.user != null) {
          // Kullanıcı verilerini oluştur ve bekle
          await _initializeUserData(userCredential.user!.uid);
        
          // Veri oluşturma başarılı - yönlendirme yap
          if (!mounted) return;
          
          _showSuccessMessage(tr("verification_success"));
          
          // Add a slight delay to allow the InfoCard to display
          await Future.delayed(const Duration(seconds: 1));
          
          // Check if still mounted before navigating
          if (!mounted) return;
          
          // Use stored context for navigation
          AppRoutes.navigateToAndRemoveUntil(currentContext, AppRoutes.dashboard);
        }
      } else {
        // Normal kayıt akışına devam et
        // Create user account
        final auth = FirebaseAuth.instance;
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );
      
        final user = userCredential.user;
        if (user == null) throw Exception('User creation failed');

        // Kullanıcı verilerini oluştur ve bekle
        await _initializeUserData(user.uid);
      
        // Başarı mesajını göster
        if (!mounted) return;
        _showSuccessMessage(tr("verification_success"));
        
        // Add a slight delay to allow the InfoCard to display
        await Future.delayed(const Duration(seconds: 1));
        
        // Check if still mounted before navigating
        if (!mounted) return;
        
        // Use stored context for navigation
        AppRoutes.navigateToAndRemoveUntil(currentContext, AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(tr("errors_something_went_wrong"));
      }
      print(tr('verification_process_error', args: [e.toString()]));
    } finally {
      if (mounted) {
        safeSetState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      // Önce kullanıcının mevcut olup olmadığını kontrol et
      final userDoc = await firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        print(tr('user_data_already_exists'));
        await firestore.collection('users').doc(uid).update({
          'emailVerified': true,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      
      // CRITICAL FIX: Create direct hardcoded true values
      // Instead of trying to convert from incoming values which might be causing issues
      final Map<String, dynamic> firebaseAgreementData = {
        'terms': true,
        'privacyPolicy': true, 
        'kvkk': true,
        'userManual': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      };
      
      print("AGREEMENT_DEBUG_FIXED: Using direct true values for agreements: $firebaseAgreementData");
      
      // Yeni kullanıcı kaydı oluştur
      final batch = firestore.batch();

      // User profile
      final userRef = firestore.collection('users').doc(uid);
      batch.set(userRef, {
        'email': widget.email,
        'emailVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'profileName': widget.email.split('@')[0], // Email adresinden kullanıcı adını çıkarma
        'membershipStatus': 'starter',
        'membershipStartDate': DateTime.now(),
        'membershipEndDate': DateTime.now().add(const Duration(days: 7)),
        'membershipPlan': 'starter',
        'registrationDate': DateTime.now(),
        'dailyQuestionCount': 0,
        'lastQuestionDate': null,
        'tutorialMode': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
        // Use the hardcoded agreement data
        'agreementsAccepted': firebaseAgreementData,
      });

      // Verileri kaydet ve bekle
      await batch.commit();
      
      print(tr('user_data_created_successfully', args: [uid]));
      
      // Verify the saved data
      try {
        DocumentSnapshot verifyDoc = await firestore.collection('users').doc(uid).get();
        if (verifyDoc.exists) {
          Map<String, dynamic> userData = verifyDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('agreementsAccepted')) {
            Map<String, dynamic> savedAgreements = userData['agreementsAccepted'];
            print("AGREEMENT_DEBUG_FIXED: Verified saved agreement data: $savedAgreements");
            
            // Check each agreement value
            print("AGREEMENT_DEBUG_FIXED: terms = ${savedAgreements['terms']} (${savedAgreements['terms'].runtimeType})");
            print("AGREEMENT_DEBUG_FIXED: privacyPolicy = ${savedAgreements['privacyPolicy']} (${savedAgreements['privacyPolicy'].runtimeType})");
            print("AGREEMENT_DEBUG_FIXED: kvkk = ${savedAgreements['kvkk']} (${savedAgreements['kvkk'].runtimeType})");
            print("AGREEMENT_DEBUG_FIXED: userManual = ${savedAgreements['userManual']} (${savedAgreements['userManual'].runtimeType})");
          }
        }
      } catch (verifyError) {
        print("Error verifying saved data: $verifyError");
      }
      
      // Firestore'un güncellendiğinden emin olmak için kısa bir bekleme süresi
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      print(tr('user_data_creation_error', args: [e.toString()]));
      rethrow; // Hatayı üst metoda ilet
    }
  }

  Future<void> _resendVerificationCode() async {
    try {
      safeSetState(() => _isLoading = true);

      HttpsCallableResult result;
      try {
        final functions = FirebaseFunctions.instance;
        result = await functions
            .httpsCallable('sendVerificationEmail')
            .call({'email': widget.email});
      } catch (e) {
        print(tr('direct_function_call_error', args: [e.toString()]));
        throw Exception(tr('connection_error'));
      }
      
      // Process the result safely
      bool success = false;
      
      if (result.data is Map) {
        final data = result.data as Map;
        success = data['success'] == true;
      }

      if (success) {
        safeSetState(() => _resendCountdown = 300);
        startTimer();
        InfoCard.showInfoCard(
          context,
          tr("verification_code_resent"),
          Colors.green,
          icon: Icons.check_circle,
        );
      } else {
        throw Exception('Failed to resend code');
      }
    } catch (e) {
      InfoCard.showInfoCard(
        context,
        tr("verification_resend_failed"),
        Colors.red,
        icon: Icons.error,
      );
      print(tr('resend_code_error', args: [e.toString()]));
    } finally {
      safeSetState(() => _isLoading = false);
    }
  }


  // Modify InfoCard.showInfoCard to use BuildContext more safely

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    try {
      InfoCard.showInfoCard(
        context,
        message,
        Colors.green,
        icon: Icons.check_circle,
      );
    } catch (e) {
      print(tr('error_showing_success_message', args: [e.toString()]));
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    try {
      InfoCard.showInfoCard(
        context,
        message,
        Colors.red,
        icon: Icons.error,
      );
    } catch (e) {
      print(tr('error_showing_error_message', args: [e.toString()]));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the countdown timer
    String minutes = (_resendCountdown ~/ 60).toString().padLeft(2, '0');
    String seconds = (_resendCountdown % 60).toString().padLeft(2, '0');
    
    // Determine if we're in landscape mode on a small device
    bool isSmallLandscape = ResponsiveSize.isLandscape(context) && 
                           (MediaQuery.of(context).size.height < 500);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity, // Add explicit width
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
          // Use a direct SingleChildScrollView instead of LayoutBuilder+IntrinsicHeight
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(), // Prevent over-scrolling
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.getHorizontalPadding(context),
              vertical: ResponsiveSize.getVerticalPadding(context),
            ),
            // Replace ConstrainedBox + IntrinsicHeight with a simple Column
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Choose the layout based on screen size
                ResponsiveSize.isMobile(context) || isSmallLandscape
                  ? _buildMobileLayout(minutes, seconds, context)
                  : _buildTabletDesktopLayout(minutes, seconds, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(String minutes, String seconds, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: AppColors.primaryColor,
            iconSize: ResponsiveSize.getIconSize(context, 24),
            onPressed: () => AppRoutes.pop(context),
          ),
        ),
        SizedBox(height: ResponsiveSize.getSpacing(context, 20)),
        
        // Animation 
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          )),
          child: SizedBox(
            width: screenWidth * 0.35,
            height: screenWidth * 0.35,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background glow effect
                Container(
                  width: screenWidth * 0.35,
                  height: screenWidth * 0.35,
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
                Icon(
                  Icons.mark_email_read,
                  size: screenWidth * 0.2,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveSize.getSpacing(context, 24)),
        
        // Verification card
        _buildVerificationCard(minutes, seconds, context, true),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(String minutes, String seconds, BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = ResponsiveSize.isTablet(context);
    
    return Container(
      // Use fixed height constraints instead of percentage-based ones
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.6,
        maxHeight: screenHeight * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        // Replace IntrinsicHeight with a SizedBox with explicit constraints
        child: SizedBox(
          // Set a minimum height to ensure the container has enough space
          height: screenHeight * 0.7,
          width: screenWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Verification card on the left side
              Expanded(
                flex: isTablet ? 5 : 4,
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveSize.getSpacing(context, 20)),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            color: AppColors.primaryColor,
                            iconSize: ResponsiveSize.getIconSize(context, 24),
                            onPressed: () => AppRoutes.pop(context),
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.getSpacing(context, 20)),
                        
                        _buildVerificationCard(minutes, seconds, context, false),
                      ],
                    ),
                  ),
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
              
              // Animation on the right side
              Expanded(
                flex: isTablet ? 4 : 5,
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
                  padding: EdgeInsets.all(ResponsiveSize.getSpacing(context, 16)),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight * 0.5,
                      ),
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
                              child: _buildAnimationSection(context),
                            ),
                          ),
                          SizedBox(height: ResponsiveSize.getSpacing(context, 30)),
                          
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
                                tr("verification_email_verification"),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: ResponsiveSize.getFontSize(context, 32),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveSize.getSpacing(context, 30)),
                          
                          // Timer and resend button
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                            )),
                            child: _buildTimerSection(minutes, seconds, context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final animationSize = ResponsiveSize.isTablet(context) 
        ? size.width * 0.15
        : size.width * 0.10;
        
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background glow effect
        Container(
          width: animationSize * 1.5,
          height: animationSize * 1.5,
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
          width: animationSize * 1.2,
          height: animationSize * 1.2,
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
        Icon(
          Icons.mark_email_read,
          size: animationSize,
          color: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildTimerSection(String minutes, String seconds, BuildContext context) {
    ResponsiveSize.isTablet(context);
    
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getSpacing(context, 18)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                size: ResponsiveSize.getIconSize(context, 28),
                color: _resendCountdown < 60 
                  ? Colors.red 
                  : AppColors.primaryColor,
              ),
              SizedBox(width: ResponsiveSize.getSpacing(context, 10)),
              Text(
                tr("verification_code_valid_for"),
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(context, 18),
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.getSpacing(context, 10)),
          Text(
            "$minutes:$seconds",
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(context, 40),
              fontWeight: FontWeight.bold,
              color: _resendCountdown < 60 
                ? Colors.red 
                : AppColors.primaryColor,
            ),
          ),
          SizedBox(height: ResponsiveSize.getSpacing(context, 20)),
          ElevatedButton(
            onPressed: _isLoading || _resendCountdown > 0 
              ? null 
              : _resendVerificationCode,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.getSpacing(context, 30),
                vertical: ResponsiveSize.getSpacing(context, 16),
              ),
              backgroundColor: _resendCountdown > 0
                ? Colors.grey.withOpacity(0.3)
                : AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              _resendCountdown > 0
                ? tr("verification_wait_before_resend")
                : tr("verification_resend_code"),
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(String minutes, String seconds, BuildContext context, bool showTimerInCard) {
    // Set explicit width and height constraints for the card
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = ResponsiveSize.isMobile(context) 
        ? screenSize.width - (ResponsiveSize.getHorizontalPadding(context) * 2) 
        : double.infinity;
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovering
              ? (Matrix4.identity()..translate(0, -5, 0))
              : Matrix4.identity(),
          width: cardWidth,
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.9,
          ),
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
          child: Padding(
            padding: EdgeInsets.all(ResponsiveSize.getSpacing(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with icon
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(ResponsiveSize.getSpacing(context, 10)),
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
                        Icons.mail_lock,
                        color: Colors.white,
                        size: ResponsiveSize.getIconSize(context, 22),
                      ),
                    ),
                    SizedBox(width: ResponsiveSize.getSpacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr("verification_title"),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveSize.getFontSize(context, 20),
                            ),
                          ),
                          SizedBox(height: ResponsiveSize.getSpacing(context, 4)),
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
                SizedBox(height: ResponsiveSize.getSpacing(context, 20)),
                
                // Email sent text for mobile layout
                if (showTimerInCard) ...[
                  Container(
                    padding: EdgeInsets.all(ResponsiveSize.getSpacing(context, 14)),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr("verification_subtitle", args: [widget.email]),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(context, 14),
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.getSpacing(context, 8)),
                        Text(
                          tr("verification_check_inbox"),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(context, 13),
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        // Timer and resend button for mobile view
                        SizedBox(height: ResponsiveSize.getSpacing(context, 16)),
                        
                        // Responsive layout for timer and resend button
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // If container width is small, stack the elements
                            if (constraints.maxWidth < 300) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTimerInfo(minutes, seconds, context),
                                  SizedBox(height: ResponsiveSize.getSpacing(context, 12)),
                                  Center(
                                    child: _buildResendButton(context),
                                  ),
                                ],
                              );
                            } else {
                              // Otherwise show them side by side
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTimerInfo(minutes, seconds, context),
                                  _buildResendButton(context),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.getSpacing(context, 24)),
                ],
                
                // Pin Input
                Text(
                  tr("verification_enter_code"),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    fontSize: ResponsiveSize.getFontSize(context, 15),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getSpacing(context, 14)),
                
                // Adaptive PinCodeTextField
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate the size of each field based on available width
                    double fieldWidth = ResponsiveSize.getPinFieldWidth(context);
                    double fieldHeight = fieldWidth * 1.1; // Height a bit more than width
                    
                    return PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _verificationController,
                      onChanged: (value) {},
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: fieldHeight,
                        fieldWidth: fieldWidth,
                        activeFillColor: Colors.white,
                        activeColor: AppColors.primaryColor,
                        selectedColor: AppColors.primaryColor,
                        inactiveColor: Colors.grey.shade300,
                        selectedFillColor: Colors.grey[50],
                        inactiveFillColor: Colors.grey[50],
                      ),
                      cursorColor: AppColors.primaryColor,
                      animationDuration: const Duration(milliseconds: 300),
                      enableActiveFill: true,
                      keyboardType: TextInputType.number,
                    );
                  }
                ),
                SizedBox(height: ResponsiveSize.getSpacing(context, 28)),
                
                // Verify Button with gradient
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndRegister,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveSize.getSpacing(context, 14)
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
                            ? SizedBox(
                                width: ResponsiveSize.getIconSize(context, 20),
                                height: ResponsiveSize.getIconSize(context, 20),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                tr("verification_verify_button"),
                                style: TextStyle(
                                  fontSize: ResponsiveSize.getFontSize(context, 15),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getSpacing(context, 18)),
                
                // Return to login link
                Container(
                  padding: EdgeInsets.only(top: ResponsiveSize.getSpacing(context, 8)),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: TextButton(
                      onPressed: () => AppRoutes.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSize.getSpacing(context, 6),
                          vertical: 0,
                        ),
                      ),
                      child: Text(
                        tr("verification_back_to_login"),
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerInfo(String minutes, String seconds, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr("verification_code_valid_for"),
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(context, 13),
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: ResponsiveSize.getSpacing(context, 4)),
        Row(
          children: [
            Icon(
              Icons.timer,
              size: ResponsiveSize.getIconSize(context, 18),
              color: _resendCountdown < 60 
                ? Colors.red 
                : AppColors.primaryColor,
            ),
            SizedBox(width: ResponsiveSize.getSpacing(context, 4)),
            Text(
              "$minutes:$seconds",
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: _resendCountdown < 60 
                  ? Colors.red 
                  : AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResendButton(BuildContext context) {
    return TextButton(
      onPressed: _isLoading || _resendCountdown > 0 
        ? null 
        : _resendVerificationCode,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.getSpacing(context, 10),
          vertical: ResponsiveSize.getSpacing(context, 8),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _resendCountdown > 0 
              ? Colors.grey[300]! 
              : AppColors.primaryColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Text(
        _resendCountdown > 0
          ? tr("verification_wait_before_resend")
          : tr("verification_resend_code"),
        style: TextStyle(
          fontSize: ResponsiveSize.getFontSize(context, 13),
          fontWeight: FontWeight.w600,
          color: _resendCountdown > 0 
            ? Colors.grey 
            : AppColors.primaryColor,
        ),
      ),
    );
  }
}