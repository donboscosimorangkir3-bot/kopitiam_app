// lib/presentation/pages/cart_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/cart_remote_datasource.dart';
import 'package:kopitiam_app/data/models/cart_item_model.dart';
import 'package:kopitiam_app/presentation/pages/checkout_page.dart';
import 'package:kopitiam_app/core/api_constants.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  late Future<List<CartItem>> _cartItemsFuture;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Set<int> _selectedItemIds = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _resetSelection(List<CartItem> items) {
    setState(() {
      _selectedItemIds.clear();
      _selectAll = false;
    });
  }

  void _updateSelectAllStatus(List<CartItem> items) {
    if (items.isEmpty) {
      _selectAll = false;
      return;
    }
    final allSelected = items.every((item) => _selectedItemIds.contains(item.id));
    if (_selectAll != allSelected) {
      _selectAll = allSelected;
    }
  }

  void _toggleSelectItem(CartItem item) {
    setState(() {
      if (_selectedItemIds.contains(item.id)) {
        _selectedItemIds.remove(item.id);
      } else {
        _selectedItemIds.add(item.id);
      }
    });
  }

  void _toggleSelectAll(List<CartItem> items) {
    setState(() {
      if (_selectAll) {
        _selectedItemIds.clear();
        _selectAll = false;
      } else {
        _selectedItemIds = items.map((item) => item.id).toSet();
        _selectAll = true;
      }
    });
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

  void _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;

    if (newQuantity > item.product.stock) {
      if (!mounted) return;
      _showSnackBar(
        "Kuantitas melebihi stok tersedia!",
        isError: true,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => item.quantity = newQuantity);

    final success = await CartRemoteDatasource().updateCartItem(item.id, newQuantity);
    if (success) {
      _fetchCartItems();
    } else {
      if (!mounted) return;
      _showSnackBar(
        "Gagal memperbarui kuantitas. Coba login ulang.",
        isError: true,
        icon: Icons.error_outline_rounded,
      );
      _fetchCartItems();
    }
  }

  void _removeItem(CartItem item) async {
    final bool? confirm = await _showDeleteDialog(item.product.name);

    if (confirm == true) {
      final success = await CartRemoteDatasource().deleteCartItem(item.id);
      if (success) {
        if (!mounted) return;
        _showSnackBar(
          "${item.product.name} dihapus dari keranjang",
          icon: Icons.check_circle_outline_rounded,
        );
        setState(() {
          _selectedItemIds.remove(item.id);
        });
        _fetchCartItems();
      } else {
        if (!mounted) return;
        _showSnackBar(
          "Gagal menghapus item. Coba login ulang.",
          isError: true,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, required IconData icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
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

  Future<bool?> _showDeleteDialog(String productName) {
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                "Hapus Item?",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "\"$productName\" akan dihapus dari keranjang kamu.",
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
                        "Batal",
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
                        "Hapus",
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
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final cartItems = snapshot.data!;

                final validSelectedIds = _selectedItemIds
                    .where((id) => cartItems.any((item) => item.id == id))
                    .toSet();
                if (validSelectedIds.length != _selectedItemIds.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedItemIds.clear();
                      _selectedItemIds.addAll(validSelectedIds);
                      _updateSelectAllStatus(cartItems);
                    });
                  });
                } else {
                  _updateSelectAllStatus(cartItems);
                }

                // ✅ FIXED: pakai effectivePrice, bukan product.price
                double selectedTotal = 0;
                int selectedCount = 0;
                for (var item in cartItems) {
                  if (_selectedItemIds.contains(item.id)) {
                    selectedTotal += item.effectivePrice * item.quantity;
                    selectedCount += item.quantity;
                  }
                }

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleSelectAll(cartItems),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _selectAll
                                            ? AppColors.primaryGreen
                                            : Colors.white,
                                        border: Border.all(
                                          color: _selectAll
                                              ? AppColors.primaryGreen
                                              : Colors.grey.shade400,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _selectAll
                                          ? const Icon(Icons.check,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Pilih Semua (${cartItems.length} menu)",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  _fetchCartItems();
                                  setState(() {
                                    _selectedItemIds.clear();
                                    _selectAll = false;
                                  });
                                },
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
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              return _buildCartItemCard(
                                  cartItems[index], index);
                            },
                          ),
                        ),
                        _buildBottomBar(
                            selectedTotal, selectedCount, cartItems),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Keranjang",
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      "Kopitiam33",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, int index) {
    String resolveImageUrl(String? rawUrl) {
      if (rawUrl == null || rawUrl.trim().isEmpty) return '';
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        return rawUrl;
      }
      final base = ApiConstants.baseUrl.endsWith('/')
          ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
          : ApiConstants.baseUrl;
      final path = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
      return '$base$path';
    }

    final imageUrl = resolveImageUrl(item.product.imageUrl);
    final bool isSelected = _selectedItemIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _toggleSelectItem(item),
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 8, top: 28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen.withOpacity(0.4),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ✅ FIXED: tampilkan effectivePrice bukan product.price
                      Text(
                        _formatPrice(item.effectivePrice),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.temperature != null &&
                      item.temperature!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.temperature == 'hot'
                                ? Icons.local_fire_department_rounded
                                : Icons.ac_unit_rounded,
                            size: 12,
                            color: item.temperature == 'hot'
                                ? Colors.orange.shade600
                                : Colors.blue.shade400,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.temperature == 'hot' ? 'Hot' : 'Cold',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: item.temperature == 'hot'
                                  ? Colors.orange.shade600
                                  : Colors.blue.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildQtyBtn(
                        icon: Icons.remove_rounded,
                        onTap: () =>
                            _updateQuantity(item, item.quantity - 1),
                        enabled: item.quantity > 1,
                        isDestructive: false,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F2EA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                AppColors.primaryGreen.withOpacity(0.35),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.quantity.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildQtyBtn(
                        icon: Icons.add_rounded,
                        onTap: () =>
                            _updateQuantity(item, item.quantity + 1),
                        enabled: item.quantity < item.product.stock,
                        isDestructive: false,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _removeItem(item),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.coffee_rounded,
        size: 32,
        color: AppColors.primaryGreen.withOpacity(0.4),
      ),
    );
  }

  Widget _buildBottomBar(
      double selectedTotal, int selectedItemCount, List<CartItem> cartItems) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Pembayaran",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrice(selectedTotal),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$selectedItemCount item terpilih",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (selectedItemCount == 0) {
                _showSnackBar(
                  "Pilih minimal satu item untuk checkout",
                  isError: true,
                  icon: Icons.warning_amber_rounded,
                );
                return;
              }
              final List<CartItem> selectedItems = cartItems
                  .where((item) => _selectedItemIds.contains(item.id))
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CheckoutPage(selectedCartItems: selectedItems),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.primaryGreen.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Checkout Sekarang",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
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
    );
  }

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
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppColors.primaryGreen.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Keranjang Kosong",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Belum ada item di keranjangmu.\nYuk, pilih menu favoritmu!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
                      "Lihat Menu",
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

  Widget _buildErrorState(String error) {
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
              "Periksa koneksi internet kamu,\nlalu coba lagi.",
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
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

  Widget _buildQtyBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: !enabled
              ? Colors.grey.shade100
              : isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(9),
          boxShadow: enabled && !isDestructive
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 16,
          color: !enabled
              ? Colors.grey.shade400
              : isDestructive
                  ? Colors.redAccent
                  : Colors.white,
        ),
      ),
    );
  }
}