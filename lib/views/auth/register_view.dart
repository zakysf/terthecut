import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/ui_helpers.dart';
import '../../controllers/auth_controller.dart';
import '../customer_root_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthController _authController = AuthController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPassController.text.trim();

    if (name.isEmpty || identifier.isEmpty || password.isEmpty) {
      showAppSnackBar(
        context,
        'Lengkapi seluruh data pendaftaran.',
        title: 'Perhatian',
      );
      return;
    }

    if (password != confirm) {
      showAppSnackBar(
        context,
        'Konfirmasi kata sandi tidak cocok.',
        title: 'Perhatian',
      );
      return;
    }

    final ok = await _authController.register(
      name: name,
      identifier: identifier,
      password: password,
    );
    if (!mounted) return;

    if (ok) {
      showAppSnackBar(
        context,
        'Selamat datang di Ter The Cut Barbershop, $name!',
        title: 'Registrasi Berhasil',
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerRootView()),
        (route) => false,
      );
    } else {
      showAppSnackBar(
        context,
        _authController.errorMessage,
        title: 'Pendaftaran Gagal',
        backgroundColor: AppColors.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('DAFTAR MEMBER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bergabung dengan Ter The Cut',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Dapatkan poin loyalitas otomatis setiap kali potong rambut dan tukarkan dengan voucher eksklusif.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Form Nama Lengkap
              Text('NAMA LENGKAP', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Contoh: Bagas Pratama'),
              ),
              const SizedBox(height: 16),

              // Form Nomor Telepon
              Text('NOMOR TELEPON', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.inkSoft),
                  hintText: '081234567890',
                ),
              ),
              const SizedBox(height: 16),

              // Form Kata Sandi
              Text('KATA SANDI', style: Theme.of(context).textTheme.labelSmall),
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
              const SizedBox(height: 16),

              // Konfirmasi Kata Sandi
              Text('KONFIRMASI KATA SANDI', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPassController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(hintText: 'Ulangi kata sandi Anda'),
              ),
              const SizedBox(height: 28),

              // Tombol Daftar
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
                    child: const Text('DAFTAR SEKARANG'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

