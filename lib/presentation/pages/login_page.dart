// lib/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kopitiam_app/core/app_colors.dart';
import 'package:kopitiam_app/data/datasources/auth_remote_datasource.dart';
import 'package:kopitiam_app/presentation/pages/initial_wrapper_page.dart';
import 'package:kopitiam_app/presentation/pages/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kopitiam_app/presentation/pages/otp_page.dart';
import 'package:kopitiam_app/presentation/pages/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMeEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================
  // LOAD REMEMBER ME DATA
  // =========================
  Future<void> _loadRememberMeEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remember_email');
    final savedRemember = prefs.getBool('remember_me') ?? false;

    if (savedEmail != null && savedRemember) {
      _emailController.text = savedEmail;
      if (!mounted) return;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  // =========================
  // HANDLE LOGIN
  // =========================
  Future<void> _handleLogin() async {
  if (_emailController.text.isEmpty ||
      _passwordController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Email dan Password harus diisi!"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authService = AuthRemoteDatasource();
    final success = await authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setString(
            'remember_email', _emailController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remember_email');
        await prefs.setBool('remember_me', false);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const InitialWrapperPage(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Berhasil!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Gagal. Cek email/password Anda."),
          backgroundColor: Colors.red,
        ),
      );
    }
  } on DioException catch (e) {
    if (!mounted) return;

    setState(() => _isLoading = false);

    // Jika belum verifikasi (403)
    if (e.response?.statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Akun belum diverifikasi. Silakan OTP."),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OtpPage(email: _emailController.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email atau Password salah"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terjadi kesalahan, coba lagi."),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // =========================
  // BUILD UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 30),

              Text(
                "Welcome Back!",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "Silahkan masuk untuk melanjutkan.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color:
                      AppColors.lightCream.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 40),

              _buildInputField(
                controller: _emailController,
                hintText: "Masukkan Email",
                icon: Icons.email_outlined,
                keyboardType:
                    TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                controller: _passwordController,
                hintText: "Masukkan Password",
                icon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible:
                    _isPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isPasswordVisible =
                        !_isPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 15),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe =
                                value ?? false;
                          });
                        },
                        activeColor:
                            AppColors.lightCream,
                        checkColor:
                            AppColors.darkGreen,
                        materialTapTargetSize:
                            MaterialTapTargetSize
                                .shrinkWrap,
                      ),
                      Text(
                        "Ingat Saya",
                        style: GoogleFonts.poppins(
                            color:
                                AppColors.white),
                      ),
                    ],
                  ),
                  TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordPage(),
      ),
    );
  },
  child: Text(
    "Lupa Password?",
    style: GoogleFonts.poppins(
      color: AppColors.white,
    ),
  ),
),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.lightCream,
                    foregroundColor:
                        AppColors.darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color:
                              AppColors.darkGreen)
                      : Text(
                          "Masuk",
                          style:
                              GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    "Belum punya akun? ",
                    style: GoogleFonts.poppins(
                        color: AppColors.white),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const RegisterPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Daftar",
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontWeight:
                            FontWeight.bold,
                        decoration:
                            TextDecoration
                                .underline,
                        decorationColor:
                            AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // INPUT FIELD WIDGET
  // =========================
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? toggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightCream,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText:
            isPassword && !isPasswordVisible,
        style: GoogleFonts.poppins(
            color: AppColors.darkBrown),
        decoration: InputDecoration(
          prefixIcon:
              Icon(icon,
                  color:
                      AppColors.primaryGreen),
          hintText: hintText,
          hintStyle:
              GoogleFonts.poppins(
            color: AppColors.primaryGreen
                .withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors
                        .primaryGreen,
                  ),
                  onPressed:
                      toggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}