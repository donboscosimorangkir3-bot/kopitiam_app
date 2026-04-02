// lib/presentation/pages/category_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/category_remote_datasource.dart';
import 'package:kopitiam_app/data/models/category_model.dart';
import 'package:kopitiam_app/presentation/pages/category_form_page.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage>
    with SingleTickerProviderStateMixin {
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _hasError = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ═══════════════════════════════════════════════════════════
  // SMART ICON & COLOR MAPPING
  // Sistem prioritas 3 lapis:
  //   1. Exact match nama kategori (misal "Kopi" → Icons.coffee)
  //   2. Keyword match dalam nama (misal "Es Kopi" → contains "kopi")
  //   3. Fallback: warna & ikon dari hash nama (konsisten, tidak random)
  // ═══════════════════════════════════════════════════════════

  /// Daftar rules keyword → {icon, color}
  /// Urutan penting: lebih spesifik di atas, lebih umum di bawah.
  static const List<_IconRule> _iconRules = [
    // ── Minuman kopi ──
    _IconRule(
      keywords: ['kopi', 'coffee', 'espresso', 'latte', 'cappuccino',
                 'americano', 'macchiato', 'mocha', 'cold brew'],
      icon: Icons.coffee_rounded,
      color: Color(0xFF6F4E37),
    ),
    // ── Minuman teh ──
    _IconRule(
      keywords: ['teh', 'tea', 'matcha', 'chamomile', 'jasmine'],
      icon: Icons.emoji_food_beverage_rounded,
      color: Color(0xFF558B2F),
    ),
    // ── Minuman jus / buah ──
    _IconRule(
      keywords: ['jus', 'juice', 'buah', 'fruit', 'smoothie',
                 'blend', 'segar', 'fresh'],
      icon: Icons.blender_rounded,
      color: Color(0xFFFF8F00),
    ),
    // ── Minuman es / dingin ──
    _IconRule(
      keywords: ['es', 'ice', 'frappe', 'freeze', 'dingin', 'cold'],
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF29B6F6),
    ),
    // ── Minuman coklat / susu ──
    _IconRule(
      keywords: ['coklat', 'chocolate', 'choco', 'susu', 'milk',
                 'milo', 'ovaltine'],
      icon: Icons.local_drink_rounded,
      color: Color(0xFF795548),
    ),
    // ── Minuman umum ──
    _IconRule(
      keywords: ['minuman', 'drink', 'beverage', 'soda', 'air',
                 'mineral', 'boba', 'thai'],
      icon: Icons.local_bar_rounded,
      color: Color(0xFF26A69A),
    ),
    // ── Makanan berat ──
    _IconRule(
      keywords: ['nasi', 'rice', 'mie', 'mie', 'pasta', 'bakso',
                 'soto', 'rawon', 'rendang', 'ayam', 'chicken',
                 'daging', 'beef', 'meat', 'seafood', 'ikan', 'fish',
                 'udang', 'berat', 'makanan'],
      icon: Icons.rice_bowl_rounded,
      color: Color(0xFFFF7043),
    ),
    // ── Roti / sandwich ──
    _IconRule(
      keywords: ['roti', 'bread', 'sandwich', 'burger', 'toast',
                 'brioche', 'croissant', 'bakery'],
      icon: Icons.breakfast_dining_rounded,
      color: Color(0xFFFFCA28),
    ),
    // ── Cemilan / snack ──
    _IconRule(
      keywords: ['snack', 'cemilan', 'keripik', 'chips', 'kue',
                 'cookie', 'biscuit', 'cracker', 'gorengan'],
      icon: Icons.cookie_rounded,
      color: Color(0xFFFF8A65),
    ),
    // ── Dessert / manis ──
    _IconRule(
      keywords: ['dessert', 'kue', 'cake', 'pastry', 'manis',
                 'sweet', 'pudding', 'tiramisu', 'waffle'],
      icon: Icons.cake_rounded,
      color: Color(0xFFEC407A),
    ),
    // ── Es krim ──
    _IconRule(
      keywords: ['es krim', 'ice cream', 'gelato', 'sorbet',
                 'sundae', 'parfait'],
      icon: Icons.icecream_rounded,
      color: Color(0xFFAB47BC),
    ),
    // ── Add on / tambahan ──
    _IconRule(
      keywords: ['add on', 'addon', 'tambahan', 'topping', 'extra',
                 'pilihan', 'optional'],
      icon: Icons.add_circle_outline_rounded,
      color: Color(0xFF78909C),
    ),
    // ── Promo / paket ──
    _IconRule(
      keywords: ['promo', 'paket', 'bundle', 'hemat', 'set',
                 'combo', 'special', 'spesial'],
      icon: Icons.local_offer_rounded,
      color: Color(0xFFE53935),
    ),
    // ── Sarapan / breakfast ──
    _IconRule(
      keywords: ['sarapan', 'breakfast', 'pagi', 'morning'],
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFFA726),
    ),
    // ── Makan siang / lunch ──
    _IconRule(
      keywords: ['siang', 'lunch', 'makan siang'],
      icon: Icons.lunch_dining_rounded,
      color: Color(0xFF66BB6A),
    ),
    // ── Makan malam / dinner ──
    _IconRule(
      keywords: ['malam', 'dinner', 'makan malam'],
      icon: Icons.dinner_dining_rounded,
      color: Color(0xFF5C6BC0),
    ),
    // ── Vegetarian / vegan ──
    _IconRule(
      keywords: ['vegetarian', 'vegan', 'sehat', 'healthy',
                 'sayur', 'vegetable', 'salad'],
      icon: Icons.eco_rounded,
      color: Color(0xFF43A047),
    ),
  ];

  /// Warna fallback cycling — digunakan saat tidak ada keyword match.
  /// Warna dipilih berdasarkan hash nama, bukan index urutan.
  /// Hasilnya: nama yang sama SELALU dapat warna yang sama.
  static const List<Color> _fallbackColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF5722),
    Color(0xFF9C27B0),
    Color(0xFF009688),
    Color(0xFFFF9800),
    Color(0xFF607D8B),
    Color(0xFFE91E63),
  ];

  /// Ikon fallback cycling — sama seperti warna, konsisten per nama.
  static const List<IconData> _fallbackIcons = [
    Icons.category_rounded,
    Icons.restaurant_menu_rounded,
    Icons.storefront_rounded,
    Icons.local_dining_rounded,
    Icons.set_meal_rounded,
    Icons.fastfood_rounded,
    Icons.food_bank_rounded,
    Icons.dining_rounded,
  ];

  /// Fungsi utama: dapatkan ikon & warna berdasarkan nama kategori.
  /// Mencari keyword match (case-insensitive, partial match).
  /// Fallback ke hash-based index jika tidak ada yang cocok.
  _CategoryStyle _getStyleForCategory(String name) {
    final lower = name.toLowerCase().trim();

    // Iterasi rules dari atas ke bawah (lebih spesifik → lebih umum)
    for (final rule in _iconRules) {
      for (final kw in rule.keywords) {
        if (lower.contains(kw)) {
          return _CategoryStyle(icon: rule.icon, color: rule.color);
        }
      }
    }

    // Fallback: hash nama untuk konsistensi
    final hashIndex = name.codeUnits
        .fold(0, (sum, code) => sum + code) %
        _fallbackColors.length;

    return _CategoryStyle(
      icon: _fallbackIcons[hashIndex],
      color: _fallbackColors[hashIndex],
    );
  }

  // ═══════════════════════════════════════════════
  // STATE & LIFECYCLE
  // ═══════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic));
    _fetchCategories();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await CategoryRemoteDatasource().getCategories();
      if (!mounted) return;
      setState(() {
        _categories = result;
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

  Future<void> _deleteCategory(int id, String name) async {
    final confirmed = await _showDeleteDialog(name);
    if (confirmed != true) return;

    _showSnackBar('Menghapus "$name"...',
        icon: Icons.delete_outline_rounded);

    final success = await CategoryRemoteDatasource().deleteCategory(id);
    if (!mounted) return;

    if (success) {
      _showSnackBar('"$name" berhasil dihapus',
          icon: Icons.check_circle_outline_rounded);
      _fetchCategories();
    } else {
      _showSnackBar(
        'Gagal menghapus. Pastikan tidak ada produk terkait.',
        isError: true,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<bool?> _showDeleteDialog(String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                'Hapus Kategori?',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 8),
              Text(
                '"$name" akan dihapus permanen.\nPastikan tidak ada produk terkait.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Hapus',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
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

  void _showSnackBar(String message,
      {bool isError = false,
      IconData icon = Icons.info_outline_rounded}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(fontSize: 12.5)),
            ),
          ],
        ),
        backgroundColor:
            isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  Future<void> _navigateToForm({Category? category}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CategoryFormPage(category: category)),
    );
    _fetchCategories();
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCategories,
              color: AppColors.primaryGreen,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                          strokeWidth: 2.5),
                    )
                  : _hasError
                      ? _buildErrorState()
                      : _categories.isEmpty
                          ? _buildEmptyState()
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
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Tambah Kategori',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 13),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
      child: Stack(
        children: [
          Positioned(top: -18, right: -18, child: _circle(110, 0.07)),
          Positioned(top: 38, right: 60, child: _circle(44, 0.08)),
          Positioned(bottom: -8, left: -20, child: _circle(70, 0.05)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 18),
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
                    child: const Icon(Icons.category_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manajemen Kategori',
                          style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20),
                        ),
                        Text(
                          'Kelola kategori produk toko',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7)),
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
  // CONTENT
  // ─────────────────────────────────────────────────
  Widget _buildContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Summary strip ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.category_rounded,
                              color: AppColors.primaryGreen, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_categories.length}',
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A1A)),
                            ),
                            Text(
                              'Total Kategori',
                              style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              AppColors.primaryGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            color: AppColors.primaryGreen, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ikon menyesuaikan nama kategori secara otomatis',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: AppColors.primaryGreen,
                                height: 1.4),
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

        // ── Section title ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Semua Kategori',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),
        ),

        // ── Grid kategori ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildCategoryCard(_categories[i]),
              childCount: _categories.length,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // CATEGORY CARD
  // Ikon & warna didapat dari _getStyleForCategory,
  // bukan dari index — sehingga selalu konsisten.
  // ─────────────────────────────────────────────────
  Widget _buildCategoryCard(Category category) {
    // ← PERUBAHAN UTAMA: pakai nama, bukan index
    final style = _getStyleForCategory(category.name);
    final color = style.color;
    final icon = style.icon;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── TOP: ikon berwarna ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      category.name,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A)),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BOTTOM: aksi ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToForm(category: category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_rounded,
                              color: Colors.blueAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        _deleteCategory(category.id, category.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Hapus',
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.category_rounded,
                  size: 42,
                  color: AppColors.primaryGreen.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Kategori',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat kategori seperti Kopi, Teh,\natau Makanan untuk mengorganisir produkmu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.6),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => _navigateToForm(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Buat Kategori',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ],
                ),
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
              child: const Icon(Icons.wifi_off_rounded,
                  size: 38, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Kategori',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internetmu\nlalu coba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.6),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchCategories,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════

/// Satu rule: kumpulan keyword → pasangan ikon + warna
class _IconRule {
  final List<String> keywords;
  final IconData icon;
  final Color color;

  const _IconRule({
    required this.keywords,
    required this.icon,
    required this.color,
  });
}

/// Hasil mapping: ikon + warna untuk satu kategori
class _CategoryStyle {
  final IconData icon;
  final Color color;

  const _CategoryStyle({required this.icon, required this.color});
}