// lib/presentation/pages/checkout_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/datasources/cart_remote_datasource.dart';
import 'package:kopitiam_app/data/models/cart_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kopitiam_app/presentation/pages/order_history_page.dart';
import 'package:kopitiam_app/data/models/table_model.dart';
import 'package:kopitiam_app/data/datasources/table_remote_datasource.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {
  String _paymentMethod = 'cash_on_pickup';
  String _orderType = 'pickup'; // 'pickup' | 'dine-in'
  // --- TAMBAHAN BAGIAN MEJA ---
  List<TableModel> _tables = []; // Penampung list meja dari API
  String? _selectedTableNumber;  // Penampung pilihan user

  bool _isLoading = false;
  late Future<List<CartItem>> _cartItemsFuture;

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

    _fetchCartItems();
    _fetchTables();
  }

  // --- FUNGSI AMBIL DATA MEJA ---
  Future<void> _fetchTables() async {
    try {
      final tables = await TableRemoteDatasource().getTables();
      if (mounted) {
        setState(() {
          // Hanya ambil meja yang statusnya tersedia (isAvailable)
          _tables = tables.where((t) => t.isAvailable).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetch tables: $e");
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    
    super.dispose();
  }

  Future<void> _fetchCartItems() async {
    setState(() {
      _cartItemsFuture = CartRemoteDatasource().getCartItems();
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

  // ─── Proses Checkout ────────────────────────────
  void _processCheckout() async {
    // Validasi nomor meja menggunakan variabel _selectedTableNumber
    if (_orderType == 'dine-in' && _selectedTableNumber == null) {
    _showSnackBar("Silakan pilih nomor meja terlebih dahulu!", isError: true);
    return;
    }

    setState(() => _isLoading = true);

    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (!mounted) return;
      _showSnackBar("Anda belum login!", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
    final response = await dio.post(
      ApiConstants.checkout,
      data: {
        'shipping_address': _orderType == 'dine-in'
            ? 'Dine In - Meja $_selectedTableNumber' // GANTI INI
            : 'Pickup di Kopitiam33',
        'payment_method': _paymentMethod,
        'order_type': _orderType,
        'table_number': _orderType == 'dine-in'
            ? _selectedTableNumber // GANTI INI
            : null,
      },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        await _showSuccessDialog();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
        );
      } else {
        if (!mounted) return;
        _showSnackBar(
          "Checkout Gagal: ${response.data['message'] ?? 'Terjadi kesalahan.'}",
          isError: true,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnackBar(
        "Checkout Gagal: ${e.response?.data['message'] ?? e.message}",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    size: 40, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 16),
              Text("Pesanan Berhasil!",
                style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text(
                _orderType == 'dine-in'
                    ? "Pesananmu sedang disiapkan.\nSilakan tunggu di Meja $_selectedTableNumber."
                    : "Pesananmu sedang disiapkan.\nSilakan ambil di Kopitiam33.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500, height: 1.6),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.primaryGreen.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Lihat Pesanan",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<CartItem>>(
              future: _cartItemsFuture,
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

                final cartItems = snapshot.data!;
                double subtotal = 0;
                for (var item in cartItems) {
                  subtotal += item.product.price * item.quantity;
                }

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── RINGKASAN PESANAN ──
                                _buildSectionTitle(
                                  icon: Icons.receipt_long_rounded,
                                  title: "Ringkasan Pesanan",
                                  iconColor: Colors.orange.shade700,
                                ),
                                const SizedBox(height: 12),
                                _buildOrderSummaryCard(cartItems, subtotal),

                                const SizedBox(height: 20),

                                // ── METODE PENGAMBILAN ──
                                _buildSectionTitle(
                                  icon: Icons.store_rounded,
                                  title: "Metode Pengambilan",
                                  iconColor: Colors.teal,
                                ),
                                const SizedBox(height: 12),
                                _buildOrderTypeSection(),

                                const SizedBox(height: 20),

                                // ── METODE PEMBAYARAN ──
                                _buildSectionTitle(
                                  icon: Icons.payment_rounded,
                                  title: "Metode Pembayaran",
                                  iconColor: Colors.purple.shade400,
                                ),
                                const SizedBox(height: 12),
                                _buildPaymentCard(),

                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        // ── BOTTOM BAR ──
                        _buildBottomBar(subtotal),
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
                child: const Icon(Icons.shopping_bag_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Checkout",
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Konfirmasi pesananmu",
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
  // SECTION TITLE
  // ─────────────────────────────────────────────────
  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // ORDER SUMMARY CARD
  // ─────────────────────────────────────────────────
  Widget _buildOrderSummaryCard(List<CartItem> cartItems, double subtotal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // List item
          ...cartItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == cartItems.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Qty badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            "${item.quantity}x",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPrice(item.product.price * item.quantity),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade100,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }),

          // Total row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Bayar",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  _formatPrice(subtotal),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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

  // ─────────────────────────────────────────────────
  // ORDER TYPE SECTION (Pickup / Dine In)
  // ─────────────────────────────────────────────────
  Widget _buildOrderTypeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOrderTypeChip(
                label: "Pickup",
                sublabel: "Ambil di kasir",
                icon: Icons.shopping_bag_rounded,
                color: Colors.teal.shade600,
                isSelected: _orderType == 'pickup',
                onTap: () => setState(() {
                  _orderType = 'pickup';
                  _selectedTableNumber = null; // Reset pilihan meja
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOrderTypeChip(
                label: "Dine In",
                sublabel: "Makan di tempat",
                icon: Icons.restaurant_rounded,
                color: Colors.orange.shade600,
                isSelected: _orderType == 'dine-in',
                onTap: () => setState(() => _orderType = 'dine-in'),
              ),
            ),
          ],
        ),

        // ── Input Nomor Meja (animasi muncul/hilang) ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState: _orderType == 'dine-in'
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade300, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: _selectedTableNumber,
                  isExpanded: true,
                  hint: Text("Pilih Nomor Meja", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400)),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.orange.shade600),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.table_restaurant_rounded, color: Colors.orange.shade600, size: 20),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                  ),
                  items: _tables.map((table) {
                    return DropdownMenuItem<String>(
                      value: table.number,
                      child: Text("Meja Nomor ${table.number}", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTableNumber = value;
                    });
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Info strip sesuai pilihan ──
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: (_orderType == 'dine-in'
                    ? Colors.orange
                    : Colors.teal)
                .withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _orderType == 'dine-in'
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 15,
                color: _orderType == 'dine-in'
                    ? Colors.orange.shade600
                    : Colors.teal.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _orderType == 'dine-in'
                      ? "Pesanan akan diantarkan ke meja kamu oleh staf kami."
                      : "Pesananmu akan disiapkan dan bisa diambil di kasir.",
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: _orderType == 'dine-in'
                        ? Colors.orange.shade700
                        : Colors.teal.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTypeChip({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? color : Colors.grey.shade400,
                  size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    isSelected ? color : Colors.grey.shade600,
              ),
            ),
            Text(
              sublabel,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: isSelected
                    ? color.withOpacity(0.8)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // PICKUP CARD (kept for reference, replaced by _buildOrderTypeSection)
  // ─────────────────────────────────────────────────
  Widget _buildPickupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.storefront_rounded,
                color: Colors.teal.shade600, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ambil di Kafe (Pickup)",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Pesanan disiapkan untuk diambil\nlangsung di Kopitiam33",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                color: Colors.teal.shade600, size: 16),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // PAYMENT CARD
  // ─────────────────────────────────────────────────
  Widget _buildPaymentCard() {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = 'cash_on_pickup'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _paymentMethod == 'cash_on_pickup'
                ? AppColors.primaryGreen
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _paymentMethod == 'cash_on_pickup'
                  ? AppColors.primaryGreen.withOpacity(0.12)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.payments_rounded,
                  color: Colors.purple.shade400, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bayar di Kafe",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Tunai / QRIS langsung ke kasir\nsaat pengambilan pesanan",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _paymentMethod == 'cash_on_pickup'
                      ? AppColors.primaryGreen
                      : Colors.grey.shade300,
                  width: 2,
                ),
                color: _paymentMethod == 'cash_on_pickup'
                    ? AppColors.primaryGreen
                    : Colors.transparent,
              ),
              child: _paymentMethod == 'cash_on_pickup'
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────────
  Widget _buildBottomBar(double subtotal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                _formatPrice(subtotal),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _processCheckout,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey.shade400, Colors.grey.shade400]
                        : [
                            AppColors.primaryGreen,
                            AppColors.primaryGreen.withOpacity(0.8),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.38),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Konfirmasi Pesanan",
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
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // EMPTY & ERROR STATE
  // ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
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
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 38,
                  color: AppColors.primaryGreen.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Text(
              "Keranjang Kosong",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tidak ada item untuk di-checkout.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Kembali",
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
              onTap: _fetchCartItems,
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