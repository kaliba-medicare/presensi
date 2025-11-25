import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/face_service.dart';
import '../services/api_service.dart';
import '../widgets/blink_detection_camera.dart';

class EnrollPage extends StatefulWidget {
  final ApiService api;
  const EnrollPage({Key? key, required this.api}) : super(key: key);
  
  @override
  _EnrollPageState createState() => _EnrollPageState();
}

class _EnrollPageState extends State<EnrollPage> {
  final FaceService _faceService = FaceService();
  bool loading = false;
  bool modelLoaded = false;
  String? capturedImagePath;
  String statusMessage = '';

  // Gaya Modern
  final Color _primaryColor = const Color(0xFF3B82F6); 
  final Color _backgroundColor = const Color(0xFFFFFFFF); 
  final double _borderRadius = 16.0;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  void _showModernSnackBar(String message, {Color color = Colors.red}) {
    if (!mounted) return;

    final Color contentColor = Colors.white;
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
        duration: const Duration(seconds: 4),
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
        statusMessage = 'Model siap. Silakan ambil foto wajah Anda.';
        loading = false;
      });
    } catch (e) {
      setState(() {
        modelLoaded = false;
        statusMessage = 'Gagal memuat model: $e';
        loading = false;
      });
      _showModernSnackBar('Gagal memuat model pengenalan wajah', color: Colors.red.shade600);
    }
  }

  // Open blink detection camera
  Future<void> openBlinkDetectionCamera() async {
    if (!modelLoaded) {
      _showModernSnackBar('Model belum siap, harap tunggu', color: Colors.orange.shade600);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlinkDetectionCamera(
          onImageCaptured: (imagePath) {
            Navigator.pop(context);
            setState(() => capturedImagePath = imagePath);
            _processEnrollment(imagePath);
          },
          onCancel: () {
            Navigator.pop(context);
            setState(() => statusMessage = 'Pengambilan foto dibatalkan');
          },
        ),
      ),
    );
  }

  Future<void> _processEnrollment(String imagePath) async {
    setState(() {
      loading = true;
      statusMessage = 'Mendeteksi wajah...';
    });

    print('📷 Image captured: $imagePath');
    
    // Read image bytes and encode to base64 for sending to server
    final bytes = await File(imagePath).readAsBytes();
    final base64Img = 'data:image/jpeg;base64,' + base64Encode(bytes);

    // Extract face embedding dengan liveness detection
    final result = await _faceService.getEmbeddingFromImageFile(imagePath);
    
    if (result == null) {
      _showModernSnackBar('Terjadi kesalahan saat memproses gambar.', color: Colors.red.shade600);
      setState(() {
        statusMessage = 'Proses gagal.';
        loading = false;
      });
      return;
    }
    
    // Cek apakah ada error
    if (result.containsKey('error')) {
      final errorType = result['error'];
      final errorMessage = result['message'] ?? 'Error tidak diketahui';
      
      setState(() {
        statusMessage = 'Verifikasi gagal.';
        loading = false;
      });

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
      
      return;
    }
    
    // Ambil embedding dari hasil
    final embedding = result['embedding'] as List<double>?;
    if (embedding == null) {
      _showModernSnackBar('Gagal mengekstrak data wajah.', color: Colors.red.shade600);
      setState(() {
        statusMessage = 'Ekstraksi wajah gagal.';
        loading = false;
      });
      return;
    }

    setState(() => statusMessage = 'Wajah terdeteksi & diverifikasi! Mendaftarkan...');
    print('✅ Face detected, embedding size: ${embedding.length}');

    try {
      // Register to server
      final resp = await widget.api.registerFace(embedding, base64Img);
      
      setState(() {
        statusMessage = 'Pendaftaran berhasil!';
        loading = false;
      });

      final livenessInfo = result['liveness'] as Map<String, dynamic>?;
      final confidence = livenessInfo?['confidence'] ?? 100.0;

      // Notifikasi Sukses
      _showModernSnackBar(
        '✅ ${resp['message'] ?? 'Wajah berhasil didaftarkan'} (Liveness: ${confidence.toStringAsFixed(0)}/100)', 
        color: Colors.green.shade600
      );
        
      // Navigate back after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: ${e.toString()}';
        loading = false;
      });
      
      print('❌ Error in enrollment: $e');
      
      // Notifikasi Gagal
      _showModernSnackBar('Gagal mendaftarkan wajah: ${e.toString()}', color: Colors.red.shade600);
    }
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text(
          'Pendaftaran Wajah', 
          style: TextStyle(
            color: Colors.grey.shade800, 
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Header Ikon dengan Badge Keamanan
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 80,
                  color: _primaryColor.withOpacity(0.8),
                ),
                Positioned(
                  bottom: 0,
                  right: 100,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Siapkan Wajah Anda',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dengan deteksi kedipan mata real-time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // Preview image (Modern Card)
            if (capturedImagePath != null)
              Container(
                height: 300,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_borderRadius),
                  child: Image.file(
                    File(capturedImagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            // Status message (Modern Alert Box)
            if (statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      loading 
                          ? Icons.sync 
                          : (modelLoaded ? Icons.check_circle_outline : Icons.warning_amber_rounded),
                      color: loading 
                          ? _primaryColor 
                          : (modelLoaded ? Colors.green : Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (loading)
                      const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ),
                  ],
                ),
              ),

            // Info Box Blink Detection
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
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
                      'Sistem deteksi kedipan mata - Foto dari layar TIDAK AKAN BISA LOLOS!',
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

            // Main Button
            if (loading && capturedImagePath == null) 
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memproses...', 
                      style: TextStyle(color: _primaryColor),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: modelLoaded && !loading ? openBlinkDetectionCamera : null,
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(
                  capturedImagePath == null 
                      ? 'Mulai Pendaftaran Wajah' 
                      : 'Ambil Foto Ulang',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  elevation: 5,
                  textStyle: const TextStyle(
                    fontSize: 17, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Instructions (Modern Card)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: _primaryColor, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Cara Menggunakan',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    _buildInstruction('Posisikan wajah Anda di dalam frame oval yang terlihat'),
                    _buildInstruction('Pastikan pencahayaan cukup baik dan wajah terlihat jelas'),
                    _buildInstruction('Tunggu hingga wajah terdeteksi (frame akan berubah warna)'),
                    _buildInstruction('Kedipkan KEDUA mata Anda secara bergantian atau bersamaan'),
                    _buildInstruction('Foto akan diambil OTOMATIS setelah kedipan terdeteksi'),
                    _buildInstruction('TIDAK perlu menekan tombol - cukup kedipkan mata!'),
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