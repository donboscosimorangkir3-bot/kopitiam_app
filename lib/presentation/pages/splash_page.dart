// lib/presentation/pages/splash_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/presentation/pages/initial_wrapper_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    _navigateToNextPage();
  }

  Future<void> _navigateToNextPage() async {
    // Delay 3 detik
    await Future.delayed(const Duration(seconds: 3));

    // Cek status login (fungsi tetap dipanggil agar tidak mengurangi logic)
    final isLoggedIn = await AuthRemoteDatasource().isLogin();

    if (!mounted) return;

    // Tetap arahkan ke InitialWrapperPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const InitialWrapperPage(),
      ),
    );
  }

  void _manualNavigate() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const InitialWrapperPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Kopi
            Image.asset(
              'assets/coffee_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),

            // Text Kopitiam33
            Text(
              "KOPITIAM³³",
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.lightCream,
                letterSpacing: 2,
              ),
            ),

            
          ],
        ),
      ),
    );
  }
}