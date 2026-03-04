// lib/presentation/widgets/product_grid_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/product_remote_datasource.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/product_detail_page.dart'; // Import detail page

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
    _fetchProducts(); // Panggil saat initState
  }

  // Penting: Agar widget bisa update saat filter berubah dari luar
  @override
  void didUpdateWidget(covariant ProductGridSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Muat ulang produk jika filter kategori atau search query berubah
    if (widget.filterCategoryId != oldWidget.filterCategoryId ||
        widget.searchQuery != oldWidget.searchQuery) {
      _fetchProducts(); // Panggil ulang untuk memuat data baru
    }
  }

  // Fungsi untuk memuat produk
  void _fetchProducts() {
    setState(() {
      _productsFuture = ProductRemoteDatasource().getProducts();
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

  // Fungsi untuk menangani klik pada Product Card
  void _onProductTap(Product product) {
    if (!widget.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Silakan login untuk menambahkan ${product.name} ke keranjang!"),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      // Opsional: Langsung arahkan ke halaman login
      // Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } else {
      // Navigasi ke Halaman Detail Produk
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: AppColors.darkBrown)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Menu belum tersedia.", style: TextStyle(color: AppColors.greyText)));
        }

        final products = snapshot.data!
            .where((p) {
              // Filter berdasarkan kategori ID
              bool categoryMatch = widget.filterCategoryId == null || p.category_id == widget.filterCategoryId;
              
              // Filter berdasarkan query pencarian (nama produk)
              bool searchMatch = widget.searchQuery == null ||
                  widget.searchQuery!.isEmpty ||
                  p.name.toLowerCase().contains(widget.searchQuery!.toLowerCase());
              
              // Jika ingin cari di deskripsi juga, tambahkan:
              // || p.description?.toLowerCase().contains(widget.searchQuery!.toLowerCase()) == true;

              return categoryMatch && searchMatch;
            })
            .toList();

        if (products.isEmpty) {
          return const Center(child: Text("Tidak ada menu di kategori ini.", style: TextStyle(color: AppColors.greyText)));
        }
        return GridView.builder(
          key: ValueKey('${widget.filterCategoryId}-${widget.searchQuery}'), // <-- TAMBAHKAN KEY INI
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.60, // <-- Coba 0.60, jika masih overflow coba 0.55
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  // WIDGET KARTU PRODUK (Perbaikan Overflow)
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _onProductTap(product),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  product.imageUrl ?? 'https://via.placeholder.com/150/6DAF9F/FFFFFF?text=Kopitiam33', // Default image
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container( // Placeholder jika gambar error
                      color: AppColors.lightCream.withOpacity(0.5),
                      child: const Icon(Icons.coffee, size: 50, color: AppColors.greyText),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Perbaikan overflow di harga
                    Flexible(
                      child: Text(
                        product.priceCold != null
                            ? '${_formatPrice(product.price)} - ${_formatPrice(product.priceCold!)}'
                            : _formatPrice(product.price),
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Tombol "Add to Cart" (hanya muncul jika isLoggedIn true)
                    if (widget.isLoggedIn) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Logika Add to Cart
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Add ${product.name} ke Keranjang")),
                            );
                          },
                          child: CircleAvatar(
                            backgroundColor: AppColors.primaryGreen,
                            radius: 18,
                            child: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.white),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}