import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'controllers/auth_controller.dart';
import 'views/admin/admin_dashboard_view.dart';
import 'views/auth/login_view.dart';
import 'views/customer_root_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}
  await SupabaseConfig.initialize();
  runApp(const TerTheCutApp());
}

class TerTheCutApp extends StatelessWidget {
  const TerTheCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ter The Cut Barbershop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

/// Gerbang awal aplikasi untuk memeriksa sesi SharedPreferences (auto-login Modul 6).
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final profile = await AuthController().checkSavedSession();
    if (!mounted) return;

    final Widget destination;
    if (profile == null) {
      destination = const LoginView();
    } else if (profile.isAdmin) {
      destination = const AdminDashboardView();
    } else {
      destination = const CustomerRootView();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TER THE CUT',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3.0,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}
