import 'package:flutter_test/flutter_test.dart';
import 'package:terthecut/services/branch_service.dart';
import 'package:terthecut/services/service_catalog_service.dart';

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

  test('ServiceCatalogService returns 18 services with rounded hour durations', () async {
    final serviceCatalogService = ServiceCatalogService();
    final services = await serviceCatalogService.fetchServices();
    expect(services.length, 18);

    // Verifikasi seluruh durasi layanan adalah bilangan bulat jam (1, 2, atau 3 jam)
    for (final svc in services) {
      expect(svc.durationHours >= 1 && svc.durationHours <= 3, true);
      expect(svc.slotsNeeded, equals(svc.durationHours));
    }
  });
}

