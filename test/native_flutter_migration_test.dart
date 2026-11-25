import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terthecut/controllers/admin_controller.dart';
import 'package:terthecut/controllers/auth_controller.dart';
import 'package:terthecut/controllers/customer_nav_controller.dart';
import 'package:terthecut/controllers/feedback_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Native Flutter Refactor & SharedPreferences Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Controllers use Singleton Pattern consistently', () {
      expect(identical(AuthController(), AuthController()), isTrue);
      expect(identical(CustomerNavController(), CustomerNavController()), isTrue);
      expect(identical(AdminController(), AdminController()), isTrue);
      expect(identical(FeedbackController(), FeedbackController()), isTrue);
    });

    test('CustomerNavController updates ValueNotifier<int> tabs correctly', () {
      final nav = CustomerNavController();
      nav.toBooking();
      expect(nav.currentIndex.value, 1);
      nav.toPointLedger();
      expect(nav.currentIndex.value, 2);
      nav.toVouchers();
      expect(nav.currentIndex.value, 3);
      nav.toHome();
      expect(nav.currentIndex.value, 0);
    });

    test('AuthController persists session to SharedPreferences and restores/clears it', () async {
      final auth = AuthController();

      // Awalnya belum login
      final initial = await auth.checkSavedSession();
      expect(initial, isNull);

      // Login sebagai customer mock
      final ok = await auth.login(
        identifier: '081234567890',
        password: 'password123',
      );
      expect(ok, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentProfile?.id, 'mock-customer-1');

      // Cek data SharedPreferences tersimpan (pola Modul 6)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('loginData'), isTrue);
      expect(prefs.getString('loggedInUserId'), 'mock-customer-1');

      // Cek checkSavedSession memulihkan profil tersimpan
      final restored = await auth.checkSavedSession();
      expect(restored?.id, 'mock-customer-1');
      expect(restored?.phone, '081234567890');

      // Logout menghapus sesi SharedPreferences
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentProfile, isNull);
      expect(prefs.getBool('loginData'), isFalse);
      expect(prefs.getString('loggedInUserId'), isNull);
    });

    test('AdminController debounces customer search with native Timer (300ms)', () async {
      final admin = AdminController();
      admin.onCustomerSearchChanged('0812');

      // Sebelum 300ms, debounce belum menjalankan pencarian akhir
      expect(admin.customerSearchQuery, '0812');

      // Setelah melewati 300ms, hasil pencarian termuat
      await Future.delayed(const Duration(milliseconds: 450));
      expect(admin.searchedCustomers.any((p) => p.phone == '081234567890'), isTrue);

      admin.onCustomerSearchChanged('');
      await Future.delayed(const Duration(milliseconds: 400));
      expect(admin.searchedCustomers, isEmpty);
    });

    test('FeedbackController rejects empty input without UI side effects', () async {
      final fc = FeedbackController();
      final ok = await fc.submitFeedback(message: '   ');
      expect(ok, isFalse);
      expect(fc.errorMessage, isNotEmpty);
    });
  });
}
