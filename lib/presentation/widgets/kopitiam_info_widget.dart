// lib/presentation/widgets/kopitiam_info_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KopitiamInfoWidget extends StatelessWidget {
  const KopitiamInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tentang Kopitiam33",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Kopitiam33 menyajikan pengalaman ngopi tradisional dengan sentuhan modern. Kami berkomitmen untuk menyajikan kopi terbaik dari biji pilihan dan makanan pendamping yang lezat.",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Text(
            "Jam Operasional:",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Setiap Hari: 07.00 - 22.00 WIB",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Text(
            "Alamat:",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Jl. Kopi Nikmat No. 33, Pusat Kota",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}