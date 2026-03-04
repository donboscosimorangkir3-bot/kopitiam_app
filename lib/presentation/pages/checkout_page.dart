// lib/presentation/pages/checkout_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/datasources/cart_remote_datasource.dart';
import 'package:kopitiam_app/data/models/cart_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kopitiam_app/presentation/pages/order_history_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // TextEditingController _addressController tidak diperlukan lagi di UI,
  // tapi kita akan kirim string default 'Pickup di Kopitiam33' ke backend
  String _paymentMethod = 'cash_on_pickup'; // <-- Default ke Cash on Pickup
  bool _isLoading = false;
  late Future<List<CartItem>> _cartItemsFuture;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // Dispose tidak diperlukan karena tidak ada TextEditingController
  // @override
  // void dispose() {
  //   super.dispose();
  // }

  Future<void> _fetchCartItems() async {
    _cartItemsFuture = CartRemoteDatasource().getCartItems();
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

  // Fungsi untuk proses Checkout
  void _processCheckout() async {
    setState(() {
      _isLoading = true;
    });

    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda belum login!"), backgroundColor: Colors.red),
      );
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final response = await dio.post(
        ApiConstants.checkout, // POST /api/checkout
        data: {
          'shipping_address': 'Pickup di Kopitiam33', // <-- Kirim alamat default
          'payment_method': _paymentMethod,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pesanan berhasil dibuat, menunggu pembayaran di kafe."),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Checkout Gagal: ${response.data['message'] ?? 'Terjadi kesalahan.'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      print("Checkout Dio Gagal: ${e.response?.data}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Checkout Gagal: ${e.response?.data['message'] ?? e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Checkout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              child: Text(
                "Keranjang kosong. Tidak bisa checkout.",
                style: GoogleFonts.poppins(fontSize: 18, color: AppColors.greyText),
              ),
            );
          }

          final cartItems = snapshot.data!;
          double subtotal = 0;
          for (var item in cartItems) {
            subtotal += item.product.price * item.quantity;
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ringkasan Pesanan",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text("${item.quantity}x ${item.product.name}", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
                                const Spacer(),
                                Text(_formatPrice(item.product.price * item.quantity), style: GoogleFonts.poppins(color: AppColors.darkBrown)),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Bayar:",
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
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Bagian Metode Pengambilan
                      Text(
                        "Metode Pengambilan",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.store, color: AppColors.primaryGreen),
                          title: Text("Ambil di Kafe (Pickup)", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
                          subtitle: Text("Pesanan disiapkan untuk diambil di Kopitiam33", style: GoogleFonts.poppins(color: AppColors.greyText)),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Bagian Metode Pembayaran
                      Text(
                        "Metode Pembayaran",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: RadioListTile<String>(
                          title: Text("Bayar di Kafe", style: GoogleFonts.poppins(color: AppColors.darkBrown)), // <-- Ubah teks
                          subtitle: Text("Pembayaran tunai/QRIS langsung kepada kasir saat pengambilan", style: GoogleFonts.poppins(color: AppColors.greyText)), // <-- Ubah subtitle
                          value: 'cash_on_pickup', // <-- Ubah nilai
                          groupValue: _paymentMethod,
                          onChanged: (String? value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                          activeColor: AppColors.primaryGreen,
                        ),
                      ),
                      // Hapus seluruh bagian Gambar QRIS Statis dan Upload Bukti Pembayaran
                    ],
                  ),
                ),
              ),
              // Tombol Konfirmasi Checkout (sama)
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
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _processCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 24),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: AppColors.white)
                        : Text(
                            "Konfirmasi Pesanan",
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}