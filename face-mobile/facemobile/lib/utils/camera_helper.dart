// lib/utils/camera_helper.dart
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraHelper {
  static List<CameraDescription>? _cameras;
  
  /// Initialize cameras once at app startup
  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      debugPrint('📷 Available cameras: ${_cameras?.length ?? 0}');
      
      for (var i = 0; i < (_cameras?.length ?? 0); i++) {
        final camera = _cameras![i];
        debugPrint('  Camera $i: ${camera.name} (${camera.lensDirection})');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize cameras: $e');
      _cameras = [];
    }
  }
  
  /// Get front camera
  static CameraDescription? getFrontCamera() {
    if (_cameras == null || _cameras!.isEmpty) {
      debugPrint('⚠️ No cameras available');
      return null;
    }
    
    try {
      return _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } catch (e) {
      debugPrint('⚠️ No front camera found, using first available');
      return _cameras!.first;
    }
  }
  
  /// Get back camera
  static CameraDescription? getBackCamera() {
    if (_cameras == null || _cameras!.isEmpty) {
      debugPrint('⚠️ No cameras available');
      return null;
    }
    
    try {
      return _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    } catch (e) {
      debugPrint('⚠️ No back camera found, using first available');
      return _cameras!.first;
    }
  }
  
  /// Check if cameras are initialized
  static bool get isInitialized => _cameras != null && _cameras!.isNotEmpty;
  
  /// Get all cameras
  static List<CameraDescription> get cameras => _cameras ?? [];
}