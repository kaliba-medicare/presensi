import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FaceRecognitionExample {
  late FaceDetector _faceDetector;

  FaceRecognitionExample() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        minFaceSize: 0.1,
      ),
    );
  }

  // Register a face - capture image and extract embedding
  Future<List<double>?> registerFace() async {
    try {
      // 1. Capture image
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      
      if (image == null) return null;

      // 2. Process image to detect face
      final faceData = await _processFaceImage(image.path);
      
      if (faceData == null) return null;

      // 3. Extract face embedding
      final embedding = _extractFaceEmbedding(faceData);
      
      // 4. Send to backend API (not implemented here)
      // await _sendToBackend(embedding, 'register');
      
      return embedding;
    } catch (e) {
      print('Error registering face: $e');
      return null;
    } finally {
      _faceDetector.close();
    }
  }

  // Verify a face - capture image and compare with stored embedding
  Future<Map<String, dynamic>?> verifyFace(List<double> storedEmbedding) async {
    try {
      // 1. Capture image
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      
      if (image == null) return null;

      // 2. Process image to detect face
      final faceData = await _processFaceImage(image.path);
      
      if (faceData == null) return null;

      // 3. Extract face embedding
      final embedding = _extractFaceEmbedding(faceData);
      
      // 4. Calculate similarity
      final similarity = _calculateSimilarity(embedding, storedEmbedding);
      
      // 5. Determine if face matches (threshold can be adjusted)
      final isVerified = similarity >= 0.7;
      
      // 6. Send to backend API (not implemented here)
      // await _sendToBackend(embedding, 'verify', 
      //   similarity: similarity, 
      //   isVerified: isVerified
      // );
      
      return {
        'isVerified': isVerified,
        'similarity': similarity,
        'embedding': embedding
      };
    } catch (e) {
      print('Error verifying face: $e');
      return null;
    } finally {
      _faceDetector.close();
    }
  }

  // Process image and detect faces
  Future<Face?> _processFaceImage(String imagePath) async {
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

  // Extract face embedding from detected face
  List<double> _extractFaceEmbedding(Face face) {
    // Create a simple representation based on face features
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
    final norm = sum > 0 ? _sqrt(sum) : 1.0;
    
    for (int i = 0; i < embedding.length; i++) {
      embedding[i] = embedding[i] / norm;
    }
    
    return embedding;
  }

  // Calculate cosine similarity between two embeddings
  double _calculateSimilarity(List<double> a, List<double> b) {
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length && i < b.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (_sqrt(normA) * _sqrt(normB));
  }

  // Simple square root function
  double _sqrt(double value) {
    return value <= 0 ? 0 : double.parse(_sqrtApprox(value).toStringAsFixed(10));
  }
  
  // Approximate square root using Newton's method
  double _sqrtApprox(double number) {
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
}