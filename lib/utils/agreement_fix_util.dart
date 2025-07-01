import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Utility class for fixing agreement data issues
class AgreementFixUtil {
  /// Fix agreement data for the current user
  /// Can be called from a settings page or developer menu
  static Future<bool> fixCurrentUserAgreements(BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      
      final user = auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is logged in')),
        );
        return false;
      }
      
      // Show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      try {
        // Get current user document
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Pop loading dialog
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User document not found')),
          );
          return false;
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Check if agreements exist
        if (!userData.containsKey('agreementsAccepted')) {
          // Create default agreement data
          await firestore.collection('users').doc(user.uid).update({
            'agreementsAccepted': {
              'terms': true,
              'privacyPolicy': true,
              'kvkk': true,
              'userManual': true,
              'updatedAt': FieldValue.serverTimestamp(),
            }
          });
        } else {
          // Extract current values
          final existingAgreements = userData['agreementsAccepted'] as Map<String, dynamic>;
          
          // Force update with proper boolean values
          await firestore.collection('users').doc(user.uid).update({
            'agreementsAccepted': {
              'terms': true,
              'privacyPolicy': true,
              'kvkk': true,
              'userManual': true,
              'updatedAt': FieldValue.serverTimestamp(),
              // Preserve the original acceptance time if it exists
              'acceptedAt': existingAgreements['acceptedAt'] ?? FieldValue.serverTimestamp(),
            }
          });
        }
        
        // Verify the update
        final updatedDoc = await firestore.collection('users').doc(user.uid).get();
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        print('Updated agreement data: ${updatedData['agreementsAccepted']}');
        
        // Pop loading dialog
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User agreements updated successfully')),
        );
        
        return true;
      } catch (e) {
        // Pop loading dialog
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating agreements: $e')),
        );
        return false;
      }
    } catch (e) {
      print('Error in fix utility: $e');
      return false;
    }
  }
  
  /// Force-fix agreement data to true values for the current user
  static Future<bool> fixAgreementsForCurrentUser() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      final User? currentUser = auth.currentUser;
      if (currentUser == null) {
        print('No user is logged in to fix agreements');
        return false;
      }
      
      // Direct true values without any type conversion
      final Map<String, dynamic> fixedAgreements = {
        'terms': true,
        'privacyPolicy': true,
        'kvkk': true,
        'userManual': true,
        'fixedAt': FieldValue.serverTimestamp(),
      };
      
      print('AGREEMENT_FIX: Setting all agreements to true');
      
      // Update Firestore with direct values
      await firestore.collection('users').doc(currentUser.uid).update({
        'agreementsAccepted': fixedAgreements
      });
      
      // Verify update
      final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('agreementsAccepted')) {
          final savedAgreements = userData['agreementsAccepted'];
          print('AGREEMENT_FIX: Verified fixed data: $savedAgreements');
        }
      }
      
      return true;
    } catch (e) {
      print('AGREEMENT_FIX: Error fixing agreements: $e');
      return false;
    }
  }
  
  /// Call this method after successful login
  static Future<void> runPostLoginFix(BuildContext context) async {
    try {
      final result = await fixAgreementsForCurrentUser();
      if (result) {
        print('AGREEMENT_FIX: Successfully fixed agreements after login');
      }
    } catch (e) {
      print('AGREEMENT_FIX: Error in post-login fix: $e');
    }
  }
}
