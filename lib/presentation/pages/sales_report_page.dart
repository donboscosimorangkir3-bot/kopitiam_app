// lib/presentation/pages/sales_report_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/order_remote_datasource.dart'; // Order Datasource
import 'package:kopitiam_app/data/models/order_model.dart'; // Order Model
import 'package:kopitiam_app/data/datasources/report_remote_datasource.dart'; // Report Datasource

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  late Future<List<Order>> _salesOrdersFuture;
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchSalesOrders();
  }

  Future<void> _fetchSalesOrders() async {
    _salesOrdersFuture = ReportRemoteDatasource().getDetailedSales(
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

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy, HH:mm').format(date);
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
              primary: AppColors.primaryGreen,
              onPrimary: AppColors.white,
              onSurface: AppColors.darkBrown,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
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
      _fetchSalesOrders(); // Muat ulang data setelah tanggal diubah
    }
  }

  Future<void> _exportReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mengekspor laporan..."), backgroundColor: AppColors.primaryGreen),
    );
    final message = await ReportRemoteDatasource().exportSales(
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('berhasil') ? AppColors.primaryGreen : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Laporan Penjualan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Ekspor ke Excel/PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Periode Laporan:",
                  style: GoogleFonts.poppins(fontSize: 16, color: AppColors.darkBrown),
                ),
                TextButton.icon(
                  onPressed: () => _selectDateRange(context),
                  icon: const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                  label: Text(
                    "${DateFormat('dd MMM yyyy').format(_selectedStartDate)} - ${DateFormat('dd MMM yyyy').format(_selectedEndDate)}",
                    style: GoogleFonts.poppins(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchSalesOrders,
              color: AppColors.primaryGreen,
              backgroundColor: AppColors.lightCream,
              child: FutureBuilder<List<Order>>(
                future: _salesOrdersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: Colors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Tidak ada data penjualan untuk periode ini.",
                        style: GoogleFonts.poppins(fontSize: 18, color: AppColors.greyText),
                      ),
                    );
                  }

                  final orders = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                  ),
                ),
                Text(
                  _formatPrice(order.totalAmount),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              "Pelanggan: ${order.user?.name ?? 'N/A'}",
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkGreen),
            ),
            Text(
              "Tanggal: ${_formatDate(order.createdAt)}",
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.greyText),
            ),
            const SizedBox(height: 10),
            Text(
              "Status: ${order.status.toUpperCase()}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(order.status),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Items:",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBrown),
            ),
            if (order.items != null && order.items!.isNotEmpty)
              ...order.items!.map((item) => Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text(
                      "${item.quantity}x ${item.productName} (${_formatPrice(item.price)})",
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.greyText),
                    ),
                  ))
            else
              Text("Tidak ada detail item.", style: GoogleFonts.poppins(fontSize: 13, color: AppColors.greyText)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return AppColors.primaryGreen;
      case 'processing':
        return Colors.blue;
      case 'shipping':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}