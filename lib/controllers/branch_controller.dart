import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../models/barber.dart';
import '../services/branch_service.dart';

/// Singleton controller manajemen daftar cabang dan kapster.
class BranchController extends ChangeNotifier {
  static final BranchController _instance = BranchController._internal();
  factory BranchController() => _instance;
  BranchController._internal();

  bool _isLoading = false;
  List<Branch> _branches = [];
  List<Branch> _filteredBranches = [];
  List<Barber> _selectedBranchBarbers = [];
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<Branch> get branches => _filteredBranches;
  List<Barber> get selectedBranchBarbers => _selectedBranchBarbers;
  String get searchQuery => _searchQuery;

  final _branchService = BranchService();

  Future<void> retrieveBranches() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _branchService.fetchBranches();
      _branches = data;
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Gagal memuat cabang: $e');
    }
  }

  void searchBranches(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredBranches = List.from(_branches);
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredBranches = _branches.where((b) {
        return b.name.toLowerCase().contains(q) ||
            b.address.toLowerCase().contains(q) ||
            b.city.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> loadBarbersForBranch(String branchId) async {
    try {
      _selectedBranchBarbers = [];
      notifyListeners();
      final barbers = await _branchService.fetchBarbersByBranch(branchId);
      _selectedBranchBarbers = barbers;
      notifyListeners();
    } catch (e) {
      _selectedBranchBarbers = [];
      notifyListeners();
    }
  }
}
