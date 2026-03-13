import 'package:hive/hive.dart';

part 'health_reading.g.dart';

@HiveType(typeId: 0)
class HealthReading extends HiveObject {
  @HiveField(0)
  final String patientName;

  @HiveField(1)
  final String userEmail;

  @HiveField(2)
  final double weight;

  @HiveField(3)
  final double height;

  @HiveField(4)
  final double bmi;

  @HiveField(5)
  final int heartRate;

  @HiveField(6)
  final int spo2;

  @HiveField(7)
  final double temperature;

  @HiveField(8)
  final int systolic;

  @HiveField(9)
  final int diastolic;

  @HiveField(10)
  final DateTime timestamp;

  @HiveField(11)
  bool synced;

  HealthReading({
    required this.patientName,
    required this.userEmail,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'patient_name': patientName,
      'user_email': userEmail,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'heart_rate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'systolic': systolic,
      'diastolic': diastolic,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HealthReading.fromJson(Map<String, dynamic> json) {
    return HealthReading(
      patientName: json['patient_name'],
      userEmail: json['user_email'],
      weight: json['weight'].toDouble(),
      height: json['height'].toDouble(),
      bmi: json['bmi'].toDouble(),
      heartRate: json['heart_rate'],
      spo2: json['spo2'],
      temperature: json['temperature'].toDouble(),
      systolic: json['systolic'],
      diastolic: json['diastolic'],
      timestamp: DateTime.parse(json['timestamp']),
      synced: json['synced'] ?? false,
    );
  }
}