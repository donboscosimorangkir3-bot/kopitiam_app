// lib/presentation/widgets/kopitiam_info_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/setting_remote_datasource.dart'; // Import datasource
import 'package:kopitiam_app/data/models/setting_model.dart'; // Import model

class KopitiamInfoWidget extends StatefulWidget {
  const KopitiamInfoWidget({super.key});

  @override
  State<KopitiamInfoWidget> createState() => _KopitiamInfoWidgetState();
}

class _KopitiamInfoWidgetState extends State<KopitiamInfoWidget> {
  late Future<CafeSettings?> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = SettingRemoteDatasource().getSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FutureBuilder<CafeSettings?>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Text("Gagal memuat informasi kafe.", style: GoogleFonts.poppins(color: Colors.red));
          }

          final settings = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tentang ${settings.cafeName}", // Nama dinamis
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                settings.cafeDescription, // Deskripsi dinamis
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.access_time, "Jam Operasional", settings.cafeOperationHours),
              _buildInfoRow(Icons.location_on, "Alamat", settings.cafeAddress),
              _buildInfoRow(Icons.phone, "Telepon", settings.cafePhone),
            ],
          );
        },
      ),
    );
  }

  // Helper widget untuk baris info
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.darkBrown),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(color: AppColors.greyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}