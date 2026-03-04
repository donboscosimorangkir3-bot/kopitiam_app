// lib/presentation/pages/product_detail_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart'; // Untuk notif login guest
import 'package:kopitiam_app/presentation/pages/cart_page.dart'; // Untuk navigasi ke keranjang
import 'package:kopitiam_app/data/datasources/cart_remote_datasource.dart'; // Untuk fungsi addToCart

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final bool isLoggedIn; // Untuk menentukan apakah tombol Add to Cart muncul

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.isLoggedIn,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  double _selectedPrice = 0;
  String _selectedVariant = 'Hot';
  final TextEditingController _quantityController = TextEditingController(); // <-- TAMBAHKAN INI

  @override
  void initState() {
    super.initState();
    _selectedPrice = widget.product.price; 
    _selectedVariant = widget.product.priceCold == null ? '' : 'Hot';
    _quantityController.text = _quantity.toString(); // <-- Inisialisasi controller
  }

  // Tambahkan dispose untuk controller
  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Fungsi untuk format harga
  String _formatPrice(double price) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(price);
  }

  // Fungsi untuk menambah kuantitas
  void _increaseQuantity() {
    setState(() {
      _quantity++;
      _quantityController.text = _quantity.toString(); // Update TextField
    });
  }

  // Fungsi untuk mengurangi kuantitas
  void _decreaseQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
        _quantityController.text = _quantity.toString(); // Update TextField
      }
    });
  }

  // Fungsi untuk Add to Cart
  void _addToCart() async { // Ubah jadi async
    if (!widget.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Silakan login untuk menambahkan ${widget.product.name} ke keranjang!"),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      // Opsional: Langsung arahkan ke halaman login
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } else {
      // Tambahkan pengecekan stok
      if (_quantity <= 0 || _quantity > widget.product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jumlah tidak valid atau melebihi stok!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        // _isLoading = true; // Jika ingin ada loading di tombol
      });

      final cartService = CartRemoteDatasource();
      bool success = await cartService.addToCart(
        widget.product.id,
        _quantity,
      );

      setState(() {
        // _isLoading = false;
      });

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil menambahkan $_quantity ${widget.product.name} ke keranjang!"),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        // Langsung arahkan ke halaman keranjang setelah berhasil
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menambahkan ke keranjang. Coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text(widget.product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.lightCream,
                image: DecorationImage(
                  image: NetworkImage(widget.product.imageUrl ?? 'https://via.placeholder.com/400x300/6DAF9F/FFFFFF?text=No+Image'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Stok: ${widget.product.stock}',
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Nama & Harga
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Harga: ${_formatPrice(_selectedPrice)}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi
                  Text(
                    "Deskripsi Produk:",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description ?? 'Tidak ada deskripsi tersedia.',
                    style: GoogleFonts.poppins(fontSize: 16, color: AppColors.greyText),
                  ),
                  const SizedBox(height: 24),

                  // Pilihan Varian (Panas/Dingin) jika ada
                  if (widget.product.priceCold != null) ...[
                    Text(
                      "Pilih Varian:",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildVariantChip(
                          label: "Panas (${_formatPrice(widget.product.price)})",
                          isSelected: _selectedVariant == 'Hot',
                          onTap: () {
                            setState(() {
                              _selectedVariant = 'Hot';
                              _selectedPrice = widget.product.price;
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildVariantChip(
                          label: "Dingin (${_formatPrice(widget.product.priceCold!)})",
                          isSelected: _selectedVariant == 'Cold',
                          onTap: () {
                            setState(() {
                              _selectedVariant = 'Cold';
                              _selectedPrice = widget.product.priceCold!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Kontrol Kuantitas
              Text(
                "Jumlah:",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQuantityButton(Icons.remove, _decreaseQuantity),
                  // Ganti Container dengan TextField yang bisa diedit
                  Expanded( // Gunakan Expanded agar TextField punya ruang
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.lightCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number, // Hanya angka
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero, // Hapus padding default
                        ),
                        onChanged: (value) {
                          // Update _quantity saat user mengetik
                          setState(() {
                            _quantity = int.tryParse(value) ?? 1; // Jika bukan angka, jadi 1
                            if (_quantity < 1) _quantity = 1; // Minimal 1
                            // TODO: Bisa tambahkan cek stok di sini
                          });
                        },
                      ),
                    ),
                  ),
                  _buildQuantityButton(Icons.add, _increaseQuantity),
                ],
              ),
              const SizedBox(height: 40),

                  // Tombol Tambah ke Keranjang
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 24),
                      label: Text(
                        widget.isLoggedIn ? "Tambah ke Keranjang" : "Login untuk Memesan",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET KUSTOM: Tombol Quantity
  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightCream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryGreen),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: AppColors.primaryGreen, size: 24),
      ),
    );
  }

  // WIDGET KUSTOM: Chip Varian (Panas/Dingin)
  Widget _buildVariantChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen.withOpacity(0.8),
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? AppColors.white : AppColors.darkBrown,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppColors.lightCream,
      onSelected: (selected) {
        if (selected) onTap();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryGreen : AppColors.greyText.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}