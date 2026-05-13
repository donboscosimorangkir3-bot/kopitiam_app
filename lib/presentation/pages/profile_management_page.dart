// lib/presentation/pages/profile_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';

class ProfileManagementPage extends StatefulWidget {
  final User user;
  const ProfileManagementPage({super.key, required this.user});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── State user lokal agar bisa diperbarui tanpa logout ──
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _currentUser.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ── Buka edit profil, tunggu result, lalu update state lokal ──
  Future<void> _openEditProfile() async {
    final updatedUser = await Navigator.push<User>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditProfilePage(user: _currentUser),
      ),
    );

    // Jika ada data baru yang dikembalikan dari edit page, langsung update UI
    if (updatedUser != null && mounted) {
      setState(() => _currentUser = updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildEditButton(),
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

  // ─────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -25, right: -20, child: _circle(140, 0.07)),
          Positioned(top: 50, right: 65, child: _circle(55, 0.08)),
          Positioned(bottom: -10, left: -30, child: _circle(80, 0.05)),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                children: [
                  // Tombol back
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, _currentUser),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Avatar — pakai _currentUser agar update langsung
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _currentUser.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _currentUser.email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Badge role
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "Pemilik",
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // ─────────────────────────────────────────────────
  // INFO CARD — pakai _currentUser
  // ─────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            icon: Icons.person_outline_rounded,
            label: "Nama Lengkap",
            value: _currentUser.name,
          ),
          _divider(),
          _infoRow(
            icon: Icons.email_outlined,
            label: "Email",
            value: _currentUser.email,
          ),
          _divider(),
          _infoRow(
            icon: Icons.phone_android_outlined,
            label: "Nomor Telepon",
            value: _currentUser.phone ?? "-",
          ),
          _divider(),
          _infoRow(
            icon: Icons.badge_outlined,
            label: "Role Akun",
            value: "Pemilik",
            valueColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryGreen),
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
                    color: valueColor ?? const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        color: Colors.grey.shade100,
        height: 1,
        thickness: 1,
      );

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: _openEditProfile,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.35),
              blurRadius: 14,
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
}

// ═══════════════════════════════════════════════════════
// HALAMAN EDIT PROFIL
// ═══════════════════════════════════════════════════════
class _EditProfilePage extends StatefulWidget {
  final User user;
  const _EditProfilePage({required this.user});

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPass = false;
  bool _showCurrPass = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.user.name;
    _emailCtrl.text = widget.user.email;
    _phoneCtrl.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack("Nama tidak boleh kosong", isError: true);
      return;
    }

    setState(() => _isSavingProfile = true);

    final success = await AuthRemoteDatasource().updateProfile(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSavingProfile = false);

    if (success) {
      _showSnack("Profil berhasil diperbarui!");

      // Buat User baru dengan data terbaru lalu kembalikan ke ProfileManagementPage
      final updatedUser = User(
        id: widget.user.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: widget.user.role,
      );

      // Tunggu sebentar agar snackbar terlihat, lalu pop dengan data baru
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, updatedUser);
    } else {
      _showSnack("Gagal memperbarui profil", isError: true);
    }
  }

  Future<void> _handleChangePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showSnack("Konfirmasi password tidak cocok", isError: true);
      return;
    }
    if (_newPassCtrl.text.length < 8) {
      _showSnack("Password baru minimal 8 karakter", isError: true);
      return;
    }

    setState(() => _isSavingPass = true);

    final success = await AuthRemoteDatasource().changePassword(
      _currPassCtrl.text,
      _newPassCtrl.text,
      _confirmPassCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSavingPass = false);

    if (success) {
      _currPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    }

    _showSnack(
      success ? "Password berhasil diubah!" : "Gagal mengubah password",
      isError: !success,
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor:
            isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      appBar: AppBar(
        title: Text(
          "Edit Profil",
          style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          children: [
            // ── INFORMASI PRIBADI ──
            _buildCard(
              title: "Informasi Pribadi",
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.primaryGreen,
              children: [
                _buildField(
                  ctrl: _nameCtrl,
                  label: "Nama Lengkap",
                  icon: Icons.person_outline_rounded,
                ),
                _buildField(
                  ctrl: _emailCtrl,
                  label: "Email",
                  icon: Icons.email_outlined,
                  enabled: false,
                  hint: "Email tidak dapat diubah",
                ),
                _buildField(
                  ctrl: _phoneCtrl,
                  label: "Nomor Telepon",
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 4),
                _buildPrimaryButton(
                  label: "Simpan Profil",
                  isLoading: _isSavingProfile,
                  onTap: _handleSaveProfile,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── KEAMANAN AKUN ──
            _buildCard(
              title: "Keamanan Akun",
              icon: Icons.lock_outline_rounded,
              iconColor: Colors.orange.shade700,
              children: [
                _buildPasswordField(
                  ctrl: _currPassCtrl,
                  label: "Password Lama",
                  visible: _showCurrPass,
                  onToggle: () =>
                      setState(() => _showCurrPass = !_showCurrPass),
                ),
                _buildPasswordField(
                  ctrl: _newPassCtrl,
                  label: "Password Baru",
                  visible: _showNewPass,
                  onToggle: () =>
                      setState(() => _showNewPass = !_showNewPass),
                ),
                _buildPasswordField(
                  ctrl: _confirmPassCtrl,
                  label: "Konfirmasi Password Baru",
                  visible: _showConfirmPass,
                  onToggle: () =>
                      setState(() => _showConfirmPass = !_showConfirmPass),
                ),
                const SizedBox(height: 4),
                _buildPrimaryButton(
                  label: "Ganti Password",
                  isLoading: _isSavingPass,
                  onTap: _handleChangePassword,
                  color: Colors.orange.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
            fontSize: 14, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController ctrl,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        obscureText: !visible,
        style: GoogleFonts.poppins(
            fontSize: 14, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 13),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              size: 18, color: Colors.orange.shade700),
          suffixIcon: IconButton(
            icon: Icon(
              visible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.orange.shade700, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
    Color? color,
  }) {
    final btnColor = color ?? AppColors.primaryGreen;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey.shade300 : btnColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: btnColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}