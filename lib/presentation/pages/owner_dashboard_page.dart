// lib/presentation/pages/owner_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/datasources/report_remote_datasource.dart'; 
import 'package:kopitiam_app/data/models/report_summary_model.dart'; 
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/product_management_page.dart'; 
import 'package:kopitiam_app/presentation/pages/category_management_page.dart'; 
import 'package:kopitiam_app/presentation/pages/announcement_management_page.dart'; 
import 'package:kopitiam_app/presentation/pages/sales_report_page.dart'; 
import 'package:fl_chart/fl_chart.dart'; // Import Chart Library
import 'package:kopitiam_app/data/models/top_product_model.dart'; // Import TopProduct Model
import 'package:kopitiam_app/data/models/daily_sales_model.dart'; // Import DailySales Model


class OwnerDashboardPage extends StatefulWidget {
  final User user;
  const OwnerDashboardPage({super.key, required this.user});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  late Future<ReportSummary?> _reportSummaryFuture;
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchReportSummary();
  }

  // Fungsi untuk mengambil data ringkasan laporan
  Future<void> _fetchReportSummary() async {
    _reportSummaryFuture = ReportRemoteDatasource().getReportSummary(
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
    );
    setState(() {});
  }

  String _formatPrice(double price) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(price);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _selectedStartDate, end: _selectedEndDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen, // header background color
              onPrimary: AppColors.white, // header text color
              onSurface: AppColors.darkBrown, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && (picked.start != _selectedStartDate || picked.end != _selectedEndDate)) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _fetchReportSummary(); // Muat ulang data setelah tanggal diubah
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text(
          "Dashboard Owner",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
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
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Halo, ${widget.user.name}!",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            Text(
              "Selamat datang di Dashboard Owner.",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.greyText,
              ),
            ),
            const SizedBox(height: 20),

            // Filter Tanggal
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _selectDateRange(context),
                icon: const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                label: Text(
                  "${DateFormat('dd MMM').format(_selectedStartDate)} - ${DateFormat('dd MMM').format(_selectedEndDate)}",
                  style: GoogleFonts.poppins(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              "Ringkasan Bisnis",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<ReportSummary?>(
              future: _reportSummaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text("Tidak ada data ringkasan.", style: GoogleFonts.poppins(color: AppColors.greyText)));
                }

                final summary = snapshot.data!;
                return Column(
                  children: [
                    _buildInfoCard(
                      title: "Total Omset",
                      value: _formatPrice(summary.totalRevenue),
                      icon: Icons.monetization_on_outlined,
                      color: Colors.blueAccent,
                    ),
                    _buildInfoCard(
                      title: "Total Pesanan",
                      value: "${summary.totalOrders} Pesanan",
                      icon: Icons.receipt_long,
                      color: Colors.orangeAccent,
                    ),
                    _buildInfoCard(
                      title: "Pesanan Selesai",
                      value: "${summary.completedOrders} Pesanan",
                      icon: Icons.check_circle_outline,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 20),

                    // CHART PRODUK TERLARIS (Pie Chart)
                    Text(
                      "Produk Terlaris",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopProductsChart(summary.topProducts),
                    const SizedBox(height: 30),

                    // CHART PENJUALAN HARIAN (Bar Chart)
                    Text(
                      "Penjualan Harian",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDailySalesChart(summary.dailySales),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),

            // Bagian Manajemen & Laporan
            Text(
              "Manajemen & Laporan",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 16),
            _buildManagementOption(
              context,
              icon: Icons.category_outlined,
              title: "Manajemen Kategori",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryManagementPage()),
                );
                _fetchReportSummary(); // Refresh summary jika ada metrik yang terkait kategori
              },
            ),
            _buildManagementOption(
              context,
              icon: Icons.local_cafe_outlined,
              title: "Manajemen Produk",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductManagementPage()),
                );
                _fetchReportSummary(); // Refresh summary jika ada perubahan produk
              },
            ),
            _buildManagementOption(
              context,
              icon: Icons.receipt_long_outlined,
              title: "Laporan Penjualan",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalesReportPage()),
                );
                _fetchReportSummary(); // Refresh summary setelah melihat laporan
              },
            ),
            _buildManagementOption(
              context,
              icon: Icons.campaign_outlined,
              title: "Manajemen Pengumuman",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnnouncementManagementPage()),
                );
                _fetchReportSummary(); // Refresh summary jika ada pengumuman baru (opsional)
              },
            ),
            _buildManagementOption(
              context,
              icon: Icons.people_outline,
              title: "Manajemen Staf",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fitur Manajemen Staf")),
                );
                // TODO: Navigasi ke halaman Manajemen Staf (Admin/Kasir)
              },
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET KUSTOM: Info Card (untuk Omset, Pesanan, dll)
  Widget _buildInfoCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.greyText),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET KUSTOM: Pie Chart Produk Terlaris
  Widget _buildTopProductsChart(List<TopProduct> topProducts) {
    if (topProducts.isEmpty) {
      return _buildChartPlaceholder("Produk Terlaris (Tidak ada data)");
    }

    List<PieChartSectionData> sections = [];
    double totalQuantity = topProducts.fold(0.0, (sum, item) => sum + item.totalQuantity.toDouble()); // <-- Ubah initial sum menjadi 0.0
    List<Color> pieColors = [
      Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange, Colors.teal
    ];

    for (int i = 0; i < topProducts.length; i++) {
      final product = topProducts[i];
      final percentage = totalQuantity == 0 ? 0.0 : (product.totalQuantity / totalQuantity) * 100; // <-- Tambahkan null check
      sections.add(
        PieChartSectionData(
          color: pieColors[i % pieColors.length],
          value: product.totalQuantity.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
          // badgeWidget: Text(product.productName, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.darkBrown)), // BadgeWidget di fl_chart > 0.60 sudah dihapus/berubah
          showTitle: true, // Pastikan title ditampilkan
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      height: 250,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
          pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                // handle interaction
              }
            });
          }), // Tambahkan pieTouchData untuk menghilangkan error
        ),
      ),
    );
  }

  // WIDGET KUSTOM: Bar Chart Penjualan Harian
  Widget _buildDailySalesChart(List<DailySales> dailySales) {
    if (dailySales.isEmpty) {
      return _buildChartPlaceholder("Penjualan Harian (Tidak ada data)");
    }

    List<BarChartGroupData> barGroups = [];
    double maxSales = 0;

    for (int i = 0; i < dailySales.length; i++) {
      final sales = dailySales[i];
      if (sales.totalSales > maxSales) maxSales = sales.totalSales;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sales.totalSales,
              color: AppColors.primaryGreen,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxSales == 0 ? 1 : maxSales * 1.1,
                color: AppColors.lightCream,
              ),
            ),
          ],
          // showingTooltipToReset: [], // <-- Hapus baris ini
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxSales / 4),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final day = dailySales[value.toInt()].date.day; // <-- Pastikan ini mengakses .date.day
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text('$day', style: GoogleFonts.poppins(color: AppColors.darkBrown, fontSize: 10)),
                  );
                },
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(_formatPrice(value), style: GoogleFonts.poppins(color: AppColors.darkBrown, fontSize: 10));
                },
                interval: maxSales == 0 ? 1 : maxSales / 4, // <-- Tambahkan null check
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          alignment: BarChartAlignment.spaceAround,
          maxY: maxSales == 0 ? 1 : maxSales * 1.1,
        ),
      ),
    );
  }

  // WIDGET KUSTOM: Placeholder Chart
  Widget _buildChartPlaceholder(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: Text(
                "Tidak ada data untuk grafik ini.",
                style: GoogleFonts.poppins(color: AppColors.greyText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET KUSTOM: Opsi Manajemen (Sudah ada di OwnerDashboardPage)
  Widget _buildManagementOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen, size: 30),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBrown),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.greyText),
        onTap: onTap,
      ),
    );
  }
}