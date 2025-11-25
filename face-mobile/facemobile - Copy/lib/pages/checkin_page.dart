// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../services/face_service.dart';
// import '../services/api_service.dart';

// class CheckinPage extends StatefulWidget {
//   final ApiService api;
//   CheckinPage({required this.api});
//   @override
//   _CheckinPageState createState() => _CheckinPageState();
// }

// class _CheckinPageState extends State<CheckinPage> {
//   final FaceService _faceService = FaceService();
//   bool loading = false;

//   @override
//   void initState(){
//     super.initState();
//     _faceService.loadModel();
//   }

//   Future<void> takeAndVerify() async {
//     final picker = ImagePicker();
//     final XFile? file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
//     if (file == null) return;
//     setState(()=>loading=true);

//     final embedding = await _faceService.getEmbeddingFromImageFile(file.path);
//     if (embedding == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wajah tidak terdeteksi')));
//       setState(()=>loading=false);
//       return;
//     }

//     final bytes = await File(file.path).readAsBytes();
//     final base64Img = 'data:image/jpeg;base64,' + base64Encode(bytes);

//     try {
//       final resp = await widget.api.verifyFace(embedding, );
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? 'OK - similarity:${resp['similarity']}')));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Face not matched')));
//     } finally {
//       setState(()=>loading=false);
//     }
//   }

//   @override
//   Widget build(BuildContext context){
//     return Scaffold(
//       appBar: AppBar(title: Text('Check-in')),
//       body: Center(
//         child: loading ? CircularProgressIndicator() : ElevatedButton(
//           onPressed: takeAndVerify, child: Text('Take Photo & Check-in')
//         ),
//       ),
//     );
//   }
// }



// lib/pages/checkin_page.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_service.dart';
import '../services/api_service.dart';

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

  // Helper function untuk Notifikasi Modern (diambil dari halaman Login/Enroll)
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

  // LOGIKA VERIFIKASI (TIDAK BERUBAH)
  Future<void> takeAndVerify() async {
    if (!modelLoaded) {
      _showModernSnackBar('Model belum siap. Harap tunggu.', color: Colors.orange.shade600);
      return;
    }
    
    final picker = ImagePicker();
    // Memaksa menggunakan kamera depan untuk presensi
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );
    
    if (file == null) {
      setState(() => statusMessage = 'Pengambilan foto dibatalkan');
      return;
    }
    
    setState(() {
      loading = true;
      statusMessage = 'Mendeteksi wajah...';
    });

    final embedding = await _faceService.getEmbeddingFromImageFile(file.path);
    
    if (embedding == null) {
      _showModernSnackBar('Wajah tidak terdeteksi. Silakan coba lagi.', color: Colors.red.shade600);
      setState(() {
        loading = false;
        statusMessage = 'Deteksi wajah gagal.';
      });
      return;
    }
    
    setState(() => statusMessage = 'Wajah terdeteksi. Verifikasi...');

    // Persiapan data untuk API
    final bytes = await File(file.path).readAsBytes();
    final base64Img = 'data:image/jpeg;base64,' + base64Encode(bytes);

    try {
      // Mengirim embedding dan base64 image ke API
      final resp = await widget.api.verifyFace(embedding);
      
      // Notifikasi Sukses
      _showModernSnackBar(
        resp['message'] ?? 'Check-in Berhasil! Similarity: ${resp['similarity']}', 
        color: Colors.green.shade600
      );
      
      setState(() {
        statusMessage = 'Check-in berhasil!';
      });
    } catch (e) {
      // Notifikasi Gagal
      _showModernSnackBar('Verifikasi Gagal: Wajah tidak cocok atau error server.', color: Colors.red.shade600);
      
      setState(() {
        statusMessage = 'Verifikasi Gagal.';
      });
    } finally {
      setState(() => loading = false);
    }
  }
  // END LOGIKA VERIFIKASI

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
              // Ikon Utama
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
              
              const SizedBox(height: 40),

              // Status Message Box (Modern Alert)
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

              const SizedBox(height: 60),
              
              // Tombol Utama (Action Button)
              loading
                  ? Column(
                      children: [
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                        const SizedBox(height: 16),
                        Text('Memproses Verifikasi...', style: TextStyle(color: _primaryColor)),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: isReady ? takeAndVerify : null,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Ambil Foto & Check-in'),
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

                // Tombol Bantuan (Retry/Info)
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