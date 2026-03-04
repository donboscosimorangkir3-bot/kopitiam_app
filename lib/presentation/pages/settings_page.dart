// lib/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Pengaturan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.notifications, color: AppColors.darkBrown),
            title: Text("Notifikasi", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
            trailing: Switch(
              value: true, // Placeholder
              onChanged: (bool value) {
                // TODO: Logika ubah notifikasi
              },
              activeColor: AppColors.primaryGreen,
            ),
            onTap: () {
              // TODO: Navigasi ke pengaturan notifikasi lebih detail
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.darkBrown),
            title: Text("Bahasa", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
            subtitle: Text("Indonesia", style: GoogleFonts.poppins(color: AppColors.greyText)),
            onTap: () {
              // TODO: Navigasi ke pengaturan bahasa
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.darkBrown),
            title: Text("Tentang Aplikasi", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Versi Aplikasi 1.0")),
              );
            },
          ),
        ],
      ),
    );
  }
}