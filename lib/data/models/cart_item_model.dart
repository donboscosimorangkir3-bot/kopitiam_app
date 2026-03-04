// lib/data/models/cart_item_model.dart

import 'package:kopitiam_app/data/models/product_model.dart'; // Perlu model Produk

class CartItem {
  final int id;
  final int cartId;
  final int productId;
  int quantity; // Quantity bisa berubah, jadi tidak final
  final Product product; // Detail produk yang ada di keranjang

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      cartId: json['cart_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      // Pastikan ada objek 'product' di JSON balasan dari backend
      product: Product.fromJson(json['product']), 
    );
  }
}