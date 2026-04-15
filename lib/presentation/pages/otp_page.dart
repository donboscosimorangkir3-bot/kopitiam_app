// lib/presentation/pages/otp_page.dart

import 'dart:async'; // WAJIB TAMBAHKAN INI
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/presentation/pages/customer_home_page.dart';

class OtpPage extends StatefulWidget {
  final String email;
  const OtpPage({super.key, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  // --- LOGIK TIMER ---
  Timer? _timer;
  int _secondsRemaining = 300; // 5 Menit = 300 detik

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  // Fungsi untuk mengubah detik menjadi format 05:00
  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hentikan timer saat halaman ditutup
    _otpController.dispose();
    super.dispose();
  }
  // -------------------

  void _handleVerify() async {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan 6 digit kode OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await AuthRemoteDatasource().verifyOtp(
      widget.email, 
      _otpController.text
    );

    setState(() => _isLoading = false);

    if (success) {
      _timer?.cancel(); // Stop timer jika berhasil
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("Akun Berhasil Diverifikasi!")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomePage()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text("Kode OTP Salah atau Kadaluarsa")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      appBar: AppBar(
        title: Text("Verifikasi Akun", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.primaryGreen),
            const SizedBox(height: 24),
            Text(
              "Masukkan Kode OTP",
              style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Kami telah mengirimkan 6 digit kode ke email:\n${widget.email}",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            // --- UI TIMER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 18, color: _secondsRemaining < 60 ? Colors.red : Colors.grey),
                const SizedBox(width: 5),
                Text(
                  "Kode berakhir dalam: ",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  _formattedTime,
                  style: GoogleFonts.poppins(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    color: _secondsRemaining < 60 ? Colors.red : AppColors.primaryGreen
                  ),
                ),
              ],
            ),
            // ----------------

            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: "000000",
                hintStyle: TextStyle(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // Tombol otomatis mati (null) jika waktu habis
                onPressed: (_isLoading || _secondsRemaining == 0) ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade400, // Warna saat tombol mati
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _secondsRemaining == 0 ? "Kode Kadaluarsa" : "Verifikasi Sekarang", 
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)
                    ),
              ),
            ),

            // Opsi Kirim Ulang jika waktu habis
            if (_secondsRemaining == 0) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   // Tambahkan logic panggil API register ulang di sini untuk kirim kode baru
                   setState(() {
                     _secondsRemaining = 300;
                     _startTimer();
                   });
                },
                child: Text(
                  "Kirim Ulang Kode",
                  style: GoogleFonts.poppins(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}