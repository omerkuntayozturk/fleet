import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fleet/services/membership_sync_service.dart';

/// Service for initializing and managing Firebase-related functionality
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  
  /// Initialize Firebase service and set up auth state listeners
  Future<void> initialize() async {
    // Set up auth state listener
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('FirebaseService: User signed in: ${user.uid}');
        // Initialize membership synchronization for the user
        MembershipSyncService().initialize();
      } else {
        debugPrint('FirebaseService: User signed out');
        // Cleanup when user signs out
        MembershipSyncService().dispose();
      }
    });
  }
  
  /// Set persistence settings for better offline support
  Future<void> configurePersistence() async {
    try {
      _firestore.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('FirebaseService: Persistence configured successfully');
    } catch (e) {
      debugPrint('FirebaseService: Error configuring persistence: $e');
    }
  }
  
  /// Enable Firestore network connection
  Future<void> enableNetwork() async {
    try {
      await _firestore.enableNetwork();
      debugPrint('FirebaseService: Network enabled');
    } catch (e) {
      debugPrint('FirebaseService: Error enabling network: $e');
    }
  }
  
  /// Disable Firestore network connection (offline mode)
  Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
      debugPrint('FirebaseService: Network disabled');
    } catch (e) {
      debugPrint('FirebaseService: Error disabling network: $e');
    }
  }
}
