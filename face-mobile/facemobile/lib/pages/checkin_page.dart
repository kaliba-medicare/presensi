import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/face_service.dart';
import '../services/api_service.dart';
import '../widgets/blink_detection_camera.dart';

class CheckinPage extends StatefulWidget {
  final ApiService api;
  const CheckinPage({Key? key, required this.api}) : super(key: key);
  
  @override
  _CheckinPageState createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  final FaceService _faceService = FaceService();
  bool loading = false;
  bool modelLoaded = false;
  String statusMessage = 'Loading face model...';

  // Gaya Modern
  final Color _primaryColor = const Color(0xFF3B82F6); 
  final Color _backgroundColor = const Color(0xFFF0F4F8); 
  final double _borderRadius = 20.0;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

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

  Future<void> _initializeModel() async {
    setState(() {
      loading = true;
      statusMessage = 'Memuat model pengenalan wajah...';
    });
    try {
      await _faceService.loadModel();
      setState(() {
        modelLoaded = true;
        statusMessage = 'Model siap. Tekan tombol untuk Check-in.';
        loading = false;
      });
    } catch (e) {
      setState(() {
        modelLoaded = false;
        statusMessage = 'Gagal memuat model: ${e.toString()}';
        loading = false;
      });
      _showModernSnackBar('Gagal memuat model pengenalan wajah', color: Colors.red.shade600);
    }
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  // NEW: Open blink detection camera
  Future<void> openBlinkDetectionCamera() async {
    if (!modelLoaded) {
      _showModernSnackBar('Model belum siap. Harap tunggu.', color: Colors.orange.shade600);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlinkDetectionCamera(
          onImageCaptured: (imagePath) {
            Navigator.pop(context);
            _processVerification(imagePath);
          },
          onCancel: () {
            Navigator.pop(context);
            setState(() => statusMessage = 'Pengambilan foto dibatalkan');
          },
        ),
      ),
    );
  }

  Future<void> _processVerification(String imagePath) async {
    setState(() {
      loading = true;
      statusMessage = 'Memproses verifikasi wajah...';
    });

    // Panggil fungsi dengan liveness detection
    final result = await _faceService.getEmbeddingFromImageFile(imagePath);
    
    if (result == null) {
      _showModernSnackBar('Terjadi kesalahan saat memproses gambar.', color: Colors.red.shade600);
      setState(() {
        loading = false;
        statusMessage = 'Proses gagal.';
      });
      return;
    }
    
    // Cek apakah ada error
    if (result.containsKey('error')) {
      final errorType = result['error'];
      final errorMessage = result['message'] ?? 'Error tidak diketahui';
      
      if (errorType == 'no_face') {
        _showModernSnackBar('❌ Wajah tidak terdeteksi. Silakan coba lagi.', color: Colors.red.shade600);
      } else if (errorType == 'not_live') {
        _showModernSnackBar(
          '🚫 Verifikasi gagal! Gunakan wajah asli.', 
          color: Colors.orange.shade700
        );
      } else {
        _showModernSnackBar(errorMessage, color: Colors.red.shade600);
      }
      
      setState(() {
        loading = false;
        statusMessage = 'Verifikasi gagal.';
      });
      return;
    }
    
    // Ambil embedding dari hasil
    final embedding = result['embedding'] as List<double>?;
    if (embedding == null) {
      _showModernSnackBar('Gagal mengekstrak data wajah.', color: Colors.red.shade600);
      setState(() {
        loading = false;
        statusMessage = 'Ekstraksi wajah gagal.';
      });
      return;
    }
    
    setState(() => statusMessage = 'Wajah terdeteksi & diverifikasi. Mengirim ke server...');

    // Persiapan data untuk API
    final bytes = await File(imagePath).readAsBytes();
    final base64Img = 'data:image/jpeg;base64,' + base64Encode(bytes);

    try {
      final resp = await widget.api.verifyFace(embedding);
      
      final livenessInfo = result['liveness'] as Map<String, dynamic>?;
      final confidence = livenessInfo?['confidence'] ?? 100.0;
      
      _showModernSnackBar(
        '✅ ${resp['message'] ?? 'Check-in Berhasil!'} (Liveness: ${confidence.toStringAsFixed(0)}/100)', 
        color: Colors.green.shade600
      );
      
      setState(() {
        statusMessage = 'Check-in berhasil!';
      });
    } catch (e) {
      _showModernSnackBar('❌ Verifikasi Gagal: Wajah tidak cocok atau error server.', color: Colors.red.shade600);
      
      setState(() {
        statusMessage = 'Verifikasi Gagal.';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady = modelLoaded && !loading;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text('Check-in Presensi', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon Utama dengan Badge Liveness
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_pin_circle_rounded,
                      size: 100,
                      color: isReady ? _primaryColor : Colors.grey.shade400,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),

              // Status Message Box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isReady ? Colors.green.shade50 : _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isReady ? Colors.green.shade200 : _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isReady ? Icons.check_circle_outline : Icons.sync_problem_rounded,
                      color: isReady ? Colors.green.shade700 : _primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusMessage,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info Box Blink Detection
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sistem deteksi kedipan mata - TIDAK BISA DITIPU dengan foto!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),
              
              // Tombol Utama
              loading
                  ? Column(
                      children: [
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                        const SizedBox(height: 16),
                        Text('Memproses Verifikasi...', style: TextStyle(color: _primaryColor)),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: isReady ? openBlinkDetectionCamera : null,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Mulai Verifikasi Wajah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_borderRadius),
                        ),
                        elevation: 5,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                
                const SizedBox(height: 20),

                if (!modelLoaded && !loading)
                  TextButton(
                    onPressed: _initializeModel,
                    child: Text('Coba Muat Ulang Model', style: TextStyle(color: Colors.red.shade700)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}