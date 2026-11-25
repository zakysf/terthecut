import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/ui_helpers.dart';
import '../../controllers/feedback_controller.dart';

/// Layanan Formulir Kritik & Saran Pelanggan (US-14)
class SubmitFeedbackView extends StatefulWidget {
  const SubmitFeedbackView({super.key});

  @override
  State<SubmitFeedbackView> createState() => _SubmitFeedbackViewState();
}

class _SubmitFeedbackViewState extends State<SubmitFeedbackView> {
  final FeedbackController _controller = FeedbackController();

  final TextEditingController _messageController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Harap tuliskan masukan atau saran Anda terlebih dahulu.';
      });
      showAppSnackBar(
        context,
        'Harap isi kolom kritik dan saran sebelum mengirim.',
        title: 'Perhatian',
        backgroundColor: AppColors.danger,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final success = await _controller.submitFeedback(message: text);
    if (!mounted) return;

    if (success) {
      _messageController.clear();
      _showSuccessDialog();
    } else {
      showAppSnackBar(
        context,
        _controller.errorMessage,
        title: 'Gagal Mengirim',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'MASUKAN BERHASIL TERKIRIM!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Terima kasih atas kritik dan saran yang Anda berikan. Masukan Anda sangat berharga bagi peningkatan mutu layanan Ter The Cut.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // Tutup dialog
                      Navigator.pop(context); // Kembali ke halaman Beranda
                      showAppSnackBar(
                        context,
                        'Kritik dan saran Anda telah tercatat ke sistem manajemen.',
                        title: 'Masukan Diterima',
                        icon: Icons.thumb_up_alt_outlined,
                      );
                    },
                    child: const Text('KEMBALI KE BERANDA'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          'KRITIK & SARAN',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Editorial
              Text(
                'Suara Anda Sangat Berharga',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bantu kami meningkatkan kualitas layanan, kebersihan gerai, dan kenyamanan potong rambut di seluruh cabang Ter The Cut.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Kategori Masukan
              Text(
                'KATEGORI MASUKAN',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _controller.categories.map((cat) {
                      final isSelected = _controller.selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.ink,
                        backgroundColor: AppColors.surface,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.paper : AppColors.ink,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.ink : AppColors.hairline,
                        ),
                        onSelected: (_) => _controller.setCategory(cat),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Form Input Teks Kritik & Saran
              Text(
                'PESAN ATAU SARAN',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 5,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Tuliskan pengalaman Anda secara jujur dan detail...',
                  contentPadding: const EdgeInsets.all(16),
                  errorText: _errorMessage,
                  errorStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Kirim
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final isSubmitting = _controller.isSubmitting;
                  return ElevatedButton(
                    onPressed: isSubmitting ? null : _handleSubmit,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.paper,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('KIRIM MASUKAN SAYA'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
