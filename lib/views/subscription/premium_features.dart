import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PremiumFeatures extends StatefulWidget {
  const PremiumFeatures({Key? key}) : super(key: key);

  @override
  State<PremiumFeatures> createState() => _PremiumFeaturesState();
}

class _PremiumFeaturesState extends State<PremiumFeatures> {
  Map<int, bool> hoveredItems = {};
  late PageController _pageController;
  int _currentPage = 0;
  double _viewportFraction = 0.3;
  double? _lastConstraintMaxWidth;
  bool _isSmallScreen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: _currentPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Calculate the appropriate viewport fraction based on screen width
  double _calculateViewportFraction(double maxWidth) {
    if (maxWidth <= 360) return 0.9; // Very small mobile
    if (maxWidth <= 480) return 0.85; // Small mobile
    if (maxWidth <= 600) return 0.8; // Mobile
    if (maxWidth <= 840) return 0.6; // Tablet portrait
    if (maxWidth <= 1200) return 0.4; // Tablet landscape
    return 0.25; // Desktop
  }

  // Calculate the card height based on screen size
  double _calculateCardHeight(double maxWidth, double maxHeight) {
    // Make sure card doesn't exceed 40% of screen height on small devices
    if (maxWidth <= 480) {
      return maxHeight * 0.3 < 180 ? maxHeight * 0.3 : 180;
    }
    
    if (maxWidth <= 840) {
      return 200;
    }
    
    return 220;
  }

  // Update the page controller if viewport fraction changes
  void _updatePageControllerIfNeeded(double maxWidth) {
    if (_lastConstraintMaxWidth == maxWidth) return;
    
    final isSmallScreen = maxWidth <= 600;
    _lastConstraintMaxWidth = maxWidth;
    final newViewportFraction = _calculateViewportFraction(maxWidth);
    
    if (newViewportFraction != _viewportFraction || _isSmallScreen != isSmallScreen) {
      // Schedule after the current build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        // Get the current page before creating a new controller
        final double currentPage = _pageController.hasClients && _pageController.positions.isNotEmpty
            ? _pageController.page ?? 0.0
            : 0.0;
        
        setState(() {
          _isSmallScreen = isSmallScreen;
          _viewportFraction = newViewportFraction;
          // Dispose the old controller
          _pageController.dispose();
          // Create a new controller with the updated fraction
          _pageController = PageController(
            viewportFraction: newViewportFraction,
            initialPage: currentPage.round(),
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.rocket_launch,
        'title': tr('subscription_features_ai_assistant'),
        'description': tr('subscription_features_ai_assistant_desc'),
      },
      {
        'icon': Icons.groups,
        'title': tr('subscription_features_unlimited_customers'),
        'description': tr('subscription_features_unlimited_customers_desc'),
      },
      {
        'icon': Icons.inventory_2,
        'title': tr('subscription_features_unlimited_products'),
        'description': tr('subscription_features_unlimited_products_desc'),
      },
      {
        'icon': Icons.analytics,
        'title': tr('subscription_features_advanced_reports'),
        'description': tr('subscription_features_advanced_reports_desc'),
      },
      {
        'icon': Icons.route,
        'title': tr('subscription_features_route_optimization'),
        'description': tr('subscription_features_route_optimization_desc'),
      },
      {
        'icon': Icons.sync,
        'title': tr('subscription_features_auto_backup'),
        'description': tr('subscription_features_auto_backup_desc'),
      },
    ];

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            tr("subscription_premium_features"),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (ctx, constraints) {
            // Update the controller if needed, but don't call setState during build
            _updatePageControllerIfNeeded(constraints.maxWidth);
            
            // Calculate responsive dimensions
            final isSmallScreen = constraints.maxWidth <= 600;
            final cardHeight = _calculateCardHeight(constraints.maxWidth, constraints.maxHeight);
            final horizontalPadding = isSmallScreen ? 8.0 : 16.0;
            
            return Column(
              children: [
                SizedBox(
                  height: cardHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    padEnds: true,
                    itemCount: features.length,
                    onPageChanged: (int page) {
                      if (mounted) {
                        setState(() {
                          _currentPage = page;
                        });
                      }
                    },
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      bool isCurrentPage = _currentPage == index;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuint,
                        margin: EdgeInsets.symmetric(
                          horizontal: horizontalPadding, 
                          vertical: isCurrentPage ? 5 : isSmallScreen ? 10 : 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                          boxShadow: [
                            BoxShadow(
                              color: (hoveredItems[index] == true || isCurrentPage)
                                  ? theme.primaryColor.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: (hoveredItems[index] == true || isCurrentPage) ? 12 : 8,
                              offset: (hoveredItems[index] == true || isCurrentPage)
                                  ? const Offset(0, 6)
                                  : const Offset(0, 3),
                              spreadRadius: (hoveredItems[index] == true || isCurrentPage) ? 1 : 0,
                            ),
                          ],
                          border: Border.all(
                            color: (hoveredItems[index] == true || isCurrentPage)
                                ? theme.primaryColor.withOpacity(0.3)
                                : Colors.grey[200]!,
                            width: (hoveredItems[index] == true || isCurrentPage) ? 2 : 1,
                          ),
                        ),
                        child: MouseRegion(
                          onEnter: (_) {
                            if (mounted) {
                              setState(() => hoveredItems[index] = true);
                            }
                          },
                          onExit: (_) {
                            if (mounted) {
                              setState(() => hoveredItems[index] = false);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Icon container
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(
                                        (hoveredItems[index] == true || isCurrentPage) ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                    boxShadow: (hoveredItems[index] == true || isCurrentPage)
                                        ? [
                                            BoxShadow(
                                              color: theme.primaryColor.withOpacity(0.2),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Icon(
                                    feature['icon'] as IconData,
                                    color: theme.primaryColor,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 12),
                                // Title
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    feature['title'] as String,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: (hoveredItems[index] == true || isCurrentPage)
                                          ? theme.primaryColor
                                          : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                // Description
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    child: Text(
                                      feature['description'] as String,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: isSmallScreen ? 11 : 13,
                                        height: 1.4,
                                      ),
                                      overflow: TextOverflow.fade,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                // Pagination controls - adaptive layout
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: isSmallScreen
                      // Simplified controls for small screens
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Dots only for small screens - more compact
                            ...List.generate(
                              features.length,
                              (index) => GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentPage == index ? 16.0 : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                    color: _currentPage == index
                                        ? theme.primaryColor
                                        : theme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      // Full controls for larger screens
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Back arrow
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              iconSize: 20,
                              onPressed: _currentPage > 0
                                  ? () {
                                      _pageController.animateToPage(
                                        _currentPage - 1,
                                        duration: const Duration(milliseconds: 400),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                              color: _currentPage > 0
                                  ? theme.primaryColor
                                  : Colors.grey.withOpacity(0.3),
                            ),
                            // Dots
                            ...List.generate(
                              features.length,
                              (index) => GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentPage == index ? 16.0 : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: _currentPage == index
                                        ? theme.primaryColor
                                        : theme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                            // Forward arrow
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              iconSize: 20,
                              onPressed: _currentPage < features.length - 1
                                  ? () {
                                      _pageController.animateToPage(
                                        _currentPage + 1,
                                        duration: const Duration(milliseconds: 400),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                              color: _currentPage < features.length - 1
                                  ? theme.primaryColor
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ],
                        ),
                ),
                // Touch indicator for mobile - helps users understand they can swipe
                if (isSmallScreen) 
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tr('swipe_to_see_more'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}