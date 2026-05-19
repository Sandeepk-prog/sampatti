import 'package:flutter/material.dart';
import '../models/investment_summary.dart';
import '../models/investment_holding.dart';
import '../repositories/investment_repository.dart';

enum InvestmentState { initial, loading, loaded, error }

class InvestmentProvider with ChangeNotifier {
  final InvestmentRepository _repository;

  InvestmentProvider(this._repository);

  InvestmentState _state = InvestmentState.initial;
  String _errorMessage = '';
  
  String _selectedDropdown = 'Personal';
  String _selectedFamilyTab = 'Total Invest.';
  String _selectedTab = 'Dashboard';

  List<InvestmentSummary> _summaries = [];
  List<InvestmentHolding> _holdings = [];

  // Getters
  InvestmentState get state => _state;
  String get errorMessage => _errorMessage;
  String get selectedDropdown => _selectedDropdown;
  String get selectedFamilyTab => _selectedFamilyTab;
  String get selectedTab => _selectedTab;
  List<InvestmentSummary> get summaries => _summaries;
  List<InvestmentHolding> get holdings => _holdings;
  bool get isLoading => _state == InvestmentState.loading;

  InvestmentSummary? get currentSummary {
    final type = _selectedTab == 'Mutual Funds' ? 'mutual_fund' : 'equity';
    try {
      return _summaries.firstWhere((s) => s.type == type);
    } catch (_) {
      return null;
    }
  }

  Future<void> initData(String userId) async {
    _state = InvestmentState.loading;
    notifyListeners();

    try {
      final exists = await _repository.checkInvestmentDataExists(userId);
      if (!exists) {
        await _repository.seedSampleInvestmentData(userId);
      }
      await fetchData(userId, silent: true);
      _state = InvestmentState.loaded;
    } catch (e) {
      _state = InvestmentState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> fetchData(String userId, {bool silent = false}) async {
    if (!silent) {
      _state = InvestmentState.loading;
      notifyListeners();
    }

    try {
      final memberId = _selectedDropdown == 'Family' 
          ? (_selectedFamilyTab == 'Total Invest.' ? 'total' : 'family_1') 
          : 'personal';
      
      _summaries = await _repository.getInvestmentSummaries(userId, memberId);
      
      if (_selectedTab == 'Mutual Funds') {
        _holdings = await _repository.getInvestmentHoldings(userId, memberId, 'mutual_fund');
      } else if (_selectedTab == 'Equity') {
        _holdings = await _repository.getInvestmentHoldings(userId, memberId, 'equity');
      } else {
        _holdings = [];
      }

      if (!silent) {
        _state = InvestmentState.loaded;
      }
    } catch (e) {
      _state = InvestmentState.error;
      _errorMessage = 'Error fetching data: $e';
    }
    notifyListeners();
  }

  void setSelectedDropdown(String value, String userId) {
    _selectedDropdown = value;
    fetchData(userId);
  }

  void setSelectedFamilyTab(String tab, String userId) {
    _selectedFamilyTab = tab;
    fetchData(userId);
  }

  void setSelectedTab(String tab, String userId) {
    _selectedTab = tab;
    fetchData(userId);
  }
}
