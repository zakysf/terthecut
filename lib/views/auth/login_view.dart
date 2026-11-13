import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController _authController = Get.put(AuthController());
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isAdminTab = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Perhatian',
        'Harap isi seluruh kolom dengan lengkap.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _authController.login(
      identifier: identifier,
      password: password,
      asAdmin: _isAdminTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Brand
                Text(
                  'TER THE CUT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'BARBERSHOP & GROOMING HOUSE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 36),

                // Tab Pilihan: Pelanggan vs Admin
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isAdminTab = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isAdminTab ? AppColors.ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'PELANGGAN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: !_isAdminTab ? AppColors.paper : AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isAdminTab = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isAdminTab ? AppColors.ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'STAF ADMIN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: _isAdminTab ? AppColors.paper : AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Input Nomor Telepon
                Text(
                  _isAdminTab ? 'NOMOR TELEPON ADMIN' : 'NOMOR TELEPON',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.inkSoft),
                    hintText: _isAdminTab ? '081999888777' : '081234567890',
                  ),
                ),
                const SizedBox(height: 16),

                // Form Input Password
                Text(
                  'KATA SANDI',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.inkSoft,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Masuk
                Obx(() {
                  if (_authController.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.ink),
                    );
                  }
                  return ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isAdminTab ? 'MASUK KE SISTEM ADMIN' : 'MASUK'),
                  );
                }),
                const SizedBox(height: 20),

                // Navigasi ke Registrasi
                if (!_isAdminTab)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum memiliki akun member? ',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkSoft),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed('/register'),
                        child: Text(
                          'Daftar Baru',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

