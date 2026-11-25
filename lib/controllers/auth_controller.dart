import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import 'booking_controller.dart';
import 'customer_nav_controller.dart';
import 'loyalty_controller.dart';
import 'notification_controller.dart';

/// Singleton controller autentikasi pengguna dan persistensi sesi SharedPreferences.
class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal() {
    _currentProfile = _authService.currentProfile;
  }

  static const String _prefLoginKey = 'loginData';
  static const String _prefUserIdKey = 'loggedInUserId';
  static const String _prefPhoneKey = 'loggedInPhone';
  static const String _prefNameKey = 'loggedInName';
  static const String _prefRoleKey = 'loggedInRole';

  bool _isLoading = false;
  Profile? _currentProfile;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  Profile? get currentProfile => _currentProfile;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentProfile != null;
  bool get isAdmin => _currentProfile?.isAdmin ?? false;

  final _authService = AuthService();

  /// Memeriksa apakah terdapat sesi login tersimpan di SharedPreferences (auto-login Modul 6).
  Future<Profile?> checkSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedInSaved = prefs.getBool(_prefLoginKey) ?? false;
      if (!isLoggedInSaved) return null;

      final savedUserId = prefs.getString(_prefUserIdKey) ?? '';
      final savedPhone = prefs.getString(_prefPhoneKey) ?? '';
      final savedName = prefs.getString(_prefNameKey);
      final savedRole = prefs.getString(_prefRoleKey) ?? 'customer';

      final lookupKey = savedUserId.isNotEmpty ? savedUserId : savedPhone;
      if (lookupKey.isEmpty) return null;

      Profile? fetched = await _authService.getProfile(lookupKey);
      if (fetched == null && savedUserId.isNotEmpty) {
        fetched = Profile(
          id: savedUserId,
          role: savedRole,
          name: savedName,
          phone: savedPhone.isNotEmpty ? savedPhone : null,
        );
      }

      if (fetched != null) {
        _currentProfile = fetched;
        _authService.restoreSessionProfile(fetched);
        notifyListeners();
      }
      return fetched;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(Profile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoginKey, true);
      await prefs.setString(_prefUserIdKey, profile.id);
      await prefs.setString(_prefRoleKey, profile.role);
      if (profile.phone != null) {
        await prefs.setString(_prefPhoneKey, profile.phone!);
      }
      if (profile.name != null) {
        await prefs.setString(_prefNameKey, profile.name!);
      }
    } catch (_) {}
  }

  Future<void> _clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefLoginKey, false);
      await prefs.remove(_prefUserIdKey);
      await prefs.remove(_prefPhoneKey);
      await prefs.remove(_prefNameKey);
      await prefs.remove(_prefRoleKey);
    } catch (_) {}
  }

  void updateCurrentProfile(Profile profile) {
    _currentProfile = profile;
    _authService.restoreSessionProfile(profile);
    notifyListeners();
  }

  /// Memuat ulang data profil pengguna terbaru (saldo poin, riwayat kunjungan).
  Future<void> refreshProfile() async {
    final current = _currentProfile;
    if (current == null) return;
    try {
      final updated = await _authService.getProfile(current.id);
      if (updated != null) {
        _currentProfile = updated;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final profile = await _authService.login(
        identifier: identifier,
        password: password,
      );

      _currentProfile = profile;
      await _saveSession(profile);
      CustomerNavController().toHome();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String identifier,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final profile = await _authService.register(
        name: name,
        identifier: identifier,
        password: password,
      );

      _currentProfile = profile;
      await _saveSession(profile);
      CustomerNavController().toHome();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.logout();
      await _clearSavedSession();
      _currentProfile = null;
      _errorMessage = '';
      CustomerNavController().toHome();
      BookingController().clearSession();
      LoyaltyController().clearSession();
      NotificationController().clearSession();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
