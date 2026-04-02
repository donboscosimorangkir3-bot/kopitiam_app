// lib/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  User? _currentUser;
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fetchUserProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    final user = await AuthRemoteDatasource().getUserInfo();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
    _animController.forward(from: 0);
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Pemilik';
      case 'admin':
        return 'Admin';
      case 'cashier':
        return 'Kasir';
      default:
        return 'Pelanggan';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.amber.shade700;
      case 'admin':
        return Colors.blue.shade600;
      case 'cashier':
        return Colors.purple.shade500;
      default:
        return AppColors.primaryGreen;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Icons.workspace_premium_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'cashier':
        return Icons.point_of_sale_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                      strokeWidth: 2.5,
                    ),
                  )
                : _currentUser == null
                    ? _buildErrorState()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                // ── AVATAR SECTION ──
                                _buildAvatarSection(),

                                // ── INFO CARDS ──
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 24),
                                  child: Column(
                                    children: [
                                      _buildInfoCard(),
                                      const SizedBox(height: 14),
                                      _buildEditButton(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 4),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profil Saya",
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "Informasi akun kamu",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // AVATAR SECTION
  // ─────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    final user = _currentUser!;
    final name = user.name;
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();
    final roleColor = _getRoleColor(user.role);
    final roleLabel = _getRoleLabel(user.role);
    final roleIcon = _getRoleIcon(user.role);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.75),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: user.profileImageUrl != null &&
                          user.profileImageUrl!.isNotEmpty
                      ? Image.network(
                          user.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildInitialsAvatar(initials),
                        )
                      : _buildInitialsAvatar(initials),
                ),
              ),
              // Online dot
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Nama
          Text(
            name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.78),
            ),
          ),

          const SizedBox(height: 12),

          // Role badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // INFO CARD
  // ─────────────────────────────────────────────────
  Widget _buildInfoCard() {
    final user = _currentUser!;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primaryGreen,
            label: "Nama Lengkap",
            value: user.name,
            isFirst: true,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.email_outlined,
            iconColor: Colors.blue.shade500,
            label: "Email",
            value: user.email,
          ),
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              iconColor: Colors.teal.shade500,
              label: "Nomor Telepon",
              value: user.phone!,
            ),
          ],
          _buildDivider(),
          _buildInfoRow(
            icon: _getRoleIcon(user.role),
            iconColor: _getRoleColor(user.role),
            label: "Role Akun",
            value: _getRoleLabel(user.role),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16,
    );
  }

  // ─────────────────────────────────────────────────
  // EDIT BUTTON
  // ─────────────────────────────────────────────────
  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProfilePage(user: _currentUser!),
          ),
        );
        if (result == true) {
          _fetchUserProfile();
        }
      },
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryGreen.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.38),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              "Edit Profil",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // ERROR STATE
  // ─────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_off_outlined,
                  size: 38, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text(
              "Gagal Memuat Profil",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Silakan login ulang untuk\nmelihat profilmu.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() => _isLoading = true);
                _fetchUserProfile();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Coba Lagi",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}