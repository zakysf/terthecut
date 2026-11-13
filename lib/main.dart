import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'controllers/auth_controller.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/home/home_view.dart';
import 'views/branch/branch_list_view.dart';
import 'views/branch/branch_detail_view.dart';
import 'views/services/service_catalog_view.dart';
import 'views/hairstyle/hairstyle_list_view.dart';
import 'views/admin/admin_dashboard_view.dart';
import 'views/booking/booking_wizard_view.dart';
import 'views/booking/my_bookings_view.dart';
import 'views/booking/booking_detail_view.dart';
import 'views/loyalty/reward_catalog_view.dart';
import 'views/loyalty/my_vouchers_view.dart';
import 'views/loyalty/point_ledger_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}
  await SupabaseConfig.initialize();
  // Daftarkan AuthController secara permanen di awal aplikasi
  Get.put(AuthController(), permanent: true);
  runApp(const TerTheCutApp());
}

class TerTheCutApp extends StatelessWidget {
  const TerTheCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ter The Cut Barbershop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController(), permanent: true);
        }
      }),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/register', page: () => const RegisterView()),
        GetPage(name: '/home', page: () => HomeView()),
        GetPage(name: '/branches', page: () => BranchListView()),
        GetPage(name: '/branch-detail', page: () => const BranchDetailView()),
        GetPage(name: '/services', page: () => ServiceCatalogView()),
        GetPage(name: '/hairstyles', page: () => HairstyleListView()),
        GetPage(name: '/admin-home', page: () => AdminDashboardView()),
        GetPage(name: '/booking-wizard', page: () => BookingWizardView()),
        GetPage(name: '/my-bookings', page: () => MyBookingsView()),
        GetPage(name: '/booking-detail', page: () => const BookingDetailView()),
        GetPage(name: '/rewards', page: () => RewardCatalogView()),
        GetPage(name: '/my-vouchers', page: () => MyVouchersView()),
        GetPage(name: '/point-ledger', page: () => PointLedgerView()),
      ],
    );
  }
}
