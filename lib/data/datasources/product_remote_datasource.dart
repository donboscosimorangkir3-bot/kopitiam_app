// lib/data/datasources/product_remote_datasource.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductRemoteDatasource {
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

  // GET ALL PRODUCTS (Public & Admin)
  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get(ApiConstants.products);

      if (response.statusCode == 200) {
        final List<dynamic> productList = response.data['data'];
        return productList.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error fetching products from API: ${e.response?.data}");
      if (e.response != null) {
        print("Response data: ${e.response?.data}");
      }
      return [];
    } catch (e) {
      print("Unexpected error when getting products: $e");
      return [];
    }
  }

  // GET PRODUCT BY ID (Admin/Owner)
  Future<Product?> getProductById(int id) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return null;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/admin/products/$id', // URL Admin
        options: options,
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print("Error fetching product by ID: ${e.response?.data}");
      return null;
    }
  }

  // ADD PRODUCT (Admin/Owner)
  Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final formData = FormData.fromMap(productData);
      
      final response = await _dio.post(
        ApiConstants.baseUrl + '/admin/products', // URL Admin
        data: formData,
        options: options,
      );

      return response.statusCode == 201;
    } on DioException catch (e) {
      print("Error adding product: ${e.response?.data}");
      return false;
    }
  }

  // UPDATE PRODUCT (Admin/Owner)
  Future<bool> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      // Dio akan otomatis mengirim sebagai multipart/form-data jika ada File
      final formData = FormData.fromMap(productData);

      final response = await _dio.post( // Gunakan POST karena ada potensi kirim file
        '${ApiConstants.baseUrl}/admin/products/$id', // URL Admin
        data: formData,
        options: options,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error updating product: ${e.response?.data}");
      return false;
    }
  }

  // DELETE PRODUCT (Admin/Owner)
  Future<bool> deleteProduct(int id) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/admin/products/$id', // URL Admin
        options: options,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error deleting product: ${e.response?.data}");
      return false;
    }
  }
}