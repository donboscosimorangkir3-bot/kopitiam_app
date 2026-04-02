// lib/presentation/pages/owner_dashboard_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

class OwnerDashboardPage extends StatefulWidget {
  final User user;
  const OwnerDashboardPage({super.key, required this.user});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage>
    with SingleTickerProviderStateMixin {
  ReportSummary? _summary;
  bool _isLoading = true;
  bool _hasError = false;
  int? _prevCompletedOrders;
  bool _showNewOrderBadge = false;

  DateTime _selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  Timer? _autoRefreshTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animController, curve: Curves.easeOutCubic));

    _fetchReportSummary();

    // Auto-refresh setiap 60 detik agar pesanan selesai langsung masuk
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

  Future<void> _fetchReportSummary({bool silent = false}) async {
    if (!silent)
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

    try {
      final result = await ReportRemoteDatasource().getReportSummary(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );

      if (!mounted) return;

      // Deteksi pesanan selesai baru
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

  String _formatPrice(double price) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(price);
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 11) return "Selamat Pagi";
    if (h < 15) return "Selamat Siang";
    if (h < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
      ),
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
      body: RefreshIndicator(
        onRefresh: _fetchReportSummary,
        color: AppColors.primaryGreen,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),

            if (_showNewOrderBadge)
              SliverToBoxAdapter(child: _buildNewOrderBanner()),

            SliverToBoxAdapter(child: _buildDateFilter()),

            if (_isLoading)
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _buildKpiGrid(_summary!),
                          const SizedBox(height: 24),
                          _buildTopProductsSection(_summary!.topProducts),
                          const SizedBox(height: 16),
                          _buildDailySalesSection(_summary!.dailySales),
                          const SizedBox(height: 28),
                          _buildManagementSection(),
                          const SizedBox(height: 16),
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

  // ─────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.82)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -25, right: -20, child: _circle(140, 0.07)),
          Positioned(top: 50, right: 65, child: _circle(55, 0.08)),
          Positioned(bottom: -10, left: -30, child: _circle(80, 0.05)),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_getGreeting()},",
                          style: GoogleFonts.poppins(
                              fontSize: 12.5, color: Colors.white70),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.user.name,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
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
                      ],
                    ),
                  ),
                  // Refresh
                  GestureDetector(
                    onTap: _fetchReportSummary,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  // Logout
                  GestureDetector(
                    onTap: () async {
                      await AuthRemoteDatasource().logout();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
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

  // ─────────────────────────────────────────────────
  // NEW ORDER BANNER
  // ─────────────────────────────────────────────────
  Widget _buildNewOrderBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
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
            child: Text(
              "🎉 Ada pesanan baru yang selesai!",
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showNewOrderBadge = false),
            child:
                const Icon(Icons.close_rounded, color: Colors.white, size: 18),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: _pickDateRange,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.date_range_rounded,
                    color: AppColors.primaryGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rentang Laporan",
                        style: GoogleFonts.poppins(
                            fontSize: 10.5, color: Colors.grey.shade500)),
                    Text(
                      "${fmt.format(_selectedStartDate)}  –  ${fmt.format(_selectedEndDate)}",
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
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
      {
        'title': 'Total Omset',
        'value': _formatPrice(summary.totalRevenue),
        'icon': Icons.payments_rounded,
        'color': Colors.blue.shade600,
        'sub': 'Pendapatan',
      },
      {
        'title': 'Total Pesanan',
        'value': '${summary.totalOrders}',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.orange.shade600,
        'sub': 'Semua status',
      },
      {
        'title': 'Selesai',
        'value': '${summary.completedOrders}',
        'icon': Icons.task_alt_rounded,
        'color': AppColors.primaryGreen,
        'sub': 'Pesanan tuntas',
      },
      {
        'title': 'Completion',
        'value': '${completionRate.toStringAsFixed(1)}%',
        'icon': Icons.donut_large_rounded,
        'color': Colors.purple.shade500,
        'sub': 'Tingkat selesai',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text("Ringkasan Bisnis",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A))),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: kpis.length,
          itemBuilder: (_, i) {
            final k = kpis[i];
            final color = k['color'] as Color;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(k['icon'] as IconData, color: color, size: 18),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k['value'] as String,
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A))),
                      Text(k['title'] as String,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // TOP PRODUCTS CHART
  // ─────────────────────────────────────────────────
  Widget _buildTopProductsSection(List<TopProduct> data) {
    return _buildSectionCard(
      title: "Produk Terlaris",
      icon: Icons.emoji_events_rounded,
      iconColor: Colors.amber.shade600,
      child: data.isEmpty
          ? _buildEmptyChart("Belum ada data produk")
          : Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: _buildPieSections(data),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                ...data.take(5).toList().asMap().entries.map((entry) {
                  final colors = _pieColors();
                  final color = colors[entry.key % colors.length];
                  final item = entry.value;
                  final total =
                      data.fold(0, (s, d) => s + d.totalQuantity);
                  final pct = total == 0
                      ? 0.0
                      : (item.totalQuantity / total) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.productName,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: const Color(0xFF2D2D2D)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                            "${item.totalQuantity} terjual  •  ${pct.toStringAsFixed(1)}%",
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  List<Color> _pieColors() => [
        AppColors.primaryGreen,
        Colors.orange.shade500,
        Colors.blue.shade500,
        Colors.purple.shade400,
        Colors.red.shade400,
      ];

  List<PieChartSectionData> _buildPieSections(List<TopProduct> data) {
    final colors = _pieColors();
    final total = data.fold(0, (s, d) => s + d.totalQuantity);
    return data.take(5).toList().asMap().entries.map((entry) {
      final color = colors[entry.key % colors.length];
      final pct =
          total == 0 ? 0.0 : (entry.value.totalQuantity / total) * 100;
      return PieChartSectionData(
        color: color,
        value: entry.value.totalQuantity.toDouble(),
        title: "${pct.toStringAsFixed(0)}%",
        radius: 55,
        titleStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────
  // DAILY SALES CHART
  // ─────────────────────────────────────────────────
  Widget _buildDailySalesSection(List<DailySales> data) {
    return _buildSectionCard(
      title: "Penjualan Harian",
      icon: Icons.bar_chart_rounded,
      iconColor: Colors.blue.shade600,
      child: data.isEmpty
          ? _buildEmptyChart("Belum ada data penjualan")
          : SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey.shade100, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (v, _) => Text(
                          "Rp ${(v ~/ 1000)}K",
                          style: GoogleFonts.poppins(
                              fontSize: 9, color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= data.length)
                            return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('d/M').format(data[i].date),
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey.shade500),
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
                  barGroups: data.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.totalSales,
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.primaryGreen.withOpacity(0.6),
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
    );
  }

  // ─────────────────────────────────────────────────
  // MANAGEMENT SECTION
  // ─────────────────────────────────────────────────
  Widget _buildManagementSection() {
    final menus = [
      {
        'title': 'Produk',
        'icon': Icons.local_cafe_rounded,
        'color': Colors.teal.shade600,
        'page': const ProductManagementPage(),
      },
      {
        'title': 'Kategori',
        'icon': Icons.category_rounded,
        'color': Colors.orange.shade600,
        'page': const CategoryManagementPage(),
      },
      {
        'title': 'Laporan',
        'icon': Icons.bar_chart_rounded,
        'color': Colors.blue.shade600,
        'page': const SalesReportPage(),
      },
      {
        'title': 'Pengumuman',
        'icon': Icons.campaign_rounded,
        'color': Colors.purple.shade500,
        'page': const AnnouncementManagementPage(),
      },
      {
        'title': 'Manajemen Staf',
        'icon': Icons.people_rounded,
        'color': Colors.pink.shade500,
        'page': const StaffManagementPage(),
      },
      {
        'title': 'Info Kafe',
        'icon': Icons.info_outline,
        'color': Colors.green,
        'page': const CafeInfoManagementPage(),
      },
      {
        'title': 'Manajemen Meja',
        'icon': Icons.table_restaurant_rounded,
        'color': Colors.orange.shade700,
        'page': const TableManagementPage(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              "Manajemen",
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: menus.length,
          itemBuilder: (_, i) {
            final m = menus[i];
            final color = m['color'] as Color;

            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => m['page'] as Widget,
                  ),
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
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        m['icon'] as IconData,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      m['title'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String msg) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(msg,
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey.shade400)),
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
                  size: 38, color: Colors.redAccent),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
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