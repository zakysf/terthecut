import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../controllers/customer_nav_controller.dart';
import 'home/home_view.dart';
import 'booking/my_bookings_view.dart';
import 'loyalty/point_ledger_view.dart';
import 'loyalty/my_vouchers_view.dart';

/// Halaman induk pelanggan dengan BottomNavigationBar 4 Tab:
/// 1. Beranda
/// 2. Booking (Jadwal Saya)
/// 3. Mutasi Poin (Point Ledger)
/// 4. Voucher (Voucher Saya)
class CustomerRootView extends StatelessWidget {
  const CustomerRootView({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomerNavController navController = Get.put(
      CustomerNavController(),
      permanent: true,
    );

    final List<Widget> pages = [
      HomeView(),
      MyBookingsView(showBackButton: false),
      PointLedgerView(showBackButton: false),
      MyVouchersView(showBackButton: false),
    ];

    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: navController.currentIndex.value,
          children: pages,
        ),
      ),
      bottomNavigationBar: Obx(
        () => Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.hairline, width: 0.8),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: navController.currentIndex.value,
            onTap: navController.changeTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.inkSoft,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Booking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Mutasi Poin',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.wallet_outlined),
                activeIcon: Icon(Icons.wallet),
                label: 'Voucher',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
