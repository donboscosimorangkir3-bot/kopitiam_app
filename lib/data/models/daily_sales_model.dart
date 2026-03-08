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
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      totalSales:
          double.tryParse(json['total_sales']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'total_sales': totalSales,
    };
  }
}