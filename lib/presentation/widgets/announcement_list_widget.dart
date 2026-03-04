// lib/presentation/widgets/announcement_list_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/announcement_remote_datasource.dart';
import 'package:kopitiam_app/data/models/announcement_model.dart';

class AnnouncementListWidget extends StatefulWidget {
  const AnnouncementListWidget({super.key});

  @override
  State<AnnouncementListWidget> createState() =>
      _AnnouncementListWidgetState();
}

class _AnnouncementListWidgetState extends State<AnnouncementListWidget> {
  late Future<List<Announcement>> _announcementsFuture;
  final PageController _pageController =
      PageController(viewportFraction: 0.88);
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    _announcementsFuture =
        AnnouncementRemoteDatasource().getAnnouncements();
    setState(() {});
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// TITLE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Pengumuman & Promo",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
        ),

        const SizedBox(height: 12),

        FutureBuilder<List<Announcement>>(
          future: _announcementsFuture,
          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildInfoText("Terjadi kesalahan memuat data.");
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildInfoText("Tidak ada pengumuman.");
            }

            final activeAnnouncements = snapshot.data!
                .where((a) =>
                    a.isActive &&
                    (a.expiredAt == null ||
                        a.expiredAt!.isAfter(DateTime.now())))
                .toList();

            if (activeAnnouncements.isEmpty) {
              return _buildInfoText("Tidak ada pengumuman aktif.");
            }

            return Column(
              children: [

                /// CAROUSEL
                SizedBox(
                  height: 210,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: activeAnnouncements.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildAnnouncementCard(
                            activeAnnouncements[index]),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                /// DOT INDICATOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    activeAnnouncements.length,
                    (index) => AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4),
                      width: _currentIndex == index ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? AppColors.primaryGreen
                            : AppColors.greyText
                                .withOpacity(0.4),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 20),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: AppColors.greyText,
          ),
        ),
      ),
    );
  }

  /// CARD ANNOUNCEMENT (BISA DITEKAN)
  Widget _buildAnnouncementCard(Announcement announcement) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(announcement),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.white,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              /// IMAGE
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: announcement.imageUrl != null &&
                        announcement.imageUrl!.isNotEmpty
                    ? Image.network(
                        announcement.imageUrl!,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),

              /// CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        announcement.title,
                        style: GoogleFonts.poppins(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                          color:
                              AppColors.darkBrown,
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      Expanded(
                        child: Text(
                          announcement.content,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                AppColors.greyText,
                          ),
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),

                      Align(
                        alignment:
                            Alignment.bottomRight,
                        child: Text(
                          _formatDate(
                              announcement
                                  .publishedAt),
                          style:
                              GoogleFonts.poppins(
                            fontSize: 10,
                            color:
                                AppColors.greyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 110,
      width: double.infinity,
      color: AppColors.lightCream,
      child: const Center(
        child: Icon(Icons.campaign,
            size: 40,
            color: AppColors.primaryGreen),
      ),
    );
  }

  /// DETAIL POPUP (BOTTOM SHEET)
  void _showDetail(Announcement announcement) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  announcement.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  announcement.content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Dipublikasikan: ${_formatDate(announcement.publishedAt)}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}