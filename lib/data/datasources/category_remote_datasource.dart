// lib/data/datasources/category_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryRemoteDatasource {
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

  // GET ALL CATEGORIES (Public & Admin)
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);

      if (response.statusCode == 200) {
        final List<dynamic> categoryList = response.data['data'];
        return categoryList.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error fetching categories: ${e.response?.data}");
      return [];
    } catch (e) {
      print("Unexpected error when getting categories: $e");
      return [];
    }
  }

  // CREATE CATEGORY (Admin/Owner)
  Future<bool> createCategory(String name) async { // <-- Ubah nama fungsi ini menjadi createCategory
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        ApiConstants.baseUrl + '/admin/categories',
        data: {'name': name},
        options: options,
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      print("Error creating category: ${e.response?.data}");
      return false;
    }
  }

  // UPDATE CATEGORY (Admin/Owner)
  Future<bool> updateCategory(int id, String name) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/admin/categories/$id',
        data: {'name': name},
        options: options,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error updating category: ${e.response?.data}");
      return false;
    }
  }

  // DELETE CATEGORY (Admin/Owner)
  Future<bool> deleteCategory(int id) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/admin/categories/$id',
        options: options,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error deleting category: ${e.response?.data}");
      return false;
    }
  }
}