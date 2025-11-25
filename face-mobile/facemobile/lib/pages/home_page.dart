import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enroll_page.dart';
import 'checkin_page.dart';
import '../services/api_service.dart';
import '../main.dart'; // Import LoginPageWrapper

class HomePage extends StatefulWidget {
  final String? token;
  final String baseUrl;
  final Map<String, dynamic>? userData;

  const HomePage({
    Key? key,
    required this.token,
    required this.baseUrl,
    this.userData,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late ApiService api;
  bool isConnected = false;
  bool isLoading = false;
  String statusMessage = '';

  // Gaya Modern
  final Color _primaryColor = const Color(0xFF3B82F6);
  final Color _backgroundColor = const Color(0xFFF0F4F8);
  final double _borderRadius = 16.0;

  @override
  void initState() {
    super.initState();
    api = ApiService(widget.baseUrl, widget.token!);
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Testing connection to server...';
    });

    try {
      final connected = await api.testConnection();
      setState(() {
        isConnected = connected;
        isLoading = false;
        statusMessage = connected
            ? 'Connected to server ✓'
            : 'Cannot connect to server';
      });
    } catch (e) {
      setState(() {
        isConnected = false;
        isLoading = false;
        statusMessage = 'Connection error: ${e.toString().split(':')[0]}';
      });
    }
  }

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
                    isConnected ? 'Not Connected' : 'Login Required',
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

  List<Widget> _buildPages() {
    return [
      // Dashboard Page
      SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Info Card with improved design
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: _primaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userData?['name'] ?? 'User',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.userData?['email'] ?? 'user@example.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.verified,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Additional user info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildUserInfoItem(Icons.badge, 'ID', widget.userData?['id']?.toString() ?? 'N/A'),
                          _buildUserInfoItem(Icons.calendar_today, 'Joined', _formatDate(widget.userData?['created_at'])),
                          _buildUserInfoItem(Icons.update, 'Updated', _formatDate(widget.userData?['updated_at'])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Connection Status
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
                          fontWeight: FontWeight.w600,
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

            const SizedBox(height: 32),

            // Action Buttons
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
                  onPressed: isConnected
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EnrollPage(api: api)),
                          )
                      : null,
                  color: Colors.blue,
                ),

                // Check-in Button
                _buildActionButton(
                  title: 'Presensi Check-in',
                  icon: Icons.fingerprint_rounded,
                  onPressed: isConnected
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CheckinPage(api: api)),
                          )
                      : null,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // API Info
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
                    _buildInfoRow('Base URL', widget.baseUrl, Icons.link_rounded),
                    _buildInfoRow(
                        'Token', widget.token != null ? '${widget.token!.substring(0, 10)}...' : 'Not set', Icons.vpn_key_rounded),

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

      // Enroll Page
      EnrollPage(api: api),

      // Check-in Page
      CheckinPage(api: api),
    ];
  }

  // Widget for user info items
  Widget _buildUserInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: _primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // Helper function to format dates
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text(
          'Presensi Face',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Clear saved token
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.remove('user_data');
              
              // Navigate back to login
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPageWrapper(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _buildPages()[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Enroll',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Check-in',
          ),
        ],
      ),
    );
  }
}