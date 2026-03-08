import 'package:flutter/material.dart';
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

class OwnerDashboardPage extends StatefulWidget {
  final User user;

  const OwnerDashboardPage({super.key, required this.user});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  Future<ReportSummary?>? _reportSummaryFuture;

  DateTime _selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchReportSummary();
  }

  Future<void> _fetchReportSummary() async {
    setState(() {
      _reportSummaryFuture = ReportRemoteDatasource().getReportSummary(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
    });
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          "Dashboard Owner",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReportSummary,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthRemoteDatasource().logout();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReportSummary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              _buildHeader(),

              const SizedBox(height: 25),

              /// SUMMARY TITLE
              Text(
                "Ringkasan Bisnis",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              /// SUMMARY DATA
              FutureBuilder<ReportSummary?>(
                future: _reportSummaryFuture,
                builder: (context, snapshot) {

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Text("Tidak ada data.");
                  }

                  final summary = snapshot.data!;

                  double completionRate =
                      summary.totalOrders == 0
                          ? 0
                          : (summary.completedOrders /
                                  summary.totalOrders) *
                              100;

                  return Column(
                    children: [

                      /// KPI GRID
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _kpiCard(
                            "Total Omset",
                            _formatPrice(summary.totalRevenue),
                            Icons.monetization_on,
                            Colors.blue,
                          ),
                          _kpiCard(
                            "Total Pesanan",
                            "${summary.totalOrders}",
                            Icons.receipt_long,
                            Colors.orange,
                          ),
                          _kpiCard(
                            "Pesanan Selesai",
                            "${summary.completedOrders}",
                            Icons.check_circle,
                            AppColors.primaryGreen,
                          ),
                          _kpiCard(
                            "Completion Rate",
                            "${completionRate.toStringAsFixed(1)}%",
                            Icons.percent,
                            Colors.purple,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      _sectionCard(
                        "Produk Terlaris",
                        _buildTopProductsChart(summary.topProducts),
                      ),

                      const SizedBox(height: 20),

                      _sectionCard(
                        "Penjualan Harian",
                        _buildDailySalesChart(summary.dailySales),
                      ),

                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),

              /// MANAGEMENT MENU
              Text(
                "Manajemen",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
                children: [

                  _menuTile(
                    "Kategori",
                    Icons.category,
                    const CategoryManagementPage(),
                  ),

                  _menuTile(
                    "Produk",
                    Icons.local_cafe,
                    const ProductManagementPage(),
                  ),

                  _menuTile(
                    "Laporan",
                    Icons.bar_chart,
                    const SalesReportPage(),
                  ),

                  _menuTile(
                    "Pengumuman",
                    Icons.campaign,
                    const AnnouncementManagementPage(),
                  ),

                  /// MENU BARU STAFF
                  _menuTile(
                    "Manajemen Staf",
                    Icons.people_outline,
                    const StaffManagementPage(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, ${widget.user.name}",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Pantau performa bisnis Anda",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.storefront, color: Colors.white, size: 40)
        ],
      ),
    );
  }

  /// KPI CARD
  Widget _kpiCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  /// SECTION CARD
  Widget _sectionCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child
        ],
      ),
    );
  }

  /// MENU TILE
  Widget _menuTile(String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 30, color: AppColors.primaryGreen),
            const SizedBox(height: 10),
            Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// PIE CHART
  Widget _buildTopProductsChart(List<TopProduct> data) {
    if (data.isEmpty) {
      return const SizedBox(height: 150);
    }

    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.red,
    ];

    double total =
        data.fold(0, (sum, item) => sum + item.totalQuantity);

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            final percent =
                (item.totalQuantity / total) * 100;

            return PieChartSectionData(
              color: colors[index % colors.length],
              value: item.totalQuantity.toDouble(),
              title: "${percent.toStringAsFixed(1)}%",
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// BAR CHART
  Widget _buildDailySalesChart(List<DailySales> data) {
    if (data.isEmpty) {
      return const SizedBox(height: 150);
    }

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    "Rp ${value ~/ 1000}K",
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {

                  int index = value.toInt();

                  if (index >= 0 && index < data.length) {

                    final date = data[index].date;

                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('d MMM').format(date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }

                  return const Text('');
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.totalSales,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.primaryGreen,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}