import 'package:flutter/services.dart';

class CastarService {
  static const MethodChannel _channel = MethodChannel('com.castar.sdk/bridge');
  static bool _isInitialized = false;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final bool result = await _channel.invokeMethod('initializeCastar');
      _isInitialized = result;
      return result;
    } on PlatformException catch (e) {
      print('Failed to initialize Castar SDK: ${e.message}');
      return false;
    }
  }

  static Future<bool> start() async {
    try {
      return await _channel.invokeMethod('startCastar');
    } on PlatformException catch (e) {
      print('Failed to start Castar SDK: ${e.message}');
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      return await _channel.invokeMethod('stopCastar');
    } on PlatformException catch (e) {
      print('Failed to stop Castar SDK: ${e.message}');
      return false;
    }
  }
} 