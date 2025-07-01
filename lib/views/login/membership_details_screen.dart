// lib/screens/membership_details_screen.dart
import 'package:fleet/views/subscription/subscription.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';

class MembershipDetailsScreen extends StatefulWidget {
  const MembershipDetailsScreen({Key? key}) : super(key: key);

  static void show(BuildContext context, {required String membershipStatus}) {
    if (membershipStatus == 'free') {
      debugPrint('Showing membership details screen');
      // Use more forceful navigation that clears the entire stack
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/membership_details',
        (route) => false,
      );
    }
  }

  @override
  State<MembershipDetailsScreen> createState() => _MembershipDetailsScreenState();
}

class _MembershipDetailsScreenState extends State<MembershipDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Navigate to subscription screen safely
  void _navigateToSubscription() {
    // Use pushAndRemoveUntil to clear the stack completely instead of pushReplacement
    // This ensures we have a clean navigation stack with proper context
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(
          fromMembershipDetails: true,
        ),
      ),
      (route) => false, // Clear all routes
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive calculations
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive values based on available space
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            
            // Adaptive padding based on screen size
            final horizontalPadding = maxWidth * 0.06;
            final verticalPadding = maxHeight * 0.04;
            
            // Calculate animation size based on screen dimensions
            final animationSize = maxWidth < 600 
                ? maxWidth * 0.5 
                : maxWidth * 0.3;
            
            // Limit animation size for very large screens
            final clampedAnimationSize = animationSize.clamp(120.0, 220.0);
            
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 800, // Max width for large screens
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Responsive top spacing
                        SizedBox(height: maxHeight * 0.02),
                        
                        FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                            ),
                          ),
                          child: SizedBox(
                            height: clampedAnimationSize,
                            width: clampedAnimationSize,
                            child: Lottie.network(
                              'https://assets4.lottiefiles.com/packages/lf20_qpsnmykx.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: maxHeight * 0.03),
                        
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                          )),
                          child: Text(
                            tr('membership_expired_title'),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: isSmallScreen ? 22 : 28,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        SizedBox(height: maxHeight * 0.02),
                        
                        FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                            ),
                          ),
                          child: Text(
                            tr('membership_expired_message'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                              height: 1.5,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        SizedBox(height: maxHeight * 0.04),
                        
                        FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                            ),
                          ),
                          child: SizedBox(
                            width: isSmallScreen ? double.infinity : maxWidth * 0.4,
                            child: ElevatedButton.icon(
                              onPressed: _navigateToSubscription,
                              icon: const Icon(Icons.workspace_premium_outlined),
                              label: Text(
                                tr('membership_renew_button'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 24, 
                                  vertical: isSmallScreen ? 10 : 12
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ),
                        
                        // Bottom spacing for scrollable area
                        SizedBox(height: maxHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
