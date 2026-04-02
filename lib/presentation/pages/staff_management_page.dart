import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/staff_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/staff_form_page.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage>
    with SingleTickerProviderStateMixin {

  List<User> _staffList = [];
  bool _isLoading = true;
  bool _hasError = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600));

    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _fetchStaff();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await StaffRemoteDatasource().getStaff();

      if (!mounted) return;

      setState(() {
        _staffList = result;
        _isLoading = false;
      });

      _animController.forward(from: 0);

    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // ─────────────────────────────────
  // ROLE HELPER
  // ─────────────────────────────────

  String _getRoleLabel(String role) {
    return "Kasir";
  }

  Color _getRoleColor(String role) {
    return Colors.purple.shade500;
  }

  IconData _getRoleIcon(String role) {
    return Icons.point_of_sale_rounded;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(" ");
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  // ─────────────────────────────────
  // NAVIGATE
  // ─────────────────────────────────

  Future<void> _navigateToForm({User? staff}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffFormPage(staff: staff),
      ),
    );

    _fetchStaff();
  }

  // ─────────────────────────────────
  // DELETE
  // ─────────────────────────────────

  Future<void> _deleteStaff(int id, String name) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Staf"),
        content: Text("Yakin ingin menghapus $name ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context,false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context,true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await StaffRemoteDatasource().deleteStaff(id);

    if (!mounted) return;

    if (success) {
      _fetchStaff();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Staf berhasil dihapus")),
      );
    }
  }

  // ─────────────────────────────────
  // BUILD
  // ─────────────────────────────────

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),

      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStaff,
              color: AppColors.primaryGreen,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? const Center(child: Text("Terjadi kesalahan"))
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: _buildContent(),
                          ),
                        ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.person_add,color: Colors.white),
        label: Text(
          "Tambah Staf",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // HEADER
  // ─────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.85),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10,8,16,18),
          child: Row(
            children: [

              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back,color: Colors.white),
              ),

              const SizedBox(width:8),

              const Icon(Icons.people,color: Colors.white),

              const SizedBox(width:10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Manajemen Staf",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  Text(
                    "Kelola staf kasir kopitiam di sini",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white70,
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

  // ─────────────────────────────────
  // CONTENT
  // ─────────────────────────────────

  Widget _buildContent() {

    return ListView(
      padding: const EdgeInsets.fromLTRB(16,12,16,100),
      children: [

        _buildSummary(),

        const SizedBox(height:20),

        _buildSectionLabel(
          "Kasir",
          Icons.point_of_sale,
          Colors.purple,
          _staffList.length,
        ),

        const SizedBox(height:10),

        ..._staffList.map(_buildStaffCard),
      ],
    );
  }

  // ─────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────

  Widget _buildSummary() {

    final stats = [

      {
        "label":"Total Staf",
        "value":_staffList.length.toString(),
        "icon":Icons.people,
        "color":AppColors.primaryGreen
      },

      {
        "label":"Kasir",
        "value":_staffList.length.toString(),
        "icon":Icons.point_of_sale,
        "color":Colors.purple
      }

    ];

    return Row(
      children: stats.map((s){

        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right:10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  blurRadius:10,
                  color: Colors.black.withOpacity(0.05),
                )
              ],
            ),
            child: Column(
              children: [

                Icon(
                  s["icon"] as IconData,
                  color: s["color"] as Color,
                ),

                const SizedBox(height:6),

                Text(
                  s["value"] as String,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                Text(
                  s["label"] as String,
                  style: GoogleFonts.poppins(fontSize:10),
                ),
              ],
            ),
          ),
        );

      }).toList(),
    );
  }

  // ─────────────────────────────────
  // SECTION LABEL
  // ─────────────────────────────────

  Widget _buildSectionLabel(
      String title, IconData icon, Color color, int count) {

    return Row(
      children: [

        Icon(icon,color:color,size:16),

        const SizedBox(width:6),

        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width:6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal:8,vertical:2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "$count",
            style: TextStyle(color: color),
          ),
        )
      ],
    );
  }

  // ─────────────────────────────────
  // STAFF CARD
  // ─────────────────────────────────

  Widget _buildStaffCard(User staff) {

    final roleColor = _getRoleColor(staff.role);

    return Container(
      margin: const EdgeInsets.only(bottom:10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius:10,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),

      child: Row(
        children: [

          CircleAvatar(
            radius:24,
            backgroundColor: roleColor.withOpacity(0.2),
            child: Text(
              _getInitials(staff.name),
              style: TextStyle(color: roleColor,fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(width:12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  staff.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  staff.email,
                  style: GoogleFonts.poppins(fontSize:12),
                ),

                if(staff.phone != null)
                  Text(
                    staff.phone!,
                    style: GoogleFonts.poppins(fontSize:12),
                  )
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.edit,color: Colors.blue),
            onPressed: () => _navigateToForm(staff: staff),
          ),

          IconButton(
            icon: const Icon(Icons.delete,color: Colors.red),
            onPressed: () => _deleteStaff(staff.id, staff.name),
          )
        ],
      ),
    );
  }
}