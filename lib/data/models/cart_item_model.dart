// lib/data/models/cart_item_model.dart

import 'package:kopitiam_app/data/models/product_model.dart';

class CartItem {
  final int id;
  final int cartId;
  final int productId;
  int quantity;
  final String? temperature;    // ← BARU: 'Hot', 'Cold', atau null
  final Product product;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    this.temperature,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id:        json['id'],
      cartId:    json['cart_id'],
      productId: json['product_id'],
      quantity:  json['quantity'],
      temperature: json['temperature'],           // ← BARU
      product:   Product.fromJson(json['product']),
    );
  }

  // Helper untuk label yang ditampilkan di UI keranjang
  String get variantLabel {
    if (temperature == null || temperature!.isEmpty) return '';
    
    // Sesuaikan dengan data dari Laravel (biasanya huruf kecil 'hot'/'cold')
    final t = temperature!.toLowerCase();
    if (t == 'hot')  return '☕ Panas';
    if (t == 'cold') return '🧊 Dingin';
    
    return temperature!;
  }
}