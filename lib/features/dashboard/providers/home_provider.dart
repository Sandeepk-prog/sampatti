import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_data.dart';
import '../repositories/home_repository.dart';

enum HomeState { initial, loading, loaded, error }

class HomeProvider with ChangeNotifier {
  final HomeRepository _repository;

  HomeProvider(this._repository);

  HomeData? _homeData;
  HomeState _state = HomeState.initial;
  String _errorMessage = '';
  String _userName = 'N/A';

  HomeData? get homeData => _homeData;
  HomeState get state => _state;
  String get errorMessage => _errorMessage;
  String get userName => _userName;

  Future<void> fetchHomeData() async {
    _state = HomeState.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstVisit = prefs.getBool('is_first_visit_dashboard') ?? true;

      if (isFirstVisit) {
        final dataExists = await _repository.checkDataExists();
        if (!dataExists) {
          await _repository.initializeSampleData();
        }
        await prefs.setBool('is_first_visit_dashboard', false);
      }

      _userName = await _repository.getSavedNameFromPrefs() ?? 'N/A';
      _homeData = await _repository.getHomeData();
      _state = HomeState.loaded;
    } catch (e) {
      _state = HomeState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
