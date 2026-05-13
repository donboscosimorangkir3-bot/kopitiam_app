// lib/presentation/pages/table_management_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/models/table_model.dart';
import 'package:kopitiam_app/data/datasources/table_remote_datasource.dart';

class TableManagementPage extends StatefulWidget {
  const TableManagementPage({super.key});

  @override
  State<TableManagementPage> createState() => _TableManagementPageState();
}

class _TableManagementPageState extends State<TableManagementPage>
    with SingleTickerProviderStateMixin {
  List<TableModel> _tables = [];
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchTables();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Fetch ───────────────────────────────────────────────────────────────────

  Future<void> _fetchTables() async {
    setState(() => _isLoading = true);
    final data = await TableRemoteDatasource().getTables();
    if (!mounted) return;
    setState(() {
      _tables = data;
      _isLoading = false;
    });
    _animController.forward(from: 0);
  }

  // ─── Dialog Edit Status ───────────────────────────────────────────────────────

  void _showEditStatusDialog(TableModel table) {
    bool tempAvailable = table.isAvailable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.table_restaurant_rounded,
                    color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Meja ${table.number}',
                  style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubah status ketersediaan meja jika terjadi kerusakan fisik.',
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: tempAvailable
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  title: Text('Status Meja',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                    tempAvailable
                        ? 'Aktif – Dapat digunakan'
                        : 'Nonaktif – Sedang Rusak',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: tempAvailable
                            ? AppColors.primaryGreen
                            : Colors.redAccent),
                  ),
                  activeColor: AppColors.primaryGreen,
                  inactiveThumbColor: Colors.redAccent,
                  inactiveTrackColor: Colors.red.shade100,
                  value: tempAvailable,
                  onChanged: (v) => setLocalState(() => tempAvailable = v),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal',
                  style:
                      GoogleFonts.poppins(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final success = await TableRemoteDatasource().updateTable(
                    table.id, table.number, tempAvailable);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  _fetchTables();
                  _showSnackbar('Status meja berhasil diubah',
                      isError: false);
                }
              },
              child: Text('Simpan',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialog Tambah / Edit Nomor Meja ─────────────────────────────────────────

  Future<void> _openFormDialog({TableModel? table}) async {
    final controller = TextEditingController(text: table?.number);
    final isEdit = table != null;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isEdit
                            ? Colors.orange.shade600
                            : AppColors.primaryGreen)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_rounded : Icons.add_rounded,
                    color: isEdit
                        ? Colors.orange.shade600
                        : AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Nomor Meja' : 'Tambah Meja Baru',
                    style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit
                      ? 'Ubah nomor meja ${table.number} menjadi:'
                      : 'Masukkan nomor untuk meja baru.',
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Nomor Meja (Contoh: 01)',
                    hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: Icon(Icons.table_restaurant_rounded,
                        color: AppColors.primaryGreen, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF5F0E8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: AppColors.primaryGreen, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: Text('Batal',
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEdit
                      ? Colors.orange.shade600
                      : AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        setDialogState(() => isSaving = true);
                        final success = await TableRemoteDatasource()
                            .saveTable(text, id: table?.id);
                        if (ctx.mounted) {
                          Navigator.pop(dialogContext, success);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Simpan',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (saved == true) {
      await _fetchTables();
      _showSnackbar(
          isEdit
              ? 'Nomor meja berhasil diperbarui'
              : 'Meja berhasil ditambahkan',
          isError: false);
    } else if (saved == false) {
      _showSnackbar('Gagal menyimpan meja. Cek koneksi & coba lagi.',
          isError: true);
    }
  }

  // ─── Dialog Konfirmasi Hapus ──────────────────────────────────────────────────

  Future<void> _deleteTable(TableModel table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_rounded,
                  color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Hapus Meja?',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey.shade600),
            children: [
              const TextSpan(text: 'Meja '),
              TextSpan(
                  text: table.number,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A))),
              const TextSpan(
                  text:
                      ' akan dihapus permanen dan tidak dapat dikembalikan.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style:
                    GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success =
          await TableRemoteDatasource().deleteTable(table.id);
      if (success && mounted) {
        await _fetchTables();
        _showSnackbar('Meja ${table.number} berhasil dihapus',
            isError: true);
      }
    }
  }

  // ─── Snackbar ─────────────────────────────────────────────────────────────────

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.delete_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white)),
            ),
          ],
        ),
        backgroundColor:
            isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = _tables.length;
    final active = _tables.where((t) => t.isAvailable).length;
    final inactive = total - active;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: Text('Manajemen Meja',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormDialog(),
        backgroundColor: const Color(0xFF2D6A4F),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Meja Baru',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _buildBody(total, active, inactive),
    );
  }

  Widget _buildBody(int total, int active, int inactive) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primaryGreen, strokeWidth: 2.5),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTables,
      color: AppColors.primaryGreen,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          // ── Stat Cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _statCard('Total Meja', '$total',
                          Icons.table_restaurant_rounded,
                          const Color(0xFF1565C0),
                          const Color(0xFFE3F2FD)),
                      const SizedBox(width: 10),
                      _statCard('Aktif', '$active',
                          Icons.check_circle_rounded,
                          const Color(0xFF2D6A4F),
                          const Color(0xFFE8F5E9)),
                      const SizedBox(width: 10),
                      _statCard('Nonaktif', '$inactive',
                          Icons.cancel_rounded,
                          Colors.redAccent,
                          const Color(0xFFFFEBEE)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Info hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.primaryGreen, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ketuk kartu meja untuk ubah status aktif/nonaktif',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Grid / Empty ──
          if (_tables.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  // Tinggi lebih besar agar tidak overflow
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildTableCard(_tables[index]),
                  ),
                  childCount: _tables.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Stat Card ────────────────────────────────────────────────────────────────

  Widget _statCard(String label, String value, IconData icon,
      Color color, Color bg) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A))),
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.table_restaurant_rounded,
                size: 38, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 14),
          Text('Belum ada meja',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text('Tap "+ Meja Baru" untuk menambahkan',
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─── Table Card ──────────────────────────────────────────────────────────────

  Widget _buildTableCard(TableModel table) {
    final isAvailable = table.isAvailable;

    return GestureDetector(
      onTap: () => _showEditStatusDialog(table),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isAvailable
                ? Colors.transparent
                : Colors.redAccent.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isAvailable
                  ? Colors.black.withOpacity(0.05)
                  : Colors.redAccent.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Ikon meja ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFFE8F5E9)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.table_restaurant_rounded,
                color: isAvailable
                    ? const Color(0xFF2D6A4F)
                    : Colors.grey.shade400,
                size: 24,
              ),
            ),

            const SizedBox(height: 5),

            // ── Nomor ──
            Text(
              table.number,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isAvailable
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey.shade400,
                decoration: isAvailable
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
              ),
            ),

            const SizedBox(height: 3),

            // ── Badge status ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFF2D6A4F).withOpacity(0.1)
                    : Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isAvailable ? 'AKTIF' : 'NONAKTIF',
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: isAvailable
                      ? const Color(0xFF2D6A4F)
                      : Colors.redAccent,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Tombol Edit & Hapus ──
            // Menggunakan InkWell dengan padding besar agar mudah ditekan
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Edit
                Material(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openFormDialog(table: table),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(Icons.edit_rounded,
                          color: Colors.orange.shade700, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Hapus
                Material(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _deleteTable(table),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(Icons.delete_rounded,
                          color: Colors.redAccent, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}