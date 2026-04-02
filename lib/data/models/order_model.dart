// lib/data/models/order_model.dart

import 'package:kopitiam_app/data/models/order_item_model.dart';
import 'package:kopitiam_app/data/models/user_model.dart';

class Order {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status; // Ini adalah order_status (pending, processing, ready, completed, cancelled)
  final String shippingAddress;
  final DateTime createdAt;

  final String? paymentStatus;  // 'unpaid', 'paid' -> DITAMBAHKAN
  final String? paymentMethod;  // 'cash_on_pickup', dll
  final String? orderType;      // 'pickup' | 'dine-in'
  final String? tableNumber;    // nomor meja (jika dine-in)

  final List<OrderItem>? items;
  final User? user;

  Order({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
    this.paymentStatus,
    this.paymentMethod,
    this.orderType,
    this.tableNumber,
    this.items,
    this.user,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items =[];
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((i) => OrderItem.fromJson(i))
          .toList();
    }

    User? user;
    if (json['user'] != null) {
      user = User.fromJson(json['user']);
    }

    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      shippingAddress: json['shipping_address'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      paymentStatus: json['payment'] != null 
        ? json['payment']['payment_status'] 
        : 'unpaid', 
        
    paymentMethod: json['payment'] != null 
        ? json['payment']['payment_method'] 
        : null,
      orderType: json['order_type'],
      tableNumber: json['table_number']?.toString(),
      items: items,
      user: user,
    );
  }
}