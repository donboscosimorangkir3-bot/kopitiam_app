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
  // 1. Variabel penampung data asli dari Database
  List<Product> _products =[];
  bool _isFetchingProducts = true; // Loading awal untuk list produk

  // Keranjang lokal kasir: Map<id_produk, int_jumlah>
  final Map<int, int> _cart = {}; 

  final _customerNameController = TextEditingController();
  final _tableNumberController = TextEditingController();
  String _orderType = 'dine-in';
  bool _isLoading = false; // Loading saat submit pesanan

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Tarik data saat halaman dibuka
  }

  // 2. Fungsi untuk mengambil produk dari Backend
  Future<void> _fetchProducts() async {
    setState(() => _isFetchingProducts = true);
    try {
      // Pastikan nama class datasource produk Anda sesuai (ProductRemoteDatasource)
      final fetchedProducts = await ProductRemoteDatasource().getProducts();
      
      if (mounted) {
        setState(() {
          _products = fetchedProducts;
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

  String _formatPrice(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  // 3. Menghitung total harga berdasarkan data asli
  double _getTotalPrice() {
    double total = 0;
    _cart.forEach((id, qty) {
      try {
        final product = _products.firstWhere((p) => p.id == id);
        total += product.price * qty;
      } catch (e) {
        // Jika produk tidak ditemukan, lewati
      }
    });
    return total;
  }

  void _showSnackBar(String message, {bool isError = false, IconData icon = Icons.info_outline}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children:[
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

  void _processManualOrder() async {
    if (_cart.isEmpty) {
      _showSnackBar("Pilih minimal 1 produk!", isError: true);
      return;
    }
    if (_customerNameController.text.isEmpty) {
      _showSnackBar("Nama pelanggan harus diisi!", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _showSnackBar("Memproses pesanan...", icon: Icons.hourglass_top_rounded);

    List<Map<String, dynamic>> items = [];
_cart.forEach((id, qty) {
  items.add({
    "product_id": id,
    "quantity": qty,
    "note": "Panas", // Anda bisa modifikasi UI kasir agar bisa memilih ini juga
  });
});

    Map<String, dynamic> orderData = {
      "customer_name": _customerNameController.text,
      "order_type": _orderType,
      "table_number": _orderType == 'dine-in' ? _tableNumberController.text : null,
      "items": items,
    };
    
    final success = await OrderRemoteDatasource().createManualOrder(orderData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar("Pesanan berhasil dibuat!", icon: Icons.check_circle_outline);
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, true); 
      });
    } else {
      _showSnackBar("Gagal membuat pesanan, periksa koneksi/stok.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      appBar: AppBar(
        title: Text("Buat Pesanan Manual", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children:[
          // ── LIST PRODUK DARI DATABASE ──
          Expanded(
            child: _isFetchingProducts 
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                )
              : _products.isEmpty
                ? Center(
                    child: Text("Belum ada produk.", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final id = product.id;
                      final qty = _cart[id] ?? 0;
                      final bool isOutOfStock = product.stock <= 0; // Cek stok

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children:[
                            // ── GAMBAR PRODUK ──
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product.imageUrl ?? 'https://via.placeholder.com/150/4CAF50/FFFFFF?text=K',
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 65, height: 65,
                                  decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.fastfood_rounded, color: AppColors.primaryGreen.withOpacity(0.5), size: 30),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // ── INFO PRODUK ──
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  Text(
                                    product.name, 
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.grey.shade500 : const Color(0xFF1A1A1A)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatPrice(product.price.toDouble()), 
                                    style: GoogleFonts.poppins(fontSize: 13, color: isOutOfStock ? Colors.grey.shade400 : AppColors.primaryGreen, fontWeight: FontWeight.w600)
                                  ),
                                  if (isOutOfStock)
                                    Text("Stok Habis", style: GoogleFonts.poppins(fontSize: 10, color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // ── PENGATUR JUMLAH (MINUS / PLUS) ──
                            if (!isOutOfStock)
                              Row(
                                children:[
                                  if (qty > 0)
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        if (qty == 1) _cart.remove(id); else _cart[id] = qty - 1;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Icon(Icons.remove, size: 16, color: Colors.red.shade600),
                                      ),
                                    ),
                                  if (qty > 0)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text("$qty", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                                    ),
                                  GestureDetector(
                                    onTap: () {
                                      if (qty < product.stock) {
                                        setState(() => _cart[id] = qty + 1);
                                      } else {
                                        _showSnackBar("Sisa stok hanya ${product.stock}!", isError: true);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ── PANEL BAWAH (CHECKOUT KASIR) ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children:[
                      Expanded(
                        child: TextField(
                          controller: _customerNameController,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Nama Pelanggan / Tamu",
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children:[
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _orderType,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const[
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
                            decoration: InputDecoration(
                              hintText: "No. Meja",
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Text("Total Tagihan", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                          Text(_formatPrice(_getTotalPrice()), style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _processManualOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Proses Pesanan", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}