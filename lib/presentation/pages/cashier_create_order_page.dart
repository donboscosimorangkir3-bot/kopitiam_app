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
  // Map<product_id, { "qty": int, "temp": String }>
  // "temp" hanya relevan untuk produk kategori minuman
  final Map<int, Map<String, dynamic>> _cart = {};

  // ── STATE FORM ORDER ──
  final _customerNameController = TextEditingController();
  final _tableNumberController = TextEditingController();
  String _orderType = 'dine-in';
  bool _isSubmitting = false;

  // ── KATEGORI YANG MEMILIKI PILIHAN HOT/COLD ──
  // Sesuaikan dengan nilai category di model Product kamu
  static const Set<String> _drinkCategories = {'minuman', 'beverage', 'drink', 'drinks'};

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

  // ── AMBIL PRODUK DARI BACKEND ──
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
        _showSnackBar("Gagal memuat produk. Periksa koneksi internet.", isError: true);
      }
    }
  }

  // ── PENCARIAN PRODUK ──
  void _onSearchChanged(String query) {
    setState(() {
      _filteredProducts = _allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // ── CEK APAKAH PRODUK ADALAH MINUMAN ──
  bool _isDrink(Product product) {
    // Sesuaikan field category dengan model Product kamu
    // Contoh: product.category atau product.categoryName
      final cat = (product.category?.name ?? '').toLowerCase().trim();
    return _drinkCategories.contains(cat);
  }

  // ── TAMBAH KE KERANJANG ──
  void _addToCart(Product product) {
    final id = product.id;
    final qty = (_cart[id]?['qty'] as int?) ?? 0;

    if (qty >= product.stock) {
      _showSnackBar("Sisa stok hanya ${product.stock}!", isError: true);
      return;
    }

    if (_isDrink(product) && qty == 0) {
      // Tampilkan dialog pilih suhu saat pertama kali ditambahkan
      _showTempDialog(product);
    } else {
      setState(() {
        _cart[id] = {
          'qty': qty + 1,
          'temp': _cart[id]?['temp'] ?? 'hot',
        };
      });
    }
  }

  // ── KURANGI DARI KERANJANG ──
  void _removeFromCart(int id) {
    final qty = (_cart[id]?['qty'] as int?) ?? 0;
    setState(() {
      if (qty <= 1) {
        _cart.remove(id);
      } else {
        _cart[id]!['qty'] = qty - 1;
      }
    });
  }

  // ── DIALOG PILIH HOT / COLD ──
  void _showTempDialog(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Pilih Suhu",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "${product.name}\nMau disajikan hangat atau dingin?",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          // COLD
          OutlinedButton.icon(
            icon: const Icon(Icons.ac_unit_rounded, color: Colors.blue),
            label: Text("Cold", style: GoogleFonts.poppins(color: Colors.blue)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _cart[product.id] = {'qty': 1, 'temp': 'cold'};
              });
            },
          ),
          // HOT
          ElevatedButton.icon(
            icon: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
            label: Text("Hot", style: GoogleFonts.poppins(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _cart[product.id] = {'qty': 1, 'temp': 'hot'};
              });
            },
          ),
        ],
      ),
    );
  }

  // ── HITUNG TOTAL HARGA ──
  double _getTotalPrice() {
    double total = 0;
    _cart.forEach((id, data) {
      try {
        final product = _allProducts.firstWhere((p) => p.id == id);
        total += product.price * (data['qty'] as int);
      } catch (_) {}
    });
    return total;
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  void _showSnackBar(String message, {bool isError = false, IconData icon = Icons.info_outline}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: GoogleFonts.poppins(fontSize: 12))),
        ]),
        backgroundColor: isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    setState(() => _isSubmitting = true);
    _showSnackBar("Memproses pesanan...", icon: Icons.hourglass_top_rounded);

    final List<Map<String, dynamic>> items = [];
    _cart.forEach((id, data) {
      items.add({
        "product_id": id,
        "quantity": data['qty'],
        "note": data['temp'] ?? '',  // "hot" atau "cold"
      });
    });

    final Map<String, dynamic> orderData = {
      "customer_name": _customerNameController.text.trim(),
      "order_type": _orderType,
      "table_number": _orderType == 'dine-in' ? _tableNumberController.text.trim() : null,
      "items": items,
    };

    final success = await OrderRemoteDatasource().createManualOrder(orderData);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSnackBar("Pesanan berhasil dibuat!", icon: Icons.check_circle_outline);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      _showSnackBar("Gagal membuat pesanan, periksa koneksi/stok.", isError: true);
    }
  }

  // ── BUILD UTAMA ──
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
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(_filteredProducts[index]);
                        },
                      ),
          ),

          // ── PANEL BAWAH (CHECKOUT) ──
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
    final bool isDrink = _isDrink(product);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // ── GAMBAR PRODUK ──
          _buildProductImage(product),
          const SizedBox(width: 14),

          // ── INFO PRODUK ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? Colors.grey.shade500 : const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPrice(product.price.toDouble()),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isOutOfStock ? Colors.grey.shade400 : AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Badge Hot/Cold jika sudah dipilih
                if (qty > 0 && isDrink && temp.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: temp == 'hot'
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: temp == 'hot' ? Colors.orange.shade300 : Colors.blue.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            temp == 'hot'
                                ? Icons.local_fire_department_rounded
                                : Icons.ac_unit_rounded,
                            size: 12,
                            color: temp == 'hot' ? Colors.orange.shade700 : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            temp == 'hot' ? "Hot" : "Cold",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: temp == 'hot' ? Colors.orange.shade700 : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

          // ── TOMBOL QTY ──
          if (!isOutOfStock) _buildQtyControls(product, qty),
        ],
      ),
    );
  }

  // ── WIDGET GAMBAR PRODUK (dengan fallback robust) ──
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
      child: Icon(
        Icons.fastfood_rounded,
        color: AppColors.primaryGreen.withOpacity(0.5),
        size: 30,
      ),
    );
  }

  // ── TOMBOL MINUS / PLUS ──
  Widget _buildQtyControls(Product product, int qty) {
    return Row(
      children: [
        if (qty > 0)
          GestureDetector(
            onTap: () => _removeFromCart(product.id),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.remove, size: 16, color: Colors.red.shade600),
            ),
          ),
        if (qty > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "$qty",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        GestureDetector(
          onTap: () => _addToCart(product),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ── PANEL CHECKOUT ──
  Widget _buildCheckoutPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
            // Input nama pelanggan
            TextField(
              controller: _customerNameController,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Nama Pelanggan / Tamu",
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown tipe order + input nomor meja
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _orderType,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'dine-in', child: Text("Dine In (Makan Sini)")),
                      DropdownMenuItem(value: 'pickup', child: Text("Pickup (Bungkus)")),
                    ],
                    onChanged: (val) => setState(() => _orderType = val!),
                  ),
                ),
                if (_orderType == 'dine-in') const SizedBox(width: 12),
                if (_orderType == 'dine-in')
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _tableNumberController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "No. Meja",
                        hintStyle: GoogleFonts.poppins(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
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
                      "Total Tagihan",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Text(
                      _formatPrice(_getTotalPrice()),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

  // ── EMPTY STATE ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Produk tidak ditemukan",
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}