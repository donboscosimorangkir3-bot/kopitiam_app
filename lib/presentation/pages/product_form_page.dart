// lib/presentation/pages/product_form_page.dart

import 'dart:io'; // Untuk File gambar
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Untuk pilih gambar
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/category_remote_datasource.dart';
import 'package:kopitiam_app/data/datasources/product_remote_datasource.dart';
import 'package:kopitiam_app/data/models/category_model.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:dio/dio.dart'; // Import Dio untuk MultipartFile

class ProductFormPage extends StatefulWidget {
  final Product? product; // Jika ada produk, berarti mode Edit
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _priceColdController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  Category? _selectedCategory;
  File? _imageFile; // Gambar yang dipilih dari galeri
  bool _isLoading = false;
  bool _isEditing = false; // Mode Edit atau Add
  String? _currentImageUrl; // URL gambar yang ada saat ini (untuk mode edit)

  late Future<List<Category>> _categoriesFuture; // Untuk dropdown kategori

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryRemoteDatasource().getCategories();
    if (widget.product != null) {
      _isEditing = true;
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _priceColdController.text = widget.product!.priceCold?.toString() ?? '';
      _stockController.text = widget.product!.stock.toString();
      _currentImageUrl = widget.product!.imageUrl; // Simpan URL gambar saat ini
      // Untuk kategori, kita akan set setelah _categoriesFuture selesai
      _categoriesFuture.then((categories) {
        setState(() {
          _selectedCategory = categories.firstWhere(
            (cat) => cat.id == widget.product!.category_id,
            orElse: () => categories.first, // Default jika tidak ketemu
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _priceColdController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // Kualitas gambar 70%
    setState(() {
      if (image != null) {
        _imageFile = File(image.path);
        _currentImageUrl = null; // Jika ada gambar baru, hapus tampilan gambar lama
      }
    });
  }

  // Fungsi untuk menyimpan/mengedit produk
  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silakan pilih kategori!"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final ProductRemoteDatasource productRemoteDatasource = ProductRemoteDatasource();
        bool success;

        // Siapkan data untuk dikirim
        final Map<String, dynamic> data = {
          'category_id': _selectedCategory!.id,
          'name': _nameController.text,
          'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
          'price': double.parse(_priceController.text),
          'price_cold': _priceColdController.text.isEmpty ? null : double.parse(_priceColdController.text),
          'stock': int.parse(_stockController.text),
        };

        // Jika ada gambar baru yang dipilih, tambahkan ke data
        if (_imageFile != null) {
          data['image'] = await MultipartFile.fromFile(_imageFile!.path, filename: _imageFile!.path.split('/').last);
        } else if (_isEditing && _currentImageUrl == null) {
          // Jika mode edit dan gambar sebelumnya sudah dihapus, kirim flag ke backend
          data['clear_image'] = 'true';
        }


        if (_isEditing) {
          // Mode Edit
          success = await productRemoteDatasource.updateProduct(widget.product!.id, data);
        } else {
          // Mode Add
          success = await productRemoteDatasource.addProduct(data);
        }

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_isEditing ? "Produk berhasil diperbarui!" : "Produk berhasil ditambahkan!"),
                backgroundColor: AppColors.primaryGreen),
          );
          Navigator.pop(context, true); // Kembali ke halaman sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Gagal menyimpan produk.", style: TextStyle(color: AppColors.white)),
                backgroundColor: Colors.red),
          );
        }
      } on DioException catch (e) {
        print("Form Error: ${e.response?.data}");
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
        title: Text(_isEditing ? "Edit Produk" : "Tambah Produk", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              // Input Kategori
              FutureBuilder<List<Category>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error memuat kategori: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("Tidak ada kategori. Tambahkan kategori terlebih dahulu.", style: TextStyle(color: Colors.red));
                  }

                  // Jika mode edit, set selected category (jika belum diset)
                  if (_isEditing && _selectedCategory == null && widget.product?.category_id != null) {
                    try {
                      _selectedCategory = snapshot.data!.firstWhere((cat) => cat.id == widget.product!.category_id);
                    } catch (e) {
                      _selectedCategory = null; // Jika kategori tidak ditemukan
                    }
                  } else if (!_isEditing && _selectedCategory == null && snapshot.data!.isNotEmpty) {
                    // Default selected category untuk mode tambah jika belum ada
                    _selectedCategory = snapshot.data!.first;
                  }


                  return DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    hint: Text("Pilih Kategori", style: GoogleFonts.poppins(color: AppColors.greyText)),
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      labelStyle: GoogleFonts.poppins(color: AppColors.darkBrown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category, color: AppColors.primaryGreen),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                    items: snapshot.data!.map((category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.name, style: GoogleFonts.poppins(color: AppColors.darkBrown)),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) => value == null ? "Kategori tidak boleh kosong" : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Input Nama Produk
              _buildTextFormField(
                controller: _nameController,
                labelText: "Nama Produk",
                hintText: "Contoh: Kopi O Kosong",
                icon: Icons.local_cafe_outlined,
                validator: (value) => value!.isEmpty ? "Nama produk tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),

              // Input Deskripsi
              _buildTextFormField(
                controller: _descriptionController,
                labelText: "Deskripsi",
                hintText: "Contoh: Kopi hitam tradisional tanpa gula",
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Input Harga Panas
              _buildTextFormField(
                controller: _priceController,
                labelText: "Harga (Panas/Default)",
                hintText: "Contoh: 10000",
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Harga tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),

              // Input Harga Dingin (opsional)
              _buildTextFormField(
                controller: _priceColdController,
                labelText: "Harga Dingin (Opsional)",
                hintText: "Contoh: 12000",
                icon: Icons.ac_unit,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Input Stok
              _buildTextFormField(
                controller: _stockController,
                labelText: "Stok",
                hintText: "Contoh: 50",
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Stok tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),

              // Upload Gambar
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGreen),
                  ),
                  child: _imageFile != null // Jika ada gambar baru yang dipilih
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty // Jika ada gambar lama dari backend
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _currentImageUrl!, 
                                fit: BoxFit.cover, 
                                // Tambahkan cache-busting parameter untuk memastikan gambar terbaru terload
                                key: ValueKey(_currentImageUrl!), // Ini penting untuk memaksa refresh Image.network
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: AppColors.primaryGreen,
                                    ),
                                  );
                                },
                                errorBuilder: (c, e, s) => _buildImagePlaceholder(), // Jika error, tampilkan placeholder
                              ),
                            )
                          : _buildImagePlaceholder()), // Placeholder jika tidak ada gambar sama sekali
                ),
              ),
              const SizedBox(height: 10),
              if (_isEditing && _currentImageUrl != null) // Tombol hapus gambar lama
                TextButton(
                  onPressed: () {
                    setState(() {
                      _imageFile = null; // Hapus gambar baru yang mungkin dipilih
                      _currentImageUrl = null; // Hapus tampilan gambar lama
                    });
                  },
                  child: Text("Hapus Gambar Lama", style: GoogleFonts.poppins(color: Colors.red)),
                ),
              const SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProduct,
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
                          _isEditing ? "Simpan Perubahan" : "Tambah Produk",
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

  // Helper widget untuk input form
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: AppColors.darkBrown),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: GoogleFonts.poppins(color: AppColors.darkBrown),
        hintStyle: GoogleFonts.poppins(color: AppColors.greyText),
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
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
      validator: validator,
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 50, color: AppColors.primaryGreen),
        Text("Pilih Gambar Produk", style: GoogleFonts.poppins(color: AppColors.primaryGreen)),
      ],
    );
  }
}