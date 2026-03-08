// lib/presentation/pages/cashier_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/datasources/order_remote_datasource.dart';
import 'package:kopitiam_app/data/models/order_model.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/core/api_constants.dart';


class CashierDashboardPage extends StatefulWidget {
  final User user;

  const CashierDashboardPage({super.key, required this.user});

  @override
  State<CashierDashboardPage> createState() => _CashierDashboardPageState();
}

class _CashierDashboardPageState extends State<CashierDashboardPage> {
  Future<List<Order>>? _allOrdersFuture;
  String _filterStatus = 'pending';

  final List<String> _statusOptions = [
    'pending',
    'paid',
    'processing',
    'shipping',
    'completed',
    'cancelled',
    'all'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllOrders();
  }

  Future<void> _fetchAllOrders() async {
    final orders = await OrderRemoteDatasource().getAllOrders();
    setState(() {
      _allOrdersFuture = Future.value(orders);
    });
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
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
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

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    final success = await OrderRemoteDatasource()
        .updateOrderStatus(order.id, newStatus);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Status pesanan ${order.orderNumber} berhasil diupdate ke ${newStatus.toUpperCase()}"),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      setState(() {
        _filterStatus = newStatus;
      });

      _fetchAllOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengupdate status pesanan."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: Text(
          "Dashboard Admin",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthRemoteDatasource().logout();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Halo, ${widget.user.name}!",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Anda login sebagai ${widget.user.role}.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.greyText,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Daftar Pesanan",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// FILTER STATUS
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statusOptions.length,
                      itemBuilder: (context, index) {
                        final status = _statusOptions[index];

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status.toUpperCase()),
                            selected: _filterStatus == status,
                            selectedColor: AppColors.primaryGreen,
                            labelStyle: GoogleFonts.poppins(
                              color: _filterStatus == status
                                  ? Colors.white
                                  : AppColors.darkBrown,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _filterStatus = status;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            /// ORDER LIST
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchAllOrders,
                child: FutureBuilder<List<Order>>(
                  future: _allOrdersFuture,
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: Text("Tidak ada data"));
                    }

                    final filteredOrders = snapshot.data!
                        .where((o) =>
                            _filterStatus == 'all' ||
                            o.status == _filterStatus)
                        .toList();

                    if (filteredOrders.isEmpty) {
                      return const Center(
                        child: Text("Tidak ada pesanan"),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(filteredOrders[index]);
                      },
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  avatar: Icon(
                    _getStatusIcon(order.status),
                    size: 16,
                    color: _getStatusColor(order.status),
                  ),
                  label: Text(order.status.toUpperCase()),
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  backgroundColor:
                      _getStatusColor(order.status).withOpacity(0.15),
                )
              ],
            ),

            const Divider(height: 20),

            /// CUSTOMER
            Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 6),
                Text(
                  "Pelanggan: ${order.user?.name ?? "-"}",
                  style: GoogleFonts.poppins(),
                )
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatDate(order.createdAt),
                  style: GoogleFonts.poppins(fontSize: 13),
                )
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "Total: ${_formatPrice(order.totalAmount)}",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),

            const SizedBox(height: 14),

            /// ITEMS
            if (order.items != null)
              ...order.items!.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [

                      /// IMAGE
                      ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            // <-- Perubahan di sini -->
                            item.product?.imageUrl != null && item.product!.imageUrl!.startsWith('http')
                                ? item.product!.imageUrl!
                                : (item.product?.imageUrl != null && item.product!.imageUrl!.isNotEmpty
                                    ? '${ApiConstants.baseUrl}${item.product!.imageUrl!}'
                                    : 'https://via.placeholder.com/50'),
                            // <-- Akhir perubahan di sini -->
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.coffee, size: 24, color: AppColors.greyText);
                            },
                          ),
                        ),

                      /// NAME
                      Expanded(
                        child: Text(
                          "${item.quantity}x ${item.productName}",
                          style: GoogleFonts.poppins(),
                        ),
                      ),

                      /// PRICE
                      Text(
                        _formatPrice(item.price * item.quantity),
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            /// UPDATE STATUS
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.edit, color: AppColors.primaryGreen),
                onSelected: (value) => _updateOrderStatus(order, value),
                itemBuilder: (context) => [
                  _statusMenu("pending"),
                  _statusMenu("paid"),
                  _statusMenu("processing"),
                  _statusMenu("shipping"),
                  _statusMenu("completed"),
                  _statusMenu("cancelled"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _statusMenu(String status) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
          ),
          const SizedBox(width: 10),
          Text(status.toUpperCase(), style: GoogleFonts.poppins()),
        ],
      ),
    );
  }
}