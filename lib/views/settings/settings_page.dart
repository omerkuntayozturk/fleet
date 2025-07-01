import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleet/info_card.dart';
import 'package:fleet/services/firestore_service.dart';
import 'package:fleet/views/login/membership_details_screen.dart';
import 'package:fleet/views/settings/aboutus.dart';
import 'package:fleet/views/settings/cookies.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/top_bar.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'log_out.dart';
import 'delete_account.dart';
import 'languade.dart';
import 'sss.dart';
import 'contact_us.dart';
import 'privacy_policy.dart';
import 'kvkkk.dart';
import 'user_manuel.dart';
import 'users.dart';
import 'curency.dart';
import '../../services/user_service.dart';

// Custom class to handle responsive breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 650;
  static const double tablet = 900;
  static const double desktop = 1200;
  
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < mobile;
      
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobile && 
      MediaQuery.of(context).size.width < tablet;
      
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= tablet;
      
  // Helper to get appropriate horizontal padding based on screen size
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return const EdgeInsets.symmetric(horizontal: 16);
    if (width < tablet) return const EdgeInsets.symmetric(horizontal: 24);
    return const EdgeInsets.symmetric(horizontal: 32);
  }
  
  // Get appropriate section spacing
  static double getSectionSpacing(BuildContext context) {
    return isMobile(context) ? 16 : 24;
  }
  
  // Updated content width constraint to match dashboard approach
  static double getContentMaxWidth(BuildContext context) {
    // For web, don't constrain the width at all to match dashboard approach
    return double.infinity;
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  Widget buildPlaceholder(BuildContext context) {
    return Container(); // Replace with your actual widget tree
  }
  bool cookieConsent = true;
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Selected currency - updated to start with loading state
  Map<String, dynamic> _selectedCurrency = {'symbol': '...', 'name': 'Loading...', 'code': '...'};
  bool _isLoadingCurrency = true;
  
  // User service instance to get currency info
  final UserService _userService = UserService();
  
  // Settings categories and items for searching
  final List<Map<String, dynamic>> _allSettings = [
    {
      'category': tr('settings_category_account'),
      'items': [
        tr('settings_item_edit_profile'),
        tr('settings_item_change_password'),
        tr('settings_item_account_activity'),
        tr('settings_item_login_history'),
        tr('settings_item_logout'),
        tr('settings_item_delete_account')
      ]
    },
    {
      'category': tr('settings_category_preferences'),
      'items': [
        tr('settings_item_multilanguage'),
        tr('settings_item_currency'),
        'Türkçe',
        'English',
        'Deutsch',
        'Français',
        'Español'
      ]
    },
    {
      'category': tr('settings_category_privacy'),
      'items': [
        tr('settings_item_privacy_policy'),
        tr('settings_item_kvkk'),
        tr('settings_item_cookie_policy'),
        tr('settings_item_cookie_consent'),
        tr('settings_item_terms')
      ]
    },
    {
      'category': tr('settings_category_help'),
      'items': [
        tr('settings_item_faq'),
        tr('settings_item_sss'),
        tr('settings_item_contact_us'),
        tr('settings_item_support'),
        tr('settings_item_contact'),
        tr('settings_item_about_us')
      ]
    },
    {
      'category': tr('settings_category_system'),
      'items': [
        tr('settings_item_user_management'),
        tr('settings_item_add_user'),
        tr('settings_item_permissions')
      ]
    }
  ];

  // Visible sections based on search
  bool _showAccountSettings = true;
  bool _showPreferences = true;
  bool _showPrivacy = true;
  bool _showHelp = true;
  bool _showSystemManagement = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
    
    // Load user's currency preference
    _loadUserCurrency();
  }
  
  // Method to load the user's currency preference
  Future<void> _loadUserCurrency() async {
    try {
      setState(() {
        _isLoadingCurrency = true;
      });
      
      // First synchronize currency settings
      await _userService.synchronizeCurrencySettings();
      
      // Then get the user's current currency preference
      final currencyCode = await _userService.getUserCurrency();
      
      if (currencyCode != null) {
        // Map the currency code to our currency data
        Map<String, dynamic> currencyData = _getCurrencyDataByCode(currencyCode);
        
        setState(() {
          _selectedCurrency = currencyData;
          _isLoadingCurrency = false;
        });
        
        debugPrint('Loaded user currency: ${currencyData['code']}');
      } else {
        // Default to TRY if no preference found
        setState(() {
          _selectedCurrency = {'symbol': '₺', 'name': 'Turkish Lira', 'code': 'TRY'};
          _isLoadingCurrency = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user currency: $e');
      setState(() {
        _selectedCurrency = {'symbol': '₺', 'name': 'Turkish Lira', 'code': 'TRY'};
        _isLoadingCurrency = false;
      });
    }
  }
  
  // Helper method to get currency data by code
  Map<String, dynamic> _getCurrencyDataByCode(String code) {
    // Currency mapping - should match your CurrencyPage data structure
    final List<Map<String, dynamic>> currencies = [
      {'symbol': '₺', 'name': 'Turkish Lira', 'code': 'TRY'},
      {'symbol': '\$', 'name': 'US Dollar', 'code': 'USD'},
      {'symbol': '€', 'name': 'Euro', 'code': 'EUR'},
      {'symbol': '¥', 'name': 'Japanese Yen', 'code': 'JPY'},
      {'symbol': '£', 'name': 'British Pound', 'code': 'GBP'},
      {'symbol': '¥', 'name': 'Chinese Yuan', 'code': 'CNY'},
      {'symbol': 'CA\$', 'name': 'Canadian Dollar', 'code': 'CAD'},
      {'symbol': 'CHF', 'name': 'Swiss Franc', 'code': 'CHF'},
      // Add more currencies as needed
    ];
    
    // Find the currency by code
    final currency = currencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'symbol': '₺', 'name': 'Turkish Lira', 'code': 'TRY'},
    );
    
    return currency;
  }

  // Method to handle search changes
  void _onSearchChanged() {
    _filterSettings(_searchController.text);
  }

  // Filter settings based on search query
  void _filterSettings(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
      
      if (_searchQuery.isEmpty) {
        // Show all sections if search is empty
        _showAccountSettings = true;
        _showPreferences = true;
        _showPrivacy = true;
        _showHelp = true;
        _showSystemManagement = true;
      } else {
        // Check each category for matches
        _showAccountSettings = _categoryContainsQuery(_allSettings[0]);
        _showPreferences = _categoryContainsQuery(_allSettings[1]);
        _showPrivacy = _categoryContainsQuery(_allSettings[2]);
        _showHelp = _categoryContainsQuery(_allSettings[3]);
        _showSystemManagement = _categoryContainsQuery(_allSettings[4]);
      }
    });
  }

  // Helper method to check if category or any of its items match the query
  bool _categoryContainsQuery(Map<String, dynamic> category) {
    if (category['category'].toString().toLowerCase().contains(_searchQuery)) {
      return true;
    }
    
    for (var item in category['items']) {
      if (item.toString().toLowerCase().contains(_searchQuery)) {
        return true;
      }
    }
    
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    // Remove the listener to prevent memory leaks
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Show profile edit dialog
  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.isMobile(context) ? 8 : 20, 
            vertical: ResponsiveBreakpoints.isMobile(context) ? 8 : 20
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.isMobile(context) 
                ? MediaQuery.of(context).size.width * 0.95
                : MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: ProfileEditDialog(
              onSave: (userData) {
                InfoCard.showInfoCard(
                  context,
                  tr('settings_profile_update_success'),
                  Colors.green,
                  icon: Icons.check_circle,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Show password change dialog with responsive adjustments
  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.isMobile(context) ? 8 : 20, 
            vertical: ResponsiveBreakpoints.isMobile(context) ? 8 : 20
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.isMobile(context) 
                ? MediaQuery.of(context).size.width * 0.95
                : MediaQuery.of(context).size.width * 0.5,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: const PasswordChangeDialog(),
          ),
        );
      },
    );
  }

  // This method uses the LogoutDialog class
  void _showLogoutConfirmationDialog() {
    LogoutDialog.showLogoutConfirmationDialog(context);
  }

  // Navigate to language settings page - updated to show dialog
  void _navigateToLanguageSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const LanguagePage(isDialog: true),
          ),
        );
      },
    );
  }

  // This is a new method to show the SSS dialog
  void _showSSSDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const SSSPage(),
          ),
        );
      },
    );
  }

  // This is a new method to show the About Us dialog
  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const AboutUsDialog(),
          ),
        );
      },
    );
  }

  // This is a new method to show the Contact Us dialog
  void _showContactUsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const ContactUsPage(),
          ),
        );
      },
    );
  }

  // Show users management dialog
  void _showUsersManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const UsersPage(isDialog: true),
          ),
        );
      },
     );
    }
      

  // Show currency selection dialog
  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: CurrencyPage(
              isDialog: true,
              onCurrencySelected: (currency) {
                setState(() {
                  _selectedCurrency = currency;
                });
                InfoCard.showInfoCard(
                  context,
                  tr('currency_updated_success'),
                  Colors.green,
                  icon: Icons.check_circle,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Method to cancel membership - updated with improved sub-user synchronization
  void _cancelMembership() {
    // Store context reference to avoid BuildContext issues
    final BuildContext currentContext = context;
    
    // Show loading indicator
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Call user service to update membership status
    UserService().updateMembershipStatus('free').then((success) async {
      if (success) {
        // Also ensure parent membership status is propagated to all sub-users
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            // Create FirestoreService instance to update all sub-users
            final firestoreService = FirestoreService();
            await firestoreService.updateParentMembershipStatusForAllSubUsers(
              currentUser.uid, 
              'free'
            );
            debugPrint('Successfully propagated free status to all sub-users');
            
            // Verify the update worked by checking a sub-user
            try {
              QuerySnapshot subUsersSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .where('parentUserId', isEqualTo: currentUser.uid)
                  .limit(1)
                  .get();
                  
              if (subUsersSnapshot.docs.isNotEmpty) {
                String sampleSubUserId = subUsersSnapshot.docs.first.id;
                DocumentSnapshot verifyDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(sampleSubUserId)
                    .get();
                    
                if (verifyDoc.exists) {
                  Map<String, dynamic> verifyData = verifyDoc.data() as Map<String, dynamic>;
                  String updatedStatus = verifyData['parentMembershipStatus'] ?? 'unknown';
                  debugPrint('Verified sub-user status update: $updatedStatus');
                }
              }
            } catch (verifyError) {
              debugPrint('Error verifying sub-user update: $verifyError');
            }
          }
        } catch (propagationError) {
          debugPrint('Error propagating free status to sub-users: $propagationError');
        }
      }
      
      // Close loading indicator - only if still mounted and context is valid
      if (mounted && Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }

      if (success) {
        // Check if widget is still mounted before using context
        if (mounted) {
          // Show success message with a slight delay to allow UI to update
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              InfoCard.showInfoCard(
                currentContext,
                tr('membership_cancelled_success'),
                Colors.green,
                icon: Icons.check_circle,
              );
              
              // Navigate to membership details screen after a short delay
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  MembershipDetailsScreen.show(currentContext, membershipStatus: 'free');
                }
              });
            }
          });
        } else {
          // If widget is unmounted, navigate directly without using the old context
          MembershipDetailsScreen.show(currentContext, membershipStatus: 'free');
        }
      } else {
        // Only show error if widget is still mounted
        if (mounted) {
          InfoCard.showInfoCard(
            currentContext,
            tr('membership_cancelled_error'),
            Colors.red,
            icon: Icons.error_outline,
          );
        }
      }
    }).catchError((error) {
      // Close loading indicator - only if still mounted and context is valid
      if (mounted && Navigator.canPop(currentContext)) {
        Navigator.pop(currentContext);
      }
      
      // Only show error if widget is still mounted
      if (mounted) {
        InfoCard.showInfoCard(
          currentContext,
          tr('membership_cancelled_error_details', args: [error.toString()]),
          Colors.red,
          icon: Icons.error_outline,
        );
      }
    });
  }

  // Show cancel membership dialog with updated implementation
  void _showCancelMembershipDialog() {
    final BuildContext currentContext = context;
    showDialog(
      context: currentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(tr('cancel_membership_title')),
          content: Text(tr('cancel_membership_confirmation')),
          actions: [
            TextButton(
              child: Text(tr('cancel')),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(tr('confirm'), style: const TextStyle(color: Colors.red)),
              onPressed: () {
                // Close dialog first
                Navigator.of(dialogContext).pop();
                // Then cancel membership
                _cancelMembership();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and determine if we're on mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(currentPage: '/settings'),
      body: SafeArea(
        // Remove the Center and ConstrainedBox, use LayoutBuilder instead
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section with title and search
                    _buildHeaderSection(context),
                    
                    SizedBox(height: ResponsiveBreakpoints.getSectionSpacing(context)),
                    
                    // Responsive layout for settings sections
                    if (isTablet && screenWidth >= 800) 
                      _buildTabletLayout(context)
                    else if (isMobile || screenWidth < 800)
                      _buildMobileLayout(context)
                    else
                      _buildDesktopLayout(context),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  // New tablet layout method for medium sized screens
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure column children stretch
      children: [
        // First row with account and preferences sections side by side
        if (_showAccountSettings || _showPreferences)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showAccountSettings)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildAccountSettingsSection(context),
                  ),
                ),
              if (_showPreferences)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildPreferencesSection(context),
                  ),
                ),
            ],
          ),
          
        SizedBox(height: ResponsiveBreakpoints.getSectionSpacing(context)),
        
        // Second row with privacy and help sections side by side
        if (_showPrivacy || _showHelp)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showPrivacy)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildPrivacySettingsSection(context),
                  ),
                ),
              if (_showHelp)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildHelpAndSupportSection(context),
                  ),
                ),
            ],
          ),
          
        SizedBox(height: ResponsiveBreakpoints.getSectionSpacing(context)),
        
        // System management in full width
        if (_showSystemManagement)
          _buildSystemManagementSection(context),
      ],
    );
  }

  // Updated desktop layout method for larger screens
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure column children stretch
      children: [
        // First row with account, preferences and privacy sections
        if (_showAccountSettings || _showPreferences || _showPrivacy)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showAccountSettings)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildAccountSettingsSection(context),
                  ),
                ),
              if (_showPreferences)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildPreferencesSection(context),
                  ),
                ),
              if (_showPrivacy)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _buildPrivacySettingsSection(context),
                  ),
                ),
            ],
          ),
          
        SizedBox(height: ResponsiveBreakpoints.getSectionSpacing(context)),
        
        // Second row with help and system management
        if (_showHelp || _showSystemManagement)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showHelp)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildHelpAndSupportSection(context),
                  ),
                ),
              if (_showSystemManagement)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _buildSystemManagementSection(context),
                  ),
                ),
              if (!_showSystemManagement)
                Expanded(flex: 1, child: Container()),
            ],
          ),
      ],
    );
  }

  // Updated mobile layout method for small screens
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure column children stretch
      children: [
        // All sections stacked vertically for mobile
        if (_showAccountSettings)
          _buildAccountSettingsSection(context),
          
        SizedBox(height: ResponsiveBreakpoints.getSectionSpacing(context)),
        
        if (_showPreferences)
          _buildPreferencesSection(context),
          
        SizedBox(height: ResponsiveBreakpoints.getSectionSpacing(context)),
        
        if (_showPrivacy)
          _buildPrivacySettingsSection(context),
          
        SizedBox(height: ResponsiveBreakpoints.getSectionSpacing(context)),
        
        if (_showHelp)
          _buildHelpAndSupportSection(context),
          
        SizedBox(height: ResponsiveBreakpoints.getSectionSpacing(context)),
        
        if (_showSystemManagement)
          _buildSystemManagementSection(context),
      ],
    );
  }

  // Updated header section to stretch fully
  Widget _buildHeaderSection(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and search in a column on mobile, row on larger screens
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with animation
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                )),
                child: Text(
                  tr('settings_title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: isMobile ? 24 : null, // Smaller text on mobile
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle with fade animation
              FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                  ),
                ),
                child: Text(
                  tr('settings_subtitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 14 : null, // Smaller text on mobile
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Search field takes full width on mobile
              FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity, // Ensure full width
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: tr('settings_search_placeholder'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
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
            ],
          )
        else
          // For tablets and desktops: horizontal layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded( // Wrap in Expanded to allow stretching
                flex: 2, // Give more space to title section
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
                      child: Text(
                        tr('settings_title'),
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
                        tr('settings_subtitle'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: ResponsiveBreakpoints.isTablet(context) ? 250 : 300,
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
                      hintText: tr('settings_search_placeholder'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
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
            ],
          ),
      ],
    );
  }

  // Updated section building methods to ensure full width
  Widget _buildAccountSettingsSection(BuildContext context) {
    // Only render if this section should be shown based on search
    if (!_showAccountSettings) return const SizedBox.shrink();
    
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('settings_category_account'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : null, // Smaller on mobile
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, // Ensure container takes full width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure columns stretch
              children: [
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_edit_profile'),
                  subtitle: tr('settings_item_edit_profile_desc'),
                  icon: Icons.person_outline,
                  color: Colors.cyan,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showProfileEditDialog();
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_change_password'),
                  subtitle: tr('settings_item_change_password_desc'),
                  icon: Icons.password,
                  color: Colors.amber,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showPasswordChangeDialog();
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_cancel_membership'),
                  subtitle: tr('settings_item_cancel_membership_desc'),
                  icon: Icons.card_membership,
                  color: Colors.deepOrange,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showCancelMembershipDialog();
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_logout'),
                  subtitle: tr('settings_item_logout_desc'),
                  icon: Icons.logout,
                  color: Colors.orange,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLogoutConfirmationDialog();
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_delete_account'),
                  subtitle: tr('settings_item_delete_account_desc'),
                  icon: Icons.delete_forever,
                  color: Colors.red,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    if (!_showPreferences) return const SizedBox.shrink();
    
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('settings_category_preferences'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : null, // Smaller on mobile
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, // Ensure container takes full width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure columns stretch
              children: [
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_multilanguage'),
                  subtitle: tr('settings_item_multilanguage_desc'),
                  icon: Icons.language,
                  color: Colors.teal,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _navigateToLanguageSettings,
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_currency'),
                  subtitle: tr('settings_item_currency_desc', args: [_selectedCurrency['code']]),
                  icon: Icons.currency_exchange,
                  color: Colors.amber,
                  trailing: _isLoadingCurrency 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${_selectedCurrency['symbol']} (${_selectedCurrency['code']})",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                  onTap: _showCurrencyDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrivacySettingsSection(BuildContext context) {
    // Only render if this section should be shown based on search
    if (!_showPrivacy) return const SizedBox.shrink();
    
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('settings_category_privacy'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : null, // Smaller on mobile
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, // Ensure container takes full width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure columns stretch
              children: [
                // Add Privacy Policy tile
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_privacy_policy'),
                  subtitle: tr('settings_item_privacy_policy_desc'),
                  icon: Icons.privacy_tip,
                  color: Colors.red,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _navigateToPrivacyPolicy(context);
                  },
                ),
                const Divider(height: 1),
                // Add KVKK and GDPR compliance tile
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_kvkk'),
                  subtitle: tr('settings_item_kvkk_desc'),
                  icon: Icons.verified_user,
                  color: Colors.blue,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _navigateToKVKK(context);
                  },
                ),
                const Divider(height: 1),
                // Add User Manual tile
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_terms'),
                  subtitle: tr('settings_item_terms_desc'),
                  icon: Icons.description_outlined,
                  color: Colors.indigo,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _navigateToUserManual(context);
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_cookie_policy'),
                  subtitle: tr('settings_item_cookie_policy_desc'),
                  icon: Icons.cookie,
                  color: Colors.brown,
                  trailing: Switch(
                    value: cookieConsent,
                    onChanged: (value) {
                      setState(() => cookieConsent = value);
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  onTap: () {
                    _showCookiePolicyDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Navigation methods for the privacy section - updated to show dialogs
  void _navigateToPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const PrivacyPolicyPage(isDialog: true),
          ),
        );
      },
    );
  }

  void _navigateToKVKK(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const KVKKPage(isDialog: true),
          ),
        );
      },
    );
  }

  void _navigateToUserManual(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const UserAgreementPage(isDialog: true),
          ),
        );
      },
    );
  }

  Widget _buildHelpAndSupportSection(BuildContext context) {
    // Only render if this section should be shown based on search
    if (!_showHelp) return const SizedBox.shrink();
    
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('settings_category_help'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : null, // Smaller on mobile
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, // Ensure container takes full width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure columns stretch
              children: [
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_faq'),
                  subtitle: tr('settings_item_faq_desc'),
                  icon: Icons.help_outline,
                  color: Colors.green,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showSSSDialog();
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_contact_us'),
                  subtitle: tr('settings_item_contact_us_desc'),
                  icon: Icons.contact_support,
                  color: Colors.purple,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showContactUsDialog();
                  },
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_about_us'),
                  subtitle: tr('settings_item_about_us_desc'),
                  icon: Icons.info_outline,
                  color: Colors.blueGrey,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showAboutUsDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New method to build the System Management section
  Widget _buildSystemManagementSection(BuildContext context) {
    // Only render if this section should be shown based on search
    if (!_showSystemManagement) return const SizedBox.shrink();
    
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('settings_category_system'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : null, // Smaller on mobile
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, // Ensure container takes full width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make sure columns stretch
              children: [
                _buildSettingsTile(
                  context: context,
                  title: tr('settings_item_user_management'),
                  subtitle: tr('settings_item_user_management_desc'),
                  icon: Icons.people,
                  color: Colors.indigo,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showUsersManagementDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated settings tile to be responsive
  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: color.withOpacity(0.05),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.1),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(isMobile ? 4 : 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 20),
          ),
          title: isMobile 
            // Simpler title for mobile - without info icon to save space
            ? Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13, // Smaller on mobile
                ),
              )
            // Desktop/tablet view with info icon
            : Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Tooltip(
                    message: _getTooltipText(title),
                    preferBelow: false,
                    showDuration: const Duration(seconds: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: isMobile ? 11 : 12),
              maxLines: isMobile ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: trailing,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16, 
            vertical: isMobile ? 4 : 6
          ),
          dense: true,
          visualDensity: isMobile 
            ? const VisualDensity(horizontal: -1, vertical: -1) // More compact on mobile
            : VisualDensity.standard,
        ),
      ),
    );
  }
  
  // Helper method to get detailed tooltip text based on menu item title
  String _getTooltipText(String title) {
    // Get the right tooltip text based on the menu item
    if (title == tr('settings_item_edit_profile')) {
      return tr('tooltip_edit_profile', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_change_password')) {
      return tr('tooltip_change_password', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_cancel_membership')) {
      return tr('tooltip_cancel_membership', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_logout')) {
      return tr('tooltip_logout', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_delete_account')) {
      return tr('tooltip_delete_account', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_multilanguage')) {
      return tr('tooltip_multilanguage', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_currency')) {
      return tr('tooltip_currency', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_privacy_policy')) {
      return tr('tooltip_privacy_policy', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_kvkk')) {
      return tr('tooltip_kvkk', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_terms')) {
      return tr('tooltip_terms', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_cookie_policy')) {
      return tr('tooltip_cookie_policy', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_faq')) {
      return tr('tooltip_faq', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_contact_us')) {
      return tr('tooltip_contact_us', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_about_us')) {
      return tr('tooltip_about_us', args: [''], namedArgs: {});
    } else if (title == tr('settings_item_user_management')) {
      return tr('tooltip_user_management', args: [''], namedArgs: {});
    }
    
    // Default tooltip if no specific match
    return tr('tooltip_default', args: [''], namedArgs: {});
  }
  
  void _showDeleteAccountDialog(BuildContext context) {
    DeleteAccountDialog.showDeleteAccountDialog(context);
  }

  // Show cookie policy dialog
  void _showCookiePolicyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveBreakpoints.isMobile(context) ? 8 : 20, 
            vertical: ResponsiveBreakpoints.isMobile(context) ? 8 : 20
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.isMobile(context) 
                ? MediaQuery.of(context).size.width * 0.95
                : MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: const CookiesPage(isDialog: true),
          ),
        );
      },
    );
  }
  
  // Rest of the methods with similar responsive dialog patterns
  // ...existing code...
}