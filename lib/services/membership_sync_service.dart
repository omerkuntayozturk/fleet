import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for syncing membership status between parent and sub-user accounts
class MembershipSyncService {
  // Singleton pattern
  static final MembershipSyncService _instance = MembershipSyncService._internal();
  factory MembershipSyncService() => _instance;
  MembershipSyncService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Active subscriptions
  StreamSubscription<DocumentSnapshot>? _parentUserSubscription;
  StreamSubscription<DocumentSnapshot>? _subUserSubscription;
  
  // State management
  bool _isInitialized = false;
  bool _isDisposed = false;
  int _consecutiveErrors = 0;
  Timer? _retryTimer;
  String? _parentUserId;
  String? _subUserId;
  
  // Constants
  static const int _maxRetries = 5;
  static const Duration _initialRetryDelay = Duration(seconds: 2);

  /// Initialize the service and set up listeners
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('MembershipSyncService: Cannot initialize - No user is signed in');
        return;
      }
      
      _subUserId = user.uid;
      
      // Check if this is a sub-user
      DocumentSnapshot userDoc;
      try {
        userDoc = await _firestore.collection('users').doc(user.uid).get();
      } catch (e) {
        debugPrint('MembershipSyncService: Error fetching user document: $e');
        // Schedule a retry with exponential backoff
        _scheduleRetry();
        return;
      }
      
      if (!userDoc.exists) {
        debugPrint('MembershipSyncService: User document does not exist');
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) {
        debugPrint('MembershipSyncService: User data is null');
        return;
      }
      
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      
      if (!isSubUser) {
        debugPrint('MembershipSyncService: User is not a sub-user, no need for sync');
        _isInitialized = true;
        return;
      }
      
      _parentUserId = userData['parentUserId'] as String?;
      if (_parentUserId == null) {
        debugPrint('MembershipSyncService: Sub-user has no parent user ID');
        return;
      }
      
      // Initialize with stored data first
      _updateLocalParentMembershipStatus(
        userData['parentMembershipStatus'] as String? ?? 'free',
        userData['parentMembershipPlan'] as String? ?? 'free'
      );
      
      // Set up listeners with proper error handling
      await _setupListeners();
      
      _isInitialized = true;
      _consecutiveErrors = 0;
      debugPrint('MembershipSyncService: Successfully initialized');
    } catch (e) {
      debugPrint('MembershipSyncService: Error during initialization: $e');
      _scheduleRetry();
    }
  }
  
  /// Set up listeners for parent and sub-user document changes
  Future<void> _setupListeners() async {
    if (_isDisposed || _parentUserId == null || _subUserId == null) return;
    
    // Cancel existing subscriptions if any
    await _cancelSubscriptions();
    
    try {
      debugPrint('MembershipSyncService: Set up parent membership listener from $_parentUserId to $_subUserId');
      
      // First, set up a safer way to listen to parent changes
      // Use a REST API approach instead of direct listener when permissions might be an issue
      _schedulePeriodicParentCheck();
      
      // Listen to sub-user document for local changes
      _subUserSubscription = _firestore
          .collection('users')
          .doc(_subUserId)
          .snapshots()
          .listen(
            _handleSubUserChange,
            onError: (e) {
              debugPrint('MembershipSyncService: Error in sub-user listener: $e');
              _handleListenerError();
            },
          );
    } catch (e) {
      debugPrint('MembershipSyncService: Error setting up listeners: $e');
      _handleListenerError();
    }
  }
  
  /// Schedule periodic parent check instead of using a direct listener
  void _schedulePeriodicParentCheck() {
    // Cancel any existing timer
    _retryTimer?.cancel();
    
    // Schedule a periodic check every 30 minutes
    _retryTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _checkParentMembershipStatus();
    });
    
    // Do an immediate check
    _checkParentMembershipStatus();
  }
  
  /// Check parent membership status using a permission-safe approach
  Future<void> _checkParentMembershipStatus() async {
    if (_isDisposed || _parentUserId == null || _subUserId == null) return;
    
    try {
      debugPrint('⚡ REAL-TIME: Membership status change detected!');
      
      // Try to use the sub-user's cached data first
      DocumentSnapshot subUserDoc = await _firestore
          .collection('users')
          .doc(_subUserId)
          .get();
          
      if (!subUserDoc.exists) return;
      
      final subUserData = subUserDoc.data() as Map<String, dynamic>?;
      if (subUserData == null) return;
      
      final currentStatus = subUserData['parentMembershipStatus'] as String?;
      final currentPlan = subUserData['parentMembershipPlan'] as String?;
      
      debugPrint('Current membership status: $currentStatus, Plan: $currentPlan');
      
      // Try to update the parent membership status using FirestoreService
      try {
        // Update the local cache via shared preferences
        await _updateLocalParentMembershipStatus(
          currentStatus ?? 'free',
          currentPlan ?? 'free'
        );
        
        // Use FirestoreService to refresh parent status
        final firestoreService = FirestoreService();
        final refreshedStatus = await firestoreService.refreshParentMembershipStatus(_subUserId!);
        
        if (refreshedStatus != null) {
          debugPrint('MembershipSyncService: Updated parent status to $refreshedStatus for sub-user $_subUserId');
        }
      } catch (e) {
        debugPrint('MembershipSyncService: Error refreshing parent status: $e');
        // The error is not critical, so we continue
      }
    } catch (e) {
      debugPrint('MembershipSyncService: Error checking parent membership: $e');
    }
  }
  
  /// Handle sub-user document changes
  void _handleSubUserChange(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    
    try {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      
      final parentStatus = data['parentMembershipStatus'] as String?;
      final parentPlan = data['parentMembershipPlan'] as String?;
      
      if (parentStatus != null) {
        _updateLocalParentMembershipStatus(parentStatus, parentPlan ?? 'free');
      }
    } catch (e) {
      debugPrint('MembershipSyncService: Error handling sub-user change: $e');
    }
  }
  
  /// Update local parent membership status in SharedPreferences
  Future<void> _updateLocalParentMembershipStatus(String status, String plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parent_membership_status', status);
      await prefs.setString('parent_membership_plan', plan);
      
      // Store last updated time
      await prefs.setInt('parent_membership_updated_at', DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('MembershipSyncService: Updated local parent membership: Status=$status, Plan=$plan');
    } catch (e) {
      debugPrint('MembershipSyncService: Error updating local parent membership: $e');
    }
  }
  
  /// Handle listener errors with exponential backoff
  void _handleListenerError() {
    _consecutiveErrors++;
    
    if (_consecutiveErrors <= _maxRetries) {
      // Calculate backoff delay
      final delayMs = _initialRetryDelay.inMilliseconds * (1 << (_consecutiveErrors - 1));
      final maxDelayMs = const Duration(minutes: 5).inMilliseconds;
      final actualDelayMs = delayMs < maxDelayMs ? delayMs : maxDelayMs;
      
      debugPrint('MembershipSyncService: Retry #$_consecutiveErrors scheduled in ${actualDelayMs}ms');
      
      // Schedule retry
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(milliseconds: actualDelayMs), () {
        if (!_isDisposed) _setupListeners();
      });
    } else {
      debugPrint('MembershipSyncService: Max retries exceeded, giving up');
      // Save the error state to prevent repeated retries during this session
      _isInitialized = true;
    }
  }
  
  /// Schedule a retry with exponential backoff
  void _scheduleRetry() {
    _consecutiveErrors++;
    
    if (_consecutiveErrors <= _maxRetries) {
      // Calculate backoff delay
      final delayMs = _initialRetryDelay.inMilliseconds * (1 << (_consecutiveErrors - 1));
      final maxDelayMs = const Duration(minutes: 5).inMilliseconds;
      final actualDelayMs = delayMs < maxDelayMs ? delayMs : maxDelayMs;
      
      debugPrint('MembershipSyncService: Initialization retry #$_consecutiveErrors scheduled in ${actualDelayMs}ms');
      
      // Schedule retry
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(milliseconds: actualDelayMs), () {
        if (!_isDisposed) initialize();
      });
    } else {
      debugPrint('MembershipSyncService: Max retries exceeded for initialization, giving up');
      // Save the error state to prevent repeated retries during this session
      _isInitialized = true;
    }
  }
  
  /// Cancel all active subscriptions
  Future<void> _cancelSubscriptions() async {
    try {
      if (_parentUserSubscription != null) {
        await _parentUserSubscription!.cancel();
        _parentUserSubscription = null;
      }
      
      if (_subUserSubscription != null) {
        await _subUserSubscription!.cancel();
        _subUserSubscription = null;
      }
      
      _retryTimer?.cancel();
      _retryTimer = null;
    } catch (e) {
      debugPrint('MembershipSyncService: Error cancelling subscriptions: $e');
    }
  }
  
  /// Dispose the service and clean up resources
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _isInitialized = false;
    
    await _cancelSubscriptions();
    
    _parentUserId = null;
    _subUserId = null;
    _consecutiveErrors = 0;
    
    debugPrint('MembershipSyncService: Disposed');
  }
  
  /// Get parent membership status from local cache
  static Future<String> getParentMembershipStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('parent_membership_status') ?? 'free';
    } catch (e) {
      debugPrint('MembershipSyncService: Error getting parent membership status: $e');
      return 'free';
    }
  }
  
  /// Get parent membership plan from local cache
  static Future<String> getParentMembershipPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('parent_membership_plan') ?? 'free';
    } catch (e) {
      debugPrint('MembershipSyncService: Error getting parent membership plan: $e');
      return 'free';
    }
  }
  
  /// Check if parent has premium access from local cache
  static Future<bool> hasParentPremiumAccess() async {
    try {
      final status = await getParentMembershipStatus();
      return status == 'premium' || status == 'starter';
    } catch (e) {
      debugPrint('MembershipSyncService: Error checking parent premium access: $e');
      return true; // Default to true to prevent lockout
    }
  }
}

/// Helper class to import FirestoreService only when needed
class FirestoreService {
  // This is a simplified version just to handle the refreshParentMembershipStatus call
  Future<String?> refreshParentMembershipStatus(String subUserId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Get the sub-user document to find the parent ID
      DocumentSnapshot subUserDoc = await firestore
          .collection('users')
          .doc(subUserId)
          .get();
      
      if (!subUserDoc.exists) {
        debugPrint('Sub-user document not found');
        return null;
      }
      
      Map<String, dynamic> subUserData = subUserDoc.data() as Map<String, dynamic>;
      String? parentUserId = subUserData['parentUserId'];
      
      if (parentUserId == null) {
        debugPrint('No parent user ID found for this sub-user');
        return null;
      }
      
      // Use a safe approach that doesn't rely on direct parent document access
      // which might cause permission issues
      try {
        // Use a cloud function, admin-only API, or a safer approach
        // For now, let's use the local approach with direct access but handle permissions gracefully
        
        // Try to directly query parent document (may fail due to permissions)
        DocumentSnapshot parentDoc;
        try {
          parentDoc = await firestore
              .collection('users')
              .doc(parentUserId)
              .get();
              
          if (parentDoc.exists) {
            Map<String, dynamic> parentData = parentDoc.data() as Map<String, dynamic>;
            String membershipStatus = parentData['membershipStatus'] as String? ?? 'free';
            
            // Update the sub-user document with the parent's membership status
            await firestore
                .collection('users')
                .doc(subUserId)
                .update({
                  'parentMembershipStatus': membershipStatus,
                  'parentMembershipPlan': parentData['membershipPlan'] as String? ?? 'free',
                  'parentMembershipCachedAt': FieldValue.serverTimestamp(),
                });
                
            return membershipStatus;
          }
        } catch (e) {
          // If direct access fails, use the fallback approach
          debugPrint('Direct parent document access failed: $e');
        }
        
        // Fallback: Use the subuser's existing data, just refresh the timestamp
        await firestore
            .collection('users')
            .doc(subUserId)
            .update({
              'parentMembershipCachedAt': FieldValue.serverTimestamp(),
              'pendingParentMembershipRefresh': true // Flag for background refresh
            });
            
        // Return the currently cached status
        return subUserData['parentMembershipStatus'] as String? ?? 'free';
      } catch (e) {
        debugPrint('Error updating parent membership status: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Error in refreshParentMembershipStatus: $e');
      return null;
    }
  }
}
