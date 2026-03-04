// lib/presentation/pages/initial_wrapper_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/customer_home_page.dart';
import 'package:kopitiam_app/presentation/widgets/kopitiam_info_widget.dart';
import 'package:kopitiam_app/presentation/pages/role_based_dashboard_router.dart';
import 'package:kopitiam_app/presentation/widgets/product_category_and_grid_section.dart';
import 'package:kopitiam_app/presentation/pages/cashier_dashboard_page.dart';
import 'package:kopitiam_app/presentation/pages/owner_dashboard_page.dart'; // Import halaman dashboard owner
import 'package:kopitiam_app/presentation/widgets/announcement_list_widget.dart'; // Import widget daftar pengumuman

class InitialWrapperPage extends StatefulWidget {
  const InitialWrapperPage({super.key});

  @override
  State<InitialWrapperPage> createState() => _InitialWrapperPageState();
}

class _InitialWrapperPageState extends State<InitialWrapperPage> {
  bool _isLoggedIn = false;
  User? _currentUser;
  int? _selectedCategoryId; // Untuk filter kategori di Guest view

  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndUser();
  }

  Future<void> _checkLoginStatusAndUser() async {
    _isLoggedIn = await AuthRemoteDatasource().isLogin();
    if (_isLoggedIn) {
      _currentUser = await AuthRemoteDatasource().getUserInfo();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Jika sudah login, cek role user dan arahkan ke halaman yang sesuai
    if (_isLoggedIn && _currentUser != null) {
      if (_currentUser!.role == 'owner') { // <-- Cek jika role adalah 'owner'
        return OwnerDashboardPage(user: _currentUser!); // <-- ARAHKAN KE OWNERDASHBOARDPAGE
      } else if (_currentUser!.role == 'admin' || _currentUser!.role == 'cashier') {
        // Untuk admin dan kasir, arahkan ke CashierDashboardPage
        return CashierDashboardPage(user: _currentUser!);
      } else {
        // Jika customer atau role lain, arahkan ke CustomerHomePage
        return const CustomerHomePage();
      }
    }

    // Jika belum login (Guest), tampilkan Home Page dengan Info dan Menu
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text(
          "Kopitiam33",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ).then((value) => _checkLoginStatusAndUser());
            },
            child: Text(
              "Login",
              style: GoogleFonts.poppins(color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const KopitiamInfoWidget(), // Informasi Kopitiam33
            const SizedBox(height: 20),
            
            // Pengumuman & Promo (untuk Guest)
            const AnnouncementListWidget(), // <-- TAMBAHKAN INI
            const SizedBox(height: 20),

            // Bagian Kategori dan Grid Produk untuk Guest
            ProductCategoryAndGridSection(
              isLoggedIn: false,
              selectedCategoryId: _selectedCategoryId,
              searchQuery: null,
              onCategorySelected: (id) {
                setState(() {
                  _selectedCategoryId = id;
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}