// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart'; 
import 'package:kopitiam_app/presentation/pages/splash_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kopitiam33',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Set warna utama tema dari AppColors
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen), 
        useMaterial3: true,
        // Gunakan font Poppins untuk seluruh aplikasi
        textTheme: GoogleFonts.poppinsTextTheme(),
        // Set warna latar belakang Scaffold default
        scaffoldBackgroundColor: AppColors.lightCream, 
        // Tema AppBar default
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGreen, 
          foregroundColor: AppColors.white,        
        ),
      ),
      // Halaman pertama yang akan ditampilkan adalah SplashPage
      home: const SplashPage(), 
    );
  }
}