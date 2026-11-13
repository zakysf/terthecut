import 'package:get/get.dart';
import '../models/hairstyle.dart';
import '../services/hairstyle_service.dart';

class HairstyleController extends GetxController {
  final RxBool _isLoading = false.obs;
  final RxList<Hairstyle> _hairstyles = <Hairstyle>[].obs;

  bool get isLoading => _isLoading.value;
  List<Hairstyle> get hairstyles => _hairstyles;

  final _hairstyleService = HairstyleService();

  @override
  void onInit() {
    retrieveHairstyles();
    super.onInit();
  }

  Future<void> retrieveHairstyles() async {
    try {
      _isLoading.value = true;
      final data = await _hairstyleService.fetchHairstyles();
      _hairstyles.assignAll(data);
      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(Hairstyle item) async {
    final newStatus = await _hairstyleService.toggleFavorite(item.id);
    final index = _hairstyles.indexWhere((h) => h.id == item.id);
    if (index != -1) {
      _hairstyles[index].isFavorite = newStatus;
      _hairstyles.refresh();
    }
  }
}

