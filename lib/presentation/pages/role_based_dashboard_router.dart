// lib/presentation/pages/role_based_dashboard_router.dart

import 'package:flutter/material.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:kopitiam_app/presentation/pages/cashier_dashboard_page.dart'; // Nanti kita buat
import 'package:kopitiam_app/presentation/pages/owner_dashboard_page.dart';   // Nanti kita buat
import 'package:kopitiam_app/presentation/pages/customer_home_page.dart'; // Untuk jaga-jaga jika role customer lolos

class RoleBasedDashboardRouter extends StatelessWidget {
  final User user; // Terima objek user lengkap

  const RoleBasedDashboardRouter({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Berdasarkan role user, arahkan ke dashboard yang sesuai
    if (user.role == 'owner') {
      return OwnerDashboardPage(user: user);
    } else if (user.role == 'admin' || user.role == 'cashier') {
      // Untuk admin dan kasir, bisa diarahkan ke Cashier Dashboard dulu
      return CashierDashboardPage(user: user);
    } else {
      // Jika ada role lain atau tidak dikenal, arahkan ke Customer Home
      return const CustomerHomePage();
    }
  }
}