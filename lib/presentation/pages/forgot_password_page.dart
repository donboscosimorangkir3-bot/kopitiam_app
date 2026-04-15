// lib/presentation/pages/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;

  void _handleRequestOtp() async {
    setState(() => _isLoading = true);
    final success = await AuthRemoteDatasource().forgotPassword(_emailController.text);
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP terkirim ke email!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email tidak ditemukan")));
    }
  }

  void _handleReset() async {
    setState(() => _isLoading = true);
    final success = await AuthRemoteDatasource().resetPassword(
      _emailController.text, 
      _otpController.text, 
      _passController.text, 
      _confirmPassController.text
    );
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diganti!")));
      Navigator.pop(context); // Kembali ke Login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal reset, cek OTP Anda")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      appBar: AppBar(title: const Text("Lupa Password"), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_open_rounded, size: 80, color: AppColors.primaryGreen),
            const SizedBox(height: 20),
            Text(_otpSent ? "Masukkan Password Baru" : "Lupa password? Masukkan email Anda untuk menerima kode OTP.", textAlign: TextAlign.center),
            const SizedBox(height: 30),
            
            // TAHAP 1: INPUT EMAIL
            TextField(
              controller: _emailController,
              enabled: !_otpSent,
              decoration: InputDecoration(labelText: "Alamat Email", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),

            if (_otpSent) ...[
              const SizedBox(height: 16),
              // TAHAP 2: INPUT OTP & PASSWORD BARU
              TextField(controller: _otpController, decoration: const InputDecoration(labelText: "6 Digit OTP")),
              const SizedBox(height: 16),
              TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Password Baru")),
              const SizedBox(height: 16),
              TextField(controller: _confirmPassController, obscureText: true, decoration: const InputDecoration(labelText: "Konfirmasi Password Baru")),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                onPressed: _isLoading ? null : (_otpSent ? _handleReset : _handleRequestOtp),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(_otpSent ? "Reset Password" : "Kirim Kode OTP", style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}