import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'onboarding.dart';
import 'models/health_reading.dart';
import 'esp32_connection_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapter for HealthReading
  Hive.registerAdapter(HealthReadingAdapter());

  // Open the box for health readings
  await Hive.openBox<HealthReading>('health_readings');

  // Open the box for seen patient emails
  await Hive.openBox('seen_patient_emails');

  // ✅ START ESP32 MONITORING GLOBALLY - RUNS FOREVER!
  Esp32ConnectionService().startMonitoring();
  print('✅ ESP32 Global Monitoring is now ACTIVE!');

  runApp(const HealthXApp());
}

class HealthXApp extends StatelessWidget {
  const HealthXApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
      ),
      home: const OnboardingScreen(),
    );
  }
}