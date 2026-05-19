import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/bank_statement_model.dart';
import '../models/transaction_model.dart';
import '../services/pdf_parser_service.dart';
import '../services/llm_parser_service.dart';
import '../services/llm_insight_service.dart';
import 'package:read_pdf_text/read_pdf_text.dart';

class BankAnalyzerService {
  /// Parses a bank statement file (PDF or CSV).
  /// This now uses the local PDFParser for PDF files.
  Future<AnalyzedStatement?> parseStatement(File file, {String? apiKey}) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    if (extension == 'pdf') {
      List<Map<String, dynamic>> jsonTransactions = [];
      
      try {
        if (apiKey != null && apiKey.isNotEmpty) {
          print("Using LLM Parser for PDF");
          final text = await ReadPdfText.getPDFtext(file.path);
          final llmParser = LlmParserService(apiKey);
          jsonTransactions = await llmParser.parseTransactionsFromText(text);
          print("Transactions parsed by LLM: $jsonTransactions");
        } else {
          print("Using Regex Parser for PDF");
          jsonTransactions = await PDFParser.parseBankStatement(file);
        }
      } catch (e) {
        print("Parser Error: $e");
        if (apiKey != null && apiKey.isNotEmpty) {
          print("LLM parsing failed, falling back to regex parser...");
          jsonTransactions = await PDFParser.parseBankStatement(file);
        } else {
          rethrow;
        }
      }

      if (jsonTransactions.isEmpty) return null;
      final bankTransactions = _convertToBankTransactions(jsonTransactions);
      return _generateAnalysisFromTransactions(bankTransactions, apiKey: apiKey);
      
    }
    else if (extension == 'json') {
      print("Parsing JSON statement...");
      final content = await file.readAsString();
      List<Map<String, dynamic>> jsonTransactions = [];

      try {
        final decoded = jsonDecode(content);
        if (decoded is List) {
          jsonTransactions = decoded.map((e) => e as Map<String, dynamic>).toList();
        } else if (decoded is Map && decoded.containsKey('transactions')) {
          final txList = decoded['transactions'];
          if (txList is List) {
            jsonTransactions = txList.map((e) => e as Map<String, dynamic>).toList();
          }
        }
        
        // If we found transactions but they don't have the expected keys, 
        // we might still want to use LLM to normalize them.
        if (jsonTransactions.isNotEmpty && !jsonTransactions.first.containsKey('debit') && !jsonTransactions.first.containsKey('credit') && apiKey != null) {
           print("JSON found but schema is different, using LLM for normalization...");
           final llmParser = LlmParserService(apiKey);
           jsonTransactions = await llmParser.parseTransactionsFromText(content);
        }

      } catch (e) {
        print("Direct JSON parse failed: $e");
        if (apiKey != null && apiKey.isNotEmpty) {
          print("Falling back to LLM for JSON parsing...");
          final llmParser = LlmParserService(apiKey);
          jsonTransactions = await llmParser.parseTransactionsFromText(content);
        } else {
          throw Exception("Failed to parse JSON file and no API key provided for AI parsing.");
        }
      }

      if (jsonTransactions.isEmpty) return null;
      final bankTransactions = _convertToBankTransactions(jsonTransactions);
      return _generateAnalysisFromTransactions(bankTransactions, apiKey: apiKey);

    } else {
      print("Unsupported file type: $extension");
    }
    
    // CSV parsing could be added here in the future
    return null;
  }

  List<BankTransaction> _convertToBankTransactions(List<Map<String, dynamic>> rawTx) {
    return rawTx.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      final double debit = data['debit'] ?? 0.0;
      final double credit = data['credit'] ?? 0.0;
      final double amount = (debit > 0) ? debit : credit;
      final type = (debit > 0) ? TransactionType.outbound : TransactionType.inbound;
      
      // Basic categorization based on description
      final category = _categorizeDescription(data['description'] ?? '');
      
      return BankTransaction(
        id: 'tx_$index',
        description: data['description'] ?? 'Bank Transaction',
        amount: amount,
        date: _parseDate(data['date'] ?? ''),
        type: type,
        creditAmount: data['credit'] ?? 0.0 ,
        debitAmount: data['debit'] ?? 0.0,
        category: category,
      );
    }).toList();
  }

  DateTime _parseDate(String dateStr) {
    try {
      // Basic DD/MM/YYYY parser
      final parts = dateStr.split(RegExp(r'[/-]'));
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // Year
          int.parse(parts[1]), // Month
          int.parse(parts[0]), // Day
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  String _categorizeDescription(String desc) {
    final lower = desc.toLowerCase();
    if (lower.contains('amazon') || lower.contains('flipkart') || lower.contains('shopping')) return 'Shopping';
    if (lower.contains('starbucks') || lower.contains('zomato') || lower.contains('swiggy') || lower.contains('rest')) return 'Food & Dining';
    if (lower.contains('uber') || lower.contains('ola') || lower.contains('fuel') || lower.contains('petrol')) return 'Transport';
    if (lower.contains('netflix') || lower.contains('spotify') || lower.contains('hotstar')) return 'Entertainment';
    if (lower.contains('emi') || lower.contains('loan') || lower.contains('mortgage')) return 'Loans';
    if (lower.contains('salary') || lower.contains('credit') || lower.contains('neft')) return 'Income';
    return 'General';
  }

  Future<AnalyzedStatement> _generateAnalysisFromTransactions(List<BankTransaction> transactions, {String? apiKey}) async {
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
    double totalInflow = inbound.fold(0.0, (sum, t) => sum + t.amount);
    
    // Update percentages
    for (var i = 0; i < categorySpending.length; i++) {
        final c = categorySpending[i];
        categorySpending[i] = CategorySpending(
            category: c.category,
            amount: c.amount,
            percentage: totalOutflow > 0 ? (c.amount / totalOutflow) * 100 : 0.0,
            color: c.color,
            transactions: c.transactions,
        );
    }

    final summary = StatementSummary(
      totalInflow: totalInflow,
      totalOutflow: totalOutflow,
      netChange: totalInflow - totalOutflow,
      transactionCount: transactions.length,
      healthScore: _calculateHealthScore(totalInflow, totalOutflow),
    );

    return AnalyzedStatement(
      summary: summary,
      outboundCategories: categorySpending,
      inboundTransactions: inbound,
      insights: await _generateInsights(transactions, summary, apiKey: apiKey),
      analyzedAt: DateTime.now(),
    );
  }

  Future<List<AIInsight>> _generateInsights(
    List<BankTransaction> transactions, 
    StatementSummary summary, 
    {String? apiKey}
  ) async {
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final insightService = LlmInsightService(apiKey);
        return await insightService.generateInsights(
          transactions: transactions, 
          summary: summary
        );
      } catch (e) {
        print("Falling back to basic insights due to error: $e");
        return _generateBasicInsights(summary.totalInflow, summary.totalOutflow);
      }
    }
    return _generateBasicInsights(summary.totalInflow, summary.totalOutflow);
  }

  int _calculateHealthScore(double inflow, double outflow) {
    if (inflow <= 0) return 30;
    final ratio = outflow / inflow;
    if (ratio <= 0.3) return 95;
    if (ratio <= 0.5) return 85;
    if (ratio <= 0.7) return 70;
    if (ratio <= 0.9) return 50;
    return 35;
  }

  List<AIInsight> _generateBasicInsights(double inflow, double outflow) {
    final insights = <AIInsight>[];
    
    if (outflow > inflow) {
      insights.add(AIInsight(
        title: 'Negative Cash Flow',
        content: 'Your spending exceeded your income this month. Review your top categories to identify potential savings.',
        icon: LucideIcons.trendingDown,
        color: Colors.red,
      ));
    } else if (outflow < inflow * 0.5) {
      insights.add(AIInsight(
        title: 'Strong Savings Rate',
        content: 'Excellent! You saved more than 50% of your income. Consider investing the surplus for long-term growth.',
        icon: LucideIcons.sparkles,
        color: Colors.green,
      ));
    }

    insights.add(AIInsight(
      title: 'Monthly Review',
      content: 'Regularly analyzing your statements helps in maintaining financial discipline and reaching your goals faster.',
      icon: LucideIcons.shieldCheck,
      color: Colors.blue,
    ));

    return insights;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining': return Colors.orange;
      case 'Shopping': return Colors.purple;
      case 'Transport': return Colors.blue;
      case 'Entertainment': return Colors.red;
      case 'Loans': return Colors.teal;
      case 'Income': return Colors.green;
      default: return Colors.grey;
    }
  }
}
