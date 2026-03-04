// lib/data/models/product_model.dart

class Product {
  final int id;
  final int category_id; // <-- TAMBAHKAN INI
  final String name;
  final String? description;
  final double price;
  final double? priceCold;
  final String? imageUrl;
  final int stock;

  Product({
    required this.id,
    required this.category_id, // <-- TAMBAHKAN INI
    required this.name,
    this.description,
    required this.price,
    this.priceCold,
    this.imageUrl,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      category_id: json['category_id'], // <-- TAMBAHKAN INI
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      priceCold: json['price_cold'] != null
          ? double.parse(json['price_cold'].toString())
          : null,
      imageUrl: json['image_url'],
      stock: json['stock'],
    );
  }
}