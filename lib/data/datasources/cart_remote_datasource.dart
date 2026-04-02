// lib/data/datasources/cart_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kopitiam_app/data/models/cart_item_model.dart';

class CartRemoteDatasource {
  final Dio _dio = Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {
        'Accept':        'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // 1. TAMBAH ITEM KE KERANJANG
  // temperature hanya dikirim jika tidak null (produk dengan varian suhu)
  Future<bool> addToCart(int productId, int quantity, {String? temperature}) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final Map<String, dynamic> body = {
        'product_id': productId,
        'quantity':   quantity,
      };

      // Hanya sertakan temperature jika produk punya varian suhu
      if (temperature != null) {
        body['temperature'] = temperature;
      }

      final response = await _dio.post(
        ApiConstants.cart,
        data:    body,
        options: options,
      );

      return response.statusCode == 201;
    } on DioException catch (e) {
      print("Gagal menambahkan ke keranjang: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Error tak terduga saat menambah ke keranjang: $e");
      return false;
    }
  }

  // 2. GET KERANJANG
  Future<List<CartItem>> getCartItems() async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return [];

      final response = await _dio.get(ApiConstants.cart, options: options);

      if (response.statusCode == 200) {
        if (response.data != null &&
            response.data['data'] != null &&
            response.data['data']['items'] != null) {
          final List<dynamic> itemsJson = response.data['data']['items'];
          return itemsJson.map((json) => CartItem.fromJson(json)).toList();
        }
        return [];
      }
      return [];
    } on DioException catch (e) {
      print("Gagal mengambil item keranjang: ${e.response?.data}");
      return [];
    } catch (e) {
      print("Error tak terduga: $e");
      return [];
    }
  }

  // 3. UPDATE QUANTITY
  Future<bool> updateCartItem(int cartItemId, int quantity) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final response = await _dio.patch(
        '${ApiConstants.cart}/$cartItemId',
        data:    {'quantity': quantity},
        options: options,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Gagal update kuantitas: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Error tak terduga: $e");
      return false;
    }
  }

  // 4. HAPUS ITEM
  Future<bool> deleteCartItem(int cartItemId) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final response = await _dio.delete(
        '${ApiConstants.cart}/$cartItemId',
        options: options,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Gagal menghapus item: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Error tak terduga: $e");
      return false;
    }
  }
}