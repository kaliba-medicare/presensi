// import 'package:flutter/material.dart';
// import 'pages/login_page.dart';
// import 'pages/enroll_page.dart';
// import 'pages/checkin_page.dart';
// import 'services/api_service.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Presensi Face',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: HomePage(),
//     );
//   }
// }

// class HomePage extends StatefulWidget {
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   ApiService? api;
//   bool isConnected = false;
//   bool isLoading = false;
//   bool isAuthenticated = false;
//   String statusMessage = '';
//   Map<String, dynamic>? userData;

//   // TODO: Ganti dengan URL server Anda
//   final String baseUrl = 'http://192.168.10.213:8000';
//   String? token;

//   @override
//   void initState() {
//     super.initState();
//     // Don't initialize API or test connection until user logs in
//   }

//   Future<void> _login() async {
//     final result = await Navigator.push<Map<String, dynamic>>(
//       context,
//       MaterialPageRoute(
//         builder: (context) => LoginPage(baseUrl: baseUrl),
//       ),
//     );

//     if (result != null && result['token'] != null) {
//       setState(() {
//         token = result['token'];
//         userData = result['user'];
//         api = ApiService(baseUrl, token!);
//         isAuthenticated = true;
//       });
      
//       _testConnection();
//     }
//   }

//   Future<void> _logout() async {
//     // Optionally call logout API
//     if (api != null) {
//       try {
//         await api!.dio.post('/api/logout');
//       } catch (e) {
//         print('Logout error: $e');
//       }
//     }

//     setState(() {
//       token = null;
//       api = null;
//       isAuthenticated = false;
//       isConnected = false;
//       userData = null;
//       statusMessage = '';
//     });
//   }

//   Future<void> _testConnection() async {
//     if (api == null) return;
    
//     setState(() {
//       isLoading = true;
//       statusMessage = 'Testing connection to server...';
//     });

//     try {
//       final connected = await api!.testConnection();
//       setState(() {
//         isConnected = connected;
//         isLoading = false;
//         statusMessage = connected
//             ? 'Connected to server ✓'
//             : 'Cannot connect to server';
//       });
//     } catch (e) {
//       setState(() {
//         isConnected = false;
//         isLoading = false;
//         statusMessage = 'Connection error: $e';
//       });
//     }
//   }

//   void _showSettingsDialog() {
//     final urlController = TextEditingController(text: baseUrl);
//     final tokenController = TextEditingController(text: token);

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('API Settings'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: urlController,
//               decoration: const InputDecoration(
//                 labelText: 'Base URL',
//                 hintText: 'http://192.168.x.x:8000',
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: tokenController,
//               decoration: const InputDecoration(
//                 labelText: 'Token',
//                 hintText: 'Bearer token',
//               ),
//               obscureText: true,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // TODO: Save settings and recreate API service
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Settings saved. Restart app to apply.'),
//                 ),
//               );
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Presensi Face'),
//         centerTitle: true,
//         actions: [
//           if (isAuthenticated) ...[
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: _testConnection,
//               tooltip: 'Test Connection',
//             ),
//             IconButton(
//               icon: const Icon(Icons.logout),
//               onPressed: _logout,
//               tooltip: 'Logout',
//             ),
//           ] else
//             IconButton(
//               icon: const Icon(Icons.login),
//               onPressed: _login,
//               tooltip: 'Login',
//             ),
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: _showSettingsDialog,
//             tooltip: 'API Settings',
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Logo or App Name
//             Icon(
//               Icons.face,
//               size: 100,
//               color: Theme.of(context).primaryColor,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Face Recognition Attendance',
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 32),

//             // User Info Card (if logged in)
//             if (isAuthenticated && userData != null)
//               Card(
//                 color: Colors.blue.shade50,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         child: Text(
//                           userData!['name']?.substring(0, 1).toUpperCase() ?? 'U',
//                           style: const TextStyle(fontSize: 24),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               userData!['name'] ?? 'User',
//                               style: Theme.of(context).textTheme.titleMedium,
//                             ),
//                             Text(
//                               userData!['email'] ?? '',
//                               style: Theme.of(context).textTheme.bodySmall,
//                             ),
//                           ],
//                         ),
//                       ),
//                       Icon(Icons.check_circle, color: Colors.green),
//                     ],
//                   ),
//                 ),
//               ),

//             // Login prompt if not authenticated
//             if (!isAuthenticated)
//               Card(
//                 color: Colors.orange.shade50,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       Icon(Icons.lock, size: 48, color: Colors.orange),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Login Required',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Silakan login terlebih dahulu untuk menggunakan fitur face recognition',
//                         textAlign: TextAlign.center,
//                         style: Theme.of(context).textTheme.bodySmall,
//                       ),
//                       const SizedBox(height: 12),
//                       ElevatedButton.icon(
//                         onPressed: _login,
//                         icon: const Icon(Icons.login),
//                         label: const Text('Login Now'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//             const SizedBox(height: 16),

//             // Connection Status Card
//             if (isAuthenticated)
//               Card(
//                 color: isConnected
//                     ? Colors.green.shade50
//                     : Colors.orange.shade50,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       Icon(
//                         isConnected ? Icons.check_circle : Icons.warning,
//                         color: isConnected ? Colors.green : Colors.orange,
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Server Status',
//                               style: Theme.of(context).textTheme.titleSmall,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               isLoading ? 'Checking...' : statusMessage,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: isConnected
//                                     ? Colors.green.shade900
//                                     : Colors.orange.shade900,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (isLoading)
//                         const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
            
//             if (isAuthenticated) const SizedBox(height: 32),

//             // Enroll Button
//             ElevatedButton.icon(
//               onPressed: (isAuthenticated && isConnected && api != null)
//                   ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => EnrollPage(api: api!),
//                         ),
//                       )
//                   : null,
//               icon: const Icon(Icons.person_add),
//               label: const Text('Enroll Face'),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 textStyle: const TextStyle(fontSize: 16),
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Check-in Button
//             ElevatedButton.icon(
//               onPressed: (isAuthenticated && isConnected && api != null)
//                   ? () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => CheckinPage(api: api!),
//                         ),
//                       )
//                   : null,
//               icon: const Icon(Icons.login),
//               label: const Text('Check-in'),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 textStyle: const TextStyle(fontSize: 16),
//               ),
//             ),
//             const SizedBox(height: 32),

//             // API Info
//             if (isAuthenticated)
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'API Configuration',
//                         style: Theme.of(context).textTheme.titleSmall,
//                       ),
//                       const SizedBox(height: 8),
//                       _buildInfoRow('Base URL', baseUrl),
//                       _buildInfoRow('Token', token != null ? '${token!.substring(0, 10)}...' : 'Not set'),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Endpoints tersedia:',
//                         style: Theme.of(context).textTheme.bodySmall,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '• POST /api/face/register\n'
//                         '• POST /api/face/verify\n'
//                         '• GET /api/user',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                               fontFamily: 'monospace',
//                               fontSize: 11,
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 12),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/enroll_page.dart';
import 'pages/checkin_page.dart';
import 'services/api_service.dart';

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
        // Tema yang lebih modern dan konsisten
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Latar belakang abu-abu muda
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ApiService? api;
  bool isConnected = false;
  bool isLoading = false;
  bool isAuthenticated = false;
  String statusMessage = '';
  Map<String, dynamic>? userData;

  // Constants for Modern Design
  final Color _primaryColor = const Color(0xFF3B82F6);
  final double _borderRadius = 16.0;

  // TODO: Ganti dengan URL server Anda
  final String baseUrl = 'http://192.168.10.213:8000';
  String? token;

  // Helper function untuk Notifikasi Modern
  void _showModernSnackBar(String message, {Color color = Colors.red}) {
    if (!mounted) return;

    final Color contentColor = color == Colors.red.shade600 ? Colors.white : Colors.white;
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
  // END Helper function

  @override
  void initState() {
    super.initState();
    // Don't initialize API or test connection until user logs in
  }

  Future<void> _login() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(baseUrl: baseUrl),
      ),
    );

    if (result != null && result['token'] != null) {
      setState(() {
        token = result['token'];
        userData = result['user'];
        api = ApiService(baseUrl, token!);
        isAuthenticated = true;
      });
      
      _testConnection();
      _showModernSnackBar('Login Berhasil! Selamat datang, ${userData?['name']}', color: Colors.green.shade600);
    }
  }

  Future<void> _logout() async {
    // Optionally call logout API
    if (api != null) {
      try {
        await api!.dio.post('/api/logout');
      } catch (e) {
        print('Logout error: $e');
      }
    }

    setState(() {
      token = null;
      api = null;
      isAuthenticated = false;
      isConnected = false;
      userData = null;
      statusMessage = '';
    });
    _showModernSnackBar('Anda telah berhasil Logout', color: Colors.orange.shade600);
  }

  Future<void> _testConnection() async {
    if (api == null) return;
    
    setState(() {
      isLoading = true;
      statusMessage = 'Testing connection to server...';
    });

    try {
      final connected = await api!.testConnection();
      setState(() {
        isConnected = connected;
        isLoading = false;
        statusMessage = connected
            ? 'Connected to server ✓'
            : 'Cannot connect to server';
      });
      if (!connected) {
        _showModernSnackBar('Gagal terhubung ke server API', color: Colors.red.shade600);
      }
    } catch (e) {
      setState(() {
        isConnected = false;
        isLoading = false;
        statusMessage = 'Connection error: ${e.toString().split(':')[0]}';
      });
      _showModernSnackBar('Terjadi error koneksi: ${e.toString().split(':')[0]}', color: Colors.red.shade600);
    }
  }

  void _showSettingsDialog() {
    final urlController = TextEditingController(text: baseUrl);
    final tokenController = TextEditingController(text: token);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
        title: Text('API Settings', style: TextStyle(color: _primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: _modernInputDecoration('Base URL', Icons.public),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: _modernInputDecoration('Token', Icons.vpn_key),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Save settings and recreate API service
              Navigator.pop(context);
              _showModernSnackBar('Settings saved. Restart app to apply.', color: Colors.orange.shade600);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Widget untuk tombol aksi utama (Enroll/Checkin)
  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            color: onPressed != null ? color.withOpacity(0.1) : Colors.grey.shade100,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: onPressed != null ? color : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onPressed != null ? Colors.grey.shade800 : Colors.grey.shade500,
                ),
              ),
              if (onPressed == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    isAuthenticated ? 'Not Connected' : 'Login Required',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Info Row Modern
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _primaryColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget Decoration Modern
  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: _primaryColor),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool canProceed = isAuthenticated && isConnected && api != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Presensi Face', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
            tooltip: 'API Settings',
          ),
          if (isAuthenticated)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _testConnection,
              tooltip: 'Test Connection',
            ),
          if (isAuthenticated)
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          if (!isAuthenticated)
            IconButton(
              icon: Icon(Icons.login, color: Colors.white),
              onPressed: _login,
              tooltip: 'Login',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // ==================== 1. STATUS KONEKSI & USER ====================
            
            // Connection Status Card (Modern)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(
                      isAuthenticated ? Icons.check_circle_outlined : Icons.login_rounded,
                      size: 30,
                      color: isAuthenticated ? Colors.green.shade600 : Colors.orange.shade600,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAuthenticated ? 'Logged In as' : 'Status: Logged Out',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAuthenticated 
                                ? userData!['name'] ?? userData!['email'] ?? 'User' 
                                : 'Silakan Login untuk Presensi.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isAuthenticated ? Colors.grey.shade800 : Colors.orange.shade700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (!isAuthenticated)
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Login'),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Server Status (Modern Alert Card)
            if (isAuthenticated)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isLoading ? 'Checking connection...' : statusMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: isConnected ? Colors.green.shade900 : Colors.red.shade900,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ),
                      if (isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                        ),
                      if (!isLoading)
                         IconButton(
                           icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                           onPressed: _testConnection,
                           padding: EdgeInsets.zero,
                           constraints: const BoxConstraints(),
                         ),
                    ],
                  ),
                ),
              ),

            // ==================== 2. ACTION BUTTONS ====================
            
            if (isAuthenticated) const SizedBox(height: 32),
            if (isAuthenticated)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Enroll Button
                  _buildActionButton(
                    title: 'Daftar Wajah',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: canProceed
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EnrollPage(api: api!)),
                            )
                        : null,
                    color: Colors.blue,
                  ),
                  
                  // Check-in Button
                  _buildActionButton(
                    title: 'Presensi Check-in',
                    icon: Icons.fingerprint_rounded,
                    onPressed: canProceed
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CheckinPage(api: api!)),
                            )
                        : null,
                    color: Colors.green,
                  ),
                ],
              ),
            
            // ==================== 3. API CONFIG INFO ====================
            
            if (isAuthenticated) const SizedBox(height: 32),
            if (isAuthenticated)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Configuration',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildInfoRow('Base URL', baseUrl, Icons.link_rounded),
                      _buildInfoRow('Token', token != null ? '${token!.substring(0, 10)}...' : 'Not set', Icons.vpn_key_rounded),
                      
                      const SizedBox(height: 16),
                      Text(
                        'Available Endpoints:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• POST /api/login\n• POST /api/logout\n• POST /api/face/register\n• POST /api/face/verify',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
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
    );
  }
}