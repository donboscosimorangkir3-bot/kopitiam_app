import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/models/notification_model.dart';
import 'package:kopitiam_app/data/datasources/notification_remote_datasource.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Fungsi untuk mengambil data dari API Laravel
  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await NotificationRemoteDatasource().getNotifications();
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat notifikasi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA), // Warna cream dashboard
      appBar: AppBar(
        title: Text(
          "Notifikasi",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
        actions: [
          IconButton(
            onPressed: _fetchNotifications,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Segarkan",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: AppColors.primaryGreen,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _buildNotificationCard(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    IconData icon;
    Color iconColor;

    // Logika pemilihan ikon berdasarkan tipe dari database
    switch (item.type) {
      case 'pesanan':
        icon = Icons.shopping_bag_rounded;
        iconColor = AppColors.primaryGreen;
        break;
      case 'promo':
        icon = Icons.local_offer_rounded;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.info_rounded;
        iconColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Jika belum dibaca, beri border hijau tipis
        border: item.isRead
            ? Border.all(color: Colors.grey.shade200)
            : Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lingkaran Ikon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          // Isi Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    // Titik Merah jika belum dibaca
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(item.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk memformat waktu (Contoh: 5 mnt lalu / 12 Jan, 10:00)
  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mnt lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam lalu";
    return DateFormat('dd MMM, HH:mm').format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada notifikasi",
            style: GoogleFonts.poppins(
              color: Colors.grey, 
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Info pesanan dan promo akan muncul di sini.",
            style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}