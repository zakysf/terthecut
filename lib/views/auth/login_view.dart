import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/ui_helpers.dart';
import '../../controllers/auth_controller.dart';
import '../admin/admin_dashboard_view.dart';
import '../customer_root_view.dart';
import 'register_view.dart';

/// Halaman Masuk Portal Tunggal (Single Portal dengan RBAC Otomatis)
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController _authController = AuthController();

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      showAppSnackBar(
        context,
        'Harap isi nomor telepon dan kata sandi dengan lengkap.',
        title: 'Perhatian',
      );
      return;
    }

    final ok = await _authController.login(
      identifier: identifier,
      password: password,
    );
    if (!mounted) return;

    if (ok) {
      final destination = _authController.isAdmin
          ? const AdminDashboardView()
          : const CustomerRootView();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      showAppSnackBar(
        context,
        _authController.errorMessage,
        title: 'Gagal Masuk',
        backgroundColor: AppColors.danger,
      );
    }
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
                // Header Brand Ter The Cut
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
                const SizedBox(height: 40),

                // Form Input Nomor Telepon
                Text(
                  'NOMOR TELEPON',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      size: 20,
                      color: AppColors.inkSoft,
                    ),
                    hintText: '081234567890',
                  ),
                ),
                const SizedBox(height: 18),

                // Form Input Kata Sandi
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
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: AppColors.inkSoft,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.inkSoft,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Masuk Utama
                ListenableBuilder(
                  listenable: _authController,
                  builder: (context, _) {
                    if (_authController.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.ink),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _submit,
                      child: const Text('MASUK'),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Tautan Pendaftaran Akun Pelanggan Baru
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum memiliki akun member? ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterView()),
                      ),
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
