// lib/presentation/pages/category_form_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/category_remote_datasource.dart';
import 'package:kopitiam_app/data/models/category_model.dart';
import 'package:dio/dio.dart'; // Import Dio untuk error handling

class CategoryFormPage extends StatefulWidget {
  final Category? category; // Jika ada kategori, berarti mode Edit
  const CategoryFormPage({super.key, this.category});

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false; // Mode Edit atau Add

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _isEditing = true;
      _nameController.text = widget.category!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan/mengedit kategori
  void _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final CategoryRemoteDatasource categoryRemoteDatasource = CategoryRemoteDatasource();
        bool success;

        if (_isEditing) {
          // Mode Edit: Panggil updateCategory()
          success = await categoryRemoteDatasource.updateCategory(widget.category!.id, _nameController.text); // <-- PERBAIKAN INI
        } else {
          // Mode Add: Panggil createCategory()
          success = await categoryRemoteDatasource.createCategory(_nameController.text); // <-- PERBAIKAN INI
        }

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_isEditing ? "Kategori berhasil diperbarui!" : "Kategori berhasil ditambahkan!"),
                backgroundColor: AppColors.primaryGreen),
          );
          Navigator.pop(context, true); // Kembali ke halaman sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Gagal menyimpan kategori.", style: TextStyle(color: AppColors.white)),
                backgroundColor: Colors.red),
          );
        }
      } on DioException catch (e) {
        print("Form Kategori Error: ${e.response?.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Gagal: ${e.response?.data['message'] ?? 'Terjadi kesalahan.'}", style: TextStyle(color: AppColors.white)),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Kategori" : "Tambah Kategori", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input Nama Kategori
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: AppColors.darkBrown),
                decoration: InputDecoration(
                  labelText: "Nama Kategori",
                  hintText: "Contoh: Makanan, Minuman",
                  labelStyle: GoogleFonts.poppins(color: AppColors.darkBrown),
                  hintStyle: GoogleFonts.poppins(color: AppColors.greyText),
                  prefixIcon: const Icon(Icons.category, color: AppColors.primaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGreen.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGreen.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                  ),
                ),
                validator: (value) => value!.isEmpty ? "Nama kategori tidak boleh kosong" : null,
              ),
              const SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.save_outlined, size: 24),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : Text(
                          _isEditing ? "Simpan Perubahan" : "Tambah Kategori",
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}