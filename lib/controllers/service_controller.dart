import 'package:get/get.dart';
import '../models/service_item.dart';
import '../services/service_catalog_service.dart';

class ServiceController extends GetxController {
  final RxBool _isLoading = false.obs;
  final RxList<ServiceCategory> _categories = <ServiceCategory>[].obs;
  final RxList<ServiceItem> _services = <ServiceItem>[].obs;
  final RxList<ServiceItem> _filteredServices = <ServiceItem>[].obs;
  final RxString _selectedCategoryId = 'all'.obs;

  bool get isLoading => _isLoading.value;
  List<ServiceCategory> get categories => _categories;
  List<ServiceItem> get services => _filteredServices;
  String get selectedCategoryId => _selectedCategoryId.value;

  final _serviceCatalogService = ServiceCatalogService();

  @override
  void onInit() {
    retrieveCatalog();
    super.onInit();
  }

  Future<void> retrieveCatalog() async {
    try {
      _isLoading.value = true;
      final cats = await _serviceCatalogService.fetchCategories();
      final svcs = await _serviceCatalogService.fetchServices();

      _categories.assignAll(cats);
      _services.assignAll(svcs);
      _filteredServices.assignAll(svcs);
      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
      throw Exception('Gagal memuat katalog layanan: $e');
    }
  }

  void filterByCategory(String categoryId) {
    _selectedCategoryId.value = categoryId;
    if (categoryId == 'all') {
      _filteredServices.assignAll(_services);
    } else {
      _filteredServices.assignAll(
        _services.where((s) => s.categoryId == categoryId).toList(),
      );
    }
  }
}

