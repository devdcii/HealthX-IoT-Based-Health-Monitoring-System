class ApiConfig {
  // ===== BASE URLs =====
  static const String baseUrl = 'https://healthhccx.cpedev.site//healthx/api';
  static const String esp32Url = 'http://192.168.8.45';

  // ===== WEB SERVER ENDPOINTS (Database) =====
  static const String authEndpoint = '$baseUrl/auth.php';
  static const String getPatientsEndpoint = '$baseUrl/get_patients.php';
  static const String getReadingsEndpoint = '$baseUrl/get_readings.php';
  static const String saveReadingEndpoint = '$baseUrl/save_reading.php';
  static const String deletePatientEndpoint = '$baseUrl/delete_patient.php';
  static const String deleteReadingEndpoint = '$baseUrl/delete_reading.php';
  static const String updateReadingEndpoint = '$baseUrl/update_reading.php';
  static const String updateProfileEndpoint = '$baseUrl/update_profile.php';

  // ===== 🆕 ESP32 SENSOR CONTROL ENDPOINTS (START) =====
  static const String esp32WeightStartEndpoint = '$esp32Url/sensor/weight/start';
  static const String esp32HeightStartEndpoint = '$esp32Url/sensor/height/start';
  static const String esp32HRStartEndpoint = '$esp32Url/sensor/hr/start';
  static const String esp32TempStartEndpoint = '$esp32Url/sensor/temp/start';
  static const String esp32BPStartEndpoint = '$esp32Url/sensor/bp/start';

  // ===== 🆕 ESP32 SENSOR CONTROL ENDPOINTS (STOP) =====
  static const String esp32StopSensorEndpoint = '$esp32Url/sensor/stop';
  static const String esp32StopSensorsEndpoint = '$esp32Url/sensors/stop';

  // ===== ESP32 DATA ENDPOINTS (READ-ONLY) =====
  static const String esp32HealthEndpoint = '$esp32Url/health';
  static const String esp32StatusEndpoint = '$esp32Url/status';
  static const String esp32WeightEndpoint = '$esp32Url/weight';
  static const String esp32HeightEndpoint = '$esp32Url/height';
  static const String esp32HeartRateEndpoint = '$esp32Url/heartrate';
  static const String esp32SpO2Endpoint = '$esp32Url/spo2';
  static const String esp32TemperatureEndpoint = '$esp32Url/temperature';
  static const String esp32BloodPressureEndpoint = '$esp32Url/bloodpressure';

  // ===== ESP32 UTILITY ENDPOINTS =====
  static const String esp32TareEndpoint = '$esp32Url/tare';
  static const String esp32StartBPEndpoint = '$esp32Url/bp/start';
}