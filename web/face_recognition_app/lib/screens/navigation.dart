import 'package:face_recognition_app/screens/face_register_screen.dart';
import 'package:face_recognition_app/screens/face_verify_screen.dart';
import 'package:face_recognition_app/screens/home_screen.dart';
import 'package:face_recognition_app/screens/login_screen.dart';
import 'package:face_recognition_app/screens/register_screen.dart';
import 'package:flutter/material.dart';


class AppNavigation {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/face-register':
        return MaterialPageRoute(builder: (_) => const FaceRegisterScreen());
      case '/face-verify':
        return MaterialPageRoute(builder: (_) => const FaceVerifyScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}