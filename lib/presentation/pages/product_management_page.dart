// lib/presentation/pages/product_management_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/product_remote_datasource.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:kopitiam_app/presentation/pages/product_form_page.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage>
    with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  bool _hasError = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchProducts();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await ProductRemoteDatasource().getProducts();
      if (!mounted) return;
      setState(() {
        _products = result;
        _applyFilter();
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_products)
        : _products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  String _formatPrice(double price) => NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);

  // ── Delete ──────────────────────────────────────
  Future<void> _deleteProduct(int id, String name) async {
    final confirmed = await _showDeleteDialog(name);
    if (confirmed != true) return;

    _showSnackBar("Menghapus \"$name\"...",
        icon: Icons.delete_outline_rounded);

    final success = await ProductRemoteDatasource().deleteProduct(id);
    if (!mounted) return;

    if (success) {
      _showSnackBar("\"$name\" berhasil dihapus",
          icon: Icons.check_circle_outline_rounded);
      _fetchProducts();
    } else {
      _showSnackBar("Gagal menghapus produk. Coba lagi.",
          isError: true, icon: Icons.error_outline_rounded);
    }
  }

  Future<bool?> _showDeleteDialog(String name) {
    return showDialog<bool>(
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 30),
              ),
              const SizedBox(height: 14),
              Text("Hapus Produk?",
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text(
                "\"$name\" akan dihapus secara permanen.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
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
                        backgroundColor: Colors.redAccent,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text("Hapus",
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

  Future<void> _navigateToForm({Product? product}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProductFormPage(product: product)),
    );
    _fetchProducts();
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
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchProducts,
              color: AppColors.primaryGreen,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                          strokeWidth: 2.5),
                    )
                  : _hasError
                      ? _buildErrorState()
                      : _filtered.isEmpty
                          ? _buildEmptyState()
                          : FadeTransition(
                              opacity: _fadeAnim,
                              child: Column(
                                children: [
                                  // Info bar
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 10, 20, 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          "${_filtered.length} produk",
                                          style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              color:
                                                  Colors.grey.shade500),
                                        ),
                                        const Spacer(),
                                        if (_products
                                            .where((p) => p.stock <= 5)
                                            .isNotEmpty)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20),
                                            ),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Icon(
                                                    Icons
                                                        .warning_amber_rounded,
                                                    size: 12,
                                                    color: Colors
                                                        .orange.shade700),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${_products.where((p) => p.stock <= 5).length} stok hampir habis",
                                                  style:
                                                      GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Colors
                                                        .orange.shade700,
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
                                      physics:
                                          const BouncingScrollPhysics(),
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                              16, 6, 16, 100),
                                      itemCount: _filtered.length,
                                      itemBuilder: (_, i) =>
                                          _buildProductCard(
                                              _filtered[i]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text("Tambah Produk",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 13)),
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
      child: Stack(
        children: [
          Positioned(top: -18, right: -18, child: _circle(110, 0.07)),
          Positioned(top: 38, right: 60, child: _circle(44, 0.08)),
          SafeArea(
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
                    child: const Icon(Icons.local_cafe_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Manajemen Produk",
                            style: GoogleFonts.playfairDisplay(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 20)),
                        Text("Kelola semua produk kopitiam33 di sini",
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color:
                                    Colors.white.withOpacity(0.7))),
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
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // ─────────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          setState(() {
            _searchQuery = v;
            _applyFilter();
          });
        },
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: "Cari produk...",
          hintStyle: GoogleFonts.poppins(
              fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _applyFilter();
                    });
                  },
                  child: Icon(Icons.close_rounded,
                      color: Colors.grey.shade400, size: 18),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF7F2EA),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // PRODUCT CARD
  // FIX: gunakan CachedNetworkImage agar gambar
  // tidak hilang-hilang dan ter-cache dengan baik
  // ─────────────────────────────────────────────────
  Widget _buildProductCard(Product product) {
    final isLowStock = product.stock <= 5;
    final hasVariant = product.priceCold != null;
    final hasImage =
        product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isLowStock
            ? Border.all(
                color: Colors.orange.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── GAMBAR — CachedNetworkImage ──
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: SizedBox(
              width: 90,
              height: 110,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      // Key unik per produk agar cache tidak bentrok
                      cacheKey: 'product_thumb_${product.id}',
                      // Shimmer saat loading
                      placeholder: (_, __) => _buildImageShimmer(),
                      // Fallback jika error
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
          ),

          // ── INFO ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama
                  Text(
                    product.name,
                    style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFF1A1A1A)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  // Harga
                  hasVariant
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _priceChip("☕ Panas",
                                _formatPrice(product.price),
                                AppColors.primaryGreen),
                            const SizedBox(height: 3),
                            _priceChip("🧊 Dingin",
                                _formatPrice(product.priceCold!),
                                Colors.blue.shade500),
                          ],
                        )
                      : Text(
                          _formatPrice(product.price),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen),
                        ),

                  const SizedBox(height: 6),

                  // Stok badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? Colors.orange.withOpacity(0.12)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLowStock
                                  ? Icons.warning_amber_rounded
                                  : Icons.inventory_2_outlined,
                              size: 11,
                              color: isLowStock
                                  ? Colors.orange.shade700
                                  : Colors.green.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Stok: ${product.stock}",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isLowStock
                                    ? Colors.orange.shade700
                                    : Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLowStock) ...[
                        const SizedBox(width: 6),
                        Text(
                          "Hampir habis!",
                          style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: Colors.orange.shade600,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── AKSI ──
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 10, 12),
            child: Column(
              children: [
                _actionBtn(
                  icon: Icons.edit_rounded,
                  color: Colors.blue,
                  onTap: () => _navigateToForm(product: product),
                ),
                const SizedBox(height: 8),
                _actionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  onTap: () =>
                      _deleteProduct(product.id, product.name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer saat gambar sedang loading
  Widget _buildImageShimmer() {
    return Container(
      width: 90,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryGreen.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  // Placeholder jika tidak ada gambar / gambar error
  Widget _placeholderImage() {
    return Container(
      width: 90,
      height: 110,
      color: AppColors.primaryGreen.withOpacity(0.08),
      child: Icon(
        Icons.local_cafe_rounded,
        size: 36,
        color: AppColors.primaryGreen.withOpacity(0.4),
      ),
    );
  }

  Widget _priceChip(String label, String price, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label  ",
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey.shade500)),
        Text(price,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // EMPTY & ERROR STATE
  // ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isSearch = _searchQuery.isNotEmpty;
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
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.local_cafe_rounded,
                size: 38,
                color: AppColors.primaryGreen.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch
                  ? "Produk Tidak Ditemukan"
                  : "Belum Ada Produk",
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? "Tidak ada produk yang cocok dengan\n\"$_searchQuery\"."
                  : "Tambahkan produk pertama\nuntuk ditampilkan ke pelanggan.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.6),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: isSearch
                  ? () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyFilter();
                      });
                    }
                  : () => _navigateToForm(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isSearch ? "Hapus Pencarian" : "Tambah Produk",
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
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
            Text("Gagal Memuat Produk",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text(
              "Periksa koneksi internetmu\nlalu coba lagi.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.6),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchProducts,
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