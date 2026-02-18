import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRemoteDatasource {
  final Dio dio = Dio();

  // Fungsi Login
  Future<bool> login(String email, String password) async {
    try {
      final response = await dio.post(
        ApiConstants.login, // URL http://10.0.2.2:8000/api/login
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {'Accept': 'application/json'}, // Wajib ada
        ),
      );

      if (response.statusCode == 200) {
        // Ambil Token dari balasan server
        final token = response.data['access_token'];
        
        // Simpan Token ke Memori HP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        
        return true; // Login Sukses
      }
      return false;
    } on DioException catch (e) {
      // Jika password salah atau server error
      print("Login Gagal: ${e.response?.data}");
      return false;
    }
  }

  // Fungsi Cek Apakah User Sudah Login (Cek Token)
  Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null;
  }

  // Fungsi Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}