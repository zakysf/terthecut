import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      ],
    );
  }
}
