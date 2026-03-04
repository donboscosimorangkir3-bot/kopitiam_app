// lib/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    _currentUser = await AuthRemoteDatasource().getUserInfo();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Profil Saya", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _currentUser == null
              ? Center(
                  child: Text(
                    "Gagal memuat profil. Silakan login ulang.",
                    style: GoogleFonts.poppins(color: AppColors.darkBrown),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                        backgroundImage: _currentUser!.profileImageUrl != null && _currentUser!.profileImageUrl!.isNotEmpty
                            ? NetworkImage(_currentUser!.profileImageUrl!) as ImageProvider
                            : null,
                        child: _currentUser!.profileImageUrl == null || _currentUser!.profileImageUrl!.isEmpty
                            ? Icon(Icons.person, size: 60, color: AppColors.primaryGreen)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _currentUser!.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentUser!.email,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_currentUser!.phone != null && _currentUser!.phone!.isNotEmpty)
                        Text(
                          _currentUser!.phone!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.greyText,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Divider(color: AppColors.primaryGreen.withOpacity(0.5)),
                      _buildProfileInfoRow(Icons.security, "Role", _currentUser!.role.toUpperCase()),
                      _buildProfileInfoRow(Icons.calendar_today, "Bergabung Sejak", "Tanggal"), // TODO: Tambahkan created_at jika ada di model user
                      const SizedBox(height: 20),
                      // Tombol Edit Profil (Opsional)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Fitur Edit Profil")),
                            );
                            // TODO: Navigasi ke halaman Edit Profile
                          },
                          icon: const Icon(Icons.edit, color: AppColors.white),
                          label: Text("Edit Profil", style: GoogleFonts.poppins(color: AppColors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.greyText),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBrown),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}