// lib/data/models/order_item_model.dart

import 'package:kopitiam_app/data/models/product_model.dart';

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final double price;
  final String? temperature;
  final int quantity;
  final double subtotal;
  final Product? product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    this.temperature,
    required this.quantity,
    required this.subtotal,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Semua field numerik pakai fallback '0' jika null
    // String field pakai fallback '' jika null
    return OrderItem(
      id:          json['id'] ?? 0,
      orderId:     json['order_id'] ?? 0,
      productId:   json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Produk',
      price:       double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity:    json['quantity'] ?? 0,
      subtotal:    double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      temperature: json['temperature'],
      product:     json['product'] != null
                      ? Product.fromJson(json['product'])
                      : null,
    );
  }
}