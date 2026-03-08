// lib/presentation/pages/staff_form_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/staff_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:dio/dio.dart'; // Import Dio untuk error handling

class StaffFormPage extends StatefulWidget {
  final User? staff; // Jika ada staf, berarti mode Edit
  const StaffFormPage({super.key, this.staff});

  @override
  State<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedRole = 'cashier'; // Default role
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      _isEditing = true;
      _nameController.text = widget.staff!.name;
      _emailController.text = widget.staff!.email;
      _phoneController.text = widget.staff!.phone ?? '';
      _selectedRole = widget.staff!.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan/mengedit staf
  void _saveStaff() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final StaffRemoteDatasource staffRemoteDatasource = StaffRemoteDatasource();
        bool success;

        final Map<String, dynamic> data = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'role': _selectedRole,
        };

        // Tambahkan password hanya jika diisi (untuk mode Add atau reset password di mode Edit)
        if (_passwordController.text.isNotEmpty) {
          data['password'] = _passwordController.text;
          data['password_confirmation'] = _confirmPasswordController.text;
        }

        if (_isEditing) {
          success = await staffRemoteDatasource.updateStaff(widget.staff!.id, data);
        } else {
          success = await staffRemoteDatasource.createStaff(data);
        }

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_isEditing ? "Staf berhasil diperbarui!" : "Staf berhasil ditambahkan!"),
                backgroundColor: AppColors.primaryGreen),
          );
          Navigator.pop(context, true); // Kembali ke halaman sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Gagal menyimpan staf.", style: TextStyle(color: AppColors.white)),
                backgroundColor: Colors.red),
          );
        }
      } on DioException catch (e) {
        print("Form Staf Error: ${e.response?.data}");
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
        title: Text(_isEditing ? "Edit Staf" : "Tambah Staf", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              _buildTextFormField(
                controller: _nameController,
                labelText: "Nama Staf",
                icon: Icons.person_outline,
                validator: (value) => value!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _emailController,
                labelText: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? "Email tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _phoneController,
                labelText: "Nomor Telepon",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? "Nomor telepon tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              // Pilihan Role
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: "Role",
                  labelStyle: GoogleFonts.poppins(color: AppColors.darkBrown),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.security, color: AppColors.primaryGreen),
                ),
                items: ['admin', 'cashier'].map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role.toUpperCase(), style: GoogleFonts.poppins(color: AppColors.darkBrown)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Password (wajib saat add, opsional saat edit)
              _buildTextFormField(
                controller: _passwordController,
                labelText: _isEditing ? "Password Baru (Opsional)" : "Password",
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) {
                  if (!_isEditing && value!.isEmpty) {
                    return "Password tidak boleh kosong";
                  }
                  if (value!.isNotEmpty && value.length < 8) {
                    return "Password minimal 8 karakter";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _confirmPasswordController,
                labelText: "Konfirmasi Password",
                icon: Icons.lock_open_outlined,
                obscureText: true,
                validator: (value) {
                  if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
                    return "Konfirmasi password tidak cocok";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveStaff,
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
                          _isEditing ? "Simpan Perubahan" : "Tambah Staf",
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
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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
}