// lib/presentation/pages/order_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/order_remote_datasource.dart';
import 'package:kopitiam_app/data/models/order_model.dart';
import 'package:kopitiam_app/presentation/pages/order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Order>> _ordersFuture;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fetchOrders();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _ordersFuture = OrderRemoteDatasource().getMyOrders();
    });
    _animController.forward(from: 0);
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy • HH:mm').format(date);
  }

  // ── Status helpers ──────────────────────────────
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade600;
      case 'paid':
        return AppColors.primaryGreen;
      case 'processing':
        return Colors.blue.shade600;
      case 'shipping':
        return Colors.purple.shade500;
      case 'completed':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'paid':
        return Icons.check_circle_outline_rounded;
      case 'processing':
        return Icons.coffee_rounded;
      case 'shipping':
        return Icons.local_shipping_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'paid':
        return 'Dibayar';
      case 'processing':
        return 'Diproses';
      case 'shipping':
        return 'Dikirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status.toUpperCase();
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
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                      strokeWidth: 2.5,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _buildErrorState();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final orders = snapshot.data!;

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // Info jumlah pesanan + refresh
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 4),
                          child: Row(
                            children: [
                              Text(
                                "${orders.length} pesanan ditemukan",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _fetchOrders,
                                child: Row(
                                  children: [
                                    Icon(Icons.refresh_rounded,
                                        size: 15,
                                        color: AppColors.primaryGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Refresh",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(orders[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            AppColors.primaryGreen.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 16),
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
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Riwayat Pesanan",
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Semua pesananmu di Kopitiam33",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
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

  // ─────────────────────────────────────────────────
  // ORDER CARD
  // ─────────────────────────────────────────────────
  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final isCompleted = order.status == 'completed';
    final isCancelled = order.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER CARD ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
              ),
            ),
            child: Row(
              children: [
                // Status icon bulat
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        _formatDate(order.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── DIVIDER ──
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

          // ── ITEM LIST ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                if (order.items != null && order.items!.isNotEmpty)
                  ...order.items!.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: Text(
                                  "${item.quantity}x",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF2D2D2D),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatPrice(item.price * item.quantity),
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "Tidak ada detail item.",
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ),

                // Label "+N item lainnya" jika > 3
                if (order.items != null && order.items!.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "+ ${order.items!.length - 3} item lainnya",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── DIVIDER ──
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

          // ── FOOTER: TOTAL + TOMBOL ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Bayar",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
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

                const Spacer(),

                // Tombol detail
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(order: order),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Detail",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 11, color: AppColors.primaryGreen),
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

  // ─────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 46,
                color: AppColors.primaryGreen.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Belum Ada Pesanan",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Kamu belum pernah memesan.\nYuk, coba menu Kopitiam33!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.coffee_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Mulai Pesan",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // ERROR STATE
  // ─────────────────────────────────────────────────
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
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 38, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text(
              "Gagal Memuat",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Periksa koneksi internetmu\nlalu coba lagi.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchOrders,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Coba Lagi",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}