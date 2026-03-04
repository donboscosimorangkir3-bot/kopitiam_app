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
    extends State<ProductCategoryAndGridSection> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryRemoteDatasource().getCategories();
  }

  @override
  void didUpdateWidget(
      covariant ProductCategoryAndGridSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika diperlukan refresh kategori saat widget berubah,
    // bisa tambahkan logika di sini.
  }

  // =========================
  // CATEGORY TAB WIDGET
  // =========================
  Widget _buildCategoryTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.lightCream
                : AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.lightCream.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected
                  ? AppColors.darkGreen
                  : AppColors.white,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =========================
        // TITLE: KATEGORI MENU
        // =========================
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Kategori Menu",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // =========================
        // CATEGORY LIST
        // =========================
        FutureBuilder<List<Category>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: GoogleFonts.poppins(
                    color: AppColors.darkBrown,
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final categories = snapshot.data!
                .where((category) =>
                    category.name.toLowerCase() !=
                    'add on')
                .toList();

            if (categories.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  // Tab "All"
                  if (index == 0) {
                    return _buildCategoryTab(
                      label: "All",
                      isSelected:
                          widget.selectedCategoryId ==
                              null,
                      onTap: () =>
                          widget.onCategorySelected(null),
                    );
                  }

                  final category =
                      categories[index - 1];

                  return _buildCategoryTab(
                    label: category.name,
                    isSelected:
                        widget.selectedCategoryId ==
                            category.id,
                    onTap: () => widget
                        .onCategorySelected(category.id),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // =========================
        // TITLE: PILIHAN MENU
        // =========================
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Pilihan Menu Kami",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // =========================
        // PRODUCT GRID
        // =========================
        ProductGridSection(
          isLoggedIn: widget.isLoggedIn,
          filterCategoryId:
              widget.selectedCategoryId,
          searchQuery: widget.searchQuery,
        ),
      ],
    );
  }
}