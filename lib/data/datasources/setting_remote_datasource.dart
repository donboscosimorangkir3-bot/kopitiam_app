// lib/data/datasources/setting_remote_datasource.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/setting_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingRemoteDatasource {
  final Dio _dio = Dio();

  // Ambil Data
  Future<CafeSettings?> getSettings() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/settings');
      if (response.statusCode == 200) {
        return CafeSettings.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update Data (Teks + Gambar)
  Future<bool> updateSettings(CafeSettings settings, File? imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Siapkan Map data dari model
      Map<String, dynamic> dataMap = settings.toJson();

      // Jika ada file gambar baru, masukkan ke Map
      if (imageFile != null) {
        dataMap['image'] = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        );
      }

      // Ubah Map menjadi FormData
      FormData formData = FormData.fromMap(dataMap);

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/settings/update',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error Update: $e");
      return false;
    }
  }
}