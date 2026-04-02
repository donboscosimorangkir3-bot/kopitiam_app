// lib/data/datasources/order_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderRemoteDatasource {
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

  // Fungsi untuk mendapatkan riwayat pesanan user (GET /api/orders)
  Future<List<Order>> getMyOrders() async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') {
        print("Tidak ada token autentikasi. User belum login.");
        return [];
      }

      final response = await _dio.get(
        ApiConstants.baseUrl + '/orders',
        options: options,
      );

      if (response.statusCode == 200) {
        final List<dynamic> orderListJson = response.data['data'];
        return orderListJson.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Gagal mengambil riwayat pesanan: ${e.response?.data}");
      return [];
    } catch (e) {
      print("Error tak terduga saat mengambil riwayat pesanan: $e");
      return [];
    }
  }

  // Fungsi untuk mendapatkan SEMUA pesanan (khusus Admin/Kasir/Owner) - GET /api/admin/orders
  Future<List<Order>> getAllOrders() async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') {
        print("Tidak ada token autentikasi. User belum login.");
        return [];
      }

      final response = await _dio.get(
        ApiConstants.baseUrl + '/admin/orders', // <-- URL untuk Admin
        options: options,
      );

      if (response.statusCode == 200) {
        final List<dynamic> orderListJson = response.data['data'];
        return orderListJson.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Gagal mengambil semua pesanan (Admin): ${e.response?.data}");
      return [];
    } catch (e) {
      print("Error tak terduga saat mengambil semua pesanan: $e");
      return [];
    }
  }

  // Fungsi untuk mengupdate status pesanan (PATCH /api/admin/orders/{id}/status)
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') {
        print("Tidak ada token autentikasi. User belum login.");
        return false;
      }

      final response = await _dio.patch(
        // URL Admin (sesuai routes/api.php)
        '${ApiConstants.baseUrl}/admin/orders/$orderId/status', // <-- PERBAIKAN URL INI!
        data: {
          'status': newStatus,
        },
        options: options,
      );

      if (response.statusCode == 200) {
        print("Status pesanan $orderId berhasil diupdate ke $newStatus!");
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Gagal update status pesanan: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Error tak terduga saat update status: $e");
      return false;
    }
  }
  // Fungsi untuk Membuat Pesanan Manual oleh Kasir (POST /api/admin/orders/manual)
  Future<bool> createManualOrder(Map<String, dynamic> orderData) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/admin/orders/manual',
        data: orderData,
        options: options,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Gagal membuat pesanan manual: ${e.response?.data}");
      return false;
    } catch (e) {
      print("Error tak terduga: $e");
      return false;
    }
  }
}