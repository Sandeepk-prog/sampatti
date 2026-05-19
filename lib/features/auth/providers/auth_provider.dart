import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  AppUser? _user;
  bool _isLoginLoading = false;
  bool _isGoogleLoading = false;
  bool _isBiometricLoading = false;
  bool _isBiometricEnabled = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoginLoading || _isGoogleLoading || _isBiometricLoading;
  bool get isLoginLoading => _isLoginLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isBiometricLoading => _isBiometricLoading;
  bool get isBiometricEnabled => _isBiometricEnabled;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isBiometricEnabled = await _authService.getBiometricEnabled();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoginLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty && password.isNotEmpty) {
      _user = AppUser(
        id: 'user_123',
        email: email,
        name: 'John Doe',
      );
    }

    _isLoginLoading = false;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    _isGoogleLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _user = user;
        await _authService.saveUserData(user);
        await _authService.saveUserDataToPrefs(user);
        
        // Sync user details with Firestore
        try {
          await _userService.syncUser(user);
          // After sync, fetch the full user data (including cas_url)
          final updatedUser = await _userService.getUser(user.id);
          if (updatedUser != null) {
            _user = updatedUser;
            // Update local storage with full data if needed
            await _authService.saveUserData(_user!);
          }
        } catch (firestoreError) {
          debugPrint('Firestore Sync Error: $firestoreError');
          // We don't block the login if Firestore sync fails, 
          // but we might want to notify the user or retry later.
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithBiometrics() async {
    _isBiometricLoading = true;
    notifyListeners();

    try {
      final enrolledBiometrics = await _authService.getEnrolledBiometrics();
      if (enrolledBiometrics.isEmpty) {
        throw 'NO_BIOMETRICS_ENROLLED';
      }

      final success = await _authService.authenticateWithBiometrics();
      if (success) {
        final savedUser = await _authService.getSavedUserData();
        if (savedUser != null) {
          _user = savedUser;
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Biometric Auth Error: $e');
      rethrow;
    } finally {
      _isBiometricLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _authService.setBiometricEnabled(enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  Future<bool> canUseBiometrics() async {
    return await _authService.isBiometricAvailable();
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    
    try {
      final updatedUser = await _userService.getUser(_user!.id);
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
        debugPrint('AuthProvider: User profile refreshed from Firestore');
      }
    } catch (e) {
      debugPrint('AuthProvider: Failed to refresh user: $e');
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
