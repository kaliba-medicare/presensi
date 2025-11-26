// // lib/widgets/blink_detection_camera.dart
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class BlinkDetectionCamera extends StatefulWidget {
//   final Function(String imagePath) onImageCaptured;
//   final VoidCallback onCancel;

//   const BlinkDetectionCamera({
//     Key? key,
//     required this.onImageCaptured,
//     required this.onCancel,
//   }) : super(key: key);

//   @override
//   _BlinkDetectionCameraState createState() => _BlinkDetectionCameraState();
// }

// class _BlinkDetectionCameraState extends State<BlinkDetectionCamera> with SingleTickerProviderStateMixin {
//   CameraController? _cameraController;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;

//   final FaceDetector _faceDetector = FaceDetector(
//     options: FaceDetectorOptions(
//       enableClassification: true,
//       enableLandmarks: true,
//       performanceMode: FaceDetectorMode.fast,
//       minFaceSize: 0.15,
//     ),
//   );

//   bool _isProcessing = false;
//   bool _isCameraInitialized = false;
//   bool _isCapturing = false;

//   String _instructionText = "Posisikan wajah Anda di dalam frame";
//   Color _instructionColor = Colors.white;

//   // BLINK DETECTION STATES
//   bool? _leftOpenPrev;
//   bool? _rightOpenPrev;

//   bool _leftBlinkDetected = false;
//   bool _rightBlinkDetected = false;

//   int _leftBlinkCount = 0;
//   int _rightBlinkCount = 0;

//   DateTime? _lastProcess;
//   DateTime? _faceDetectedTime;

//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
    
//     _initCamera();
//   }

//   Future<void> _initCamera() async {
//     try {
//       final status = await Permission.camera.request();
//       if (!status.isGranted) {
//         if (mounted) {
//           setState(() {
//             _instructionText = "❌ Izin kamera ditolak!";
//             _instructionColor = Colors.red;
//           });
//         }
//         return;
//       }

//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         if (mounted) {
//           setState(() {
//             _instructionText = "❌ Tidak ada kamera tersedia";
//             _instructionColor = Colors.red;
//           });
//         }
//         return;
//       }

//       CameraDescription? frontCamera;
//       try {
//         frontCamera = cameras.firstWhere(
//           (c) => c.lensDirection == CameraLensDirection.front,
//         );
//       } catch (e) {
//         frontCamera = cameras.first;
//       }

//       debugPrint('📷 Using camera: ${frontCamera.name}');

//       if (_cameraController != null) {
//         await _cameraController!.dispose();
//       }

//       _cameraController = CameraController(
//         frontCamera,
//         ResolutionPreset.medium,
//         enableAudio: false,
//         imageFormatGroup: Platform.isAndroid 
//             ? ImageFormatGroup.nv21 
//             : ImageFormatGroup.bgra8888,
//       );

//       await _cameraController!.initialize().timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           throw Exception('Camera initialization timeout');
//         },
//       );

//       if (!mounted) {
//         await _cameraController?.dispose();
//         return;
//       }

//       setState(() => _isCameraInitialized = true);

//       await Future.delayed(const Duration(milliseconds: 500));

//       if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) {
//         return;
//       }

//       await _cameraController!.startImageStream(_onImage);
      
//       debugPrint('✅ Camera initialized successfully');

//     } catch (e) {
//       debugPrint('❌ Camera initialization error: $e');
//       if (mounted) {
//         setState(() {
//           _instructionText = "❌ Gagal membuka kamera: ${e.toString()}";
//           _instructionColor = Colors.red;
//         });
//       }
//     }
//   }

//   void _onImage(CameraImage image) {
//     if (_isCapturing) return;

//     final now = DateTime.now();
//     if (_lastProcess != null &&
//         now.difference(_lastProcess!).inMilliseconds < 150) {
//       return;
//     }
//     _lastProcess = now;

//     if (_isProcessing) return;
//     _isProcessing = true;

//     _detectFace(image);
//   }

//   Future<void> _detectFace(CameraImage image) async {
//     try {
//       final InputImage inputImage = _buildInputImage(image);
//       final faces = await _faceDetector.processImage(inputImage);

//       if (!mounted) return;

//       if (faces.isEmpty) {
//         _resetFaceState();
//         return;
//       }

//       final face = faces.first;
//       _faceDetectedTime ??= DateTime.now();

//       final left = face.leftEyeOpenProbability ?? 0.5;
//       final right = face.rightEyeOpenProbability ?? 0.5;

//       _handleBlink(left, right);
//     } catch (e) {
//       debugPrint('Face detection error: $e');
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   InputImage _buildInputImage(CameraImage image) {
//     final format = Platform.isAndroid 
//         ? InputImageFormat.nv21 
//         : InputImageFormat.bgra8888;

//     final camera = _cameraController!.description;
//     final sensorOrientation = camera.sensorOrientation;
//     InputImageRotation? rotation;

//     if (Platform.isAndroid) {
//       rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
//       if (rotation == null) {
//         rotation = InputImageRotation.rotation0deg;
//       }
//     } else if (Platform.isIOS) {
//       rotation = InputImageRotation.rotation270deg;
//     }

//     final metadata = InputImageMetadata(
//       size: Size(image.width.toDouble(), image.height.toDouble()),
//       rotation: rotation ?? InputImageRotation.rotation0deg,
//       format: format,
//       bytesPerRow: image.planes[0].bytesPerRow,
//     );

//     final WriteBuffer buffer = WriteBuffer();
//     for (final Plane plane in image.planes) {
//       buffer.putUint8List(plane.bytes);
//     }
//     final bytes = buffer.done().buffer.asUint8List();

//     return InputImage.fromBytes(
//       bytes: bytes,
//       metadata: metadata,
//     );
//   }

//   void _resetFaceState() {
//     if (!mounted) return;
    
//     setState(() {
//       _leftOpenPrev = null;
//       _rightOpenPrev = null;
//       _leftBlinkDetected = false;
//       _rightBlinkDetected = false;
//       _leftBlinkCount = 0;
//       _rightBlinkCount = 0;
//       _faceDetectedTime = null;
//       _instructionText = "👤 Wajah tidak terdeteksi";
//       _instructionColor = Colors.orange;
//     });
//   }

//   void _handleBlink(double leftProb, double rightProb) {
//     const double openThreshold = 0.5;
//     const double closedThreshold = 0.4;

//     bool leftOpen = leftProb > openThreshold;
//     bool leftClosed = leftProb < closedThreshold;

//     bool rightOpen = rightProb > openThreshold;
//     bool rightClosed = rightProb < closedThreshold;

//     if (_leftOpenPrev == null) {
//       _leftOpenPrev = leftOpen;
//       _rightOpenPrev = rightOpen;
      
//       setState(() {
//         _instructionText = "👀 Wajah terdeteksi! Kedipkan mata Anda";
//         _instructionColor = Colors.lightGreen;
//       });
//       return;
//     }

//     if (!_leftBlinkDetected) {
//       if (_leftOpenPrev! && leftClosed) {
//         _leftOpenPrev = false;
//       } else if (!_leftOpenPrev! && leftOpen) {
//         _leftBlinkDetected = true;
//         _leftBlinkCount++;
//         debugPrint('✅ LEFT eye blink detected! Count: $_leftBlinkCount');
//       }
//     }

//     if (!_rightBlinkDetected) {
//       if (_rightOpenPrev! && rightClosed) {
//         _rightOpenPrev = false;
//       } else if (!_rightOpenPrev! && rightOpen) {
//         _rightBlinkDetected = true;
//         _rightBlinkCount++;
//         debugPrint('✅ RIGHT eye blink detected! Count: $_rightBlinkCount');
//       }
//     }

//     if (leftOpen) _leftOpenPrev = true;
//     if (rightOpen) _rightOpenPrev = true;

//     if (!mounted) return;

//     if (_leftBlinkDetected && _rightBlinkDetected) {
//       setState(() {
//         _instructionText = "✅ Kedipan terdeteksi! Mengambil foto...";
//         _instructionColor = Colors.green;
//       });

//       _capturePhoto();
//       return;
//     }

//     if (_leftBlinkDetected && !_rightBlinkDetected) {
//       setState(() {
//         _instructionText = "👁️ Mata kiri OK! Kedipkan mata kanan";
//         _instructionColor = Colors.amber;
//       });
//     } else if (!_leftBlinkDetected && _rightBlinkDetected) {
//       setState(() {
//         _instructionText = "👁️ Mata kanan OK! Kedipkan mata kiri";
//         _instructionColor = Colors.amber;
//       });
//     } else {
//       setState(() {
//         _instructionText = "👀 Kedipkan kedua mata Anda";
//         _instructionColor = Colors.white;
//       });
//     }
//   }

//   Future<void> _capturePhoto() async {
//     if (_cameraController == null || _isCapturing || !_cameraController!.value.isInitialized) {
//       return;
//     }

//     _isCapturing = true;

//     try {
//       if (_cameraController!.value.isStreamingImages) {
//         await _cameraController!.stopImageStream();
//       }

//       await Future.delayed(const Duration(milliseconds: 300));

//       if (!mounted || _cameraController == null) return;

//       final XFile file = await _cameraController!.takePicture();

//       debugPrint('📸 Picture taken: ${file.path}');

//       final dir = await getTemporaryDirectory();
//       final newPath = "${dir.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg";

//       final File sourceFile = File(file.path);
//       if (await sourceFile.exists()) {
//         await sourceFile.copy(newPath);
//         debugPrint('✅ Photo saved: $newPath');

//         if (mounted) {
//           widget.onImageCaptured(newPath);
//         }
//       } else {
//         throw Exception('Source file does not exist');
//       }

//     } catch (e) {
//       debugPrint('❌ Capture error: $e');
      
//       if (mounted) {
//         setState(() {
//           _instructionText = "❌ Gagal mengambil foto. Coba lagi.";
//           _instructionColor = Colors.red;
//           _isCapturing = false;
//         });

//         await Future.delayed(const Duration(seconds: 2));

//         if (mounted && _cameraController != null) {
//           _resetFaceState();
          
//           try {
//             if (!_cameraController!.value.isStreamingImages) {
//               await _cameraController!.startImageStream(_onImage);
//             }
//           } catch (restartError) {
//             debugPrint('Failed to restart stream: $restartError');
//           }
//         }
//       }
//     }
//   }

//   @override
//   void dispose() {
//     debugPrint('🔚 Disposing camera resources');
//     _pulseController.dispose();
//     _cameraController?.dispose();
//     _faceDetector.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isCameraInitialized) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Modern loading spinner
//               Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   SizedBox(
//                     width: 80,
//                     height: 80,
//                     child: CircularProgressIndicator(
//                       color: Colors.blue.shade400,
//                       strokeWidth: 3,
//                     ),
//                   ),
//                   Icon(
//                     Icons.camera_alt_rounded,
//                     color: Colors.blue.shade400,
//                     size: 40,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Memuat Kamera',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Mohon tunggu sebentar...',
//                 style: TextStyle(
//                   color: Colors.grey.shade400,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Camera Preview with gradient overlay
//           Positioned.fill(
//             child: Stack(
//               children: [
//                 CameraPreview(_cameraController!),
//                 // Top gradient
//                 Positioned(
//                   top: 0,
//                   left: 0,
//                   right: 0,
//                   child: Container(
//                     height: 200,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.black.withOpacity(0.7),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Bottom gradient
//                 Positioned(
//                   bottom: 0,
//                   left: 0,
//                   right: 0,
//                   child: Container(
//                     height: 200,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.bottomCenter,
//                         end: Alignment.topCenter,
//                         colors: [
//                           Colors.black.withOpacity(0.7),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Animated Face Oval Guide
//           Positioned.fill(
//             child: AnimatedBuilder(
//               animation: _pulseAnimation,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _ModernFaceOvalPainter(
//                     color: _instructionColor,
//                     isCapturing: _isCapturing,
//                     faceDetected: _faceDetectedTime != null,
//                     pulseScale: _pulseAnimation.value,
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Modern Header with Instruction
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   children: [
//                     // Title
//                     Text(
//                       'Verifikasi Wajah',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 0.5,
//                         shadows: [
//                           Shadow(
//                             color: Colors.black.withOpacity(0.5),
//                             blurRadius: 10,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Instruction Card
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 16,
//                         horizontal: 24,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.6),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: _instructionColor.withOpacity(0.5),
//                           width: 2,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: _instructionColor.withOpacity(0.2),
//                             blurRadius: 20,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: _instructionColor.withOpacity(0.2),
//                               shape: BoxShape.circle,
//                             ),
//                             child: Icon(
//                               _getInstructionIcon(),
//                               color: _instructionColor,
//                               size: 24,
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Flexible(
//                             child: Text(
//                               _instructionText,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 letterSpacing: 0.3,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Modern Blink Status Indicators
//           if (_faceDetectedTime != null)
//             Positioned(
//               top: MediaQuery.of(context).size.height * 0.35,
//               left: 0,
//               right: 0,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _buildModernBlinkIndicator(
//                     'Kiri',
//                     _leftBlinkDetected,
//                     Icons.visibility,
//                   ),
//                   const SizedBox(width: 24),
//                   _buildModernBlinkIndicator(
//                     'Kanan',
//                     _rightBlinkDetected,
//                     Icons.visibility,
//                   ),
//                 ],
//               ),
//             ),

//           // Modern Cancel Button
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(30),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.3),
//                         blurRadius: 20,
//                         spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: ElevatedButton.icon(
//                     onPressed: _isCapturing ? null : widget.onCancel,
//                     icon: const Icon(Icons.close_rounded, size: 24),
//                     label: const Text(
//                       "Batalkan",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red.shade600,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey.shade700,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 32,
//                         vertical: 16,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       elevation: 0,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // Modern Capturing Overlay
//           if (_isCapturing)
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withOpacity(0.8),
//                       Colors.black.withOpacity(0.9),
//                     ],
//                   ),
//                 ),
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Success icon animation
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.green.withOpacity(0.2),
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                             color: Colors.green,
//                             width: 3,
//                           ),
//                         ),
//                         child: const Icon(
//                           Icons.check_circle_rounded,
//                           color: Colors.green,
//                           size: 60,
//                         ),
//                       ),
//                       const SizedBox(height: 32),
                      
//                       // Loading spinner
//                       SizedBox(
//                         width: 60,
//                         height: 60,
//                         child: CircularProgressIndicator(
//                           color: Colors.green,
//                           strokeWidth: 4,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
                      
//                       Text(
//                         'Memproses Foto',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Mohon tunggu sebentar...',
//                         style: TextStyle(
//                           color: Colors.grey.shade400,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   IconData _getInstructionIcon() {
//     if (_isCapturing) return Icons.check_circle_rounded;
//     if (_faceDetectedTime != null) {
//       if (_leftBlinkDetected && _rightBlinkDetected) {
//         return Icons.check_circle_rounded;
//       }
//       return Icons.visibility_rounded;
//     }
//     return Icons.face_rounded;
//   }

//   Widget _buildModernBlinkIndicator(String label, bool detected, IconData icon) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       decoration: BoxDecoration(
//         color: detected
//             ? Colors.green.withOpacity(0.9)
//             : Colors.black.withOpacity(0.6),
//         borderRadius: BorderRadius.circular(25),
//         border: Border.all(
//           color: detected ? Colors.green : Colors.white.withOpacity(0.3),
//           width: 2,
//         ),
//         boxShadow: detected ? [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.4),
//             blurRadius: 15,
//             spreadRadius: 2,
//           ),
//         ] : [],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             child: Icon(
//               detected ? Icons.check_circle_rounded : icon,
//               color: Colors.white,
//               size: 22,
//               key: ValueKey(detected),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//               letterSpacing: 0.3,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Modern Custom painter for face oval guide
// class _ModernFaceOvalPainter extends CustomPainter {
//   final Color color;
//   final bool isCapturing;
//   final bool faceDetected;
//   final double pulseScale;

//   _ModernFaceOvalPainter({
//     required this.color,
//     required this.isCapturing,
//     required this.faceDetected,
//     required this.pulseScale,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2.5);
//     final radiusX = size.width * 0.35 * (faceDetected ? pulseScale : 1.0);
//     final radiusY = size.height * 0.25 * (faceDetected ? pulseScale : 1.0);

//     // Draw outer glow
//     if (faceDetected) {
//       final glowPaint = Paint()
//         ..color = color.withOpacity(0.2)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 8.0
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

//       canvas.drawOval(
//         Rect.fromCenter(
//           center: center,
//           width: radiusX * 2,
//           height: radiusY * 2,
//         ),
//         glowPaint,
//       );
//     }

//     // Draw main oval with dashed effect
//     final paint = Paint()
//       ..color = isCapturing ? Colors.green : color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.0;

//     final rect = Rect.fromCenter(
//       center: center,
//       width: radiusX * 2,
//       height: radiusY * 2,
//     );

//     // Draw dashed oval
//     const dashWidth = 15.0;
//     const dashSpace = 8.0;
//     double distance = 0.0;

//     final path = Path()..addOval(rect);
//     final pathMetrics = path.computeMetrics();

//     for (final pathMetric in pathMetrics) {
//       while (distance < pathMetric.length) {
//         final extractPath = pathMetric.extractPath(
//           distance,
//           distance + dashWidth,
//         );
//         canvas.drawPath(extractPath, paint);
//         distance += dashWidth + dashSpace;
//       }
//     }

//     // Draw corner indicators
//     _drawCornerIndicators(canvas, rect, paint);
//   }

//   void _drawCornerIndicators(Canvas canvas, Rect rect, Paint paint) {
//     final cornerPaint = Paint()
//       ..color = paint.color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 5.0
//       ..strokeCap = StrokeCap.round;

//     const cornerSize = 25.0;

//     // Top left
//     canvas.drawLine(
//       Offset(rect.left - 10, rect.top),
//       Offset(rect.left - 10 + cornerSize, rect.top),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(rect.left - 10, rect.top),
//       Offset(rect.left - 10, rect.top + cornerSize),
//       cornerPaint,
//     );

//     // Top right
//     canvas.drawLine(
//       Offset(rect.right + 10, rect.top),
//       Offset(rect.right + 10 - cornerSize, rect.top),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(rect.right + 10, rect.top),
//       Offset(rect.right + 10, rect.top + cornerSize),
//       cornerPaint,
//     );

//     // Bottom left
//     canvas.drawLine(
//       Offset(rect.left - 10, rect.bottom),
//       Offset(rect.left - 10 + cornerSize, rect.bottom),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(rect.left - 10, rect.bottom),
//       Offset(rect.left - 10, rect.bottom - cornerSize),
//       cornerPaint,
//     );

//     // Bottom right
//     canvas.drawLine(
//       Offset(rect.right + 10, rect.bottom),
//       Offset(rect.right + 10 - cornerSize, rect.bottom),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(rect.right + 10, rect.bottom),
//       Offset(rect.right + 10, rect.bottom - cornerSize),
//       cornerPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(_ModernFaceOvalPainter oldDelegate) {
//     return oldDelegate.color != color || 
//            oldDelegate.isCapturing != isCapturing ||
//            oldDelegate.faceDetected != faceDetected ||
//            oldDelegate.pulseScale != pulseScale;
//   }
// }

// lib/widgets/blink_detection_camera.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BlinkDetectionCamera extends StatefulWidget {
  final Function(String imagePath) onImageCaptured;
  final VoidCallback onCancel;

  const BlinkDetectionCamera({
    Key? key,
    required this.onImageCaptured,
    required this.onCancel,
  }) : super(key: key);

  @override
  _BlinkDetectionCameraState createState() => _BlinkDetectionCameraState();
}

class _BlinkDetectionCameraState extends State<BlinkDetectionCamera> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  String _instructionText = "Posisikan wajah Anda di dalam lingkaran"; // Diubah instruksinya
  Color _instructionColor = Colors.blueAccent; // Warna default yang lebih modern

  // BLINK DETECTION STATES
  bool? _leftOpenPrev;
  bool? _rightOpenPrev;

  bool _leftBlinkDetected = false;
  bool _rightBlinkDetected = false;

  int _leftBlinkCount = 0;
  int _rightBlinkCount = 0;

  DateTime? _lastProcess;
  DateTime? _faceDetectedTime;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Durasi pulse sedikit lebih cepat
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate( // Pulse lebih halus
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _instructionText = "❌ Izin kamera ditolak!";
            _instructionColor = Colors.redAccent;
          });
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _instructionText = "❌ Tidak ada kamera tersedia";
            _instructionColor = Colors.redAccent;
          });
        }
        return;
      }

      CameraDescription? frontCamera;
      try {
        frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        frontCamera = cameras.first;
      }

      debugPrint('📷 Using camera: ${frontCamera.name}');

      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Camera initialization timeout');
        },
      );

      if (!mounted) {
        await _cameraController?.dispose();
        return;
      }

      setState(() => _isCameraInitialized = true);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      await _cameraController!.startImageStream(_onImage);
      
      debugPrint('✅ Camera initialized successfully');

    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _instructionText = "❌ Gagal membuka kamera: ${e.toString()}";
          _instructionColor = Colors.redAccent;
        });
      }
    }
  }

  void _onImage(CameraImage image) {
    if (_isCapturing) return;

    final now = DateTime.now();
    if (_lastProcess != null &&
        now.difference(_lastProcess!).inMilliseconds < 150) {
      return;
    }
    _lastProcess = now;

    if (_isProcessing) return;
    _isProcessing = true;

    _detectFace(image);
  }

  Future<void> _detectFace(CameraImage image) async {
    try {
      final InputImage inputImage = _buildInputImage(image);
      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isEmpty) {
        _resetFaceState();
        return;
      }

      final face = faces.first;
      _faceDetectedTime ??= DateTime.now();

      final left = face.leftEyeOpenProbability ?? 0.5;
      final right = face.rightEyeOpenProbability ?? 0.5;

      _handleBlink(left, right);
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _buildInputImage(CameraImage image) {
    final format = Platform.isAndroid 
        ? InputImageFormat.nv21 
        : InputImageFormat.bgra8888;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      if (rotation == null) {
        rotation = InputImageRotation.rotation0deg;
      }
    } else if (Platform.isIOS) {
      rotation = InputImageRotation.rotation270deg;
    }

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation ?? InputImageRotation.rotation0deg,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final WriteBuffer buffer = WriteBuffer();
    for (final Plane plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  void _resetFaceState() {
    if (!mounted) return;
    
    setState(() {
      _leftOpenPrev = null;
      _rightOpenPrev = null;
      _leftBlinkDetected = false;
      _rightBlinkDetected = false;
      _leftBlinkCount = 0;
      _rightBlinkCount = 0;
      _faceDetectedTime = null;
      _instructionText = "👤 Wajah tidak terdeteksi";
      _instructionColor = Colors.deepOrangeAccent; // Warna orange yang lebih gelap
    });
  }

  void _handleBlink(double leftProb, double rightProb) {
    const double openThreshold = 0.5;
    const double closedThreshold = 0.4;

    bool leftOpen = leftProb > openThreshold;
    bool leftClosed = leftProb < closedThreshold;

    bool rightOpen = rightProb > openThreshold;
    bool rightClosed = rightProb < closedThreshold;

    if (_leftOpenPrev == null) {
      _leftOpenPrev = leftOpen;
      _rightOpenPrev = rightOpen;
      
      setState(() {
        _instructionText = "👀 Wajah terdeteksi! Kedipkan mata Anda";
        _instructionColor = Colors.lightGreenAccent; // Warna hijau yang lebih terang
      });
      return;
    }

    if (!_leftBlinkDetected) {
      if (_leftOpenPrev! && leftClosed) {
        _leftOpenPrev = false;
      } else if (!_leftOpenPrev! && leftOpen) {
        _leftBlinkDetected = true;
        _leftBlinkCount++;
        debugPrint('✅ LEFT eye blink detected! Count: $_leftBlinkCount');
      }
    }

    if (!_rightBlinkDetected) {
      if (_rightOpenPrev! && rightClosed) {
        _rightOpenPrev = false;
      } else if (!_rightOpenPrev! && rightOpen) {
        _rightBlinkDetected = true;
        _rightBlinkCount++;
        debugPrint('✅ RIGHT eye blink detected! Count: $_rightBlinkCount');
      }
    }

    if (leftOpen) _leftOpenPrev = true;
    if (rightOpen) _rightOpenPrev = true;

    if (!mounted) return;

    if (_leftBlinkDetected && _rightBlinkDetected) {
      setState(() {
        _instructionText = "✅ Kedipan terdeteksi! Mengambil foto...";
        _instructionColor = Colors.greenAccent; // Warna hijau yang lebih cerah
      });

      _capturePhoto();
      return;
    }

    if (_leftBlinkDetected && !_rightBlinkDetected) {
      setState(() {
        _instructionText = "👁️ Mata kiri OK! Kedipkan mata kanan";
        _instructionColor = Colors.amberAccent; // Warna amber yang lebih cerah
      });
    } else if (!_leftBlinkDetected && _rightBlinkDetected) {
      setState(() {
        _instructionText = "👁️ Mata kanan OK! Kedipkan mata kiri";
        _instructionColor = Colors.amberAccent;
      });
    } else {
      setState(() {
        _instructionText = "👀 Kedipkan kedua mata Anda";
        _instructionColor = Colors.blueAccent; // Kembali ke warna default yang modern
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || _isCapturing || !_cameraController!.value.isInitialized) {
      return;
    }

    _isCapturing = true;

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || _cameraController == null) return;

      final XFile file = await _cameraController!.takePicture();

      debugPrint('📸 Picture taken: ${file.path}');

      final dir = await getTemporaryDirectory();
      final newPath = "${dir.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final File sourceFile = File(file.path);
      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        debugPrint('✅ Photo saved: $newPath');

        if (mounted) {
          widget.onImageCaptured(newPath);
        }
      } else {
        throw Exception('Source file does not exist');
      }

    } catch (e) {
      debugPrint('❌ Capture error: $e');
      
      if (mounted) {
        setState(() {
          _instructionText = "❌ Gagal mengambil foto. Coba lagi.";
          _instructionColor = Colors.redAccent;
          _isCapturing = false;
        });

        await Future.delayed(const Duration(seconds: 2));

        if (mounted && _cameraController != null) {
          _resetFaceState();
          
          try {
            if (!_cameraController!.value.isStreamingImages) {
              await _cameraController!.startImageStream(_onImage);
            }
          } catch (restartError) {
            debugPrint('Failed to restart stream: $restartError');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    debugPrint('🔚 Disposing camera resources');
    _pulseController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[900], // Background lebih gelap
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Modern loading spinner
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent, // Warna spinner lebih modern
                      strokeWidth: 3,
                    ),
                  ),
                  Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.blueAccent,
                    size: 40,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Memuat Kamera',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mohon tunggu sebentar...',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview with gradient overlay
          Positioned.fill(
            child: Stack(
              children: [
                _cameraController!.value.isInitialized 
                  ? CameraPreview(_cameraController!)
                  : Container(color: Colors.black), // Fallback jika kamera belum siap
                // Top gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.8), // Opacity lebih tinggi
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom gradient
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8), // Opacity lebih tinggi
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animated Face Circle Guide
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ModernFaceCirclePainter( // Diubah ke Circle Painter
                    color: _instructionColor,
                    isCapturing: _isCapturing,
                    faceDetected: _faceDetectedTime != null,
                    pulseScale: _pulseAnimation.value,
                  ),
                );
              },
            ),
          ),

          // Modern Header with Instruction
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Title
                    Text(
                      'Verifikasi Wajah',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Instruction Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(15), // Sudut sedikit membulat
                        border: Border.all(
                          color: _instructionColor.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _instructionColor.withOpacity(0.2),
                            blurRadius: 15, // Blur sedikit berkurang
                            spreadRadius: 1, // Spread berkurang
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _instructionColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getInstructionIcon(),
                              color: _instructionColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              _instructionText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Modern Blink Status Indicators (Gaya disederhanakan)
          if (_faceDetectedTime != null)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModernBlinkIndicator(
                    'Kiri',
                    _leftBlinkDetected,
                    Icons.remove_red_eye_rounded, // Ikon mata yang lebih modern
                  ),
                  const SizedBox(width: 24),
                  _buildModernBlinkIndicator(
                    'Kanan',
                    _rightBlinkDetected,
                    Icons.remove_red_eye_rounded,
                  ),
                ],
              ),
            ),

          // Modern Cancel Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isCapturing ? null : widget.onCancel,
                    icon: const Icon(Icons.close_rounded, size: 24),
                    label: const Text(
                      "Batalkan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700, // Warna merah yang lebih pekat
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Modern Capturing Overlay
          if (_isCapturing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.9), // Opacity lebih tinggi
                      Colors.black.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success icon animation
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.greenAccent, // Warna hijau yang lebih cerah
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.greenAccent,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Loading spinner
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'Memproses Foto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mohon tunggu sebentar...',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getInstructionIcon() {
    if (_isCapturing) return Icons.check_circle_rounded;
    if (_faceDetectedTime != null) {
      if (_leftBlinkDetected && _rightBlinkDetected) {
        return Icons.check_circle_rounded;
      }
      return Icons.visibility_rounded;
    }
    return Icons.face_rounded;
  }

  Widget _buildModernBlinkIndicator(String label, bool detected, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: detected
            ? Colors.greenAccent.withOpacity(0.2) // Latar belakang indikator transparan
            : Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: detected ? Colors.greenAccent : Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: detected ? [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              detected ? Icons.check_circle_rounded : icon,
              color: detected ? Colors.greenAccent : Colors.white, // Warna ikon berubah
              size: 22,
              key: ValueKey(detected),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Custom painter for face circle guide (Previously _ModernFaceOvalPainter)
class _ModernFaceCirclePainter extends CustomPainter {
  final Color color;
  final bool isCapturing;
  final bool faceDetected;
  final double pulseScale;

  _ModernFaceCirclePainter({
    required this.color,
    required this.isCapturing,
    required this.faceDetected,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2.5);
    final baseRadius = size.width * 0.35; // Radius untuk lingkaran sempurna
    final currentRadius = baseRadius * (faceDetected ? pulseScale : 1.0);

    // Draw outer glow (Menggunakan lingkaran sempurna)
    if (faceDetected) {
      final glowPaint = Paint()
        ..shader = LinearGradient( // Gradient untuk glow
          colors: [color.withOpacity(0.3), Colors.blue.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: currentRadius + 10))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0 // Ketebalan glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15); // Blur lebih kuat

      canvas.drawCircle(center, currentRadius + 5, glowPaint); // Lingkaran glow sedikit lebih besar
    }

    // Draw main circle with dashed effect
    final paint = Paint()
      ..shader = LinearGradient( // Gradient untuk garis lingkaran
        colors: isCapturing 
            ? [Colors.greenAccent, Colors.lightGreen]
            : [color, color.withOpacity(0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Ketebalan garis lingkaran

    final path = Path()..addOval(Rect.fromCircle(center: center, radius: currentRadius));
    
    // Draw dashed circle
    const dashWidth = 12.0; // Lebar dash sedikit lebih kecil
    const dashSpace = 8.0;
    double distance = 0.0;

    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_ModernFaceCirclePainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.isCapturing != isCapturing ||
           oldDelegate.faceDetected != faceDetected ||
           oldDelegate.pulseScale != pulseScale;
  }
}