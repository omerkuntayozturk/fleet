import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleet/info_card.dart';
import '../services/auth_service.dart';
import '../views/settings/edit_profile.dart';
import '../views/settings/settings_page.dart';
import '../views/settings/sss.dart';
import '../services/auth_state_manager.dart';

// Define notification model for better type safety
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  final String? itemId;
  final bool isRead;
  
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.itemId,
    this.isRead = false,
  });
  
  // Get appropriate icon based on notification type
  IconData get icon {
    switch (type) {
      case NotificationType.newOpportunity:
        return Icons.lightbulb_outline;
      case NotificationType.wonOpportunity:
        return Icons.check_circle_outline;
      case NotificationType.lowStock:
        return Icons.inventory_2_outlined;
      case NotificationType.newProduct:
        return Icons.add_shopping_cart;
      case NotificationType.newContact:
        return Icons.person_add_alt_1;
    }
  }
  
  // Get appropriate color based on notification type
  Color get color {
    switch (type) {
      case NotificationType.newOpportunity:
        return Colors.blue;
      case NotificationType.wonOpportunity:
        return Colors.green;
      case NotificationType.lowStock:
        return Colors.red;
      case NotificationType.newProduct:
        return Colors.purple;
      case NotificationType.newContact:
        return Colors.orange;
    }
  }
}

// Enum for notification types
enum NotificationType {
  newOpportunity,
  wonOpportunity,
  lowStock,
  newProduct,
  newContact
}

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  const TopBar({super.key});
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showUserMenu = false;
  late AnimationController _animController;
  final LayerLink _userProfileLayerLink = LayerLink();
  OverlayEntry? _userProfileOverlay;
  
  // User information
  String _username = '';
  String _userRole = '';
  bool _isSubUser = false;
  bool _isDataLoaded = false;
  
  // Stream subscription for auth state changes
  StreamSubscription<User?>? _authStateSubscription;

  // Define breakpoints for responsive design
  static const double _mobileBreakpoint = 600;
  static const double _smallMobileBreakpoint = 360;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    // Initial load of user data
    _getCurrentUser();
    
    // Set up auth state listener to refresh data when auth state changes
    _setupAuthListener();
  }
  
  void _setupAuthListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in or token refreshed
        debugPrint('TopBar: Auth state changed - user logged in: ${user.uid}');
        // Force fetch fresh data with delay to ensure Firestore is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _getCurrentUser(forceRefresh: true);
        });
      } else {
        // User logged out
        debugPrint('TopBar: Auth state changed - user logged out');
        _resetUserData();
      }
    });
  }
  
  void _resetUserData() {
    if (mounted) {
      setState(() {
        _username = '';
        _userRole = '';
        _isSubUser = false;
        _isDataLoaded = false;
      });
    }
  }
  
  Future<void> _getCurrentUser({bool forceRefresh = false}) async {
    // Don't try to access Firestore if we're in the logout process
    if (AuthStateManager.isLoggingOut) return;
    
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        _resetUserData();
        return;
      }
      
      if (mounted && !AuthStateManager.isLoggingOut) {
        debugPrint('TopBar: Fetching user data for: ${user.uid}');
        
        // Add a small delay to ensure Firestore data is ready
        if (forceRefresh) {
          await Future.delayed(const Duration(milliseconds: 500));
          // Forcibly refresh token to ensure permissions are current
          await user.getIdToken(true);
          debugPrint('TopBar: Forcibly refreshed auth token');
        }
        
        // Get additional user information from Firestore with retries
        DocumentSnapshot? userDoc;
        
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            userDoc = await _firestore.collection('users').doc(user.uid).get();
            if (userDoc.exists) break;
            
            debugPrint('TopBar: User document not found, retrying (${attempt}/3)');
            await Future.delayed(Duration(milliseconds: 300 * attempt));
          } catch (e) {
            debugPrint('TopBar: Error fetching user document (attempt ${attempt}): $e');
            await Future.delayed(Duration(milliseconds: 300 * attempt));
          }
        }
        
        if (userDoc == null || !userDoc.exists) {
          debugPrint('TopBar: User document still not found after retries');
          if (mounted) {
            setState(() {
              _username = user.email?.split('@')[0] ?? tr('topbar_user');
              _userRole = tr('topbar_user_role');
              _isSubUser = false;
              _isDataLoaded = false;
            });
          }
          return;
        }
        
        if (mounted && !AuthStateManager.isLoggingOut) {
          final userData = userDoc.data() as Map<String, dynamic>;
          debugPrint('TopBar: Received user data: ${userData['username']}');
          debugPrint('TopBar: Is sub-user: ${userData['isSubUser'] ?? false}');
          
          setState(() {
            _isSubUser = userData['isSubUser'] ?? false;
            _username = userData['username'] ?? user.email?.split('@')[0] ?? 
                        (_isSubUser ? tr('topbar_user') : tr('topbar_admin'));
            
            // Update role text based on user type
            if (_isSubUser) {
              // For sub-users, show their specific role or just "User"
              _userRole = userData['role'] ?? tr('topbar_sub_user');
            } else {
              // For regular users/admins
              _userRole = tr('topbar_admin_role');
            }
            
            _isDataLoaded = true;
          });
          
          debugPrint('TopBar: Updated state - username: $_username, role: $_userRole, isSubUser: $_isSubUser');
        } else if (mounted) {
          setState(() {
            _username = tr('topbar_admin');
            _userRole = tr('topbar_admin_role');
            _isSubUser = false;
            _isDataLoaded = false;
          });
        }
      }
    } catch (e) {
      // Only log errors if we're not in the logout process
      if (!AuthStateManager.isLoggingOut) {
        debugPrint('Error getting current user: $e');
        if (mounted) {
          setState(() {
            _username = tr('topbar_admin');
            _userRole = tr('topbar_admin_role');
            _isSubUser = false;
            _isDataLoaded = false;
          });
        }
      }
    }
  }
  
  @override
  void dispose() {
    _hideUserProfileDropdown();
    _animController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _hideUserProfileDropdown() {
    _userProfileOverlay?.remove();
    _userProfileOverlay = null;
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get available width
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isVerySmallMobile = screenWidth <= _smallMobileBreakpoint;
        final isMobile = screenWidth <= _mobileBreakpoint;
        
        return AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          // Remove titleSpacing for better control
          titleSpacing: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: tr('topbar_menu'),
              // Make touch target bigger on mobile
              padding: isMobile 
                  ? const EdgeInsets.all(12.0) 
                  : const EdgeInsets.all(8.0),
            ),
          ),
          title: _buildResponsiveTitle(context, isMobile, isVerySmallMobile),
          actions: [
            _buildResponsiveProfileButton(context, isMobile, isVerySmallMobile),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ),
        );
      }
    );
  }

  // Responsive title widget
  Widget _buildResponsiveTitle(BuildContext context, bool isMobile, bool isVerySmallMobile) {
    if (isVerySmallMobile) {
      // For very small screens, just show the logo
      return Container(
        constraints: const BoxConstraints(maxHeight: 60),
        child: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              tr('topbar_crm'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    } else if (isMobile) {
      // For mobile screens, make the title and logo smaller
      return Container(
        constraints: const BoxConstraints(maxHeight: 60),
        child: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  tr('topbar_crm'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isSubUser 
                      ? tr('topbar_user_panel')
                      : tr('topbar_admin_panel'),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // For larger screens, use the original layout
      return Container(
        constraints: const BoxConstraints(maxHeight: 60),
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  tr('topbar_crm'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _isSubUser 
                    ? tr('topbar_user_panel')
                    : tr('topbar_admin_panel'),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Responsive profile button
  Widget _buildResponsiveProfileButton(BuildContext context, bool isMobile, bool isVerySmallMobile) {
    return Padding(
      padding: EdgeInsets.only(right: isMobile ? 8.0 : 16.0),
      child: CompositedTransformTarget(
        link: _userProfileLayerLink,
        child: InkWell(
          onTap: _isDataLoaded
              ? () {
                  if (_showUserMenu) {
                    _hideUserProfileDropdown();
                  } else {
                    _showUserProfileDropdown(context);
                  }
                  
                  setState(() {
                    _showUserMenu = !_showUserMenu;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallMobile ? 6 : (isMobile ? 6 : 8),
              vertical: isVerySmallMobile ? 3 : 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: _isDataLoaded 
                ? _buildUserInfo(context, isMobile, isVerySmallMobile)
                : _buildLoadingInfo(context, isMobile, isVerySmallMobile),
          ),
        ),
      ),
    );
  }

  // User info for different screen sizes
  Widget _buildUserInfo(BuildContext context, bool isMobile, bool isVerySmallMobile) {
    if (isVerySmallMobile) {
      // For very small screens, just show the avatar icon
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 16,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: _showUserMenu ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
              size: 16,
            ),
          ),
        ],
      );
    } else if (isMobile) {
      // For mobile screens, show compact user info
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 16,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username.isEmpty ? tr('topbar_loading') : _username,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          AnimatedRotation(
            turns: _showUserMenu ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
              size: 18,
            ),
          ),
        ],
      );
    } else {
      // For larger screens, use the original layout with username and role
      return Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 18,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username.isEmpty ? tr('topbar_loading') : _username,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                _userRole.isEmpty ? tr('topbar_loading_role') : _userRole,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: _showUserMenu ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }
  }

  // Loading state for different screen sizes
  Widget _buildLoadingInfo(BuildContext context, bool isMobile, bool isVerySmallMobile) {
    if (isVerySmallMobile) {
      // Very compact loading for very small screens
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      );
    } else if (isMobile) {
      // Compact loading for mobile screens
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[400],
            size: 18,
          ),
        ],
      );
    } else {
      // Original loading for larger screens
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[400],
          ),
        ],
      );
    }
  }

  // Show user profile dropdown overlay with modern animation and responsive positioning
  void _showUserProfileDropdown(BuildContext context) {
    _hideUserProfileDropdown();
    _animController.forward(from: 0.0);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= _mobileBreakpoint;
    final isVerySmallMobile = screenWidth <= _smallMobileBreakpoint;
    
    _userProfileOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full screen gesture detector to close the dropdown when tapping outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _hideUserProfileDropdown();
                setState(() => _showUserMenu = false);
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The actual dropdown menu with responsive positioning
          Positioned(
            child: CompositedTransformFollower(
              link: _userProfileLayerLink,
              offset: isMobile 
                  ? Offset(isVerySmallMobile ? -80 : -60, kToolbarHeight - 10)
                  : const Offset(-20, kToolbarHeight - 10),
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.topRight,
              showWhenUnlinked: false,
              child: FadeTransition(
                opacity: _animController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {},
                      child: _buildSimpleUserProfileDropdown(context, isMobile),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_userProfileOverlay!);
  }

  // Simple user profile dropdown with responsive width
  Widget _buildSimpleUserProfileDropdown(BuildContext context, bool isMobile) {
    return Container(
      width: isMobile ? 160 : 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildMenuItems(context, isMobile),
        ),
      ),
    );
  }
  
  // Build menu items with responsive text size
  List<Widget> _buildMenuItems(BuildContext context, [bool isMobile = false]) {
    if (_isSubUser) {
      return [
        _buildSimpleMenuItem(
          context: context,
          icon: Icons.logout,
          title: tr('topbar_logout'),
          onTap: () {
            _hideUserProfileDropdown();
            setState(() => _showUserMenu = false);
            _showLogoutConfirmation(context);
          },
          isLogout: true,
          isLastItem: true,
          isMobile: isMobile,
        ),
      ];
    } else {
      return [
        _buildSimpleMenuItem(
          context: context,
          icon: Icons.person_outline,
          title: tr('topbar_my_profile'),
          onTap: () {
            _hideUserProfileDropdown();
            setState(() => _showUserMenu = false);
            _showProfileEditDialog(context);
          },
          isMobile: isMobile,
        ),
        
        _buildSimpleMenuItem(
          context: context,
          icon: Icons.settings_outlined,
          title: tr('topbar_settings'),
          onTap: () {
            _hideUserProfileDropdown();
            setState(() => _showUserMenu = false);
            _showSettingsPage(context);
          },
          isMobile: isMobile,
        ),
        
        _buildSimpleMenuItem(
          context: context,
          icon: Icons.help_outline,
          title: tr('topbar_help'),
          onTap: () {
            _hideUserProfileDropdown();
            setState(() => _showUserMenu = false);
            _showSSSDialog(context);
          },
          isMobile: isMobile,
        ),
        
        Divider(color: Colors.grey[200], height: 1, thickness: 1),
        
        _buildSimpleMenuItem(
          context: context,
          icon: Icons.logout,
          title: tr('topbar_logout'),
          onTap: () {
            _hideUserProfileDropdown();
            setState(() => _showUserMenu = false);
            _showLogoutConfirmation(context);
          },
          isLogout: true,
          isLastItem: true,
          isMobile: isMobile,
        ),
      ];
    }
  }
  
  // Responsive menu item with smaller text and padding for mobile
  Widget _buildSimpleMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
    bool isLastItem = false,
    bool isMobile = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16, 
          vertical: isMobile ? 10 : 12
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: isLastItem 
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: isMobile ? 16 : 18,
              color: isLogout ? Colors.red : Theme.of(context).primaryColor,
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: isLogout ? Colors.red : Colors.grey[800],
                  fontWeight: isLogout ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showProfileEditDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth <= _mobileBreakpoint;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 20, 
            vertical: isMobile ? 10 : 20
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? screenWidth * 0.95 : screenWidth * 0.8,
              maxHeight: isMobile ? screenHeight * 0.9 : screenHeight * 0.85,
            ),
            child: ProfileEditDialog(
              onSave: (userData) {
                InfoCard.showInfoCard(
                  context,
                  tr('topbar_profile_updated_success'),
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

  void _showSettingsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _showSSSDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth <= _mobileBreakpoint;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 20, 
            vertical: isMobile ? 10 : 20
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? screenWidth * 0.95 : screenWidth * 0.8,
              maxHeight: isMobile ? screenHeight * 0.9 : screenHeight * 0.85,
            ),
            child: const SSSPage(),
          ),
        );
      },
    );
  }
  
  void _showLogoutConfirmation(BuildContext context) {
    // Store navigator instance for later use to avoid context issues
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('topbar_logout_confirmation_title')),
        content: Text(tr('topbar_logout_confirmation_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('topbar_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // First close the dialog
              Navigator.pop(dialogContext);
              
              try {
                // Set logging out state to prevent further Firestore access
                AuthStateManager.setLoggingOut(true);
                
                // Reset state variables before navigation
                _resetUserData();
                
                // Navigate to login screen BEFORE sign out to avoid permission issues
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                });
                
                // Then perform the sign out
                await Future.delayed(const Duration(milliseconds: 100));
                await _authService.signOut();
                
              } catch (e) {
                // Reset logging out state if sign out fails
                AuthStateManager.setLoggingOut(false);
                debugPrint('Error during logout: $e');
                
                // We already navigated away, so no need to show error message
              }
            },
            child: Text(tr('topbar_logout')),
          ),
        ],
      ),
    );
  }
}