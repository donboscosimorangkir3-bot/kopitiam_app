// lib/presentation/pages/cafe_info_screen.dart
// Halaman INFO KAFE untuk Customer & Guest
// Perbaikan: CachedNetworkImage agar gambar tidak hilang + UI lebih premium

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/setting_model.dart';
import 'package:kopitiam_app/data/datasources/setting_remote_datasource.dart';

class CafeInfoScreen extends StatefulWidget {
  const CafeInfoScreen({super.key});

  @override
  State<CafeInfoScreen> createState() => _CafeInfoScreenState();
}

class _CafeInfoScreenState extends State<CafeInfoScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  CafeSettings? _cafeData;
  String? _imageUrl; // URL lengkap foto kafe

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _fetchCafeInfo();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Bangun URL lengkap gambar dari path relatif
  // Contoh: "cafe/abc.jpg" → "https://domain.com/storage/cafe/abc.jpg"
  // ─────────────────────────────────────────────
  String? _buildImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.trim().isEmpty) return null;
    // Jika sudah URL penuh (http/https), langsung pakai
    if (relativePath.startsWith('http')) return relativePath;
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$base/storage/$relativePath';
  }

  Future<void> _fetchCafeInfo() async {
    setState(() => _isLoading = true);
    try {
      final data = await SettingRemoteDatasource().getSettings();
      if (mounted) {
        setState(() {
          _cafeData  = data;
          _imageUrl  = _buildImageUrl(data?.cafeImage);
          _isLoading = false;
        });
        _animCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryGreen, strokeWidth: 2.5))
          : _cafeData == null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildSliverHeader(),
                      SliverToBoxAdapter(
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _buildMainContent(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ─────────────────────────────────────────────
  // SLIVER HEADER — gambar kafe dengan CachedNetworkImage
  // ─────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.primaryGreen,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _buildHeaderBackground(),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── GAMBAR KAFE — CachedNetworkImage supaya tidak hilang ──
        _imageUrl != null
            ? CachedNetworkImage(
                imageUrl: _imageUrl!,
                fit: BoxFit.cover,
                // cacheKey memastikan gambar sama tidak diunduh ulang
                cacheKey: 'cafe_banner',
                placeholder: (_, __) => _buildHeaderShimmer(),
                errorWidget: (_, __, ___) => _buildHeaderFallback(),
              )
            : _buildHeaderFallback(),

        // Gradient atas — agar tombol back terbaca
        Positioned(
          top: 0, left: 0, right: 0,
          height: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Gradient bawah — agar nama kafe terbaca
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: 130,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.72),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Nama cafe + badge status
        Positioned(
          bottom: 22,
          left: 22,
          right: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _cafeData?.cafeName ?? 'Kopitiam33',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Tag "Buka Sekarang" / jam operasional singkat
              if (_cafeData?.cafeOperationHours.isNotEmpty == true)
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _cafeData!.cafeOperationHours,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Shimmer saat gambar loading pertama kali
  Widget _buildHeaderShimmer() {
    return _AnimatedShimmer(
      child: Container(color: const Color(0xFFD4CFC7)),
    );
  }

  // Fallback ketika tidak ada foto atau URL error
  Widget _buildHeaderFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Lingkaran dekorasi
          Positioned(
            top: -40, right: -30,
            child: _circle(200, 0.06),
          ),
          Positioned(
            bottom: 40, left: -20,
            child: _circle(100, 0.05),
          ),
          // Ikon dan teks tengah
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 44, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  _cafeData?.cafeName ?? 'Kopitiam33',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // ─────────────────────────────────────────────
  // MAIN CONTENT
  // ─────────────────────────────────────────────
  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tentang kami ──
          _sectionTitle('Tentang Kami'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _cafeData!.cafeDescription,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.grey.shade700,
                height: 1.68,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Kontak & lokasi ──
          _sectionTitle('Informasi Kontak & Lokasi'),
          const SizedBox(height: 14),

          _buildInfoCard(
            icon: Icons.access_time_filled_rounded,
            title: 'Jam Operasional',
            subtitle: _cafeData!.cafeOperationHours,
            accentColor: Colors.orange.shade600,
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.phone_rounded,
            title: 'Nomor Telepon',
            subtitle: _cafeData!.cafePhone,
            accentColor: Colors.blue.shade600,
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.location_on_rounded,
            title: 'Alamat Lengkap',
            subtitle: _cafeData!.cafeAddress,
            accentColor: Colors.red.shade500,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 34, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text('Gagal memuat data kafe',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Periksa koneksi lalu coba lagi',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchCafeInfo,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text('Coba Lagi',
                  style: GoogleFonts.poppins(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ANIMATED SHIMMER — untuk placeholder loading gambar
// ═══════════════════════════════════════════════
class _AnimatedShimmer extends StatefulWidget {
  final Widget child;
  const _AnimatedShimmer({required this.child});

  @override
  State<_AnimatedShimmer> createState() => _AnimatedShimmerState();
}

class _AnimatedShimmerState extends State<_AnimatedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFFD4CFC7),
                  const Color(0xFFE8E3DB), _anim.value)!,
              Color.lerp(const Color(0xFFE8E3DB),
                  const Color(0xFFD4CFC7), _anim.value)!,
            ],
          ),
        ),
      ),
    );
  }
}