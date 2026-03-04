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
      totalRevenue: double.parse(json['total_revenue'].toString()),
      totalOrders: json['total_orders'],
      completedOrders: json['completed_orders'],
      topProducts: (json['top_products'] as List).map((i) => TopProduct.fromJson(i)).toList(),
      dailySales: (json['daily_sales'] as List).map((i) => DailySales.fromJson(i)).toList(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }
}