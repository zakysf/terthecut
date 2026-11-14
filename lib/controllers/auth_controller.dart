import 'package:get/get.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final RxBool _isLoading = false.obs;
  final Rx<Profile?> _currentProfile = Rx<Profile?>(null);
  final RxString _errorMessage = ''.obs;

  bool get isLoading => _isLoading.value;
  Profile? get currentProfile => _currentProfile.value;
  String get errorMessage => _errorMessage.value;
  bool get isLoggedIn => _currentProfile.value != null;
  bool get isAdmin => _currentProfile.value?.isAdmin ?? false;

  final _authService = AuthService();

  @override
  void onInit() {
    _checkInitialSession();
    super.onInit();
  }

  void _checkInitialSession() {
    _currentProfile.value = _authService.currentProfile;
  }

  void updateCurrentProfile(Profile profile) {
    _currentProfile.value = profile;
  }

  /// Memuat ulang data profil pengguna terbaru (saldo poin, riwayat kunjungan)
  Future<void> refreshProfile() async {
    final current = _currentProfile.value;
    if (current == null) return;
    try {
      final updated = await _authService.getProfile(current.id);
      if (updated != null) {
        _currentProfile.value = updated;
      }
    } catch (_) {}
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final profile = await _authService.login(
        identifier: identifier,
        password: password,
      );

      _currentProfile.value = profile;
      _isLoading.value = false;

      // Navigasi otomatis berbasis RBAC (Role-Based Access Control)
      if (profile.isAdmin) {
        Get.offAllNamed('/admin-home');
      } else {
        Get.offAllNamed('/home');
      }
      return true;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      Get.snackbar(
        'Gagal Masuk',
        _errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String identifier,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final profile = await _authService.register(
        name: name,
        identifier: identifier,
        password: password,
      );

      _currentProfile.value = profile;
      _isLoading.value = false;

      Get.snackbar(
        'Registrasi Berhasil',
        'Selamat datang di Ter The Cut Barbershop, $name!',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.offAllNamed('/home');
      return true;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
      Get.snackbar(
        'Pendaftaran Gagal',
        _errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading.value = true;
      await _authService.logout();
      _currentProfile.value = null;
      _isLoading.value = false;
      Get.offAllNamed('/login');
    } catch (e) {
      _isLoading.value = false;
      Get.offAllNamed('/login');
    }
  }
}

