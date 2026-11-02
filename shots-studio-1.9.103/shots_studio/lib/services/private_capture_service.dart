import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/logger_service.dart';
import 'package:uuid/uuid.dart';

class PrivateCaptureService {
  static const MethodChannel _channel = MethodChannel('mind_space_capture');
  static final PrivateCaptureService _instance = PrivateCaptureService._internal();

  factory PrivateCaptureService() => _instance;

  final StreamController<String> _captureController = StreamController<String>.broadcast();
  Stream<String> get onPrivateMemoryCaptured => _captureController.stream;

  bool _initialized = false;

  PrivateCaptureService._internal();

  void initialize({required Function(Screenshot) onNewScreenshot}) {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPrivateMemoryCaptured') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          LoggerService.log('PrivateCaptureService: Received private capture: $path');
          _captureController.add(path);
          final screenshot = _createScreenshotFromPath(path);
          onNewScreenshot(screenshot);
        }
      }
    });

    // Check for any captures that happened while app was paused or closed
    checkPendingMemories(onNewScreenshot);
  }

  Future<void> checkPendingMemories(Function(Screenshot) onNewScreenshot) async {
    if (kIsWeb) return;
    try {
      final List<dynamic>? pendingPaths = await _channel.invokeMethod<List<dynamic>>('getPendingMemories');
      if (pendingPaths != null && pendingPaths.isNotEmpty) {
        LoggerService.log('PrivateCaptureService: Found ${pendingPaths.length} pending private captures');
        for (final item in pendingPaths) {
          final path = item.toString();
          if (path.isNotEmpty) {
            final screenshot = _createScreenshotFromPath(path);
            onNewScreenshot(screenshot);
          }
        }
      }
    } catch (e) {
      LoggerService.error('PrivateCaptureService: Error checking pending memories', e);
    }
  }

  Screenshot _createScreenshotFromPath(String path) {
    return Screenshot(
      id: const Uuid().v4(),
      path: path,
      addedOn: DateTime.now(),
      aiProcessed: false,
      title: 'Mind Space Memory',
      description: '',
      tags: ['Memory'],
      links: [],
      collectionIds: [],
    );
  }

  Future<void> triggerCapture() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('triggerCapture');
    } catch (e) {
      LoggerService.error('PrivateCaptureService: Error triggering capture', e);
    }
  }

  Future<void> showCaptureNotification() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('showCaptureNotification');
    } catch (e) {
      LoggerService.error('PrivateCaptureService: Error showing capture notification', e);
    }
  }

  Future<void> dismissCaptureNotification() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('dismissCaptureNotification');
    } catch (e) {
      LoggerService.error('PrivateCaptureService: Error dismissing capture notification', e);
    }
  }
}
