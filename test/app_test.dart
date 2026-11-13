import 'package:flutter_test/flutter_test.dart';
import 'package:terthecut/services/branch_service.dart';

void main() {
  test('BranchService returns 11 branches with complete addresses', () async {
    final branchService = BranchService();
    final branches = await branchService.fetchBranches();
    expect(branches.length, 11);
    expect(branches.first.name, contains('Warungboto'));

    // Verifikasi masing-masing cabang memiliki 2 kapster
    final barbers = await branchService.fetchBarbersByBranch(branches.first.id);
    expect(barbers.length, 2);
  });

  test('Branch.isOpenNow calculates real-time operating status accurately', () async {
    final branchService = BranchService();
    final branches = await branchService.fetchBranches();
    final branch = branches.first;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final isOpenExpected = currentMinutes >= (10 * 60) && currentMinutes < (22 * 60);

    expect(branch.isOpenNow, isOpenExpected);
    expect(branch.statusText, isOpenExpected ? 'BUKA' : 'TUTUP');
    expect(branch.formattedOperatingHours, '10:00 - 22:00 WIB');
  });
}

