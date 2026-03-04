// lib/data/models/order_model.dart

import 'package:kopitiam_app/data/models/order_item_model.dart';
import 'package:kopitiam_app/data/models/user_model.dart'; // <-- TAMBAHKAN IMPORT INI

class Order {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final DateTime createdAt;

  final List<OrderItem>? items;
  final User? user; // <-- TAMBAHKAN PROPERTI INI
  // final Payment? payment; // Jika nanti perlu detail payment di sini

  Order({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
    this.items,
    this.user, // <-- TAMBAHKAN INI DI KONSTRUKTOR
    // this.payment,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList();
    }
    
    // Parsing data user dari JSON
    User? user;
    if (json['user'] != null) {
      user = User.fromJson(json['user']);
    }

    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      shippingAddress: json['shipping_address'],
      createdAt: DateTime.parse(json['created_at']),
      items: items,
      user: user, // <-- BACA DATA USER DARI JSON
      // payment: json['payment'] != null ? Payment.fromJson(json['payment']) : null,
    );
  }
}