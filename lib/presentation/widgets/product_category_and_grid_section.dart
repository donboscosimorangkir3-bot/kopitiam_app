// lib/presentation/widgets/product_category_and_grid_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/category_remote_datasource.dart';
import 'package:kopitiam_app/data/models/category_model.dart';
import 'package:kopitiam_app/presentation/widgets/product_grid_section.dart';

class ProductCategoryAndGridSection extends StatefulWidget {
  final bool isLoggedIn;
  final int? selectedCategoryId;
  final String? searchQuery;
  final Function(int?) onCategorySelected;

  const ProductCategoryAndGridSection({
    super.key,
    required this.isLoggedIn,
    this.selectedCategoryId,
    this.searchQuery,
    required this.onCategorySelected,
  });

  @override
  State<ProductCategoryAndGridSection> createState() =>
      _ProductCategoryAndGridSectionState();
}

class _ProductCategoryAndGridSectionState
    extends State<ProductCategoryAndGridSection>
    with SingleTickerProviderStateMixin {
  late Future<List<Category>> _categoriesFuture;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryRemoteDatasource().getCategories();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // CATEGORY TAB
  // ─────────────────────────────────────────────
  Widget _buildCategoryTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 18 : 16,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : AppColors.primaryGreen,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF444444),
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen.withOpacity(0.16),
                  AppColors.primaryGreen.withOpacity(0.07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 19, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EMPTY SEARCH STATE
  // ─────────────────────────────────────────────
  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            "Produk tidak ditemukan",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Coba kata kunci lain atau pilih kategori berbeda",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER KATEGORI ──
          _buildSectionHeader(
            title: "Kategori Menu",
            subtitle: "Pilih kategori favoritmu",
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(height: 14),

          // ── CATEGORY CHIPS ──
          FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (_, __) => _buildSkeletonChip(),
                  ),
                );
              }

              // Error state
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Text(
                          "Gagal memuat kategori",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final categories = snapshot.data!
                  .where((c) => c.name.toLowerCase() != 'add on')
                  .toList();

              if (categories.isEmpty) return const SizedBox.shrink();

              return SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCategoryTab(
                        label: "Semua",
                        icon: Icons.apps_rounded,
                        isSelected: widget.selectedCategoryId == null,
                        onTap: () => widget.onCategorySelected(null),
                      );
                    }
                    final category = categories[index - 1];
                    return _buildCategoryTab(
                      label: category.name,
                      isSelected:
                          widget.selectedCategoryId == category.id,
                      onTap: () =>
                          widget.onCategorySelected(category.id),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── DIVIDER TIPIS ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.brown.withOpacity(0.10),
              thickness: 1,
            ),
          ),

          const SizedBox(height: 16),

          // ── HEADER PRODUK ──
          _buildSectionHeader(
            title: "Pilihan Menu Kami",
            subtitle: widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                ? 'Hasil pencarian: "${widget.searchQuery}"'
                : widget.selectedCategoryId != null
                    ? "Menampilkan kategori terpilih"
                    : "Menu segar setiap hari",
            icon: Icons.restaurant_menu_rounded,
          ),

          const SizedBox(height: 14),

          // ── PRODUCT GRID ──
          ProductGridSection(
            isLoggedIn: widget.isLoggedIn,
            filterCategoryId: widget.selectedCategoryId,
            searchQuery: widget.searchQuery,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SKELETON CHIP (loading placeholder)
  // ─────────────────────────────────────────────
  Widget _buildSkeletonChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _ShimmerBox(
        width: 80,
        height: 36,
        borderRadius: 22,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIMMER BOX — skeleton loading effect
// ─────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            colors: [
              Color.lerp(const Color(0xFFE8E2D8),
                  const Color(0xFFF5F0E8), _anim.value)!,
              Color.lerp(const Color(0xFFF5F0E8),
                  const Color(0xFFE8E2D8), _anim.value)!,
            ],
          ),
        ),
      ),
    );
  }
}