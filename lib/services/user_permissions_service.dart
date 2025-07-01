import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service to handle user permissions throughout the app
class UserPermissionsService {
  // Keys for SharedPreferences
  static const String _isSubUserKey = 'is_sub_user';
  // Updated keys to match Firestore data structure
  static const String _canAccessDashboardKey = 'users_permission_dashboard';
  static const String _canAccessDepartmentPositionKey = 'users_permission_department_position';
  static const String _canAccessListKey = 'users_permission_list';
  static const String _canAccessContractsKey = 'users_permission_contracts';
  static const String _canAccessOrgchartKey = 'users_permission_orgchart';
  static const String _canAccessSkillsKey = 'users_permission_skills';
  static const String _lastUpdatedKey = 'permissions_last_updated';
  static const String _currentUserIdKey = 'current_permissions_user_id';

  /// Fetches user permissions from Firestore and stores them in SharedPreferences
  static Future<void> fetchAndStoreUserPermissions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Cannot fetch permissions: No user is signed in');
        return;
      }

      // Force token refresh to ensure we have fresh permissions
      try {
        await user.getIdToken(true);
        debugPrint('Auth token refreshed before fetching permissions');
      } catch (tokenError) {
        debugPrint('Error refreshing auth token: $tokenError');
        // Continue anyway
      }

      final prefs = await SharedPreferences.getInstance();
      
      // Store current user ID to validate permissions later
      await prefs.setString(_currentUserIdKey, user.uid);
      
      // Get user document from Firestore with retries
      DocumentSnapshot? userDoc;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userDoc.exists) break;
          
          debugPrint('User document not found, retrying (${attempt+1}/3)');
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        } catch (e) {
          debugPrint('Error fetching user document (attempt ${attempt+1}): $e');
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }
      }
      
      if (userDoc == null || !userDoc.exists) {
        debugPrint('User document does not exist in Firestore after retries');
        // Clear any existing permissions
        await _clearPermissions(prefs);
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Check if this is a sub-user
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      await prefs.setBool(_isSubUserKey, isSubUser);
      
      if (isSubUser) {
        // For sub-users, get permissions from the userData
        final permissions = userData['permissions'] as Map<String, dynamic>? ?? {};
        
        // Log the raw permissions for debugging
        debugPrint('Raw sub-user permissions: $permissions');
        
        // Store individual permissions using the correct keys from Firestore
        // Explicitly cast each permission to bool to prevent type issues
        await prefs.setBool(_canAccessDashboardKey, 
            permissions[_canAccessDashboardKey] == true);
        await prefs.setBool(_canAccessDepartmentPositionKey, 
            permissions[_canAccessDepartmentPositionKey] == true);
        await prefs.setBool(_canAccessListKey, 
            permissions[_canAccessListKey] == true);
        await prefs.setBool(_canAccessContractsKey, 
            permissions[_canAccessContractsKey] == true);
        await prefs.setBool(_canAccessOrgchartKey, 
            permissions[_canAccessOrgchartKey] == true);
        await prefs.setBool(_canAccessSkillsKey, 
            permissions[_canAccessSkillsKey] == true);
        
        // Debug logging of permissions as they're set in SharedPreferences
        debugPrint('Storing sub-user permissions in SharedPreferences:');
        debugPrint('Dashboard: ${permissions[_canAccessDashboardKey] == true}');
        debugPrint('Department & Position: ${permissions[_canAccessDepartmentPositionKey] == true}');
        debugPrint('List: ${permissions[_canAccessListKey] == true}');
        debugPrint('Contracts: ${permissions[_canAccessContractsKey] == true}');
        debugPrint('Org Chart: ${permissions[_canAccessOrgchartKey] == true}');
        debugPrint('Skills: ${permissions[_canAccessSkillsKey] == true}');
        
        // If this is a sub-user, also make sure the parent membership status is cached
        if (userData['parentUserId'] != null) {
          final String parentUserId = userData['parentUserId'];
          // Check if we need to refresh parent membership status
          final needsRefresh = userData['parentMembershipCachedAt'] == null || 
              userData['parentMembershipStatus'] == null;
              
          if (needsRefresh) {
            try {
              // Try to directly query parent document
              final parentDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(parentUserId)
                  .get();
                  
              if (parentDoc.exists) {
                final parentData = parentDoc.data() as Map<String, dynamic>;
                final parentStatus = parentData['membershipStatus'] as String? ?? 'free';
                
                // Update the sub-user document with parent membership status
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                      'parentMembershipStatus': parentStatus,
                      'parentMembershipCachedAt': FieldValue.serverTimestamp(),
                    });
                    
                debugPrint('Updated parent membership status cache: $parentStatus');
              }
            } catch (e) {
              debugPrint('Error refreshing parent membership status: $e');
              // Non-critical error, continue
            }
          }
        }
      } else {
        // For regular users, grant all permissions
        await prefs.setBool(_canAccessDashboardKey, true);
        await prefs.setBool(_canAccessDepartmentPositionKey, true);
        await prefs.setBool(_canAccessListKey, true);
        await prefs.setBool(_canAccessContractsKey, true);
        await prefs.setBool(_canAccessOrgchartKey, true);
        await prefs.setBool(_canAccessSkillsKey, true);
      }
      
      // Store last updated timestamp
      await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
      
      // Verify the permissions were stored correctly
      debugPrint('Verifying stored permissions:');
      debugPrint('Is sub-user: ${prefs.getBool(_isSubUserKey)}');
      debugPrint('Dashboard: ${prefs.getBool(_canAccessDashboardKey)}');
      debugPrint('Department & Position: ${prefs.getBool(_canAccessDepartmentPositionKey)}');
      debugPrint('List: ${prefs.getBool(_canAccessListKey)}');
      debugPrint('Contracts: ${prefs.getBool(_canAccessContractsKey)}');
      debugPrint('Org Chart: ${prefs.getBool(_canAccessOrgchartKey)}');
      debugPrint('Skills: ${prefs.getBool(_canAccessSkillsKey)}');
      
      debugPrint('User permissions successfully stored for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error fetching and storing user permissions: $e');
      // In case of error, don't update permissions
    }
  }
  
  /// Clear all permissions from SharedPreferences
  static Future<void> _clearPermissions(SharedPreferences prefs) async {
    await prefs.setBool(_isSubUserKey, false);
    await prefs.setBool(_canAccessDashboardKey, true); // Default to true
    await prefs.setBool(_canAccessDepartmentPositionKey, false);
    await prefs.setBool(_canAccessListKey, false);
    await prefs.setBool(_canAccessContractsKey, false);
    await prefs.setBool(_canAccessOrgchartKey, false);
    await prefs.setBool(_canAccessSkillsKey, false);
  }

  /// Checks if current user is a sub-user
  static Future<bool> isSubUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate user ID to prevent permission leakage
      if (!await _validateCurrentUser(prefs)) {
        // User has changed, re-fetch permissions
        await fetchAndStoreUserPermissions();
      }
      
      return prefs.getBool(_isSubUserKey) ?? false;
    } catch (e) {
      debugPrint('Error checking if user is sub-user: $e');
      return false; // Default to false in case of error
    }
  }

  /// Checks if user can access dashboard
  static Future<bool> canAccessDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate user ID to prevent permission leakage
      if (!await _validateCurrentUser(prefs)) {
        // User has changed, re-fetch permissions
        await fetchAndStoreUserPermissions();
      }
      
      return prefs.getBool(_canAccessDashboardKey) ?? true; // Default to true
    } catch (e) {
      debugPrint('Error checking dashboard access: $e');
      return true; // Default to true in case of error
    }
  }

  /// Checks if user can access department position
  static Future<bool> canAccessDepartmentPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate user ID to prevent permission leakage
      if (!await _validateCurrentUser(prefs)) {
        // User has changed, re-fetch permissions
        await fetchAndStoreUserPermissions();
      }
      
      // For a sub-user, check stored permission
      if (await isSubUser()) {
        return prefs.getBool(_canAccessDepartmentPositionKey) ?? false;
      }
      // Regular users always have access
      return true;
    } catch (e) {
      debugPrint('Error checking department position access: $e');
      return false; // Default to false in case of error
    }
  }

  /// Checks if user can access list
  static Future<bool> canAccessList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate user ID to prevent permission leakage
      if (!await _validateCurrentUser(prefs)) {
        // User has changed, re-fetch permissions
        await fetchAndStoreUserPermissions();
      }
      
      // For a sub-user, check stored permission
      if (await isSubUser()) {
        return prefs.getBool(_canAccessListKey) ?? false;
      }
      // Regular users always have access
      return true;
    } catch (e) {
      debugPrint('Error checking list access: $e');
      return false; // Default to false in case of error
    }
  }

  /// Checks if user can access contracts
  static Future<bool> canAccessContracts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate user ID to prevent permission leakage
      if (!await _validateCurrentUser(prefs)) {
        // User has changed, re-fetch permissions
        await fetchAndStoreUserPermissions();
      }
      
      // For a sub-user, check stored permission
      if (await isSubUser()) {
        return prefs.getBool(_canAccessContractsKey) ?? false;
      }
      // Regular users always have access
      return true;
    } catch (e) {
      debugPrint('Error checking contracts access: $e');
      return false; // Default to false in case of error
    }
  }

  /// Checks if user can access org chart
  static Future<bool> canAccessOrgChart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate user ID to prevent permission leakage
      if (!await _validateCurrentUser(prefs)) {
        // User has changed, re-fetch permissions
        await fetchAndStoreUserPermissions();
      }
      
      // For a sub-user, check stored permission
      if (await isSubUser()) {
        return prefs.getBool(_canAccessOrgchartKey) ?? false;
      }
      // Regular users always have access
      return true;
    } catch (e) {
      debugPrint('Error checking org chart access: $e');
      return false; // Default to false in case of error
    }
  }

  /// Checks if user can access skills
  static Future<bool> canAccessSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate user ID to prevent permission leakage
      if (!await _validateCurrentUser(prefs)) {
        // User has changed, re-fetch permissions
        await fetchAndStoreUserPermissions();
      }
      
      // For a sub-user, check stored permission
      if (await isSubUser()) {
        return prefs.getBool(_canAccessSkillsKey) ?? false;
      }
      // Regular users always have access
      return true;
    } catch (e) {
      debugPrint('Error checking skills access: $e');
      return false; // Default to false in case of error
    }
  }
  
  /// Refreshes permissions from Firestore if they're older than the specified duration
  static Future<void> refreshPermissionsIfNeeded({Duration maxAge = const Duration(hours: 1)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate current user ID
      if (!await _validateCurrentUser(prefs)) {
        // User has changed, force refresh
        await fetchAndStoreUserPermissions();
        return;
      }
      
      final lastUpdatedStr = prefs.getString(_lastUpdatedKey);
      
      if (lastUpdatedStr == null) {
        // No stored permissions, fetch them
        await fetchAndStoreUserPermissions();
        return;
      }
      
      final lastUpdated = DateTime.parse(lastUpdatedStr);
      final now = DateTime.now();
      
      if (now.difference(lastUpdated) > maxAge) {
        // Permissions are older than maxAge, refresh them
        await fetchAndStoreUserPermissions();
      }
    } catch (e) {
      debugPrint('Error refreshing permissions: $e');
    }
  }
  
  /// Clears all stored permissions (useful for logout)
  static Future<void> clearStoredPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearPermissions(prefs);
      await prefs.remove(_lastUpdatedKey);
      await prefs.remove(_currentUserIdKey);
      debugPrint('Cleared all stored user permissions on logout');
    } catch (e) {
      debugPrint('Error clearing stored permissions: $e');
    }
  }
  
  /// Validate that stored permissions belong to the current user
  static Future<bool> _validateCurrentUser(SharedPreferences prefs) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user is signed in, permissions are invalid');
        return false;
      }
      
      final storedUserId = prefs.getString(_currentUserIdKey);
      if (storedUserId == null) {
        debugPrint('No stored user ID found, permissions need refresh');
        return false;
      }
      
      if (storedUserId != user.uid) {
        debugPrint('User ID mismatch: stored=$storedUserId, current=${user.uid}');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error validating current user: $e');
      return false;
    }
  }
}
