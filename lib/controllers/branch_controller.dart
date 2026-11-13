import 'package:get/get.dart';
import '../models/branch.dart';
import '../models/barber.dart';
import '../services/branch_service.dart';

class BranchController extends GetxController {
  final RxBool _isLoading = false.obs;
  final RxList<Branch> _branches = <Branch>[].obs;
  final RxList<Branch> _filteredBranches = <Branch>[].obs;
  final RxList<Barber> _selectedBranchBarbers = <Barber>[].obs;
  final RxString _searchQuery = ''.obs;

  bool get isLoading => _isLoading.value;
  List<Branch> get branches => _filteredBranches;
  List<Barber> get selectedBranchBarbers => _selectedBranchBarbers;
  String get searchQuery => _searchQuery.value;

  final _branchService = BranchService();

  @override
  void onInit() {
    retrieveBranches();
    super.onInit();
  }

  Future<void> retrieveBranches() async {
    try {
      _isLoading.value = true;
      final data = await _branchService.fetchBranches();
      _branches.assignAll(data);
      _filteredBranches.assignAll(data);
      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
      throw Exception('Gagal memuat cabang: $e');
    }
  }

  void searchBranches(String query) {
    _searchQuery.value = query;
    if (query.trim().isEmpty) {
      _filteredBranches.assignAll(_branches);
    } else {
      final q = query.toLowerCase();
      final filtered = _branches.where((b) {
        return b.name.toLowerCase().contains(q) ||
            b.address.toLowerCase().contains(q) ||
            b.city.toLowerCase().contains(q);
      }).toList();
      _filteredBranches.assignAll(filtered);
    }
  }

  Future<void> loadBarbersForBranch(String branchId) async {
    try {
      _selectedBranchBarbers.clear();
      final barbers = await _branchService.fetchBarbersByBranch(branchId);
      _selectedBranchBarbers.assignAll(barbers);
    } catch (e) {
      _selectedBranchBarbers.clear();
    }
  }
}

