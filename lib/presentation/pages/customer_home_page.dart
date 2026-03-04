// lib/presentation/pages/customer_home_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/login_page.dart';
import 'package:kopitiam_app/presentation/pages/cart_page.dart';
import 'package:kopitiam_app/presentation/pages/profile_page.dart';
import 'package:kopitiam_app/presentation/pages/settings_page.dart';
import 'package:kopitiam_app/presentation/pages/help_page.dart';
import 'package:kopitiam_app/presentation/widgets/product_category_and_grid_section.dart';
import 'package:kopitiam_app/presentation/pages/order_history_page.dart';
import 'package:kopitiam_app/presentation/widgets/announcement_list_widget.dart'; // Import widget daftar pengumuman

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  User? _currentUser;

  final TextEditingController _searchController = TextEditingController();

  int? _selectedCategoryId;
  String? _currentSearchQuery;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = await AuthRemoteDatasource().getUserInfo();

    if (!mounted) return;

    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // =========================
                // PENGUMUMAN
                // =========================
                const AnnouncementListWidget(),
                const SizedBox(height: 20),
                

                // =========================
                // PRODUCT SECTION
                // =========================
                ProductCategoryAndGridSection(
                  isLoggedIn: true,
                  selectedCategoryId: _selectedCategoryId,
                  searchQuery: _currentSearchQuery,
                  onCategorySelected: (id) {
                    setState(() {
                      _selectedCategoryId = id;
                      _searchController.clear();
                      _currentSearchQuery = null;
                    });
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // =========================
  // SLIVER APP BAR
  // =========================
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      expandedHeight: 180,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(),

              const SizedBox(height: 6),

              Text(
                "What would you like to drink today?",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.lightCream.withOpacity(0.85),
                ),
              ),

              const SizedBox(height: 10),

              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "Good day, ${_currentUser?.name ?? 'Customer'}!",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_outlined,
                size: 26,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Fitur Notifikasi"),
                  ),
                );
              },
            ),

            _buildPopupMenu(),
          ],
        ),
      ],
    );
  }

  // =========================
  // POPUP MENU
  // =========================
  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, size: 26),

      onSelected: (value) async {
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfilePage(),
              ),
            );
            break;

          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
            break;

          case 'help':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HelpPage(),
              ),
            );
            break;

          case 'logout':
            await AuthRemoteDatasource().logout();

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ),
              (route) => false,
            );
            break;
        }
      },

      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem(
          value: 'help',
          child: ListTile(
            leading: Icon(Icons.help),
            title: Text('Help'),
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // SEARCH BAR
  // =========================
  Widget _buildSearchBar() {
    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.lightCream,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(
              color: AppColors.darkBrown,
            ),

            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.primaryGreen,
              ),
              hintText: "Cari kopi atau kategori...",
              hintStyle: GoogleFonts.poppins(
                color: AppColors.primaryGreen.withOpacity(0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),

              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.primaryGreen,
                      ),
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _currentSearchQuery = null;
                        });

                        setInnerState(() {});
                      },
                    )
                  : null,
            ),

            onChanged: (value) {
              setState(() {
                _currentSearchQuery =
                    value.isEmpty ? null : value;
              });

              setInnerState(() {});
            },
          ),
        );
      },
    );
  }

  // =========================
  // BOTTOM NAVIGATION
  // =========================
  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      backgroundColor: AppColors.primaryGreen,
      selectedItemColor: AppColors.lightCream,
      unselectedItemColor: AppColors.lightCream.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],

      onTap: (index) {
        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }

        else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CartPage(),
            ),
          );
        }

        else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OrderHistoryPage(),
            ),
          );
        }

        else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfilePage(),
            ),
          );
        }
      },
    );
  }
}