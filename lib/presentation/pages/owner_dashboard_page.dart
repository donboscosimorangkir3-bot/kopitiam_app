// lib/presentation/pages/owner_dashboard_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/datasources/report_remote_datasource.dart';
import 'package:kopitiam_app/data/models/report_summary_model.dart';
import 'package:kopitiam_app/data/models/top_product_model.dart';
import 'package:kopitiam_app/data/models/daily_sales_model.dart';
import 'package:kopitiam_app/data/models/user_model.dart';

import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/product_management_page.dart';
import 'package:kopitiam_app/presentation/pages/category_management_page.dart';
import 'package:kopitiam_app/presentation/pages/announcement_management_page.dart';
import 'package:kopitiam_app/presentation/pages/sales_report_page.dart';
import 'package:kopitiam_app/presentation/pages/staff_management_page.dart';
import 'package:kopitiam_app/presentation/pages/cafe_info_management_page.dart';
import 'package:kopitiam_app/presentation/pages/table_management_page.dart';
import 'package:kopitiam_app/presentation/pages/profile_management_page.dart';

class OwnerDashboardPage extends StatefulWidget {
  final User user;
  const OwnerDashboardPage({super.key, required this.user});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage>
    with SingleTickerProviderStateMixin {
  // ── FIX: state user lokal agar update profil langsung terganti ──
  late User _currentUser;

  ReportSummary? _summary;
  bool _isLoading = true;
  bool _hasError = false;
  bool _localeReady = false;
  int? _prevCompletedOrders;
  bool _showNewOrderBadge = false;

  DateTime _selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  Timer? _autoRefreshTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Inisialisasi user lokal dari widget
    _currentUser = widget.user;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animController, curve: Curves.easeOutCubic));

    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) setState(() => _localeReady = true);
      _fetchReportSummary();
    });

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchReportSummary(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────────
  Future<void> _fetchReportSummary({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final result = await ReportRemoteDatasource().getReportSummary(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );

      if (!mounted) return;

      if (_prevCompletedOrders != null &&
          result != null &&
          result.completedOrders > _prevCompletedOrders!) {
        setState(() => _showNewOrderBadge = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _showNewOrderBadge = false);
        });
      }

      setState(() {
        _summary = result;
        _isLoading = false;
        _hasError = result == null;
        if (result != null) _prevCompletedOrders = result.completedOrders;
      });

      _animController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  /// Ambil 7 hari terakhir yang BENAR-BENAR ada datanya (ada transaksi)
  /// Jika kurang dari 7, tampilkan semua yang ada
  List<DailySales> _getLast7ActiveDays(List<DailySales> allData) {
    // Filter hanya hari yang punya transaksi (totalSales > 0)
    final activeDays = allData
        .where((d) => d.totalSales > 0)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // urutkan dari terbaru

    // Ambil 7 hari aktif terakhir, lalu balik ke urutan ascending (lama → baru)
    return activeDays.take(7).toList().reversed.toList();
  }

  String _formatPrice(double price) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(price);

  String _formatCompact(double price) {
    if (price >= 1000000) {
      return 'Rp ${(price / 1000000).toStringAsFixed(1)}Jt';
    } else if (price >= 1000) {
      return 'Rp ${(price / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp ${price.toStringAsFixed(0)}';
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 11) return "Selamat Pagi";
    if (h < 15) return "Selamat Siang";
    if (h < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  String _shortDayName(int weekday) {
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return names[(weekday - 1) % 7];
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: _selectedStartDate, end: _selectedEndDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _fetchReportSummary();
    }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: RefreshIndicator(
        onRefresh: _fetchReportSummary,
        color: AppColors.primaryGreen,
        backgroundColor: Colors.white,
        displacement: 80,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),

            if (_showNewOrderBadge)
              SliverToBoxAdapter(child: _buildNewOrderBanner()),

            SliverToBoxAdapter(child: _buildDateFilter()),

            if (_isLoading || !_localeReady)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGreen, strokeWidth: 2.5),
                ),
              )
            else if (_hasError || _summary == null)
              SliverFillRemaining(child: _buildErrorState())
            else
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          _sectionTitle("Ringkasan Bisnis",
                              Icons.dashboard_rounded, AppColors.primaryGreen),
                          const SizedBox(height: 12),
                          _buildKpiGrid(_summary!),

                          const SizedBox(height: 14),
                          _buildCompletionCard(_summary!),

                          const SizedBox(height: 18),
                          _sectionTitle("7 Hari Penjualan Terakhir",
                              Icons.bar_chart_rounded,
                              const Color(0xFF1565C0)),
                          const SizedBox(height: 12),
                          _buildDailySalesSection(_summary!.dailySales),

                          const SizedBox(height: 18),
                          _sectionTitle("Produk Terlaris",
                              Icons.emoji_events_rounded,
                              const Color(0xFFF57F17)),
                          const SizedBox(height: 12),
                          _buildTopProductsSection(_summary!.topProducts),

                          const SizedBox(height: 18),
                          _sectionTitle("Manajemen",
                              Icons.apps_rounded, AppColors.primaryGreen),
                          const SizedBox(height: 12),
                          _buildManagementGrid(),

                          const SizedBox(height: 18),
                          _buildPeriodeInfoCard(_summary!),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // HEADER — pakai _currentUser agar langsung update
  // ═══════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -30, right: -20, child: _decorCircle(160, 0.06)),
          Positioned(top: 60, right: 75, child: _decorCircle(55, 0.08)),
          Positioned(bottom: -15, left: -30, child: _decorCircle(100, 0.05)),
          Positioned(bottom: 20, right: 40, child: _decorCircle(30, 0.07)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.workspace_premium_rounded,
                                      color: Colors.amber, size: 13),
                                  const SizedBox(width: 5),
                                  Text("Pemilik",
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_getGreeting(),
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.75))),
                            const SizedBox(height: 2),
                            // ── FIX: gunakan _currentUser.name ──
                            Text(
                              _currentUser.name,
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateManual(DateTime.now()),
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol aksi vertikal
                      Column(
                        children: [
                          _headerActionBtn(
                              icon: Icons.refresh_rounded,
                              onTap: _fetchReportSummary,
                              tooltip: 'Refresh'),
                          const SizedBox(height: 8),
                          // ── FIX: navigate dengan await + update _currentUser ──
                          _headerActionBtn(
                              icon: Icons.person_rounded,
                              onTap: () async {
                                final updatedUser =
                                    await Navigator.push<User>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileManagementPage(
                                        user: _currentUser),
                                  ),
                                );
                                if (updatedUser != null && mounted) {
                                  setState(() => _currentUser = updatedUser);
                                }
                              },
                              tooltip: 'Profil'),
                          const SizedBox(height: 8),
                          _headerActionBtn(
                              icon: Icons.logout_rounded,
                              onTap: () async {
                                await AuthRemoteDatasource().logout();
                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginPage()),
                                    (r) => false);
                              },
                              tooltip: 'Keluar',
                              isDestructive: true),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Quick stats strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.18)),
                    ),
                    child: _summary != null
                        ? Row(children: [
                            _headerStat('Total Omset',
                                _formatCompact(_summary!.totalRevenue),
                                Icons.payments_rounded),
                            _vDivider(),
                            _headerStat('Pesanan',
                                '${_summary!.totalOrders}',
                                Icons.receipt_long_rounded),
                            _vDivider(),
                            _headerStat('Selesai',
                                '${_summary!.completedOrders}',
                                Icons.task_alt_rounded),
                            _vDivider(),
                            _headerStat(
                                'Completion',
                                _summary!.totalOrders == 0
                                    ? '0%'
                                    : '${(_summary!.completedOrders / _summary!.totalOrders * 100).toStringAsFixed(0)}%',
                                Icons.donut_large_rounded),
                          ])
                        : Row(children: [
                            _headerStat('Total Omset', '—',
                                Icons.payments_rounded),
                            _vDivider(),
                            _headerStat(
                                'Pesanan', '—', Icons.receipt_long_rounded),
                            _vDivider(),
                            _headerStat(
                                'Selesai', '—', Icons.task_alt_rounded),
                            _vDivider(),
                            _headerStat('Completion', '—',
                                Icons.donut_large_rounded),
                          ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateManual(DateTime d) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 14),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 9, color: Colors.white.withOpacity(0.6)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _headerActionBtn({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 2),
      );

  // ─────────────────────────────────────────────────
  // NEW ORDER BANNER
  // ─────────────────────────────────────────────────
  Widget _buildNewOrderBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade500]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text("🎉 Ada pesanan baru yang selesai!",
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
          GestureDetector(
            onTap: () => setState(() => _showNewOrderBadge = false),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // DATE FILTER
  // ─────────────────────────────────────────────────
  Widget _buildDateFilter() {
    final fmt = DateFormat('dd MMM yyyy');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: _pickDateRange,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.date_range_rounded,
                    color: AppColors.primaryGreen, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rentang Laporan",
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey.shade500)),
                    Text(
                      "${fmt.format(_selectedStartDate)}  –  ${fmt.format(_selectedEndDate)}",
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Ubah",
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // KPI GRID
  // ─────────────────────────────────────────────────
  Widget _buildKpiGrid(ReportSummary summary) {
    final completionRate = summary.totalOrders == 0
        ? 0.0
        : (summary.completedOrders / summary.totalOrders) * 100;

    final kpis = [
      _KpiData(
        title: 'Total Omset',
        value: _formatCompact(summary.totalRevenue),
        sub: _formatPrice(summary.totalRevenue),
        icon: Icons.payments_rounded,
        color: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F2FD),
      ),
      _KpiData(
        title: 'Total Pesanan',
        value: '${summary.totalOrders}',
        sub: 'Semua status',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFE65100),
        bgColor: const Color(0xFFFFF3E0),
      ),
      _KpiData(
        title: 'Pesanan Selesai',
        value: '${summary.completedOrders}',
        sub: 'Tuntas terlayani',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF2D6A4F),
        bgColor: const Color(0xFFE8F5E9),
      ),
      _KpiData(
        title: 'Completion Rate',
        value: '${completionRate.toStringAsFixed(1)}%',
        sub: 'Tingkat penyelesaian',
        icon: Icons.donut_large_rounded,
        color: const Color(0xFF6A1B9A),
        bgColor: const Color(0xFFF3E5F5),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => _buildKpiCard(kpis[i]),
    );
  }

  Widget _buildKpiCard(_KpiData k) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: k.bgColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(k.icon, color: k.color, size: 18),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: k.color.withOpacity(0.3),
                    shape: BoxShape.circle),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k.value,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 1),
              Text(k.title,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500)),
              Text(k.sub,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // COMPLETION CARD
  // ─────────────────────────────────────────────────
  Widget _buildCompletionCard(ReportSummary summary) {
    final rate = summary.totalOrders == 0
        ? 0.0
        : (summary.completedOrders / summary.totalOrders).clamp(0.0, 1.0);
    final pending = summary.totalOrders - summary.completedOrders;
    final avgOrder = summary.completedOrders == 0
        ? 0.0
        : summary.totalRevenue / summary.completedOrders;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2D6A4F).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Performa Pesanan",
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(rate * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF95D5B2)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _darkStat('Selesai', '${summary.completedOrders}',
                  const Color(0xFF95D5B2)),
              const SizedBox(width: 24),
              _darkStat('Belum Selesai', '$pending',
                  Colors.orange.shade300),
              const SizedBox(width: 24),
              _darkStat('Total', '${summary.totalOrders}', Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text("Rata-rata per pesanan selesai: ",
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.75))),
                Expanded(
                  child: Text(
                    _formatPrice(avgOrder),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: Colors.white.withOpacity(0.65))),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // DAILY SALES CHART — 7 hari penjualan terakhir
  // ─────────────────────────────────────────────────
  Widget _buildDailySalesSection(List<DailySales> allData) {
    // ── FIX: ambil 7 hari yang benar-benar ada transaksi ──
    final data = _getLast7ActiveDays(allData);

    final maxSales =
        data.fold(0.0, (m, d) => d.totalSales > m ? d.totalSales : m);
    final total7 = data.fold(0.0, (s, d) => s + d.totalSales);
    final avg7 = data.isEmpty ? 0.0 : total7 / data.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label info jumlah hari aktif
          if (data.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    "Menampilkan ${data.length} hari dengan transaksi",
                    style: GoogleFonts.poppins(
                        fontSize: 10.5, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

          // Chip ringkasan
          Row(
            children: [
              _salesChip('Total ${data.length} Hari', _formatCompact(total7),
                  const Color(0xFF2D6A4F), const Color(0xFFE8F5E9)),
              const SizedBox(width: 8),
              _salesChip('Rata-rata/Hari', _formatCompact(avg7),
                  const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
              const SizedBox(width: 8),
              _salesChip(
                  'Hari Terbaik',
                  maxSales == 0 ? '-' : _formatCompact(maxSales),
                  const Color(0xFFF57F17),
                  const Color(0xFFFFF8E1)),
            ],
          ),
          const SizedBox(height: 18),

          // Bar chart atau empty state
          data.isEmpty
              ? _buildEmptyChart("Belum ada data penjualan")
              : SizedBox(
                  height: 210,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxSales == 0 ? 100000 : maxSales * 1.35,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxSales == 0
                            ? 25000
                            : (maxSales * 1.35) / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.grey.shade100, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            interval: maxSales == 0
                                ? 25000
                                : (maxSales * 1.35) / 4,
                            getTitlesWidget: (v, _) => Text(
                              _formatCompact(v),
                              style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= data.length) {
                                return const SizedBox.shrink();
                              }
                              final day = data[i].date;
                              final fmt = DateFormat('dd/MM');
                              // Tandai hari ini jika ada di data
                              final now = DateTime.now();
                              final isToday = day.day == now.day &&
                                  day.month == now.month &&
                                  day.year == now.year;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _shortDayName(day.weekday),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isToday
                                            ? const Color(0xFF2D6A4F)
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                    Text(
                                      fmt.format(day),
                                      style: GoogleFonts.poppins(
                                          fontSize: 8.5,
                                          color: isToday
                                              ? const Color(0xFF2D6A4F)
                                              : Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: const Color(0xFF1B4332),
                          getTooltipItem: (group, _, rod, __) {
                            final day = data[group.x].date;
                            return BarTooltipItem(
                              '${day.day}/${day.month}/${day.year}\n',
                              GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 10),
                              children: [
                                TextSpan(
                                  text: _formatPrice(rod.toY),
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      barGroups: data.asMap().entries.map((entry) {
                        final i = entry.key;
                        final d = entry.value;
                        final now = DateTime.now();
                        final isToday = d.date.day == now.day &&
                            d.date.month == now.month &&
                            d.date.year == now.year;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: d.totalSales,
                              width: 28,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              gradient: LinearGradient(
                                colors: isToday
                                    ? [
                                        const Color(0xFF1B4332),
                                        const Color(0xFF52B788),
                                      ]
                                    : [
                                        const Color(0xFF52B788),
                                        const Color(0xFFB7E4C7),
                                      ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(const Color(0xFF1B4332), const Color(0xFF52B788),
                  'Hari ini'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF52B788), const Color(0xFFB7E4C7),
                  'Hari lainnya'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c1, Color c2, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              colors: [c1, c2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10.5, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _salesChip(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 9, color: color.withOpacity(0.7))),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // TOP PRODUCTS
  // ─────────────────────────────────────────────────
  Widget _buildTopProductsSection(List<TopProduct> data) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: _buildEmptyChart("Belum ada data produk terlaris"),
      );
    }

    final total = data.fold(0, (s, d) => s + d.totalQuantity);
    final colors = _pieColors();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 145,
                height: 145,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    startDegreeOffset: -90,
                    sections: _buildPieSections(data),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.take(5).toList().asMap().entries.map(
                    (entry) {
                      final color = colors[entry.key % colors.length];
                      final item = entry.value;
                      final pct = total == 0
                          ? 0.0
                          : (item.totalQuantity / total) * 100;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(item.productName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF2D2D2D)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('${pct.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: color)),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0EDE8)),
          const SizedBox(height: 14),

          ...data.take(5).toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final color = colors[entry.key % colors.length];
            final pct = total == 0
                ? 0.0
                : (item.totalQuantity / total) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFFFF8E1)
                          : rank == 2
                              ? const Color(0xFFF5F5F5)
                              : rank == 3
                                  ? const Color(0xFFFBE9E7)
                                  : color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: rank <= 3
                          ? Text(
                              rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                              style: const TextStyle(fontSize: 15))
                          : Text('$rank',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(item.productName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A1A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('${item.totalQuantity} terjual',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 5,
                            backgroundColor: color.withOpacity(0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                            '${pct.toStringAsFixed(1)}% dari total penjualan',
                            style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Color> _pieColors() => const [
        Color(0xFF2D6A4F),
        Color(0xFFF57C00),
        Color(0xFF1565C0),
        Color(0xFF6A1B9A),
        Color(0xFFC62828),
      ];

  List<PieChartSectionData> _buildPieSections(List<TopProduct> data) {
    final colors = _pieColors();
    final total = data.fold(0, (s, d) => s + d.totalQuantity);
    return data.take(5).toList().asMap().entries.map((entry) {
      final color = colors[entry.key % colors.length];
      final pct = total == 0
          ? 0.0
          : (entry.value.totalQuantity / total) * 100;
      return PieChartSectionData(
        color: color,
        value: entry.value.totalQuantity.toDouble(),
        title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 52,
        titleStyle: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────
  // MANAGEMENT GRID
  // ─────────────────────────────────────────────────
  Widget _buildManagementGrid() {
    final menus = [
      _MenuData(
          title: 'Produk',
          icon: Icons.local_cafe_rounded,
          color: const Color(0xFF00796B),
          bg: const Color(0xFFE0F2F1),
          page: const ProductManagementPage()),
      _MenuData(
          title: 'Kategori',
          icon: Icons.category_rounded,
          color: const Color(0xFFE65100),
          bg: const Color(0xFFFFF3E0),
          page: const CategoryManagementPage()),
      _MenuData(
          title: 'Laporan',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF1565C0),
          bg: const Color(0xFFE3F2FD),
          page: const SalesReportPage()),
      _MenuData(
          title: 'Pengumuman',
          icon: Icons.campaign_rounded,
          color: const Color(0xFF6A1B9A),
          bg: const Color(0xFFF3E5F5),
          page: const AnnouncementManagementPage()),
      _MenuData(
          title: 'Manajemen\nStaf',
          icon: Icons.people_rounded,
          color: const Color(0xFFC2185B),
          bg: const Color(0xFFFCE4EC),
          page: const StaffManagementPage()),
      _MenuData(
          title: 'Info Kafe',
          icon: Icons.store_rounded,
          color: const Color(0xFF2E7D32),
          bg: const Color(0xFFE8F5E9),
          page: const CafeInfoManagementPage()),
      _MenuData(
          title: 'Manajemen\nMeja',
          icon: Icons.table_restaurant_rounded,
          color: const Color(0xFFBF360C),
          bg: const Color(0xFFFBE9E7),
          page: const TableManagementPage()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: menus.length,
      itemBuilder: (_, i) => _buildMenuCard(menus[i]),
    );
  }

  Widget _buildMenuCard(_MenuData m) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => m.page),
        );
        _fetchReportSummary();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: m.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(m.icon, color: m.color, size: 24),
            ),
            const SizedBox(height: 9),
            Text(
              m.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // INFO PERIODE CARD
  // ─────────────────────────────────────────────────
  Widget _buildPeriodeInfoCard(ReportSummary summary) {
    final fmt = DateFormat('dd MMM yyyy');
    final avgOrder = summary.completedOrders == 0
        ? 0.0
        : summary.totalRevenue / summary.completedOrders;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Detail Periode",
            Icons.info_outline_rounded, Colors.grey.shade600),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              _infoRow(
                  Icons.calendar_today_rounded,
                  "Periode Laporan",
                  "${fmt.format(_selectedStartDate)} – ${fmt.format(_selectedEndDate)}",
                  const Color(0xFF1565C0)),
              const Divider(height: 22, color: Color(0xFFF0EDE8)),
              _infoRow(Icons.payments_rounded, "Total Omset",
                  _formatPrice(summary.totalRevenue),
                  const Color(0xFF2D6A4F)),
              const Divider(height: 22, color: Color(0xFFF0EDE8)),
              _infoRow(
                  Icons.receipt_rounded,
                  "Rata-rata per Pesanan Selesai",
                  _formatPrice(avgOrder),
                  const Color(0xFFE65100)),
              const Divider(height: 22, color: Color(0xFFF0EDE8)),
              _infoRow(
                  Icons.pending_actions_rounded,
                  "Pesanan Belum Selesai",
                  '${summary.totalOrders - summary.completedOrders} pesanan',
                  const Color(0xFF6A1B9A)),
              const Divider(height: 22, color: Color(0xFFF0EDE8)),
              _infoRow(
                  Icons.update_rounded,
                  "Terakhir Diperbarui",
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}, ${fmt.format(now)}',
                  Colors.grey.shade500),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10.5, color: Colors.grey.shade500)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String msg) {
    return SizedBox(
      height: 90,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                color: Colors.grey.shade300, size: 32),
            const SizedBox(height: 8),
            Text(msg,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade400)),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 36, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text("Gagal Memuat Data",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text("Periksa koneksimu lalu coba lagi.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchReportSummary,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
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

// ─────────────────────────────────────────────────
// HELPER DATA CLASSES
// ─────────────────────────────────────────────────
class _KpiData {
  final String title, value, sub;
  final IconData icon;
  final Color color, bgColor;
  const _KpiData({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _MenuData {
  final String title;
  final IconData icon;
  final Color color, bg;
  final Widget page;
  const _MenuData({
    required this.title,
    required this.icon,
    required this.color,
    required this.bg,
    required this.page,
  });
}