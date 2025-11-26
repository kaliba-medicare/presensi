import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'dart:convert'; // Add this import for JSON encoding

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presensi Face',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPageWrapper(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<bool> _authCheck;

  @override
  void initState() {
    super.initState();
    _authCheck = _checkAuthStatus();
  }

  Future<bool> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const HomePageWrapper();
        } else {
          return const LoginPageWrapper();
        }
      },
    );
  }
}

class LoginPageWrapper extends StatefulWidget {
  const LoginPageWrapper({super.key});

  @override
  State<LoginPageWrapper> createState() => _LoginPageWrapperState();
}

class _LoginPageWrapperState extends State<LoginPageWrapper> {
  // TODO: Ganti dengan URL server Anda
  final String baseUrl = 'http://192.168.10.166:8000';

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      baseUrl: baseUrl,
    );
  }
}

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  // TODO: Ganti dengan URL server Anda
  final String baseUrl = 'http://192.168.10.166:8000';
  Map<String, dynamic>? userData;
  String? token;
  late Future<void> _loadData;

  @override
  void initState() {
    super.initState();
    _loadData = _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    
    // Load user data from shared preferences
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        // Parse the JSON string to get user data
        userData = jsonDecode(userDataString);
      } catch (e) {
        print('Error parsing user data: $e');
        // Fallback to default user data
        userData = {
          'id': 0,
          'name': 'User',
          'email': 'user@example.com',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
      }
    } else {
      userData = {
        'id': 0,
        'name': 'User',
        'email': 'user@example.com',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (token == null) {
          // Token not found, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return HomePage(
          token: token,
          baseUrl: baseUrl,
          userData: userData,
        );
      },
    );
  }
}