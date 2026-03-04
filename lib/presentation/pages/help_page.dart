// lib/presentation/pages/help_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Bantuan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "FAQ (Pertanyaan Umum)",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              "Bagaimana cara memesan?",
              "Pilih menu yang Anda inginkan, masukkan ke keranjang, lalu lanjutkan ke pembayaran.",
            ),
            _buildFaqItem(
              context,
              "Metode pembayaran apa saja yang diterima?",
              "Kami menerima pembayaran via QRIS yang terhubung dengan berbagai e-wallet dan mobile banking.",
            ),
            _buildFaqItem(
              context,
              "Bagaimana cara melacak pesanan saya?",
              "Anda bisa melihat status pesanan di menu 'Riwayat Transaksi' setelah login.",
            ),
            const SizedBox(height: 30),
            Text(
              "Hubungi Kami",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primaryGreen),
              title: Text("Nomor Telepon", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
              subtitle: Text("0812-3456-7890", style: GoogleFonts.poppins(color: AppColors.greyText)),
              onTap: () {
                // TODO: Buka dialer telepon
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: AppColors.primaryGreen),
              title: Text("Email", style: GoogleFonts.poppins(color: AppColors.darkBrown)),
              subtitle: Text("support@kopitiam33.com", style: GoogleFonts.poppins(color: AppColors.greyText)),
              onTap: () {
                // TODO: Buka aplikasi email
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.darkBrown,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            answer,
            style: GoogleFonts.poppins(color: AppColors.greyText),
          ),
        ),
      ],
    );
  }
}