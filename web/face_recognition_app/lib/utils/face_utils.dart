import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';

class FaceUtils {
  // Process image and extract face embedding using Google ML Kit
  static Future<List<double>?> processFaceImage(String imagePath) async {
    try {
      // Initialize face detector
      final FaceDetector _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
          minFaceSize: 0.1,
        ),
      );

      // Load image
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Process image
      final faces = await _faceDetector.processImage(inputImage);
      
      // Close detector
      _faceDetector.close();
      
      // Return null if no face detected
      if (faces.isEmpty) return null;
      
      // Extract embedding from first detected face
      return extractFaceEmbedding(faces.first);
    } catch (e) {
      debugPrint('Error processing face: $e');
      return null;
    }
  }
  
  // Extract face embedding from detected face
  static List<double> extractFaceEmbedding(Face face) {
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
  
  // Calculate cosine similarity between two embeddings
  static double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length && i < b.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }
  
  // Simple square root function
  static double sqrt(double value) {
    return value <= 0 ? 0 : double.parse(sqrtApprox(value).toStringAsFixed(10));
  }
  
  // Approximate square root using Newton's method
  static double sqrtApprox(double number) {
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