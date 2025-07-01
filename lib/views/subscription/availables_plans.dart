import 'package:fleet/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailablesPlans extends StatefulWidget {
  final String? membershipPlan;
  final Function(BuildContext, String, int) handleSubscription;
  final String Function(String) getPriceForPlan;
  final AnimationController controller;
  final Timestamp? membershipEndDate; // Ekledik: mevcut üyelik bitiş tarihini almak için

  // Updated subscription plans with monthly and yearly options
  static Map<String, Map<String, dynamic>> get subscriptionPlans => {
    'monthly': {
      'title': tr('subscription_plans_monthly_title'),
      'duration': tr('subscription_plans_monthly_duration'),
      'days': 30,
      'features': [
        tr('subscription_features_unlimited_visits'),
        tr('subscription_features_unlimited_products'),
        tr('subscription_features_detailed_reports'),
        tr('subscription_features_ai_assistant_pro'),
        tr('subscription_features_stock_tracking'),
        tr('subscription_features_route_optimization'),
        tr('subscription_features_customer_segmentation'),
        tr('subscription_features_payment_tracking'),
        tr('subscription_features_email_notifications'),
      ],
      'color': Color(0xFF2563EB),
      'icon': Icons.calendar_month,
    },
    'yearly': {
      'title': tr('subscription_plans_yearly_title'),
      'duration': tr('subscription_plans_yearly_duration'),
      'days': 365,
      'features': [
        tr('subscription_features_unlimited_visits'),
        tr('subscription_features_unlimited_products'),
        tr('subscription_features_detailed_reports'),
        tr('subscription_features_ai_assistant_pro'),
        tr('subscription_features_stock_tracking'),
        tr('subscription_features_route_optimization'),
        tr('subscription_features_customer_segmentation'),
        tr('subscription_features_payment_tracking'),
        tr('subscription_features_email_notifications'),
        tr('subscription_features_priority_support'),
        tr('subscription_features_api_integration'),
        tr('subscription_features_multi_user'),
        tr('subscription_features_data_backup'),
      ],
      'color': Color(0xFF1E3A8A),
      'popular': true,
      'icon': Icons.calendar_today,
    },
  };

  const AvailablesPlans({
    Key? key,
    required this.membershipPlan,
    required this.handleSubscription,
    required this.getPriceForPlan,
    required this.controller,
    this.membershipEndDate, // Ekledik
  }) : super(key: key);

  @override
  State<AvailablesPlans> createState() => _AvailablesPlansState();
}

class _AvailablesPlansState extends State<AvailablesPlans> {
  final List<bool> _isHovering = [false, false];

  // Updated method to handle subscription with proper parent membership status propagation
  void _handleSubscription(BuildContext context, String planType, int days) async {
    // Store navigator reference before async operations
    final navigator = Navigator.of(context);
    // Store scaffold messenger for showing error messages
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Show loading indicator with animation and text
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false, // Prevent dialog dismissal with back button
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AvailablesPlans.subscriptionPlans[planType]!['color']),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr('subscription_processing'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('subscription_wait_message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      );
      
      // Call the parent handleSubscription function
      await widget.handleSubscription(context, planType, days);
      
      // After successful subscription, update parent membership status for all sub-users
      try {
        // Get the current user ID
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userId = currentUser.uid;
          
          // First update the user's own membership status document
          // Always set membershipStatus to "premium" regardless of plan type
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
                'membershipStatus': 'premium', // Always set to premium
                'membershipPlan': planType, // Keep track of specific plan type
                'membershipUpdatedAt': FieldValue.serverTimestamp(),
              });
          
          debugPrint('Updated user membership status to premium with plan: $planType');
              
          // Then use FirestoreService to propagate to all sub-users
          final firestoreService = FirestoreService();
          
          // Use the propagation method to update all sub-users with premium status
          await firestoreService.updateParentMembershipStatusForAllSubUsers(
            userId,
            'premium' // Always propagate "premium" to sub-users
          );
          
          debugPrint('Propagated premium membership status to all sub-users');
        }
      } catch (e) {
        debugPrint('Error propagating membership status: $e');
        // We'll still continue to navigation even if propagation fails
      }

      // IMPORTANT: Use a direct navigation approach to dashboard
      // Don't close the loading dialog - we'll let the new screen replace everything
      try {
        // Use pushAndRemoveUntil to completely clear the navigation stack
        navigator.pushNamedAndRemoveUntil(
          '/', 
          (_) => false,  // Remove all previous routes
          arguments: {
            'showSubscriptionSuccess': true,
            'refreshRequired': true,
          },
        );
      } catch (navError) {
        debugPrint('Error during navigation to dashboard: $navError');
        
        // Try an alternative navigation approach as fallback
        try {
          navigator.pushNamedAndRemoveUntil('/', (_) => false);
        } catch (fallbackError) {
          debugPrint('Fallback navigation also failed: $fallbackError');
        }
      }
    } catch (e) {
      debugPrint('Error handling subscription: $e');
      
      // Make sure we close the loading dialog if there's an error
      try {
        if (navigator.canPop()) {
          navigator.pop();
        }
      } catch (navError) {
        debugPrint('Navigation error when closing dialog on error: $navError');
      }
      
      // Show error message safely
      try {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (snackBarError) {
        debugPrint('Error showing snackbar: $snackBarError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get device screen size
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    // Responsive font sizes and spacing
    final double titleFontSize = isMobile ? 20 : 22;
    final double headingSpacing = isMobile ? 16 : 24;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: widget.controller,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 4 : 8),
            child: Text(
              tr('subscription_available_plans'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
            ),
          ),
        ),
        SizedBox(height: headingSpacing),
        
        // Plan cards in responsive layout
        _buildResponsiveCardLayout(context),
      ],
    );
  }
  
  // New method for responsive card layout
  Widget _buildResponsiveCardLayout(BuildContext context) {
    // Advanced responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;
    
    // For very small devices, ensure proper padding
    final double horizontalPadding = isMobile ? 8 : 0;
    final double cardSpacing = isMobile ? 16 : isTablet ? 20 : 24;
    
    // Return layout based on screen size
    if (isDesktop) {
      // Side-by-side layout for wider screens
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildSubscriptionCard(context, 'monthly', 0)),
          SizedBox(width: cardSpacing),
          Expanded(child: _buildSubscriptionCard(context, 'yearly', 1)),
        ],
      );
    } else if (isTablet) {
      // Medium screens - still side by side but with different proportions
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 10,
            child: _buildSubscriptionCard(context, 'monthly', 0),
          ),
          SizedBox(width: cardSpacing),
          Expanded(
            flex: 11, // Slightly larger for the featured yearly plan
            child: _buildSubscriptionCard(context, 'yearly', 1),
          ),
        ],
      );
    } else {
      // Stacked layout for mobile screens
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            _buildSubscriptionCard(context, 'monthly', 0),
            SizedBox(height: cardSpacing),
            _buildSubscriptionCard(context, 'yearly', 1),
          ],
        ),
      );
    }
  }

  Widget _buildSubscriptionCard(BuildContext context, String planType, int index) {
    final planData = AvailablesPlans.subscriptionPlans[planType]!;
    final bool isCurrentPlan = widget.membershipPlan == planType;
    final bool isYearlyActive = widget.membershipPlan == 'yearly';
    final bool isMonthlyActive = widget.membershipPlan == 'monthly';
    final bool isMonthlyCard = planType == 'monthly';
    final bool isYearlyCard = planType == 'yearly';
    final bool isDisabled = isMonthlyCard && isYearlyActive;
    
    final Color planColor = planData['color'];
    final List<String> features = List<String>.from(planData['features']);
    final String price = widget.getPriceForPlan(planType);
    final IconData planIcon = planData['icon'] ?? Icons.diamond_outlined;
    
    // Get screen dimensions for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    // Responsive sizing
    final double headerHeight = isMobile ? 80 : 100;
    final double iconSize = isMobile ? 36 : 48;
    final double cardBorderRadius = isMobile ? 16 : 20;
    final double priceFontSize = isMobile ? 24 : 28;
    final double featureFontSize = isMobile ? 13 : 14;
    final double featureIconSize = isMobile ? 12 : 14;
    final double buttonVerticalPadding = isMobile ? 12 : 16;
    final double badgeFontSize = isMobile ? 10 : 12;
    
    // Calculate end date
    final DateTime now = DateTime.now();
    final DateTime endDate = now.add(Duration(days: planData['days'] as int));
    
    // Calculate adjusted end date for monthly to yearly upgrade
    DateTime adjustedEndDate = endDate;
    int adjustedDays = planData['days'] as int;
    if (isMonthlyActive && isYearlyCard && widget.membershipEndDate != null) {
      final DateTime currentEndDate = widget.membershipEndDate!.toDate();
      if (currentEndDate.isAfter(now)) {
        final int remainingDays = currentEndDate.difference(now).inDays;
        adjustedDays = (planData['days'] as int) + remainingDays;
        adjustedEndDate = now.add(Duration(days: adjustedDays));
      }
    }
    
    final String formattedEndDate = DateFormat.yMd(context.locale.languageCode).format(adjustedEndDate);
    
    // Calculate savings for yearly plan
    if (planType == 'yearly') {
      final String monthlyRaw = widget.getPriceForPlan('monthly').replaceAll(RegExp(r'[^0-9]'), '');
      final String yearlyRaw = price.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (monthlyRaw.isNotEmpty && yearlyRaw.isNotEmpty) {
        final int monthlyValue = int.tryParse(monthlyRaw) ?? 0;
        final int yearlyValue = int.tryParse(yearlyRaw) ?? 0;
        
        if (yearlyValue < monthlyValue * 12 && monthlyValue > 0) {
          final int savings = ((monthlyValue * 12) - yearlyValue) * 100 ~/ (monthlyValue * 12);
          if (savings > 0) {
            planData['savings'] = savings;
          }
        }
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering[index] = true),
      onExit: (_) => setState(() => _isHovering[index] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: (!isMobile && _isHovering[index])
            ? (Matrix4.identity()..translate(0, -8, 0))
            : Matrix4.identity(),
        // Use intrinsic height instead of fixed height
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: isDisabled 
                  ? Colors.grey.withOpacity(0.1)
                  : planColor.withOpacity(_isHovering[index] ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: _isHovering[index] ? 2 : 0,
            ),
          ],
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : (isCurrentPlan
                    ? Colors.green.withOpacity(0.8)
                    : (_isHovering[index] ? planColor.withOpacity(0.5) : Colors.grey[200]!)),
            width: isCurrentPlan || _isHovering[index] ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Header/image section at the top
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Plan header with gradient
                Container(
                  height: headerHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        planColor.withOpacity(0.8),
                        planColor,
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(cardBorderRadius),
                      topRight: Radius.circular(cardBorderRadius),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      planIcon,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                ),
              ],
            ),
            
            // Badge (current plan or popular)
            if (isCurrentPlan)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16, 
                    vertical: isMobile ? 6 : 8
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(cardBorderRadius),
                      bottomLeft: Radius.circular(cardBorderRadius * 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: isMobile ? 14 : 16,
                      ),
                      SizedBox(width: isMobile ? 2 : 4),
                      Text(
                        tr('subscription_current_plan_badge'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: badgeFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (planData['popular'] == true)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16, 
                    vertical: isMobile ? 6 : 8
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(cardBorderRadius),
                      bottomLeft: Radius.circular(cardBorderRadius * 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.white,
                        size: isMobile ? 14 : 16,
                      ),
                      SizedBox(width: isMobile ? 2 : 4),
                      Text(
                        tr('subscription_popular_badge'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: badgeFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Disabled overlay
            if (isDisabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(cardBorderRadius),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: iconSize,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            tr('subscription_yearly_active_message'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Content
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 20,
                headerHeight + (isMobile ? 8 : 10),
                isMobile ? 16 : 20,
                isMobile ? 16 : 20
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Plan title and duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planData['title'],
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              planData['duration'],
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Savings badge for yearly plan
                      if (planType == 'yearly' && planData['savings'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 8, 
                            vertical: isMobile ? 3 : 4
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                            border: Border.all(
                              color: Colors.green[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.savings,
                                color: Colors.green[800],
                                size: isMobile ? 14 : 16,
                              ),
                              SizedBox(width: isMobile ? 2 : 4),
                              Text(
                                '%${planData['savings'].toString()} ${tr('subscription_discount')}',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: isMobile ? 10 : 12),
                  
                  // Price section
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 10 : 12, 
                      horizontal: isMobile ? 12 : 16
                    ),
                    decoration: BoxDecoration(
                      color: isDisabled 
                          ? Colors.grey[200] 
                          : planColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      border: Border.all(
                        color: planColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              price,
                              style: TextStyle(
                                fontSize: priceFontSize,
                                fontWeight: FontWeight.bold,
                                color: isDisabled ? Colors.grey[500] : planColor,
                              ),
                            ),
                            SizedBox(width: isMobile ? 2 : 4),
                            Text(
                              planType == 'yearly' ? tr('subscription_per_year') : tr('subscription_per_month'),
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        // Different messages based on subscription state
                        if (isMonthlyActive && isYearlyCard && widget.membershipEndDate != null)
                          Text(
                            tr('subscription_upgrade_with_remaining', namedArgs: {'date': formattedEndDate}),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 13,
                              color: Colors.green[700],
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (widget.membershipPlan == 'starter' && widget.membershipEndDate != null)
                          Text(
                            widget.membershipEndDate!.toDate().difference(DateTime.now()).inDays.toString(),
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 13,
                              color: Colors.orange[700],
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            tr('subscription_valid_until', namedArgs: {'date': formattedEndDate}),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 13,
                              color: isDisabled ? Colors.grey[500] : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 14 : 16),
                  
                  // Features title
                  Text(
                    tr('subscription_features_title'),
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  
                  // Features list - adaptive height with scrolling
                  _buildFeaturesListWidget(
                    features, 
                    planColor, 
                    isMobile, 
                    featureFontSize, 
                    featureIconSize
                  ),
                  
                  SizedBox(height: isMobile ? 14 : 16),
                  
                  // Subscribe button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: (!isMobile && _isHovering[index])
                          ? (Matrix4.identity()..translate(0, -2, 0))
                          : Matrix4.identity(),
                      child: ElevatedButton(
                        onPressed: isCurrentPlan || isDisabled
                            ? null
                            : () {
                                if (isMonthlyActive && isYearlyCard) {
                                  _showUpgradeConfirmationDialog(
                                    context, 
                                    planType, 
                                    adjustedDays, 
                                    formattedEndDate
                                  );
                                } else {
                                  final int days = planData['days'] as int;
                                  _handleSubscription(context, planType, days);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDisabled 
                              ? Colors.grey[400] 
                              : (isCurrentPlan ? Colors.grey[400] : planColor),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                          elevation: (!isMobile && _isHovering[index]) ? 8 : 2,
                          shadowColor: planColor.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                          ),
                        ),
                        child: Text(
                          isCurrentPlan 
                            ? tr('subscription_current_plan_button')
                            : isDisabled
                              ? tr('subscription_unavailable_button')
                              : isMonthlyActive && isYearlyCard
                                ? tr('subscription_upgrade_button')
                                : tr('subscription_join_now'),
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method to build features list with responsive height
  Widget _buildFeaturesListWidget(
    List<String> features, 
    Color planColor, 
    bool isMobile, 
    double fontSize, 
    double iconSize
  ) {
    // Calculate ideal height based on screen size and feature count
    final double featureItemHeight = isMobile ? 28.0 : 32.0;
    final int visibleItems = isMobile ? 5 : 7;
    final double containerHeight = features.length <= visibleItems 
        ? features.length * featureItemHeight 
        : visibleItems * featureItemHeight;
    
    return Container(
      height: containerHeight,
      constraints: BoxConstraints(
        minHeight: featureItemHeight * 3,
        maxHeight: isMobile 
            ? featureItemHeight * 6 // More compact on mobile
            : featureItemHeight * 7.5 // More space on desktop
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: features.length > visibleItems 
            ? const ClampingScrollPhysics() 
            : const NeverScrollableScrollPhysics(),
        itemCount: features.length,
        itemBuilder: (context, idx) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: isMobile ? 1 : 2),
                  padding: EdgeInsets.all(isMobile ? 3 : 4),
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: planColor,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    features[idx],
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Responsive upgrade confirmation dialog
  void _showUpgradeConfirmationDialog(
    BuildContext context, 
    String planType, 
    int adjustedDays,
    String formattedEndDate
  ) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20)
        ),
        contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
        title: Text(
          tr('subscription_upgrade_title'),
          style: TextStyle(fontSize: isMobile ? 18 : 20),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('subscription_upgrade_confirmation'),
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, 
                      color: Colors.green[700],
                      size: isMobile ? 18 : 24,
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Text(
                        tr('subscription_upgrade_detail', namedArgs: {'date': formattedEndDate}),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tr('subscription_cancel'),
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleSubscription(context, planType, adjustedDays);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AvailablesPlans.subscriptionPlans['yearly']!['color'],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 8 : 10,
              ),
            ),
            child: Text(
              tr('subscription_upgrade_confirm'),
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
        ],
      ),
    );
  }
}
