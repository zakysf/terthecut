import 'dart:math';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/reward.dart';
import '../models/reward_redemption.dart';
import '../models/point_ledger.dart';
import '../models/profile.dart';

class LoyaltyService {
  // 3 Reward Resmi Sesuai PRD
  static final List<Reward> _seedRewards = [
    Reward(
      id: 'rew-1',
      name: 'Diskon Rp 10.000',
      description: 'Potongan harga langsung sebesar Rp 10.000 untuk satu kali layanan apa pun.',
      terms: 'Berlaku 30 hari sejak penukaran di seluruh 11 cabang Ter The Cut.',
      pointsCost: 50,
      sortOrder: 1,
    ),
    Reward(
      id: 'rew-2',
      name: 'Gratis Hair Mask',
      description: 'Satu kali perawatan Hair Mask - Short Hair tanpa biaya tambahan.',
      terms: 'Berlaku 30 hari sejak penukaran di seluruh 11 cabang Ter The Cut.',
      pointsCost: 80,
      sortOrder: 2,
    ),
    Reward(
      id: 'rew-3',
      name: 'Gratis Premium Haircut',
      description: 'Satu kali potongan rambut eksklusif Premium Haircut gratis.',
      terms: 'Berlaku 30 hari sejak penukaran di seluruh 11 cabang Ter The Cut.',
      pointsCost: 150,
      sortOrder: 3,
    ),
  ];

  static final List<RewardRedemption> _mockVouchers = [];
  static final List<PointLedgerEntry> _mockLedger = [];

  /// Mengambil katalog Reward yang tersedia
  Future<List<Reward>> fetchRewards() async {
    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('rewards')
            .select()
            .eq('is_active', true)
            .order('sort_order', ascending: true);

        final list = (data as List).map((e) => Reward.fromJson(e)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        // Fallback ke seed
      }
    }
    return _seedRewards;
  }

  /// Menukarkan poin pelanggan dengan Voucher Reward (US-12)
  Future<RewardRedemption> redeemReward({
    required Profile profile,
    required Reward reward,
  }) async {
    if (profile.pointsBalance < reward.pointsCost) {
      throw Exception(
        'Saldo poin Anda tidak mencukupi (${profile.pointsBalance}/${reward.pointsCost} Poin).',
      );
    }

    // Generate kode voucher unik (format REW-XXXXXXXX)
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomStr = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    final voucherCode = 'REW-$randomStr';

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 30));
    final redemptionId = 'red-${now.millisecondsSinceEpoch}';

    final redemption = RewardRedemption(
      id: redemptionId,
      customerId: profile.id,
      customerName: profile.name,
      customerPhone: profile.phone,
      rewardId: reward.id,
      rewardName: reward.name,
      rewardDescription: reward.description,
      pointsSpent: reward.pointsCost,
      voucherCode: voucherCode,
      status: 'active',
      expiresAt: expiresAt,
      createdAt: now,
    );

    final ledgerEntry = PointLedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}',
      customerId: profile.id,
      delta: -reward.pointsCost,
      reason: 'redeem',
      refId: redemptionId,
      note: reward.name,
      createdAt: now,
    );

    final client = SupabaseConfig.client;
    if (client != null && SupabaseConfig.isConfigured) {
      try {
        // Kurangi poin di tabel profiles
        final newPoints = profile.pointsBalance - reward.pointsCost;
        await client
            .from('profiles')
            .update({'points_balance': newPoints})
            .eq('id', profile.id);

        // Catat voucher di tabel reward_redemptions
        await client.from('reward_redemptions').insert({
          'customer_id': profile.id,
          'reward_id': reward.id,
          'points_spent': reward.pointsCost,
          'voucher_code': voucherCode,
          'status': 'active',
          'expires_at': expiresAt.toIso8601String(),
        });

        // Catat mutasi di point_ledger
        await client.from('point_ledger').insert({
          'customer_id': profile.id,
          'delta': -reward.pointsCost,
          'reason': 'redeem',
          'note': reward.name,
        });
      } catch (e) {
        // Fallback simpan ke mock
      }
    }

    // Simpan ke mock
    _mockVouchers.insert(0, redemption);
    _mockLedger.insert(0, ledgerEntry);

    return redemption;
  }

  /// Mengambil daftar voucher milik pelanggan (US-13)
  Future<List<RewardRedemption>> fetchCustomerVouchers(String customerId) async {
    final client = SupabaseConfig.client;
    final List<RewardRedemption> remoteList = [];

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('reward_redemptions')
            .select('*, rewards(name, description)')
            .eq('customer_id', customerId)
            .order('created_at', ascending: false);

        remoteList.addAll((data as List).map((e) => RewardRedemption.fromJson(e)).toList());
      } catch (e) {
        // Fallback ke mock
      }
    }

    final Map<String, RewardRedemption> merged = {};
    for (final v in _mockVouchers.where((v) => v.customerId == customerId || customerId == 'demo-user-1' || v.customerId.startsWith('mock-'))) {
      merged[v.voucherCode] = v;
    }
    for (final v in remoteList) {
      if (merged[v.voucherCode]?.status == 'used') {
        merged[v.voucherCode] = v.copyWith(status: 'used');
      } else {
        merged[v.voucherCode] = v;
      }
    }
    return merged.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Mengambil riwayat mutasi poin (Point Ledger) pelanggan (US-11)
  Future<List<PointLedgerEntry>> fetchCustomerPointLedger(String customerId) async {
    final client = SupabaseConfig.client;
    final List<PointLedgerEntry> remoteList = [];

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        final data = await client
            .from('point_ledger')
            .select()
            .eq('customer_id', customerId)
            .order('created_at', ascending: false);

        remoteList.addAll((data as List).map((e) => PointLedgerEntry.fromJson(e)).toList());
      } catch (e) {
        // Fallback ke mock
      }
    }

    final Map<String, PointLedgerEntry> merged = {};
    for (final l in _mockLedger.where((l) => l.customerId == customerId || customerId == 'demo-user-1' || l.customerId.startsWith('mock-'))) {
      merged[l.id] = l;
    }
    for (final l in remoteList) {
      merged[l.id] = l;
    }
    return merged.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Menambahkan mutasi poin langsung (misal saat kasir menandai selesai)
  void recordPointEarning({
    required String customerId,
    required int points,
    required String serviceName,
  }) {
    final now = DateTime.now();
    final entry = PointLedgerEntry(
      id: 'led-${now.millisecondsSinceEpoch}',
      customerId: customerId,
      delta: points,
      reason: 'visit',
      note: serviceName,
      createdAt: now,
    );
    _mockLedger.insert(0, entry);
  }

  /// Menandai voucher telah digunakan oleh pelanggan (US-13)
  Future<bool> useVoucher(String voucherCode) async {
    final cleanCode = voucherCode.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    final client = SupabaseConfig.client;

    if (client != null && SupabaseConfig.isConfigured) {
      try {
        await client
            .from('reward_redemptions')
            .update({'status': 'used'})
            .eq('voucher_code', cleanCode);
      } catch (e) {
        if (kDebugMode) {
          print('Supabase update voucher error: $e');
        }
      }
    }

    final index = _mockVouchers.indexWhere((v) => v.voucherCode.toUpperCase() == cleanCode);
    if (index != -1) {
      _mockVouchers[index] = _mockVouchers[index].copyWith(status: 'used');
    }
    return true;
  }
}

