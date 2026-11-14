import 'package:get/get.dart';

/// Controller untuk mengelola navigasi 4 Tab BottomNavigationBar Pelanggan:
/// Tab 0: Beranda
/// Tab 1: Booking
/// Tab 2: Mutasi Poin
/// Tab 3: Voucher
class CustomerNavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    if (index >= 0 && index <= 3) {
      currentIndex.value = index;
    }
  }

  void toHome() => changeTab(0);
  void toBooking() => changeTab(1);
  void toPointLedger() => changeTab(2);
  void toVouchers() => changeTab(3);
}
