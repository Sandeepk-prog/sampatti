import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/bank_statement_model.dart';
import '../services/bank_analyzer_service.dart';
import '../services/firebase_chat_service.dart';
import '../models/chat_models.dart';

enum AnalyzerState {
  idle,
  uploading,
  parsing,
  categorizing,
  analyzing,
  ready,
  error
}

class BankAnalyzerProvider extends ChangeNotifier {
  AnalyzerState _state = AnalyzerState.idle;
  String? _errorMessage;
  AnalyzedStatement? _analyzedData;
  double _uploadProgress = 0.0;
  BankInfo? _bankInfo;
  final FirebaseChatService _fbService = FirebaseChatService();

  AnalyzerState get state => _state;
  String? get errorMessage => _errorMessage;
  AnalyzedStatement? get analyzedData => _analyzedData;
  double get uploadProgress => _uploadProgress;
  BankInfo? get bankInfo => _bankInfo;

  bool get isProcessing => 
    _state == AnalyzerState.uploading || 
    _state == AnalyzerState.parsing || 
    _state == AnalyzerState.categorizing || 
    _state == AnalyzerState.analyzing;

  String get processingMessage {
    switch (_state) {
      case AnalyzerState.uploading:
        return 'Uploading statement...';
      case AnalyzerState.parsing:
        return 'Parsing transactions...';
      case AnalyzerState.categorizing:
        return 'Categorizing spending habits...';
      case AnalyzerState.analyzing:
        return 'AI is generating financial insights...';
      default:
        return '';
    }
  }

  void reset() {
    _state = AnalyzerState.idle;
    _errorMessage = null;
    _analyzedData = null;
    _uploadProgress = 0.0;
    _bankInfo = null;
    notifyListeners();
  }

  Future<void> fetchBankInfo(String userId) async {
    if (_bankInfo != null) return; // Already fetched
    
    try {
      // Ensure sample data exists (similar to ChatProvider)
      await _fbService.seedSampleData(userId);
      
      _bankInfo = await _fbService.getBankInfo(userId);
      notifyListeners();
    } catch (e) {
      print('Error fetching bank info in provider: $e');
    }
  }

  Future<void> startDemo() async {
    _state = AnalyzerState.uploading;
    _errorMessage = null;
    _uploadProgress = 0.0;
    notifyListeners();

    // Simulated flow
    await _simulateStep(AnalyzerState.uploading, 1500, (p) => _uploadProgress = p);
    await _simulateStep(AnalyzerState.parsing, 2000);
    await _simulateStep(AnalyzerState.categorizing, 2500);
    await _simulateStep(AnalyzerState.analyzing, 3000);

    _analyzedData = _generateMockData();
    _state = AnalyzerState.ready;
    notifyListeners();
  }

  Future<void> analyzeStatement(File file, {String? apiKey}) async {
    _state = AnalyzerState.uploading;
    _errorMessage = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // 1. Uploading (Simulated progress for now since it's local parsing, but useful for UX)
      await _simulateStep(AnalyzerState.uploading, 1000, (p) => _uploadProgress = p);
      
      // 2. Parsing
      _state = AnalyzerState.parsing;
      notifyListeners();
      final service = BankAnalyzerService();
      final result = await service.parseStatement(file, apiKey: apiKey);
      print("Parsed Result: $result");

      
      if (result == null) {
        throw Exception('Failed to parse the bank statement. Please ensure it is a valid PDF or CSV.');
      }
      
      // 3. Categorizing
      await _simulateStep(AnalyzerState.categorizing, 1500);
      
      // 4. Analyzing
      await _simulateStep(AnalyzerState.analyzing, 1500);
      
      _analyzedData = result;
      _state = AnalyzerState.ready;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AnalyzerState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _simulateStep(AnalyzerState newState, int ms, [Function(double)? onProgress]) async {
    _state = newState;
    notifyListeners();
    
    if (onProgress != null) {
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(Duration(milliseconds: ms ~/ 10));
        onProgress(i / 10.0);
        notifyListeners();
      }
    } else {
      await Future.delayed(Duration(milliseconds: ms));
    }
  }

  AnalyzedStatement _generateMockData() {
    final now = DateTime.now();
    
    final transactions = [
      BankTransaction(
        id: '1',
        description: 'Salary Credit - Tech Corp',
        amount: 85000.0,
        date: now.subtract(const Duration(days: 2)),
        type: TransactionType.inbound,
        category: 'Income',
      ),
      BankTransaction(
        id: '2',
        description: 'Starbucks Coffee',
        amount: 450.0,
        date: now.subtract(const Duration(days: 1)),
        type: TransactionType.outbound,
        category: 'Food & Dining',
      ),
      BankTransaction(
        id: '3',
        description: 'Amazon.in',
        amount: 2500.0,
        date: now.subtract(const Duration(days: 3)),
        type: TransactionType.outbound,
        category: 'Shopping',
      ),
      BankTransaction(
        id: '4',
        description: 'Uber India',
        amount: 650.0,
        date: now.subtract(const Duration(days: 4)),
        type: TransactionType.outbound,
        category: 'Transport',
      ),
      BankTransaction(
        id: '5',
        description: 'Netflix Subscription',
        amount: 499.0,
        date: now.subtract(const Duration(days: 5)),
        type: TransactionType.outbound,
        category: 'Entertainment',
      ),
      BankTransaction(
        id: '6',
        description: 'HDFC Home Loan EMI',
        amount: 32000.0,
        date: now.subtract(const Duration(days: 10)),
        type: TransactionType.outbound,
        category: 'Loans',
      ),
      BankTransaction(
        id: '7',
        description: 'Dividend - Reliance',
        amount: 1200.0,
        date: now.subtract(const Duration(days: 12)),
        type: TransactionType.inbound,
        category: 'Investment',
      ),
    ];

    final outbound = transactions.where((t) => t.type == TransactionType.outbound).toList();
    final inbound = transactions.where((t) => t.type == TransactionType.inbound).toList();

    final categories = <String, List<BankTransaction>>{};
    for (var t in outbound) {
      categories.putIfAbsent(t.category, () => []).add(t);
    }

    final categorySpending = categories.entries.map((e) {
      final total = e.value.fold(0.0, (sum, t) => sum + t.amount);
      return CategorySpending(
        category: e.key,
        amount: total,
        percentage: 0.0, // Calculated later
        color: _getCategoryColor(e.key),
        transactions: e.value,
      );
    }).toList();

    double totalOutflow = categorySpending.fold(0.0, (sum, c) => sum + c.amount);
    
    // Update percentages
    for (var i = 0; i < categorySpending.length; i++) {
        final c = categorySpending[i];
        categorySpending[i] = CategorySpending(
            category: c.category,
            amount: c.amount,
            percentage: (c.amount / totalOutflow) * 100,
            color: c.color,
            transactions: c.transactions,
        );
    }

    return AnalyzedStatement(
      summary: StatementSummary(
        totalInflow: inbound.fold(0.0, (sum, t) => sum + t.amount),
        totalOutflow: totalOutflow,
        netChange: inbound.fold(0.0, (sum, t) => sum + t.amount) - totalOutflow,
        transactionCount: transactions.length,
        healthScore: 78,
      ),
      outboundCategories: categorySpending,
      inboundTransactions: inbound,
      insights: [
        AIInsight(
          title: 'High EMI Ratio',
          content: 'Your loan EMIs account for 38% of your monthly income. Aim to keep this under 30%.',
          icon: LucideIcons.trendingUp,
          color: Colors.orange,
        ),
        AIInsight(
          title: 'Subscription Savings',
          content: 'We noticed multiple entertainment subscriptions. Consolidating them could save you ₹1,200 annually.',
          icon: LucideIcons.sparkles,
          color: Colors.blue,
        ),
        AIInsight(
          title: 'Emergency Fund',
          content: 'You have a healthy net change this month. Consider moving ₹10,000 to a high-yield liquid fund.',
          icon: LucideIcons.shieldCheck,
          color: Colors.green,
        ),
      ],
      analyzedAt: DateTime.now(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining': return Colors.orange;
      case 'Shopping': return Colors.purple;
      case 'Transport': return Colors.blue;
      case 'Entertainment': return Colors.red;
      case 'Loans': return Colors.teal;
      default: return Colors.grey;
    }
  }
}
