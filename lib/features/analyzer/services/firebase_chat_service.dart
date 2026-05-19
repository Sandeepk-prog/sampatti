import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_models.dart';

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Names
  static const String bankInfoCollection = 'bank_info';
  static const String bankPoliciesCollection = 'bank_policies';
  static const String transactionsCollection = 'transactions';

  Future<BankInfo?> getBankInfo(String userId) async {
    try {
      final doc = await _firestore.collection(bankInfoCollection).doc(userId).get();
      if (doc.exists) {
        return BankInfo.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching bank info: $e');
      return null;
    }
  }

  Future<List<BankPolicy>> getBankPolicies(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(bankPoliciesCollection)
          .where('user_id', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => BankPolicy.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching bank policies: $e');
      return [];
    }
  }

  Future<List<FirebaseTransaction>> getRecentTransactions(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(transactionsCollection)
          .where('user_id', isEqualTo: userId)
          //.orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => FirebaseTransaction.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Future<void> seedSampleData(String userId) async {
    try {
      // 1. Check if bank info exists
      final bankInfoDoc = await _firestore.collection(bankInfoCollection).doc(userId).get();
      if (!bankInfoDoc.exists) {
        print('Seeding sample bank info for user: $userId');
        await _firestore.collection(bankInfoCollection).doc(userId).set({
          'account_id': 'ACC-${userId.substring(0, 5).toUpperCase()}',
          'account_type': 'Savings',
          'current_balance': 125430.50,
          'currency': 'INR',
          'bank_name': 'HDFC Bank',
          'last_updated': FieldValue.serverTimestamp(),
          'user_id': userId,
        });
      }

      // 2. Check if transactions exist
      final transactionsSnapshot = await _firestore
          .collection(transactionsCollection)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (transactionsSnapshot.docs.isEmpty) {
        print('Seeding sample transactions for user: $userId');
        final batch = _firestore.batch();
        final samples = [
          {'description': 'Amazon.in', 'amount': 1200.0, 'type': 'debit', 'category': 'Shopping'},
          {'description': 'Salary Credit', 'amount': 75000.0, 'type': 'credit', 'category': 'Income'},
          {'description': 'Starbucks Coffee', 'amount': 450.0, 'type': 'debit', 'category': 'Food & Drinks'},
          {'description': 'Rent Payment', 'amount': 15000.0, 'type': 'debit', 'category': 'Housing'},
          {'description': 'Zomato Order', 'amount': 320.0, 'type': 'debit', 'category': 'Food & Drinks'},
        ];

        for (var i = 0; i < samples.length; i++) {
          final docRef = _firestore.collection(transactionsCollection).doc();
          batch.set(docRef, {
            ...samples[i],
            'user_id': userId,
            'date': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i))),
            'status': 'completed',
          });
        }
        await batch.commit();
      }

      // 3. Check if policies exist
      final policiesSnapshot = await _firestore
          .collection(bankPoliciesCollection)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (policiesSnapshot.docs.isEmpty) {
        print('Seeding sample policies for user: $userId');
        final batch = _firestore.batch();
        final samples = [
          {
            'title': 'Minimum Balance Policy',
            'description': 'Maintenance of average monthly balance.',
            'category': 'Savings',
            'terms': {'min_balance': 10000, 'penalty': 500}
          },
          {
            'title': 'Personal Loan Eligibility',
            'description': 'Pre-approved loan offers for active savers.',
            'category': 'Loans',
            'terms': {'interest_rate': '10.5%', 'max_tenure': '5 years'}
          },
          {
            'title': 'Card Security Policy',
            'description': 'Protection against unauthorized transactions.',
            'category': 'Security',
            'terms': {'reporting_window': '24 hours', 'liability': 'Zero'}
          },
        ];

        for (var sample in samples) {
          final docRef = _firestore.collection(bankPoliciesCollection).doc();
          batch.set(docRef, {
            ...sample,
            'user_id': userId,
          });
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error seeding sample data: $e');
    }
  }
}
