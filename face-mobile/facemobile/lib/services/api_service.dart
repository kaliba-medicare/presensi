// lib/services/api_service.dart
import 'dart:io';

import 'package:dio/dio.dart';

class ApiService {
  final Dio dio;

  ApiService(String baseUrl, String token)
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    // Add interceptor for logging
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🌐 API Request: ${options.method} ${options.uri}');
          print('📤 Headers: ${options.headers}');
          print('📤 Body: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ API Response: ${response.statusCode}');
          print('📥 Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.message}');
          print('❌ Status Code: ${error.response?.statusCode}');
          print('❌ Response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  // Register face embedding
  Future<dynamic> registerFace(
    List<double> embedding,
    String? photoBase64,
  ) async {
    try {
      print('📡 Registering face with ${embedding.length} dimensions...');

      final resp = await dio.post(
        '/api/face/register',
        data: {
          'embedding': embedding,
          'photo_base64': photoBase64,
        },
      );

      return resp.data;
    } on DioException catch (e) {
      print('❌ Register Face Error: ${e.type}');

      if (e.response != null) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');

        switch (e.response?.statusCode) {
          case 404:
            throw Exception(
              'Endpoint tidak ditemukan. Periksa URL API: ${dio.options.baseUrl}/api/face/register',
            );
          case 401:
            throw Exception('Token tidak valid atau expired');
          case 422:
            throw Exception('Data tidak valid: ${e.response?.data}');
          case 500:
            throw Exception('Server error: ${e.response?.data}');
          default:
            throw Exception(
              'Error ${e.response?.statusCode}: ${e.response?.data}',
            );
        }
      } else {
        // Network error
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Koneksi timeout. Periksa jaringan internet Anda.');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Server tidak merespon. Coba lagi nanti.');
        } else {
          throw Exception(
            'Tidak dapat terhubung ke server. Periksa URL: ${dio.options.baseUrl}',
          );
        }
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Error tidak terduga: $e');
    }
  }

  /// Verify face for check-in
  Future<dynamic> verifyFace(
    List<double> embedding, {
    String? photoBase64,
    String? location,
  }) async {
    try {
      print('📡 Verifying face with ${embedding.length} dimensions...');

      final resp = await dio.post(
        '/api/face/verify',
        data: {
          'embedding': embedding,
          if (photoBase64 != null) 'photo_base64': photoBase64,
          if (location != null) 'location': location,
        },
      );

      return resp.data;
    } on DioException catch (e) {
      print('❌ Verify Face Error: ${e.type}');

      if (e.response != null) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');

        switch (e.response?.statusCode) {
          case 404:
            throw Exception(
              'Endpoint tidak ditemukan. Periksa URL API: ${dio.options.baseUrl}/api/face/verify',
            );
          case 401:
            throw Exception('Token tidak valid atau expired');
          case 422:
            throw Exception('Data tidak valid: ${e.response?.data}');
          case 500:
            throw Exception('Server error: ${e.response?.data}');
          default:
            throw Exception(
              'Error ${e.response?.statusCode}: ${e.response?.data}',
            );
        }
      } else {
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Koneksi timeout. Periksa jaringan internet Anda.');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Server tidak merespon. Coba lagi nanti.');
        } else {
          throw Exception(
            'Tidak dapat terhubung ke server. Periksa URL: ${dio.options.baseUrl}',
          );
        }
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Error tidak terduga: $e');
    }
  }

  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      print('🔍 Testing connection to: ${dio.options.baseUrl}');
      // Test with /api/user endpoint since it's protected but available
      final response = await dio.get('/api/user');
      print('✅ Server is reachable');
      return true;
    } catch (e) {
      print('❌ Server is not reachable: $e');
      // Still return true if we get 401 (means server is up but needs auth)
      if (e is DioException && e.response?.statusCode == 401) {
        print('⚠️ Server is reachable but endpoint requires authentication');
        return true;
      }
      return false;
    }
  }
}
