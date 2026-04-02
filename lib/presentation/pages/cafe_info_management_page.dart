// lib/presentation/pages/cafe_info_management_page.dart
// FIX: setelah simpan, fetch ulang data dari server agar preview
//      foto owner langsung terupdate + evict cache gambar lama

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/setting_model.dart';
import 'package:kopitiam_app/data/datasources/setting_remote_datasource.dart';

class CafeInfoManagementPage extends StatefulWidget {
  const CafeInfoManagementPage({super.key});

  @override
  State<CafeInfoManagementPage> createState() =>
      _CafeInfoManagementPageState();
}

class _CafeInfoManagementPageState extends State<CafeInfoManagementPage>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl  = TextEditingController();

  File?   _imageFile;
  String? _currentImageUrl;

  bool _isLoading  = true;
  bool _isSaving   = false;
  bool _isDirty    = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetchCafeData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _hoursCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // URL builder
  // ─────────────────────────────────────────────
  String? _buildImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$base/storage/$path';
  }

  // ─────────────────────────────────────────────
  // FETCH
  // ─────────────────────────────────────────────
  Future<void> _fetchCafeData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final data = await SettingRemoteDatasource().getSettings();
      if (data != null && mounted) {
        _nameCtrl.text  = data.cafeName;
        _descCtrl.text  = data.cafeDescription;
        _hoursCtrl.text = data.cafeOperationHours;
        _phoneCtrl.text = data.cafePhone;
        _addrCtrl.text  = data.cafeAddress;

        final newUrl = _buildImageUrl(data.cafeImage);

        setState(() {
          _currentImageUrl = newUrl;
          _imageFile       = null; // hapus file lokal setelah sync
        });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; _isDirty = false; });
        if (!silent) _animCtrl.forward();
      }
    }
  }

  // ─────────────────────────────────────────────
  // PILIH GAMBAR
  // ─────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _isDirty   = true;
      });
    }
  }

  void _removeNewImage() => setState(() => _imageFile = null);

  // ─────────────────────────────────────────────
  // SIMPAN — FIX UTAMA
  // Setelah berhasil simpan:
  // 1. Evict cache gambar lama supaya CachedNetworkImage
  //    mengunduh versi baru dari server
  // 2. Fetch ulang data dari server agar _currentImageUrl
  //    terupdate dengan path gambar baru
  // ─────────────────────────────────────────────
  Future<void> _saveCafeInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final settings = CafeSettings(
        cafeName:           _nameCtrl.text.trim(),
        cafeDescription:    _descCtrl.text.trim(),
        cafeOperationHours: _hoursCtrl.text.trim(),
        cafePhone:          _phoneCtrl.text.trim(),
        cafeAddress:        _addrCtrl.text.trim(),
      );

      final success =
          await SettingRemoteDatasource().updateSettings(settings, _imageFile);

      if (!mounted) return;

      if (success) {
        // Hapus cache gambar lama — paksa unduh ulang dari server
        await _evictImageCache();

        _snack('Data kafe berhasil disimpan! ✓');

        // Fetch ulang agar preview langsung update tanpa perlu restart
        await _fetchCafeData(silent: true);

        if (mounted) Navigator.pop(context, true);
      } else {
        _snack('Gagal menyimpan data. Periksa koneksi server.',
            error: true);
      }
    } catch (e) {
      if (mounted) _snack('Terjadi kesalahan: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Hapus cache gambar lama dari CachedNetworkImage
  Future<void> _evictImageCache() async {
    try {
      // Evict dengan cacheKey yang dipakai saat render
      await CachedNetworkImage.evictFromCache('cafe_banner_owner');
      await CachedNetworkImage.evictFromCache('cafe_banner');
      // Jika URL lama ada, evict juga berdasarkan URL
      if (_currentImageUrl != null) {
        await CachedNetworkImage.evictFromCache(_currentImageUrl!);
      }
    } catch (_) {
      // Evict gagal tidak kritis — lanjutkan
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
      backgroundColor: error ? Colors.redAccent : AppColors.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  Widget _circle(double s, double o) => Container(
        width: s, height: s,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(o)));

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return PopScope(
      canPop: !_isDirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Ada perubahan belum disimpan',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold)),
            content: Text('Keluar tanpa menyimpan?',
                style: GoogleFonts.poppins(fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Tetap di sini',
                    style: GoogleFonts.poppins(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Keluar',
                    style: GoogleFonts.poppins(color: Colors.red)),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F2EA),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryGreen, strokeWidth: 2.5))
            : FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildPhotoCard()),
                    SliverToBoxAdapter(child: _buildFormCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
        bottomNavigationBar: _isLoading ? null : _buildBottomAction(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -20, right: -20, child: _circle(130, 0.07)),
          Positioned(top: 50,  right: 70,  child: _circle(50,  0.08)),
          Positioned(bottom: -10, left: -15, child: _circle(80, 0.05)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manajemen Info Kafe',
                            style: GoogleFonts.playfairDisplay(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 20)),
                        Text('Kelola profil & kontak kafe',
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.white.withOpacity(0.72))),
                      ],
                    ),
                  ),
                  if (_isDirty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Belum disimpan',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOTO CARD
  // ─────────────────────────────────────────────
  Widget _buildPhotoCard() {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview foto
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _buildPhotoPreview(),
                ),
              ),

              // Label + tombol
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Banner Utama Kafe',
                              style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A))),
                          Text('Ditampilkan di profil kafe pelanggan',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ),

                    // Upload / Ganti
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen
                                  .withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasPhoto
                                  ? Icons.edit_rounded
                                  : Icons.add_photo_alternate_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _hasPhoto ? 'Ganti' : 'Upload',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Batal pilih foto baru
                    if (_imageFile != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _removeNewImage,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasPhoto =>
      _imageFile != null ||
      (_currentImageUrl != null && _currentImageUrl!.isNotEmpty);

  Widget _buildPhotoPreview() {
    const double h = 210;

    // Foto baru dari galeri (belum disimpan)
    if (_imageFile != null) {
      return Stack(
        children: [
          Image.file(_imageFile!,
              height: h, width: double.infinity, fit: BoxFit.cover),
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fiber_new_rounded,
                      size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('Foto baru (belum disimpan)',
                      style: GoogleFonts.poppins(
                          fontSize: 10.5, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Foto dari server — pakai CachedNetworkImage
    // Setelah _evictImageCache() dipanggil saat save, gambar ini
    // akan diunduh ulang dengan versi terbaru dari server
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        height: h,
        width: double.infinity,
        fit: BoxFit.cover,
        // Gunakan URL asli sebagai cacheKey — setelah evict,
        // cache lama tidak akan dipakai lagi
        cacheKey: _currentImageUrl,
        placeholder: (_, __) => _photoLoading(h),
        errorWidget: (_, __, ___) => _photoEmpty(h),
      );
    }

    return _photoEmpty(h);
  }

  Widget _photoLoading(double h) => Container(
        height: h,
        color: const Color(0xFFF0EBE0),
        child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primaryGreen),
        ),
      );

  Widget _photoEmpty(double h) => Container(
        height: h,
        color: const Color(0xFFF0EBE0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 46, color: Colors.brown.withOpacity(0.22)),
            const SizedBox(height: 8),
            Text('Tap untuk upload foto kafe',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.brown.withOpacity(0.38))),
            const SizedBox(height: 4),
            Text('Format: JPG, PNG, WEBP · Maks 4MB',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.brown.withOpacity(0.28))),
          ],
        ),
      );

  // ─────────────────────────────────────────────
  // FORM CARD
  // ─────────────────────────────────────────────
  Widget _buildFormCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Informasi Dasar'),
              const SizedBox(height: 14),
              _buildInput(ctrl: _nameCtrl, label: 'Nama Kafe',
                  icon: Icons.storefront_rounded,
                  onChanged: (_) => _markDirty()),
              _buildInput(ctrl: _descCtrl, label: 'Tentang / Deskripsi',
                  icon: Icons.description_rounded, maxLines: 4,
                  onChanged: (_) => _markDirty()),
              const SizedBox(height: 8),
              _sectionLabel('Kontak & Jam Operasional'),
              const SizedBox(height: 14),
              _buildInput(ctrl: _hoursCtrl, label: 'Jam Operasional',
                  icon: Icons.access_time_filled_rounded,
                  hint: 'Contoh: Setiap Hari 08:00 - 22:00',
                  onChanged: (_) => _markDirty()),
              _buildInput(ctrl: _phoneCtrl, label: 'Nomor Telepon',
                  icon: Icons.phone_android_rounded,
                  keyboard: TextInputType.phone,
                  onChanged: (_) => _markDirty()),
              _buildInput(ctrl: _addrCtrl, label: 'Alamat Lengkap',
                  icon: Icons.location_on_rounded, maxLines: 2,
                  onChanged: (_) => _markDirty()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A))),
      ],
    );
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Widget _buildInput({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboard,
    String? hint,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: GoogleFonts.poppins(
            fontSize: 13.5, color: const Color(0xFF1A1A1A)),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              fontSize: 12, color: Colors.grey.shade400),
          prefixIcon:
              Icon(icon, color: AppColors.primaryGreen, size: 21),
          filled: true,
          fillColor: const Color(0xFFF8F5EF),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppColors.primaryGreen, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1),
          ),
          labelStyle: GoogleFonts.poppins(
              fontSize: 13, color: Colors.grey.shade600),
        ),
        validator: (v) =>
            v!.trim().isEmpty ? 'Bidang ini tidak boleh kosong' : null,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM ACTION
  // ─────────────────────────────────────────────
  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveCafeInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor:
                  AppColors.primaryGreen.withOpacity(0.55),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('Simpan Data',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}