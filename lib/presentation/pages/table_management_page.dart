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

class _TableManagementPageState extends State<TableManagementPage> {
  List<TableModel> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    setState(() => _isLoading = true);
    final data = await TableRemoteDatasource().getTables();
    if (!mounted) return;
    setState(() {
      _tables = data;
      _isLoading = false;
    });
    print('[_fetchTables] Jumlah meja: ${data.length}');
  }

  Future<void> _openFormDialog({TableModel? table}) async {
    final controller = TextEditingController(text: table?.number);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool _isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              table == null ? "Tambah Meja" : "Edit Meja",
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: "Nomor Meja (Contoh: 01)",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    _isSaving ? null : () => Navigator.pop(dialogContext, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;

                        setDialogState(() => _isSaving = true);

                        final success = await TableRemoteDatasource()
                            .saveTable(text, id: table?.id);

                        print('[Dialog] saveTable result: $success');

                        if (ctx.mounted) {
                          Navigator.pop(dialogContext, success);
                        }
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Simpan",
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );

    print('[_openFormDialog] Dialog result: $saved');

    if (!mounted) return;

    if (saved == true) {
      await _fetchTables();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(table == null
              ? "Meja berhasil ditambahkan"
              : "Meja berhasil diperbarui"),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (saved == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal menyimpan meja. Cek koneksi & coba lagi."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteTable(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Meja?",
            style:
                GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text(
          "Meja ini akan dihapus secara permanen.",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await TableRemoteDatasource().deleteTable(id);
      if (success && mounted) {
        await _fetchTables();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Meja berhasil dihapus"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      appBar: AppBar(
        title: Text(
          "Daftar Meja",
          style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryGreen, strokeWidth: 2.5),
            )
          : _tables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_restaurant_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        "Belum ada meja",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "+ Meja Baru" untuk menambahkan',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTables,
                  color: AppColors.primaryGreen,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1,
                    ),
                    itemCount: _tables.length,
                    itemBuilder: (context, index) {
                      final table = _tables[index];
                      return GestureDetector(
                        onLongPress: () => _openFormDialog(table: table),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.table_restaurant_rounded,
                                        color: AppColors.primaryGreen,
                                        size: 30),
                                    const SizedBox(height: 4),
                                    Text(
                                      table.number,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () => _deleteTable(table.id),
                                  child: const Icon(Icons.cancel,
                                      color: Colors.redAccent, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormDialog(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Meja Baru",
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}