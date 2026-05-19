import 'dart:convert';
import 'package:googleai_dart/googleai_dart.dart';
import '../models/bank_statement_model.dart';
import '../models/chat_models.dart';

class LlmChatException implements Exception {
  final String message;
  LlmChatException(this.message);
  @override
  String toString() => message;
}



class LlmChatService {
  final String apiKey;
  late final GoogleAIClient _client;

  LlmChatService(this.apiKey) {
    _client = GoogleAIClient.withApiKey(apiKey);
  }

  Future<String> getChatResponse({
    BankInfo? bankInfo,
    List<BankPolicy>? policies,
    List<FirebaseTransaction>? fbTransactions,
    List<BankTransaction>? localTransactions,
    String? casData,
    required List<ChatMessage> history,
    required String userQuery,
  }) async {
    try {
      final contextJson = _prepareAllContext(
        bankInfo: bankInfo,
        policies: policies,
        fbTransactions: fbTransactions,
        casData: casData,
        localTransactions: localTransactions,
      );
      
      final systemPrompt = '''
You are "Sampatti AI", a premium, world-class financial assistant. 
Your goal is to provide precise, insightful, and empathetic financial advice based on the user's data provided below.

DATA CONTEXT (JSON):
 ${contextJson}

OPERATING RULES:
1. PERSONALIZED ANSWERS: Use the provided DATA CONTEXT to answer questions about the user's specific accounts, policies, transactions, and investments (CAS data).
2. GENERIC QUERIES: If the user asks a general question (e.g., "What is a Mutual Fund?", "How to save taxes?", or even "Tell me a joke"), answer it professionally and helpfully using your general knowledge.
3. PERSONALITY: Premium, professional, and friendly (like a trusted private banker).
4. FORMATTING: Use markdown for readability. Use **bold** for amounts and dates. Use bullet points for lists.
5. SCOPE: 
   - "Balance Check": Look at Bank Info.
   - "Policies/Rules": Look at Bank Policies.
   - "Investments/CAS": Look at the CAS data context for mutual funds, stocks, and holdings.
6. NO HALLUCINATION: Never invent personal data. If specific information is missing from the DATA CONTEXT but the query is about the user's personal finances, politely state what is missing.
7. GENERATIVE UI (GenUI): 
   - DO NOT use a widget for simple factual queries like "What is my balance?" or "What are my loan policies?". Answer these with text only.
   - ONLY use a widget when the user explicitly asks to view a list, a table, or a comprehensive summary.
   - For "Bank Statement" or "Transaction List" (e.g., "Show me my recent transactions", "List my spending"), use the `transaction_table` widget. Populate the "transactions" array with ALL RELEVANT records.
     ```json
     {
       "widget": "transaction_table",
       "data": {
         "title": "Recent Transactions",
         "transactions": [ {"date": "2024-03-01", "description": "Starbucks", "amount": 150.0, "type": "debit"} ]
       }
     }
     ```
   - For "Financial Portfolio" or "CAS" intent (e.g., "Show my investment summary", "How is my portfolio doing"), use the `portfolio_summary` widget. Summarize the investments from the CAS data. Extract `totalValue`, `totalInvestment`, calculate an approximate `xirr` if available (or use 0), and list the top holdings (mutual funds/stocks).
     ```json
     {
       "widget": "portfolio_summary",
       "data": {
         "totalValue": 150000.0,
         "totalInvestment": 120000.0,
         "xirr": 12.5,
         "topHoldings": [ {"name": "HDFC Flexi Cap Fund", "value": 50000.0} ]
       }
     }
     ```
   - Include ONLY ONE JSON block in your response if a widget is needed. You can still provide a brief text intro before or after the JSON block.

User Query: ${userQuery}
''';

      final contents = _buildHistoryContents(history, systemPrompt);

      final response = await _client.models.generateContent(
        request: GenerateContentRequest(
          contents: contents,
        ),
        model: 'gemini-3.1-flash-lite',
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw LlmChatException('I encountered an empty response. Please try rephrasing.');
      }

      return text;
    } catch (e) {
      print('LlmChatService Error: $e');
      throw LlmChatException('AI Service Error: $e');
    }
  }

  Map<String, dynamic>? parseGenUIWidget(String text) {
    try {
      // Improved regex to handle potential formatting variations
      final regex = RegExp(r'```(?:json)?\s*(\{[\s\S]*?"widget":[\s\S]*?\})\s*```');
      final match = regex.firstMatch(text);
      if (match != null) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          return jsonDecode(jsonStr);
        }
      }
      
      // Fallback for JSON without code blocks if it's the only thing in the response
      if (text.trim().startsWith('{') && text.trim().endsWith('}') && text.contains('"widget":')) {
        return jsonDecode(text.trim());
      }
    } catch (e) {
      print('Error parsing GenUI widget: $e');
    }
    return null;
  }

  String cleanResponseText(String text) {
    return text.replaceAll(RegExp(r'```(?:json)?\s*\{[\s\S]*?"widget":[\s\S]*?\}\s*```'), '').trim();
  }

  Future<List<String>> getSuggestedActions({
    BankInfo? bankInfo,
    List<BankPolicy>? policies,
    List<FirebaseTransaction>? transactions,
    String? casData,
  }) async {
    try {
      final context = _prepareAllContext(
        bankInfo: bankInfo,
        policies: policies,
        fbTransactions: transactions,
        casData: casData,
      );

      final prompt = '''
Based on the following user financial data, suggest 4-5 very short, highly relevant "Action Chips" (max 3 words each) that the user might want to click to start a conversation.
Focus on: Balance, Recent large spends, Interest rates, or Policy details.

Data:
$context

Return ONLY a JSON array of strings. Example: ["Check Balance", "Loan Policies", "Recent Spends"]
''';

      final response = await _client.models.generateContent(
        request: GenerateContentRequest(
          contents: [Content.text(prompt)],
        ),
        model: 'gemini-3.1-flash-lite',
      );

      final text = response.text;
      if (text != null) {
        // Clean text from potential markdown code blocks
        final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> list = jsonDecode(cleaned);
        return list.map((e) => e.toString()).toList();
      }
      return ["Balance Check", "Recent Transactions", "Loan Info", "Spending Trends"];
    } catch (e) {
      print('Error getting suggested actions: $e');
      return ["Balance Check", "Recent Transactions", "Loan Info", "Spending Trends"];
    }
  }

  String _prepareAllContext({
    BankInfo? bankInfo,
    List<BankPolicy>? policies,
    List<FirebaseTransaction>? fbTransactions,
    List<BankTransaction>? localTransactions,
    String? casData,
  }) {
    final Map<String, dynamic> context = {};
    
    if (bankInfo != null) context['bank_info'] = bankInfo.toJson();
    if (policies != null && policies.isNotEmpty) {
      context['policies'] = policies.map((p) => p.toJson()).toList();
    }
    
    // Unify transactions into a single list for the AI
    final List<Map<String, dynamic>> allTransactions = [];
    
    if (fbTransactions != null && fbTransactions.isNotEmpty) {
      allTransactions.addAll(fbTransactions.map((t) => {
        'date': t.date.toIso8601String().split('T')[0],
        'description': t.description,
        'amount': t.amount,
        'type': t.type.toLowerCase(), // Ensure 'credit' or 'debit'
        'category': t.category,
      }));
    }
    
    if (localTransactions != null && localTransactions.isNotEmpty) {
      allTransactions.addAll(localTransactions.map((t) => {
        'date': t.date.toIso8601String().split('T')[0],
        'description': t.description,
        'amount': t.amount,
        'type': t.type.name == 'outbound' ? 'debit' : 'credit', // Map to standard 'debit'/'credit'
        'category': t.category,
      }));
    }

    if (allTransactions.isNotEmpty) {
      context['transactions'] = allTransactions;
    }

    if (casData != null && casData.isNotEmpty) {
      try {
        context['cas_data'] = jsonDecode(casData);
      } catch (e) {
        context['cas_data_raw'] = casData;
      }
    }

    return jsonEncode(context);
  }


  List<Content> _buildHistoryContents(List<ChatMessage> history, String currentPrompt) {
    final List<Content> contents = [];
    final relevantHistory = history.length > 10 
        ? history.sublist(history.length - 10) 
        : history;

    for (var msg in relevantHistory) {
      if (contents.isEmpty && !msg.isUser) continue;
      
      contents.add(
        msg.isUser 
          ? Content.text(msg.text)
          : Content.model([Part.text(msg.text)])
      );
    }

    contents.add(Content.text(currentPrompt));
    return contents;
  }
}
