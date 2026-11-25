import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/ui_helpers.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/branch_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/customer_nav_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../auth/login_view.dart';
import '../booking/booking_wizard_view.dart';
import '../branch/branch_detail_view.dart';
import '../branch/branch_list_view.dart';
import '../feedback/submit_feedback_view.dart';
import '../hairstyle/hairstyle_list_view.dart';
import '../loyalty/reward_catalog_view.dart';
import '../notification/notification_list_view.dart';
import '../services/service_catalog_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final AuthController _authController = AuthController();
  final BranchController _branchController = BranchController();
  final PromotionController _promotionController = PromotionController();
  final NotificationController _notificationController =
      NotificationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authController.refreshProfile();
      _branchController.retrieveBranches();
      _promotionController.loadPromotions();
      _notificationController.loadNotifications();
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Konfirmasi Keluar',
      message: 'Apakah Anda yakin ingin keluar dari akun?',
      confirmLabel: 'Ya, Keluar',
      cancelLabel: 'Batal',
    );
    if (!confirmed) return;

    await _authController.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          'TER THE CUT',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
        actions: [
          // Lonceng Notifikasi In-App dengan Badge Reaktif (US-21)
          ListenableBuilder(
            listenable: _notificationController,
            builder: (context, _) {
              final unread = _notificationController.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 22,
                      color: AppColors.ink,
                    ),
                    tooltip: 'Notifikasi',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationListView(),
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.paper,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppColors.inkSoft),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sapaan Editorial
              ListenableBuilder(
                listenable: _authController,
                builder: (context, _) {
                  final profile = _authController.currentProfile;
                  final name = profile?.name ?? 'Pelanggan';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang,',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      Text(
                        name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Digital Membership Card (Editorial Style)
              ListenableBuilder(
                listenable: _authController,
                builder: (context, _) {
                  final profile = _authController.currentProfile;
                  final tier = profile?.tier ?? 'Bronze';
                  final points = profile?.pointsBalance ?? 0;
                  final lifetime = profile?.lifetimePoints ?? 0;
                  final name = profile?.name ?? 'Ter The Cut Member';

                  return InkWell(
                    onTap: () => CustomerNavController().toPointLedger(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'MEMBERSHIP CARD',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  color: AppColors.paper.withValues(alpha: 0.7),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  tier.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: AppColors.paper,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '$points',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: AppColors.paper,
                            ),
                          ),
                          Text(
                            'SALDO POIN LOYALITAS',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: AppColors.paper.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 2,
                            color: AppColors.paper.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.paper,
                                ),
                              ),
                              Text(
                                'Mutasi: $lifetime Pts ->',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Tombol Utama Reservasi Jadwal (Sprint 2)
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                label: const Text('RESERVASI JADWAL SEKARANG'),
                onPressed: () {
                  final bc = BookingController();
                  bc.initWizard();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookingWizardView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Menu Pintasan Cepat (Simetris 2 Baris x 3 Kolom)
              Text(
                'LAYANAN UTAMA',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.store_outlined,
                    label: '11 Cabang',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BranchListView()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.content_cut_outlined,
                    label: 'Layanan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServiceCatalogView(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.face_outlined,
                    label: 'Inspirasi',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HairstyleListView(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.card_giftcard_outlined,
                    label: 'Tukar Reward',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RewardCatalogView(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bagian Cabang Populer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LOKASI CABANG',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BranchListView()),
                    ),
                    child: Text(
                      'Lihat Semua (11)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _branchController,
                builder: (context, _) {
                  if (_branchController.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: AppColors.ink),
                      ),
                    );
                  }

                  final previewBranches = _branchController.branches
                      .take(3)
                      .toList();
                  return Column(
                    children: previewBranches.map((branch) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  branch.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                branch.statusText,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: branch.isOpenNow
                                      ? AppColors.success
                                      : AppColors.danger,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              branch.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.inkSoft,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BranchDetailView(branch: branch),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Banner Kritik & Saran Pelanggan (US-14)
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubmitFeedbackView()),
                ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Punya Kritik atau Saran?',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sampaikan pengalaman Anda untuk peningkatan kualitas layanan.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.inkSoft,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: AppColors.ink),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
