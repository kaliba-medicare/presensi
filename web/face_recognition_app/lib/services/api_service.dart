import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator localhost
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  // Authentication APIs
  Future<Response> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });
      return response;
    } on DioException catch (e) {
      throw e;
    }
  }

  Future<Response> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        await _storage.write(key: 'token', value: token);
      }
      
      return response;
    } on DioException catch (e) {
      throw e;
    }
  }

  Future<Response> logout() async {
    try {
      final response = await _dio.post('/logout');
      await _storage.delete(key: 'token');
      return response;
    } on DioException catch (e) {
      throw e;
    }
  }

  Future<Response> getUser() async {
    try {
      final response = await _dio.get('/user');
      return response;
    } on DioException catch (e) {
      throw e;
    }
  }

  // Face Recognition APIs
  Future<Response> registerFace(List<double> embedding) async {
    try {
      final response = await _dio.post('/face/register', data: {
        'embedding': embedding,
      });
      return response;
    } on DioException catch (e) {
      throw e;
    }
  }

  Future<Response> verifyFace(List<double> embedding, {String? photoBase64, Map<String, dynamic>? location}) async {
    try {
      final Map<String, dynamic> data = {
        'embedding': embedding,
      };
      
      if (photoBase64 != null) {
        data['photo_base64'] = photoBase64;
      }
      
      if (location != null) {
        data['location'] = location;
      }
      
      final response = await _dio.post('/face/verify', data: data);
      return response;
    } on DioException catch (e) {
      throw e;
    }
  }
}