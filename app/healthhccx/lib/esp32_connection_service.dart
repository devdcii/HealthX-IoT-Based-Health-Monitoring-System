import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

/// Global singleton service for ESP32 connection monitoring
/// Runs continuously across all screens - never disconnects when switching tabs
class Esp32ConnectionService {
  // Singleton pattern
  static final Esp32ConnectionService _instance = Esp32ConnectionService._internal();
  factory Esp32ConnectionService() => _instance;
  Esp32ConnectionService._internal();

  // Connection status - ALL screens can listen to this
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  Timer? _connectionTimer;
  bool _isChecking = false;

  /// Start monitoring - called once in main.dart
  void startMonitoring() {
    if (_connectionTimer != null && _connectionTimer!.isActive) {
      print('⚠️ ESP32 monitoring already running');
      return;
    }

    print('🚀 ESP32 Monitoring STARTED - Will run continuously!');

    // Check immediately
    _checkConnection();

    // Check every 3 seconds FOREVER (until app closes)
    _connectionTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _checkConnection();
    });
  }

  /// Stop monitoring - ONLY call when app completely closes
  void stopMonitoring() {
    print('🛑 ESP32 Monitoring STOPPED');
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }

  /// Check ESP32 connection status
  Future<void> _checkConnection() async {
    if (_isChecking) return;

    _isChecking = true;

    try {
      final result = await ApiService.getEsp32HealthData();
      bool newStatus = result['success'] != false;

      // Only update if status changed (prevents unnecessary rebuilds)
      if (isConnected.value != newStatus) {
        isConnected.value = newStatus;
        print('📡 ESP32 Status: ${newStatus ? "CONNECTED ✅" : "DISCONNECTED ❌"}');
      }
    } catch (e) {
      if (isConnected.value != false) {
        isConnected.value = false;
        print('📡 ESP32 Status: DISCONNECTED ❌ (Error: $e)');
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Force refresh connection (optional - for manual refresh button)
  Future<void> refreshConnection() async {
    await _checkConnection();
  }

  /// Dispose service (ONLY when app closes completely)
  void dispose() {
    stopMonitoring();
    isConnected.dispose();
  }
}