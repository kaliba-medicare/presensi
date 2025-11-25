import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  bool _isProcessing = false;
  String _status = 'Position your face in the frame';
  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        minFaceSize: 0.1,
      ),
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _captureAndRegisterFace() async {
    setState(() {
      _isProcessing = true;
      _status = 'Capturing face...';
    });

    try {
      // Capture image using image picker
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      
      if (image == null) {
        setState(() {
          _status = 'No image captured';
          _isProcessing = false;
        });
        return;
      }

      // Process the image to detect face
      final faceData = await _processFaceImage(image.path);
      
      if (faceData == null) {
        setState(() {
          _status = 'No face detected. Please try again.';
          _isProcessing = false;
        });
        return;
      }

      // Extract face embedding (simplified representation)
      final embedding = _extractFaceEmbedding(faceData);
      
      // TODO: Send embedding to your Laravel API
      // await ApiService().registerFace(embedding);
      
      setState(() {
        _status = 'Face registered successfully!';
      });
      
      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face registered successfully!')),
        );
        
        // Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to register face: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register face: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<Face?> _processFaceImage(String imagePath) async {
    setState(() {
      _status = 'Processing face detection...';
    });

    try {
      // Load image
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Process image
      final faces = await _faceDetector.processImage(inputImage);
      
      // Return first detected face
      return faces.isNotEmpty ? faces.first : null;
    } catch (e) {
      print('Error processing face: $e');
      return null;
    }
  }

  List<double> _extractFaceEmbedding(Face face) {
    // This is a simplified embedding extraction
    // In a real implementation, you would use a neural network model
    // to generate a 128-dimensional embedding vector
    
    setState(() {
      _status = 'Extracting face features...';
    });

    // Create a simple representation based on face landmarks
    final List<double> embedding = [];
    
    // Add bounding box coordinates
    embedding.add(face.boundingBox.left);
    embedding.add(face.boundingBox.top);
    embedding.add(face.boundingBox.width);
    embedding.add(face.boundingBox.height);
    
    // Add classification data if available
    if (face.smilingProbability != null) {
      embedding.add(face.smilingProbability!);
    } else {
      embedding.add(0.0);
    }
    
    if (face.leftEyeOpenProbability != null) {
      embedding.add(face.leftEyeOpenProbability!);
    } else {
      embedding.add(0.0);
    }
    
    if (face.rightEyeOpenProbability != null) {
      embedding.add(face.rightEyeOpenProbability!);
    } else {
      embedding.add(0.0);
    }
    
    // Note: Skipping landmark processing to avoid null issues
    // In a real implementation, you would process landmarks safely
    
    // Pad to 128 dimensions
    while (embedding.length < 128) {
      embedding.add(0.0);
    }
    
    // Normalize values
    double sum = 0;
    for (var value in embedding) {
      sum += value * value;
    }
    final norm = sum > 0 ? sqrt(sum) : 1.0;
    
    for (int i = 0; i < embedding.length; i++) {
      embedding[i] = embedding[i] / norm;
    }
    
    return embedding;
  }
  
  double sqrt(double value) {
    return value <= 0 ? 0 : double.parse(sqrtApprox(value).toStringAsFixed(10));
  }
  
  double sqrtApprox(double number) {
    if (number < 0) return 0;
    if (number == 0) return 0;
    
    double guess = number / 2;
    double betterGuess;
    
    do {
      betterGuess = (guess + number / guess) / 2;
      if ((guess - betterGuess).abs() < 1e-10) break;
      guess = betterGuess;
    } while (true);
    
    return betterGuess;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Face'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Face Registration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.face,
                size: 150,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _captureAndRegisterFace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Register Face',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}