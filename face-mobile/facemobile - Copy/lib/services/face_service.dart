// lib/services/face_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceService {
  Interpreter? _interpreter;

  // Initialize FaceDetector with optimized settings
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate, // Changed to accurate
      enableLandmarks: true,
      enableContours: true,
      enableTracking: false,
      minFaceSize: 0.1, // Detect smaller faces (10% of image)
    ),
  );

  /// Load the TFLite model
  Future<void> loadModel() async {
    try {
      _interpreter ??= await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
      );
      
      // Print model input/output details
      print('✅ Model loaded successfully');
      print('📥 Input tensor details:');
      var inputTensor = _interpreter!.getInputTensor(0);
      print('   Shape: ${inputTensor.shape}');
      print('   Type: ${inputTensor.type}');
      
      print('📤 Output tensor details:');
      var outputTensor = _interpreter!.getOutputTensor(0);
      print('   Shape: ${outputTensor.shape}');
      print('   Type: ${outputTensor.type}');
      
    } catch (e) {
      print('❌ Failed to load model: $e');
      throw Exception('Failed to load TFLite model: $e');
    }
  }

  /// Get 128-d embedding from an image file
  Future<List<double>?> getEmbeddingFromImageFile(String imagePath) async {
    try {
      print('📸 Processing image: $imagePath');
      
      // Ensure model is loaded
      if (_interpreter == null) {
        print('⚠️ Model not loaded, loading now...');
        await loadModel();
      }

      // Check if file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ Image file does not exist');
        return null;
      }

      final bytes = await file.readAsBytes();
      print('📊 Image size: ${bytes.length} bytes');

      // Decode image first to check dimensions
      img.Image? ori = img.decodeImage(bytes);
      if (ori == null) {
        print('❌ Failed to decode image');
        return null;
      }
      print('🖼️ Image dimensions: ${ori.width}x${ori.height}');

      // Create InputImage
      final inputImage = InputImage.fromFilePath(imagePath);
      print('🔍 Starting face detection...');
      
      final faces = await _faceDetector.processImage(inputImage);
      print('👤 Detected ${faces.length} face(s)');

      if (faces.isEmpty) {
        print('❌ No faces detected');
        return null;
      }

      // Log all detected faces
      for (int i = 0; i < faces.length; i++) {
        final face = faces[i];
        print('Face $i: ${face.boundingBox}');
        print('  - Head euler angle Y: ${face.headEulerAngleY}');
        print('  - Head euler angle Z: ${face.headEulerAngleZ}');
        print('  - Left eye open probability: ${face.leftEyeOpenProbability}');
        print('  - Right eye open probability: ${face.rightEyeOpenProbability}');
      }

      final face = faces.first;
      final rect = face.boundingBox;

      // Add padding to bounding box
      const double padding = 0.2; // 20% padding
      int x = (rect.left - rect.width * padding).toInt().clamp(0, ori.width - 1);
      int y = (rect.top - rect.height * padding).toInt().clamp(0, ori.height - 1);
      int w = (rect.width * (1 + 2 * padding)).toInt().clamp(1, ori.width - x);
      int h = (rect.height * (1 + 2 * padding)).toInt().clamp(1, ori.height - y);

      print('✂️ Cropping face: x=$x, y=$y, w=$w, h=$h');

      // Crop face
      img.Image faceImg = img.copyCrop(
        ori,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      // Resize to 112x112
      img.Image resized = img.copyResize(
        faceImg,
        width: 112,
        height: 112,
      );
      print('📐 Resized to: ${resized.width}x${resized.height}');

      // Prepare input for TFLite with correct shape
      var input = _imageToFloat32List(resized, 112, 112);
      print('🔢 Input tensor shape: [1, 112, 112, 3]');

      // Get output tensor details
      try {
        var outputShape = _interpreter!.getOutputTensor(0).shape;
        print('📊 Output tensor shape: $outputShape');
        
        int embeddingSize = outputShape.last; // Usually 128 or 192
        var output = List.generate(1, (_) => List.filled(embeddingSize, 0.0));

        print('🧠 Running inference...');
        _interpreter!.run(input, output);
        print('✅ Inference complete');

        List<double> embedding = output[0].cast<double>();

        // L2 normalize
        double norm = sqrt(embedding.fold(0.0, (sum, val) => sum + val * val));
        if (norm == 0) norm = 1.0;
        final normalized = embedding.map((e) => e / norm).toList();

        print('✅ Embedding generated successfully (${normalized.length} dimensions)');
        return normalized;
      } catch (inferenceError) {
        print('❌ Inference error: $inferenceError');
        print('Trying alternative tensor allocation...');
        
        // Alternative: Try with different output format
        var output = List.filled(128, 0.0);
        try {
          _interpreter!.run(input, output.reshape([1, 128]));
          
          // L2 normalize
          double norm = sqrt(output.fold(0.0, (sum, val) => sum + val * val));
          if (norm == 0) norm = 1.0;
          final normalized = output.map((e) => e / norm).toList();
          
          print('✅ Embedding generated with alternative method');
          return normalized;
        } catch (altError) {
          print('❌ Alternative method also failed: $altError');
          return null;
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error getting embedding: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Convert image to Float32List for TFLite input
  /// Returns properly shaped tensor data
  List<List<List<List<double>>>> _imageToFloat32List(img.Image image, int inputWidth, int inputHeight) {
    // Create the correct shape: [1, 112, 112, 3]
    List<List<List<List<double>>>> input = List.generate(
      1,
      (_) => List.generate(
        inputHeight,
        (y) => List.generate(
          inputWidth,
          (x) {
            final pixel = image.getPixel(x, y);
            // Normalize RGB values to [-1, 1] range
            return [
              (pixel.r - 127.5) / 128.0,
              (pixel.g - 127.5) / 128.0,
              (pixel.b - 127.5) / 128.0,
            ];
          },
        ),
      ),
    );
    
    return input;
  }

  /// Close resources
  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}