import 'package:flutter/foundation.dart';
import '../models/hairstyle.dart';
import '../services/hairstyle_service.dart';

/// Singleton controller inspirasi gaya rambut dan favorit.
class HairstyleController extends ChangeNotifier {
  static final HairstyleController _instance = HairstyleController._internal();
  factory HairstyleController() => _instance;
  HairstyleController._internal();

  bool _isLoading = false;
  List<Hairstyle> _hairstyles = [];

  bool get isLoading => _isLoading;
  List<Hairstyle> get hairstyles => _hairstyles;

  final _hairstyleService = HairstyleService();

  Future<void> retrieveHairstyles() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _hairstyleService.fetchHairstyles();
      _hairstyles = data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Hairstyle item) async {
    final newStatus = await _hairstyleService.toggleFavorite(item.id);
    final index = _hairstyles.indexWhere((h) => h.id == item.id);
    if (index != -1) {
      _hairstyles[index].isFavorite = newStatus;
      notifyListeners();
    }
  }
}
