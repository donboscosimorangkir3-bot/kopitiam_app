import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import Halaman Login
import 'package:kopitiam_app/presentation/pages/login_page.dart'; 

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6F4E37)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // Ganti Scaffold biasa menjadi LoginPage
      home: const LoginPage(), 
    );
  }
}