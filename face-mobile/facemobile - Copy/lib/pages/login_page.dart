// // lib/pages/login_page.dart
// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
// import '../services/api_service.dart';

// class LoginPage extends StatefulWidget {
//   final String baseUrl;
  
//   const LoginPage({Key? key, required this.baseUrl}) : super(key: key);

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _login() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final dio = Dio(BaseOptions(
//         baseUrl: widget.baseUrl,
//         headers: {'Accept': 'application/json'},
//       ));

//       print('📡 Login request to: ${widget.baseUrl}/api/login');
//       print('📧 Email: ${_emailController.text}');

//       final response = await dio.post(
//         '/api/login',
//         data: {
//           'email': _emailController.text.trim(),
//           'password': _passwordController.text,
//         },
//       );

//       print('✅ Login successful');
//       print('Response: ${response.data}');

//       // Extract token from response
//       // Handle different response structures
//       String? token;
//       Map<String, dynamic>? user;
      
//       if (response.data['data'] != null) {
//         // Structure: {success, message, data: {user, token}}
//         token = response.data['data']['token'];
//         user = response.data['data']['user'];
//       } else if (response.data['token'] != null) {
//         // Structure: {token, user}
//         token = response.data['token'];
//         user = response.data['user'];
//       } else if (response.data['access_token'] != null) {
//         // Structure: {access_token, user}
//         token = response.data['access_token'];
//         user = response.data['user'];
//       }
      
//       if (token == null || token.isEmpty) {
//         throw Exception('Token tidak ditemukan dalam response');
//       }

//       print('✅ Token extracted: ${token.substring(0, 10)}...');
//       print('✅ User: ${user?['name']}');

//       // Return token and user data to previous screen
//       if (mounted) {
//         Navigator.pop(context, {
//           'token': token,
//           'user': user,
//         });
//       }
//     } on DioException catch (e) {
//       print('❌ Login error: ${e.type}');
//       print('Response: ${e.response?.data}');
      
//       String errorMessage = 'Login gagal';
      
//       if (e.response != null) {
//         switch (e.response?.statusCode) {
//           case 401:
//             errorMessage = 'Email atau password salah';
//             break;
//           case 422:
//             final errors = e.response?.data['errors'];
//             if (errors != null) {
//               errorMessage = errors.values.first[0];
//             } else {
//               errorMessage = e.response?.data['message'] ?? 'Data tidak valid';
//             }
//             break;
//           case 500:
//             errorMessage = 'Server error. Coba lagi nanti.';
//             break;
//           default:
//             errorMessage = e.response?.data['message'] ?? 'Error ${e.response?.statusCode}';
//         }
//       } else {
//         errorMessage = 'Tidak dapat terhubung ke server';
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMessage),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       print('❌ Unexpected error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   Future<void> _register() async {
//     // Navigate to register page or show register dialog
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Fitur registrasi belum tersedia')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Login'),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Logo
//                   Icon(
//                     Icons.face,
//                     size: 100,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Face Recognition\nAttendance',
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                   const SizedBox(height: 48),

//                   // Email Field
//                   TextFormField(
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: InputDecoration(
//                       labelText: 'Email',
//                       hintText: 'Enter your email',
//                       prefixIcon: const Icon(Icons.email),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Email harus diisi';
//                       }
//                       if (!value.contains('@')) {
//                         return 'Email tidak valid';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),

//                   // Password Field
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: _obscurePassword,
//                     decoration: InputDecoration(
//                       labelText: 'Password',
//                       hintText: 'Enter your password',
//                       prefixIcon: const Icon(Icons.lock),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscurePassword
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                         ),
//                         onPressed: () {
//                           setState(() => _obscurePassword = !_obscurePassword);
//                         },
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Password harus diisi';
//                       }
//                       if (value.length < 6) {
//                         return 'Password minimal 6 karakter';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 24),

//                   // Login Button
//                   ElevatedButton(
//                     onPressed: _isLoading ? null : _login,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Colors.white,
//                             ),
//                           )
//                         : const Text(
//                             'Login',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Register Link
//                   TextButton(
//                     onPressed: _isLoading ? null : _register,
//                     child: const Text('Belum punya akun? Daftar'),
//                   ),

//                   const SizedBox(height: 24),

//                   // Server Info
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Server Info',
//                             style: Theme.of(context).textTheme.titleSmall,
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             widget.baseUrl,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               fontFamily: 'monospace',
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// import '../services/api_service.dart'; // Dianggap sudah ada atau tidak diperlukan di sini

class LoginPage extends StatefulWidget {
  final String baseUrl;
  
  const LoginPage({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Mendefinisikan warna untuk tampilan modern
  final Color _primaryColor = Colors.blue.shade800;
  final Color _backgroundColor = Colors.blue.shade50;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper function untuk Notifikasi Modern
  void _showModernSnackBar(String message, {Color color = Colors.red}) {
    if (!mounted) return;

    final Color contentColor = color == Colors.red ? Colors.white : (color == Colors.white ? Colors.black : Colors.white);
    final IconData icon = color == Colors.green.shade600 
                          ? Icons.check_circle_outline 
                          : (color == Colors.red.shade600 ? Icons.error_outline : Icons.info_outline);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: contentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: contentColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color, 
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio(BaseOptions(
        baseUrl: widget.baseUrl,
        headers: {'Accept': 'application/json'},
      ));

      print('📡 Login request to: ${widget.baseUrl}/api/login');
      print('📧 Email: ${_emailController.text}');

      final response = await dio.post(
        '/api/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      print('✅ Login successful');
      print('Response: ${response.data}');

      // Extract token and user data from response
      String? token;
      Map<String, dynamic>? user;
      
      if (response.data['data'] != null) {
        // Structure: {success, message, data: {user, token}}
        token = response.data['data']['token'];
        user = response.data['data']['user'];
      } else if (response.data['token'] != null) {
        // Structure: {token, user}
        token = response.data['token'];
        user = response.data['user'];
      } else if (response.data['access_token'] != null) {
        // Structure: {access_token, user}
        token = response.data['access_token'];
        user = response.data['user'];
      }
      
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan dalam response');
      }

      print('✅ Token extracted: ${token.substring(0, 10)}...');
      print('✅ User: ${user?['name']}');

      // Notifikasi Sukses Login menggunakan gaya modern
      _showModernSnackBar('Selamat datang, ${user?['name'] ?? 'Pengguna'}! Login Berhasil.', color: Colors.green.shade600);

      // Return token and user data to previous screen
      if (mounted) {
        Navigator.pop(context, {
          'token': token,
          'user': user,
        });
      }
    } on DioException catch (e) {
      print('❌ Login error: ${e.type}');
      print('Response: ${e.response?.data}');
      
      String errorMessage = 'Login gagal';
      
      if (e.response != null) {
        switch (e.response?.statusCode) {
          case 401:
            errorMessage = 'Email atau password salah';
            break;
          case 422:
            final errors = e.response?.data['errors'];
            if (errors != null) {
              errorMessage = errors.values.first[0]; 
            } else {
              errorMessage = e.response?.data['message'] ?? 'Data tidak valid';
            }
            break;
          case 500:
            errorMessage = 'Server error. Coba lagi nanti.';
            break;
          default:
            errorMessage = e.response?.data['message'] ?? 'Error ${e.response?.statusCode}';
        }
      } else {
        errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
      }

      // Notifikasi Error menggunakan gaya modern
      _showModernSnackBar(errorMessage, color: Colors.red.shade600);
      
    } catch (e) {
      print('❌ Unexpected error: $e');
      // Notifikasi Error tak terduga menggunakan gaya modern
      _showModernSnackBar('Terjadi kesalahan tak terduga: ${e.toString()}', color: Colors.red.shade600);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    // Notifikasi Info menggunakan gaya modern
    _showModernSnackBar('Fitur registrasi belum tersedia saat ini.', color: Colors.orange.shade600);
  }

  // Helper function untuk InputDecoration yang konsisten dan modern
  InputDecoration _inputDecoration(
    BuildContext context, {
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: _primaryColor),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      // Border Modern
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none, 
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _primaryColor, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, 
      body: SafeArea(
        child: Container(
          // Gradien latar belakang
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_backgroundColor, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo dan Header
                    Icon(
                      Icons.fingerprint_rounded, 
                      size: 90,
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.grey.shade800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login untuk masuk ke sistem Presensi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.grey.shade800),
                      decoration: _inputDecoration(
                        context,
                        labelText: 'Email',
                        hintText: 'Masukkan email Anda',
                        icon: Icons.alternate_email_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email harus diisi';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: Colors.grey.shade800),
                      decoration: _inputDecoration(
                        context,
                        labelText: 'Password',
                        hintText: 'Masukkan password Anda',
                        icon: Icons.lock_open_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password harus diisi';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Login Button (Elevated Modern)
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4), 
                          ),
                        ],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _primaryColor, 
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), 
                          ),
                          elevation: 0, // Dikelola oleh Container
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Login Sekarang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Link
                    TextButton(
                      onPressed: _isLoading ? null : _register,
                      child: Text(
                        'Belum punya akun? Daftar',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Server Info Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Server API',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              widget.baseUrl,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}