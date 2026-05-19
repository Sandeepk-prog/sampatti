import 'package:flutter/material.dart';
import '../models/bank_statement_model.dart';
import '../models/chat_models.dart';
import '../services/llm_chat_service.dart';
import '../services/firebase_chat_service.dart';
import '../../../core/services/cas_service.dart';
import '../../auth/services/user_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<BankTransaction>? transactions;
  String _apiKey;
  final String? userId;
  final String? casUrl;
  
  LlmChatService _llmService;
  final FirebaseChatService _fbService = FirebaseChatService();
  final UserService _userService = UserService();
  final CASService _casService = CASService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  List<String> _suggestedActions = [];
  
  // Data Contexts
  BankInfo? _bankInfo;
  List<BankPolicy> _policies = [];
  List<FirebaseTransaction> _fbTransactions = [];
  String? _casData;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get suggestedActions => _suggestedActions;
  String get apiKey => _apiKey;

  ChatProvider({
    this.transactions,
    required String apiKey,
    this.userId,
    this.casUrl,
  }) : _apiKey = apiKey, 
       _llmService = LlmChatService(apiKey) {
    if (apiKey.isNotEmpty) {
      _initializeSession();
    }
  }

  void updateConfig({required String apiKey}) {
    if (_apiKey != apiKey && apiKey.isNotEmpty) {
      final wasEmpty = _apiKey.isEmpty;
      _apiKey = apiKey;
      _llmService = LlmChatService(apiKey);
      
      if (wasEmpty) {
        _initializeSession();
      }
    }
  }

  Future<void> _initializeSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Seed & Fetch Firebase Data
      if (userId != null) {
        await _fbService.seedSampleData(userId!);
        _bankInfo = await _fbService.getBankInfo(userId!);
        _fbTransactions = await _fbService.getRecentTransactions(userId!);
        _policies = await _fbService.getBankPolicies(userId!);
      }

      // 2. Fetch CAS Data if available
      final effectiveCasUrl = casUrl ?? (userId != null ? (await _userService.getUser(userId!))?.casUrl : null);
      
      if (effectiveCasUrl != null && effectiveCasUrl.isNotEmpty) {
        // We assume JSON type for now as the app seems to prefer JSON for AI context
        // If it's a PDF, we might need a password, but the user requested CAS URL as context
        // which usually implies the parsed JSON URL or the app handles it.
        // In this app, UserService.updateCasUrl is called with 'json' type for parsed results often.
        try {
          print('Fetching CAS data from URL: $effectiveCasUrl');
          _casData = await _casService.getJsonFromUrl(effectiveCasUrl);
          print('CAS data fetched successfully, length: ${_casData?.length}');
        } catch (e) {
          print('Error fetching CAS data: $e');
        }
      }

      // 3. Generate Suggested Actions
      _suggestedActions = await _llmService.getSuggestedActions(
        bankInfo: _bankInfo,
        policies: _policies,
        transactions: _fbTransactions,
        casData: _casData,
      );

      // 3. Add initial greeting
      _addInitialGreeting();
    } catch (e) {
      print('Initialization Error: $e');
      _addInitialGreeting(); // Still greet even if FB fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addInitialGreeting() {
    String greeting = "Hello! I'm Sampatti AI. ";
    if (_bankInfo != null) {
      greeting += "I see your ${_bankInfo!.bankName} account has a balance of ${_bankInfo!.currency} ${_bankInfo!.currentBalance}. ";
    }
    greeting += "How can I assist you with your finances today?";

    _messages.add(
      ChatMessage(
        id: 'initial_greeting',
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _llmService.getChatResponse(
        bankInfo: _bankInfo,
        policies: _policies,
        fbTransactions: _fbTransactions,
        localTransactions: transactions,
        casData: _casData,
        history: _messages.sublist(0, _messages.length - 1),
        userQuery: text,
      );

      final widgetData = _llmService.parseGenUIWidget(response);
      print("--Widget Data Parsed:-- $widgetData");
      final cleanedText = _llmService.cleanResponseText(response);
      print("--Cleaned Response Text:-- $cleanedText");

      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: cleanedText.isEmpty && widgetData != null ? "Here is the data you requested:" : cleanedText,
        isUser: false,
        timestamp: DateTime.now(),
        widgetData: widgetData,
      );

      _messages.add(aiMessage);
    } catch (e) {
      _error = e.toString();
      _messages.add(ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        text: "Sorry, I'm having trouble connecting. ${e.toString()}",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  void clearHistory() {
    _messages.clear();
    _addInitialGreeting();
    notifyListeners();
  }
}
