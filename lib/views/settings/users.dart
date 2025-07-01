import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleet/info_card.dart';
import '../../services/firestore_service.dart';

class UsersPage extends StatefulWidget {
  final bool isDialog;

  const UsersPage({Key? key, this.isDialog = false}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // Remove username controller as we'll extract it from email
  // final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  
  // Add scroll controller for the user list
  final ScrollController _userListScrollController = ScrollController();

  // Permission toggles for different pages - All set to true by default now
  Map<String, bool> permissions = {
    'users_permission_dashboard': true,
    'users_permission_department_position': true,
    'users_permission_list': true,
    'users_permission_contracts': true,
    'users_permission_orgchart': true,
    'users_permission_skills': true,
  };
  
  // Add a method to enforce permission dependencies - Still keep this logic even though all are true
  void _enforcePermissionDependencies(Map<String, bool> perms) {
    // If contracts is selected, list must be selected
    if (perms['users_permission_contracts'] == true) {
      perms['users_permission_list'] = true;
    }
    
    // If orgchart is selected, department_position must be selected
    if (perms['users_permission_orgchart'] == true) {
      perms['users_permission_department_position'] = true;
    }
  }
  
  // Helper to check if a permission should be disabled based on dependencies
  bool _isPermissionDisabled(String key, Map<String, bool> perms) {
    // Disable list permission when contracts is selected
    if (key == 'users_permission_list' && perms['users_permission_contracts'] == true) {
      return true;
    }
    
    // Disable department_position when orgchart is selected
    if (key == 'users_permission_department_position' && perms['users_permission_orgchart'] == true) {
      return true;
    }
    
    return false;
  }

  // Users list
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = []; // For search functionality
  
  // Pagination variables
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;
  String _searchQuery = '';

  // Add instance of FirestoreService
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    // Initialize search controller listener
    _searchController.addListener(_onSearchChanged);
    
    // Load users from Firestore
    _loadUsers();
  }

  @override
  void dispose() {
    // Remove username controller disposal
    // _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    _controller.dispose();
    _userListScrollController.dispose();
    super.dispose();
  }

  // Handle search query changes
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterUsers();
      _currentPage = 1; // Reset to first page when search changes
    });
  }

  // Filter users based on search query
  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      filteredUsers = List.from(users);
    } else {
      filteredUsers = users.where((user) {
        final username = user['username']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        return username.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList();
    }
    
    // Calculate total pages
    _totalPages = (filteredUsers.length / _pageSize).ceil();
    if (_totalPages < 1) _totalPages = 1;
    
    // Ensure current page is valid
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
  }

  // Get users for current page
  List<Map<String, dynamic>> _getCurrentPageUsers() {
    if (filteredUsers.isEmpty) return [];
    
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize > filteredUsers.length 
        ? filteredUsers.length 
        : startIndex + _pageSize;
        
    if (startIndex >= filteredUsers.length) return [];
    
    return filteredUsers.sublist(startIndex, endIndex);
  }
  
  // Navigate to next page
  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }
  
  // Navigate to previous page
  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }
  
  // Navigate to first page
  void _firstPage() {
    if (_currentPage != 1) {
      setState(() {
        _currentPage = 1;
      });
    }
  }
  
  // Navigate to last page
  void _lastPage() {
    if (_currentPage != _totalPages) {
      setState(() {
        _currentPage = _totalPages;
      });
    }
  }
  
  // Change page size
  void _changePageSize(int newSize) {
    setState(() {
      _pageSize = newSize;
      // Recalculate total pages
      _totalPages = (filteredUsers.length / _pageSize).ceil();
      if (_totalPages < 1) _totalPages = 1;
      
      // Adjust current page if needed
      if (_currentPage > _totalPages) {
        _currentPage = _totalPages;
      }
    });
  }

  // Get current parent user data for reference

  // Check if at least one permission is selected
  bool _isAtLeastOnePermissionSelected(Map<String, bool> perms) {
    return perms.values.any((selected) => selected);
  }

  Future<void> _addUser() async {
    // Since all permissions are auto-selected to true, 
    // we can skip the permissions check
    
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);
        
        // Get current user - we need this to create proper relationships
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception(tr('users_not_logged_in'));
        }
        
        // Store current user info
        final String currentUserId = currentUser.uid;
        final String? currentUserEmail = currentUser.email;
        
        if (currentUserEmail == null) {
          throw Exception(tr('users_admin_email_missing'));
        }
        
        final String email = _emailController.text.trim();
        final String password = _passwordController.text.trim();
        
        // Check if email is already in use among existing users
        if (users.any((user) => user['email'] == email)) {
          throw Exception(tr('users_email_already_exists'));
        }
        
        // Before creating the sub-user, ask admin for their password to enable re-authentication
        String? adminPassword = await _promptForAdminPassword(currentUserEmail);
        
        if (adminPassword == null || adminPassword.isEmpty) {
          setState(() => _isLoading = false);
          InfoCard.showInfoCard(
            context,
            tr('users_admin_password_required'),
            Colors.red,
            icon: Icons.error,
          );
          return;
        }
        
        // Show a progress dialog during the creation process
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text(tr('users_creating')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(tr('users_creating_message')),
                ],
              ),
            ),
          ),
        );
        
        // Create sub-user using our service method that handles re-authentication
        final Map<String, dynamic> newUserData = await _firestoreService.createSubUser(
          email: email,
          password: password,
          permissions: Map<String, bool>.from(permissions), // All true by default
          adminEmail: currentUserEmail,
          adminPassword: adminPassword,
        );
        
        // Close the progress dialog
        if (mounted) Navigator.of(context).pop();
        
        // After sub-user creation, verify we're still logged in as the admin
        if (_auth.currentUser == null || _auth.currentUser!.uid != currentUserId) {
          // Session was lost despite our efforts - we need to redirect to login
          InfoCard.showInfoCard(
            context,
            tr('users_session_lost') + " " + tr('users_login_again'),
            Colors.red,
            icon: Icons.error,
            duration: const Duration(seconds: 10),
          );
          
          // Navigate to login screen after showing the message
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          });
          return;
        }
        
        // Add to local list and update UI
        setState(() {
          users.add(newUserData);
          
          // Sort users to maintain consistent order (parent first, then sub-users by creation time)
          users.sort((a, b) {
            // Parent user (admin) always comes first
            if (a['isAdmin'] == true) return -1;
            if (b['isAdmin'] == true) return 1;
            
            // Then sort by creation timestamp if available
            final aTime = a['createdAt'] ?? 0;
            final bTime = b['createdAt'] ?? 0;
            return bTime.compareTo(aTime); // Newest first
          });

          // Reset form
          _emailController.clear();
          _passwordController.clear();
          // All permissions remain true
          permissions = {
            'users_permission_dashboard': true,
            'users_permission_department_position': true,
            'users_permission_list': true,
            'users_permission_contracts': true,
            'users_permission_orgchart': true,
            'users_permission_skills': true,
          };
          
          _isLoading = false;
          
          // Update filtered users and pagination
          _filterUsers();
        });

        // Find the index of the newly added user
        final int newUserIndex = users.indexWhere((u) => u['userId'] == newUserData['userId']);
        if (newUserIndex >= 0) {
          // Schedule a microtask to scroll after the UI has been built
          Future.microtask(() {
            if (_userListScrollController.hasClients) {
              // Calculate position to scroll to
              _userListScrollController.animateTo(
                // Estimate the position based on item height
                newUserIndex * 100.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        // Show success message
        InfoCard.showInfoCard(
          context,
          tr('users_add_success'),
          Colors.green,
          icon: Icons.check_circle,
        );
      } on FirebaseAuthException catch (e) {
        // Handle any authentication errors
        String errorMessage;
        
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = tr('users_email_already_exists');
            break;
          case 'weak-password':
            errorMessage = tr('users_password_weak');
            break;
          case 'invalid-email':
            errorMessage = tr('users_email_invalid');
            break;
          case 'wrong-password':
            errorMessage = tr('users_admin_password_incorrect');
            break;
          default:
            errorMessage = tr('users_add_failed') + ': ${e.message}';
        }
        
        InfoCard.showInfoCard(
          context,
          errorMessage,
          Colors.red,
          icon: Icons.error,
        );
      } catch (e) {
        InfoCard.showInfoCard(
          context,
          '${tr('users_add_failed')}: $e',
          Colors.red,
          icon: Icons.error,
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Add a method to prompt for admin password
  Future<String?> _promptForAdminPassword(String adminEmail) async {
    final TextEditingController passwordController = TextEditingController();
    
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(tr('users_admin_verification')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('users_admin_password_needed')),
              SizedBox(height: 8),
              Text(
                tr('users_admin_verification_explanation'),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              Text(
                '${tr('users_admin_email')}: $adminEmail',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: tr('users_admin_password'),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('users_cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(passwordController.text);
              },
              child: Text(tr('users_continue')),
            ),
          ],
        ),
      );
    } finally {
      passwordController.dispose();
    }
  }

  // Add a new method to toggle user status (activate/deactivate)
  Future<void> _toggleUserStatus(int index) async {
    try {
      setState(() => _isLoading = true);
      
      if (users[index].containsKey('userId')) {
        final String userId = users[index]['userId'];
        final bool newStatus = !(users[index]['status'] ?? true);
        
        // Update user status in Firestore
        await _firestore.collection('users').doc(userId).update({
          'status': newStatus,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        // Update local list
        setState(() {
          users[index]['status'] = newStatus;
          _isLoading = false;
        });
        
        // Show success message
        InfoCard.showInfoCard(
          context,
          newStatus 
            ? tr('users_activated_success') 
            : tr('users_deactivated_success'),
          Colors.green,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      InfoCard.showInfoCard(
        context,
        '${tr('users_status_toggle_failed')}: $e',
        Colors.red,
        icon: Icons.error,
      );
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          users = []; // Empty list if not authenticated
          filteredUsers = [];
          _totalPages = 1;
        });
        return;
      }
      
      // First get the parent user (current user) document
      List<Map<String, dynamic>> loadedUsers = [];
      
      try {
        final DocumentSnapshot currentUserDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (currentUserDoc.exists) {
          final data = currentUserDoc.data() as Map<String, dynamic>;
          loadedUsers.add({
            'username': data['username'] ?? currentUser.email?.split('@')[0] ?? 'Admin',
            'email': currentUser.email,
            'userId': currentUser.uid,
            'isAdmin': true, // Mark as admin/parent
            'permissions': data['permissions'] ?? {
              'users_permission_dashboard': true,
              'users_permission_department_position': true,
              'users_permission_list': true,
              'users_permission_contracts': true,
              'users_permission_orgchart': true,
              'users_permission_skills': true,
            },
            'createdAt': data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch 
                : DateTime.now().millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        print('Error loading current user data: $e');
        // Continue with empty parent user if this fails
      }
      
      // Then try to get sub-users with error handling
      try {
        // Get all users where parentUserId equals current user's ID
        final QuerySnapshot snapshot = await _firestore
            .collection('users')
            .where('parentUserId', isEqualTo: currentUser.uid)
            .get();
        
        // Add all sub-users
        snapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Only add active users or include a status flag
          final bool status = data['status'] as bool? ?? true;
          
          loadedUsers.add({
            'username': data['username'],
            'email': data['email'],
            'userId': doc.id,
            'isSubUser': true,
            'parentUserId': data['parentUserId'],
            'createdBy': data['creatorUsername'] ?? data['creatorEmail'] ?? 'Unknown',
            'permissions': data['permissions'] ?? {},
            'status': status,
            'createdAt': data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch 
                : DateTime.now().millisecondsSinceEpoch,
          });
        });
      } catch (e) {
        print('Error loading sub-users: $e');
        // Show a specific error message for permissions issues
        if (e is FirebaseException && e.code == 'permission-denied') {
          InfoCard.showInfoCard(
            context,
            tr('users_permission_error') + " " + tr('users_refresh'),
            Colors.orange,
            icon: Icons.warning,
          );
        }
        // We'll continue with just the parent user if this fails
      }
      
      // Sort users - admin first, then by creation date (newest first)
      loadedUsers.sort((a, b) {
        if (a['isAdmin'] == true) return -1;
        if (b['isAdmin'] == true) return 1;
        
        final aTime = a['createdAt'] ?? 0;
        final bTime = b['createdAt'] ?? 0;
        return bTime.compareTo(aTime); // Newest first
      });
      
      setState(() {
        users = loadedUsers;
        _filterUsers(); // This sets filteredUsers and calculates pagination
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  // Helper method to determine if we're on a small screen
  bool get isSmallScreen => MediaQuery.of(context).size.width < 600;
  
  // Helper method to determine if we're on a medium screen
  bool get isMediumScreen => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  
  // Helper method for responsive padding
  EdgeInsets get responsivePadding {
    if (isSmallScreen) {
      return const EdgeInsets.all(12);
    } else if (isMediumScreen) {
      return const EdgeInsets.all(18);
    } else {
      return const EdgeInsets.all(24);
    }
  }
  
  // Helper method for responsive font size scaling
  double responsiveFontSize(double baseSize) {
    if (isSmallScreen) {
      return baseSize * 0.85;
    } else if (isMediumScreen) {
      return baseSize * 0.92;
    } else {
      return baseSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isDialog
        ? Stack(
            children: [
              _buildContent(),
              // Add X button in the top-right corner
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: Colors.grey[700],
                  tooltip: tr('users_close'),
                ),
              ),
            ],
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(tr('users_title')),
            ),
            body: _buildContent(),
          );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: isSmallScreen ? 20 : 32),

              // Main content in scrollable area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add new user section
                      _buildAddUserSection(),
                      SizedBox(height: isSmallScreen ? 20 : 32),
                      
                      // User list section
                      _buildUsersListSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people,
                  size: isSmallScreen ? 28 : 36,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  tr('users_title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: responsiveFontSize(isSmallScreen ? 22 : 28),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
            ),
          ),
          child: Text(
            tr('users_subtitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: responsiveFontSize(isSmallScreen ? 14 : 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddUserSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add,
                      size: isSmallScreen ? 20 : 24,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('users_add_new'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: responsiveFontSize(isSmallScreen ? 18 : 22),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: tr('users_email'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.email_outlined),
                        helperText: tr('users_email_username_helper', args: ['Username will be created from email address']),
                        helperMaxLines: 2,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: isSmallScreen ? 12 : 16
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('users_email_required');
                        }
                        // Email format validation
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value)) {
                          return tr('users_email_invalid');
                        }
                        // Check if email already exists
                        if (users.any((user) => user['email'] == value)) {
                          return tr('users_email_already_exists');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: tr('users_password'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: isSmallScreen ? 12 : 16
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('users_password_required');
                        } else if (value.length < 6) {
                          return tr('users_password_min_length');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addUser,
                        icon: _isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(tr('users_add_button')),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20, 
                            vertical: isSmallScreen ? 12 : 15
                          ),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }

  // Keep this method but it won't be displayed in the UI
  Widget _buildPermissionCheckboxes() {
    bool hasPermission = _isAtLeastOnePermissionSelected(permissions);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasPermission ? Colors.grey.shade200 : Colors.red.shade300),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate how many permission items can fit in a row
              // For small screens use 1 item per row, for larger screens calculate based on width
              int itemsPerRow = isSmallScreen ? 1 : (constraints.maxWidth / 200).floor();
              itemsPerRow = itemsPerRow < 1 ? 1 : itemsPerRow;
              
              // Calculate item width based on available space
              double itemWidth = isSmallScreen 
                  ? constraints.maxWidth 
                  : (constraints.maxWidth / itemsPerRow) - 16;
              
              return Wrap(
                spacing: 16,
                runSpacing: 8,
                children: permissions.keys.map((String key) {
                  // Display the translated label but keep using the fixed key
                  String displayLabel = tr(key);
                  
                  // Check if this permission should be disabled
                  bool isDisabled = _isPermissionDisabled(key, permissions);
                  
                  // Add dependency indicator to permission labels if needed
                  if (isDisabled) {
                    displayLabel += ' *';
                  }
                  
                  return Container(
                    width: itemWidth,
                    decoration: BoxDecoration(
                      color: permissions[key]! 
                          ? (isDisabled ? Colors.blue.withOpacity(0.05) : Colors.blue.withOpacity(0.1))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: permissions[key]! 
                            ? (isDisabled ? Colors.grey.withOpacity(0.3) : Colors.blue.withOpacity(0.3))
                            : Colors.transparent
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        displayLabel,
                        style: TextStyle(
                          fontWeight: permissions[key]! ? FontWeight.bold : FontWeight.normal,
                          fontSize: responsiveFontSize(isSmallScreen ? 13 : 14),
                          color: isDisabled && permissions[key]! ? Colors.grey[600] : null,
                        ),
                      ),
                      value: permissions[key],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: isDisabled ? Colors.grey : Colors.blue,
                      dense: isSmallScreen,
                      onChanged: isDisabled ? null : (bool? value) {
                        setState(() {
                          permissions[key] = value ?? false;
                          
                          // Enforce dependencies when opportunities permission changes
                          if (key == 'users_permission_opportunities') {
                            _enforcePermissionDependencies(permissions);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              );
            }
          ),
        ),
        
        // Add warning message if no permission is selected
        if (!hasPermission)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16.0),
            child: Text(
              tr('users_permission_required'),
              style: TextStyle(
                color: Colors.red,
                fontSize: responsiveFontSize(12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
        // Add dependency explanation
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 16.0),
          child: Text(
            '* ${tr('users_permission_dependency_note')}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: responsiveFontSize(11),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersListSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.group,
                      size: isSmallScreen ? 20 : 24,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('users_existing'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: responsiveFontSize(isSmallScreen ? 18 : 22),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Add refresh button
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.orange),
                    onPressed: _loadUsers,
                    tooltip: tr('users_refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Add search bar
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: tr('users_search_placeholder'),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: isSmallScreen ? 12 : 14
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey.shade600),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              _isLoading && filteredUsers.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User list
                        _buildUserList(),
                        
                        // No results message
                        if (filteredUsers.isEmpty && !_isLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    tr('users_no_search_results'),
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(16),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Pagination controls
                        if (filteredUsers.isNotEmpty)
                          _buildPaginationControls(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
    }
  
  Widget _buildUserList() {
    return ListView.separated(
      controller: _userListScrollController, 
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _getCurrentPageUsers().length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _getCurrentPageUsers()[index];
        final bool isActive = user['status'] != false; // Consider null as active
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.grey.shade50 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? Colors.grey.shade200 : Colors.grey.shade300),
          ),
          child: _buildUserListTile(user, isActive)
        );
      },
    );
  }
  
  Widget _buildUserListTile(Map<String, dynamic> user, bool isActive) {
    // For small screens, use a more compact layout
    if (isSmallScreen) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header row with icon and name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: user['isAdmin'] == true
                        ? Colors.purple.withOpacity(0.1)
                        : (isActive 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user['isAdmin'] == true
                        ? Icons.admin_panel_settings 
                        : (isActive ? Icons.person : Icons.person_off),
                    size: 20,
                    color: user['isAdmin'] == true
                        ? Colors.purple 
                        : (isActive ? Colors.blue : Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['username'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 15,
                          color: isActive ? Colors.black : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (user['email'] != null)
                        Text(
                          user['email'],
                          style: TextStyle(
                            fontSize: 12, 
                            color: isActive ? Colors.grey[600] : Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Status chips
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 36.0),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (user['isSubUser'] == true)
                    Chip(
                      label: Text(
                        tr('users_sub_user'),
                        style: TextStyle(
                          fontSize: 10, 
                          color: isActive ? Colors.white : Colors.grey.shade300,
                        ),
                      ),
                      backgroundColor: isActive ? Colors.teal : Colors.grey,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    ),
                  if (!isActive)
                    Chip(
                      label: Text(
                        tr('users_inactive'),
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: Colors.red.shade300,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    ),
                ],
              ),
            ),
            
            // Created by info
            if (user['isSubUser'] == true && user['createdBy'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 36.0),
                child: Text(
                  '${tr('users_created_by')}: ${user['createdBy']}',
                  style: TextStyle(
                    fontSize: 11, 
                    color: isActive ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ),
            
            // Hide permissions chips by commenting out this section
            /*
            // Permissions chips
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 36.0),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: (user['permissions'] as Map<dynamic, dynamic>)
                    .map((k, v) => MapEntry<String, bool>(k.toString(), v as bool))
                    .entries
                    .where((e) => e.value)
                    .map((e) => Chip(
                          label: Text(
                            tr(e.key), // Translate the permission key
                            style: TextStyle(
                              fontSize: 10, 
                              color: isActive ? Colors.white : Colors.grey.shade300,
                            ),
                          ),
                          backgroundColor: isActive 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ))
                    .toList(),
              ),
            ),
            */
            
            // Action buttons - remove edit button, keep only activate/deactivate
            if (user['isAdmin'] != true) // Prevent modifying the admin user
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Remove Edit button
                    // if (isActive)
                    //   OutlinedButton.icon(
                    //     icon: Icon(Icons.edit, size: 16),
                    //     label: Text(tr('users_edit'), style: TextStyle(fontSize: 12)),
                    //     onPressed: () => _editUserPermissions(user),
                    //     style: OutlinedButton.styleFrom(
                    //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    //       side: BorderSide(color: Colors.blue),
                    //       foregroundColor: Colors.blue,
                    //     ),
                    //   ),
                    // SizedBox(width: 8),
                    // Toggle status button
                    OutlinedButton.icon(
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 16,
                      ),
                      label: Text(
                        isActive ? tr('users_deactivate') : tr('users_activate'),
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _toggleUserStatus(
                        users.indexOf(user) // Find the actual index in the full list
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: BorderSide(color: isActive ? Colors.orange : Colors.green),
                        foregroundColor: isActive ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(
                        tr('users_admin_nodelete'),
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: Colors.purple.shade300,
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.admin_panel_settings, size: 14, color: Colors.white),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } else {
      // For larger screens, use the original ListTile layout with some improvements
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: 8
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: user['isAdmin'] == true
                ? Colors.purple.withOpacity(0.1)
                : (isActive 
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            user['isAdmin'] == true
                ? Icons.admin_panel_settings 
                : (isActive ? Icons.person : Icons.person_off),
            color: user['isAdmin'] == true
                ? Colors.purple 
                : (isActive ? Colors.blue : Colors.grey),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user['username'],
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: isActive ? Colors.black : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (user['isSubUser'] == true)
              Chip(
                label: Text(
                  tr('users_sub_user'),
                  style: TextStyle(
                    fontSize: 10, 
                    color: isActive ? Colors.white : Colors.grey.shade300,
                  ),
                ),
                backgroundColor: isActive ? Colors.teal : Colors.grey,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              ),
            if (!isActive)
              Chip(
                label: Text(
                  tr('users_inactive'),
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: Colors.red.shade300,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user['email'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  user['email'],
                  style: TextStyle(
                    fontSize: 12, 
                    color: isActive ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ),
            if (user['isSubUser'] == true && user['createdBy'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${tr('users_created_by')}: ${user['createdBy']}',
                  style: TextStyle(
                    fontSize: 12, 
                    color: isActive ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ),
            // Hide permissions chips by commenting out this section
            /*
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (user['permissions'] as Map<dynamic, dynamic>)
                  .map((k, v) => MapEntry<String, bool>(k.toString(), v as bool))
                  .entries
                  .where((e) => e.value)
                  .map((e) => Chip(
                        label: Text(
                          tr(e.key), // Translate the permission key
                          style: TextStyle(
                            fontSize: 10, 
                            color: isActive ? Colors.white : Colors.grey.shade300,
                          ),
                        ),
                        backgroundColor: isActive 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ))
                  .toList(),
            ),
            */
          ],
        ),
        trailing: user['isAdmin'] != true // Prevent modifying the admin user
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Remove edit button
                  // if (isActive)
                  //   IconButton(
                  //     icon: Icon(
                  //       Icons.edit,
                  //       color: Colors.blue,
                  //     ),
                  //     onPressed: () => _editUserPermissions(user),
                  //     tooltip: tr('users_edit_permissions_tooltip'),
                  //   ),
                  // Toggle status button
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.block : Icons.check_circle,
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                    onPressed: () => _toggleUserStatus(
                      users.indexOf(user) // Find the actual index in the full list
                    ),
                    tooltip: isActive 
                        ? tr('users_deactivate') 
                        : tr('users_activate'),
                  ),
                ],
              )
            : Tooltip(
                message: tr('users_admin_nodelete'),
                child: const Icon(Icons.admin_panel_settings, color: Colors.grey),
              ),
      );
    }
  }
  
  Widget _buildPaginationControls() {
    // On small screens, we'll use a more compact pagination control
    if (isSmallScreen) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Records info
            Text(
              tr('users_total_records', namedArgs: {'count': filteredUsers.length.toString()}),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Pagination buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // First page
                IconButton(
                  icon: const Icon(Icons.first_page, size: 20),
                  onPressed: _currentPage > 1 ? _firstPage : null,
                  tooltip: tr('users_first_page'),
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey.shade300,
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
                
                // Previous page
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _currentPage > 1 ? _previousPage : null,
                  tooltip: tr('users_previous_page'),
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey.shade300,
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
                
                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                
                // Next page
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _currentPage < _totalPages ? _nextPage : null,
                  tooltip: tr('users_next_page'),
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey.shade300,
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
                
                // Last page
                IconButton(
                  icon: const Icon(Icons.last_page, size: 20),
                  onPressed: _currentPage < _totalPages ? _lastPage : null,
                  tooltip: tr('users_last_page'),
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey.shade300,
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Page size selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr('users_per_page'),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _pageSize,
                  underline: Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  onChanged: (int? newValue) {
                    if (newValue != null) _changePageSize(newValue);
                  },
                  items: [5, 10, 20, 50]
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // For larger screens, use the original layout with three columns
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Records info
            Text(
              tr('users_total_records', args: [filteredUsers.length.toString()]),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            
            // Pagination buttons
            Row(
              children: [
                // First page
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: _currentPage > 1 ? _firstPage : null,
                  tooltip: tr('users_first_page'),
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey.shade300,
                ),
                
                // Previous page
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1 ? _previousPage : null,
                  tooltip: tr('users_previous_page'),
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey.shade300,
                ),
                
                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                
                // Next page
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages ? _nextPage : null,
                  tooltip: tr('users_next_page'),
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey.shade300,
                ),
                
                // Last page
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: _currentPage < _totalPages ? _lastPage : null,
                  tooltip: tr('users_last_page'),
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey.shade300,
                ),
              ],
            ),
            
            // Page size selector
            Row(
              children: [
                Text(
                  tr('users_per_page'),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _pageSize,
                  underline: Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  onChanged: (int? newValue) {
                    if (newValue != null) _changePageSize(newValue);
                  },
                  items: [5, 10, 20, 50]
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  // Add this method to edit user permissions
  Future<void> _editUserPermissions(Map<String, dynamic> user) async {
    // Create a copy of the user's permissions to edit
    Map<String, bool> userPermissions = Map<String, bool>.from(
      (user['permissions'] as Map<dynamic, dynamic>)
          .map((k, v) => MapEntry<String, bool>(k.toString(), v as bool))
    );
    
    // Show dialog to edit permissions
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('users_edit_permissions')),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tr('users_editing_for')}: ${user['username']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: userPermissions.keys.map((String key) {
                          String displayLabel = tr(key);
                          
                          // Check if this permission should be disabled
                          bool isDisabled = _isPermissionDisabled(key, userPermissions);
                          
                          // Add dependency indicator to permission labels if needed
                          if (isDisabled) {
                            displayLabel += ' *';
                          }
                          
                          return Container(
                            width: 180,
                            decoration: BoxDecoration(
                              color: userPermissions[key]! 
                                  ? (isDisabled ? Colors.blue.withOpacity(0.05) : Colors.blue.withOpacity(0.1))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: userPermissions[key]! 
                                    ? (isDisabled ? Colors.grey.withOpacity(0.3) : Colors.blue.withOpacity(0.3))
                                    : Colors.transparent
                              ),
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                displayLabel,
                                style: TextStyle(
                                  fontWeight: userPermissions[key]! ? FontWeight.bold : FontWeight.normal,
                                  color: isDisabled && userPermissions[key]! ? Colors.grey[600] : null,
                                ),
                              ),
                              value: userPermissions[key],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: isDisabled ? Colors.grey : Colors.blue,
                              onChanged: isDisabled ? null : (bool? value) {
                                setState(() {
                                  userPermissions[key] = value ?? false;
                                  
                                  // Enforce dependencies when opportunities permission changes
                                  if (key == 'users_permission_opportunities') {
                                    _enforcePermissionDependencies(userPermissions);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Add permission validation message
                    if (!_isAtLeastOnePermissionSelected(userPermissions))
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          tr('users_permission_required'),
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                    // Add dependency explanation
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        '* ${tr('users_permission_dependency_note')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('users_cancel')),
          ),
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  // Validate at least one permission is selected
                  if (!_isAtLeastOnePermissionSelected(userPermissions)) {
                    InfoCard.showInfoCard(
                      context,
                      tr('users_permission_required'),
                      Colors.red,
                      icon: Icons.error,
                    );
                    return;
                  }
                  
                  // Ensure permission dependencies are enforced before saving
                  _enforcePermissionDependencies(userPermissions);
                  
                  Navigator.of(context).pop(userPermissions);
                },
                child: Text(tr('users_save')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
      
    // If dialog was dismissed or canceled
    if (result == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Get user ID
      final String userId = user['userId'];
      
      // Update permissions in Firestore
      await _firestore.collection('users').doc(userId).update({
        'permissions': result,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local list
      setState(() {
        // Find user in the original list
        final int userIndex = users.indexWhere((u) => u['userId'] == userId);
        if (userIndex != -1) {
          users[userIndex]['permissions'] = result;
          
          // Re-filter to update filtered users
          _filterUsers();
        }
        _isLoading = false;
      });
      
      // Show success message
      InfoCard.showInfoCard(
        context,
        tr('users_permissions_updated'),
        Colors.green,
        icon: Icons.check_circle,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      InfoCard.showInfoCard(
        context,
        '${tr('users_update_failed')}: $e',
        Colors.red,
        icon: Icons.error,
      );
    }
    }
   }