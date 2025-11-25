// // // lib/pages/enroll_page.dart
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import '../services/face_service.dart';
// // import '../services/api_service.dart';

// // class EnrollPage extends StatefulWidget {
// //   final ApiService api;
// //   const EnrollPage({Key? key, required this.api}) : super(key: key);
  
// //   @override
// //   _EnrollPageState createState() => _EnrollPageState();
// // }

// // class _EnrollPageState extends State<EnrollPage> {
// //   final FaceService _faceService = FaceService();
// //   bool loading = false;
// //   bool modelLoaded = false;
// //   String? capturedImagePath;
// //   String statusMessage = '';

// //   @override
// //   void initState() {
// //     super.initState();
// //     _initializeModel();
// //   }

// //   Future<void> _initializeModel() async {
// //     setState(() {
// //       loading = true;
// //       statusMessage = 'Loading face recognition model...';
// //     });

// //     try {
// //       await _faceService.loadModel();
// //       setState(() {
// //         modelLoaded = true;
// //         statusMessage = 'Model loaded successfully';
// //         loading = false;
// //       });
// //     } catch (e) {
// //       setState(() {
// //         modelLoaded = false;
// //         statusMessage = 'Failed to load model: $e';
// //         loading = false;
// //       });
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Failed to load face recognition model'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //   }

// //   Future<void> pickAndEnroll() async {
// //     if (!modelLoaded) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Model belum siap, harap tunggu')),
// //       );
// //       return;
// //     }

// //     final picker = ImagePicker();
    
// //     try {
// //       // Show dialog to choose camera or gallery
// //       final source = await showDialog<ImageSource>(
// //         context: context,
// //         builder: (context) => AlertDialog(
// //           title: const Text('Pilih Sumber Gambar'),
// //           content: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               ListTile(
// //                 leading: const Icon(Icons.camera_alt),
// //                 title: const Text('Kamera'),
// //                 onTap: () => Navigator.pop(context, ImageSource.camera),
// //               ),
// //               // ListTile(
// //               //   leading: const Icon(Icons.photo_library),
// //               //   title: const Text('Galeri'),
// //               //   onTap: () => Navigator.pop(context, ImageSource.gallery),
// //               // ),
// //             ],
// //           ),
// //         ),
// //       );

// //       if (source == null) return;

// //       final XFile? file = await picker.pickImage(
// //         source: source,
// //         imageQuality: 90, // Higher quality for better detection
// //         preferredCameraDevice: CameraDevice.front,
// //         maxWidth: 1920,
// //         maxHeight: 1920,
// //       );
      
// //       if (file == null) {
// //         setState(() => statusMessage = 'Photo capture cancelled');
// //         return;
// //       }

// //       setState(() {
// //         loading = true;
// //         capturedImagePath = file.path;
// //         statusMessage = 'Detecting face in image...';
// //       });

// //       print('📷 Image captured: ${file.path}');

// //       // Extract face embedding
// //       final embedding = await _faceService.getEmbeddingFromImageFile(file.path);
      
// //       if (embedding == null) {
// //         setState(() {
// //           statusMessage = 'Face not detected - Please try again';
// //           loading = false;
// //         });
// //         if (mounted) {
// //           showDialog(
// //             context: context,
// //             builder: (context) => AlertDialog(
// //               title: const Text('Wajah Tidak Terdeteksi'),
// //               content: const Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text('Pastikan:'),
// //                   SizedBox(height: 8),
// //                   Text('• Wajah terlihat jelas dan menghadap kamera'),
// //                   Text('• Pencahayaan cukup baik'),
// //                   Text('• Tidak ada yang menutupi wajah (masker/tangan)'),
// //                   Text('• Wajah tidak terlalu kecil dalam foto'),
// //                 ],
// //               ),
// //               actions: [
// //                 TextButton(
// //                   onPressed: () => Navigator.pop(context),
// //                   child: const Text('OK'),
// //                 ),
// //                 TextButton(
// //                   onPressed: () {
// //                     Navigator.pop(context);
// //                     pickAndEnroll(); // Retry
// //                   },
// //                   child: const Text('Coba Lagi'),
// //                 ),
// //               ],
// //             ),
// //           );
// //         }
// //         return;
// //       }

// //       setState(() => statusMessage = 'Face detected! Registering...');
// //       print('✅ Face detected, embedding size: ${embedding.length}');

// //       // Register to server
// //       final resp = await widget.api.registerFace(embedding);
      
// //       setState(() {
// //         statusMessage = 'Face registered successfully';
// //         loading = false;
// //       });

// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(resp['message'] ?? 'Wajah berhasil didaftarkan'),
// //             backgroundColor: Colors.green,
// //             duration: const Duration(seconds: 2),
// //           ),
// //         );
        
// //         // Navigate back after success
// //         Future.delayed(const Duration(seconds: 2), () {
// //           if (mounted) Navigator.pop(context, true);
// //         });
// //       }
      
// //     } catch (e) {
// //       setState(() {
// //         statusMessage = 'Error: ${e.toString()}';
// //         loading = false;
// //       });
      
// //       print('❌ Error in pickAndEnroll: $e');
      
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Gagal mendaftarkan wajah: ${e.toString()}'),
// //             backgroundColor: Colors.red,
// //             duration: const Duration(seconds: 3),
// //           ),
// //         );
// //       }
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _faceService.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Daftar Wajah'),
// //         centerTitle: true,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             // Preview image if captured
// //             if (capturedImagePath != null)
// //               Container(
// //                 height: 300,
// //                 margin: const EdgeInsets.only(bottom: 20),
// //                 decoration: BoxDecoration(
// //                   border: Border.all(color: Colors.grey),
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: ClipRRect(
// //                   borderRadius: BorderRadius.circular(12),
// //                   child: Image.file(
// //                     File(capturedImagePath!),
// //                     fit: BoxFit.cover,
// //                   ),
// //                 ),
// //               ),

// //             // Status message
// //             if (statusMessage.isNotEmpty)
// //               Container(
// //                 padding: const EdgeInsets.all(12),
// //                 margin: const EdgeInsets.only(bottom: 20),
// //                 decoration: BoxDecoration(
// //                   color: Colors.blue.shade50,
// //                   borderRadius: BorderRadius.circular(8),
// //                   border: Border.all(color: Colors.blue.shade200),
// //                 ),
// //                 child: Text(
// //                   statusMessage,
// //                   textAlign: TextAlign.center,
// //                   style: TextStyle(
// //                     color: Colors.blue.shade900,
// //                     fontSize: 14,
// //                   ),
// //                 ),
// //               ),

// //             // Loading indicator or button
// //             if (loading)
// //               const Center(
// //                 child: Column(
// //                   children: [
// //                     CircularProgressIndicator(),
// //                     SizedBox(height: 16),
// //                     Text('Memproses...'),
// //                   ],
// //                 ),
// //               )
// //             else
// //               ElevatedButton.icon(
// //                 onPressed: modelLoaded ? pickAndEnroll : null,
// //                 icon: const Icon(Icons.camera_alt),
// //                 label: const Text('Ambil Foto & Daftar'),
// //                 style: ElevatedButton.styleFrom(
// //                   padding: const EdgeInsets.symmetric(vertical: 16),
// //                   textStyle: const TextStyle(fontSize: 16),
// //                 ),
// //               ),

// //             const SizedBox(height: 12),

// //             // Instructions
// //             Card(
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16.0),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       'Petunjuk Pengambilan Foto:',
// //                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
// //                             fontWeight: FontWeight.bold,
// //                           ),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     _buildInstruction('Pastikan wajah terlihat jelas dan menghadap kamera'),
// //                     _buildInstruction('Gunakan pencahayaan yang cukup'),
// //                     _buildInstruction('Lepas masker, kacamata, atau topi'),
// //                     _buildInstruction('Jarak wajah tidak terlalu jauh dari kamera'),
// //                     _buildInstruction('Hindari backlight (cahaya dari belakang)'),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildInstruction(String text) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4.0),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
// //           const SizedBox(width: 8),
// //           Expanded(child: Text(text)),
// //         ],
// //       ),
// //     );
// //   }
// // }


// // lib/pages/enroll_page.dart
// import 'dart:convert'; // Add this import for base64 encoding
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../services/face_service.dart';
// import '../services/api_service.dart';

// class EnrollPage extends StatefulWidget {
//   final ApiService api;
//   const EnrollPage({Key? key, required this.api}) : super(key: key);
  
//   @override
//   _EnrollPageState createState() => _EnrollPageState();
// }

// class _EnrollPageState extends State<EnrollPage> {
//   final FaceService _faceService = FaceService();
//   bool loading = false;
//   bool modelLoaded = false;
//   String? capturedImagePath;
//   String statusMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     _initializeModel();
//   }

//   Future<void> _initializeModel() async {
//     setState(() {
//       loading = true;
//       statusMessage = 'Loading face recognition model...';
//     });

//     try {
//       await _faceService.loadModel();
//       setState(() {
//         modelLoaded = true;
//         statusMessage = 'Model loaded successfully';
//         loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         modelLoaded = false;
//         statusMessage = 'Failed to load model: $e';
//         loading = false;
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to load face recognition model'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> pickAndEnroll() async {
//     if (!modelLoaded) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Model belum siap, harap tunggu')),
//       );
//       return;
//     }

//     final picker = ImagePicker();
    
//     try {
//       // Show dialog to choose camera or gallery
//       final source = await showDialog<ImageSource>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Pilih Sumber Gambar'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Kamera'),
//                 onTap: () => Navigator.pop(context, ImageSource.camera),
//               ),
//               // Uncomment if you want to enable gallery
//               // ListTile(
//               //   leading: const Icon(Icons.photo_library),
//               //   title: const Text('Galeri'),
//               //   onTap: () => Navigator.pop(context, ImageSource.gallery),
//               // ),
//             ],
//           ),
//         ),
//       );

//       if (source == null) return;
//       final picker = ImagePicker();
//       final XFile? file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
//       // final XFile? file = await picker.pickImage(
//       //   source: source,
//       //   imageQuality: 90, // Higher quality for better detection
//       //   preferredCameraDevice: CameraDevice.front,
//       //   maxWidth: 1920,
//       //   maxHeight: 1920,
//       // );
      
//       if (file == null) {
//         setState(() => statusMessage = 'Photo capture cancelled');
//         return;
//       }

//       setState(() {
//         loading = true;
//         capturedImagePath = file.path;
//         statusMessage = 'Detecting face in image...';
//       });

//       print('📷 Image captured: ${file.path}');

//       // Read image bytes and encode to base64 for sending to server
//       final bytes = await File(file.path).readAsBytes();
//       final base64Img = 'data:image/jpeg;base64,' + base64Encode(bytes);

//       // Extract face embedding
//       final embedding = await _faceService.getEmbeddingFromImageFile(file.path);
      
//       if (embedding == null) {
//         setState(() {
//           statusMessage = 'Face not detected - Please try again';
//           loading = false;
//         });
//         if (mounted) {
//           showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Text('Wajah Tidak Terdeteksi'),
//               content: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Pastikan:'),
//                   SizedBox(height: 8),
//                   Text('• Wajah terlihat jelas dan menghadap kamera'),
//                   Text('• Pencahayaan cukup baik'),
//                   Text('• Tidak ada yang menutupi wajah (masker/tangan)'),
//                   Text('• Wajah tidak terlalu kecil dalam foto'),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('OK'),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     pickAndEnroll(); // Retry
//                   },
//                   child: const Text('Coba Lagi'),
//                 ),
//               ],
//             ),
//           );
//         }
//         return;
//       }

//       setState(() => statusMessage = 'Face detected! Registering...');
//       print('✅ Face detected, embedding size: ${embedding.length}');

//       // Register to server with embedding and photo
//       final resp = await widget.api.registerFace(embedding,base64Img);
      
//       setState(() {
//         statusMessage = 'Face registered successfully';
//         loading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(resp['message'] ?? 'Wajah berhasil didaftarkan'),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 2),
//           ),
//         );
        
//         // Navigate back after success
//         Future.delayed(const Duration(seconds: 2), () {
//           if (mounted) Navigator.pop(context, true);
//         });
//       }
      
//     } catch (e) {
//       setState(() {
//         statusMessage = 'Error: ${e.toString()}';
//         loading = false;
//       });
      
//       print('❌ Error in pickAndEnroll: $e');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Gagal mendaftarkan wajah: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _faceService.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Daftar Wajah'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Preview image if captured
//             if (capturedImagePath != null)
//               Container(
//                 height: 300,
//                 margin: const EdgeInsets.only(bottom: 20),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.file(
//                     File(capturedImagePath!),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),

//             // Status message
//             if (statusMessage.isNotEmpty)
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 margin: const EdgeInsets.only(bottom: 20),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue.shade200),
//                 ),
//                 child: Text(
//                   statusMessage,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.blue.shade900,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),

//             // Loading indicator or button
//             if (loading)
//               const Center(
//                 child: Column(
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text('Memproses...'),
//                   ],
//                 ),
//               )
//             else
//               ElevatedButton.icon(
//                 onPressed: modelLoaded ? pickAndEnroll : null,
//                 icon: const Icon(Icons.camera_alt),
//                 label: const Text('Ambil Foto & Daftar'),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   textStyle: const TextStyle(fontSize: 16),
//                 ),
//               ),

//             const SizedBox(height: 12),

//             // Instructions
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Petunjuk Pengambilan Foto:',
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                     ),
//                     const SizedBox(height: 8),
//                     _buildInstruction('Pastikan wajah terlihat jelas dan menghadap kamera'),
//                     _buildInstruction('Gunakan pencahayaan yang cukup'),
//                     _buildInstruction('Lepas masker, kacamata, atau topi'),
//                     _buildInstruction('Jarak wajah tidak terlalu jauh dari kamera'),
//                     _buildInstruction('Hindari backlight (cahaya dari belakang)'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInstruction(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
//           const SizedBox(width: 8),
//           Expanded(child: Text(text)),
//         ],
//       ),
//     );
//   }
// }


// lib/pages/enroll_page.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_service.dart';
import '../services/api_service.dart';

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

  // LOGIKA TIDAK BERUBAH
  Future<void> _initializeModel() async {
    setState(() {
      loading = true;
      statusMessage = 'Loading face recognition model...';
    });

    try {
      await _faceService.loadModel();
      setState(() {
        modelLoaded = true;
        statusMessage = 'Model loaded successfully';
        loading = false;
      });
    } catch (e) {
      setState(() {
        modelLoaded = false;
        statusMessage = 'Failed to load model: $e';
        loading = false;
      });
      _showModernSnackBar('Gagal memuat model pengenalan wajah', color: Colors.red.shade600);
    }
  }

  // LOGIKA TIDAK BERUBAH
  Future<void> pickAndEnroll() async {
    if (!modelLoaded) {
      _showModernSnackBar('Model belum siap, harap tunggu', color: Colors.orange.shade600);
      return;
    }

    final picker = ImagePicker();
    
    try {
      // Show dialog to choose camera or gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              // ListTile(
              //   leading: const Icon(Icons.photo_library),
              //   title: const Text('Galeri'),
              //   onTap: () => Navigator.pop(context, ImageSource.gallery),
              // ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 90, 
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (file == null) {
        setState(() => statusMessage = 'Photo capture cancelled');
        return;
      }

      setState(() {
        loading = true;
        capturedImagePath = file.path;
        statusMessage = 'Detecting face in image...';
      });

      print('📷 Image captured: ${file.path}');
      
      // Read image bytes and encode to base64 for sending to server
      final bytes = await File(file.path).readAsBytes();
      final base64Img = 'data:image/jpeg;base64,' + base64Encode(bytes);


      // Extract face embedding
      final embedding = await _faceService.getEmbeddingFromImageFile(file.path);
      
      if (embedding == null) {
        setState(() {
          statusMessage = 'Face not detected - Please try again';
          loading = false;
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Wajah Tidak Terdeteksi'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pastikan:'),
                  SizedBox(height: 8),
                  Text('• Wajah terlihat jelas dan menghadap kamera'),
                  Text('• Pencahayaan cukup baik'),
                  Text('• Tidak ada yang menutupi wajah (masker/tangan)'),
                  Text('• Wajah tidak terlalu kecil dalam foto'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    pickAndEnroll(); // Retry
                  },
                  child: Text('Coba Lagi', style: TextStyle(color: _primaryColor)),
                ),
              ],
            ),
          );
        }
        return;
      }

      setState(() => statusMessage = 'Face detected! Registering...');
      print('✅ Face detected, embedding size: ${embedding.length}');

      // Register to server
      final resp = await widget.api.registerFace(embedding, base64Img);
      
      setState(() {
        statusMessage = 'Face registered successfully';
        loading = false;
      });

      // Notifikasi Sukses
      _showModernSnackBar(resp['message'] ?? 'Wajah berhasil didaftarkan', color: Colors.green.shade600);
        
      // Navigate back after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
      
    } catch (e) {
      setState(() {
        statusMessage = 'Error: ${e.toString()}';
        loading = false;
      });
      
      print('❌ Error in pickAndEnroll: $e');
      
      // Notifikasi Gagal
      _showModernSnackBar('Gagal mendaftarkan wajah: ${e.toString()}', color: Colors.red.shade600);
    }
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  // Widget untuk tampilan petunjuk yang modern
  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: Colors.grey.shade700))),
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
        title: Text('Pendaftaran Wajah', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Header Ikon
            Icon(
              Icons.face_retouching_natural_rounded,
              size: 80,
              color: _primaryColor.withOpacity(0.8),
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
                  color: _primaryColor.withOpacity(0.1), // Latar belakang ringan
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      loading ? Icons.sync : (modelLoaded ? Icons.check_circle_outline : Icons.warning_amber_rounded),
                      color: loading ? _primaryColor : (modelLoaded ? Colors.green : Colors.red),
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

            // Main Button
            if (loading && capturedImagePath == null) 
              // Loading indicator for initial model load
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                    const SizedBox(height: 16),
                    Text('Memproses...', style: TextStyle(color: _primaryColor)),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: modelLoaded && !loading ? pickAndEnroll : null,
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(capturedImagePath == null ? 'Ambil Foto & Daftar' : 'Ambil Foto Ulang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  elevation: 5,
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                    Text(
                      'Petunjuk Pengambilan Foto:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                    ),
                    const Divider(height: 24, thickness: 1),
                    _buildInstruction('Pastikan wajah **terlihat jelas** dan menghadap kamera (pandangan mata lurus)'),
                    _buildInstruction('Gunakan **pencahayaan yang cukup** dan merata, hindari bayangan pada wajah.'),
                    _buildInstruction('Lepas **masker, kacamata hitam, atau topi** yang menutupi bagian wajah.'),
                    _buildInstruction('Posisikan wajah **proporsional**, tidak terlalu dekat atau terlalu jauh.'),
                    _buildInstruction('Hindari **backlight** (cahaya dari belakang) yang membuat wajah gelap.'),
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