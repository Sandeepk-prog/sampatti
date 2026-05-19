import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _spUserNameKey = 'sp_user_name';
  static const String _spUserEmailKey = 'sp_user_email';
  static const String _userCasUrlKey = 'user_cas_url';

  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      return AppUser(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName ?? 'Google User',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<bool> isBiometricAvailable() async {
    final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<List<BiometricType>> getEnrolledBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> getBiometricEnabled() async {
    final String? value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> saveUserData(AppUser user) async {
    await _secureStorage.write(key: _userEmailKey, value: user.email);
    await _secureStorage.write(key: _userNameKey, value: user.name);
    await _secureStorage.write(key: _userCasUrlKey, value: user.casUrl ?? '');
  }

  Future<AppUser?> getSavedUserData() async {
    final email = await _secureStorage.read(key: _userEmailKey);
    final name = await _secureStorage.read(key: _userNameKey);
    final casUrl = await _secureStorage.read(key: _userCasUrlKey);
    if (email != null && name != null) {
      return AppUser(
        id: 'stored',
        email: email,
        name: name,
        casUrl: casUrl,
      );
    }
    return null;
  }

  Future<void> saveUserDataToPrefs(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spUserNameKey, user.name);
    await prefs.setString(_spUserEmailKey, user.email);
  }

  Future<String?> getSavedNameFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_spUserNameKey);
  }
}
