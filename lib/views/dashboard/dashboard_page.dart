import 'package:flutter/material.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/top_bar.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'ai.dart'; 
import 'sales_activities.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async'; // For subscription timer

class DashboardPage extends StatefulWidget {
  final bool? showSubscriptionSuccess; // Add parameter to show subscription success
  final bool? refreshRequired; // Add parameter to force refresh
  
  const DashboardPage({
    super.key, 
    this.showSubscriptionSuccess,
    this.refreshRequired,
  });

  // Add static method to create instance with navigation data
  static MaterialPageRoute createRouteWithRefresh({bool showSuccess = true}) {
    return MaterialPageRoute(
      builder: (context) => DashboardPage(
        showSubscriptionSuccess: showSuccess,
        refreshRequired: true,
      ),
    );
  }

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  
  // Firebase services
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // Data storage - updated for HR models
  String? _currentUserId;
  bool _isLoadingMembership = true;
  bool _isSearching = false;
  
  // User profile data
  String _profileName = '';
  bool _isLoadingProfile = true;
  
  String _membershipPlan = 'free';
  
  // Subscription success message control
  bool _showSubscriptionSuccess = false;
  Timer? _subscriptionMessageTimer;

  // Add date filtering variables
  String _currentDateRange = 'this_month'; // Default filter, can be: today, yesterday, last_week, last_month, this_month, custom, all_time
  DateTimeRange? _customDateRange;
  
  // Helper to check if any data is still loading
  bool get _isLoadingStats => _isLoadingMembership;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _searchController.addListener(_onSearchChanged);
    _getCurrentUser();
    
    // Check if we should show subscription success message
    if (widget.showSubscriptionSuccess == true) {
      _showSubscriptionSuccess = true;
      
      // Auto-hide the success message after 10 seconds
      _subscriptionMessageTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {  // Check mounted before calling setState
          setState(() {
            _showSubscriptionSuccess = false;
          });
        }
      });
      
      // Force refresh membership data immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {  // Check mounted before calling async method
          _refreshMembershipStatus();
          
          // If refresh is explicitly required, force reload all data
          if (widget.refreshRequired == true) {
            _loadData();
          }
        }
      });
    }
  }
  
  // Method to refresh membership status after subscription change
  Future<void> _refreshMembershipStatus() async {
    try {
      // For sub-users, we need to refresh their parent's membership status cache
      await _userService.refreshParentMembershipStatus();
      
      // Check if still mounted before continuing
      if (!mounted) return;
      
      // Then load membership plan data again
      await _loadMembershipPlan();
      
      // Check premium access
      bool hasPremium = await _userService.hasPremiumAccess();
      print('Premium access check after subscription update: $hasPremium');
      
    } catch (e) {
      print('Error refreshing membership status: $e');
    }
  }
  
  // Search function to filter contracts
  void _onSearchChanged() {
    // Only update state if still mounted
    if (!mounted) return;
    
    final query = _searchController.text.trim().toLowerCase();
    
    setState(() {
      _isSearching = query.isNotEmpty;
      
      if (query.isEmpty) {
        // If search is empty, show all contracts
      } else {
        // Filter contracts based on query
      }
    });
  }
  
  // Function to clear search
  void _clearSearch() {
    _searchController.clear();
    if (mounted) {  // Check mounted before accessing context
      FocusScope.of(context).unfocus();
    }
  }
  
  // Get current user and load data
  Future<void> _getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {  // Check mounted before setState
        setState(() {
          _currentUserId = user.uid;
        });
        _loadData();
        _loadProfileName();
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
  }
  
  // Load user profile name from Firestore
  Future<void> _loadProfileName() async {
    if (!mounted) return;  // Add early return if not mounted
    
    setState(() => _isLoadingProfile = true);
    try {
      if (_currentUserId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .get();
            
        if (!mounted) return;  // Check again after async operation
            
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          
          // Check if this is a sub-user
          final bool isSubUser = userData['isSubUser'] as bool? ?? false;
          
          setState(() {
            if (isSubUser) {
              // For sub-users, use username field as the profile name
              _profileName = userData['username'] as String? ?? 
                            userData['email'] as String? ?? 
                            tr('dashboard_default_user');
            } else {
              // For regular users, keep using profileName with fallbacks
              _profileName = userData['profileName'] as String? ?? 
                            userData['email'] as String? ?? 
                            tr('dashboard_default_user');
            }
            _isLoadingProfile = false;
          });
        } else {
          setState(() {
            _profileName = tr('dashboard_default_user');
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;  // Check mounted status before setState
      setState(() {
        _profileName = tr('dashboard_default_user');
        _isLoadingProfile = false;
      });
      print('Error loading profile name: $e');
    }
  }
  
  // Load all required data
  void _loadData() {
    if (!mounted) return;
    
    // Reset to default date range
    _currentDateRange = 'this_month';
    _customDateRange = null;
    
    _loadMembershipPlan(); 
  }
  
  // Load membership plan from Firestore
  Future<void> _loadMembershipPlan() async {
    if (!mounted) return;  // Check mounted status at the beginning
    setState(() => _isLoadingMembership = true);
    
    try {
      if (_currentUserId != null) {
        // Get the latest membership data
        final user = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .get();
            
        if (!mounted) return;  // Check again after async operation
            
        if (user.exists && user.data() != null) {
          final userData = user.data()!;
          
          // Check if it's a sub-user
          final bool isSubUser = userData['isSubUser'] as bool? ?? false;
          
          if (isSubUser) {
            // For sub-users, get parentMembershipStatus from cache
            final parentStatus = userData['parentMembershipStatus'] as String?;
            setState(() {
              _membershipPlan = parentStatus ?? userData['membershipPlan'] as String? ?? 'free';
              _isLoadingMembership = false;
            });
            
            // Check if we need to refresh parent status
            final cachedAt = userData['parentMembershipCachedAt'] as Timestamp?;
            if (cachedAt == null || DateTime.now().difference(cachedAt.toDate()).inHours > 1) {
              // Cache is old, refresh parent status in the background
              // Don't await to avoid blocking if the widget gets disposed
              _userService.refreshParentMembershipStatus().then((_) {
                // Only reload if still mounted
                if (mounted) {
                  _loadMembershipPlan();
                }
              });
            }
          } else {
            // For regular users, get own membership plan
            setState(() {
              _membershipPlan = userData['membershipPlan'] as String? ?? 'free';
              _isLoadingMembership = false;
            });
          }
        } else {
          setState(() {
            _membershipPlan = 'free';
            _isLoadingMembership = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;  // Check mounted status before setState
      setState(() {
        _isLoadingMembership = false;
        _membershipPlan = 'free';
      });
      print('Error loading membership plan: $e');
    }
  }
  
  // Format currency
  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} ₺';
  }

  // Dismiss subscription success message
  void _dismissSubscriptionSuccess() {
    if (!mounted) return;  // Check mounted before setState
    
    setState(() {
      _showSubscriptionSuccess = false;
    });
    if (_subscriptionMessageTimer != null) {
      _subscriptionMessageTimer!.cancel();
      _subscriptionMessageTimer = null;
    }
  }

  // Handle date range change
  void _handleDateRangeChanged(String dateRange, {DateTimeRange? customDateRange}) {
    debugPrint('Date range changed: $dateRange, customRange: ${customDateRange?.start} - ${customDateRange?.end}');
    setState(() {
      _currentDateRange = dateRange;
      _customDateRange = customDateRange;
      _isLoadingMembership = true;
    });
    
    // Reload data with the new date filter
    _loadFilteredData();
  }
  
  // Load all filtered data based on current date range
  Future<void> _loadFilteredData() async {
    // Load only membership data, as other data types have been removed
  }
  
  // Get date range for current filter
  DateTimeRange _getDateRangeFromFilter() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_currentDateRange) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'last_week':
        // Last 7 days
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'last_month':
        // Last 30 days
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'this_month':
        // Start of current month
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'custom':
        if (_customDateRange != null) {
          // Create a new instance to ensure we're using a fresh object
          startDate = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day
          );
          // For the end date, set it to the end of day to include all records on that day
          endDate = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
            23, 59, 59
          );
          debugPrint('Using custom date range: $startDate to $endDate');
          return DateTimeRange(start: startDate, end: endDate);
        } else {
          // Fallback to this month if no custom range
          startDate = DateTime(now.year, now.month, 1);
          debugPrint('Custom date range was null, defaulting to this month');
        }
        break;
      case 'all_time':
        // Tüm zamanlar: çok eski bir tarih ve uzak bir gelecek tarihi kullan
        startDate = DateTime(2000, 1, 1);
        endDate = DateTime(2100, 1, 1);
        break;
      default:
        // Default to this month
        startDate = DateTime(now.year, now.month, 1);
    }

    return DateTimeRange(start: startDate, end: endDate);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _searchController.removeListener(_onSearchChanged); // Remove listener first
    _searchController.dispose();
    
    // Cancel timer if active
    if (_subscriptionMessageTimer != null) {
      _subscriptionMessageTimer!.cancel();
      _subscriptionMessageTimer = null;
    }
    
    super.dispose();
  }

  // Add responsive breakpoints
  bool _isSmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool _isMediumScreen(BuildContext context) => 
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1200;
  
  // Get responsive padding based on screen size
  EdgeInsets _getResponsivePadding(BuildContext context) {
    if (_isSmallScreen(context)) {
      return const EdgeInsets.all(12);
    } else if (_isMediumScreen(context)) {
      return const EdgeInsets.all(18);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(currentPage: '/',),
      body: Stack(
        children: [
          // Main content with responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: _getResponsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subscription success message
                      if (_showSubscriptionSuccess)
                        _buildSubscriptionSuccessMessage(),
                      
                      // Responsive header section
                      _buildResponsiveHeaderSection(context, constraints),
                      
                      const SizedBox(height: 32),
                      
                      // Stats cards section using the SalesActivities component
                      FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                          ),
                        ),
                        child: SalesActivities(
                          membershipPlan: _membershipPlan,
                          isLoading: _isLoadingStats,
                          formatCurrency: _formatCurrency,
                          onDateRangeChanged: _handleDateRangeChanged,
                          contractStatusCounts: const {}, // Provide an empty/default map or your actual data
                          averageContractDuration: 0, // Provide a default value or your actual data
                          averageSkillLevel: 0, // Provide a default value or your actual data
                          totalDepartments: 0, // Provide a default value or your actual data
                          totalEmployees: 0, // Provide a default value or your actual data
                          totalSkills: 0, // Provide a default value or your actual data
                        ),
                      ),
                      
                      // Add bottom padding to prevent content from being hidden by the FAB
                      SizedBox(height: _isSmallScreen(context) ? 100 : 80),
                    ],
                  ),
                ),
              );
            }
          ),
        ],
      ),
      floatingActionButton: _buildResponsiveFloatingActionButton(context),
    );
  }
  
  // Build responsive FAB
  Widget _buildResponsiveFloatingActionButton(BuildContext context) {
    if (_isSmallScreen(context)) {
      // Smaller FAB for mobile with adjusted position
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: const AIChatButton(),
      );
    } else {
      return const AIChatButton();
    }
  }

  // Responsive subscription success message
  Widget _buildSubscriptionSuccessMessage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = _isSmallScreen(context);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 24, 
            vertical: isSmall ? 12 : 16
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.green.shade800,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: isSmall ? 24 : 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('subscription_success_title'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('subscription_success_message', namedArgs: {
                        'plan': _membershipPlan.toUpperCase()
                      }),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _dismissSubscriptionSuccess,
                constraints: BoxConstraints(
                  minWidth: isSmall ? 40 : 48,
                  minHeight: isSmall ? 40 : 48,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // Completely redesigned responsive header section
  Widget _buildResponsiveHeaderSection(BuildContext context, BoxConstraints constraints) {
    final bool isSmall = constraints.maxWidth < 900;
    final double headerFontSize = isSmall ? 
        Theme.of(context).textTheme.titleLarge!.fontSize! : 
        Theme.of(context).textTheme.headlineMedium!.fontSize!;
    
    // For small screens, stack elements vertically
    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome and title section
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            )),
            child: _isLoadingProfile
              ? SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Text(
                        tr('dashboard_welcome'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: headerFontSize,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  '${tr('dashboard_welcome')} $_profileName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: headerFontSize,
                  ),
                ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
              ),
            ),
            child: Text(
              tr('dashboard_overview'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Search field and refresh button aligned horizontally on mobile
          Row(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: tr('dashboard_search_placeholder'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(tr('dashboard_refresh')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _loadData,
              ),
            ],
          ),
        ],
      );
    } 
    // For larger screens, use the original horizontal layout with adjustments
    else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: welcome message
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                      )),
                      child: _isLoadingProfile
                        ? SizedBox(
                            height: 36,
                            child: Row(
                              children: [
                                Text(
                                  tr('dashboard_welcome'),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            '${tr('dashboard_welcome')} $_profileName',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                        ),
                      ),
                      child: Text(
                        tr('dashboard_overview'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side: search and refresh button aligned
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _isMediumScreen(context) ? 250 : 300,
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: tr('dashboard_search_placeholder'),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching 
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 20),
                      label: Text(tr('dashboard_refresh')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _loadData,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  // The original _buildHeaderSection method has been removed 
  // as it's been completely replaced by _buildResponsiveHeaderSection
}