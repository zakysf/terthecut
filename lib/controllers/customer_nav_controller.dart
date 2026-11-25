import 'package:flutter/foundation.dart';

/// Singleton controller untuk mengelola indeks tab navigasi bawah pelanggan.
class CustomerNavController extends ChangeNotifier {
  static final CustomerNavController _instance = CustomerNavController._internal();
  factory CustomerNavController() => _instance;
  CustomerNavController._internal();

  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  void changeTab(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
    notifyListeners();
  }

  void toHome() => changeTab(0);
  void toBooking() => changeTab(1);
  void toPointLedger() => changeTab(2);
  void toVouchers() => changeTab(3);
}
