import 'package:cloud_firestore/cloud_firestore.dart';
import 'investment_allocation.dart';

class InvestmentSummary {
  final String id;
  final String userId;
  final String memberId;
  final String memberName;
  final String type;
  final double currentValue;
  final double? investedAmount;
  final DateTime lastUpdated;
  final List<InvestmentAllocation> allocation;

  InvestmentSummary({
    required this.id,
    required this.userId,
    required this.memberId,
    required this.memberName,
    required this.type,
    required this.currentValue,
    this.investedAmount,
    required this.lastUpdated,
    required this.allocation,
  });

  factory InvestmentSummary.fromFirestore(String id, Map<String, dynamic> data) {
    return InvestmentSummary(
      id: id,
      userId: data['userId'] ?? '',
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      type: data['type'] ?? '',
      currentValue: (data['currentValue'] ?? 0).toDouble(),
      investedAmount: data['investedAmount']?.toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allocation: (data['allocation'] as List<dynamic>?)
              ?.map((e) => InvestmentAllocation.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'memberId': memberId,
      'memberName': memberName,
      'type': type,
      'currentValue': currentValue,
      'investedAmount': investedAmount,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'allocation': allocation.map((e) => e.toMap()).toList(),
    };
  }
}
