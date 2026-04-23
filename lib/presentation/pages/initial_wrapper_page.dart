// lib/presentation/pages/initial_wrapper_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/customer_home_page.dart';
import 'package:kopitiam_app/presentation/widgets/kopitiam_info_widget.dart';
import 'package:kopitiam_app/presentation/pages/cashier_dashboard_page.dart';
import 'package:kopitiam_app/presentation/pages/owner_dashboard_page.dart';
import 'package:kopitiam_app/presentation/widgets/announcement_list_widget.dart';
import 'package:kopitiam_app/presentation/widgets/product_category_and_grid_section.dart';

class InitialWrapperPage extends StatefulWidget {
  const InitialWrapperPage({super.key});

  @override
  State<InitialWrapperPage> createState() => _InitialWrapperPageState();
}

class _InitialWrapperPageState extends State<InitialWrapperPage>
    with TickerProviderStateMixin {
  bool _isLoggedIn = false;
  User? _currentUser;
  int? _selectedCategoryId;

  // ── ANIMATIONS ──────────────────────────────────
  late AnimationController _masterController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _badgeFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkLoginStatusAndUser();
  }

  void _initAnimations() {
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
    ));

    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatusAndUser() async {
    _isLoggedIn = await AuthRemoteDatasource().isLogin();
    if (_isLoggedIn) {
      _currentUser = await AuthRemoteDatasource().getUserInfo();
    }
    setState(() {});
    _masterController.forward();
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Routing berdasarkan role
    if (_isLoggedIn && _currentUser != null) {
      if (_currentUser!.role == 'owner') {
        return OwnerDashboardPage(user: _currentUser!);
      } else if (_currentUser!.role == 'admin' ||
          _currentUser!.role == 'cashier') {
        return CashierDashboardPage(user: _currentUser!);
      } else {
        return const CustomerHomePage();
      }
    }

    // ── TAMPILAN GUEST ──
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HERO BANNER ──
                FadeTransition(
                  opacity: _heroFade,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: _buildHeroBanner(context),
                  ),
                ),

                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── STATS ROW ──
                        _buildStatsRow(),

                        const SizedBox(height: 24),

                        // ── INFO KOPITIAM ──
                        _buildInfoCard(),

                        const SizedBox(height: 20),

                        // ── PENGUMUMAN ──
                        _buildAnnouncementSection(),

                        const SizedBox(height: 20),

                        // ── DIVIDER MENU ──
                        _buildMenuDivider(),

                        const SizedBox(height: 16),

                        // ── KATEGORI & GRID PRODUK ──
                        ProductCategoryAndGridSection(
                          isLoggedIn: false,
                          selectedCategoryId: _selectedCategoryId,
                          searchQuery: null,
                          onCategorySelected: (id) {
                            setState(() => _selectedCategoryId = id);
                          },
                        ),

                        const SizedBox(height: 28),

                        // ── FOOTER CTA ──
                        FadeTransition(
                          opacity: _badgeFade,
                          child: _buildFooterCTA(context),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════════
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      snap: true,
      elevation: 0,
      backgroundColor: AppColors.primaryGreen,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            "Kopitiam33",
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ).then((_) => _checkLoginStatusAndUser());
            },
            icon: const Icon(Icons.login_rounded,
                color: Colors.white, size: 15),
            label: Text(
              "Masuk",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // HERO BANNER — redesign premium
  // ═══════════════════════════════════════════════
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      // Tidak pakai margin agar full-bleed dari atas
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            Color.lerp(AppColors.primaryGreen, const Color(0xFF0D3D2B), 0.55)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // ── Dekorasi lingkaran besar kanan ──
          Positioned(
            right: -50,
            top: 20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          // ── Dot pattern kiri bawah ──
          Positioned(
            left: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(
                painter: _DotPatternPainter(),
                size: const Size(160, 80),
              ),
            ),
          ),

          // ── Konten ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge "Selamat Datang"
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("☕", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          "Selamat Datang di Kopitiam33",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Judul utama
                  Text(
                    "Nikmati Cita Rasa\nTerbaik Kami",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.22,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Kopi pilihan, suasana hangat, harga ramah\nuntuk menemani hari-harimu.",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // CTA Button
                  Row(
                    children: [
                      // Tombol Login
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          ).then((_) => _checkLoginStatusAndUser());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login_rounded,
                                  size: 16,
                                  color: AppColors.primaryGreen),
                              const SizedBox(width: 7),
                              Text(
                                "Masuk Sekarang",
                                style: GoogleFonts.poppins(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Teks "Lihat menu"
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Lihat menu dulu",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_downward_rounded,
                              size: 13,
                              color: Colors.white.withOpacity(0.75)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STATS ROW — melengkung dari hero ke konten
  // ═══════════════════════════════════════════════
  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      transform: Matrix4.translationValues(0, -22, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem("☕", "20+", "Minuman"),
          _buildStatDivider(),
          _buildStatItem("🍴", "20+", "Makanan"),
          _buildStatDivider(),
          _buildStatItem("⭐", "4.8", "Rating"),
          _buildStatDivider(),
          _buildStatItem("🕐", "07-22", "Jam Buka"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade100,
    );
  }

  // ═══════════════════════════════════════════════
  // INFO CARD — wrapper untuk KopitiamInfoWidget
  // ═══════════════════════════════════════════════
  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Tentang Kami",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Card wrapper dengan shadow halus
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const KopitiamInfoWidget(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ANNOUNCEMENT SECTION
  // ═══════════════════════════════════════════════
  Widget _buildAnnouncementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen.withOpacity(0.18),
                      AppColors.primaryGreen.withOpacity(0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.campaign_rounded,
                    size: 20, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pengumuman & Promo",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      "Info terkini dari Kopitiam33",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge "By Owner"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.25),
                      width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        size: 11, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      "By Owner",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const AnnouncementListWidget(),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // MENU DIVIDER
  // ═══════════════════════════════════════════════
  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Divider(
                color: AppColors.primaryGreen.withOpacity(0.20),
                thickness: 1),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.18), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.coffee_rounded,
                    size: 13, color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  "MENU KAMI",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Divider(
                color: AppColors.primaryGreen.withOpacity(0.20),
                thickness: 1),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // FOOTER CTA — ajak login
  // ═══════════════════════════════════════════════
  Widget _buildFooterCTA(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1C1C1C),
            const Color(0xFF2D2D2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekorasi sudut kanan
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          // Konten
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + label
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open_rounded,
                          size: 12, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        "Akses Penuh",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Mau pesan lebih\nmudah & cepat?",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Login untuk akses keranjang, riwayat pesanan,\ndan berbagai fitur eksklusif.",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Tombol Login utama
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          ).then((_) => _checkLoginStatusAndUser());
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGreen,
                                AppColors.primaryGreen.withOpacity(0.82),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryGreen.withOpacity(0.40),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Masuk Sekarang",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}

// ═══════════════════════════════════════════════
// DOT PATTERN PAINTER (dekorasi hero)
// ═══════════════════════════════════════════════
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const spacing = 16.0;
    const radius = 1.8;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}