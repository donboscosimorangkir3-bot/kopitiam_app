import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/table_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TableRemoteDatasource {
  final _dio = Dio();

  Future<List<TableModel>> getTables() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/tables',
        options: options,
      );

      // Debug: print response untuk cek struktur
      print('[getTables] response.data: ${response.data}');

      // Handle berbagai kemungkinan struktur response
      final raw = response.data;
      List dataList;
      if (raw is List) {
        dataList = raw;
      } else if (raw is Map && raw['data'] is List) {
        dataList = raw['data'];
      } else {
        print('[getTables] Struktur response tidak dikenali: $raw');
        return [];
      }

      return dataList.map((e) => TableModel.fromJson(e)).toList();
    } catch (e, stack) {
      print('[getTables] ERROR: $e');
      print(stack);
      return [];
    }
  }

  Future<bool> saveTable(String number, {int? id}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      Response response;
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

      print('[saveTable] status: ${response.statusCode}, data: ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      print('[saveTable] ERROR: $e');
      print(stack);
      return false;
    }
  }

  Future<bool> deleteTable(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/tables/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('[deleteTable] status: ${response.statusCode}');
      return true;
    } catch (e, stack) {
      print('[deleteTable] ERROR: $e');
      print(stack);
      return false;
    }
  }
}