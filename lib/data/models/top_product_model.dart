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
      productName: json['product_name'],
      totalQuantity: json['total_quantity'],
    );
  }
}