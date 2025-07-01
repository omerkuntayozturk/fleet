// lib/screens/login_screen.dart
import 'dart:async';
import 'package:fleet/core/app_colors.dart';
import 'package:fleet/core/routes.dart';
import 'package:fleet/services/firestore_service.dart';
import 'package:fleet/info_card.dart';
import 'package:fleet/views/login/membership_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/foundation.dart';
import 'package:fleet/services/user_permissions_service.dart';
import 'package:fleet/views/login/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // ───────────────────────── Controllers & FormKey ───────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;

  // ───────────────────────────── State Variables ─────────────────────────────
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isHovering = false;
  bool _isWeb = false;

  // ─────────────────────────────── Google SignIn ─────────────────────────────
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    // Web platformunu tespit et
    _isWeb = kIsWeb;
    
    // Google Sign-In konfigürasyonu - client ID sorununu çözmek için
    _googleSignIn = GoogleSignIn(
      clientId: _isWeb 
          ? '687311780277-rgfodjc33ungs8gq150ka2e31bb6nmaj.apps.googleusercontent.com' // Web client ID
          : null, // Mobil için clientId gerekmez
      scopes: ['email', 'profile'],
    );
    
    _loadRememberMe();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Check if we need to sign out (for example, if coming back from an error state)
    _checkAndSignOutIfNeeded();
  }
  
  // Add method to handle sign out if needed
  Future<void> _checkAndSignOutIfNeeded() async {
    try {
      // Check if the current user is in an invalid state
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // If we arrive at login screen with a user still signed in, sign them out
        // This helps prevent permission errors when logging back in
        await FirebaseAuth.instance.signOut();
        
        // Also clear SharedPreferences data to prevent user data leakage
        await UserPermissionsService.clearStoredPermissions();
        
        // Clear other potential cached data
        final prefs = await SharedPreferences.getInstance();
        // Keep rememberMe setting but clear user-specific data
        final rememberMe = prefs.getBool('rememberMe') ?? false;
        final email = rememberMe ? prefs.getString('email') : null;
        final password = rememberMe ? prefs.getString('password') : null;
        
        // Selectively clear SharedPreferences
        final keysToKeep = <String>[];
        if (rememberMe) {
          keysToKeep.add('rememberMe');
          if (email != null) keysToKeep.add('email');
          if (password != null) keysToKeep.add('password');
        }
        
        // Get all keys and remove those that aren't in keysToKeep
        final allKeys = prefs.getKeys();
        for (final key in allKeys) {
          if (!keysToKeep.contains(key)) {
            await prefs.remove(key);
          }
        }
        
        debugPrint('User was automatically signed out to prevent permission issues');
      }
    } catch (e) {
      debugPrint('Error in _checkAndSignOutIfNeeded: $e');
      // No need to show an error to the user here
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ───────────────────────────── Remember‑Me Logic ───────────────────────────
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
    } else {
      await prefs.setBool('rememberMe', false);
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  // ───────────────────────────── Genel Auth Fonksiyonları ────────────────────
  String _getAuthErrorMessage(String code) {
    final key = 'auth_$code';
    final trn = tr(key);
    return trn == key ? tr('auth_login_failed') : trn;
  }

  // Add this helper method to check if user is a deactivated sub-user
  Future<bool> _isDeactivatedSubUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      final status = userData['status'] as bool? ?? true; // Default to true if not found
      
      // Return true if this is a sub-user with status set to false
      return isSubUser && !status;
    } catch (e) {
      debugPrint('Error checking user status: $e');
      return false;
    }
  }

  // Add the missing _checkParentUserMembership method
  Future<bool> _checkParentUserMembership(String parentUserId) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      bool forceRefresh = false;
      
      // First, check cached data in the sub-user document
      DocumentSnapshot subUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (subUserDoc.exists) {
        Map<String, dynamic> subUserData = subUserDoc.data() as Map<String, dynamic>;
        
        // Check if we have cached parent membership data
        String? cachedParentMembershipStatus = subUserData['parentMembershipStatus'];
        Timestamp? cachedTimestamp = subUserData['parentMembershipCachedAt'];
        
        // If we have relatively recent cached data (within 1 hour), use it
        if (cachedParentMembershipStatus != null && 
            cachedTimestamp != null &&
            DateTime.now().difference(cachedTimestamp.toDate()).inHours < 1) {
          
          debugPrint('Using cached parent membership status: $cachedParentMembershipStatus');
          return cachedParentMembershipStatus == 'premium' || 
                 cachedParentMembershipStatus == 'starter';
        } else {
          // Cache is too old or doesn't exist, force a refresh
          forceRefresh = true;
        }
      }
      
      if (forceRefresh) {
        debugPrint('Cached parent membership status is outdated, fetching fresh data...');
        // Try to directly query parent document - this requires special Firebase rules
        try {
          DocumentSnapshot parentUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(parentUserId)
              .get();
          
          if (parentUserDoc.exists) {
            Map<String, dynamic> parentData = parentUserDoc.data() as Map<String, dynamic>;
            String membershipStatus = parentData['membershipStatus'] ?? 'free';
            
            // Update the cache
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({
                  'parentMembershipStatus': membershipStatus,
                  'parentMembershipCachedAt': FieldValue.serverTimestamp(),
                });
                
            debugPrint('Updated parent membership status to: $membershipStatus');
            return membershipStatus == 'premium' || membershipStatus == 'starter';
          }
        } catch (queryError) {
          // If direct query fails due to permission issues, let's try another approach
          debugPrint('Direct query to parent document failed: $queryError');
          
          // Use FirestoreService as fallback
          try {
            final firestoreService = FirestoreService();
            final refreshedStatus = await firestoreService.refreshParentMembershipStatus(currentUser.uid);
            
            if (refreshedStatus != null) {
              return refreshedStatus == 'premium' || refreshedStatus == 'starter';
            }
          } catch (serviceError) {
            debugPrint('Error using service to refresh: $serviceError');
          }
          
          // Default to true to allow access for now to prevent lockout
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
                'parentMembershipStatus': 'premium', // Optimistic assumption
                'parentMembershipCachedAt': FieldValue.serverTimestamp(),
                'needsMembershipStatusRefresh': true // Flag for backend to refresh
              });
              
          return true;
        }
      }
      
      // Default fallback - allow access
      return true;
    } catch (e) {
      debugPrint('Error checking parent user membership: $e');
      return true; // Default to allowing access on errors
    }
  }
  
  // Add the missing _determineRedirectPath method
  Future<String> _determineRedirectPath() async {
    // Check dashboard access first - if no access, try other pages
    final canAccessDashboard = await UserPermissionsService.canAccessDashboard();
    if (canAccessDashboard) {
      return AppRoutes.dashboard;
    }
    
    // If no dashboard access, check other permissions in priority order
    final canAccessDepartmentPosition = await UserPermissionsService.canAccessDepartmentPosition();
    if (canAccessDepartmentPosition) {
      return '/department-position'; // Path to department-position page
    }
    
    final canAccessList = await UserPermissionsService.canAccessList();
    if (canAccessList) {
      return '/list'; // Path to list page
    }
    
    final canAccessContracts = await UserPermissionsService.canAccessContracts();
    if (canAccessContracts) {
      return '/contracts'; // Path to contracts page
    }
    
    final canAccessOrgChart = await UserPermissionsService.canAccessOrgChart();
    if (canAccessOrgChart) {
      return '/orgchart'; // Path to orgchart page
    }
    
    final canAccessSkills = await UserPermissionsService.canAccessSkills();
    if (canAccessSkills) {
      return '/skills'; // Path to skills page
    }
    
    // If somehow no permissions are granted, default to settings page
    return '/settings';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Clear any existing user data first
      await _cleanupBeforeLogin();
      
      // Now proceed with login
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Get current user from the userCredential result
      final currentUser = userCredential.user;
      if (currentUser == null) {
        throw Exception('Login failed: No user after authentication');
      }
      
      // Force token refresh to ensure fresh permissions
      await currentUser.getIdToken(true);
      
      // Ensure we fetch fresh permissions for this user
      await UserPermissionsService.clearStoredPermissions();
      await UserPermissionsService.fetchAndStoreUserPermissions();
      
      // Check if user is a deactivated sub-user
      final isDeactivated = await _isDeactivatedSubUser();
      if (isDeactivated) {
        // Sign out the user immediately
        await FirebaseAuth.instance.signOut();
        throw Exception('account_deactivated');
      }

      // Verify that user data was loaded properly
      if (!await _verifyUserDataIntegrity()) {
        debugPrint('User data integrity check failed, retrying permission fetch');
        // Try one more time
        await UserPermissionsService.fetchAndStoreUserPermissions();
      }
      
      await _saveRememberMe();
      
      // Small delay to allow Firebase to fully initialize
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Check membership status before navigating
      if (mounted) {
        await _checkAndHandleMembershipStatus(forceRefresh: true);
      }
    } on FirebaseAuthException catch (e) {
      InfoCard.showInfoCard(
        context,
        _getAuthErrorMessage(e.code),
        Colors.red,
        icon: Icons.error,
      );
    } catch (e) {
      String errorMessage = tr('login_errors_unknown_error');
      if (e.toString().contains('account_deactivated')) {
        errorMessage = tr('login_errors_account_deactivated', 
          namedArgs: {'fallback': 'Your account has been deactivated by the admin.'});
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
  
  // New method to properly clean up before login
  Future<void> _cleanupBeforeLogin() async {
    try {
      // Check if there's already a user signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('Found existing user, cleaning up before new login');
        
        // Clear permissions from SharedPreferences
        await UserPermissionsService.clearStoredPermissions();
        
        // Clear other user-specific SharedPreferences data
        final prefs = await SharedPreferences.getInstance();
        // Keep rememberMe setting
        final rememberMe = prefs.getBool('rememberMe') ?? false;
        final email = rememberMe ? prefs.getString('email') : null;
        final password = rememberMe ? prefs.getString('password') : null;
        
        // Get all keys and selectively clear
        final keysToKeep = <String>[];
        if (rememberMe) {
          keysToKeep.add('rememberMe');
          if (email != null) keysToKeep.add('email');
          if (password != null) keysToKeep.add('password');
        }
        
        final allKeys = prefs.getKeys().toList();
        for (final key in allKeys) {
          if (!keysToKeep.contains(key)) {
            await prefs.remove(key);
          }
        }
        
        // Sign out current user
        await FirebaseAuth.instance.signOut();
        
        // Wait a moment to ensure clean state
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      debugPrint('Error in cleanup before login: $e');
      // Continue with login even if cleanup fails
    }
  }
  
  // New method to verify that user data was loaded properly
  Future<bool> _verifyUserDataIntegrity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      // Check if we have valid user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        debugPrint('User document not found after login');
        return false;
      }
      
      // For sub-users, check if we have parent membership status
      final userData = userDoc.data() as Map<String, dynamic>;
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      
      if (isSubUser) {
        // Verify we have parent user ID
        final parentUserId = userData['parentUserId'] as String?;
        if (parentUserId == null) {
          debugPrint('Sub-user missing parent user ID');
          return false;
        }
        
        // Check if we have permission data
        final prefs = await SharedPreferences.getInstance();
        final hasPermissionsData = prefs.containsKey('users_permission_dashboard') &&
                                  prefs.containsKey('users_permission_opportunities');
        
        if (!hasPermissionsData) {
          debugPrint('Sub-user permissions not properly loaded');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error verifying user data integrity: $e');
      return false;
    }
  }

  // Modify _handleGoogleUser to also use our new methods
  Future<void> _handleGoogleUser(GoogleSignInAccount account) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Ensure clean state before login
      await _cleanupBeforeLogin();

      // Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('No Firebase user');
      
      // Force token refresh for fresh permissions
      await user.getIdToken(true);

      // Check if user is a deactivated sub-user
      final isDeactivated = await _isDeactivatedSubUser();
      if (isDeactivated) {
        // Sign out the user immediately
        await FirebaseAuth.instance.signOut();
        throw Exception('account_deactivated');
      }

      // Firebase Authentication successful, now do Firestore operations
      await Future.delayed(const Duration(milliseconds: 500)); // Allow auth token to propagate
      
      try {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          // New user - 7 day trial period
          await userDoc.set({
            'email': user.email ?? '',
            'profileName': user.displayName ?? user.email ?? 'Google User',
            'membershipStatus': 'starter',
            'membershipStartDate': FieldValue.serverTimestamp(),
            'membershipEndDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
            'membershipPlan': 'starter',
            'registrationDate': FieldValue.serverTimestamp(),
            'dailyQuestionCount': 0,
            'lastQuestionDate': null,
            'tutorialMode': true,
          });
        }
      } catch (e) {
        debugPrint('Firestore error: $e');
        // Continue even if Firestore operation fails
      }

      if (!mounted) return;
      
      // Add permission fetching after successful authentication
      await UserPermissionsService.fetchAndStoreUserPermissions();
      
      // Verify data integrity and retry if needed
      if (!await _verifyUserDataIntegrity()) {
        debugPrint('User data integrity check failed after Google login, retrying');
        await UserPermissionsService.fetchAndStoreUserPermissions();
      }
      
      // Small delay to allow Firebase to fully initialize
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Check membership status before navigating
      await _checkAndHandleMembershipStatus(forceRefresh: true);
    } catch (error) {
      if (!mounted) return;
      
      String errorMessage;
      if (error.toString().contains('account_deactivated')) {
        errorMessage = tr('login_errors_account_deactivated', 
          namedArgs: {'fallback': 'Your account has been deactivated by the admin.'});
      } else if (error.toString().contains('permission-denied')) {
        errorMessage = tr('login_errors_permission_denied');
      } else {
        errorMessage = tr('login_errors_google_auth_failed');
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

  // Enhance _checkAndHandleMembershipStatus method for better reliability
  Future<void> _checkAndHandleMembershipStatus({bool forceRefresh = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // If force refresh, refetch the token to ensure fresh data
      if (forceRefresh) {
        try {
          await user.getIdToken(true);
          debugPrint('Successfully refreshed Firebase auth token');
        } catch (e) {
          debugPrint('Error refreshing token: $e');
        }
      }
      
      // Fetch and store user permissions
      if (forceRefresh) {
        await UserPermissionsService.clearStoredPermissions();
      }
      await UserPermissionsService.fetchAndStoreUserPermissions();
      
      // Fetch user document with retry mechanism
      DocumentSnapshot? userDoc;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
              
          if (userDoc.exists) break;
          
          // Wait briefly before retry
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('Error fetching user document (attempt ${attempt+1}): $e');
          // Wait longer before retry
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (userDoc == null || !userDoc.exists) {
        debugPrint('Unable to fetch user document after multiple attempts');
        if (mounted) {
          InfoCard.showInfoCard(
            context,
            tr('login_errors_user_data_not_found', 
              namedArgs: {'fallback': 'User data not found. Please try logging in again.'}),
            Colors.red,
            icon: Icons.error,
          );
        }
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      
      if (isSubUser) {
        // This is a sub-user, check if account is active
        final bool isActive = userData['status'] as bool? ?? true;
        if (!isActive) {
          if (mounted) {
            InfoCard.showInfoCard(
              context,
              tr('login_errors_account_deactivated', 
                namedArgs: {'fallback': 'Your account has been deactivated by the admin.'}),
              Colors.red,
              icon: Icons.error,
            );
          }
          await FirebaseAuth.instance.signOut();
          return;
        }
        
        // Check parent user ID
        final parentUserId = userData['parentUserId'] as String?;
        if (parentUserId == null) {
          debugPrint('Sub-user has no parent user ID');
          if (mounted) {
            InfoCard.showInfoCard(
              context,
              tr('login_errors_invalid_account', 
                namedArgs: {'fallback': 'Invalid account configuration'}),
              Colors.red,
              icon: Icons.error,
            );
          }
          await FirebaseAuth.instance.signOut();
          return;
        }
        
        // If forceRefresh is true, we'll forcibly update the status
        if (forceRefresh) {
          // This will create a new instance of FirestoreService
          final firestoreService = FirestoreService();
          String? refreshedStatus = await firestoreService.refreshParentMembershipStatus(user.uid);
          
          if (refreshedStatus != null) {
            debugPrint('Forcibly refreshed parent membership status: $refreshedStatus');
          }
        }
        
        // Now check parent premium membership
        bool parentHasPremium = await _checkParentUserMembership(parentUserId);
        
        if (!parentHasPremium) {
          // Parent has free membership, sub-user cannot log in
          if (mounted) {
            InfoCard.showInfoCard(
              context,
              tr('login_errors_parent_membership_required', 
                namedArgs: {'fallback': 'Parent account requires premium membership for sub-account access'}),
              Colors.amber,
              icon: Icons.warning,
            );
          }
          await FirebaseAuth.instance.signOut();
          return;
        }
        
        // Parent has premium, check sub-user permissions and redirect accordingly
        if (mounted) {
          // Determine the appropriate landing page based on permissions
          final String redirectPath = await _determineRedirectPath();
          debugPrint('Sub-user with valid parent membership. Redirecting to: $redirectPath');
          
          // Navigate to the determined path
          AppRoutes.navigateToAndRemoveUntil(context, redirectPath);
        }
      } else {
        // This is a regular user, check their own membership
        final membershipStatus = userData['membershipStatus'] as String?;
        final membershipEndDate = userData['membershipEndDate'] as Timestamp?;
        
        // Check if membership has expired
        final now = DateTime.now();
        if (membershipEndDate != null && now.isAfter(membershipEndDate.toDate())) {
          // Update status to free if expired
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'membershipStatus': 'free',
                'membershipPlan': 'free',
              });
              
          if (mounted) {
            // Navigate to membership details screen for expired users
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MembershipDetailsScreen()),
              (route) => false,
            );
            return;
          }
        }
        
        // If status is 'free', redirect to membership details
        if (membershipStatus == 'free' && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MembershipDetailsScreen()),
            (route) => false,
          );
          return;
        }
        
        // Premium or starter users go to dashboard
        if (mounted) {
          AppRoutes.navigateToAndRemoveUntil(context, AppRoutes.dashboard);
        }
      }
    } catch (e) {
      debugPrint('Error checking membership status: $e');
      // Default to dashboard on error
      if (mounted) {
        AppRoutes.navigateToAndRemoveUntil(context, AppRoutes.dashboard);
      }
    }
  }
  
  // ───────────────────── Google Sign‑In için modifiye edilmiş kod ──────────────────
  Future<void> _loginWithGoogleMobile() async {
    setState(() => _isLoading = true);
    try {
      // First make sure any existing user data is cleared
      await _checkAndSignOutIfNeeded();
      
      // Web platformunda hata vermeyecek şekilde ayarlandı
      final account = await _googleSignIn.signIn();
      if (account != null) await _handleGoogleUser(account);
    } catch (error) {
      debugPrint('Google sign in error: $error');
      InfoCard.showInfoCard(
        context,
        tr('login_errors_google_sign_in_failed'),
        Colors.red,
        icon: Icons.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // The _checkParentUserMembership method is already defined earlier in the file



  // ───────────────────────────── UI – Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 1000;
    final isSmallScreen = screenHeight < 700;
    final isMobileScreen = screenWidth < 800;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Container(
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
                      _buildLoginCard(context, isSmallScreen),
                    ],
                  )
                // For desktop/tablet screens, use a row layout
                : Container(
                    // Fix the infinite height constraint by using MinHeight instead of fixed constraints
                    height: screenHeight - 100,
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Login card on the left side
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: _buildLoginCard(context, isSmallScreen),
                            ),
                          ),
                          
                          // Divider with gradient
                          Container(
                            width: 1,
                            height: double.infinity,
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
                              child: _buildHeaderForSideBySide(context, isSmallScreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Original header for mobile layout
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
              Lottie.asset('assets/animations/login.json',
                  height: isSmallScreen ? 120 : 180),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
        
        // Welcome text with gradient
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
              tr('login_welcome_back'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // This will be overridden by the gradient
                    fontSize: isSmallScreen ? 22 : null,
                  ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              tr('login_sign_in_prompt'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                    fontSize: isSmallScreen ? 14 : null,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  // New header optimized for side-by-side layout with modern design
  Widget _buildHeaderForSideBySide(BuildContext context, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated staggered opacity for depth effect
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
                  Lottie.asset('assets/animations/login.json',
                          height: isSmallScreen ? 220 : 280),
                ],
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 20 : 30),
          
          // Welcome text with gradient effect
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
                tr('login_welcome_back'),
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
          
          // Animated prompt text with container
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
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
              child: Text(
                tr('login_sign_in_prompt'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[800],
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileScreen = screenWidth < 800;
    
    // Adjust card width based on layout
    final cardWidth = isMobileScreen 
        ? (screenWidth > 600 ? 450.0 : screenWidth - 32)
        : double.infinity; // Take full width of the column in side-by-side layout
    
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
          width: cardWidth,
          // İçerik yüksekliğine sığdır
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: double.infinity,
          ),
          transform: _isHovering
              ? (Matrix4.identity()..translate(0, -5, 0))
              : Matrix4.identity(),
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
              // İçeriğin taşmaması için padding miktarını azaltıyoruz
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern title with icon - basitleştirilmiş
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
                          Icons.lock_open,
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
                              tr('login_account_access'),
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
                  const SizedBox(height: 16),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  _buildLoginForm(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Google Sign‑In button with improved design - basitleştirilmiş
                  Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _loginWithGoogleMobile,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10 : 14,
                            horizontal: isSmallScreen ? 16 : 20
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.asset('assets/animations/google.json', height: 24),
                              const SizedBox(width: 12),
                              Text(
                                tr('login_google_sign_in'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
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
        ),
      ),
    );
  }

  // ─────────────────────────── Login Form Widget ─────────────────────────────
  Widget _buildLoginForm([bool isSmallScreen = false]) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email - daha kompakt hale getir
          Text(
            tr('login_email_label'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          TextFormField(
            controller: _emailController,
            // Daha kompakt form alanları
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            decoration: InputDecoration(
              hintText: tr('login_email_hint'),
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
            validator: (v) {
              if (v == null || v.isEmpty) {
                return tr('validator_email_required');
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                return tr('validator_email_invalid');
              }
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Password
          Text(
            tr('login_password_label'),
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
            // Daha kompakt form alanları
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
            decoration: InputDecoration(
              hintText: tr('login_password_hint'),
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
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
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
            validator: (v) {
              if (v == null || v.isEmpty) return tr('validator_password_required');
              if (v.length < 6) return tr('validator_password_min_length');
              return null;
            },
          ),
          SizedBox(height: isSmallScreen ? 10 : 14),

          // Remember Me and Forgot Password with modern styling
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Transform.scale(
                      scale: 0.8,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        activeColor: AppColors.primaryColor,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr('login_remember_me'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 11 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Show forgot password dialog
                  showDialog(
                    context: context,
                    builder: (context) => const ForgotPasswordDialog(),
                    barrierDismissible: false,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: 0,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  tr('login_forgot_password'),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Login Button with gradient
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
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
                tr('login_login_button'),
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
      ),
    ),
   ),
   ), 
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
            tr('login_no_account'),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 12 : 13,
            ),
          ),
          TextButton(
            onPressed: () => AppRoutes.navigateTo(
              context,
              AppRoutes.register,
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 4 : 6,
                vertical: 0,
              ),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              tr('login_sign_up'),
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