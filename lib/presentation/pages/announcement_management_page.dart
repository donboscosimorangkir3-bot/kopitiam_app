// lib/presentation/pages/announcement_management_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/datasources/announcement_remote_datasource.dart';
import 'package:kopitiam_app/data/models/announcement_model.dart';
import 'package:kopitiam_app/presentation/pages/announcement_form_page.dart';

class AnnouncementManagementPage extends StatefulWidget {
  const AnnouncementManagementPage({super.key});

  @override
  State<AnnouncementManagementPage> createState() =>
      _AnnouncementManagementPageState();
}

class _AnnouncementManagementPageState
    extends State<AnnouncementManagementPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Announcement>> _announcementsFuture;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic));

    _fetchAnnouncements();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Bangun URL lengkap dari path relatif server
  // Sama persis dengan pola di cafe_info_management_page
  // ─────────────────────────────────────────────
  String? _buildImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    // Jika sudah berupa URL penuh, langsung pakai
    if (path.startsWith('http')) return path;
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$base/storage/$path';
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _announcementsFuture =
          AnnouncementRemoteDatasource().getAnnouncements();
    });
    _animController.forward(from: 0);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy • HH:mm').format(date);
  }

  void _showSnackBar(String message,
      {bool isError = false,
      IconData icon = Icons.info_outline_rounded}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 9),
            Expanded(
                child: Text(message,
                    style: GoogleFonts.poppins(fontSize: 13))),
          ],
        ),
        backgroundColor:
            isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  Future<void> _deleteAnnouncement(int id, String title) async {
    final confirmed = await _showDeleteDialog(title);
    if (confirmed != true) return;

    _showSnackBar('Menghapus "$title"...',
        icon: Icons.delete_outline_rounded);

    final success =
        await AnnouncementRemoteDatasource().deleteAnnouncement(id);
    if (!mounted) return;

    if (success) {
      _showSnackBar('"$title" berhasil dihapus',
          icon: Icons.check_circle_outline_rounded);
      _fetchAnnouncements();
    } else {
      _showSnackBar('Gagal menghapus pengumuman. Coba lagi.',
          isError: true, icon: Icons.error_outline_rounded);
    }
  }

  Future<bool?> _showDeleteDialog(String title) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                "Hapus Pengumuman?",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$title" akan dihapus secara permanen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text("Batal",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text("Hapus",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToForm({Announcement? announcement}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnnouncementFormPage(announcement: announcement),
      ),
    );
    _fetchAnnouncements();
  }

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAnnouncements,
              color: AppColors.primaryGreen,
              backgroundColor: Colors.white,
              child: FutureBuilder<List<Announcement>>(
                future: _announcementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                          strokeWidth: 2.5),
                    );
                  }
                  if (snapshot.hasError) return _buildErrorState();
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final list = snapshot.data!;
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          // Info bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                20, 14, 20, 4),
                            child: Row(
                              children: [
                                Text(
                                  "${list.length} pengumuman",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade500),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${list.where((a) => a.isActive).length} aktif",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 100),
                              itemCount: list.length,
                              itemBuilder: (_, i) =>
                                  _buildAnnouncementCard(list[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          "Tambah",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 13),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
            AppColors.primaryGreen.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 4),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manajemen Pengumuman",
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Kelola promo & info untuk pelanggan",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ANNOUNCEMENT CARD — gambar pakai CachedNetworkImage
  // ─────────────────────────────────────────────
  Widget _buildAnnouncementCard(Announcement announcement) {
    final isActive = announcement.isActive;

    // Bangun URL lengkap — FIX utama untuk gambar yang tidak muncul
    final imageUrl = _buildImageUrl(announcement.imageUrl);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: isActive
                ? AppColors.primaryGreen
                : Colors.grey.shade300,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── GAMBAR — CachedNetworkImage ──
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                // cacheKey unik per pengumuman agar gambar berbeda tidak
                // saling menimpa di cache
                cacheKey: 'announcement_${announcement.id}',
                placeholder: (_, __) => _imagePlaceholder(),
                errorWidget: (_, __, ___) => _imageError(),
              ),
            ),

          // ── KONTEN ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ikon megaphone
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    size: 20,
                    color: isActive
                        ? AppColors.primaryGreen
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 12),

                // Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul + badge status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: GoogleFonts.playfairDisplay(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF1A1A1A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryGreen
                                      .withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActive ? "Aktif" : "Nonaktif",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? AppColors.primaryGreen
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Isi
                      Text(
                        announcement.content,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Tanggal
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(announcement.publishedAt),
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Aksi edit & hapus
                Column(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          _navigateToForm(announcement: announcement),
                      child: Container(
                        width: 34, height: 34,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.blueAccent, size: 17),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _deleteAnnouncement(
                          announcement.id, announcement.title),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 17),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder shimmer saat gambar loading
  Widget _imagePlaceholder() {
    return _AnnouncementShimmer(height: 160);
  }

  // Widget error saat gambar gagal dimuat
  Widget _imageError() {
    return Container(
      height: 120,
      color: AppColors.primaryGreen.withOpacity(0.06),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 32,
                color: AppColors.primaryGreen.withOpacity(0.35)),
            const SizedBox(height: 6),
            Text('Gambar tidak tersedia',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.primaryGreen.withOpacity(0.45))),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EMPTY & ERROR STATE
  // ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.campaign_rounded,
                  size: 42,
                  color: AppColors.primaryGreen.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text("Belum Ada Pengumuman",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text(
              "Tambahkan pengumuman atau promo\nuntuk ditampilkan ke pelanggan.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.6),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => _navigateToForm(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primaryGreen,
                    AppColors.primaryGreen.withOpacity(0.8),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text("Buat Pengumuman",
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 38, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text("Gagal Memuat",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text("Periksa koneksi internetmu\nlalu coba lagi.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.6)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchAnnouncements,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(14)),
                child: Text("Coba Lagi",
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIMMER untuk placeholder gambar pengumuman
// ─────────────────────────────────────────────
class _AnnouncementShimmer extends StatefulWidget {
  final double height;
  const _AnnouncementShimmer({required this.height});

  @override
  State<_AnnouncementShimmer> createState() => _AnnouncementShimmerState();
}

class _AnnouncementShimmerState extends State<_AnnouncementShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(const Color(0xFFEAE5DC),
                  const Color(0xFFF2EDE4), _anim.value)!,
              Color.lerp(const Color(0xFFF2EDE4),
                  const Color(0xFFEAE5DC), _anim.value)!,
            ],
          ),
        ),
      ),
    );
  }
}