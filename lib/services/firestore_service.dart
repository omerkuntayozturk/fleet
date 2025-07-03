import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleet/models/contract.dart' as contract_model;
import 'package:fleet/models/vehicle.dart';
import '../core/enums.dart'; // For enums
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to handle Firestore permission errors
  Future<T> _handleFirestoreOperation<T>({
    required Future<T> Function() operation,
    required String errorMessage,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        print('$errorMessage: Permission denied. This could be due to missing authentication or insufficient permissions.');
        
        // Check if user is authenticated
        User? currentUser = _auth.currentUser;
        if (currentUser == null) {
          print('User is not authenticated. Please sign in again.');
          // Here you might want to trigger a re-authentication flow
        } else {
          // Try to get a fresh token
          try {
            await currentUser.getIdToken(true);
            // Retry the operation after getting a fresh token
            try {
              return await operation();
            } catch (retryError) {
              print('Retry failed after token refresh: $retryError');
            }
          } catch (tokenError) {
            print('Failed to refresh authentication token: $tokenError');
          }
        }
      }
      print('$errorMessage: ${e.message}');
      
      // If a default value is provided, return it instead of throwing
      if (defaultValue != null) {
        return defaultValue;
      }
      throw e;
    } catch (e) {
      print('$errorMessage: $e');
      
      // If a default value is provided, return it instead of throwing
      if (defaultValue != null) {
        return defaultValue;
      }
      throw e;
    }
  }

  // Helper method to check if user is a sub-user and get parent user ID
  Future<String?> _getParentUserIdIfSubUser(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Check if this is a sub-user
      bool isSubUser = userData['isSubUser'] ?? false;
      if (isSubUser && userData.containsKey('parentUserId')) {
        return userData['parentUserId'] as String;
      }
      
      return null; // Not a sub-user or no parent ID found
    } catch (e) {
      print('Error checking if user is sub-user: $e');
      return null;
    }
  }

  // Helper method to validate document access
  Future<bool> _validateDocumentAccess(String userId) async {
    try {
      // Verify user exists
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User document does not exist');
        return false;
      }
      
      // Get current authenticated user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No authenticated user');
        return false;
      }
      
      // If the user is trying to access their own document, allow it
      if (userId == currentUser.uid) {
        return true;
      }
      
      // For sub-users, check if they have permissions to access parent data
      DocumentSnapshot currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!currentUserDoc.exists) {
        return false;
      }
      
      Map<String, dynamic> currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      bool isSubUser = currentUserData['isSubUser'] ?? false;
      
      // If the current user is a sub-user, check if they're trying to access their parent's data
      if (isSubUser && currentUserData.containsKey('parentUserId')) {
        String parentId = currentUserData['parentUserId'];
        return parentId == userId;
      }
      
      return false;
    } catch (e) {
      print('Error validating document access: $e');
      return false;
    }
  }

  // Simplified method to copy data to parent user
  Future<void> _copyDataToParent({
    required String userId, 
    required String parentUserId, 
    required String collectionName, 
    required String documentId, 
    required Map<String, dynamic> data,
  }) async {
    try {
      // Add metadata to track the original creator
      Map<String, dynamic> parentData = Map<String, dynamic>.from(data);
      parentData['originalCreatorId'] = userId;
      parentData['mirroredAt'] = FieldValue.serverTimestamp();
      
      // Directly write to the parent's collection
      await _firestore
          .collection('users')
          .doc(parentUserId)
          .collection(collectionName)
          .doc(documentId)
          .set(parentData);
          
      print('Successfully copied data to parent user: $parentUserId');
    } catch (e) {
      print('Error copying data to parent user: $e');
      // If this fails due to permission issues, your Firebase rules need updating
      print('Please check Firebase security rules to ensure sub-users can write to parent documents');
    }
  }

  // Fetch contacts for a specific user
  Future<List<Map<String, dynamic>>> fetchContacts({required String? userId}) async {
    if (userId == null) {
      return [];
    }

    return _handleFirestoreOperation<List<Map<String, dynamic>>>(
      operation: () async {
        // Create query reference
        Query query = _firestore
            .collection('users')
            .doc(userId)
            .collection('contacts');
        
        // Apply sorting
        query = query.orderBy('createdAt', descending: true);
        
        // Execute query
        final querySnapshot = await query.get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'phone': data['phone'] ?? '',
            'createdAt': data['createdAt'],
          };
        }).toList();
      },
      errorMessage: 'Error fetching contacts',
      defaultValue: [], // Return empty list on error
    );
  }

  // Fetch customer contacts for a specific user
  Future<List<Map<String, dynamic>>> fetchCustomers({required String? userId}) async {
    if (userId == null) {
      return [];
    }

    try {
      final contactsList = await fetchContacts(userId: userId);
      
      return contactsList.map((contact) => {
        'id': contact['id'],
        'name': contact['name'],
        'email': contact['email'],
        'phone': contact['phone'],
      }).toList();
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  // Update user membership details
  Future<void> updateUserMembership({
    required String userId,
    required String membershipPlan,
    required String membershipStatus
  }) async {
    if (userId.isEmpty) {
      throw Exception('User ID is required to update membership');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'membershipPlan': membershipPlan,
            'membershipStatus': membershipStatus,
          });
    } catch (e) {
      print('Error updating user membership: $e');
      throw e;
    }
  }

  // Fetch a user's permissions directly from Firestore
  Future<Map<String, bool>> fetchUserPermissions(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final isSubUser = userData['isSubUser'] as bool? ?? false;
      
      // If it's not a sub-user, grant all permissions
      if (!isSubUser) {
        return {
          'users_permission_dashboard': true,
          'users_permission_opportunities': true,
          'users_permission_customers': true,
          'users_permission_products': true,
          'users_permission_reports': true,
        };
      }
      
      // Get permissions map from user data
      final permissions = userData['permissions'] as Map<String, dynamic>? ?? {};
      
      // Convert to proper Map<String, bool>
      return {
        'users_permission_dashboard': permissions['users_permission_dashboard'] as bool? ?? false,
        'users_permission_opportunities': permissions['users_permission_opportunities'] as bool? ?? false,
        'users_permission_customers': permissions['users_permission_customers'] as bool? ?? false,
        'users_permission_products': permissions['users_permission_products'] as bool? ?? false,
        'users_permission_reports': permissions['users_permission_reports'] as bool? ?? false,
      };
    } catch (e) {
      print('Error fetching user permissions: $e');
      // Return default permissions (no access) in case of error
      return {
        'users_permission_dashboard': false,
        'users_permission_opportunities': false,
        'users_permission_customers': false,
        'users_permission_products': false,
        'users_permission_reports': false,
      };
    }
  }

  // Fetch sub-users for a parent user
  Future<List<Map<String, dynamic>>> fetchSubUsers(String parentUserId) async {
    return _handleFirestoreOperation<List<Map<String, dynamic>>>(
      operation: () async {
        try {
          final QuerySnapshot snapshot = await _firestore
              .collection('users')
              .where('parentUserId', isEqualTo: parentUserId)
              .where('status', isEqualTo: true) // Only fetch active users
              .orderBy('createdAt', descending: true)
              .get();
              
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Convert Timestamp to milliseconds for consistent handling
            int createdAtMillis = data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch 
                : DateTime.now().millisecondsSinceEpoch;
                
            return {
              'userId': doc.id,
              'username': data['username'] ?? '',
              'email': data['email'] ?? '',
              'isSubUser': data['isSubUser'] ?? true,
              'parentUserId': data['parentUserId'] ?? parentUserId,
              'createdBy': data['creatorUsername'] ?? data['creatorEmail'] ?? 'Unknown',
              'permissions': data['permissions'] ?? {},
              'status': data['status'] ?? true,
              'createdAt': createdAtMillis,
            };
          }).toList();
        } catch (e) {
          print('Error fetching sub-users: $e');
          throw e;
        }
      },
      errorMessage: 'Error fetching sub-users',
      defaultValue: [], // Return empty list on error
    );
  }

  // Toggle sub-user status (activate/deactivate)
  Future<void> toggleSubUserStatus(String userId, bool newStatus) async {
    return _handleFirestoreOperation(
      operation: () async {
        try {
          await _firestore.collection('users').doc(userId).update({
            'status': newStatus,
            'statusUpdatedAt': FieldValue.serverTimestamp(),
          });
          
          return;
        } catch (e) {
          print('Error toggling sub-user status: $e');
          throw e;
        }
      },
      errorMessage: 'Error toggling sub-user status',
    );
  }

  // Check if current security rules allow querying sub-users
  Future<bool> checkSubUserAccessPermission() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }
      
      // Try a small limit query to test permissions
      await _firestore
          .collection('users')
          .where('parentUserId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      // If we get here without an error, the query succeeded
      return true;
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('Security rules prevent querying sub-users: ${e.message}');
        return false;
      }
      print('Error checking sub-user access: $e');
      return false;
    }
  }

  // Updated method to create sub-users with proper admin re-authentication
  Future<Map<String, dynamic>> createSubUser({
    required String email, 
    required String password,
    required Map<String, bool> permissions,
    required String adminEmail,
    required String adminPassword,
  }) async {
    try {
      // Get current authenticated user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to create sub-users');
      }
      
      // Store current user's ID and email for re-authentication
      final String adminUid = currentUser.uid;
      
      // Get current user's data for reference
      final DocumentSnapshot currentUserDoc = await _firestore
          .collection('users')
          .doc(adminUid)
          .get();
          
      if (!currentUserDoc.exists) {
        throw Exception('Parent user data not found');
      }
      
      final Map<String, dynamic> currentUserData = 
          currentUserDoc.data() as Map<String, dynamic>;
          
      // Extract username from email (part before @)
      final String username = email.split('@')[0];
      
      // The parent (creator) username/email for display purposes
      final String parentUsername = currentUserData['username'] ?? adminEmail ?? 'Unknown';
      
      // Generate a unique ID for the new user document in Firestore
      // We'll store this as an additional reference ID in the user document
      final String newUserId = _firestore.collection('users').doc().id;
      
      // Create the user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to create user account');
      }
      
      // At this point, we're logged in as the new user
      // Let's immediately sign out and switch back to admin
      await _auth.signOut();
      
      // Re-authenticate as admin user
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        
        // Verify we're back as admin
        final User? reAuthUser = _auth.currentUser;
        if (reAuthUser == null || reAuthUser.uid != adminUid) {
          throw Exception('Failed to restore admin session');
        }
        
        print('Successfully re-authenticated as admin user');
      } catch (e) {
        print('Error during admin re-authentication: $e');
        throw Exception('Admin session was lost. Please sign in again with your admin account.');
      }
      
      // Now create the user document in Firestore
      // Since we're authenticated as admin again, this should work
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': adminUid,
        'creatorEmail': adminEmail,
        'creatorUsername': parentUsername,
        'isSubUser': true,
        'parentUserId': adminUid,
        'parentUserPath': _firestore.collection('users').doc(adminUid).path,
        'permissions': permissions,
        'organizationId': currentUserData['organizationId'],
        'status': true,
        'firestoreGeneratedId': newUserId, // Using the previously generated ID as a reference
      });
      
      // Also update the parent user's document to keep track of sub-users
      await _firestore.collection('users').doc(adminUid).update({
        'hasSubUsers': true,
        'subUserCount': FieldValue.increment(1),
        'lastSubUserCreatedAt': FieldValue.serverTimestamp(),
        'lastCreatedSubUserId': userCredential.user!.uid,
        'lastCreatedSubUserRefId': newUserId, // Store reference to the generated ID
      });
      
      // Return the created user data
      return {
        'userId': userCredential.user!.uid,
        'firestoreGeneratedId': newUserId, // Include the generated ID in the response
        'email': email,
        'username': username,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isSubUser': true,
        'parentUserId': adminUid,
        'createdBy': parentUsername,
        'permissions': permissions,
        'status': true,
      };
      
    } catch (e) {
      print('Error creating sub-user: $e');
      throw e;
    }
  }

  // Update parent membership status for all sub-users when parent status changes
  Future<void> updateParentMembershipStatusForAllSubUsers(String parentUserId, String newStatus) async {
    try {
      // First, get all sub-users of this parent
      QuerySnapshot subUsersSnapshot = await _firestore
          .collection('users')
          .where('parentUserId', isEqualTo: parentUserId)
          .get();
      
      if (subUsersSnapshot.docs.isEmpty) {
        print('No sub-users found for parent ID: $parentUserId');
        return;
      }
      
      // Make sure we set a valid parentMembershipStatus value
      // Convert plan types to membership status if needed
      String membershipStatus = newStatus;
      if (newStatus == 'monthly' || newStatus == 'yearly') {
        // If a plan type was passed, convert it to 'premium' status
        membershipStatus = 'premium';
        print('Converting plan type "$newStatus" to membership status "premium"');
      }
      
      print('Found ${subUsersSnapshot.docs.length} sub-users to update with parent status: $membershipStatus');
      
      // Create a batch to update all sub-users efficiently
      WriteBatch batch = _firestore.batch();
      
      for (var doc in subUsersSnapshot.docs) {
        batch.update(doc.reference, {
          'parentMembershipStatus': membershipStatus,
          'parentMembershipCachedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Commit the batch update
      await batch.commit();
      
      // Verify the updates were successful by checking a sample sub-user
      if (subUsersSnapshot.docs.isNotEmpty) {
        try {
          String sampleSubUserId = subUsersSnapshot.docs.first.id;
          DocumentSnapshot verifyDoc = await _firestore
              .collection('users')
              .doc(sampleSubUserId)
              .get();
              
          if (verifyDoc.exists) {
            Map<String, dynamic> verifyData = verifyDoc.data() as Map<String, dynamic>;
            String updatedStatus = verifyData['parentMembershipStatus'] ?? 'unknown';
            print('Verified updated parent membership status: $updatedStatus for sub-user: $sampleSubUserId');
          }
        } catch (verifyError) {
          // Just log verification errors, don't throw
          print('Error verifying update: $verifyError');
        }
      }
      
      print('Successfully updated parent membership status for all sub-users');
    } catch (e) {
      print('Error updating parent membership status for sub-users: $e');
      // Don't throw here to ensure the calling widget won't be affected
    }
  }

  // Force refresh parent membership status for a specific sub-user
  Future<String?> refreshParentMembershipStatus(String subUserId) async {
    try {
      // Get the sub-user document to find the parent ID
      DocumentSnapshot subUserDoc = await _firestore
          .collection('users')
          .doc(subUserId)
          .get();
      
      if (!subUserDoc.exists) {
        print('Sub-user document not found');
        return null;
      }
      
      Map<String, dynamic> subUserData = subUserDoc.data() as Map<String, dynamic>;
      String? parentUserId = subUserData['parentUserId'];
      
      if (parentUserId == null) {
        print('No parent user ID found for this sub-user');
        return null;
      }
      
      // Now get the parent user document to check actual membership status
      DocumentSnapshot parentUserDoc = await _firestore
          .collection('users')
          .doc(parentUserId)
          .get();
      
      if (!parentUserDoc.exists) {
        print('Parent user document not found');
        return null;
      }
      
      Map<String, dynamic> parentUserData = parentUserDoc.data() as Map<String, dynamic>;
      String membershipStatus = parentUserData['membershipStatus'] ?? 'free';
      
      // Try to update the sub-user's cached parent membership status
      try {
        await _firestore
            .collection('users')
            .doc(subUserId)
            .update({
              'parentMembershipStatus': membershipStatus,
              'parentMembershipCachedAt': FieldValue.serverTimestamp(),
            });
        
        // Return the refreshed status immediately without verifying
        print('Updated parent membership status for sub-user: $membershipStatus');
        return membershipStatus;
      } catch (updateError) {
        print('Error updating sub-user document: $updateError');
        
        // Try alternative approach with merge
        try {
          await _firestore
              .collection('users')
              .doc(subUserId)
              .set({
                'parentMembershipStatus': membershipStatus,
                'parentMembershipCachedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              
          print('Updated parent membership status using merge approach');
          return membershipStatus;
        } catch (mergeError) {
          print('Merge approach also failed: $mergeError');
          // Don't throw, just return null
          return null;
        }
      }
    } catch (e) {
      print('Error refreshing parent membership status: $e');
      // Don't throw, just return null
      return null;
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
      // First update the user's own membership
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'membershipPlan': membershipPlan,
            'membershipStatus': membershipStatus,
            'membershipUpdatedAt': FieldValue.serverTimestamp(),
          });
      
      // Then propagate this change to all sub-users
      await updateParentMembershipStatusForAllSubUsers(userId, membershipStatus);
      
      print('Successfully updated user membership and propagated to sub-users');
    } catch (e) {
      print('Error updating user membership with propagation: $e');
      throw e;
    }
  }

  // Add or update a service in Firestore
  Future<void> addService(dynamic service, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('services')
            .doc(service.id);
            
        await docRef.set({
          'id': service.id,
          'vehicleId': service.vehicleId,
          'date': service.date,
          'serviceType': service.serviceType,
          'cost': service.cost,
          'supplier': service.supplier,
          'driver': service.driver,
          'odometer': service.odometer,
          'stage': service.stage.toString(),
          'notes': service.notes,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        return;
      },
      errorMessage: 'Error adding/updating service',
    );
  }

  // Fetch services for a specific user
  Future<List<Map<String, dynamic>>> fetchServices({required String userId}) async {
    return _handleFirestoreOperation<List<Map<String, dynamic>>>(
      operation: () async {
        // Create query reference
        Query query = _firestore
            .collection('users')
            .doc(userId)
            .collection('services');
        
        // Apply sorting (newest first)
        query = query.orderBy('createdAt', descending: true);
        
        // Execute query
        final querySnapshot = await query.get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Convert Firestore Timestamp to DateTime
          DateTime date = DateTime.now();
          if (data['date'] != null) {
            if (data['date'] is Timestamp) {
              date = (data['date'] as Timestamp).toDate();
            } else if (data['date'] is String) {
              date = DateTime.tryParse(data['date']) ?? DateTime.now();
            }
          }
          
          return {
            'id': doc.id,
            'vehicleId': data['vehicleId'] ?? '',
            'serviceType': data['serviceType'] ?? '',
            'date': date,
            'cost': data['cost'] ?? 0.0,
            'supplier': data['supplier'] ?? '',
            'driver': data['driver'] ?? '',
            'odometer': data['odometer'] ?? 0.0,
            'stage': data['stage'] ?? 'newService',
            'notes': data['notes'] ?? '',
            'createdAt': data['createdAt'] is Timestamp ? 
                (data['createdAt'] as Timestamp).toDate() : 
                DateTime.now(),
          };
        }).toList();
      },
      errorMessage: 'Error fetching services',
      defaultValue: [], // Return empty list on error
    );
  }

  // Delete a service from Firestore
  Future<void> deleteService(String serviceId, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('services')
            .doc(serviceId)
            .delete();
            
        return;
      },
      errorMessage: 'Error deleting service',
    );
  }

  // Add this helper to convert EmploymentStatus to Turkish string for export
  String employmentStatusToTurkish(EmploymentStatus status) {
    switch (status) {
      case EmploymentStatus.active:
        return 'Aktif';
      case EmploymentStatus.onLeave:
        return 'İzinli';
      case EmploymentStatus.terminated:
        return 'Feshedildi';
      case EmploymentStatus.resigned:
        return 'İstifa Etti';
      default:
        return 'Aktif';
    }
  }

  // Fetch employees for a specific user
  Future<List<dynamic>> fetchEmployees({required String userId}) async {
    return _handleFirestoreOperation<List<dynamic>>(
      operation: () async {
        // Create query reference
        Query query = _firestore
            .collection('users')
            .doc(userId)
            .collection('employees');
        
        // Apply sorting
        query = query.orderBy('name', descending: false);
        
        // Execute query
        final querySnapshot = await query.get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'phone': data['phone'] ?? '',
            'position': data['position'] ?? '',
            'departmentId': data['departmentId'] ?? '',
            'status': data['status'] ?? 'active',
          };
        }).toList();
      },
      errorMessage: 'Error fetching employees',
      defaultValue: [], // Return empty list on error
    );
  }

  // Add a contract to Firestore
  Future<void> addContract(contract_model.Contract contract, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('contracts')
            .doc(contract.id);
            
        await docRef.set({
          'id': contract.id,
          'employeeId': contract.employeeId,
          'employeeName': contract.employeeName,
          'vehicleId': contract.vehicleId,
          'vehiclePlate': contract.vehiclePlate, // <-- PLATE eklendi
          'type': contract.reference,
          'reference': contract.reference,
          'startDate': contract.startDate,
          'endDate': contract.endDate,
          'status': contract.status.toString(),
          'createdAt': contract.createdAt,
        });
        
        return;
      },
      errorMessage: 'Error adding contract',
    );
  }

  // Update a contract in Firestore
  Future<void> updateContract(contract_model.Contract contract, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('contracts')
            .doc(contract.id);
            
        await docRef.update({
          'employeeId': contract.employeeId,
          'employeeName': contract.employeeName,
          'vehicleId': contract.vehicleId,
          'vehiclePlate': contract.vehiclePlate, // <-- PLATE eklendi
          'type': contract.reference,
          'reference': contract.reference,
          'startDate': contract.startDate,
          'endDate': contract.endDate,
          'status': contract.status.toString(),
        });
        
        return;
      },
      errorMessage: 'Error updating contract',
    );
  }

  // Delete a contract from Firestore
  Future<void> deleteContract(String contractId, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('contracts')
            .doc(contractId)
            .delete();
            
        return;
      },
      errorMessage: 'Error deleting contract',
    );
  }

  // Fetch contracts for a specific user
  Future<List<contract_model.Contract>> fetchContracts({required String userId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contracts')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return contract_model.Contract(
          id: data['id'] ?? doc.id,
          employeeId: data['employeeId'] ?? '',
          employeeName: data['employeeName'] ?? '',
          vehicleId: data['vehicleId'] ?? '',
          vehiclePlate: data['vehiclePlate'], // <-- PLATE eklendi
          reference: data['type'] ?? '',
          startDate: (data['startDate'] is Timestamp)
              ? (data['startDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['startDate'].toString()) ?? DateTime.now(),
          endDate: (data['endDate'] is Timestamp)
              ? (data['endDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['endDate'].toString()) ?? DateTime.now(),
          status: _parseContractStatus(data['status']),
          createdAt: (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching contracts: $e');
      return [];
    }
  }

  // Helper to parse status from string
  contract_model.ContractStatus _parseContractStatus(dynamic status) {
    if (status is contract_model.ContractStatus) return status;
    if (status is String) {
      switch (status) {
        case 'ContractStatus.ongoing':
        case 'ongoing':
          return contract_model.ContractStatus.ongoing;
        case 'ContractStatus.expired':
        case 'completed':
        case 'expired':
          return contract_model.ContractStatus.expired;
        case 'ContractStatus.terminated':
        case 'terminated':
          return contract_model.ContractStatus.terminated;
        case 'ContractStatus.renewed':
        case 'renewed':
          return contract_model.ContractStatus.renewed;
        default:
          return contract_model.ContractStatus.ongoing;
      }
    }
    return contract_model.ContractStatus.ongoing;
  }

  // Araçları çek
  Future<List<Map<String, dynamic>>> fetchVehicles({required String userId}) async {
    return _handleFirestoreOperation<List<Map<String, dynamic>>>(
      operation: () async {
        Query query = _firestore
            .collection('users')
            .doc(userId)
            .collection('vehicles');
        query = query.orderBy('name', descending: false);
        final querySnapshot = await query.get();
        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
          };
        }).toList();
      },
      errorMessage: 'Error fetching vehicles',
      defaultValue: [],
    );
  }

  // Sözleşme ekle (supplier ile)
  Future<void> addContractWithSupplier(contract_model.Contract contract, String userId, String supplier) async {
    return _handleFirestoreOperation(
      operation: () async {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('contracts')
            .doc(contract.id);

        await docRef.set({
          'id': contract.id,
          'employeeId': contract.employeeId,
          'employeeName': contract.employeeName,
          'vehicleId': contract.vehicleId,
          'type': contract.reference,
          'reference': contract.reference,
          'supplier': supplier,
          'startDate': contract.startDate,
          'endDate': contract.endDate,
          'status': contract.status.toString(),
          'createdAt': contract.createdAt,
        });

        return;
      },
      errorMessage: 'Error adding contract',
    );
  }

  // Sözleşme güncelle (supplier ile)
  Future<void> updateContractWithSupplier(contract_model.Contract contract, String userId, String supplier) async {
    return _handleFirestoreOperation(
      operation: () async {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('contracts')
            .doc(contract.id);

        await docRef.update({
          'employeeId': contract.employeeId,
          'employeeName': contract.employeeName,
          'vehicleId': contract.vehicleId,
          'type': contract.reference,
          'reference': contract.reference,
          'supplier': supplier,
          'startDate': contract.startDate,
          'endDate': contract.endDate,
          'status': contract.status.toString(),
        });

        return;
      },
      errorMessage: 'Error updating contract',
    );
  }

  // Add an employee to Firestore
  Future<void> addEmployee(dynamic employee, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('employees')
            .doc(employee.id);
        await docRef.set(employee.toJson());
        return;
      },
      errorMessage: 'Error adding employee',
    );
  }

  // Update an employee in Firestore
  Future<void> updateEmployee(dynamic employee, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('employees')
            .doc(employee.id);
        await docRef.update(employee.toJson());
        return;
      },
      errorMessage: 'Error updating employee',
    );
  }

  // Delete an employee from Firestore
  Future<void> deleteEmployee(String employeeId, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('employees')
            .doc(employeeId)
            .delete();
        return;
      },
      errorMessage: 'Error deleting employee',
    );
  }

  // Add vehicle to Firestore
  Future<String> addVehicle(Vehicle vehicle, String userId) async {
    return _handleFirestoreOperation<String>(
      operation: () async {
        // Generate a unique ID if not provided
        final String vehicleId = vehicle.id.startsWith('new_') 
            ? _firestore.collection('users').doc(userId).collection('vehicles').doc().id 
            : vehicle.id;

        // Create a copy of the vehicle with the new ID
        final Vehicle vehicleWithId = Vehicle(
          id: vehicleId,
          model: vehicle.model,
          plate: vehicle.plate,
          year: vehicle.year,
        );
        
        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('vehicles')
            .doc(vehicleId)
            .set({
              'id': vehicleId,
              'model': vehicleWithId.model,
              'plate': vehicleWithId.plate,
              'year': vehicleWithId.year,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        return vehicleId;
      },
      errorMessage: 'Error adding vehicle',
    );
  }

  // Update vehicle in Firestore
  Future<void> updateVehicle(Vehicle vehicle, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('vehicles')
            .doc(vehicle.id)
            .update({
              'model': vehicle.model,
              'plate': vehicle.plate,
              'year': vehicle.year,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        return;
      },
      errorMessage: 'Error updating vehicle',
    );
  }

  // Delete vehicle from Firestore
  Future<void> deleteVehicle(String vehicleId, String userId) async {
    return _handleFirestoreOperation(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('vehicles')
            .doc(vehicleId)
            .delete();
        
        return;
      },
      errorMessage: 'Error deleting vehicle',
    );
  }

  // Fetch vehicles from Firestore
  Future<List<Vehicle>> fetchVehiclesWithDetails({required String userId}) async {
    return _handleFirestoreOperation<List<Vehicle>>(
      operation: () async {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('vehicles')
            .orderBy('model')
            .get();
        
        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Vehicle(
            id: doc.id,
            model: data['model'] ?? '',
            plate: data['plate'] ?? '',
            year: data['year'] != null ? int.tryParse(data['year'].toString()) : null,
          );
        }).toList();
      },
      errorMessage: 'Error fetching vehicles',
      defaultValue: [], // Return empty list on error
    );
  }
}