// lib/presentation/pages/customer_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/cart_page.dart';
import 'package:kopitiam_app/presentation/pages/profile_page.dart';
import 'package:kopitiam_app/presentation/pages/settings_page.dart';
import 'package:kopitiam_app/presentation/pages/help_page.dart';
import 'package:kopitiam_app/presentation/widgets/product_category_and_grid_section.dart';
import 'package:kopitiam_app/presentation/pages/order_history_page.dart';
import 'package:kopitiam_app/presentation/widgets/announcement_list_widget.dart';
import 'package:kopitiam_app/presentation/pages/cafe_info_screen.dart';
import 'package:kopitiam_app/presentation/pages/notification_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with TickerProviderStateMixin {
  // ── STATE ───────────────────────────────────────
  User? _currentUser;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _selectedCategoryId;
  String? _currentSearchQuery;
  int _selectedNavIndex = 0;
  double _scrollOffset = 0;

  // ── ANIMATIONS ──────────────────────────────────
  late AnimationController _entryController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _contentFade;

  late AnimationController _navController;
  late Animation<double> _navScale;

  // ─────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_onScroll);
    _fetchUserData();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    ));
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _navScale = CurvedAnimation(
      parent: _navController,
      curve: Curves.elasticOut,
    );
  }

  void _onScroll() {
    if (mounted) setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _entryController.dispose();
    _navController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────────
  Future<void> _fetchUserData() async {
    final user = await AuthRemoteDatasource().getUserInfo();
    if (!mounted) return;
    setState(() => _currentUser = user);
    _entryController.forward();
    _navController.forward();
  }

  // ─────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────
  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 11) return "Selamat Pagi";
    if (h < 15) return "Selamat Siang";
    if (h < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  String _getGreetingEmoji() {
    final h = DateTime.now().hour;
    if (h < 11) return "☀️";
    if (h < 15) return "🌤️";
    if (h < 18) return "🌇";
    return "🌙";
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      extendBody: true,
      body: Stack(
        children: [
          // ── MAIN SCROLL CONTENT ──
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildCafeBanner(),
                      const SizedBox(height: 28),
                      _buildSectionLabel(
                        icon: Icons.campaign_rounded,
                        title: "Promo & Pengumuman",
                        sub: "Info terkini dari Kopitiam33",
                      ),
                      const SizedBox(height: 12),
                      const AnnouncementListWidget(),
                      const SizedBox(height: 28),
                      _buildMenuSeparator(),
                      const SizedBox(height: 16),
                      ProductCategoryAndGridSection(
                        isLoggedIn: true,
                        selectedCategoryId: _selectedCategoryId,
                        searchQuery: _currentSearchQuery,
                        onCategorySelected: (id) {
                          setState(() {
                            _selectedCategoryId = id;
                            _searchController.clear();
                            _currentSearchQuery = null;
                          });
                        },
                      ),
                      // Ruang untuk floating nav
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── FLOATING BOTTOM NAV ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: _navScale,
              child: _buildFloatingNav(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════════
  Widget _buildSliverAppBar() {
    final collapsed = _scrollOffset > 100;

    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primaryGreen,
      title: AnimatedOpacity(
        opacity: collapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.coffee_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              "Kopitiam33",
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 19,
              ),
            ),
          ],
        ),
      ),
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: FadeTransition(
          opacity: _headerFade,
          child: SlideTransition(
            position: _headerSlide,
            child: _buildExpandedHeader(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withGreen(
              (AppColors.primaryGreen.green * 0.78).toInt(),
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Dekorasi lingkaran
          Positioned(top: -40, right: -30, child: _circle(180, 0.06)),
          Positioned(top: 60, right: 80, child: _circle(60, 0.08)),
          Positioned(bottom: 10, left: -40, child: _circle(90, 0.05)),
          Positioned(bottom: -20, right: 20, child: _circle(55, 0.04)),
          // Pattern dot
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                painter: _DotPatternPainter(),
                size: const Size(double.infinity, 60),
              ),
            ),
          ),
          // Konten
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildGreetingText()),
                      _buildNotifBtn(),
                      const SizedBox(width: 2),
                      _buildPopupMenu(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Mau minum apa hari ini? ☕",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              _getGreeting(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          _currentUser?.name ?? 'Customer',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── NOTIFIKASI ──
  Widget _buildNotifBtn() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: Colors.white, size: 23),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // POPUP MENU
  // ═══════════════════════════════════════════════
  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon:
          const Icon(Icons.more_vert_rounded, color: Colors.white, size: 23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      color: Colors.white,
      offset: const Offset(0, 48),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfilePage()))
                .then((_) => _fetchUserData());
            break;
          case 'settings':
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsPage()));
            break;
          case 'help':
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HelpPage()));
            break;
          case 'logout':
            await AuthRemoteDatasource().logout();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
            break;
        }
      },
      itemBuilder: (_) => [
        _popItem('profile', Icons.person_outline_rounded, 'Profil Saya',
            const Color(0xFF1A1A1A)),
        _popItem('settings', Icons.settings_outlined, 'Pengaturan',
            const Color(0xFF1A1A1A)),
        _popItem('help', Icons.help_outline_rounded, 'Bantuan',
            const Color(0xFF1A1A1A)),
        const PopupMenuDivider(height: 1),
        _popItem(
            'logout', Icons.logout_rounded, 'Keluar', Colors.red.shade600),
      ],
    );
  }

  PopupMenuItem<String> _popItem(
      String val, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: val,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════
  Widget _buildSearchBar() {
    return StatefulBuilder(builder: (ctx, setInner) {
      return Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(
              fontSize: 13, color: const Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded,
                color: AppColors.primaryGreen, size: 20),
            hintText: "Cari kopi, makanan, kategori...",
            hintStyle: GoogleFonts.poppins(
                fontSize: 12.5, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _currentSearchQuery = null);
                      setInner(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 15, color: Colors.grey.shade500),
                    ),
                  )
                : null,
          ),
          onChanged: (v) {
            setState(() => _currentSearchQuery = v.isEmpty ? null : v);
            setInner(() {});
          },
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════
  // CAFE BANNER
  // ═══════════════════════════════════════════════
  Widget _buildCafeBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CafeInfoScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen,
                AppColors.primaryGreen.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.3),
                blurRadius: 15,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Selamat Datang!",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Kenali Kami Lebih Dekat",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Cek jam operasional & lokasi",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Lihat Info",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
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

  // ═══════════════════════════════════════════════
  // SECTION LABEL
  // ═══════════════════════════════════════════════
  Widget _buildSectionLabel({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.18),
                  AppColors.primaryGreen.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // MENU SEPARATOR
  // ─────────────────────────────────────────────────
  Widget _buildMenuSeparator() {
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
                  "PILIHAN MENU",
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
  // FLOATING BOTTOM NAV
  // ═══════════════════════════════════════════════
  Widget _buildFloatingNav() {
    final items = [
      _NavItem(Icons.home_rounded, "Beranda"),
      _NavItem(Icons.shopping_bag_rounded, "Keranjang"),
      _NavItem(Icons.receipt_long_rounded, "Pesanan"),
      _NavItem(Icons.person_rounded, "Profil"),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _selectedNavIndex == i;
          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: active ? 20 : 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreen.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].icon,
                    size: 20,
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.38),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: active
                        ? Row(children: [
                            const SizedBox(width: 7),
                            Text(
                              items[i].label,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 0:
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage()),
        ).then((_) => setState(() => _selectedNavIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
        ).then((_) => setState(() => _selectedNavIndex = 0));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        ).then((_) {
          setState(() => _selectedNavIndex = 0);
          _fetchUserData();
        });
        break;
    }
  }
}

// ═══════════════════════════════════════════════
// DOT PATTERN PAINTER (dekorasi header)
// ═══════════════════════════════════════════════
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    const radius = 2.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════
// HELPER NAV ITEM
// ═══════════════════════════════════════════════
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}