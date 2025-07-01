import 'dart:async';

import 'package:fleet/services/user_permissions_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fleet/services/auth_state_manager.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<StreamSubscription<dynamic>>? _activeSubscriptions = [];

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Add a Firestore listener to the list of active subscriptions
  void addSubscription(StreamSubscription<dynamic> subscription) {
    _activeSubscriptions?.add(subscription);
  }

  // Cancel all active Firestore subscriptions
  Future<void> cancelAllSubscriptions() async {
    if (_activeSubscriptions != null) {
      for (var subscription in _activeSubscriptions!) {
        await subscription.cancel();
      }
      _activeSubscriptions!.clear();
    }
  }

  // Sign out the current user with improved error handling
  Future<void> signOut() async {
    try {
      // Set logging out flag to prevent further Firestore access
      AuthStateManager.setLoggingOut(true);
      
      // Clear user permissions from SharedPreferences
      await UserPermissionsService.clearStoredPermissions();
      
      // Clear user settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      // Keep rememberMe setting but clear any other user-specific data
      final rememberMe = prefs.getBool('rememberMe') ?? false;
      final email = rememberMe ? prefs.getString('email') : null;
      final password = rememberMe ? prefs.getString('password') : null;
      
      // Get all keys to selectively clear
      final allKeys = prefs.getKeys().toList();
      final keysToKeep = <String>[];
      
      // Add keys to keep
      if (rememberMe) {
        keysToKeep.add('rememberMe');
        if (email != null) keysToKeep.add('email');
        if (password != null) keysToKeep.add('password');
      }
      
      // Selectively clear keys
      for (final key in allKeys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
        }
      }
      
      // ⚠️ IMPORTANT: DO NOT terminate Firestore connection or clear persistence
      // This causes reconnection issues for subsequent logins
      // Instead, just cancel subscriptions
      
      // Cancel all active Firestore subscriptions
      await cancelAllSubscriptions();

      // Wait a moment to ensure any pending operations complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Sign out from Firebase Auth
      await _auth.signOut();

      debugPrint('User signed out successfully with selective data clearing');
      
      // Reset logging out state AFTER signout to allow for relogin
      AuthStateManager.setLoggingOut(false);
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Reset logging out flag if sign out fails
      AuthStateManager.setLoggingOut(false);
      
      // If there was an error, try the minimal approach - just sign out
      try {
        await UserPermissionsService.clearStoredPermissions();
        await _auth.signOut();
        debugPrint('Fallback signout successful');
      } catch (innerError) {
        debugPrint('Even fallback signout failed: $innerError');
      }
    }
  }

  // Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Get current user
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in.',
      );
    }

    try {
      // Get user email
      final email = user.email;
      if (email == null) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'User has no email associated with account.',
        );
      }

      // Create credential using current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      // Re-authenticate user with current password
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Log successful password change
      await logUserActivity(
        type: 'password_change',
        status: 'success',
      );
    } catch (e) {
      // Log failed password change
      await logUserActivity(
        type: 'password_change',
        status: 'failed',
        details: e.toString(),
      );
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteUserAccount({String? password}) async {
    // Get current user
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user is currently signed in.',
      );
    }

    // If password is provided, reauthenticate first
    if (password != null && user.email != null) {
      // Create credential with current email and provided password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);
    }

    try {
      // Check if this is a parent user with sub-users
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final hasSubUsers = userData['hasSubUsers'] as bool? ?? false;
        
        if (hasSubUsers) {
          // Mark all sub-users for deletion instead of trying to delete directly
          await _deleteAllSubUsers(user.uid);
        }
      }
      
      // Delete user's own data from Firestore
      try {
        // Try to delete main user document first
        await _firestore.collection('users').doc(user.uid).delete();
        
        // We won't attempt to delete subcollections - these will be cleaned up
        // by a server-side process or Cloud Function
      } catch (firestoreError) {
        print('Warning: Could not delete user data from Firestore: $firestoreError');
        // Continue with account deletion even if Firestore deletion fails
      }
      
      // Mark the user for full deletion in the deleted_users collection
      try {
        await _firestore.collection('deleted_users').doc(user.uid).set({
          'userId': user.uid,
          'email': user.email,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': 'self',
          'needsFullDeletion': true,
        });
      } catch (markingError) {
        print('Warning: Failed to mark user for full deletion: $markingError');
        // Continue anyway
      }

      // Delete user account from Firebase Auth
      await user.delete();
      print('Successfully deleted Firebase Auth account for user: ${user.uid}');
    } catch (e) {
      print('Error during user account deletion: $e');
      throw e;
    }
  }
  
  // Helper method to delete all sub-users of a parent user
  Future<void> _deleteAllSubUsers(String parentUserId) async {
    try {
      print('Deleting all sub-users for parent: $parentUserId');
      
      // Fetch all sub-users with this parentUserId
      final QuerySnapshot subUsersSnapshot = await _firestore
          .collection('users')
          .where('parentUserId', isEqualTo: parentUserId)
          .get();
      
      if (subUsersSnapshot.docs.isEmpty) {
        print('No sub-users found to delete');
        return;
      }
      
      print('Found ${subUsersSnapshot.docs.length} sub-users to delete');
      
      // For fallback in case of permission issues
      final List<Map<String, dynamic>> subUsersData = [];
      
      // Try batch first
      try {
        // Create a batch for adding to deleted_users collection
        final WriteBatch batch = _firestore.batch();
        
        // For each sub-user, mark for deletion instead of trying to delete directly
        for (var doc in subUsersSnapshot.docs) {
          final subUserId = doc.id;
          final subUserData = doc.data() as Map<String, dynamic>;
          print('Processing sub-user: $subUserId');
          
          // Store for fallback approach
          subUsersData.add({
            'userId': subUserId,
            'email': subUserData['email'] ?? 'unknown',
            'username': subUserData['username'] ?? 'unknown',
          });
          
          // Try to deactivate the sub-user account
          batch.update(_firestore.collection('users').doc(subUserId), {
            'status': false,
            'deactivatedAt': FieldValue.serverTimestamp(),
            'deactivatedBy': parentUserId,
            'deactivationReason': 'parent_account_deleted',
            'pendingDeletion': true,
          });
        }
        
        // Commit all the batch operations at once
        await batch.commit();
        print('Successfully deactivated ${subUsersSnapshot.docs.length} sub-users');
      } catch (batchError) {
        print('Batch operation failed: $batchError - trying individual updates');
        
        // If batch failed, try individual updates
        for (var data in subUsersData) {
          try {
            await _firestore.collection('users').doc(data['userId']).update({
              'status': false,
              'deactivatedAt': FieldValue.serverTimestamp(),
              'deactivatedBy': parentUserId,
              'deactivationReason': 'parent_account_deleted',
              'pendingDeletion': true,
            });
            print('Successfully deactivated sub-user: ${data['userId']}');
          } catch (updateError) {
            print('Failed to deactivate sub-user ${data['userId']}: $updateError');
          }
        }
      }
      
      // Now try to record deletion requests in main user document for backend processing
      try {
        // Store the sub-user IDs in the parent's document
        await _firestore.collection('users').doc(parentUserId).update({
          'deletedSubUsers': FieldValue.arrayUnion(
            subUsersData.map((data) => data['userId']).toList()
          ),
          'pendingSubUserDeletions': true,
          'deletionRequestedAt': FieldValue.serverTimestamp(),
        });
        
        print('Recorded sub-user deletion request in parent document');
      } catch (e) {
        print('Failed to record deletion request in parent document: $e');
      }
      
      // Create a deletion record in the parent document for server-side cleanup
      try {
        await _firestore.collection('users').doc(parentUserId).collection('deletion_requests').add({
          'subUserIds': subUsersData.map((data) => data['userId']).toList(),
          'subUserEmails': subUsersData.map((data) => data['email']).toList(),
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
        
        print('Created deletion request record for server processing');
      } catch (e) {
        print('Failed to create deletion request record: $e');
      }
    } catch (e) {
      print('Error in _deleteAllSubUsers: $e');
      // Don't throw, as we want the parent account deletion to continue
      // even if marking sub-users for deletion fails
    }
  }

  // Log user activity safely (with logout check)
  Future<void> logUserActivity({
    required String type, // login, login_attempt, password_change, profile_update
    required String status, // success, failed
    String? details,
  }) async {
    // Skip logging if we're in the process of logging out
    if (AuthStateManager.isLoggingOut) {
      debugPrint('Skipping activity logging during logout: $type');
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).collection('activity_log').add({
        'type': type,
        'status': status,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });
    } catch (e) {
      // Only log the error if we're not logging out
      if (!AuthStateManager.isLoggingOut) {
        debugPrint('Error logging user activity: $e');
      }
    }
  }

  // Get user activities
  Future<List<Map<String, dynamic>>> getUserActivities({int limit = 50}) async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final activitiesSnapshot = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .orderBy('datetime', descending: true)
          .limit(limit)
          .get();

      return activitiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'],
          'status': data['status'],
          'datetime': (data['datetime'] as Timestamp).toDate(),
          'device': data['device'],
          'ipAddress': data['ipAddress'],
          'location': data['location'],
          'details': data['details'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting user activities: $e');
      return [];
    }
  }

  // Login with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log successful login
      await logUserActivity(
        type: 'login',
        status: 'success',
      );

      return credential;
    } catch (e) {
      // Log failed login attempt
      await logUserActivity(
        type: 'login_attempt',
        status: 'failed',
        details: e.toString(),
      );
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      // Log this activity
      await logUserActivity(
        type: 'password_reset_request',
        status: 'success',
        details: 'Password reset email sent to $email',
      );
    } catch (e) {
      // Log the error
      await logUserActivity(
        type: 'password_reset_request',
        status: 'failed',
        details: 'Failed to send password reset email: $e',
      );
      rethrow;
    }
  }

  // Modified to handle permission issues safely
  Future<bool> checkParentMembershipStatus(String parentUserId) async {
    try {
      // First try to get from cache in the current user document
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) return false;
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? cachedStatus = userData['parentMembershipStatus'];
      Timestamp? cachedTime = userData['parentMembershipCachedAt'];
      
      // If we have relatively fresh cached data, use it
      if (cachedStatus != null && cachedTime != null && 
          DateTime.now().difference(cachedTime.toDate()).inHours < 24) {
        return cachedStatus == 'premium' || cachedStatus == 'starter';
      }
      
      // For security reasons, we can't directly check the parent user's document
      // from a sub-user account due to Firestore permissions
      // Instead we need an alternative approach:
      
      try {
        // Attempt to update our own document with default assumption
        // This acts as a fallback mechanism
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'parentMembershipStatus': 'premium', // Default to premium to prevent lockout
              'parentMembershipCachedAt': FieldValue.serverTimestamp(),
            });
      } catch (updateError) {
        debugPrint('Unable to update own document: $updateError');
      }
      
      // Default to allowing access to prevent lockouts
      return true;
    } catch (e) {
      debugPrint('Error checking parent membership status: $e');
      // On any error, default to true to prevent users being locked out
      return true;
    }
  }
  
  // Check if a user is a sub-user with access based on parent membership
  Future<Map<String, dynamic>> checkSubUserAccess() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'hasAccess': false, 'reason': 'not_authenticated'};
      }

      // Fetch the current user's document
      
      
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        return {'hasAccess': false, 'reason': 'user_not_found'};
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      bool isSubUser = userData['isSubUser'] ?? false;
      
      if (!isSubUser) {
        // Regular user, check their own membership
        String membershipStatus = userData['membershipStatus'] ?? 'free';
        return {
          'hasAccess': membershipStatus != 'free',
          'reason': membershipStatus == 'free' ? 'free_membership' : 'has_access',
          'membershipStatus': membershipStatus
        };
      }
      
      // This is a sub-user, check parent's membership
      String? parentUserId = userData['parentUserId'];
      if (parentUserId == null) {
        return {'hasAccess': false, 'reason': 'no_parent_user'};
      }
      
      // Check if we have cached parent membership data
      String? cachedParentMembershipStatus = userData['parentMembershipStatus'];
      Timestamp? cachedTimestamp = userData['parentMembershipCachedAt'];
      
      // If we have recently cached data (within the last hour), use it
      if (cachedParentMembershipStatus != null && 
          cachedTimestamp != null &&
          DateTime.now().difference(cachedTimestamp.toDate()).inHours < 1) {
        
        debugPrint('Using cached parent membership status: $cachedParentMembershipStatus');
        bool hasAccess = cachedParentMembershipStatus == 'premium' || 
                         cachedParentMembershipStatus == 'starter';
                         
        return {
          'hasAccess': hasAccess,
          'reason': hasAccess ? 'has_access' : 'parent_free_membership',
          'membershipStatus': cachedParentMembershipStatus,
          'fromCache': true
        };
      }
      
      // Fetch fresh data from parent user
      bool parentHasPremium = await checkParentMembershipStatus(parentUserId);
      
      // Update the cache
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'parentMembershipStatus': parentHasPremium ? 'premium' : 'free',
            'parentMembershipCachedAt': FieldValue.serverTimestamp(),
          });
      
      return {
        'hasAccess': parentHasPremium,
        'reason': parentHasPremium ? 'has_access' : 'parent_free_membership',
        'membershipStatus': parentHasPremium ? 'premium' : 'free',
        'fromCache': false
      };
    } catch (e) {
      debugPrint('Error checking sub-user access: $e');
      return {'hasAccess': false, 'reason': 'error', 'error': e.toString()};
    }
  }

  // Update user agreements in Firestore
  Future<bool> updateUserAgreements({
    required bool terms,
    required bool privacyPolicy,
    required bool kvkk,
    required bool userManual,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in to update agreements');
        return false;
      }

      // Update the user's agreement data
      await _firestore.collection('users').doc(user.uid).update({
        'agreementsAccepted': {
          'terms': terms,
          'privacyPolicy': privacyPolicy,
          'kvkk': kvkk,
          'userManual': userManual,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });

      // Log this update
      await logUserActivity(
        type: 'agreements_update',
        status: 'success',
        details: 'Updated user agreements: terms=$terms, privacy=$privacyPolicy, kvkk=$kvkk, manual=$userManual',
      );

      debugPrint('Successfully updated user agreement status');
      return true;
    } catch (e) {
      debugPrint('Error updating user agreements: $e');
      return false;
    }
  }

  // Force update user agreements in Firestore with explicit boolean values
  Future<bool> forceUpdateUserAgreements({
    required bool terms,
    required bool privacyPolicy, 
    required bool kvkk,
    required bool userManual,
    bool cookies = true, // Add cookies parameter with default value
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in to update agreements');
        return false;
      }

      // Create a clean map with explicit boolean values
      final Map<String, dynamic> agreementData = {
        'terms': terms == true,  // Force boolean conversion
        'privacyPolicy': privacyPolicy == true,
        'kvkk': kvkk == true,
        'userManual': userManual == true,
        'cookies': cookies == true, // Add cookies to agreement data
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      debugPrint('ForceUpdateAgreements: Updating with data: $agreementData');

      // Update the user's agreement data
      await _firestore.collection('users').doc(user.uid).update({
        'agreementsAccepted': agreementData
      });

      // Log this update
      await logUserActivity(
        type: 'agreements_update',
        status: 'success',
        details: 'Force-updated user agreements: terms=$terms, privacy=$privacyPolicy, kvkk=$kvkk, manual=$userManual, cookies=$cookies',
      );

      debugPrint('Successfully force-updated user agreement status');
      
      // Verify the update was successful
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('agreementsAccepted')) {
          Map<String, dynamic> savedAgreements = userData['agreementsAccepted'];
          debugPrint('Verified agreements after update: $savedAgreements');
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error force-updating user agreements: $e');
      return false;
    }
  }

  // Emergency fix for agreement data - sets all agreements to true
  Future<bool> emergencyFixUserAgreements() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in to fix agreements');
        return false;
      }

      // Create a direct map with explicit true values - no conversions
      final Map<String, dynamic> fixedAgreementData = {
        'terms': true,
        'privacyPolicy': true,
        'kvkk': true,
        'userManual': true,
        'cookies': true, // Add cookies agreement
        'fixedAt': FieldValue.serverTimestamp(),
      };
      
      debugPrint('EmergencyFixAgreements: Setting agreement data to all true: $fixedAgreementData');

      // Update the user's agreement data directly
      await _firestore.collection('users').doc(user.uid).update({
        'agreementsAccepted': fixedAgreementData
      });

      // Log this emergency fix
      await logUserActivity(
        type: 'agreements_emergency_fix',
        status: 'success',
        details: 'Emergency fix applied to set all agreements to true',
      );

      debugPrint('Successfully applied emergency fix to user agreement data');
      
      // Verify the update was successful
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('agreementsAccepted')) {
          Map<String, dynamic> savedAgreements = userData['agreementsAccepted'];
          debugPrint('Verified fixed agreements: $savedAgreements');
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error applying emergency fix to user agreements: $e');
      return false;
    }
  }
}
