// lib/data/datasources/report_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/report_summary_model.dart';
import 'package:kopitiam_app/data/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ReportRemoteDatasource {
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

  // GET RINGKASAN STATISTIK DASHBOARD
  Future<ReportSummary?> getReportSummary({DateTime? startDate, DateTime? endDate}) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return null;

      final Map<String, dynamic> queryParams = {};
      if (startDate != null) queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      if (endDate != null) queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);

      final response = await _dio.get(
        ApiConstants.baseUrl + '/admin/reports/summary',
        queryParameters: queryParams,
        options: options,
      );

      if (response.statusCode == 200) {
        return ReportSummary.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      print("Error fetching report summary: ${e.response?.data}");
      return null;
    } catch (e) {
      print("Unexpected error when getting report summary: $e");
      return null;
    }
  }

  // GET LAPORAN PENJUALAN DETAIL
  Future<List<Order>> getDetailedSales({DateTime? startDate, DateTime? endDate}) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return [];

      final Map<String, dynamic> queryParams = {};
      if (startDate != null) queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      if (endDate != null) queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);

      final response = await _dio.get(
        ApiConstants.baseUrl + '/admin/reports/sales',
        queryParameters: queryParams,
        options: options,
      );

      if (response.statusCode == 200) {
        final List<dynamic> orderListJson = response.data['data'];
        return orderListJson.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error fetching detailed sales report: ${e.response?.data}");
      return [];
    } catch (e) {
      print("Unexpected error when getting detailed sales report: $e");
      return [];
    }
  }

  // FUNGSI BARU: EKSPOR LAPORAN (mengembalikan Response untuk di-download file)
  Future<Response?> exportSalesFile({DateTime? startDate, DateTime? endDate}) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') {
        print("Login diperlukan untuk ekspor laporan.");
        return null;
      }

      final Map<String, dynamic> queryParams = {};
      if (startDate != null) queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      if (endDate != null) queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);

      // Set Accept header untuk menerima file Excel
      options.headers?['Accept'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      options.responseType = ResponseType.bytes; // Terima respons sebagai bytes

      final response = await _dio.get(
        ApiConstants.baseUrl + '/admin/reports/export',
        queryParameters: queryParams,
        options: options,
      );

      // Backend harus mengembalikan file, jadi statusCode 200 adalah sukses
      if (response.statusCode == 200) {
        return response; // Mengembalikan objek Response lengkap
      }
      return null;
    } on DioException catch (e) {
      print("Error exporting sales report: ${e.response?.data ?? e.message}");
      return e.response; // Mengembalikan response jika ada error
    } catch (e) {
      print("Unexpected error when exporting sales report: $e");
      return null;
    }
  }
}