import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/staff_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:dio/dio.dart';

class StaffFormPage extends StatefulWidget {
  final User? staff;

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

  bool _isLoading = false;
  bool _isEditing = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final String _role = "cashier";

  @override
  void initState() {
    super.initState();

    if (widget.staff != null) {
      _isEditing = true;

      _nameController.text = widget.staff!.name;
      _emailController.text = widget.staff!.email;
      _phoneController.text = widget.staff!.phone ?? '';
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

  void _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final staffRemoteDatasource = StaffRemoteDatasource();

      final Map<String, dynamic> data = {
        "name": _nameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "role": _role,
      };

      if (_passwordController.text.isNotEmpty) {
        data["password"] = _passwordController.text;
        data["password_confirmation"] = _confirmPasswordController.text;
      }

      bool success;

      if (_isEditing) {
        success = await staffRemoteDatasource.updateStaff(widget.staff!.id, data);
      } else {
        success = await staffRemoteDatasource.createStaff(data);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? "Staf berhasil diperbarui" : "Staf berhasil ditambahkan",
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menyimpan staf"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data["message"] ?? "Terjadi kesalahan",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? "Edit Staf" : "Tambah Staf",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// HEADER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1,
                      color: AppColors.primaryGreen, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? "Perbarui informasi staf kasir"
                          : "Tambahkan staf kasir baru ke sistem",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// FORM CONTAINER
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    _buildTextField(
                      controller: _nameController,
                      label: "Nama Staf",
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v!.isEmpty ? "Nama tidak boleh kosong" : null,
                    ),

                    const SizedBox(height: 18),

                    _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v!.isEmpty ? "Email tidak boleh kosong" : null,
                    ),

                    const SizedBox(height: 18),

                    _buildTextField(
                      controller: _phoneController,
                      label: "Nomor Telepon",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v!.isEmpty ? "Nomor telepon tidak boleh kosong" : null,
                    ),

                    const SizedBox(height: 18),

                    _buildPasswordField(),

                    const SizedBox(height: 18),

                    _buildConfirmPasswordField(),

                    const SizedBox(height: 30),

                    SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton.icon(
    onPressed: _isLoading ? null : _saveStaff,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white, // memperbaiki warna teks
      elevation: 3,
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    icon: _isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.save, color: Colors.white),
    label: Text(
      _isEditing ? "Simpan Perubahan" : "Tambah Staf",
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: (value) {
        if (!_isEditing && value!.isEmpty) {
          return "Password tidak boleh kosong";
        }
        if (value!.isNotEmpty && value.length < 8) {
          return "Password minimal 8 karakter";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: _isEditing ? "Password Baru (Opsional)" : "Password",
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryGreen),
        suffixIcon: IconButton(
          icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      validator: (value) {
        if (_passwordController.text.isNotEmpty &&
            value != _passwordController.text) {
          return "Konfirmasi password tidak cocok";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: "Konfirmasi Password",
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryGreen),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword
              ? Icons.visibility
              : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}