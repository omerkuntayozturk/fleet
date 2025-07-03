import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/user_permissions_service.dart';
import '../core/routes.dart'; // Add this import

class SideMenu extends StatefulWidget {
  final String currentPage;
  
  const SideMenu({super.key, required this.currentPage}); // <-- required yaptık
  
  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  // Permission state variables
  bool _canAccessDashboard = true;
  bool _canAccessDepartmentPosition = false;
  bool _canAccessList = false;
  bool _canAccessContracts = false;
  bool _canAccessOrgChart = false;
  bool _canAccessSkills = false;
  bool _isLoadingPermissions = true;
  bool _isSubUser = false;
  bool _canAccessSystemMenu = true;
  
  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }
  
  // Load user permissions
  Future<void> _loadPermissions() async {
    setState(() => _isLoadingPermissions = true);
    
    try {
      // First check if user is a sub-user
      _isSubUser = await UserPermissionsService.isSubUser();
      print('Is sub-user: $_isSubUser');
      
      // For both sub-users and regular users, load specific permissions
      _canAccessDashboard = await UserPermissionsService.canAccessDashboard();
      _canAccessDepartmentPosition = await UserPermissionsService.canAccessDepartmentPosition();
      _canAccessList = await UserPermissionsService.canAccessList();
      _canAccessContracts = await UserPermissionsService.canAccessContracts();
      _canAccessOrgChart = await UserPermissionsService.canAccessOrgChart();
      _canAccessSkills = await UserPermissionsService.canAccessSkills();
      
      // Only regular users can access system menu
      _canAccessSystemMenu = !_isSubUser;
      
      // Print permissions for debugging
      print('User permissions loaded:');
      print('Is sub-user: $_isSubUser');
      print('Dashboard: $_canAccessDashboard');
      print('Department & Position: $_canAccessDepartmentPosition');
      print('List: $_canAccessList');
      print('Contracts: $_canAccessContracts');
      print('Org Chart: $_canAccessOrgChart');
      print('Skills: $_canAccessSkills');
      print('System Menu: $_canAccessSystemMenu');
    } catch (e) {
      // If there's an error, default to showing only essential menu items
      _canAccessDashboard = true;
      _canAccessDepartmentPosition = false;
      _canAccessList = false;
      _canAccessContracts = false;
      _canAccessOrgChart = false;
      _canAccessSkills = false;
      _canAccessSystemMenu = false; // On error, restrict system menu access
      print('Error loading permissions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPermissions = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    // Normalize currentPage for comparison (handles both '/list' and 'list')
    String normalizedCurrentPage = widget.currentPage;
    if (normalizedCurrentPage.startsWith('/')) {
      normalizedCurrentPage = normalizedCurrentPage.substring(1);
    }
    normalizedCurrentPage = normalizedCurrentPage.toLowerCase();

    return Drawer(
      elevation: 10,
      width: _getDrawerWidth(context),
      child: _isLoadingPermissions
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: theme.colorScheme.surface,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildResponsiveHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: isSmallScreen ? 8 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Functions Group
                            Padding(
                              padding: EdgeInsets.only(
                                left: isSmallScreen ? 12 : 16, 
                                top: 8, 
                                bottom: 8
                              ),
                              child: Text(
                                tr('sidemenu_main_functions'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.grey
                                )
                              ),
                            ),
                            
                            // Menu items with conditional rendering based on permissions
                            if (_canAccessDashboard)
                              _buildResponsiveMenuItem(
                                context, 
                                Icons.dashboard_rounded, 
                                tr('sidemenu_home'), 
                                '/',
                                isSelected: widget.currentPage == '/' || widget.currentPage == '', // Home
                              ),
                            if (_canAccessOrgChart)
                              _buildResponsiveMenuItem(
                                context, 
                                Icons.inventory_2_rounded, 
                                tr('sidemenu_list'), 
                                '/list',
                                isSelected: widget.currentPage == '/list' || widget.currentPage == 'list',
                              ),
                                                            _buildResponsiveMenuItem(
                                context, 
                                Icons.inventory_2_rounded, 
                                tr('sidemenu_detail'), 
                                '/vehicles',
                                isSelected: widget.currentPage == '/vehicles' || widget.currentPage == 'vehicles',
                              ),

                            if (_canAccessContracts)
                              _buildResponsiveMenuItem(
                                context, 
                                Icons.speed, // Changed icon to represent odometer/km reading better
                                'Km Kaydı', // Using explicit name instead of translation key for clarity
                                '/odometer',
                                isSelected: widget.currentPage == '/odometer' || 
                                           widget.currentPage == 'odometer' ||
                                           widget.currentPage == '/odometers' || 
                                           widget.currentPage == 'odometers',
                              ),
                            if (_canAccessOrgChart)
                              _buildResponsiveMenuItem(
                                context, 
                                Icons.build, // Changed icon to wrench/tools for service
                                'Servis Kaydı', // Using explicit name for clarity 
                                '/service',
                                isSelected: widget.currentPage == '/service' || 
                                           widget.currentPage == 'service' ||
                                           widget.currentPage == '/services' || 
                                           widget.currentPage == 'services',
                              ),
                            if (_canAccessDepartmentPosition)
                              _buildResponsiveMenuItem(
                                context, 
                                Icons.corporate_fare_rounded, 
                                'Sözleşmeler', 
                                '/contracts',
                                isSelected: widget.currentPage == '/contracts' || widget.currentPage == 'contracts',
                              ),                   
                            // System section with conditional rendering
                            if (_canAccessSystemMenu) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 8 : 16,
                                ),
                                child: const Divider(height: 1),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isSmallScreen ? 12 : 16, 
                                  top: 8, 
                                  bottom: 8
                                ),
                                child: Text(
                                  tr('sidemenu_system'),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12, 
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.grey
                                  )
                                ),
                              ),
                              _buildResponsiveMenuItem(
                                context, 
                                Icons.settings_rounded, 
                                tr('sidemenu_settings'), 
                                '/settings',
                                isSelected: widget.currentPage == '/settings' || widget.currentPage == 'settings',
                              ),
                              _buildResponsiveMenuItem(
                                context, 
                                Icons.star_rounded, 
                                tr('sidemenu_subscription'), 
                                '/subscription',
                                isSelected: widget.currentPage == '/subscription' || widget.currentPage == 'subscription',
                                badge: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildResponsiveFooter(context),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Calculates drawer width based on screen size
  double _getDrawerWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // Use percentage-based width with min/max constraints
    if (width < 360) {
      return width * 0.85; // Very small screens
    } else if (width < 600) {
      return width * 0.75; // Mobile phones
    } else if (width < 900) {
      return 320; // Tablets
    } else {
      return 350; // Desktop and large tablets
    }
  }
  
  Widget _buildResponsiveHeader(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    // Use a more reliable approach for sizing the header
    final headerHeight = isSmallScreen 
      ? (size.height * 0.15).clamp(160.0, 200.0)  // Increased height values
      : (size.height * 0.18).clamp(180.0, 240.0); 
    
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withBlue(theme.colorScheme.primary.blue + 20),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: isSmallScreen ? 100 : 150,
              height: isSmallScreen ? 100 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min, // Use min size to prevent overflow
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: isSmallScreen ? 20 : 28, // Further reduced size
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: isSmallScreen ? 24 : 34, // Adjusted icon size
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 10), // Further reduced spacing
                    Row(
                      children: [
                        Icon(
                          Icons.dashboard,
                          color: Colors.white,
                          size: isSmallScreen ? 16 : 18, // Smaller icon
                        ),
                        SizedBox(width: isSmallScreen ? 5 : 7),
                        Flexible(
                          child: Text(
                            tr('sidemenu_crm_admin_panel'),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16, // Smaller font
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 3 : 4), // Minimal spacing
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 7 : 9, 
                        vertical: isSmallScreen ? 2 : 3,  // Minimal padding
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tr('sidemenu_welcome'),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11, // Smaller font
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveMenuItem(
    BuildContext context, 
    IconData icon, 
    String label, 
    String route, 
    {bool isSelected = false, bool badge = false}
  ) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 8, 
        vertical: isSmallScreen ? 1 : 2
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        dense: isSmallScreen,
        visualDensity: isSmallScreen 
            ? VisualDensity.compact 
            : VisualDensity.comfortable,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 0 : 2,
        ),
        leading: Icon(
          icon, 
          color: isSelected ? theme.colorScheme.primary : null,
          size: isSmallScreen ? 22 : 24,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge) ...[
              SizedBox(width: isSmallScreen ? 6 : 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 4 : 6, 
                  vertical: isSmallScreen ? 1 : 2
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('sidemenu_pro_badge'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 9 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          // Close the drawer first to prevent UI issues
          Navigator.pop(context);
          
          // Handle navigation using named routes
          switch (route) {
            case '/':
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              break;
            case '/vehicles':
              Navigator.pushReplacementNamed(context, AppRoutes.vehicles);
              break;
            case '/settings':
              Navigator.pushReplacementNamed(context, AppRoutes.settings);
              break;
            case '/subscription':
              Navigator.pushReplacementNamed(context, AppRoutes.subscription);
              break;
            case '/service':
              Navigator.pushReplacementNamed(context, AppRoutes.service);
              break;
            case '/odometer':
              Navigator.pushReplacementNamed(context, AppRoutes.odometer);
              break;
            case '/contracts':
              Navigator.pushReplacementNamed(context, AppRoutes.contracts);
              break;
            default:
              Navigator.pushReplacementNamed(context, route);
              break;
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  Widget _buildResponsiveFooter(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12 : 16, 
        horizontal: isSmallScreen ? 12 : 16
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline, 
            size: isSmallScreen ? 14 : 16,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Flexible(
            child: Text(
              tr('sidemenu_version_info'),
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}