// lib/data/models/category_model.dart

class Category {
  final int id;
  final String name;
  final String slug;
  final String? image; // URL ikon kategori, bisa kosong

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      image: json['image'],
    );
  }
}