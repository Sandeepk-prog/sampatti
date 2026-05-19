import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment_summary.dart';
import '../models/investment_holding.dart';
import '../models/investment_allocation.dart';
import '../repositories/investment_repository.dart';

class FirestoreInvestmentService implements InvestmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<InvestmentSummary>> getInvestmentSummaries(String userId, String memberId) async {
    try {
      final snapshot = await _firestore
          .collection('investment_summaries')
          .where('userId', isEqualTo: userId)
          .where('memberId', isEqualTo: memberId)
          .get();
      return snapshot.docs.map((doc) => InvestmentSummary.fromFirestore(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error fetching investment summaries: $e');
      rethrow;
    }
  }

  @override
  Future<List<InvestmentHolding>> getInvestmentHoldings(String userId, String memberId, String type) async {
    try {
      final snapshot = await _firestore
          .collection('investment_holdings')
          .where('userId', isEqualTo: userId)
          .where('memberId', isEqualTo: memberId)
          .where('type', isEqualTo: type)
          .get();
      return snapshot.docs.map((doc) => InvestmentHolding.fromFirestore(doc.id, doc.data())).toList();
    } catch (e) {
      print('Error fetching investment holdings: $e');
      rethrow;
    }
  }

  @override
  Future<bool> checkInvestmentDataExists(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('investment_summaries')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking investment data existence: $e');
      return false;
    }
  }

  @override
  Future<void> seedSampleInvestmentData(String userId) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // --- Personal Mutual Funds Summary ---
      final mfSummary = InvestmentSummary(
        id: '${userId}_personal_mutual_fund',
        userId: userId,
        memberId: 'personal',
        memberName: 'Personal Account',
        type: 'mutual_fund',
        currentValue: 1801932.0,
        investedAmount: 1500000.0,
        lastUpdated: now,
        allocation: [
          InvestmentAllocation(label: 'Equity', percentage: 73.0, colorHex: '0xFF2196F3'),
          InvestmentAllocation(label: 'Balance', percentage: 27.0, colorHex: '0xFF4CAF50'),
        ],
      );
      batch.set(_firestore.collection('investment_summaries').doc(mfSummary.id), mfSummary.toFirestore());

      // --- Personal Equity Summary ---
      final eqSummary = InvestmentSummary(
        id: '${userId}_personal_equity',
        userId: userId,
        memberId: 'personal',
        memberName: 'Personal Account',
        type: 'equity',
        currentValue: 180190.0,
        investedAmount: 150000.0,
        lastUpdated: now,
        allocation: [
          InvestmentAllocation(label: 'BLUECHIP', percentage: 40.0, colorHex: '0xFF2196F3'),
          InvestmentAllocation(label: 'GOOD', percentage: 30.0, colorHex: '0xFF4CAF50'),
          InvestmentAllocation(label: 'AVERAGE', percentage: 20.0, colorHex: '0xFFFF9800'),
          InvestmentAllocation(label: 'POOR', percentage: 10.0, colorHex: '0xFFF44336'),
        ],
      );
      batch.set(_firestore.collection('investment_summaries').doc(eqSummary.id), eqSummary.toFirestore());

      // --- Mutual Funds Holdings ---
      final mfHoldings = [
        InvestmentHolding(id: '', userId: userId, memberId: 'personal', type: 'mutual_fund', name: 'NIPPON INDIA PHARMA FUND', value: 1158282.0, category: 'Equity', colorHex: '0xFF2196F3'),
        InvestmentHolding(id: '', userId: userId, memberId: 'personal', type: 'mutual_fund', name: 'HDFC BALANCED ADVANTAGE', value: 410210.0, category: 'Balance', colorHex: '0xFF4CAF50'),
        InvestmentHolding(id: '', userId: userId, memberId: 'personal', type: 'mutual_fund', name: 'SBI SMALL CAP FUND', value: 233400.0, category: 'Equity', colorHex: '0xFF2196F3'),
      ];
      for (var h in mfHoldings) {
        batch.set(_firestore.collection('investment_holdings').doc(), h.toFirestore());
      }

      // --- Equity Holdings ---
      final eqHoldings = [
        InvestmentHolding(id: '', userId: userId, memberId: 'personal', type: 'equity', name: 'L&T', ticker: 'LT', units: '5 Units', value: 1930.0, category: 'BLUECHIP', colorHex: '0xFF2196F3'),
        InvestmentHolding(id: '', userId: userId, memberId: 'personal', type: 'equity', name: 'Reliance Industries', ticker: 'RELIANCE', units: '12 Units', value: 2450.0, category: 'GOOD', colorHex: '0xFF4CAF50'),
        InvestmentHolding(id: '', userId: userId, memberId: 'personal', type: 'equity', name: 'Tata Motors', ticker: 'TATA MOTORS', units: '25 Units', value: 640.0, category: 'AVERAGE', colorHex: '0xFFFF9800'),
        InvestmentHolding(id: '', userId: userId, memberId: 'personal', type: 'equity', name: 'Zomato', ticker: 'ZOMATO', units: '100 Units', value: 120.0, category: 'POOR', colorHex: '0xFFF44336'),
      ];
      for (var h in eqHoldings) {
        batch.set(_firestore.collection('investment_holdings').doc(), h.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      print('Error seeding sample investment data: $e');
      rethrow;
    }
  }
}
