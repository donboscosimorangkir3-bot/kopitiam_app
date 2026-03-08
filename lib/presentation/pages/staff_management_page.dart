// lib/presentation/pages/staff_management_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/staff_remote_datasource.dart'; // Nanti kita buat
import 'package:kopitiam_app/data/models/user_model.dart'; // Gunakan User model
import 'package:kopitiam_app/presentation/pages/staff_form_page.dart'; // Nanti kita buat

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  late Future<List<User>> _staffFuture;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  // Fungsi untuk memuat ulang daftar staf
  Future<void> _fetchStaff() async {
    _staffFuture = StaffRemoteDatasource().getStaff();
    setState(() {});
  }

  // Fungsi untuk menghapus staf
  Future<void> _deleteStaff(int staffId, String staffName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Staf?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Anda yakin ingin menghapus staf '$staffName'?", style: GoogleFonts.poppins()),
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
        SnackBar(content: Text("Menghapus staf '$staffName'...")),
      );
      final success = await StaffRemoteDatasource().deleteStaff(staffId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Staf '$staffName' berhasil dihapus")),
        );
        _fetchStaff(); // Muat ulang daftar staf
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus staf.", style: TextStyle(color: AppColors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Manajemen Staf", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StaffFormPage()), // Ke halaman tambah staf
              );
              _fetchStaff(); // Refresh setelah kembali dari form
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStaff,
        color: AppColors.primaryGreen,
        backgroundColor: AppColors.lightCream,
        child: FutureBuilder<List<User>>(
          future: _staffFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: AppColors.darkBrown)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text("Belum ada staf. Tambahkan sekarang!", style: TextStyle(color: AppColors.greyText)));
            }

            final staffList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return _buildStaffCard(staff);
              },
            );
          },
        ),
      ),
    );
  }

  // WIDGET KARTU STAF UNTUK MANAJEMEN
  Widget _buildStaffCard(User staff) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar( // Tampilan avatar staf
              radius: 30,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              child: Icon(
                staff.role == 'admin' ? Icons.security : Icons.person_outline,
                size: 30,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.darkBrown,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staff.email,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.greyText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${staff.role.toUpperCase()}',
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                      MaterialPageRoute(builder: (context) => StaffFormPage(staff: staff)), // Ke halaman edit staf
                    );
                    _fetchStaff(); // Refresh setelah kembali dari form
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStaff(staff.id, staff.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}