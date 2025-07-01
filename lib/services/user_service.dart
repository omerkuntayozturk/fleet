import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleet/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  static const String _languageKey = 'user_language_preference';
  static const String _currencyKey = 'selected_currency';

  // Update the current user's membership status and plan with sub-user propagation
  Future<bool> updateMembershipStatus(String status) async {
    try {
      // Get current user ID
      String? userId = _auth.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create an instance of FirestoreService to use the propagation method
      final firestoreService = FirestoreService();

      // Update the user document in Firestore and propagate to sub-users
      await firestoreService.updateUserMembershipWithPropagation(
        userId: userId,
        membershipPlan: status,
        membershipStatus: status,
      );
      
      // Log the profile update activity
      await _authService.logUserActivity(
        type: 'profile_update',
        status: 'success',
        details: 'Membership updated to: $status',
      );

      return true;
    } catch (e) {
      // Log the failed update activity
      await _authService.logUserActivity(
        type: 'profile_update',
        status: 'failed',
        details: 'Membership update error: $e',
      );
      print('Error updating membership status: $e');
      return false;
    }
  }
  
  // After successful subscription purchase, update membership status and return navigation data
  Future<Map<String, dynamic>> processSuccessfulSubscription(String planType) async {
    try {
      // Determine actual membership status from plan type
      String membershipStatus = 'premium';
      if (planType == 'free') {
        membershipStatus = 'free';
      } else if (planType == 'starter') {
        membershipStatus = 'starter';
      }
      
      // Update membership status and propagate to sub-users
      final success = await updateMembershipStatus(membershipStatus);
      
      if (success) {
        // Return data for navigation and success message
        return {
          'success': true,
          'planType': planType,
          'showSuccessMessage': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to update membership status',
        };
      }
    } catch (e) {
      debugPrint('Error processing successful subscription: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Force refresh parent membership status for current user if it's a sub-user
  Future<bool> refreshParentMembershipStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return false;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      
      // If not a sub-user, nothing to do
      if (!isSubUser) {
        return true;
      }
      
      // If it is a sub-user, get parent ID and refresh status
      final parentUserId = userData['parentUserId'] as String?;
      if (parentUserId == null) {
        return false;
      }
      
      // Create FirestoreService instance to use the refresh method
      final firestoreService = FirestoreService();
      final refreshedStatus = await firestoreService.refreshParentMembershipStatus(userId);
      
      return refreshedStatus != null;
    } catch (e) {
      debugPrint('Error refreshing parent membership status: $e');
      return false;
    }
  }

  // Save user's language preference to both SharedPreferences and Firestore
  Future<bool> updateUserLanguage(String languageCode) async {
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      // Save to user profile in Firestore if user is logged in
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'language': languageCode,
          'languageUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Language preference saved to Firestore: $languageCode for user $userId');
        
        // Log the profile update activity
        await _authService.logUserActivity(
          type: 'profile_update',
          status: 'success',
          details: 'Language changed to: $languageCode',
        );
      }
      
      debugPrint('Language preference saved: $languageCode');
      return true;
    } catch (e) {
      // Log the failed update activity
      await _authService.logUserActivity(
        type: 'profile_update',
        status: 'failed',
        details: 'Language update error: $e',
      );
      debugPrint('Error saving language preference: $e');
      return false;
    }
  }
  
  // Get user's language preference - first check Firestore, then SharedPreferences
  Future<String?> getUserLanguage() async {
    try {
      String? language;
      
      // Try to get from Firestore first if user is logged in
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists && userDoc.data()!.containsKey('language')) {
            language = userDoc.data()!['language'] as String?;
            debugPrint('Retrieved language from Firestore: $language');
            
            // If found in Firestore, also update SharedPreferences for consistency
            if (language != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_languageKey, language);
            }
            return language;
          }
        } catch (e) {
          debugPrint('Error retrieving language from Firestore: $e');
          // Continue to try SharedPreferences if Firestore fails
        }
      }
      
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      language = prefs.getString(_languageKey);
      debugPrint('Retrieved language from SharedPreferences: $language');
      
      // If found in SharedPreferences but not in Firestore, update Firestore
      if (language != null && userId != null) {
        try {
          await _firestore.collection('users').doc(userId).update({
            'language': language,
            'languageUpdatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('Updated Firestore with language from SharedPreferences: $language');
        } catch (e) {
          debugPrint('Error updating Firestore with language from SharedPreferences: $e');
        }
      }
      
      return language;
    } catch (e) {
      debugPrint('Error retrieving language preference: $e');
      return null;
    }
  }
  
  // Ensure language settings are synchronized across all storage locations
  Future<void> synchronizeLanguageSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      // Get current settings from both sources
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsLanguage = prefs.getString(_languageKey);
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final firestoreLanguage = userDoc.exists && userDoc.data()!.containsKey('language') 
          ? userDoc.data()!['language'] as String?
          : null;
      
      debugPrint('Synchronizing language settings - SharedPrefs: $sharedPrefsLanguage, Firestore: $firestoreLanguage');
      
      // If they don't match, use the most recent one
      if (sharedPrefsLanguage != firestoreLanguage) {
        if (firestoreLanguage != null) {
          // Update SharedPreferences with Firestore value
          await prefs.setString(_languageKey, firestoreLanguage);
          debugPrint('Updated SharedPreferences with Firestore language: $firestoreLanguage');
        } else if (sharedPrefsLanguage != null) {
          // Update Firestore with SharedPreferences value
          await _firestore.collection('users').doc(userId).update({
            'language': sharedPrefsLanguage,
            'languageUpdatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('Updated Firestore with SharedPreferences language: $sharedPrefsLanguage');
        }
      }
    } catch (e) {
      debugPrint('Error synchronizing language settings: $e');
    }
  }

  // Save user's currency preference to both SharedPreferences and Firestore
  Future<bool> updateUserCurrency(String currencyCode) async {
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currencyCode);
      
      // Save to user profile in Firestore if user is logged in
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'currency': currencyCode,
          'currencyUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Currency preference saved to Firestore: $currencyCode for user $userId');
        
        // Log the profile update activity
        await _authService.logUserActivity(
          type: 'profile_update',
          status: 'success',
          details: 'Currency changed to: $currencyCode',
        );
      }
      
      debugPrint('Currency preference saved: $currencyCode');
      return true;
    } catch (e) {
      // Log the failed update activity
      await _authService.logUserActivity(
        type: 'profile_update',
        status: 'failed',
        details: 'Currency update error: $e',
      );
      debugPrint('Error saving currency preference: $e');
      return false;
    }
  }
  
  // Get user's currency preference - first check Firestore, then SharedPreferences
  Future<String?> getUserCurrency() async {
    try {
      String? currency;
      
      // Try to get from Firestore first if user is logged in
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists && userDoc.data()!.containsKey('currency')) {
            currency = userDoc.data()!['currency'] as String?;
            debugPrint('Retrieved currency from Firestore: $currency');
            
            // If found in Firestore, also update SharedPreferences for consistency
            if (currency != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_currencyKey, currency);
            }
            return currency;
          }
        } catch (e) {
          debugPrint('Error retrieving currency from Firestore: $e');
          // Continue to try SharedPreferences if Firestore fails
        }
      }
      
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      currency = prefs.getString(_currencyKey);
      debugPrint('Retrieved currency from SharedPreferences: $currency');
      
      // If found in SharedPreferences but not in Firestore, update Firestore
      if (currency != null && userId != null) {
        try {
          await _firestore.collection('users').doc(userId).update({
            'currency': currency,
            'currencyUpdatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('Updated Firestore with currency from SharedPreferences: $currency');
        } catch (e) {
          debugPrint('Error updating Firestore with currency from SharedPreferences: $e');
        }
      }
      
      return currency;
    } catch (e) {
      debugPrint('Error retrieving currency preference: $e');
      return null;
    }
  }
  
  // Ensure currency settings are synchronized across all storage locations
  Future<void> synchronizeCurrencySettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      // Get current settings from both sources
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsCurrency = prefs.getString(_currencyKey);
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final firestoreCurrency = userDoc.exists && userDoc.data()!.containsKey('currency') 
          ? userDoc.data()!['currency'] as String?
          : null;
      
      debugPrint('Synchronizing currency settings - SharedPrefs: $sharedPrefsCurrency, Firestore: $firestoreCurrency');
      
      // If they don't match, use the most recent one
      if (sharedPrefsCurrency != firestoreCurrency) {
        if (firestoreCurrency != null) {
          // Update SharedPreferences with Firestore value
          await prefs.setString(_currencyKey, firestoreCurrency);
          debugPrint('Updated SharedPreferences with Firestore currency: $firestoreCurrency');
        } else if (sharedPrefsCurrency != null) {
          // Update Firestore with SharedPreferences value
          await _firestore.collection('users').doc(userId).update({
            'currency': sharedPrefsCurrency,
            'currencyUpdatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('Updated Firestore with SharedPreferences currency: $sharedPrefsCurrency');
        }
      }
    } catch (e) {
      debugPrint('Error synchronizing currency settings: $e');
    }
  }

  // Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      // Send password reset email using Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);
      
      // Log the password reset activity
      await _authService.logUserActivity(
        type: 'password_reset',
        status: 'success',
        details: 'Password reset email sent to: $email',
      );
      
      debugPrint('Password reset email sent to: $email');
      return true;
    } catch (e) {
      // Log the failed password reset activity
      await _authService.logUserActivity(
        type: 'password_reset',
        status: 'failed',
        details: 'Password reset error: $e',
      );
      debugPrint('Error sending password reset email: $e');
      return false;
    }
  }

  // Updated to handle permission issues safely
  Future<bool> hasPremiumAccess() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return false;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      
      // If not a sub-user, check own membership
      if (!isSubUser) {
        final membershipStatus = userData['membershipStatus'] as String? ?? 'free';
        return membershipStatus == 'premium' || membershipStatus == 'starter';
      }
      
      // If sub-user, check cached parent membership status from own document
      final cachedParentStatus = userData['parentMembershipStatus'] as String?;
      final cachedAt = userData['parentMembershipCachedAt'] as Timestamp?;
      
      // If we have relatively fresh cached data (within 1 hour), use it
      if (cachedParentStatus != null && 
          cachedAt != null && 
          DateTime.now().difference(cachedAt.toDate()).inHours < 1) {
        debugPrint('Using cached parent membership status: $cachedParentStatus');
        return cachedParentStatus == 'premium' || cachedParentStatus == 'starter';
      }
      
      // If cache is outdated or missing, try to refresh it directly
      try {
        final parentUserId = userData['parentUserId'] as String?;
        if (parentUserId != null) {
          // Try to directly query parent document (may fail due to permissions)
          final parentDoc = await _firestore.collection('users').doc(parentUserId).get();
          if (parentDoc.exists) {
            final parentData = parentDoc.data() as Map<String, dynamic>;
            final parentStatus = parentData['membershipStatus'] as String? ?? 'free';
            
            // Update the cache
            await _firestore.collection('users').doc(userId).update({
              'parentMembershipStatus': parentStatus,
              'parentMembershipCachedAt': FieldValue.serverTimestamp(),
            });
            
            debugPrint('Refreshed parent membership status: $parentStatus');
            return parentStatus == 'premium' || parentStatus == 'starter';
          }
        }
      } catch (refreshError) {
        debugPrint('Error refreshing parent status directly: $refreshError');
      }
      
      // If direct refresh fails, use the FirestoreService method as fallback
      try {
        final firestoreService = FirestoreService();
        final refreshedStatus = await firestoreService.refreshParentMembershipStatus(userId);
        
        if (refreshedStatus != null) {
          return refreshedStatus == 'premium' || refreshedStatus == 'starter';
        }
      } catch (serviceError) {
        debugPrint('Error using service to refresh: $serviceError');
      }
      
      // In case of any errors, default to true to prevent lockout
      // This should be fixed by proper synchronization from backend
      try {
        await _firestore.collection('users').doc(userId).update({
          'needsMembershipStatusRefresh': true, // Flag for backend processes
        });
      } catch (e) {
        debugPrint('Error setting refresh flag: $e');
      }
      
      return true; // Default to allowing access to prevent lockouts
    } catch (e) {
      debugPrint('Error checking premium access: $e');
      return true; // Default to allowing access on errors
    }
  }

  // Check if user is a sub-user with active parent account
  Future<Map<String, dynamic>> checkSubUserAccessStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {'hasAccess': false, 'reason': 'not_authenticated'};
      }
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'hasAccess': false, 'reason': 'user_not_found'};
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      
      if (!isSubUser) {
        // Regular user - check own membership
        final membershipStatus = userData['membershipStatus'] as String? ?? 'free';
        return {
          'hasAccess': membershipStatus != 'free',
          'reason': membershipStatus == 'free' ? 'free_membership' : 'has_access',
          'isSubUser': false,
          'membershipStatus': membershipStatus
        };
      }
      
      // This is a sub-user - check status first
      final status = userData['status'] as bool? ?? true; // Default to true if not set
      if (!status) {
        return {'hasAccess': false, 'reason': 'account_deactivated', 'isSubUser': true};
      }
      
      // Check parent's membership
      final parentUserId = userData['parentUserId'] as String?;
      if (parentUserId == null) {
        return {'hasAccess': false, 'reason': 'no_parent_user', 'isSubUser': true};
      }
      
      // Check parent membership (either from cache or directly)
      bool hasParentPremium = await hasPremiumAccess();
      
      return {
        'hasAccess': hasParentPremium,
        'reason': hasParentPremium ? 'has_access' : 'parent_free_membership',
        'isSubUser': true,
        'parentUserId': parentUserId
      };
      
    } catch (e) {
      debugPrint('Error checking sub-user access status: $e');
      return {'hasAccess': false, 'reason': 'error', 'error': e.toString()};
    }
  }

  // Update user membership details with propagation to sub-users
  Future<void> updateUserMembershipWithPropagation({
    required String userId,
    required String membershipPlan,
    required String membershipStatus
  }) async {
    if (userId.isEmpty) {
      throw Exception('User ID is required to update membership');
    }

    try {
      // Determine the actual membership status
      // If plan type was provided, ensure we use proper membership status
      String actualMembershipStatus = membershipStatus;
      if (membershipPlan == 'monthly' || membershipPlan == 'yearly') {
        actualMembershipStatus = 'premium';
        print('Converting plan "$membershipPlan" to status "premium" for consistency');
      }
      
      // First update the user's own membership
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'membershipPlan': membershipPlan,
            'membershipStatus': actualMembershipStatus,
            'membershipUpdatedAt': FieldValue.serverTimestamp(),
          });
      
      // Then propagate this change to all sub-users
      await FirestoreService().updateParentMembershipStatusForAllSubUsers(userId, actualMembershipStatus);
      
      print('Successfully updated user membership and propagated to sub-users');
    } catch (e) {
      print('Error updating user membership with propagation: $e');
      throw e;
    }
  }
}
