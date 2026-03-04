// lib/presentation/pages/order_history_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/order_remote_datasource.dart';
import 'package:kopitiam_app/data/models/order_model.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    _ordersFuture = OrderRemoteDatasource().getMyOrders();
    setState(() {}); // Untuk refresh UI
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'paid':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.hourglass_empty;
      case 'shipping':
        return Icons.local_shipping;
      case 'completed':
        return Icons.assignment_turned_in;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Riwayat Pesanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: AppColors.darkBrown)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_toggle_off, size: 80, color: AppColors.greyText),
                  const SizedBox(height: 16),
                  Text(
                    "Anda belum memiliki riwayat pesanan.",
                    style: GoogleFonts.poppins(fontSize: 18, color: AppColors.greyText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst); // Kembali ke Home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Mulai Pesan", style: GoogleFonts.poppins(fontSize: 16)),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
      ),
    );
  }

  // WIDGET KARTU PESANAN
  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(order.status), size: 16, color: _getStatusColor(order.status)),
                      const SizedBox(width: 4),
                      Text(
                        order.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(order.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              "Tanggal Pesan: ${_formatDate(order.createdAt)}",
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.greyText),
            ),
            const SizedBox(height: 8),
            Text(
              "Total: ${_formatPrice(order.totalAmount)}",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            // Detail Item Pesanan
            Text(
              "Detail Item:",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            if (order.items != null && order.items!.isNotEmpty)
              ...order.items!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Text("${item.quantity}x ${item.productName}", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
                        const Spacer(),
                        Text(_formatPrice(item.price * item.quantity), style: GoogleFonts.poppins(color: AppColors.darkBrown)),
                      ],
                    ),
                  ))
            else
              Text("Tidak ada detail item.", style: GoogleFonts.poppins(color: AppColors.greyText)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lihat detail lengkap Order #${order.orderNumber}")),
                  );
                  // TODO: Navigasi ke halaman detail pesanan lebih lanjut
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryGreen),
                label: Text("Lihat Detail", style: GoogleFonts.poppins(color: AppColors.primaryGreen)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}