import 'package:cloud_firestore/cloud_firestore.dart';

class BankInfo {
  final String accountId;
  final String accountType;
  final double currentBalance;
  final String currency;
  final String bankName;
  final DateTime lastUpdated;

  BankInfo({
    required this.accountId,
    required this.accountType,
    required this.currentBalance,
    required this.currency,
    required this.bankName,
    required this.lastUpdated,
  });

  factory BankInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BankInfo(
      accountId: data['account_id'] ?? '',
      accountType: data['account_type'] ?? '',
      currentBalance: (data['current_balance'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'INR',
      bankName: data['bank_name'] ?? '',
      lastUpdated: (data['last_updated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'account_type': accountType,
    'current_balance': currentBalance,
    'currency': currency,
    'bank_name': bankName,
    'last_updated': lastUpdated.toIso8601String(),
  };
}

class BankPolicy {
  final String id;
  final String title;
  final String description;
  final String category; // e.g., 'Loans', 'Savings', 'Cards'
  final Map<String, dynamic> terms;

  BankPolicy({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.terms,
  });

  factory BankPolicy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BankPolicy(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      terms: data['terms'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'terms': terms,
  };
}

class FirebaseTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'credit' or 'debit'
  final String category;
  final String status;

  FirebaseTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.status,
  });

  factory FirebaseTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseTransaction(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type,
    'category': category,
    'status': status,
  };
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? widgetData;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.widgetData,
  });
}

