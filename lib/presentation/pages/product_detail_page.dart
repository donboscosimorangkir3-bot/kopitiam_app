// lib/presentation/pages/product_detail_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/cart_page.dart';
import 'package:kopitiam_app/data/datasources/cart_remote_datasource.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final bool isLoggedIn;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.isLoggedIn,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  int _quantity = 1;
  double _selectedPrice = 0;
  String? _selectedVariant; // 'Hot' | 'Cold' | null
  bool _isLoading = false;
  final TextEditingController _quantityController = TextEditingController();

  late AnimationController _entryController;
  late AnimationController _btnController;
  late Animation<double> _imageFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentFade;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _selectedPrice   = widget.product.price;
    _selectedVariant = widget.product.priceCold != null ? 'Hot' : null;
    _quantityController.text = _quantity.toString();

    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _imageFade = CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.18), end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    _btnController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.95,
        upperBound: 1.0,
        value: 1.0);
    _btnScale = _btnController;

    _entryController.forward();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _entryController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────
  String _formatPrice(double price) => NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);

  void _increaseQuantity() {
    setState(() {
      _quantity++;
      _quantityController.text = _quantity.toString();
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _quantityController.text = _quantity.toString();
      });
    }
  }

  void _selectVariant(String variant) {
    setState(() {
      _selectedVariant = variant;
      _selectedPrice   = variant == 'Hot'
          ? widget.product.price
          : (widget.product.priceCold ?? widget.product.price);
    });
  }

  void _showSnack(String msg,
      {required IconData icon, required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  // ─────────────────────────────────────────────────
  // ADD TO CART
  // Mengirim note ke backend: 'Hot', 'Cold', atau null
  // ─────────────────────────────────────────────────
  Future<void> _addToCart() async {
    await _btnController.reverse();
    _btnController.forward();

    if (!widget.isLoggedIn) {
      _showSnack("Silakan login untuk memesan!",
          icon: Icons.info_outline, color: AppColors.primaryGreen);
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    if (_quantity <= 0 || _quantity > widget.product.stock) {
      _showSnack("Jumlah tidak valid atau melebihi stok!",
          icon: Icons.warning_amber_rounded, color: Colors.redAccent);
      return;
    }

    if (widget.product.priceCold != null && _selectedVariant == null) {
      _showSnack("Pilih varian Panas atau Dingin terlebih dahulu.",
          icon: Icons.thermostat_rounded, color: Colors.orange.shade700);
      return;
    }

    setState(() => _isLoading = true);

    final success = await CartRemoteDatasource().addToCart(
      widget.product.id,
      _quantity,
      temperature: _selectedVariant?.toLowerCase(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      final variantLabel = _selectedVariant == 'Hot'
          ? 'Panas'
          : _selectedVariant == 'Cold'
              ? 'Dingin'
              : '';

      final label = variantLabel.isNotEmpty
          ? "$_quantity × ${widget.product.name} ($variantLabel)"
          : "$_quantity × ${widget.product.name}";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Text("$label ditambahkan!",
                      style: GoogleFonts.poppins(fontSize: 13))),
            ],
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          action: SnackBarAction(
            label: "Lihat",
            textColor: Colors.white,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage())),
          ),
        ),
      );
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CartPage()));
    } else {
      _showSnack("Gagal menambahkan ke keranjang. Coba lagi.",
          icon: Icons.error_outline, color: Colors.redAccent);
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
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeroImage(screenH)),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                      position: _contentSlide,
                      child: _buildDetailSheet()),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildCircleBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildBottomBar()),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // HERO IMAGE
  // ─────────────────────────────────────────────────
  Widget _buildHeroImage(double screenH) {
    final url      = widget.product.imageUrl;
    final hasImage = url != null && url.trim().isNotEmpty;

    return FadeTransition(
      opacity: _imageFade,
      child: SizedBox(
        height: screenH * 0.42,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                cacheKey: 'product_${widget.product.id}',
                placeholder: (_, __) => _buildImageShimmer(),
                errorWidget: (_, __, ___) => _buildImageFallback(),
              )
            else
              _buildImageFallback(),
            Positioned(
              bottom: 0, left: 0, right: 0, height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFF7F2EA),
                      const Color(0xFFF7F2EA).withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
                bottom: 24, right: 20,
                child: _buildStockBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageShimmer() => _ShimmerBox(
      width: double.infinity, height: double.infinity, borderRadius: 0);

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFEDE8DF),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 52, color: Colors.brown.withOpacity(0.22)),
          const SizedBox(height: 8),
          Text('Foto belum tersedia',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.brown.withOpacity(0.35))),
        ],
      ),
    );
  }

  Widget _buildStockBadge() {
    final isLow = widget.product.stock <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow ? Colors.orange.shade700 : AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isLow ? Colors.orange : AppColors.primaryGreen)
                .withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isLow
                  ? Icons.warning_amber_rounded
                  : Icons.inventory_2_rounded,
              color: Colors.white,
              size: 13),
          const SizedBox(width: 5),
          Text(
            isLow
                ? "Stok tersisa ${widget.product.stock}"
                : "Stok: ${widget.product.stock}",
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // DETAIL SHEET
  // ─────────────────────────────────────────────────
  Widget _buildDetailSheet() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF7F2EA)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama & harga
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                        height: 1.2),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(_selectedPrice),
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen),
                    ),
                    if (_selectedVariant != null)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedVariant == 'Hot'
                              ? Colors.orange.withOpacity(0.12)
                              : Colors.blue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedVariant == 'Hot' ? '☕ Panas' : '🧊 Dingin',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _selectedVariant == 'Hot'
                                ? Colors.orange.shade700
                                : Colors.blue.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Deskripsi
            _buildCardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    icon: Icons.description_outlined,
                    label: "Deskripsi",
                    iconBg: AppColors.primaryGreen.withOpacity(0.1),
                    iconColor: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.description ?? 'Tidak ada deskripsi tersedia.',
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                        height: 1.55),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Pilih suhu (hanya jika ada priceCold)
            if (widget.product.priceCold != null) ...[
  _buildCardSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          icon: Icons.thermostat_rounded,
          label: "Pilih Suhu",
          iconBg: Colors.orange.withOpacity(0.1),
          iconColor: Colors.orange.shade700,
        ),
        const SizedBox(height: 12),
        // Gunakan Column agar pilihan atas-bawah (lebih hemat tempat samping)
        // atau tetap Row jika ingin bersebelahan tapi lebih tipis.
        Row(
          children: [
            Expanded(
              child: _buildTempOption(
                variant: 'Hot',
                label: 'Hot',
                emoji: '☕',
                price: widget.product.price,
                accentColor: Colors.orange.shade700,
                isSelected: _selectedVariant == 'Hot',
                onTap: () => _selectVariant('Hot'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTempOption(
                variant: 'Cold',
                label: 'Cold',
                emoji: '🧊',
                price: widget.product.priceCold!,
                accentColor: Colors.blue.shade600,
                isSelected: _selectedVariant == 'Cold',
                onTap: () => _selectVariant('Cold'),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  const SizedBox(height: 14),
],

            // Jumlah
            _buildCardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _sectionHeader(
                        icon: Icons.production_quantity_limits_rounded,
                        label: "Jumlah",
                        iconBg: Colors.purple.withOpacity(0.1),
                        iconColor: Colors.purple.shade400,
                      ),
                      const Spacer(),
                      Text(
                        "Total: ${_formatPrice(_selectedPrice * _quantity)}",
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildQtyBtn(
                          icon: Icons.remove_rounded,
                          onTap: _decreaseQuantity,
                          enabled: _quantity > 1),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F2EA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.primaryGreen.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A)),
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero),
                            onChanged: (v) {
                              setState(() {
                                _quantity = int.tryParse(v) ?? 1;
                                if (_quantity < 1) _quantity = 1;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildQtyBtn(
                          icon: Icons.add_rounded,
                          onTap: _increaseQuantity,
                          enabled: _quantity < widget.product.stock),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // TEMPERATURE OPTION CARD
  // ─────────────────────────────────────────────────
  Widget _buildTempOption({
  required String variant,
  required String label,
  required String emoji,
  required double price,
  required Color accentColor,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row( // Ubah ke Row agar lebih compact
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? accentColor : Colors.black87,
                ),
              ),
              Text(
                _formatPrice(price),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isSelected)
            Icon(Icons.check_circle, size: 18, color: accentColor)
          else
            Icon(Icons.circle_outlined, size: 18, color: Colors.grey.shade300),
        ],
      ),
    ),
  );
}

  // ─────────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final bool needsVariant =
        widget.product.priceCold != null && _selectedVariant == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Harga",
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade500)),
              Text(
                _formatPrice(_selectedPrice * _quantity),
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ScaleTransition(
              scale: _btnScale,
              child: GestureDetector(
                onTap: (_isLoading || needsVariant) ? null : _addToCart,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (_isLoading || needsVariant)
                          ? [Colors.grey.shade400, Colors.grey.shade400]
                          : [
                              AppColors.primaryGreen,
                              Color.fromARGB(
                                255,
                                (AppColors.primaryGreen.red * 0.8).toInt(),
                                (AppColors.primaryGreen.green * 0.9).toInt(),
                                (AppColors.primaryGreen.blue * 0.85).toInt(),
                              ),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: (_isLoading || needsVariant)
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_shopping_cart_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                needsVariant
                                    ? "Pilih Suhu Terlebih Dahulu"
                                    : widget.isLoggedIn
                                        ? "Tambah ke Keranjang"
                                        : "Login untuk Memesan",
                                style: GoogleFonts.poppins(
                                  fontSize: needsVariant ? 12 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────
  Widget _buildCardSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _buildCircleBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildQtyBtn(
      {required IconData icon,
      required VoidCallback onTap,
      bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withOpacity(0.25),
          borderRadius: BorderRadius.circular(13),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIMMER BOX
// ─────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox(
      {required this.width, required this.height, this.borderRadius = 8});

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
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
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
              Color.lerp(const Color(0xFFEDE8DF),
                  const Color(0xFFF5F0E8), _anim.value)!,
              Color.lerp(const Color(0xFFF5F0E8),
                  const Color(0xFFEDE8DF), _anim.value)!,
            ],
          ),
        ),
      ),
    );
  }
}