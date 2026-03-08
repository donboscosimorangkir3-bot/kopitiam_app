// lib/presentation/pages/cart_page.dart

import 'package:flutter/material.dart';
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

class _CartPageState extends State<CartPage> {
  late Future<List<CartItem>> _cartItemsFuture;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // Fungsi untuk memuat ulang item keranjang
  Future<void> _fetchCartItems() async {
    setState(() {
      _cartItemsFuture = CartRemoteDatasource().getCartItems();
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

  // Fungsi untuk update quantity item keranjang
  void _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return; // Minimal 1

    // Cek stok (jika product memiliki properti stock)
    if (newQuantity > item.product.stock) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kuantitas melebihi stok!"), backgroundColor: Colors.red),
      );
      return;
    }

    // Update UI sementara
    setState(() {
      item.quantity = newQuantity;
    });

    final success = await CartRemoteDatasource().updateCartItem(item.id, newQuantity);
    if (success) {
      // Tidak perlu snackbar sukses, karena UI sudah update dan akan refresh total harga
      _fetchCartItems(); // Muat ulang keranjang untuk refresh total harga
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui kuantitas. Coba login ulang."), backgroundColor: Colors.red),
      );
      _fetchCartItems(); // Muat ulang untuk mengembalikan ke nilai sebelumnya jika gagal
    }
  }

  // Fungsi untuk hapus item keranjang
  void _removeItem(CartItem item) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus ${item.product.name}?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text("Anda yakin ingin menghapus item ini dari keranjang?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Batal", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Hapus", style: GoogleFonts.poppins(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await CartRemoteDatasource().deleteCartItem(item.id);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item.product.name} dihapus dari keranjang")),
        );
        _fetchCartItems(); // Muat ulang keranjang setelah dihapus
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus item. Coba login ulang."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Keranjang Anda", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: FutureBuilder<List<CartItem>>(
        future: _cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: AppColors.darkBrown)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.greyText),
                  const SizedBox(height: 16),
                  Text(
                    "Keranjang Anda Kosong",
                    style: GoogleFonts.poppins(fontSize: 18, color: AppColors.greyText),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Kembali ke halaman sebelumnya
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Lihat Menu", style: GoogleFonts.poppins(fontSize: 16)),
                  ),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!;
          double subtotal = 0;
          for (var item in cartItems) {
            subtotal += item.product.price * item.quantity; // Gunakan item.product.price, bukan _selectedPrice
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItemCard(item);
                  },
                ),
              ),
              // Bagian Total Harga & Tombol Checkout
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Harga:",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        Text(
                          _formatPrice(subtotal),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigasi ke Halaman Checkout
                          Navigator.push( // <-- UBAH KE NAVIGASI INI
                            context,
                            MaterialPageRoute(builder: (context) => const CheckoutPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        icon: const Icon(Icons.payment, size: 24),
                        label: Text(
                          "Checkout Sekarang",
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // WIDGET KARTU ITEM KERANJANG (Tombol Hapus Jadi Ikon)
  Widget _buildCartItemCard(CartItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Gambar Produk
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                // <-- Perubahan di sini -->
                item.product.imageUrl != null && item.product.imageUrl!.startsWith('http')
                    ? item.product.imageUrl!
                    : (item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                        ? '${ApiConstants.baseUrl}${item.product.imageUrl!}'
                        : 'https://via.placeholder.com/80/6DAF9F/FFFFFF?text=Kopi'), // Placeholder lebih relevan
                // <-- Akhir perubahan di sini -->
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.coffee, size: 40, color: AppColors.greyText);
                },
              ),
            ),
            const SizedBox(width: 12),
            // Nama Produk & Harga
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.darkBrown,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatPrice(item.product.price), // Mengambil harga dari item.product
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Kontrol Kuantitas & Hapus
            Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _updateQuantity(item, item.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.lightCream,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.remove, size: 20, color: AppColors.primaryGreen),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        item.quantity.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _updateQuantity(item, item.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.lightCream,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.primaryGreen),
                        ),
                        child: const Icon(Icons.add, size: 20, color: AppColors.primaryGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tombol Hapus menjadi Ikon
                GestureDetector(
                  onTap: () => _removeItem(item),
                  child: const Icon(Icons.delete, color: Colors.red, size: 24), // <-- ICON HAPUS
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}