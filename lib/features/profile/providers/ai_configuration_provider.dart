import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

enum AIProvider { gemini, openai }

enum AIConfigState { idle, loading, success, error }

class AIConfigurationProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  
  AIProvider _selectedProvider = AIProvider.gemini;
  AIConfigState _state = AIConfigState.idle;
  String _errorMessage = '';
  Map<AIProvider, String> _keys = {};
  Map<AIProvider, DateTime> _lastUpdatedMap = {};
  bool _isObscured = true;
  bool _isInitialized = false;

  AIProvider get selectedProvider => _selectedProvider;
  AIConfigState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isObscured => _isObscured;
  String get currentKey => _keys[_selectedProvider] ?? '';
  DateTime? get lastUpdated => _lastUpdatedMap[_selectedProvider];

  bool get isConfigured => _keys[_selectedProvider]?.isNotEmpty ?? false;
  bool get isAnyProviderConfigured => _keys.values.any((k) => k.isNotEmpty);
  bool get isInitialized => _isInitialized;

  AIConfigurationProvider() {
    loadStoredKeys();
  }

  void toggleVisibility() {
    _isObscured = !_isObscured;
    notifyListeners();
  }

  void setProvider(AIProvider provider) {
    _selectedProvider = provider;
    _state = AIConfigState.idle;
    notifyListeners();
  }

  Future<void> loadStoredKeys() async {
    _state = AIConfigState.loading;
    
    try {
      for (var provider in AIProvider.values) {
        final key = await _storage.read(key: 'ai_key_${provider.name}');
        if (key != null) {
          _keys[provider] = key;
        }
        
        final lastUpdatedStr = await _storage.read(key: 'ai_last_updated_${provider.name}');
        if (lastUpdatedStr != null) {
          _lastUpdatedMap[provider] = DateTime.parse(lastUpdatedStr);
        }
      }
      _isInitialized = true;
      _state = AIConfigState.idle;
      selectProviderBasedOnStoredKeys();
    } catch (e) {
      _state = AIConfigState.error;
      _errorMessage = 'Failed to load stored keys';
    }
    notifyListeners();
  }

  void selectProviderBasedOnStoredKeys() {
    if (_keys.isNotEmpty) {
      final availableProvider = AIProvider.values.firstWhere(
        (provider) => _keys[provider]?.isNotEmpty == true,
        orElse: () => _selectedProvider,
      );
      if (availableProvider != _selectedProvider) {
        _selectedProvider = availableProvider;
        // Don't call notifyListeners() here if it's called immediately after, 
        // but it's safe to call it if used standalone.
        notifyListeners();
      }
    }
  }

  Future<void> saveKey(String key) async {
    if (key.trim().isEmpty) return;
    
    _state = AIConfigState.loading;
    notifyListeners();

    try {
      final now = DateTime.now();
      await _storage.write(key: 'ai_key_${_selectedProvider.name}', value: key.trim());
      await _storage.write(key: 'ai_last_updated_${_selectedProvider.name}', value: now.toIso8601String());
      
      _keys[_selectedProvider] = key.trim();
      _lastUpdatedMap[_selectedProvider] = now;
      
      _state = AIConfigState.success;
    } catch (e) {
      _state = AIConfigState.error;
      _errorMessage = 'Failed to save key';
    }
    notifyListeners();
  }

  Future<void> deleteKey() async {
    _state = AIConfigState.loading;
    notifyListeners();

    try {
      await _storage.delete(key: 'ai_key_${_selectedProvider.name}');
      await _storage.delete(key: 'ai_last_updated_${_selectedProvider.name}');
      
      _keys.remove(_selectedProvider);
      _lastUpdatedMap.remove(_selectedProvider);
      
      selectProviderBasedOnStoredKeys();
      
      _state = AIConfigState.idle;
    } catch (e) {
      _state = AIConfigState.error;
      _errorMessage = 'Failed to delete key';
    }
    notifyListeners();
  }

  Future<void> testConnection(String key) async {
    if (key.trim().isEmpty) return;

    _state = AIConfigState.loading;
    notifyListeners();

    try {
      // Lightweight mock API call simulation
      await Future.delayed(const Duration(seconds: 1));
      
      // Basic validation logic based on provider
      bool isValid = false;
      if (_selectedProvider == AIProvider.gemini) {
        isValid = key.startsWith('AIza');
      } else {
        isValid = key.startsWith('sk-');
      }

      if (isValid) {
        _state = AIConfigState.success;
      } else {
        _state = AIConfigState.error;
        _errorMessage = 'Invalid key format for ${_selectedProvider.name.toUpperCase()}';
      }
    } catch (e) {
      _state = AIConfigState.error;
      _errorMessage = 'Connection test failed';
    }
    notifyListeners();
  }
}
