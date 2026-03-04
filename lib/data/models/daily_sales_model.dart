// lib/data/models/daily_sales_model.dart

class DailySales {
  final DateTime date;
  final double totalSales;

  DailySales({
    required this.date,
    required this.totalSales,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: DateTime.parse(json['date']),
      totalSales: double.parse(json['total_sales'].toString()),
    );
  }
}