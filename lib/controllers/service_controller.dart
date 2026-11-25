import 'package:flutter/foundation.dart';
import '../models/service_item.dart';
import '../services/service_catalog_service.dart';

/// Singleton controller katalog kategori dan layanan barbershop.
class ServiceController extends ChangeNotifier {
  static final ServiceController _instance = ServiceController._internal();
  factory ServiceController() => _instance;
  ServiceController._internal();

  bool _isLoading = false;
  List<ServiceCategory> _categories = [];
  List<ServiceItem> _services = [];
  List<ServiceItem> _filteredServices = [];
  String _selectedCategoryId = 'all';

  bool get isLoading => _isLoading;
  List<ServiceCategory> get categories => _categories;
  List<ServiceItem> get services => _filteredServices;
  String get selectedCategoryId => _selectedCategoryId;

  final _serviceCatalogService = ServiceCatalogService();

  Future<void> retrieveCatalog() async {
    try {
      _isLoading = true;
      notifyListeners();

      final cats = await _serviceCatalogService.fetchCategories();
      final svcs = await _serviceCatalogService.fetchServices();

      _categories = cats;
      _services = svcs;
      _applyCategoryFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Gagal memuat katalog layanan: $e');
    }
  }

  void filterByCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    _applyCategoryFilter();
    notifyListeners();
  }

  void _applyCategoryFilter() {
    if (_selectedCategoryId == 'all') {
      _filteredServices = List.from(_services);
    } else {
      _filteredServices =
          _services.where((s) => s.categoryId == _selectedCategoryId).toList();
    }
  }
}
