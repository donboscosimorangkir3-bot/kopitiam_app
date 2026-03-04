// lib/presentation/pages/product_management_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/product_remote_datasource.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:kopitiam_app/presentation/pages/product_form_page.dart'; // Import halaman form produk

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Fungsi untuk memuat ulang daftar produk
  Future<void> _fetchProducts() async {
    _productsFuture = ProductRemoteDatasource().getProducts(); 
    setState(() {});
  }

  String _formatPrice(double price) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(price);
  }

  // Fungsi untuk menghapus produk
  Future<void> _deleteProduct(int productId, String productName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Produk?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Anda yakin ingin menghapus produk '$productName'?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Batal", style: GoogleFonts.poppins(color: AppColors.darkBrown))),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Hapus", style: GoogleFonts.poppins(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Menghapus produk '$productName'...")),
      );
      final success = await ProductRemoteDatasource().deleteProduct(productId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Produk '$productName' berhasil dihapus")),
        );
        _fetchProducts(); // Muat ulang daftar produk
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus produk.", style: TextStyle(color: AppColors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Manajemen Produk", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductFormPage()), // Ke halaman tambah produk
              );
              _fetchProducts(); // Refresh setelah kembali dari form
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        color: AppColors.primaryGreen,
        backgroundColor: AppColors.lightCream,
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: AppColors.darkBrown)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text("Belum ada produk. Tambahkan sekarang!", style: TextStyle(color: AppColors.greyText)));
            }

            final products = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product);
              },
            );
          },
        ),
      ),
    );
  }

  // WIDGET KARTU PRODUK UNTUK MANAJEMEN
  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl ?? 'https://via.placeholder.com/80',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.coffee, size: 40, color: AppColors.greyText);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.darkBrown,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.priceCold != null
                        ? 'Harga: ${_formatPrice(product.price)} - ${_formatPrice(product.priceCold!)}'
                        : 'Harga: ${_formatPrice(product.price)}',
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock}',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.greyText),
                  ),
                ],
              ),
            ),
            // Tombol Edit & Hapus
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductFormPage(product: product)), // Ke halaman edit produk
                    );
                    _fetchProducts(); // Refresh setelah kembali dari form
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(product.id, product.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}