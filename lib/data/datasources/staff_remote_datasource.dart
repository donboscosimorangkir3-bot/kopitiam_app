// lib/data/datasources/staff_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffRemoteDatasource {
  final Dio _dio = Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // GET ALL STAFF (Owner)
  Future<List<User>> getStaff() async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return [];

      final response = await _dio.get(
        ApiConstants.baseUrl + '/admin/staff',
        options: options,
      );

      if (response.statusCode == 200) {
        final List<dynamic> staffList = response.data['data'];
        return staffList.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error fetching staff: ${e.response?.data}");
      return [];
    } catch (e) {
      print("Unexpected error when getting staff: $e");
      return [];
    }
  }

  // CREATE STAFF (Owner)
  Future<bool> createStaff(Map<String, dynamic> staffData) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final response = await _dio.post(
        ApiConstants.baseUrl + '/admin/staff',
        data: staffData,
        options: options,
      );

      return response.statusCode == 201;
    } on DioException catch (e) {
      print("Error creating staff: ${e.response?.data}");
      return false;
    }
  }

  // UPDATE STAFF (Owner)
  Future<bool> updateStaff(int id, Map<String, dynamic> staffData) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final response = await _dio.put(
        '${ApiConstants.baseUrl}/admin/staff/$id',
        data: staffData,
        options: options,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error updating staff: ${e.response?.data}");
      return false;
    }
  }

  // DELETE STAFF (Owner)
  Future<bool> deleteStaff(int id) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/admin/staff/$id',
        options: options,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error deleting staff: ${e.response?.data}");
      return false;
    }
  }
}