import 'package:face_recognition_app/screens/face_register_screen.dart';
import 'package:face_recognition_app/screens/face_verify_screen.dart';
import 'package:face_recognition_app/screens/home_screen.dart';
import 'package:face_recognition_app/screens/login_screen.dart';
import 'package:face_recognition_app/screens/register_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/face-register': (context) => const FaceRegisterScreen(),
        '/face-verify': (context) => const FaceVerifyScreen(),
      },
    );
  }
}