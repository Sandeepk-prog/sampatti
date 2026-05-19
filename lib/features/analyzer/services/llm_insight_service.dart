import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleai_dart/googleai_dart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/bank_statement_model.dart';

class LlmInsightException implements Exception {
  final String message;
  LlmInsightException(this.message);
  @override
  String toString() => message;
}

class LlmInsightService {
  final String apiKey;

  LlmInsightService(this.apiKey);

  Future<List<AIInsight>> generateInsights({
    required List<BankTransaction> transactions,
    required StatementSummary summary,
  }) async {
    if (transactions.isEmpty) return [];

    final client = GoogleAIClient.withApiKey(apiKey);
    
    // 1. Prepare a compact summary for the prompt
    final summaryText = _buildCompactSummary(transactions, summary);
    
    final prompt = '''
You are a premium financial advisor AI. Analyze the following bank statement summary and generate exactly 5 diverse and high-quality financial insights.

Financial Summary:
$summaryText

Generate 5 insights covering:
1. Overall Summary (Pulse): A headline that summarizes the financial month.
2. Spending Pattern: Analyze major categories or trends.
3. Behavioral Insight: Identify a specific habit (e.g., weekend spending, frequency of transfers).
4. Risk Alert/Opportunity: Financial warning or a missed saving opportunity.
5. Recommendation: Actionable advice to improve financial health.

Rules:
- Response MUST be a valid JSON array of objects.
- Each object MUST have: "title", "content", "type", and "premium_color".
- "type" MUST be one of: "summary", "pattern", "behavior", "risk", "suggestion".
- "premium_color" MUST be one of these hex codes: "#0F172A" (Navy), "#065F46" (Emerald), "#4C1D95" (Purple), "#7F1D1D" (Crimson), "#92400E" (Bronze).
- Content should be concise, professional, and insightful.

Output Format:
[
  {
    "title": "String",
    "content": "String",
    "type": "String",
    "premium_color": "String"
  }
]
''';

    try {
      final response = await client.models.generateContent(
        request: GenerateContentRequest(
          contents: [
            Content.text(prompt),
          ],
        ),
        model: 'gemini-1.5-flash',
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw LlmInsightException('Empty response from AI.');
      }

      return _extractInsightsFromJson(text);
    } catch (e) {
      print('LlmInsightService Error: $e');
      throw LlmInsightException('Failed to generate insights: $e');
    }
  }

  String _buildCompactSummary(List<BankTransaction> transactions, StatementSummary summary) {
    // Group transactions by category for concise summary
    final categoryMap = <String, double>{};
    for (var tx in transactions) {
      if (tx.type == TransactionType.outbound) {
        categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
      }
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategories = sortedCategories.take(5).map((e) => "${e.key}: ₹${e.value.toStringAsFixed(0)}").join(", ");

    // Get top 3 largest transactions
    final topTx = (transactions.toList()..sort((a, b) => b.amount.compareTo(a.amount)))
        .take(3)
        .map((tx) => "${tx.description} (₹${tx.amount.toStringAsFixed(0)})")
        .join(", ");

    return '''
Total Inflow: ₹${summary.totalInflow.toStringAsFixed(0)}
Total Outflow: ₹${summary.totalOutflow.toStringAsFixed(0)}
Net Change: ₹${summary.netChange.toStringAsFixed(0)}
Health Score: ${summary.healthScore}/100
Top Spending Categories: $topCategories
Largest Transactions: $topTx
Total Transactions: ${summary.transactionCount}
''';
  }

  List<AIInsight> _extractInsightsFromJson(String responseText) {
    try {
      String jsonStr = responseText.trim();
      if (jsonStr.contains('```json')) {
        final start = jsonStr.indexOf('```json') + 7;
        final end = jsonStr.lastIndexOf('```');
        jsonStr = jsonStr.substring(start, end).trim();
      } else if (jsonStr.contains('```')) {
        final start = jsonStr.indexOf('```') + 3;
        final end = jsonStr.lastIndexOf('```');
        jsonStr = jsonStr.substring(start, end).trim();
      }

      final List<dynamic> parsed = jsonDecode(jsonStr);
      return parsed.map((item) {
        final type = item['type']?.toString() ?? 'summary';
        final colorHex = item['premium_color']?.toString() ?? '#0F172A';
        
        return AIInsight(
          title: item['title']?.toString() ?? 'Insight',
          content: item['content']?.toString() ?? '',
          icon: _getIconForType(type),
          color: _getColorFromHex(colorHex),
        );
      }).toList();
    } catch (e) {
      throw LlmInsightException('JSON Parsing failed: $e');
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'summary': return LucideIcons.trendingUp;
      case 'pattern': return LucideIcons.chartPie;
      case 'behavior': return LucideIcons.users;
      case 'risk': return LucideIcons.octagonAlert;
      case 'suggestion': return LucideIcons.lightbulb;
      default: return LucideIcons.sparkles;
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
