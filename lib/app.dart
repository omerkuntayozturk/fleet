import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'views/login/membership_details_screen.dart';
// Global navigator key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Flag to track if we're already on the membership details screen
bool _isOnMembershipDetailsScreen = false;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<DocumentSnapshot>? _membershipSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Cancel previous subscription if exists
        _membershipSubscription?.cancel();
        
        // Set up new subscription for current user
        _membershipSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen(_handleMembershipStatusChange);
            
        debugPrint('Set up membership listener for user: ${user.uid}');
      } else {
        // User logged out, reset flag
        _isOnMembershipDetailsScreen = false;
      }
    });
  }

  void _handleMembershipStatusChange(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    
    final userData = snapshot.data() as Map<String, dynamic>?;
    if (userData == null) return;
    
    final membershipStatus = userData['membershipStatus'] as String?;
    final membershipPlan = userData['membershipPlan'] as String?;
    
    debugPrint('⚡ REAL-TIME: Membership status change detected!');
    debugPrint('Current membership status: $membershipStatus, Plan: $membershipPlan');
    
    // If membership is now premium, reset the flag and don't redirect
    if (membershipStatus == 'premium') {
      debugPrint('✅ User has premium membership - normal app flow allowed');
      
      // Immediately reset flag to allow normal navigation
      _isOnMembershipDetailsScreen = false;
      
      // Check if we need to navigate to dashboard (if not already there)
      if (navigatorKey.currentContext != null && navigatorKey.currentState != null) {
        final currentRoute = ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
        
        // If user is on membership details or subscription screen, immediately go to dashboard
        if (currentRoute == AppRoutes.membershipDetails || 
            currentRoute == AppRoutes.subscription) {
          debugPrint('🚀 INSTANT redirect to dashboard from restricted screen');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              AppRoutes.dashboard,
              (route) => false,
            );
          });
        }
      }
      return;
    }
    
    // Handle free membership case - redirect to membership details if not already there
    if (membershipStatus == 'free' && !_isOnMembershipDetailsScreen) {
      debugPrint('FREE MEMBERSHIP DETECTED - Attempting to navigate to details screen');
      
      // Use the global navigator key to navigate
      if (navigatorKey.currentContext != null && navigatorKey.currentState != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentRoute = ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
          debugPrint('Current route: $currentRoute');
          
          if (currentRoute != AppRoutes.membershipDetails) {
            debugPrint('Navigating to membership details screen');
            _isOnMembershipDetailsScreen = true; // Set flag to prevent loops
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              AppRoutes.membershipDetails,
              (route) => false,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _membershipSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GOYA HR',
      navigatorKey: navigatorKey, // Use the global navigator key
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      navigatorObservers: [
        _MembershipStatusObserver(),
      ],
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

// Custom navigator observer to track route changes and update our flag
class _MembershipStatusObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    debugPrint('📍 Navigation detected to: ${route.settings.name}');
    
    // Update flag based on current route
    if (route.settings.name == AppRoutes.membershipDetails) {
      _isOnMembershipDetailsScreen = true;
      debugPrint('🔒 Setting membership details flag to TRUE');
    } else if (route.settings.name == AppRoutes.dashboard) {
      // Reset flag when navigating to dashboard
      _isOnMembershipDetailsScreen = false;
      debugPrint('🔓 Setting membership details flag to FALSE');
    }
    
    // Skip membership check for these screens
    if (route.settings.name == AppRoutes.login || 
        route.settings.name == AppRoutes.register ||
        route.settings.name == AppRoutes.verification ||
        route.settings.name == AppRoutes.membershipDetails ||
        route.settings.name == AppRoutes.subscription) {
      return;
    }
    
    // Check membership status when navigating to other screens
    _checkMembershipStatus(navigator?.context);
  }
  
  Future<void> _checkMembershipStatus(BuildContext? context) async {
    if (context == null) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!userDoc.exists) return;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final membershipStatus = userData['membershipStatus'] as String?;
      
      // Premium users can access all features
      if (membershipStatus == 'premium') {
        return;
      }
      
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
        
        if (!_isOnMembershipDetailsScreen) {
          // Redirect to membership details screen
          MembershipDetailsScreen.show(context, membershipStatus: 'free');
          _isOnMembershipDetailsScreen = true; // Set flag to prevent loops
        }
        return;
      }
      
      // Redirect if status is already free
      if (membershipStatus == 'free' && !_isOnMembershipDetailsScreen) {
        MembershipDetailsScreen.show(context, membershipStatus: 'free');
        _isOnMembershipDetailsScreen = true; // Set flag to prevent loops
      }
    } catch (e) {
      debugPrint('Error checking membership status: $e');
    }
  }
}