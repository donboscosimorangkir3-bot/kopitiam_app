// lib/presentation/pages/cashier_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/datasources/order_remote_datasource.dart';
import 'package:kopitiam_app/data/models/order_model.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/cashier_create_order_page.dart';

class CashierDashboardPage extends StatefulWidget {
  final User user;
  const CashierDashboardPage({super.key, required this.user});

  @override
  State<CashierDashboardPage> createState() => _CashierDashboardPageState();
}

class _CashierDashboardPageState extends State<CashierDashboardPage>
    with SingleTickerProviderStateMixin {
  List<Order> _allOrders =[];
  bool _isLoading = true;
  String _filterStatus = 'pending';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // STATUS DIUPDATE: Menghapus 'paid' (karena itu payment_status), Menambahkan 'ready'
  final List<Map<String, dynamic>> _statusOptions =[
    {'value': 'pending',    'label': 'Belum Bayar', 'icon': Icons.payments_outlined},
    {'value': 'processing', 'label': 'Diproses',    'icon': Icons.soup_kitchen_rounded},
    {'value': 'ready',      'label': 'Siap',        'icon': Icons.room_service_rounded},
    {'value': 'completed',  'label': 'Selesai',     'icon': Icons.task_alt_rounded},
    {'value': 'cancelled',  'label': 'Batal',       'icon': Icons.cancel_outlined},
    {'value': 'all',        'label': 'Semua',       'icon': Icons.list_alt_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _fetchAllOrders();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllOrders() async {
    setState(() => _isLoading = true);
    final fetched = await OrderRemoteDatasource().getAllOrders();
    if (!mounted) return;
    setState(() {
      _allOrders = fetched;
      _isLoading = false;
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
    return DateFormat('dd MMM • HH:mm').format(date);
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 11) return "Selamat Pagi";
    if (h < 15) return "Selamat Siang";
    if (h < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  // ── Status helpers ──────────────────────────────
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':    return Colors.orange.shade600;
      case 'processing': return Colors.blue.shade600;
      case 'ready':      return Colors.teal.shade500;
      case 'completed':  return AppColors.primaryGreen;
      case 'cancelled':  return Colors.red.shade500;
      default:           return Colors.grey.shade500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':    return Icons.payments_outlined;
      case 'processing': return Icons.soup_kitchen_rounded;
      case 'ready':      return Icons.room_service_rounded;
      case 'completed':  return Icons.task_alt_rounded;
      case 'cancelled':  return Icons.cancel_outlined;
      default:           return Icons.info_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':    return 'Belum Bayar';
      case 'processing': return 'Diproses Dapur';
      case 'ready':      return 'Siap Diambil';
      case 'completed':  return 'Selesai';
      case 'cancelled':  return 'Dibatalkan';
      default:           return status;
    }
  }

  // ── Statistik ringkas ───────────────────────────
  int _countByStatus(String status) =>
      _allOrders.where((o) => o.status == status).length;

  // Karena "paid" sudah dihilangkan dari order_status, 
  // maka order yang mendatangkan uang adalah processing, ready, dan completed.
  double _totalRevenue() => _allOrders
      .where((o) => o.status == 'processing' || o.status == 'ready' || o.status == 'completed')
      .fold(0, (sum, o) => sum + o.totalAmount);

  // ── Fungsi Proses Aksi Tombol ────────────────────────
  Future<void> _processAction(Order order, String newStatus, String title, String subtitle, IconData icon) async {
    if (!mounted) return;

    final confirmed = await _showActionDialog(title, subtitle, _getStatusColor(newStatus), icon);
    if (confirmed != true) return;

    _showSnackBar("Memproses pesanan ${order.orderNumber}...", icon: Icons.hourglass_top_rounded);

    // TODO: Pastikan di backend (OrderRemoteDatasource), 
    // jika newStatus = 'processing', backend otomatis mengubah payment_status menjadi 'paid'.
    final success = await OrderRemoteDatasource().updateOrderStatus(order.id, newStatus);

    if (!mounted) return;
    if (success) {
      _showSnackBar(
        "Pesanan berhasil diupdate!",
        icon: Icons.check_circle_outline_rounded,
      );
      // Agar listnya tetap rapi, jika berhasil ubah filter ke status baru
      setState(() => _filterStatus = newStatus == 'cancelled' ? _filterStatus : newStatus);
      _fetchAllOrders();
    } else {
      _showSnackBar(
        "Gagal memproses. Coba lagi.",
        isError: true,
        icon: Icons.error_outline_rounded,
      );
      _fetchAllOrders();
    }
  }

  Future<bool?> _showActionDialog(String title, String subtitle, Color color, IconData icon) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children:[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text("Batal",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text("Konfirmasi",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
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

  void _showSnackBar(String message,
      {bool isError = false, IconData icon = Icons.info_outline_rounded}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children:[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message,
                    style: GoogleFonts.poppins(fontSize: 12.5))),
          ],
        ),
        backgroundColor:
            isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 2),
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

    final filteredOrders = _filterStatus == 'all'
        ? _allOrders
        : _allOrders.where((o) => o.status == _filterStatus).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      // --- TAMBAHKAN KODE INI ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CashierCreateOrderPage()),
          ).then((value) {
            if (value == true) {
              _fetchAllOrders(); // Refresh data otomatis setelah pesan manual dibuat
            }
          });
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: Text("Buat Pesanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllOrders,
        color: AppColors.primaryGreen,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers:[
            SliverToBoxAdapter(child: _buildHeader()),
            if (!_isLoading) SliverToBoxAdapter(child: _buildStatCards()),
            SliverToBoxAdapter(child: _buildFilterSection()),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : filteredOrders.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, index) => FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildOrderCard(filteredOrders[index]),
                            ),
                            childCount: filteredOrders.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // HEADER & STAT CARDS & FILTER (Sama seperti sebelumnya)
  // ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:[AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.82)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children:[
          Positioned(top: -20, right: -20, child: _circle(120, 0.07)),
          Positioned(top: 40, right: 70, child: _circle(50, 0.08)),
          Positioned(bottom: -10, left: -30, child: _circle(80, 0.06)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Text("${_getGreeting()},", style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.78))),
                        const SizedBox(height: 2),
                        Text(widget.user.name, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children:[
                              const Icon(Icons.badge_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 5),
                              Text(widget.user.role == 'admin' ? 'Admin' : 'Kasir', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await AuthRemoteDatasource().logout();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3))),
                      child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
      );

  Widget _buildStatCards() {
    final stats =[
      {'label': 'Belum Bayar', 'value': _countByStatus('pending').toString(), 'icon': Icons.payments_outlined, 'color': Colors.orange.shade600},
      {'label': 'Diproses', 'value': _countByStatus('processing').toString(), 'icon': Icons.soup_kitchen_rounded, 'color': Colors.blue.shade600},
      {'label': 'Siap', 'value': _countByStatus('ready').toString(), 'icon': Icons.room_service_rounded, 'color': Colors.teal.shade500},
      {'label': 'Pendapatan', 'value': _formatPrice(_totalRevenue()), 'icon': Icons.payments_rounded, 'color': AppColors.primaryGreen, 'isWide': true},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children:[
          Row(
            children: stats.take(3).map((s) {
              return Expanded(
                child: _buildStatCard(label: s['label'] as String, value: s['value'] as String, icon: s['icon'] as IconData, color: s['color'] as Color),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildStatCard(label: stats[3]['label'] as String, value: stats[3]['value'] as String, icon: stats[3]['icon'] as IconData, color: stats[3]['color'] as Color, isWide: true),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value, required IconData icon, required Color color, bool isWide = false}) {
    return Container(
      margin: isWide ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 10, vertical: isWide ? 14 : 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))]),
      child: isWide
          ? Row(
              children:[
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500)), Text(value, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: color))]),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text("Hari ini", style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: color))),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 16)),
                const SizedBox(height: 8),
                Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                Text(label, style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade500)),
              ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:[
              Text("Daftar Pesanan", style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const SizedBox(width: 8),
              if (!_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text("${(_filterStatus == 'all' ? _allOrders : _allOrders.where((o) => o.status == _filterStatus).toList()).length}", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              itemBuilder: (_, index) {
                final opt = _statusOptions[index];
                final val = opt['value'] as String;
                final isSelected = _filterStatus == val;
                final color = val == 'all' ? Colors.grey.shade600 : _getStatusColor(val);

                return GestureDetector(
                  onTap: () => setState(() => _filterStatus = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.2),
                      boxShadow: isSelected ?[BoxShadow(color: color.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 2))] :[],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:[
                        Icon(opt['icon'] as IconData, size: 13, color: isSelected ? Colors.white : Colors.grey.shade500),
                        const SizedBox(width: 5),
                        Text(opt['label'] as String, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade600)),
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
  // ORDER CARD DENGAN TOMBOL AKSI
  // ─────────────────────────────────────────────────
  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final paymentStatus = order.paymentStatus ?? 'unpaid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow:[
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children:[
          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children:[
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(order.orderNumber, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                      Row(
                        children:[
                          Text("👤 ${order.user?.name ?? 'N/A'}  •  ", style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500)),
                          // LOGIKA BADGE PEMBAYARAN:
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // Cek jika statusnya 'success' atau 'paid'
        color: (order.paymentStatus == 'success' || order.paymentStatus == 'paid')
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        (order.paymentStatus == 'success' || order.paymentStatus == 'paid')
            ? "LUNAS"
            : "BELUM LUNAS",
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: (order.paymentStatus == 'success' || order.paymentStatus == 'paid')
              ? Colors.green.shade700
              : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor)),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

          // ── ITEM LIST ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Column(
              children:[
                if (order.items != null && order.items!.isNotEmpty)
                  ...order.items!.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children:[
                            Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Center(child: Text("${item.quantity}x", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)))),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item.productName, style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF2D2D2D)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text(_formatPrice(item.price * item.quantity), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                          ],
                        ),
                      ))
                else
                  Text("Tidak ada detail item.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400)),

                if (order.items != null && order.items!.length > 3)
                  Align(alignment: Alignment.centerLeft, child: Text("+ ${order.items!.length - 3} item lainnya", style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade400, fontStyle: FontStyle.italic))),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

          // ── FOOTER DENGAN TOMBOL AKSI ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children:[
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text("Total Tagihan", style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade500)),
                      Text(_formatPrice(order.totalAmount), style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                    ],
                  ),
                ),
                
                // TOMBOL AKSI BERDASARKAN STATUS
                Expanded(
                  flex: 3,
                  child: _buildActionButtons(order),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    // Jika pesanan sudah Selesai atau Dibatalkan, tidak ada tombol
    if (order.status == 'completed' || order.status == 'cancelled') {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          order.status == 'completed' ? "Pesanan Selesai" : "Pesanan Dibatalkan",
          style: GoogleFonts.poppins(
            fontSize: 12, 
            fontWeight: FontWeight.w600, 
            color: Colors.grey.shade400,
            fontStyle: FontStyle.italic
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children:[
        // Tombol Batal (Tampil saat Pending atau Processing saja)
        if (order.status == 'pending' || order.status == 'processing')
          GestureDetector(
            onTap: () => _processAction(
              order, 
              'cancelled', 
              'Batalkan Pesanan?', 
              'Tindakan ini tidak dapat diurungkan.', 
              Icons.warning_amber_rounded
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Batal",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ),
        
        if (order.status == 'pending' || order.status == 'processing')
          const SizedBox(width: 8),

        // Tombol Utama (Berdasarkan Status)
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (order.status == 'pending') {
                _processAction(order, 'processing', 'Konfirmasi Pembayaran?', 'Terima pembayaran Rp ${_formatPrice(order.totalAmount).split('Rp ')[1]} dan teruskan pesanan ke dapur?', Icons.payments_rounded);
              } else if (order.status == 'processing') {
                _processAction(order, 'ready', 'Pesanan Siap?', 'Tandai pesanan ini sudah selesai dimasak dan siap?', Icons.room_service_rounded);
              } else if (order.status == 'ready') {
                _processAction(order, 'completed', 'Selesaikan Pesanan?', 'Pesanan sudah diserahkan ke pelanggan?', Icons.task_alt_rounded);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _getMainButtonColor(order.status),
                borderRadius: BorderRadius.circular(10),
                boxShadow:[
                  BoxShadow(
                    color: _getMainButtonColor(order.status).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              ),
              child: Center(
                child: Text(
                  _getMainButtonText(order.status),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getMainButtonText(String status) {
    if (status == 'pending') return 'Terima Bayaran';
    if (status == 'processing') return 'Pesanan Siap';
    if (status == 'ready') return 'Selesaikan';
    return '';
  }

  Color _getMainButtonColor(String status) {
    if (status == 'pending') return AppColors.primaryGreen;
    if (status == 'processing') return Colors.blue.shade600;
    if (status == 'ready') return Colors.teal.shade600;
    return Colors.grey;
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
          children:[
            Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.inbox_rounded, size: 38, color: AppColors.primaryGreen.withOpacity(0.5))),
            const SizedBox(height: 16),
            Text("Tidak Ada Pesanan", style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text("Belum ada pesanan dengan\nstatus \"${_getStatusLabel(_filterStatus)}\".", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500, height: 1.6)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchAllOrders,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children:[const Icon(Icons.refresh_rounded, color: Colors.white, size: 16), const SizedBox(width: 6), Text("Refresh", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}