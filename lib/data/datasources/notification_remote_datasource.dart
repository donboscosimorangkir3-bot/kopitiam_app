import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationRemoteDatasource {
  final Dio _dio = Dio();

  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/notifications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        List data = response.data['data'];
        return data.map((json) => AppNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}