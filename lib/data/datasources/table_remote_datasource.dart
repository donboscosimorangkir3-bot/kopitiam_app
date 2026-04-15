import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/table_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TableRemoteDatasource {
  final _dio = Dio();

  // ─── Helper: Ambil Token ────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Options _authOptions(String? token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  // ─── Get All Tables ─────────────────────────────────────────────────────────

  Future<List<TableModel>> getTables() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/tables',
        options: _authOptions(token),
      );

      debugPrint('[getTables] response.data: ${response.data}');

      final raw = response.data;
      List dataList;

      if (raw is List) {
        dataList = raw;
      } else if (raw is Map && raw['data'] is List) {
        dataList = raw['data'] as List;
      } else {
        debugPrint('[getTables] Struktur response tidak dikenali: $raw');
        return [];
      }

      return dataList.map((e) => TableModel.fromJson(e)).toList();
    } catch (e, stack) {
      debugPrint('[getTables] ERROR: $e');
      debugPrint('$stack');
      return [];
    }
  }

  // ─── Save Table (Tambah / Edit Nomor) ──────────────────────────────────────

  Future<bool> saveTable(String number, {int? id}) async {
    try {
      final token = await _getToken();
      final options = _authOptions(token);

      final Response response;
      if (id == null) {
        response = await _dio.post(
          '${ApiConstants.baseUrl}/tables',
          data: {'number': number},
          options: options,
        );
      } else {
        response = await _dio.put(
          '${ApiConstants.baseUrl}/tables/$id',
          data: {'number': number},
          options: options,
        );
      }

      debugPrint('[saveTable] status: ${response.statusCode}, data: ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      debugPrint('[saveTable] ERROR: $e');
      debugPrint('$stack');
      return false;
    }
  }

  // ─── Update Table Status (Aktif / Rusak) ───────────────────────────────────

  Future<bool> updateTable(int id, String number, bool isAvailable) async {
    try {
      final token = await _getToken();
      final response = await _dio.put(
        '${ApiConstants.baseUrl}/tables/$id',
        data: {
          'number': number,
          'is_available': isAvailable ? 1 : 0,
        },
        options: _authOptions(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[updateTable] ERROR: $e');
      return false;
    }
  }

  // ─── Delete Table ───────────────────────────────────────────────────────────

  Future<bool> deleteTable(int id) async {
    try {
      final token = await _getToken();
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/tables/$id',
        options: _authOptions(token),
      );
      debugPrint('[deleteTable] status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e, stack) {
      debugPrint('[deleteTable] ERROR: $e');
      debugPrint('$stack');
      return false;
    }
  }
}