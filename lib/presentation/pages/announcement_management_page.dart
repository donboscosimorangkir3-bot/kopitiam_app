// lib/presentation/pages/announcement_management_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/announcement_remote_datasource.dart';
import 'package:kopitiam_app/data/models/announcement_model.dart';
import 'package:kopitiam_app/presentation/pages/announcement_form_page.dart'; // Import halaman form pengumuman

class AnnouncementManagementPage extends StatefulWidget {
  const AnnouncementManagementPage({super.key});

  @override
  State<AnnouncementManagementPage> createState() => _AnnouncementManagementPageState();
}

class _AnnouncementManagementPageState extends State<AnnouncementManagementPage> {
  late Future<List<Announcement>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    _announcementsFuture = AnnouncementRemoteDatasource().getAnnouncements();
    setState(() {});
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Future<void> _deleteAnnouncement(int id, String title) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Pengumuman?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Anda yakin ingin menghapus pengumuman '$title'?", style: GoogleFonts.poppins()),
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
        SnackBar(content: Text("Menghapus pengumuman '$title'...")),
      );
      final success = await AnnouncementRemoteDatasource().deleteAnnouncement(id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pengumuman '$title' berhasil dihapus")),
        );
        _fetchAnnouncements();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus pengumuman.", style: TextStyle(color: AppColors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text("Manajemen Pengumuman", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnnouncementFormPage()),
              );
              _fetchAnnouncements();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAnnouncements,
        color: AppColors.primaryGreen,
        backgroundColor: AppColors.lightCream,
        child: FutureBuilder<List<Announcement>>(
          future: _announcementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: AppColors.darkBrown)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                  child: Text("Belum ada pengumuman. Tambahkan sekarang!", style: TextStyle(color: AppColors.greyText)));
            }

            final announcements = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return _buildAnnouncementCard(announcement);
              },
            );
          },
        ),
      ),
    );
  }

  // WIDGET KARTU PENGUMUMAN UNTUK MANAJEMEN
  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Pengumuman (jika ada)
            if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  announcement.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 40, color: AppColors.greyText);
                  },
                ),
              ),
            if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
              const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.darkBrown,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement.content,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.greyText),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(announcement.isActive ? Icons.check_circle : Icons.cancel, size: 16, color: announcement.isActive ? AppColors.primaryGreen : Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        announcement.isActive ? 'Aktif' : 'Tidak Aktif',
                        style: GoogleFonts.poppins(fontSize: 12, color: announcement.isActive ? AppColors.primaryGreen : Colors.red),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today, size: 16, color: AppColors.greyText),
                      const SizedBox(width: 4),
                      Text(
                        'Publikasi: ${_formatDate(announcement.publishedAt)}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.greyText),
                      ),
                    ],
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
                      MaterialPageRoute(builder: (context) => AnnouncementFormPage(announcement: announcement)), // Ke halaman edit
                    );
                    _fetchAnnouncements();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteAnnouncement(announcement.id, announcement.title),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}