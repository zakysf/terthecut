import 'package:flutter_test/flutter_test.dart';
import 'package:terthecut/models/branch.dart';
import 'package:terthecut/services/location_service.dart';
import 'package:terthecut/controllers/branch_controller.dart';

void main() {
  group('Modul 7: Location-Based Services (LBS) Verification', () {
    test('LocationService.formatDistance formats meters and kilometers accurately', () {
      // Sesuai Modul 7 Contoh Program 7.11:
      // Di bawah 1000 meter: format meter bulat "850 m"
      expect(LocationService.formatDistance(120), equals('120 m'));
      expect(LocationService.formatDistance(850.4), equals('850 m'));
      expect(LocationService.formatDistance(999), equals('999 m'));

      // 1000 meter ke atas: format kilometer dengan 1 desimal "1.2 km"
      expect(LocationService.formatDistance(1000), equals('1.0 km'));
      expect(LocationService.formatDistance(1240), equals('1.2 km'));
      expect(LocationService.formatDistance(2500), equals('2.5 km'));
    });

    test('LocationService calculates realistic geographic distance in Yogyakarta', () {
      final locationService = LocationService();

      // Titik 1: Cabang Warungboto (-7.8115, 110.3925)
      // Titik 2: Cabang Mrican 1 Demangan (-7.7785, 110.3912)
      // Jarak lurus Warungboto ke Demangan sekitar 3.6 km
      final distanceMeters = locationService.calculateDistance(
        userLat: -7.8115,
        userLng: 110.3925,
        targetLat: -7.7785,
        targetLng: 110.3912,
      );

      expect(distanceMeters, isPositive);
      expect(distanceMeters, greaterThan(3000));
      expect(distanceMeters, lessThan(4500));
      expect(LocationService.formatDistance(distanceMeters), contains('km'));
    });

    test('Branch model parses and serializes latitude and longitude coordinates', () {
      final json = {
        'id': 'br-test',
        'name': 'Cabang UPN Seturan',
        'address': 'Jl. SWK 104 Condongcatur',
        'city': 'Sleman',
        'latitude': -7.7824,
        'longitude': 110.4162,
        'is_active': true,
        'sort_order': 1,
      };

      final branch = Branch.fromJson(json);
      expect(branch.latitude, equals(-7.7824));
      expect(branch.longitude, equals(110.4162));

      final serialized = branch.toJson();
      expect(serialized['latitude'], equals(-7.7824));
      expect(serialized['longitude'], equals(110.4162));
    });

    test('BranchController exposes LBS state and distance methods safely', () {
      final controller = BranchController();
      expect(controller.isLocating, isFalse);
      expect(controller.isSortedByDistance, isFalse);
      expect(controller.locationError, isNull);
      expect(controller.getDistanceFor('non-existent'), isNull);
      expect(controller.getFormattedDistanceFor('non-existent'), isNull);
    });
  });
}
