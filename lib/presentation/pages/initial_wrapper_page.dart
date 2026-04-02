// lib/presentation/pages/initial_wrapper_page.dart

import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  bool _isLoggedIn = false;
  User? _currentUser;
  int? _selectedCategoryId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _checkLoginStatusAndUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatusAndUser() async {
    _isLoggedIn = await AuthRemoteDatasource().isLogin();
    if (_isLoggedIn) {
      _currentUser = await AuthRemoteDatasource().getUserInfo();
    }
    setState(() {});
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Jika sudah login, cek role user dan arahkan ke halaman yang sesuai
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

    // Tampilan untuk Guest
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === HERO BANNER ===
                    _buildHeroBanner(),

                    // === INFO KOPITIAM ===
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: const KopitiamInfoWidget(),
                    ),

                    const SizedBox(height: 8),

                    // === SEKSI PENGUMUMAN & PROMO (hanya ditambah oleh owner) ===
                    _buildAnnouncementSection(),

                    const SizedBox(height: 8),

                    // === DIVIDER ===
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                  thickness: 1)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "MENU KAMI",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                  thickness: 1)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // === KATEGORI & GRID PRODUK ===
                    ProductCategoryAndGridSection(
                      isLoggedIn: false,
                      selectedCategoryId: _selectedCategoryId,
                      searchQuery: null,
                      onCategorySelected: (id) {
                        setState(() {
                          _selectedCategoryId = id;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // === FOOTER CTA ===
                    _buildFooterCTA(context),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // SLIVER APP BAR
  // ─────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryGreen,
      title: Row(
        children: [
          // Logo lingkaran kopi
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee, color: Colors.white, size: 18),
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
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          ),
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ).then((value) => _checkLoginStatusAndUser());
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

  // ─────────────────────────────────────────
  // HERO BANNER
  // ─────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekorasi lingkaran di sudut
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Konten
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "☕  Selamat Datang",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Nikmati Cita Rasa\nTerbaik Kami",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Kopi pilihan, suasana hangat, harga ramah.",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _buildHeroStat("☕", "20+", "Varian Kopi"),
                  const SizedBox(width: 20),
                  _buildHeroStat("🍴", "30+", "Menu Makanan"),
                  const SizedBox(width: 20),
                  _buildHeroStat("⭐", "4.9", "Rating"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String emoji, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$emoji $value",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.75),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // SEKSI PENGUMUMAN (hanya dikelola owner)
  // ─────────────────────────────────────────
  Widget _buildAnnouncementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Pengumuman & Promo",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const Spacer(),
              // Label informatif: hanya owner yang dapat mengelola
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        size: 12, color: AppColors.primaryGreen),
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
        const SizedBox(height: 12),
        // Widget daftar pengumuman (data dikelola oleh owner via dashboard)
        const AnnouncementListWidget(),
      ],
    );
  }

  // ─────────────────────────────────────────
  // FOOTER CTA (ajak login)
  // ─────────────────────────────────────────
  Widget _buildFooterCTA(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mau pesan lebih mudah?",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Login untuk menikmati fitur lengkap.",
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ).then((value) => _checkLoginStatusAndUser());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              "Login",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}