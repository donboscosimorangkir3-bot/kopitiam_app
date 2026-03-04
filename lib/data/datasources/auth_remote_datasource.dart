import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kopitiam_app/data/models/user_model.dart';

class AuthRemoteDatasource {
  final Dio _dio = Dio();

  // Fungsi Register
  Future<bool> register(String name, String email, String password, String phone) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 201) {
        final token = response.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Register Gagal: ${e.response?.data}");
      return false;
    }
  }

  // Fungsi Login
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        final userJson = response.data['data'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Simpan user sebagai JSON string yang valid
        await prefs.setString('user_info', jsonEncode(userJson));

        return true;
      }

      return false;
    } on DioException catch (e) {
      print("Login Gagal: ${e.response?.data}");
      return false;
    }
  }

  // Cek apakah user sudah login
  Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');
  }

  // Fungsi untuk mendapatkan informasi user yang login
  Future<User?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('user_info');

    // Jika ada di local, ambil dari SharedPreferences
    if (userJsonString != null) {
      final Map<String, dynamic> userMap = jsonDecode(userJsonString);
      return User.fromJson(userMap);
    }

    // Jika tidak ada, ambil dari API
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/user',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } on DioException catch (e) {
      print("Error fetching user info: ${e.response?.data}");
    }

    return null;
  }
}