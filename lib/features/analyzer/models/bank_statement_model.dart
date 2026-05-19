import 'package:flutter/material.dart';

enum TransactionType { inbound, outbound }

class BankTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String? subCategory;
  final double? creditAmount;
  final double? debitAmount;
  final double? balance;

  BankTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.subCategory,
    this.creditAmount,
    this.debitAmount,
    this.balance,
  });
}

class CategorySpending {
  final String category;
  final double amount;
  final double percentage;
  final Color color;
  final List<BankTransaction> transactions;

  CategorySpending({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.transactions,
  });
}

class AIInsight {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  AIInsight({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });
}

class StatementSummary {
  final double totalInflow;
  final double totalOutflow;
  final double netChange;
  final int transactionCount;
  final int healthScore; // 0-100

  StatementSummary({
    required this.totalInflow,
    required this.totalOutflow,
    required this.netChange,
    required this.transactionCount,
    required this.healthScore,
  });
}

class AnalyzedStatement {
  final StatementSummary summary;
  final List<CategorySpending> outboundCategories;
  final List<BankTransaction> inboundTransactions;
  final List<AIInsight> insights;
  final DateTime analyzedAt;

  AnalyzedStatement({
    required this.summary,
    required this.outboundCategories,
    required this.inboundTransactions,
    required this.insights,
    required this.analyzedAt,
  });
}
