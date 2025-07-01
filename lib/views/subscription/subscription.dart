import 'package:fleet/info_card.dart';
import 'package:fleet/views/subscription/premium_features.dart';
import 'package:fleet/views/subscription/availables_plans.dart';
import 'package:fleet/views/subscription/current_plan.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../../widgets/side_menu.dart';
import '../../widgets/top_bar.dart';

// Device breakpoints for responsive design
enum DeviceScreenType {
  mobile,
  tablet,
  desktop,
}

// Helper class for responsive layout - updated for full width support
class ResponsiveLayout {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  static const double desktopMaxWidth = 1200;
  
  static DeviceScreenType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return DeviceScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }
  
  static double getContentPadding(BuildContext context) {
    DeviceScreenType deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return 16.0;
      case DeviceScreenType.tablet:
        return 24.0;
      case DeviceScreenType.desktop:
        return 32.0;
    }
  }
  
  static double getHeaderFontSize(BuildContext context) {
    DeviceScreenType deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return 20.0;
      case DeviceScreenType.tablet:
        return 24.0;
      case DeviceScreenType.desktop:
        return 28.0;
    }
  }
  
  static double getSubtitleFontSize(BuildContext context) {
    DeviceScreenType deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return 14.0;
      case DeviceScreenType.tablet:
        return 16.0;
      case DeviceScreenType.desktop:
        return 18.0;
    }
  }
  
  // Modified to match dashboard approach more precisely
  static double getContentMaxWidth(BuildContext context) {
    // For web, we don't want to constrain the width at all
    return double.infinity;
  }
  
  // New method for section spacing
  static double getSectionSpacing(BuildContext context) {
    return getDeviceType(context) == DeviceScreenType.mobile ? 16.0 : 24.0;
  }
}

class SubscriptionScreen extends StatefulWidget {
  // Add parameter to indicate source
  final bool fromMembershipDetails;
  
  const SubscriptionScreen({
    Key? key, 
    this.fromMembershipDetails = false,
  }) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isHandlingSubscription = false; // Add this flag to prevent navigation conflicts
  StreamSubscription? _membershipStatusSubscription;
  String? membershipPlan;
  Timestamp? membershipEndDate;
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  // Safe method to show messages using InfoCard instead of SnackBar
  void _showMessage(String message, Color color, {IconData? icon}) {
    if (!mounted) return;
    
    // Use InfoCard instead of ScaffoldMessenger
    InfoCard.showInfoCard(
      context,
      message,
      color,
      icon: icon ?? Icons.info,
    );
  }

  @override
  void initState() {
    super.initState();
    developer.log('SubscriptionScreen initialized');

    // Initialize controller for animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Kullanıcı oturum kontrolü
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      developer.log('Kullanıcı oturum açmamış');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('Post frame callback executed');
      _initializeMembershipStatusListener();
    });
  }

  @override
  void dispose() {
    developer.log('SubscriptionScreen disposing');
    _membershipStatusSubscription?.cancel();
    _controller.dispose();
    _searchController.dispose();

    super.dispose();
  }

  /// Firestore'daki kullanıcı dokümanını izleyerek güncel üyelik durumunu çeker
  void _initializeMembershipStatusListener() {
    if (!mounted) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _membershipStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          membershipPlan = data['membershipPlan'] as String?;
          membershipEndDate = data['membershipEndDate'] as Timestamp?;
        });
      }
    });
  }

  /// Oturum kontrolü yapar, geçersizse login ekranına yollar
  Future<bool> _checkAndValidateAuth() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showMessage(
        tr('subscription_session_expired'),
        Colors.red,
        icon: Icons.error,
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }
    return true;
  }

  /// Placeholder implementation for subscription handling
  Future<void> _handleSubscription(
      BuildContext context, String plan, int days) async {
    if (_isLoading || _isHandlingSubscription) return;

    // Önce oturum kontrolü
    if (!await _checkAndValidateAuth()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isHandlingSubscription = true; // Set flag to prevent multiple submissions
    });

    try {
      // Kullanıcı bilgilerini güncelleme
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Tarih hesaplamaları
        final now = DateTime.now();
        final endDate = now.add(Duration(days: days));
        
        developer.log('🔄 INSTANT SUBSCRIPTION PROCESS STARTED:');
        developer.log('Plan: $plan');
        developer.log('Duration: $days days');

        // CRITICAL: Update local state immediately to reflect premium status
        setState(() {
          membershipPlan = plan;
          membershipEndDate = Timestamp.fromDate(endDate);
        });
        
        // IMPORTANT: First update the database in background
        // Don't wait for this to complete before updating local state
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'membershipStatus': 'premium',
          'membershipStartDate': Timestamp.fromDate(now),
          'membershipEndDate': Timestamp.fromDate(endDate),
          'membershipPlan': plan,
          'updatedAt': FieldValue.serverTimestamp(),
        }).then((_) {
          developer.log('✅ Firestore update completed successfully in background');
        }).catchError((error) {
          developer.log('❌ Background Firestore update error: $error');
        });

        // Note: The calling component (AvailablesPlans) will handle navigation
        // We don't need to navigate here
        return;
      }
    } catch (e) {
      developer.log('❌ Error during subscription process: $e');
      
      if (!mounted) return;
      
      // Use safe message display method
      _showMessage(
        tr('subscription_purchase_failed', args: [e.toString()]),
        Colors.red,
        icon: Icons.error,
      );
    } finally {
      // Only update state if still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isHandlingSubscription = false;
        });
      }
    }
  }
  
  // Simplified price function without in-app purchase details
  String _getPriceForPlan(String plan) {
    if (plan == 'free') return '0';
    
    // Return placeholder prices (can be replaced with data from your backend)
    switch (plan) {
      case 'monthly':
        return '49.99 ₺';
      case 'yearly':
        return '499.99 ₺';
      default:
        return 'N/A';
    }
  }

  /// membershipPlan değişkenini kullanıcıya gösterirken çeviri kullanıyoruz  
  String _getFormattedPlanText(String? plan) {
    if (plan == null) return tr('subscription_plans_free');

    switch (plan.toLowerCase()) {
      case 'monthly':
        return tr('subscription_plans_monthly_title');
      case 'yearly': 
        return tr('subscription_plans_yearly_title');
      case 'free':
        return tr('subscription_plans_free');
      default:
        return tr('subscription_plans_free');
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building SubscriptionScreen widget');
    developer.log('fromMembershipDetails: ${widget.fromMembershipDetails}');
    developer.log('membershipPlan: $membershipPlan');

    membershipEndDate?.toDate();
    
    // Check if the membership plan is free
    final isFree = membershipPlan == 'free' || membershipPlan == null;
    // Determine if we need to hide UI elements
    final hideNavElements = widget.fromMembershipDetails || isFree;
    
    developer.log('hideNavElements: $hideNavElements');
    
    // Get screen size information
    ResponsiveLayout.getDeviceType(context);
    final contentPadding = ResponsiveLayout.getContentPadding(context);
    
    return _isLoading
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : WillPopScope(
            // Prevent back navigation when coming from membership details
            onWillPop: () async => !widget.fromMembershipDetails,
            child: Scaffold(
              key: _scaffoldKey,
              // Conditionally show TopBar and SideMenu
              appBar: hideNavElements ? null : const TopBar(),
              drawer: hideNavElements ? null : const SideMenu(currentPage: '/subscription'),
              body: SafeArea(
                // Remove the Center and ConstrainedBox to allow content to stretch fully
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure all children stretch full width
                          children: [
                            // Add some padding at the top when there's no app bar
                            if (hideNavElements)
                              SizedBox(height: contentPadding * 1.5),
                            
                            // Header for subscription page when coming from membership details
                            if (widget.fromMembershipDetails || isFree) ...[
                              Text(
                                tr('subscription_membership_renewal'),
                                style: TextStyle(
                                  fontSize: ResponsiveLayout.getHeaderFontSize(context),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: contentPadding * 0.5),
                              Text(
                                tr('subscription_choose_plan'),
                                style: TextStyle(
                                  fontSize: ResponsiveLayout.getSubtitleFontSize(context),
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: contentPadding * 1.25),
                            ],
                            
                            // Current plan section - ensure it takes full width without any constraints
                            CurrentPlan(
                              membershipPlan: membershipPlan,
                              membershipEndDate: membershipEndDate,
                              controller: _controller,
                              getFormattedPlanText: _getFormattedPlanText,
                            ),
                            
                            SizedBox(height: ResponsiveLayout.getSectionSpacing(context)),
                            
                            // Subscription plans section - ensure it takes full width without any constraints
                            AvailablesPlans(
                              membershipPlan: membershipPlan,
                              membershipEndDate: membershipEndDate,
                              handleSubscription: _handleSubscription,
                              getPriceForPlan: _getPriceForPlan,
                              controller: _controller,
                            ),
                            
                            SizedBox(height: ResponsiveLayout.getSectionSpacing(context)),
                            
                            // Premium features section - ensure it takes full width without any constraints
                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _controller,
                                  curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                                ),
                              ),
                              child: const PremiumFeatures(),
                            ),
                            
                            // Extra space at the bottom for better mobile scrolling
                            SizedBox(height: contentPadding * 2),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
  }
}