// lib/presentation/pages/order_detail_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetailPage extends StatefulWidget {
  final Order order;
  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Order _order;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  String _formatPrice(double price) => NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);

  String _formatDate(DateTime date) =>
      DateFormat('dd MMMM yyyy, HH:mm').format(date);

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
      case 'pending':    return 'Menunggu Konfirmasi';
      case 'paid':       return 'Sudah Dibayar';
      case 'processing': return 'Sedang Diproses';
      case 'shipping':   return 'Sedang Dikirim';
      case 'completed':  return 'Selesai';
      case 'cancelled':  return 'Dibatalkan';
      default:           return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':    return 'Pesananmu sedang menunggu konfirmasi dari kasir.';
      case 'paid':       return 'Pembayaran diterima. Pesananmu akan segera diproses.';
      case 'processing': return 'Pesananmu sedang disiapkan oleh tim dapur kami.';
      case 'shipping':   return 'Pesananmu sedang dalam perjalanan ke mejamu.';
      case 'completed':  return 'Pesananmu telah selesai. Terima kasih sudah mampir!';
      case 'cancelled':  return 'Pesanan ini dibatalkan. Hubungi kami jika ada pertanyaan.';
      default:           return '';
    }
  }

  final List<String> _steps = const [
    'pending', 'paid', 'processing', 'completed'
  ];

  int _currentStep(String status) {
    if (status == 'cancelled') return -1;
    final i = _steps.indexOf(status);
    return i < 0 ? 0 : i;
  }

  // ─────────────────────────────────────────────────
  // CANCEL ORDER
  // ─────────────────────────────────────────────────
  Future<void> _cancelOrder() async {
    final bool? confirm = await _showCancelDialog();
    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.orders}/${_order.id}/cancel',
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Update status order secara lokal agar UI langsung berubah
          _order = Order(
            id: _order.id,
            orderNumber: _order.orderNumber,
            status: 'cancelled',
            totalAmount: _order.totalAmount,
            orderType: _order.orderType,
            tableNumber: _order.tableNumber,
            shippingAddress: _order.shippingAddress,
            paymentMethod: _order.paymentMethod,
            createdAt: _order.createdAt,
            items: _order.items,
          );
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("Pesanan berhasil dibatalkan.",
                      style: GoogleFonts.poppins(fontSize: 13)),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
        );

        // Kembali ke halaman sebelumnya dengan signal refresh
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data['message'] ?? 'Gagal membatalkan pesanan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg,
                    style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<bool?> _showCancelDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                "Batalkan Pesanan?",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pesanan ${_order.orderNumber} akan dibatalkan dan stok akan dikembalikan. Tindakan ini tidak dapat diurungkan.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "Tidak",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Ya, Batalkan",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final statusColor = _getStatusColor(_order.status);
    final isCancelled = _order.status == 'cancelled';
    final canCancel = _order.status == 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      body: Column(
        children: [
          _buildHeader(context, statusColor),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(statusColor, isCancelled),
                  const SizedBox(height: 16),

                  if (!isCancelled) ...[
                    _buildProgressTracker(),
                    const SizedBox(height: 16),
                  ],

                  _buildOrderInfoCard(),
                  const SizedBox(height: 14),

                  _buildItemsCard(),
                  const SizedBox(height: 14),

                  _buildTotalCard(),

                  // ✅ TOMBOL BATALKAN — hanya muncul saat status pending
                  if (canCancel) ...[
                    const SizedBox(height: 20),
                    _buildCancelButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // CANCEL BUTTON
  // ─────────────────────────────────────────────────
  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _isCancelling ? null : _cancelOrder,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _isCancelling
              ? Colors.red.shade100
              : Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.redAccent.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Center(
          child: _isCancelling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.redAccent,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel_outlined,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Batalkan Pesanan",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -18, right: -18, child: _circle(110, 0.07)),
          Positioned(top: 40, right: 65, child: _circle(44, 0.08)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detail Pesanan",
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          _order.orderNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildStatusBanner(Color statusColor, bool isCancelled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red.shade50 : statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(_order.status),
                color: statusColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusLabel(_order.status),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(_order.status),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    final stepLabels = ['Menunggu', 'Dibayar', 'Diproses', 'Selesai'];
    final stepIcons = [
      Icons.access_time_rounded,
      Icons.check_circle_outline_rounded,
      Icons.coffee_rounded,
      Icons.task_alt_rounded,
    ];
    final current = _currentStep(_order.status);

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Text("Status Pesanan",
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 14),
          Row(
            children: List.generate(_steps.length, (i) {
              final isDone = i <= current;
              final isActive = i == current;
              final isLast = i == _steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppColors.primaryGreen
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: isActive
                                ? Border.all(
                                    color: AppColors.primaryGreen.withOpacity(0.4),
                                    width: 3)
                                : null,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryGreen.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(stepIcons[i],
                              size: 16,
                              color: isDone
                                  ? Colors.white
                                  : Colors.grey.shade400),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stepLabels[i],
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isDone
                                ? AppColors.primaryGreen
                                : Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: i < current
                                ? AppColors.primaryGreen
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
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
        children: [
          _infoRow(
            icon: Icons.tag_rounded,
            iconColor: Colors.blue.shade500,
            label: "Nomor Pesanan",
            value: _order.orderNumber,
            isFirst: true,
          ),
          _divider(),
          _infoRow(
            icon: Icons.schedule_rounded,
            iconColor: Colors.orange.shade500,
            label: "Tanggal Pesan",
            value: _formatDate(_order.createdAt),
          ),
          _divider(),
          _infoRow(
            icon: _getOrderTypeIcon(),
            iconColor: Colors.teal.shade500,
            label: "Tipe Pesanan",
            value: _getOrderTypeLabel(),
          ),
          if (_getTableNumber().isNotEmpty) ...[
            _divider(),
            _infoRow(
              icon: Icons.table_restaurant_rounded,
              iconColor: Colors.orange.shade600,
              label: "Nomor Meja",
              value: _getTableNumber(),
            ),
          ],
          _divider(),
          _infoRow(
            icon: Icons.payments_rounded,
            iconColor: Colors.purple.shade400,
            label: "Metode Pembayaran",
            value: _order.paymentMethod == 'cash_on_pickup'
                ? "Bayar di Kafe"
                : _order.paymentMethod ?? "N/A",
            isLast: true,
          ),
        ],
      ),
    );
  }

  IconData _getOrderTypeIcon() {
    if (_order.orderType == 'dine-in') return Icons.restaurant_rounded;
    return Icons.shopping_bag_rounded;
  }

  String _getOrderTypeLabel() {
    if (_order.orderType == 'dine-in') return 'Dine In (Makan di Tempat)';
    return 'Pickup (Ambil di Kasir)';
  }

  String _getTableNumber() {
    if (_order.tableNumber != null && _order.tableNumber!.isNotEmpty) {
      return "Meja ${_order.tableNumber}";
    }
    if (_order.shippingAddress != null &&
        _order.shippingAddress!.startsWith('Dine In - Meja')) {
      return _order.shippingAddress!.replaceFirst('Dine In - ', '');
    }
    return '';
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(18) : Radius.zero,
          bottom: isLast ? const Radius.circular(18) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 10.5, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16);

  Widget _buildItemsCard() {
    final items = _order.items ?? [];

    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.shopping_bag_rounded,
                      color: AppColors.primaryGreen, size: 15),
                ),
                const SizedBox(width: 9),
                Text("Item Pesanan",
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A))),
                const Spacer(),
                Text("${items.length} item",
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Tidak ada detail item.",
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: Colors.grey.shade400)),
            )
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.product?.imageUrl != null &&
                                  item.product!.imageUrl!.isNotEmpty
                              ? Image.network(
                                  item.product!.imageUrl!,
                                  width: 46, height: 46,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _productPlaceholder(),
                                )
                              : _productPlaceholder(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "${item.quantity}x",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatPrice(item.price),
                                    style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatPrice(item.price * item.quantity),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        color: Colors.grey.shade100,
                        indent: 16,
                        endIndent: 16),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _productPlaceholder() => Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.local_cafe_rounded,
            size: 22, color: AppColors.primaryGreen.withOpacity(0.4)),
      );

  Widget _buildTotalCard() {
    final items = _order.items ?? [];
    final subtotal = items.fold(0.0, (s, i) => s + i.price * i.quantity);

    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Subtotal",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade500)),
                Text(_formatPrice(subtotal),
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A))),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 16,
              endIndent: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Bayar",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    )),
                Text(
                  _formatPrice(_order.totalAmount),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}