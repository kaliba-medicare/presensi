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

class _BlinkDetectionCameraState extends State<BlinkDetectionCamera> {
  CameraController? _cameraController;

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
  bool _isCapturing = false; // Prevent multiple captures

  String _instructionText = "Posisikan wajah Anda di dalam frame";
  Color _instructionColor = Colors.white;

  // BLINK DETECTION STATES
  bool? _leftOpenPrev; // null = not initialized
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
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _instructionText = "❌ Izin kamera ditolak!";
            _instructionColor = Colors.red;
          });
        }
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _instructionText = "❌ Tidak ada kamera tersedia";
            _instructionColor = Colors.red;
          });
        }
        return;
      }

      // Find front camera
      CameraDescription? frontCamera;
      try {
        frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        frontCamera = cameras.first;
      }

      debugPrint('📷 Using camera: ${frontCamera.name}');

      // Dispose previous controller if exists
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      // Initialize camera controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      // Initialize with error handling
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

      // Small delay before starting image stream
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      // Start image stream
      await _cameraController!.startImageStream(_onImage);
      
      debugPrint('✅ Camera initialized successfully');

    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _instructionText = "❌ Gagal membuka kamera: ${e.toString()}";
          _instructionColor = Colors.red;
        });
      }
    }
  }

  void _onImage(CameraImage image) {
    if (_isCapturing) return; // Don't process if already capturing

    // Limit processing to every 150ms for performance
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
      final WriteBuffer buffer = WriteBuffer();
      for (final Plane p in image.planes) {
        buffer.putUint8List(p.bytes);
      }
      final bytes = buffer.done().buffer.asUint8List();

      final rotation = InputImageRotation.rotation270deg;

      final input = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(input);

      if (!mounted) return;

      if (faces.isEmpty) {
        _resetFaceState();
        return;
      }

      final face = faces.first;

      // Mark face detected
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
      _instructionColor = Colors.orange;
    });
  }

  void _handleBlink(double leftProb, double rightProb) {
    // Adjusted thresholds for better detection
    const double openThreshold = 0.5;   // Was 0.6
    const double closedThreshold = 0.4; // Was 0.3

    bool leftOpen = leftProb > openThreshold;
    bool leftClosed = leftProb < closedThreshold;

    bool rightOpen = rightProb > openThreshold;
    bool rightClosed = rightProb < closedThreshold;

    // Initialize on first detection
    if (_leftOpenPrev == null) {
      _leftOpenPrev = leftOpen;
      _rightOpenPrev = rightOpen;
      
      setState(() {
        _instructionText = "👀 Wajah terdeteksi! Kedipkan mata Anda";
        _instructionColor = Colors.lightGreen;
      });
      return;
    }

    // Detect LEFT eye blink (OPEN → CLOSED → OPEN)
    if (!_leftBlinkDetected) {
      if (_leftOpenPrev! && leftClosed) {
        // Eye closed
        _leftOpenPrev = false;
      } else if (!_leftOpenPrev! && leftOpen) {
        // Eye reopened = BLINK COMPLETE
        _leftBlinkDetected = true;
        _leftBlinkCount++;
        debugPrint('✅ LEFT eye blink detected! Count: $_leftBlinkCount');
      }
    }

    // Detect RIGHT eye blink (OPEN → CLOSED → OPEN)
    if (!_rightBlinkDetected) {
      if (_rightOpenPrev! && rightClosed) {
        // Eye closed
        _rightOpenPrev = false;
      } else if (!_rightOpenPrev! && rightOpen) {
        // Eye reopened = BLINK COMPLETE
        _rightBlinkDetected = true;
        _rightBlinkCount++;
        debugPrint('✅ RIGHT eye blink detected! Count: $_rightBlinkCount');
      }
    }

    // Update previous states
    if (leftOpen) _leftOpenPrev = true;
    if (rightOpen) _rightOpenPrev = true;

    // Update UI based on blink status
    if (!mounted) return;

    if (_leftBlinkDetected && _rightBlinkDetected) {
      setState(() {
        _instructionText = "✅ Kedipan terdeteksi! Mengambil foto...";
        _instructionColor = Colors.green;
      });

      // Trigger photo capture
      _capturePhoto();
      return;
    }

    // Show progress
    if (_leftBlinkDetected && !_rightBlinkDetected) {
      setState(() {
        _instructionText = "👁️ Mata kiri OK! Kedipkan mata kanan";
        _instructionColor = Colors.amber;
      });
    } else if (!_leftBlinkDetected && _rightBlinkDetected) {
      setState(() {
        _instructionText = "👁️ Mata kanan OK! Kedipkan mata kiri";
        _instructionColor = Colors.amber;
      });
    } else {
      setState(() {
        _instructionText = "👀 Kedipkan kedua mata Anda";
        _instructionColor = Colors.white;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || _isCapturing || !_cameraController!.value.isInitialized) {
      return;
    }

    _isCapturing = true; // Prevent multiple captures

    try {
      // Stop image stream before capture
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      // Wait for camera to stabilize
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || _cameraController == null) return;

      // Take picture
      final XFile file = await _cameraController!.takePicture();

      debugPrint('📸 Picture taken: ${file.path}');

      // Get temp directory and copy file
      final dir = await getTemporaryDirectory();
      final newPath = "${dir.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final File sourceFile = File(file.path);
      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        debugPrint('✅ Photo saved: $newPath');

        // Return the captured image path
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
          _instructionColor = Colors.red;
          _isCapturing = false;
        });

        // Wait a bit then reset and restart
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
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Memuat kamera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
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
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // Face Oval Guide
          Positioned.fill(
            child: CustomPaint(
              painter: _FaceOvalPainter(
                color: _instructionColor,
                isCapturing: _isCapturing,
              ),
            ),
          ),

          // Instruction Text
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _instructionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _instructionColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Blink Status Indicators
          if (_faceDetectedTime != null)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBlinkIndicator(
                    'Mata Kiri',
                    _leftBlinkDetected,
                    Icons.visibility,
                  ),
                  const SizedBox(width: 30),
                  _buildBlinkIndicator(
                    'Mata Kanan',
                    _rightBlinkDetected,
                    Icons.visibility,
                  ),
                ],
              ),
            ),

          // Cancel Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : widget.onCancel,
                icon: const Icon(Icons.close),
                label: const Text("Batal"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),

          // Capturing Overlay
          if (_isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Mengambil foto...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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

  Widget _buildBlinkIndicator(String label, bool detected, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: detected
            ? Colors.green.withOpacity(0.8)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            detected ? Icons.check_circle : icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for face oval guide
class _FaceOvalPainter extends CustomPainter {
  final Color color;
  final bool isCapturing;

  _FaceOvalPainter({required this.color, required this.isCapturing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCapturing ? Colors.green : color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2.5);
    final radiusX = size.width * 0.35;
    final radiusY = size.height * 0.25;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_FaceOvalPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isCapturing != isCapturing;
  }
}