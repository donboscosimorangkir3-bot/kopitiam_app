// lib/data/datasources/cart_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kopitiam_app/data/models/cart_item_model.dart'; // Import model CartItem

class CartRemoteDatasource {
  final Dio _dio = Dio(); // Gunakan _dio sebagai private instance

  // Helper untuk mendapatkan token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Helper untuk membuat Dio Options dengan token
  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // 1. Fungsi untuk menambah item ke keranjang (POST /api/cart)
  Future<bool> addToCart(int productId, int quantity) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') {
        print("Tidak ada token autentikasi. User belum login.");
        return false;
      }

      final response = await _dio.post(
        ApiConstants.cart, // POST /api/cart
        data: {
          'product_id': productId,
          'quantity': quantity,
        },
        options: options,
      );

      if (response.statusCode == 201) { // Status 201 Created
        print("Produk berhasil ditambahkan ke keranjang!");
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Gagal menambahkan ke keranjang: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Error tak terduga saat menambah ke keranjang: $e");
      return false;
    }
  }

  // 2. Fungsi untuk mendapatkan semua item di keranjang user (GET /api/cart)
  Future<List<CartItem>> getCartItems() async {
    try {
      final options = await _getAuthOptions();
       if (options.headers?['Authorization'] == 'Bearer null') {
        print("Tidak ada token autentikasi. User belum login.");
        return [];
      }

      final response = await _dio.get(
        ApiConstants.cart, // GET /api/cart
        options: options,
      );

      if (response.statusCode == 200) {
        // Balasan backend untuk GET /api/cart: { "message": "Isi keranjang user", "data": { "items": [...] } }
        // Cek jika 'data' atau 'items' null
        if (response.data != null && response.data['data'] != null && response.data['data']['items'] != null) {
            final List<dynamic> itemsJson = response.data['data']['items'];
            return itemsJson.map((json) => CartItem.fromJson(json)).toList();
        }
        return []; // Jika items null atau data null
      }
      return [];
    } on DioException catch (e) {
      print("Gagal mengambil item keranjang: ${e.response?.data}");
      return [];
    } catch (e) {
      print("Error tak terduga saat mengambil keranjang: $e");
      return [];
    }
  }

  // 3. Fungsi untuk mengupdate kuantitas item di keranjang (PATCH /api/cart/{cart_item_id})
  Future<bool> updateCartItem(int cartItemId, int quantity) async {
    try {
      final options = await _getAuthOptions();
       if (options.headers?['Authorization'] == 'Bearer null') {
        print("Tidak ada token autentikasi. User belum login.");
        return false;
      }

      final response = await _dio.patch( // Gunakan PATCH method
        '${ApiConstants.cart}/$cartItemId', // PATCH /api/cart/{cart_item_id}
        data: {
          'quantity': quantity,
        },
        options: options,
      );

      if (response.statusCode == 200) { // Status 200 OK
        print("Kuantitas item keranjang berhasil diupdate!");
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Gagal update kuantitas keranjang: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Error tak terduga saat update keranjang: $e");
      return false;
    }
  }

  // 4. Fungsi untuk menghapus item dari keranjang (DELETE /api/cart/{cart_item_id})
  Future<bool> deleteCartItem(int cartItemId) async {
    try {
      final options = await _getAuthOptions();
       if (options.headers?['Authorization'] == 'Bearer null') {
        print("Tidak ada token autentikasi. User belum login.");
        return false;
      }

      final response = await _dio.delete( // Gunakan DELETE method
        '${ApiConstants.cart}/$cartItemId', // DELETE /api/cart/{cart_item_id}
        options: options,
      );

      if (response.statusCode == 200) { // Status 200 OK
        print("Item keranjang berhasil dihapus!");
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Gagal menghapus item keranjang: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Error tak terduga saat menghapus keranjang: $e");
      return false;
    }
  }
}