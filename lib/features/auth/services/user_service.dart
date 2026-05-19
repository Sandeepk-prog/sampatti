import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dashboard/models/insight_data.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'users';

  /// Synchronizes user details with Firestore.
  /// If the user exists, it updates the name and email.
  /// If the user doesn't exist, it creates a new document.
  Future<void> syncUser(AppUser user) async {
    try {
      final userDoc = _firestore.collection(_collectionPath).doc(user.id);
      
      // Use set with merge: true to avoid overwriting existing fields like cas_upload_url
      // if they already have a value and we are just syncing profile info.
      // However, for the initial sync, we want to ensure cas_upload_url exists.
      
      final snapshot = await userDoc.get();
      
      if (!snapshot.exists) {
        // New user: Create with initial empty casUrl
        await userDoc.set(user.toMap());
      } else {
        // Existing user: Update only Name and Email to keep them in sync
        // We do NOT update cas_url here to avoid resetting it if it was already set
        await userDoc.update({
          'name': user.name,
          'email': user.email,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the cas_url and file_type for a user.
  Future<void> updateCasUrl(String userId, String url, String fileType) async {
    try {
      await _firestore.collection(_collectionPath).doc(userId).update({
        'cas_url': url,
        'cas_file_type': fileType,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Updates insights and last_updated for a user.
  /// Returns the timestamp of the update.
  Future<DateTime> updateInsights(String userId, List<InsightData> insights) async {
    try {
      final now = DateTime.now();
      await _firestore.collection(_collectionPath).doc(userId).update({
        'insights': insights.map((i) => i.toFirestore()).toList(),
        'last_updated': now.toIso8601String(),
      });
      return now;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches user details from Firestore.
  Future<AppUser?> getUser(String userId) async {
    try {
      final snapshot = await _firestore.collection(_collectionPath).doc(userId).get();
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
