// lib/data/datasources/report_remote_datasource.dart

import 'dart:convert';
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

  // ── GET RINGKASAN STATISTIK DASHBOARD ───────────
  Future<ReportSummary?> getReportSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final Map<String, dynamic> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/admin/reports/summary',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
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

  // ── GET LAPORAN PENJUALAN DETAIL ─────────────────
  Future<List<Order>> getDetailedSales({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final Map<String, dynamic> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/admin/reports/sales',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> orderListJson = response.data['data'];
        return orderListJson.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error fetching detailed sales report: ${e.response?.data}");
      return [];
    } catch (e, stackTrace) {
      print("Unexpected error when getting detailed sales report: $e");
      print("StackTrace: ${stackTrace.toString().split('\n').take(5).join('\n')}");
      return [];
    }
  }

  // ── EKSPOR LAPORAN KE FILE EXCEL ─────────────────
  Future<Response?> exportSalesFile({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print("Login diperlukan untuk ekspor laporan.");
        return null;
      }

      final Map<String, dynamic> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      // ✅ FIX 1: Buat Options baru langsung dengan semua header sekaligus
      //    — jangan overwrite headers setelah Options dibuat
      // ✅ FIX 2: responseType = bytes HANYA untuk request ekspor ini
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/admin/reports/export',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Accept': 'text/csv, application/octet-stream',
            'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final contentType = response.headers.value('content-type') ?? '';
      final isValidFile = contentType.contains('text/csv') ||
          contentType.contains('octet-stream') ||
          contentType.contains('spreadsheetml');

      if (response.statusCode == 200 && isValidFile) {
        // Sukses — kembalikan response berisi bytes file Excel
        return response;
      } else {
        // Server return error — decode bytes ke string untuk logging
        final errorBody = utf8.decode(
          response.data is List<int>
              ? response.data as List<int>
              : List<int>.from(response.data),
          allowMalformed: true,
        );

        // Coba parse JSON jika bisa
        try {
          final decoded = jsonDecode(errorBody);
          print("Export error ${response.statusCode}: ${decoded['message']} "
              "(${decoded['file'] ?? ''}:${decoded['line'] ?? ''})");
        } catch (_) {
          // Bukan JSON (mungkin HTML) — print 200 karakter pertama saja
          print("Export error ${response.statusCode}: "
              "${errorBody.substring(0, errorBody.length.clamp(0, 200))}");
        }
        return null;
      }
    } on DioException catch (e) {
      // Decode error bytes jika ada
      if (e.response?.data is List<int>) {
        final errorBody = utf8.decode(
          e.response!.data as List<int>,
          allowMalformed: true,
        );
        print("DioException export (${e.response?.statusCode}): "
            "${errorBody.substring(0, errorBody.length.clamp(0, 300))}");
      } else {
        print("DioException export: ${e.message}");
      }
      return null;
    } catch (e) {
      print("Unexpected error when exporting sales report: $e");
      return null;
    }
  }
}