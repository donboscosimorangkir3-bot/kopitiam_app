// lib/presentation/pages/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isEditingPassword = false;

  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // ==============================
  // SAVE PROFILE
  // ==============================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthRemoteDatasource();

      bool success = await authService.updateProfile(
        _nameController.text,
        _emailController.text,
        _phoneController.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil berhasil diperbarui!"),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal memperbarui profil.",
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      debugPrint("Update Profil Error: ${e.response?.data}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal: ${e.response?.data['message'] ?? 'Terjadi kesalahan.'}",
            style: const TextStyle(color: AppColors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==============================
  // CHANGE PASSWORD
  // ==============================
  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmNewPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua field password harus diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password baru tidak cocok."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthRemoteDatasource();

      bool success = await authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _confirmNewPasswordController.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password berhasil diubah. Silakan login ulang."),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        await authService.logout();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal mengubah password. Cek password lama Anda.",
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      debugPrint("Ubah Password Error: ${e.response?.data}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal: ${e.response?.data['message'] ?? 'Terjadi kesalahan.'}",
            style: const TextStyle(color: AppColors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==============================
  // UI
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text(
          "Edit Profil",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Informasi Akun",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _nameController,
                labelText: "Nama Lengkap",
                icon: Icons.person_outline,
                validator: (v) =>
                    v!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),

              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _emailController,
                labelText: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v!.isEmpty ? "Email tidak boleh kosong" : null,
              ),

              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _phoneController,
                labelText: "Nomor Telepon",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v!.isEmpty ? "Nomor telepon tidak boleh kosong" : null,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.white)
                      : Text(
                          "Simpan Profil",
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "Ubah Password",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),

              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _currentPasswordController,
                labelText: "Password Lama",
                icon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),

              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _newPasswordController,
                labelText: "Password Baru",
                icon: Icons.lock_open_outlined,
                isPassword: true,
                isPasswordVisible: _isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),

              const SizedBox(height: 20),

              _buildTextFormField(
                controller: _confirmNewPasswordController,
                labelText: "Konfirmasi Password Baru",
                icon: Icons.lock_open_outlined,
                isPassword: true,
                isPasswordVisible: _isConfirmNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isConfirmNewPasswordVisible =
                        !_isConfirmNewPasswordVisible;
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.security_update_outlined),
                  label: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.white)
                      : Text(
                          "Ubah Password",
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================
  // FORM FIELD WIDGET
  // ==============================
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: isPassword && !isPasswordVisible,
      style: GoogleFonts.poppins(color: AppColors.darkBrown),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: GoogleFonts.poppins(color: AppColors.darkBrown),
        hintStyle: GoogleFonts.poppins(color: AppColors.greyText),
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        suffixIcon: isPassword && toggleVisibility != null
            ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: AppColors.primaryGreen,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}