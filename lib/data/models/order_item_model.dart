// lib/data/models/order_item_model.dart

import 'package:kopitiam_app/data/models/product_model.dart'; // <-- IMPORT INI

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;
  final Product? product; // <-- TAMBAHKAN INI

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.product, // <-- TAMBAHKAN INI DI KONSTRUKTOR
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'],
      subtotal: double.parse(json['subtotal'].toString()),
      product: json['product'] != null ? Product.fromJson(json['product']) : null, // <-- BACA DATA PRODUK
    );
  }
}