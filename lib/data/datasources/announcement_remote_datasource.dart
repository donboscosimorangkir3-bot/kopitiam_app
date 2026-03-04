// lib/data/datasources/announcement_remote_datasource.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:kopitiam_app/core/api_constants.dart';
import 'package:kopitiam_app/data/models/announcement_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementRemoteDatasource {
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

  // GET ALL ANNOUNCEMENTS (Public for customer, All for admin)
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await _dio.get(ApiConstants.baseUrl + '/announcements');

      if (response.statusCode == 200) {
        final List<dynamic> announcementList = response.data['data'];
        return announcementList.map((json) => Announcement.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print("Error fetching announcements: ${e.response?.data}");
      return [];
    } catch (e) {
      print("Unexpected error when getting announcements: $e");
      return [];
    }
  }

  // CREATE ANNOUNCEMENT (Admin/Owner)
  Future<bool> createAnnouncement(Map<String, dynamic> announcementData) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final formData = FormData.fromMap(announcementData);
      
      final response = await _dio.post(
        ApiConstants.baseUrl + '/admin/announcements',
        data: formData,
        options: options,
      );

      return response.statusCode == 201;
    } on DioException catch (e) {
      print("Error creating announcement: ${e.response?.data}");
      return false;
    }
  }

  // UPDATE ANNOUNCEMENT (Admin/Owner)
  Future<bool> updateAnnouncement(int id, Map<String, dynamic> announcementData) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final formData = FormData.fromMap(announcementData);

      final response = await _dio.post( // Gunakan POST karena ada potensi kirim file
        '${ApiConstants.baseUrl}/admin/announcements/$id',
        data: formData,
        options: options,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error updating announcement: ${e.response?.data}");
      return false;
    }
  }

  // DELETE ANNOUNCEMENT (Admin/Owner)
  Future<bool> deleteAnnouncement(int id) async {
    try {
      final options = await _getAuthOptions();
      if (options.headers?['Authorization'] == 'Bearer null') return false;

      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/admin/announcements/$id',
        options: options,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Error deleting announcement: ${e.response?.data}");
      return false;
    }
  }
}