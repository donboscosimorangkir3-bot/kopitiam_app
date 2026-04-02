// lib/presentation/pages/sales_report_page.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/order_remote_datasource.dart';
import 'package:kopitiam_app/data/models/order_model.dart';
import 'package:kopitiam_app/data/datasources/report_remote_datasource.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isExporting = false;
  bool _isExportingPdf = false;

  DateTime _selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchSalesOrders();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalesOrders() async {
  setState(() { _isLoading = true; _hasError = false; });
  try {
    final result = await ReportRemoteDatasource().getDetailedSales(
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
    );
    
    if (!mounted) return;
    
    // Pastikan result tidak null sebelum assign
    setState(() { 
      _orders = result ?? []; 
      _isLoading = false; 
    });
    _animController.forward(from: 0);
  } catch (e) {
    debugPrint("Error fetching detailed sales report: $e"); // Ini akan tampilkan error aslinya
    if (!mounted) return;
    setState(() { _isLoading = false; _hasError = true; });
  }
}

  String _formatPrice(double price) => NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);

  String _formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy, HH:mm').format(date);

  String _formatDateShort(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':    return Colors.orange.shade600;
      case 'paid':       return AppColors.primaryGreen;
      case 'processing': return Colors.blue.shade600;
      case 'shipping':   return Colors.purple.shade500;
      case 'completed':  return Colors.green.shade600;
      case 'cancelled':  return Colors.red.shade500;
      default:           return Colors.grey.shade500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':    return Icons.access_time_rounded;
      case 'paid':       return Icons.check_circle_outline_rounded;
      case 'processing': return Icons.coffee_rounded;
      case 'shipping':   return Icons.local_shipping_rounded;
      case 'completed':  return Icons.task_alt_rounded;
      case 'cancelled':  return Icons.cancel_outlined;
      default:           return Icons.info_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':    return 'Menunggu';
      case 'paid':       return 'Dibayar';
      case 'processing': return 'Diproses';
      case 'shipping':   return 'Dikirim';
      case 'completed':  return 'Selesai';
      case 'cancelled':  return 'Dibatalkan';
      default:           return status;
    }
  }

  double get _totalRevenue => _orders
      .where((o) => o.status == 'completed' || o.status == 'paid')
      .fold(0.0, (s, o) => s + o.totalAmount);

  int get _completedCount =>
      _orders.where((o) => o.status == 'completed').length;

  int get _cancelledCount =>
      _orders.where((o) => o.status == 'cancelled').length;

  double get _avgOrderValue {
    final valid = _orders
        .where((o) => o.status == 'completed' || o.status == 'paid')
        .toList();
    if (valid.isEmpty) return 0;
    return valid.fold(0.0, (s, o) => s + o.totalAmount) / valid.length;
  }

  Future<void> _selectDateRange() async {
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
      _fetchSalesOrders();
    }
  }

  // =================================================================
  // == PERBAIKAN: Fungsi untuk membuat konten CSV
  // =================================================================
  String _generateCsvContent(
  List<Order> orders, {
  required DateTime startDate,
  required DateTime endDate,
  required double totalRevenue,
  required int completedCount,
  required int cancelledCount,
  required double avgOrderValue,
}) {
  List<List<String>> rows = [];
  String formatCurrencyValue(double value) => value.toInt().toString();

  // 1. Header & Ringkasan
  rows.add(['Laporan Penjualan Kopitiam33']);
  rows.add(['Periode:', '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}']);
  rows.add([]);
  rows.add(['Total Pendapatan:', formatCurrencyValue(totalRevenue)]);
  rows.add(['Total Pesanan:', orders.length.toString()]);
  rows.add(['Selesai:', completedCount.toString()]);
  rows.add(['Dibatalkan:', cancelledCount.toString()]);
  rows.add(['Rata-rata Per Pesanan:', formatCurrencyValue(avgOrderValue)]);
  rows.add([]); 

  // 2. Header Tabel
  List<String> header = [
    "No", "ID Pesanan", "Nomor Pesanan", "Pelanggan", "Email", 
    "Tipe", "Meja", "Total (Rp)", "Status", "Metode", "Tanggal", "Item"
  ];
  rows.add(header);

  // 3. Baris Data
  for (var i = 0; i < orders.length; i++) {
    final order = orders[i];
    final itemsDetail = order.items?.map((it) => '${it.quantity}x ${it.productName}').join(' | ') ?? '-';
    rows.add([
      (i + 1).toString(),
      order.id.toString(),
      order.orderNumber,
      order.user?.name ?? 'N/A',
      order.user?.email ?? 'N/A',
      order.orderType ?? '-',
      order.tableNumber?.toString() ?? '-',
      formatCurrencyValue(order.totalAmount),
      _getStatusLabel(order.status),
      order.paymentMethod ?? 'N/A',
      DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
      itemsDetail,
    ]);
  }

  // 4. Baris Total (Aman: pastikan ada data sebelum akses indeks)
  if (orders.isNotEmpty) {
    List<String> totalRow = List.filled(header.length, '');
    totalRow[6] = 'TOTAL'; 
    totalRow[7] = formatCurrencyValue(totalRevenue);
    rows.add(totalRow);
  }

  return rows.map((row) => row.map((c) => '"${c.replaceAll('"', '""')}"').join(';')).join('\n');
}


  // =================================================================
  // == PERBAIKAN: Fungsi ekspor laporan CSV/Excel
  // =================================================================
  Future<void> _exportReport() async {
  if (_isExporting) return;
  setState(() => _isExporting = true);
  _showSnackBar("Menyiapkan ekspor laporan Excel/CSV...",
      icon: Icons.hourglass_top_rounded);

  // ── Cek izin penyimpanan ──
  bool permissionGranted = false;
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      permissionGranted = true; // No permission needed for Android 13+
    } else {
      var status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() => _isExporting = false);
        _showPermissionDialog();
        return;
      }
      permissionGranted = status.isGranted;
    }
  } else {
    permissionGranted = true; // No special permission needed for iOS doc dir
  }

  if (!permissionGranted) {
    if (!mounted) return;
    setState(() => _isExporting = false);
    _showSnackBar(
        "Izin penyimpanan ditolak. Buka Pengaturan untuk mengizinkan.",
        isError: true,
        icon: Icons.block_rounded);
    return;
  }

  // ── Buat dan simpan file CSV ──
  try {
    final csvContent = _generateCsvContent(
      _orders,
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
      totalRevenue: _totalRevenue,
      completedCount: _completedCount,
      cancelledCount: _cancelledCount,
      avgOrderValue: _avgOrderValue,
    );

    final startStr = DateFormat('yyyy-MM-dd').format(_selectedStartDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_selectedEndDate);
    final fileName = 'laporan_penjualan_${startStr}_$endStr.csv';

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsString(csvContent);

    if (!mounted) return;
    setState(() => _isExporting = false);
    _showExportSuccessDialog(filePath, fileName);
    
  } catch (e) {
    if (!mounted) return;
    setState(() => _isExporting = false);
    _showSnackBar("Terjadi kesalahan saat membuat file: $e",
        isError: true, icon: Icons.error_outline_rounded);
  }
}


  /// Dialog izin permanent ditolak
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_open_rounded,
                    color: Colors.orange.shade600, size: 30),
              ),
              const SizedBox(height: 14),
              Text("Izin Diperlukan",
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text(
                "Izin penyimpanan diperlukan untuk mengunduh laporan Excel.\nBuka Pengaturan → Izin → Penyimpanan.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text("Nanti",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text("Buka Pengaturan",
                          style: GoogleFonts.poppins(
                              fontSize: 12,
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

  /// Dialog sukses ekspor
  void _showExportSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.download_done_rounded,
                    color: AppColors.primaryGreen, size: 32),
              ),
              const SizedBox(height: 14),
              Text("Ekspor Berhasil!",
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text("File laporan Excel (CSV) berhasil disimpan.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file_rounded,
                        color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(fileName,
                          style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tombol Bagikan
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Share.shareXFiles(
                    [XFile(filePath)],
                    subject: 'Laporan Penjualan Kopitiam33',
                    text: 'Laporan penjualan periode terlampir.',
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.85),
                    ]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text("Bagikan File",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Tombol Oke
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text("Nanti Saja",
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    style: GoogleFonts.poppins(fontSize: 12.5))),
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

  // ─────────────────────────────────────────────────
  // EXPORT OPTIONS BOTTOM SHEET
  // ─────────────────────────────────────────────────
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text("Ekspor Laporan",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 6),
            Text("Pilih format file yang ingin diunduh",
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            _exportOptionTile(
              icon: Icons.table_chart_rounded,
              iconColor: Colors.green.shade600,
              bgColor: Colors.green.shade50,
              title: "Excel (CSV)",
              subtitle: "Buka di Microsoft Excel atau Google Sheets",
              onTap: () { Navigator.pop(context); _exportReport(); },
            ),
            const SizedBox(height: 12),
            _exportOptionTile(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: Colors.redAccent,
              bgColor: Colors.red.shade50,
              title: "PDF",
              subtitle: "Laporan siap cetak dengan tampilan rapi",
              onTap: () { Navigator.pop(context); _exportPdf(); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A))),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // EKSPOR PDF — bersih tanpa duplikasi
  // ─────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    if (_isExportingPdf || _orders.isEmpty) return;
    setState(() => _isExportingPdf = true);
    _showSnackBar("Membuat laporan PDF...",
        icon: Icons.picture_as_pdf_rounded);

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.poppinsRegular();
      final fontBold = await PdfGoogleFonts.poppinsBold();

      final totalRevenue = _orders
          .where((o) => o.status == 'completed' || o.status == 'paid')
          .fold(0.0, (s, o) => s + o.totalAmount);
      final completedCount =
          _orders.where((o) => o.status == 'completed').length;
      final cancelledCount =
          _orders.where((o) => o.status == 'cancelled').length;
      final avgOrder =
          completedCount > 0 ? totalRevenue / completedCount : 0.0;

      final startStr = DateFormat('dd MMM yyyy').format(_selectedStartDate);
      final endStr = DateFormat('dd MMM yyyy').format(_selectedEndDate);
      final generated = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

      final primaryGreen = PdfColor.fromHex('2D6A4F');
      final darkGreen = PdfColor.fromHex('1B4332');
      final lightGreen = PdfColor.fromHex('ECFDF5');
      final grey = PdfColor.fromHex('6B7280');
      final red = PdfColor.fromHex('EF4444');
      final blue = PdfColor.fromHex('3B82F6');
      final amber = PdfColor.fromHex('F59E0B');

      PdfColor sc(String status) {
        switch (status) {
          case 'completed': case 'paid': return primaryGreen;
          case 'cancelled': return red;
          case 'processing': return blue;
          default: return amber;
        }
      }

      String sl(String status) {
        switch (status) {
          case 'pending': return 'Menunggu';
          case 'paid': return 'Dibayar';
          case 'processing': return 'Diproses';
          case 'completed': return 'Selesai';
          case 'cancelled': return 'Dibatalkan';
          default: return status;
        }
      }

      String fmtRp(double v) =>
          'Rp ${NumberFormat('#,###', 'id_ID').format(v)}';

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(color: darkGreen),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Kopitiam33',
                    style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.white)),
                pw.SizedBox(height: 3),
                pw.Text('Laporan Penjualan',
                    style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.white)),
                pw.Text('Periode: $startStr - $endStr',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey300)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Digenerate:',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey300)),
                pw.Text(generated,
                    style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white)),
                pw.SizedBox(height: 3),
                pw.Text('Hal. ${ctx.pageNumber}/${ctx.pagesCount}',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey300)),
              ]),
            ],
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 12),

          // KPI Cards
          pw.Row(children: [
            _kpi('Total Pendapatan', fmtRp(totalRevenue), primaryGreen, lightGreen, font, fontBold),
            pw.SizedBox(width: 6),
            _kpi('Total Pesanan', '${_orders.length}', blue, PdfColor.fromHex('EFF6FF'), font, fontBold),
            pw.SizedBox(width: 6),
            _kpi('Selesai', '$completedCount', primaryGreen, lightGreen, font, fontBold),
            pw.SizedBox(width: 6),
            _kpi('Dibatalkan', '$cancelledCount', red, PdfColor.fromHex('FEF2F2'), font, fontBold),
            pw.SizedBox(width: 6),
            _kpi('Rata-rata', fmtRp(avgOrder), PdfColor.fromHex('7C3AED'), PdfColor.fromHex('F5F3FF'), font, fontBold),
          ]),

          pw.SizedBox(height: 14),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Detail Transaksi',
                  style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColor.fromHex('1F2937'))),
              pw.Text('${_orders.length} pesanan',
                  style: pw.TextStyle(font: font, fontSize: 9, color: grey)),
            ],
          ),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('E5E7EB'), width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(20),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(1.0),
              4: const pw.FlexColumnWidth(2.5),
              5: const pw.FlexColumnWidth(1.1),
              6: const pw.FlexColumnWidth(1.4),
              7: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: darkGreen),
                children: ['No','Nomor Pesanan','Pelanggan','Tipe','Item','Status','Tanggal','Total']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                          child: pw.Text(h,
                              style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white)),
                        ))
                    .toList(),
              ),
              ..._orders.asMap().entries.map((e) {
  final i = e.key;
  final o = e.value;
  final rowBg = i % 2 == 0 ? PdfColors.white : PdfColors.grey100;
  final sColor = sc(o.status);
  final items = (o.items ?? []).map((it) => '${it.quantity}x ${it.productName}').join(', ');
  final tipe = o.orderType == 'dine-in' ? 'Dine In' : 'Pickup';
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: rowBg),
    children: [
      _tc('${i+1}', font, 8, grey, align: pw.TextAlign.center),
      _tc(o.orderNumber, fontBold, 8, PdfColor.fromHex('1F2937')),
      _tc(o.user?.name ?? 'N/A', font, 8, PdfColor.fromHex('374151')),
      _tc(tipe, font, 7.5, grey),
      _tc(items.isEmpty ? '-' : items, font, 7.5, grey, maxLines: 2),
      
      // ============ BAGIAN YANG SUDAH DIPERBAIKI (KODE BARU) ============
      _tc(sl(o.status), fontBold, 8, sColor),
      // ====================================================================

      _tc(DateFormat('dd/MM/yy HH:mm').format(o.createdAt), font, 7.5, grey),
      _tc(fmtRp(o.totalAmount), fontBold, 8, primaryGreen, align: pw.TextAlign.right),
    ],
  );
}),
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('F0FDF4')),
                children: [
                  pw.SizedBox(), pw.SizedBox(), pw.SizedBox(),
                  pw.SizedBox(), pw.SizedBox(), pw.SizedBox(),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                    child: pw.Text('TOTAL',
                        style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('1F2937')),
                        textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                    child: pw.Text(fmtRp(totalRevenue),
                        style: pw.TextStyle(font: fontBold, fontSize: 9, color: primaryGreen),
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'Laporan digenerate otomatis oleh sistem Kopitiam33 - $generated',
              style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColor.fromHex('9CA3AF')),
            ),
          ),
        ],
      ));

      final s = DateFormat('yyyy-MM-dd').format(_selectedStartDate);
      final en = DateFormat('yyyy-MM-dd').format(_selectedEndDate);
      final fileName = 'laporan_penjualan_${s}_$en.pdf';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      await File(filePath).writeAsBytes(await pdf.save());

      if (!mounted) return;
      setState(() => _isExportingPdf = false);
      _showPdfSuccessDialog(filePath, fileName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExportingPdf = false);
      _showSnackBar("Gagal buat PDF: $e",
          isError: true, icon: Icons.error_outline_rounded);
    }
  }

  pw.Widget _tc(String text, pw.Font font, double size, PdfColor color,
      {pw.TextAlign align = pw.TextAlign.left, int maxLines = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: size, color: color),
          textAlign: align,
          maxLines: maxLines),
    );
  }

  pw.Widget _kpi(String label, String value, PdfColor color, PdfColor bg,
      pw.Font font, pw.Font fontBold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: bg,
          border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 7, color: PdfColor.fromHex('6B7280'))),
            pw.SizedBox(height: 3),
            pw.Text(value,
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  void _showPdfSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 14),
              Text("PDF Berhasil Dibuat!",
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text("Laporan PDF siap untuk dibagikan.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(fileName,
                          style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Bagikan
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Share.shareXFiles(
                    [XFile(filePath)],
                    subject: 'Laporan Penjualan Kopitiam33',
                    text: 'Laporan penjualan PDF terlampir.',
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text("Bagikan PDF",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Nanti
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text("Nanti Saja",
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        onRefresh: _fetchSalesOrders,
        color: AppColors.primaryGreen,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildDateFilterCard()),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGreen, strokeWidth: 2.5),
                ),
              )
            else if (_hasError)
              SliverFillRemaining(child: _buildErrorState())
            else if (_orders.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      children: [
                        _buildSummarySection(),
                        const SizedBox(height: 20),
                        _buildListHeader(),
                        const SizedBox(height: 10),
                        ..._orders.map(_buildOrderCard),
                      ],
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
            AppColors.primaryGreen.withOpacity(0.83),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -20, right: -20, child: _circle(130, 0.07)),
          Positioned(top: 45, right: 65, child: _circle(50, 0.08)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Laporan Penjualan",
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          "Pantau omset & performa toko",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol Ekspor (1 tombol, 2 pilihan)
                  GestureDetector(
                    onTap: (_isExporting || _isExportingPdf)
                        ? null
                        : () => _showExportOptions(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35)),
                      ),
                      child: (_isExporting || _isExportingPdf)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download_rounded,
                                    color: Colors.white, size: 15),
                                const SizedBox(width: 4),
                                Text("Ekspor",
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            ),
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
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // ─────────────────────────────────────────────────
  // DATE FILTER
  // ─────────────────────────────────────────────────
  Widget _buildDateFilterCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: _selectDateRange,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                    Text("Periode Laporan",
                        style: GoogleFonts.poppins(
                            fontSize: 10.5, color: Colors.grey.shade500)),
                    Text(
                      "${_formatDateShort(_selectedStartDate)}  –  ${_formatDateShort(_selectedEndDate)}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("Ubah",
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // SUMMARY SECTION
  // ─────────────────────────────────────────────────
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Kartu omset utama
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
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
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Pendapatan",
                        style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.8))),
                    Text(
                      _formatPrice(_totalRevenue),
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Rata-rata / pesanan",
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.white.withOpacity(0.7))),
                  Text(_formatPrice(_avgOrderValue),
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4 kartu statistik kecil
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _statCard("Total Pesanan", "${_orders.length}",
                Icons.receipt_long_rounded, Colors.orange.shade600),
            _statCard("Selesai", "$_completedCount",
                Icons.task_alt_rounded, AppColors.primaryGreen),
            _statCard("Dibatalkan", "$_cancelledCount",
                Icons.cancel_outlined, Colors.red.shade500),
            _statCard(
                "Dalam Proses",
                "${_orders.where((o) => o.status == 'processing' || o.status == 'paid').length}",
                Icons.coffee_rounded,
                Colors.blue.shade600),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A))),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10.5, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // LIST HEADER
  // ─────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text("Detail Transaksi",
            style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A))),
        const Spacer(),
        Text("${_orders.length} pesanan",
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // ORDER CARD
  // ─────────────────────────────────────────────────
  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber,
                          style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A))),
                      Text("👤 ${order.user?.name ?? 'N/A'}",
                          style: GoogleFonts.poppins(
                              fontSize: 11.5, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatPrice(order.totalAmount),
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 8),

            // Tanggal
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 5),
                Text(_formatDate(order.createdAt),
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, color: Colors.grey.shade500)),
              ],
            ),

            const SizedBox(height: 8),

            // Items
            if (order.items != null && order.items!.isNotEmpty)
              ...order.items!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: Text("${item.quantity}",
                                style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen)),
                          ),
                        ),
                        Expanded(
                          child: Text(item.productName,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF2D2D2D)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(_formatPrice(item.price),
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ))
            else
              Text("Tidak ada detail item.",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // EMPTY & ERROR
  // ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 38, color: AppColors.primaryGreen.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text("Tidak Ada Data Penjualan",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text("Belum ada transaksi dalam\nperiode yang dipilih.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.6)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text("Ubah Periode",
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
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 38, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text("Gagal Memuat Laporan",
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
              onTap: _fetchSalesOrders,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
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