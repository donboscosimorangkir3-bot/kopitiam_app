// lib/data/models/product_model.dart
import 'package:kopitiam_app/data/models/category_model.dart';

class Product {
  final int id;
  final int category_id;
  final String name;
  final String? description;
  final double price;
  final double? priceCold;
  final String? imageUrl;
  final int stock;
  final Category? category;
  final String? updatedAt; // TAMBAH INI

  Product({
    required this.id,
    required this.category_id,
    required this.name,
    this.description,
    required this.price,
    this.priceCold,
    this.imageUrl,
    required this.stock,
    this.category,
    this.updatedAt, // TAMBAH INI
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      category_id: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      priceCold: json['price_cold'] != null
          ? double.parse(json['price_cold'].toString())
          : null,
      imageUrl: json['image_url'],
      stock: json['stock'],
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      updatedAt: json['updated_at'], // TAMBAH INI
    );
  }
}