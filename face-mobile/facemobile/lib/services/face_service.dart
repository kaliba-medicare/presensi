// lib/services/face_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceService {
  Interpreter? _interpreter;

  // Initialize FaceDetector with optimized settings
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: false,
      minFaceSize: 0.1,
      enableClassification: true, // Important: Enable eye/smile classification
    ),
  );

  /// Load the TFLite model
  Future<void> loadModel() async {
    try {
      _interpreter ??= await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
      );
      
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

  /// Check if the face is live (real person) or a photo/screen
  /// IMPROVED ALGORITHM - Lebih ketat untuk foto, lebih permisif untuk manusia asli
  Map<String, dynamic> checkLiveness(Face face, img.Image image) {
    double livenessScore = 0.0;
    List<String> failedChecks = [];
    List<String> passedChecks = [];
    
    // 1. Check eye open probability (PALING PENTING)
    // Wajah asli biasanya memiliki probabilitas mata terbuka yang tinggi dan konsisten
    final leftEyeProb = face.leftEyeOpenProbability;
    final rightEyeProb = face.rightEyeOpenProbability;
    
    print('👁️ Eye probabilities - Left: $leftEyeProb, Right: $rightEyeProb');
    
    if (leftEyeProb != null && rightEyeProb != null) {
      // Manusia asli: kedua mata terbuka baik (>0.6) atau konsisten
      if (leftEyeProb > 0.6 && rightEyeProb > 0.6) {
        livenessScore += 30.0;
        passedChecks.add('Kedua mata terbuka dengan baik');
      } else if ((leftEyeProb - rightEyeProb).abs() > 0.4) {
        // Jika perbedaan terlalu besar, kemungkinan foto dengan lighting tidak merata
        failedChecks.add('Perbedaan probabilitas mata terlalu besar (foto?)');
      } else if (leftEyeProb > 0.3 && rightEyeProb > 0.3) {
        // Masih acceptable, mungkin mata agak kecil atau pencahayaan kurang
        livenessScore += 15.0;
        passedChecks.add('Mata terdeteksi cukup baik');
      } else {
        failedChecks.add('Mata tidak terdeteksi dengan jelas');
      }
    } else {
      // Jika probability null, biasanya foto yang tidak clear
      failedChecks.add('Deteksi mata tidak tersedia (foto blur?)');
    }
    
    // 2. Check smile probability (optional, tapi membantu)
    final smileProb = face.smilingProbability;
    if (smileProb != null) {
      // Wajah asli biasanya memiliki nilai smile probability yang terdeteksi
      livenessScore += 10.0;
      passedChecks.add('Ekspresi wajah terdeteksi');
      print('😊 Smile probability: $smileProb');
    }
    
    // 3. Check head rotation - DIPERBAIKI
    // Manusia asli BOLEH punya rotasi 0, tapi foto dari layar biasanya punya distorsi angle
    final headY = face.headEulerAngleY?.abs() ?? 0.0;
    final headZ = face.headEulerAngleZ?.abs() ?? 0.0;
    
    print('🔄 Head rotation - Y: $headY°, Z: $headZ°');
    
    // Lebih permisif: rotasi 0-15 derajat masih OK untuk manusia asli
    if (headY <= 15.0 && headZ <= 15.0) {
      livenessScore += 15.0;
      passedChecks.add('Posisi kepala frontal');
    } else if (headY <= 25.0 && headZ <= 25.0) {
      livenessScore += 10.0;
      passedChecks.add('Posisi kepala cukup baik');
    } else {
      failedChecks.add('Kepala terlalu miring (${headY.toStringAsFixed(1)}°, ${headZ.toStringAsFixed(1)}°)');
    }
    
    // 4. Check face size ratio
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final imageArea = image.width * image.height;
    final faceRatio = faceArea / imageArea;
    
    print('📏 Face ratio: ${(faceRatio * 100).toStringAsFixed(1)}%');
    
    // Selfie manusia asli: 8-50% dari gambar
    // Foto dari layar HP: biasanya lebih kecil atau lebih besar dari range normal
    if (faceRatio >= 0.08 && faceRatio <= 0.50) {
      livenessScore += 15.0;
      passedChecks.add('Ukuran wajah proporsional');
    } else if (faceRatio < 0.08) {
      failedChecks.add('Wajah terlalu kecil (${(faceRatio * 100).toStringAsFixed(1)}%) - kemungkinan foto dari layar');
    } else {
      failedChecks.add('Wajah terlalu besar (${(faceRatio * 100).toStringAsFixed(1)}%)');
    }
    
    // 5. Check image quality/sharpness - DIPERBAIKI
    final sharpness = _calculateSharpness(image, face.boundingBox);
    print('🔍 Sharpness: ${sharpness.toStringAsFixed(1)}');
    
    // Foto dari layar cenderung lebih blur (sharpness < 40)
    // Foto langsung dari kamera biasanya lebih tajam (> 35)
    if (sharpness > 45.0) {
      livenessScore += 15.0;
      passedChecks.add('Kualitas gambar sangat baik');
    } else if (sharpness > 30.0) {
      livenessScore += 10.0;
      passedChecks.add('Kualitas gambar cukup');
    } else {
      failedChecks.add('Gambar terlalu buram (${sharpness.toStringAsFixed(1)}) - kemungkinan foto dari layar');
    }
    
    // 6. Check for screen artifacts (moiré patterns) - LEBIH KETAT
    final hasArtifacts = _detectScreenArtifacts(image, face.boundingBox);
    if (!hasArtifacts) {
      livenessScore += 15.0;
      passedChecks.add('Tidak ada pola layar terdeteksi');
    } else {
      failedChecks.add('⚠️ TERDETEKSI pola layar/screen - ini adalah foto dari HP/monitor!');
    }
    
    print('🔍 Liveness Detection Results:');
    print('   📊 Score: $livenessScore/100');
    print('   ✅ Passed: ${passedChecks.join(", ")}');
    if (failedChecks.isNotEmpty) {
      print('   ❌ Failed: ${failedChecks.join(", ")}');
    }
    
    // THRESHOLD YANG LEBIH BAIK:
    // - Skor >= 70: Sangat yakin manusia asli
    // - Skor 55-69: Kemungkinan besar manusia asli, tapi kondisi kurang ideal
    // - Skor < 55: Kemungkinan foto/gambar
    final isLive = livenessScore >= 55.0;
    
    return {
      'isLive': isLive,
      'confidence': livenessScore,
      'failedChecks': failedChecks,
      'passedChecks': passedChecks,
    };
  }

  /// Calculate image sharpness using Laplacian variance
  double _calculateSharpness(img.Image image, Rect boundingBox) {
    try {
      // Crop to face region
      int x = boundingBox.left.toInt().clamp(0, image.width - 1);
      int y = boundingBox.top.toInt().clamp(0, image.height - 1);
      int w = boundingBox.width.toInt().clamp(1, image.width - x);
      int h = boundingBox.height.toInt().clamp(1, image.height - y);
      
      img.Image face = img.copyCrop(image, x: x, y: y, width: w, height: h);
      
      // Convert to grayscale
      img.Image gray = img.grayscale(face);
      
      // Calculate Laplacian variance (edge detection)
      List<double> laplacianValues = [];
      
      for (int y = 1; y < gray.height - 1; y++) {
        for (int x = 1; x < gray.width - 1; x++) {
          int center = gray.getPixel(x, y).r.toInt();
          int top = gray.getPixel(x, y - 1).r.toInt();
          int bottom = gray.getPixel(x, y + 1).r.toInt();
          int left = gray.getPixel(x - 1, y).r.toInt();
          int right = gray.getPixel(x + 1, y).r.toInt();
          
          // Laplacian kernel: [0, 1, 0; 1, -4, 1; 0, 1, 0]
          int laplacian = (4 * center - top - bottom - left - right).abs();
          laplacianValues.add(laplacian.toDouble());
        }
      }
      
      // Return variance (better indicator than mean)
      if (laplacianValues.isEmpty) return 0.0;
      
      double mean = laplacianValues.reduce((a, b) => a + b) / laplacianValues.length;
      double variance = laplacianValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / laplacianValues.length;
      
      // Scale variance to more readable range
      return sqrt(variance);
      
    } catch (e) {
      print('⚠️ Sharpness calculation error: $e');
      return 50.0; // Default neutral value
    }
  }

  /// Detect screen artifacts (moiré patterns, pixel grids) - IMPROVED
  bool _detectScreenArtifacts(img.Image image, Rect boundingBox) {
    try {
      // Sample dari beberapa region wajah untuk deteksi lebih akurat
      int centerX = (boundingBox.left + boundingBox.width / 2).toInt();
      int centerY = (boundingBox.top + boundingBox.height / 2).toInt();
      int sampleSize = 50;
      
      // Pastikan tidak keluar bounds
      int x = (centerX - sampleSize ~/ 2).clamp(0, image.width - sampleSize);
      int y = (centerY - sampleSize ~/ 2).clamp(0, image.height - sampleSize);
      
      img.Image sample = img.copyCrop(image, x: x, y: y, width: sampleSize, height: sampleSize);
      
      // Method 1: Analyze color distribution (screens have RGB patterns)
      int totalPixels = sampleSize * sampleSize;
      Map<String, int> colorBuckets = {};
      
      for (int py = 0; py < sample.height; py++) {
        for (int px = 0; px < sample.width; px++) {
          var pixel = sample.getPixel(px, py);
          // Bucket RGB values into groups of 20
          int r = (pixel.r / 20).floor() * 20;
          int g = (pixel.g / 20).floor() * 20;
          int b = (pixel.b / 20).floor() * 20;
          
          String key = '$r-$g-$b';
          colorBuckets[key] = (colorBuckets[key] ?? 0) + 1;
        }
      }
      
      // Jika ada bucket yang terlalu dominan (>30%), kemungkinan screen
      int maxBucketCount = colorBuckets.values.isEmpty ? 0 : colorBuckets.values.reduce(max);
      double maxRatio = maxBucketCount / totalPixels;
      
      if (maxRatio > 0.30) {
        print('⚠️ Screen artifact detected: color clustering ${(maxRatio * 100).toStringAsFixed(1)}%');
        return true;
      }
      
      // Method 2: Check for periodic patterns (moiré)
      // Foto dari layar sering punya pola berulang
      List<int> rowAverages = [];
      for (int py = 0; py < sample.height; py++) {
        int rowSum = 0;
        for (int px = 0; px < sample.width; px++) {
          var pixel = sample.getPixel(px, py);
          rowSum += (pixel.r + pixel.g + pixel.b) ~/ 3;
        }
        rowAverages.add(rowSum ~/ sample.width);
      }
      
      // Check for repeating patterns in brightness
      int periodicCount = 0;
      for (int i = 2; i < rowAverages.length - 2; i++) {
        int diff1 = (rowAverages[i] - rowAverages[i - 1]).abs();
        int diff2 = (rowAverages[i + 1] - rowAverages[i]).abs();
        
        // Jika ada pola naik-turun yang repetitive
        if (diff1 > 15 && diff2 > 15) {
          periodicCount++;
        }
      }
      
      double periodicRatio = periodicCount / rowAverages.length;
      if (periodicRatio > 0.3) {
        print('⚠️ Screen artifact detected: periodic pattern ${(periodicRatio * 100).toStringAsFixed(1)}%');
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('⚠️ Artifact detection error: $e');
      return false;
    }
  }

  /// Get 128-d embedding from an image file with liveness check
  Future<Map<String, dynamic>?> getEmbeddingFromImageFile(String imagePath) async {
    try {
      print('📸 Processing image: $imagePath');
      
      if (_interpreter == null) {
        print('⚠️ Model not loaded, loading now...');
        await loadModel();
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ Image file does not exist');
        return null;
      }

      final bytes = await file.readAsBytes();
      print('📊 Image size: ${bytes.length} bytes');

      img.Image? ori = img.decodeImage(bytes);
      if (ori == null) {
        print('❌ Failed to decode image');
        return null;
      }
      print('🖼️ Image dimensions: ${ori.width}x${ori.height}');

      final inputImage = InputImage.fromFilePath(imagePath);
      print('🔍 Starting face detection...');
      
      final faces = await _faceDetector.processImage(inputImage);
      print('👤 Detected ${faces.length} face(s)');

      if (faces.isEmpty) {
        print('❌ No faces detected');
        return {'error': 'no_face', 'message': 'Wajah tidak terdeteksi'};
      }

      final face = faces.first;
      
      // LIVENESS CHECK
      print('🔐 Performing liveness detection...');
      final livenessResult = checkLiveness(face, ori);
      
      if (!livenessResult['isLive']) {
        print('❌ Liveness check failed - Score: ${livenessResult['confidence']}/100');
        return {
          'error': 'not_live',
          'message': 'Terdeteksi foto/gambar, bukan wajah asli',
          'confidence': livenessResult['confidence'],
          'failedChecks': livenessResult['failedChecks'],
        };
      }
      
      print('✅ Liveness check passed - Score: ${livenessResult['confidence']}/100');
      
      final rect = face.boundingBox;

      // Add padding to bounding box
      const double padding = 0.2;
      int x = (rect.left - rect.width * padding).toInt().clamp(0, ori.width - 1);
      int y = (rect.top - rect.height * padding).toInt().clamp(0, ori.height - 1);
      int w = (rect.width * (1 + 2 * padding)).toInt().clamp(1, ori.width - x);
      int h = (rect.height * (1 + 2 * padding)).toInt().clamp(1, ori.height - y);

      print('✂️ Cropping face: x=$x, y=$y, w=$w, h=$h');

      img.Image faceImg = img.copyCrop(ori, x: x, y: y, width: w, height: h);
      img.Image resized = img.copyResize(faceImg, width: 112, height: 112);
      print('📐 Resized to: ${resized.width}x${resized.height}');

      var input = _imageToFloat32List(resized, 112, 112);
      print('🔢 Input tensor shape: [1, 112, 112, 3]');

      try {
        var outputShape = _interpreter!.getOutputTensor(0).shape;
        print('📊 Output tensor shape: $outputShape');
        
        int embeddingSize = outputShape.last;
        var output = List.generate(1, (_) => List.filled(embeddingSize, 0.0));

        print('🧠 Running inference...');
        _interpreter!.run(input, output);
        print('✅ Inference complete');

        List<double> embedding = output[0].cast<double>();

        double norm = sqrt(embedding.fold(0.0, (sum, val) => sum + val * val));
        if (norm == 0) norm = 1.0;
        final normalized = embedding.map((e) => e / norm).toList();

        print('✅ Embedding generated successfully (${normalized.length} dimensions)');
        return {
          'embedding': normalized,
          'liveness': livenessResult,
        };
      } catch (inferenceError) {
        print('❌ Inference error: $inferenceError');
        return {'error': 'inference_failed', 'message': 'Gagal memproses wajah'};
      }
    } catch (e, stackTrace) {
      print('❌ Error getting embedding: $e');
      print('Stack trace: $stackTrace');
      return {'error': 'unknown', 'message': e.toString()};
    }
  }

  /// Convert image to Float32List for TFLite input
  List<List<List<List<double>>>> _imageToFloat32List(img.Image image, int inputWidth, int inputHeight) {
    List<List<List<List<double>>>> input = List.generate(
      1,
      (_) => List.generate(
        inputHeight,
        (y) => List.generate(
          inputWidth,
          (x) {
            final pixel = image.getPixel(x, y);
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