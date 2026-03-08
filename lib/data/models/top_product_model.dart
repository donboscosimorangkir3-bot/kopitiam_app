// lib/data/models/top_product_model.dart

class TopProduct {
  final String productName;
  final int totalQuantity;

  TopProduct({
    required this.productName,
    required this.totalQuantity,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productName: json['product_name'] ?? '',
      totalQuantity:
          int.tryParse(json['total_quantity']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'total_quantity': totalQuantity,
    };
  }
}