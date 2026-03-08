// lib/data/models/report_summary_model.dart

import 'package:kopitiam_app/data/models/top_product_model.dart';
import 'package:kopitiam_app/data/models/daily_sales_model.dart';

class ReportSummary {
  final double totalRevenue;
  final int totalOrders;
  final int completedOrders;
  final List<TopProduct> topProducts;
  final List<DailySales> dailySales;
  final DateTime startDate;
  final DateTime endDate;

  ReportSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.topProducts,
    required this.dailySales,
    required this.startDate,
    required this.endDate,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,

      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,

      completedOrders: int.tryParse(json['completed_orders']?.toString() ?? '0') ?? 0,

      topProducts: (json['top_products'] as List<dynamic>?)
              ?.map((item) => TopProduct.fromJson(item))
              .toList() ??
          [],

      dailySales: (json['daily_sales'] as List<dynamic>?)
              ?.map((item) => DailySales.fromJson(item))
              .toList() ??
          [],

      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),

      endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'top_products': topProducts.map((e) => e.toJson()).toList(),
      'daily_sales': dailySales.map((e) => e.toJson()).toList(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}