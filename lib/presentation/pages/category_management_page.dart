// lib/presentation/pages/category_management_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/category_remote_datasource.dart';
import 'package:kopitiam_app/data/models/category_model.dart';
import 'package:kopitiam_app/presentation/pages/category_form_page.dart'; // Import halaman form kategori

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Fungsi untuk memuat ulang daftar kategori
  Future<void> _fetchCategories() async {
    _categoriesFuture = CategoryRemoteDatasource().getCategories();
    setState(() {});
  }

  // Fungsi untuk menghapus kategori
  Future<void> _deleteCategory(int categoryId, String categoryName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Kategori?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Anda yakin ingin menghapus kategori '$categoryName'? Semua produk di kategori ini harus dipindahkan terlebih dahulu.", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Batal", style: GoogleFonts.poppins(color: AppColors.darkBrown))),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Hapus", style: GoogleFonts.poppins(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Menghapus kategori '$categoryName'...")),
      );
      final success = await CategoryRemoteDatasource().deleteCategory(categoryId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kategori '$categoryName' berhasil dihapus")),
        );
        _fetchCategories(); // Muat ulang daftar kategori
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus kategori. Pastikan tidak ada produk terkait.", style: TextStyle(color: AppColors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Manajemen Kategori", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryFormPage()), // Ke halaman tambah kategori
              );
              _fetchCategories(); // Refresh setelah kembali dari form
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategories,
        color: AppColors.primaryGreen,
        backgroundColor: AppColors.lightCream,
        child: FutureBuilder<List<Category>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: AppColors.darkBrown)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text("Belum ada kategori. Tambahkan sekarang!", style: TextStyle(color: AppColors.greyText)));
            }

            final categories = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(category);
              },
            );
          },
        ),
      ),
    );
  }

  // WIDGET KARTU KATEGORI UNTUK MANAJEMEN
  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.category_outlined, size: 40, color: AppColors.primaryGreen), // Icon kategori
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.darkBrown,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Tombol Edit & Hapus
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CategoryFormPage(category: category)), // Ke halaman edit kategori
                    );
                    _fetchCategories(); // Refresh setelah kembali dari form
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCategory(category.id, category.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}