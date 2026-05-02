// lib/presentation/widgets/product_grid_section.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/product_remote_datasource.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:kopitiam_app/presentation/pages/product_detail_page.dart';

class ProductGridSection extends StatefulWidget {
  final bool isLoggedIn;
  final int? filterCategoryId;
  final String? searchQuery;

  const ProductGridSection({
    super.key,
    required this.isLoggedIn,
    this.filterCategoryId,
    this.searchQuery,
  });

  @override
  State<ProductGridSection> createState() => _ProductGridSectionState();
}

class _ProductGridSectionState extends State<ProductGridSection> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void didUpdateWidget(covariant ProductGridSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterCategoryId != oldWidget.filterCategoryId ||
        widget.searchQuery != oldWidget.searchQuery) {
      _fetchProducts();
    }
  }

  void _fetchProducts() {
    setState(() {
      _productsFuture = ProductRemoteDatasource().getProducts();
    });
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  void _onProductTap(Product product) {
    if (!widget.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Silakan login untuk melihat detail ${product.name}",
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            product: product,
            isLoggedIn: widget.isLoggedIn,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonGrid();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.coffee_outlined,
            title: "Menu belum tersedia",
            subtitle: "Belum ada produk yang ditambahkan",
          );
        }

        final products = snapshot.data!.where((p) {
          final categoryMatch = widget.filterCategoryId == null ||
              p.category_id == widget.filterCategoryId;
          final searchMatch = widget.searchQuery == null ||
              widget.searchQuery!.isEmpty ||
              p.name.toLowerCase().contains(widget.searchQuery!.toLowerCase());
          return categoryMatch && searchMatch;
        }).toList();

        if (products.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off_rounded,
            title: "Tidak ada hasil",
            subtitle: widget.searchQuery != null
                ? 'Tidak ditemukan untuk "${widget.searchQuery}"'
                : "Tidak ada menu di kategori ini",
          );
        }

        return GridView.builder(
          key: ValueKey('${widget.filterCategoryId}-${widget.searchQuery}'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.62, // ── DINAIKKAN agar tidak overflow ──
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _ProductCard(
              product: products[index],
              isLoggedIn: widget.isLoggedIn,
              onTap: () => _onProductTap(products[index]),
              formatPrice: _formatPrice,
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 34,
                color: AppColors.primaryGreen.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded,
                size: 30, color: Colors.red.shade300),
          ),
          const SizedBox(height: 14),
          Text(
            "Gagal memuat menu",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Periksa koneksi internet Anda",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _fetchProducts,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text("Coba lagi",
                style: GoogleFonts.poppins(fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.08),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PRODUCT CARD
// ═══════════════════════════════════════════════
class _ProductCard extends StatefulWidget {
  final Product product;
  final bool isLoggedIn;
  final VoidCallback onTap;
  final String Function(double) formatPrice;

  const _ProductCard({
    required this.product,
    required this.isLoggedIn,
    required this.onTap,
    required this.formatPrice,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _pressAnim = CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Widget _buildImage() {
    final url = widget.product.imageUrl;
    if (url == null || url.trim().isEmpty) {
      return _buildImagePlaceholder(showIcon: true);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheKey: url,
      placeholder: (context, _) => _buildImagePlaceholder(showIcon: false),
      errorWidget: (context, _, __) =>
          _buildImagePlaceholder(showIcon: true),
    );
  }

  Widget _buildImagePlaceholder({required bool showIcon}) {
    return Container(
      color: const Color(0xFFF0EBE0),
      child: showIcon
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported_outlined,
                    size: 28, color: Colors.brown.withOpacity(0.22)),
                const SizedBox(height: 5),
                Text(
                  "Foto belum tersedia",
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.brown.withOpacity(0.28),
                  ),
                ),
              ],
            )
          : const _ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasDescription =
        product.description != null && product.description!.trim().isNotEmpty;

    // ── FIX: Tampilkan HANYA harga asli (price), abaikan priceCold ──
    // Jika ada priceCold, tampilkan label kecil "Mulai dari"
    final hasCold = product.priceCold != null;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _pressAnim.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── GAMBAR ──
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(),

                      // Badge "Panas & Dingin" jika ada priceCold
                      if (hasCold)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('☕🧊',
                                    style: TextStyle(fontSize: 9)),
                                const SizedBox(width: 3),
                                Text(
                                  'Panas & Dingin',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Badge stok habis
                      if (product.stock == 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Habis',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── INFO PRODUK ──
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── NAMA ──
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // ── DESKRIPSI ──
                      Expanded(
                        child: Text(
                          hasDescription
                              ? product.description!
                              : "Lihat detail untuk info lebih lanjut",
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: hasDescription
                                ? Colors.grey.shade500
                                : Colors.grey.shade300,
                            height: 1.4,
                            fontStyle: hasDescription
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── HARGA — hanya satu harga (harga asli) ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Label "Mulai dari" jika ada varian dingin
                                if (hasCold)
                                  Text(
                                    'Mulai dari',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                Text(
                                  widget.formatPrice(product.price),
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // ── TOMBOL TAMBAH ──
                          if (widget.isLoggedIn && product.stock > 0)
                            GestureDetector(
                              onTap: widget.onTap,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryGreen,
                                      AppColors.primaryGreen.withOpacity(0.82),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: Colors.white,
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
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SKELETON CARD
// ═══════════════════════════════════════════════
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: const _ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(
                      width: double.infinity, height: 13, borderRadius: 6),
                  const SizedBox(height: 7),
                  _ShimmerBox(
                      width: double.infinity, height: 10, borderRadius: 5),
                  const SizedBox(height: 5),
                  _ShimmerBox(width: 100, height: 10, borderRadius: 5),
                  const Spacer(),
                  _ShimmerBox(width: 75, height: 13, borderRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SHIMMER BOX
// ═══════════════════════════════════════════════
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            colors: [
              Color.lerp(const Color(0xFFEDE8DF), const Color(0xFFF7F3EC),
                  _anim.value)!,
              Color.lerp(const Color(0xFFF7F3EC), const Color(0xFFEDE8DF),
                  _anim.value)!,
            ],
          ),
        ),
      ),
    );
  }
}