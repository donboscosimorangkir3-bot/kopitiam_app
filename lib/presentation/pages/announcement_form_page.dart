// lib/presentation/pages/announcement_form_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/announcement_remote_datasource.dart';
import 'package:kopitiam_app/data/models/announcement_model.dart';
import 'package:dio/dio.dart'; // Import Dio untuk MultipartFile

class AnnouncementFormPage extends StatefulWidget {
  final Announcement? announcement; // Jika ada, mode Edit
  const AnnouncementFormPage({super.key, this.announcement});

  @override
  State<AnnouncementFormPage> createState() => _AnnouncementFormPageState();
}

class _AnnouncementFormPageState extends State<AnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _publishedAtController = TextEditingController();
  final TextEditingController _expiredAtController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isActive = true;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _isEditing = true;
      _titleController.text = widget.announcement!.title;
      _contentController.text = widget.announcement!.content;
      _isActive = widget.announcement!.isActive;
      _currentImageUrl = widget.announcement!.imageUrl;
      if (widget.announcement!.publishedAt != null) {
        _publishedAtController.text = DateFormat('yyyy-MM-dd').format(widget.announcement!.publishedAt!);
      }
      if (widget.announcement!.expiredAt != null) {
        _expiredAtController.text = DateFormat('yyyy-MM-dd').format(widget.announcement!.expiredAt!);
      }
    } else {
      _publishedAtController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Default today
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _publishedAtController.dispose();
    _expiredAtController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    setState(() {
      if (image != null) {
        _imageFile = File(image.path);
        _currentImageUrl = null;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final AnnouncementRemoteDatasource announcementRemoteDatasource = AnnouncementRemoteDatasource();
        bool success;

        final Map<String, dynamic> data = {
          'title': _titleController.text,
          'content': _contentController.text,
          // PENTING: Ubah _isActive (boolean) menjadi 1 atau 0 (integer)
          'is_active': _isActive ? 1 : 0, // <-- PERBAIKAN INI
          'published_at': _publishedAtController.text.isEmpty ? null : _publishedAtController.text,
          'expired_at': _expiredAtController.text.isEmpty ? null : _expiredAtController.text,
        };

        if (_imageFile != null) {
          data['image'] = await MultipartFile.fromFile(_imageFile!.path, filename: _imageFile!.path.split('/').last);
        } else if (_isEditing && _currentImageUrl == null && widget.announcement?.imageUrl != null) {
          data['clear_image'] = 'true';
        }

        if (_isEditing) {
          success = await announcementRemoteDatasource.updateAnnouncement(widget.announcement!.id, data);
        } else {
          success = await announcementRemoteDatasource.createAnnouncement(data);
        }

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_isEditing ? "Pengumuman berhasil diperbarui!" : "Pengumuman berhasil ditambahkan!"),
                backgroundColor: AppColors.primaryGreen),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Gagal menyimpan pengumuman.", style: TextStyle(color: AppColors.white)),
                backgroundColor: Colors.red),
          );
        }
      } on DioException catch (e) {
        print("Form Pengumuman Error: ${e.response?.data}");
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
        title: Text(_isEditing ? "Edit Pengumuman" : "Tambah Pengumuman", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              // Input Judul
              _buildTextFormField(
                controller: _titleController,
                labelText: "Judul Pengumuman",
                hintText: "Contoh: Diskon Kopi Akhir Bulan!",
                icon: Icons.title,
                validator: (value) => value!.isEmpty ? "Judul tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),

              // Input Konten
              _buildTextFormField(
                controller: _contentController,
                labelText: "Isi Pengumuman",
                hintText: "Contoh: Nikmati potongan harga...",
                icon: Icons.description,
                maxLines: 5,
                validator: (value) => value!.isEmpty ? "Isi pengumuman tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),

              // Pilihan Aktif/Tidak Aktif
              SwitchListTile(
                title: Text("Aktif", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
                value: _isActive,
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: AppColors.primaryGreen,
                secondary: const Icon(Icons.toggle_on, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 20),

              // Tanggal Publikasi
              TextFormField(
                controller: _publishedAtController,
                readOnly: true,
                onTap: () => _selectDate(context, _publishedAtController),
                style: GoogleFonts.poppins(color: AppColors.darkBrown),
                decoration: InputDecoration(
                  labelText: "Tanggal Publikasi",
                  hintText: "YYYY-MM-DD",
                  labelStyle: GoogleFonts.poppins(color: AppColors.darkBrown),
                  prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                  ),
                ),
                validator: (value) => value!.isEmpty ? "Tanggal publikasi tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),

              // Tanggal Kadaluarsa (Opsional)
              TextFormField(
                controller: _expiredAtController,
                readOnly: true,
                onTap: () => _selectDate(context, _expiredAtController),
                style: GoogleFonts.poppins(color: AppColors.darkBrown),
                decoration: InputDecoration(
                  labelText: "Tanggal Kadaluarsa (Opsional)",
                  hintText: "YYYY-MM-DD",
                  labelStyle: GoogleFonts.poppins(color: AppColors.darkBrown),
                  prefixIcon: const Icon(Icons.calendar_month, color: AppColors.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                  ),
                ),
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
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_currentImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildImagePlaceholder()),
                            )
                          : _buildImagePlaceholder()),
                ),
              ),
              const SizedBox(height: 10),
              if (_isEditing && _currentImageUrl != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _imageFile = null;
                      _currentImageUrl = null;
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
                  onPressed: _isLoading ? null : _saveAnnouncement,
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
                          _isEditing ? "Simpan Perubahan" : "Tambah Pengumuman",
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
        Text("Pilih Gambar Pengumuman", style: GoogleFonts.poppins(color: AppColors.primaryGreen)),
      ],
    );
  }
}