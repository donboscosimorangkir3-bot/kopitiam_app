// lib/presentation/pages/cashier_create_order_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/order_remote_datasource.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:kopitiam_app/data/datasources/product_remote_datasource.dart';

class CashierCreateOrderPage extends StatefulWidget {
  const CashierCreateOrderPage({super.key});

  @override
  State<CashierCreateOrderPage> createState() => _CashierCreateOrderPageState();
}

class _CashierCreateOrderPageState extends State<CashierCreateOrderPage> {
  // ── STATE PRODUK ──
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isFetchingProducts = true;

  // ── STATE KERANJANG ──
  // Map<product_id, { "qty": int, "temp": String, "price": double }>
  final Map<int, Map<String, dynamic>> _cart = {};

  // ── STATE FORM ORDER ──
  final _customerNameController = TextEditingController();
  final _tableNumberController = TextEditingController();
  String _orderType = 'dine-in';
  bool _isSubmitting = false;

  // ── KATEGORI YANG MEMILIKI PILIHAN HOT/COLD ──
  static const Set<String> _drinkCategories = {
    'minuman', 'beverage', 'drink', 'drinks', 'coffee', 'kopi', 'juice', 'jus'
  };

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _tableNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isFetchingProducts = true);
    try {
      final fetched = await ProductRemoteDatasource().getProducts();
      if (mounted) {
        setState(() {
          _allProducts = fetched;
          _filteredProducts = fetched;
          _isFetchingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingProducts = false);
        _showSnackBar("Gagal memuat produk.", isError: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredProducts = _allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  bool _isDrink(Product product) {
    final cat = (product.category?.name ?? '').toLowerCase().trim();
    return _drinkCategories.contains(cat);
  }

  // ── HARGA EFEKTIF BERDASARKAN SUHU ──
  double _effectivePrice(Product product, String temp) {
    if (temp == 'cold' && product.priceCold != null) {
      return product.priceCold!;
    }
    return product.price;
  }

  // ── HITUNG TOTAL HARGA ──
  double _getTotalPrice() {
    double total = 0;
    _cart.forEach((id, data) {
      total += (data['price'] as double) * (data['qty'] as int);
    });
    return total;
  }

  // ── JUMLAH TOTAL ITEM DI KERANJANG ──
  int _getTotalItems() {
    int total = 0;
    _cart.forEach((_, data) => total += data['qty'] as int);
    return total;
  }

  String _formatPrice(double price) => NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);

  void _showSnackBar(String message,
      {bool isError = false, IconData icon = Icons.info_outline}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontSize: 12))),
        ]),
        backgroundColor: isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  // ════════════════════════════════════════════════
  // BOTTOM SHEET DETAIL PRODUK (mirip customer)
  // ════════════════════════════════════════════════
  void _showProductDetail(Product product) {
    final bool hasColdPrice = product.priceCold != null;
    final isDrink = _isDrink(product);

    // Ambil state keranjang saat ini untuk produk ini
    final existing = _cart[product.id];
    int qty = (existing?['qty'] as int?) ?? 1;
    String selectedTemp = (existing?['temp'] as String?) ??
        (hasColdPrice ? 'hot' : '');
    double selectedPrice =
        (existing?['price'] as double?) ?? product.price;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void selectTemp(String temp) {
              setModalState(() {
                selectedTemp = temp;
                selectedPrice = _effectivePrice(product, temp);
              });
            }

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F2EA),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── GAMBAR PRODUK ──
                          if (product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                product.imageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _detailImageFallback(),
                              ),
                            )
                          else
                            _detailImageFallback(),

                          const SizedBox(height: 16),

                          // ── NAMA & HARGA ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatPrice(selectedPrice),
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  if (selectedTemp.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 3),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: selectedTemp == 'hot'
                                            ? Colors.orange.withOpacity(0.12)
                                            : Colors.blue.withOpacity(0.10),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        selectedTemp == 'hot'
                                            ? '☕ Panas'
                                            : '🧊 Dingin',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: selectedTemp == 'hot'
                                              ? Colors.orange.shade700
                                              : Colors.blue.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Stok badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.stock <= 5
                                  ? Colors.orange.withOpacity(0.1)
                                  : AppColors.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Stok: ${product.stock}",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: product.stock <= 5
                                    ? Colors.orange.shade700
                                    : AppColors.primaryGreen,
                              ),
                            ),
                          ),

                          // ── DESKRIPSI ──
                          if (product.description != null &&
                              product.description!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                product.description!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],

                          // ── PILIH SUHU (jika ada harga dingin) ──
                          if (hasColdPrice) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                            Icons.thermostat_rounded,
                                            size: 14,
                                            color: Colors.orange.shade700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Pilih Suhu",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTempOption(
                                          variant: 'hot',
                                          label: 'Hot',
                                          emoji: '☕',
                                          price: product.price,
                                          accentColor: Colors.orange.shade700,
                                          isSelected: selectedTemp == 'hot',
                                          onTap: () => selectTemp('hot'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildTempOption(
                                          variant: 'cold',
                                          label: 'Cold',
                                          emoji: '🧊',
                                          price: product.priceCold!,
                                          accentColor: Colors.blue.shade600,
                                          isSelected: selectedTemp == 'cold',
                                          onTap: () => selectTemp('cold'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ── JUMLAH ──
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                      Icons.production_quantity_limits_rounded,
                                      size: 14,
                                      color: Colors.purple.shade400),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Jumlah",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                const Spacer(),
                                // Tombol minus
                                GestureDetector(
                                  onTap: () {
                                    if (qty > 1) {
                                      setModalState(() => qty--);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: qty > 1
                                          ? AppColors.primaryGreen
                                          : AppColors.primaryGreen
                                              .withOpacity(0.25),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.remove_rounded,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    "$qty",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                                // Tombol plus
                                GestureDetector(
                                  onTap: () {
                                    if (qty < product.stock) {
                                      setModalState(() => qty++);
                                    } else {
                                      _showSnackBar(
                                          "Stok hanya ${product.stock}!",
                                          isError: true);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: qty < product.stock
                                          ? AppColors.primaryGreen
                                          : AppColors.primaryGreen
                                              .withOpacity(0.25),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.add_rounded,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── TOMBOL TAMBAH KE PESANAN ──
                          Row(
                            children: [
                              // Tombol hapus dari keranjang (jika sudah ada)
                              if (_cart.containsKey(product.id)) ...[
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _cart.remove(product.id));
                                    Navigator.pop(ctx);
                                    _showSnackBar(
                                        "${product.name} dihapus dari pesanan",
                                        icon: Icons.delete_outline);
                                  },
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.red.withOpacity(0.3)),
                                    ),
                                    child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // Validasi suhu jika produk punya harga dingin
                                    if (hasColdPrice &&
                                        selectedTemp.isEmpty) {
                                      _showSnackBar(
                                          "Pilih suhu terlebih dahulu!",
                                          isError: true);
                                      return;
                                    }

                                    setState(() {
                                      _cart[product.id] = {
                                        'qty': qty,
                                        'temp': selectedTemp,
                                        // ✅ simpan harga efektif
                                        'price': selectedPrice,
                                        'name': product.name,
                                      };
                                    });

                                    Navigator.pop(ctx);
                                    _showSnackBar(
                                      "$qty× ${product.name}${selectedTemp.isNotEmpty ? ' (${selectedTemp == 'hot' ? 'Hot' : 'Cold'})' : ''} ditambahkan",
                                      icon: Icons.check_circle_outline,
                                    );
                                  },
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryGreen,
                                          AppColors.primaryGreen
                                              .withOpacity(0.85),
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                              Icons.add_shopping_cart_rounded,
                                              color: Colors.white,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            _cart.containsKey(product.id)
                                                ? "Perbarui Pesanan  •  ${_formatPrice(selectedPrice * qty)}"
                                                : "Tambah ke Pesanan  •  ${_formatPrice(selectedPrice * qty)}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailImageFallback() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.fastfood_rounded,
          size: 60, color: AppColors.primaryGreen.withOpacity(0.3)),
    );
  }

  Widget _buildTempOption({
    required String variant,
    required String label,
    required String emoji,
    required double price,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? accentColor : Colors.black87,
                  ),
                ),
                Text(
                  _formatPrice(price),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isSelected ? accentColor : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  // ── PROSES SUBMIT PESANAN ──
  Future<void> _processManualOrder() async {
    if (_cart.isEmpty) {
      _showSnackBar("Pilih minimal 1 produk!", isError: true);
      return;
    }
    if (_customerNameController.text.trim().isEmpty) {
      _showSnackBar("Nama pelanggan harus diisi!", isError: true);
      return;
    }
    if (_orderType == 'dine-in' &&
        _tableNumberController.text.trim().isEmpty) {
      _showSnackBar("Nomor meja harus diisi untuk Dine In!", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final List<Map<String, dynamic>> items = [];
    _cart.forEach((id, data) {
      items.add({
        "product_id": id,
        "quantity": data['qty'],
        "temperature": data['temp'] ?? '',
        "note": data['temp'] ?? '',
      });
    });

    final Map<String, dynamic> orderData = {
      "customer_name": _customerNameController.text.trim(),
      "order_type": _orderType,
      "table_number":
          _orderType == 'dine-in' ? _tableNumberController.text.trim() : null,
      "items": items,
    };

    final success =
        await OrderRemoteDatasource().createManualOrder(orderData);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSnackBar("Pesanan berhasil dibuat!",
          icon: Icons.check_circle_outline);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      _showSnackBar("Gagal membuat pesanan, periksa koneksi/stok.",
          isError: true);
    }
  }

  // ═══════════════════════════════════════════════
  // BUILD UTAMA
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      appBar: AppBar(
        title: Text(
          "Buat Pesanan Manual",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Cari menu...",
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.primaryGreen),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── LIST PRODUK ──
          Expanded(
            child: _isFetchingProducts
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGreen))
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(
                              _filteredProducts[index]);
                        },
                      ),
          ),

          // ── PANEL BAWAH ──
          _buildCheckoutPanel(),
        ],
      ),
    );
  }

  // ── KARTU PRODUK ──
  Widget _buildProductCard(Product product) {
    final id = product.id;
    final cartData = _cart[id];
    final qty = (cartData?['qty'] as int?) ?? 0;
    final temp = (cartData?['temp'] as String?) ?? '';
    final bool isOutOfStock = product.stock <= 0;
    final bool hasColdPrice = product.priceCold != null;

    return GestureDetector(
      // ✅ Klik produk → buka bottom sheet detail
      onTap: isOutOfStock ? null : () => _showProductDetail(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOutOfStock
              ? Colors.grey.shade100
              : qty > 0
                  ? AppColors.primaryGreen.withOpacity(0.04)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: qty > 0
                ? AppColors.primaryGreen.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // ── GAMBAR ──
            Stack(
              children: [
                _buildProductImage(product),
                // Badge qty di atas gambar
                if (qty > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          "$qty",
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // ── INFO ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isOutOfStock
                          ? Colors.grey.shade500
                          : const Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // ✅ Tampilkan range harga jika ada harga dingin
                  Text(
                    hasColdPrice
                        ? "${_formatPrice(product.price)} – ${_formatPrice(product.priceCold!)}"
                        : _formatPrice(product.price),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: isOutOfStock
                          ? Colors.grey.shade400
                          : AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Badge suhu terpilih
                  if (qty > 0 && temp.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: temp == 'hot'
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: temp == 'hot'
                                  ? Colors.orange.shade300
                                  : Colors.blue.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                temp == 'hot'
                                    ? Icons.local_fire_department_rounded
                                    : Icons.ac_unit_rounded,
                                size: 10,
                                color: temp == 'hot'
                                    ? Colors.orange.shade700
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                temp == 'hot' ? "Hot" : "Cold",
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: temp == 'hot'
                                      ? Colors.orange.shade700
                                      : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatPrice(
                              (cartData?['price'] as double?) ??
                                  product.price),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                  if (isOutOfStock)
                    Text(
                      "Stok Habis",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            // ── TOMBOL / HINT ──
            if (isOutOfStock)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Habis",
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade500)),
              )
            else if (qty > 0)
              // Sudah di keranjang → tampilkan tombol edit
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        size: 12, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      "Ubah",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Belum di keranjang → tombol tambah
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    size: 18, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    final url = product.imageUrl ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: 65,
              height: 65,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _imagePlaceholder();
              },
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            )
          : _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.fastfood_rounded,
          color: AppColors.primaryGreen.withOpacity(0.5), size: 30),
    );
  }

  // ── PANEL CHECKOUT ──
  Widget _buildCheckoutPanel() {
    final totalItems = _getTotalItems();
    final totalPrice = _getTotalPrice();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ringkasan item terpilih (jika ada)
            if (_cart.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    ..._cart.entries.map((entry) {
                      final product = _allProducts
                          .firstWhere((p) => p.id == entry.key,
                              orElse: () => _allProducts.first);
                      final data = entry.value;
                      final temp = data['temp'] as String? ?? '';
                      final price = data['price'] as double;
                      final qty = data['qty'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${qty}x",
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${product.name}${temp.isNotEmpty ? ' (${temp == 'hot' ? 'Hot' : 'Cold'})' : ''}",
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF1A1A1A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatPrice(price * qty),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Input nama pelanggan
            TextField(
              controller: _customerNameController,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Nama Pelanggan / Tamu",
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon:
                    const Icon(Icons.person_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown tipe order + nomor meja
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _orderType,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.black87),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'dine-in',
                          child: Text("Dine In (Makan Sini)")),
                      DropdownMenuItem(
                          value: 'pickup',
                          child: Text("Pickup (Bungkus)")),
                    ],
                    onChanged: (val) =>
                        setState(() => _orderType = val!),
                  ),
                ),
                if (_orderType == 'dine-in') ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _tableNumberController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "No. Meja",
                        hintStyle: GoogleFonts.poppins(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Total + tombol proses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalItems > 0
                          ? "Total ($totalItems item)"
                          : "Total Tagihan",
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Text(
                      _formatPrice(totalPrice),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _processManualOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Proses Pesanan",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Produk tidak ditemukan",
            style: GoogleFonts.poppins(
                color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}