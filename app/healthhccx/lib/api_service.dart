import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  // ===== HELPER METHODS: Time Conversion =====

  /// Converts Philippine Time to UTC for saving to database
  /// PHP will add +8 hours via CONVERT_TZ, so we subtract 8 hours first
  static String _convertToUTC(DateTime phTime) {
    try {
      // Subtract 8 hours to convert PH time to UTC
      DateTime utcTime = phTime.subtract(Duration(hours: 8));

      // Format as MySQL datetime: YYYY-MM-DD HH:MM:SS
      String formatted =
          '${utcTime.year.toString().padLeft(4, '0')}-'
          '${utcTime.month.toString().padLeft(2, '0')}-'
          '${utcTime.day.toString().padLeft(2, '0')} '
          '${utcTime.hour.toString().padLeft(2, '0')}:'
          '${utcTime.minute.toString().padLeft(2, '0')}:'
          '${utcTime.second.toString().padLeft(2, '0')}';

      print('   🕒 PH Time: $phTime');
      print('   🌍 UTC Time: $formatted');

      return formatted;
    } catch (e) {
      print('⚠️ UTC conversion error: $e');
      return DateTime.now().toString();
    }
  }

  // ===== AUTHENTICATION =====

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Login Request:');
      print('   Email: $email');
      print('   Endpoint: ${ApiConfig.authEndpoint}');

      final response = await http.post(
        Uri.parse(ApiConfig.authEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'login',
          'email': email,
          'password': password,
        }),
      );

      print('📥 Login Response Status: ${response.statusCode}');
      print('📥 Login Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        print('✅ Login successful!');
        print('   User ID: ${data['user_id']}');
        print('   Name: ${data['name']}');
        print('   Email: ${data['email']}');
        print('   User Type: ${data['user_type']}');

        if (data['user_id'] == null) {
          print('❌ WARNING: user_id is null! Check your PHP login API.');
        }
      } else {
        print('❌ Login failed: ${data['message']}');
      }

      return data;
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {
    try {
      print('📝 Signup Request:');
      print('   Name: $name');
      print('   Email: $email');

      final response = await http.post(
        Uri.parse(ApiConfig.authEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'signup',
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      print('📥 Signup Response Status: ${response.statusCode}');
      print('📥 Signup Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Signup error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ===== PATIENT MANAGEMENT =====

  static Future<Map<String, dynamic>> getPatients() async {
    try {
      print('👥 Fetching patients...');

      final response = await http.get(
        Uri.parse(ApiConfig.getPatientsEndpoint),
      );

      print('📥 Get Patients Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Fetched ${data['patients']?.length ?? 0} patients');
        return data;
      }

      print('❌ Failed to fetch patients - Status: ${response.statusCode}');
      return {'success': false, 'message': 'Failed to fetch patients'};
    } catch (e) {
      print('❌ Get Patients error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deletePatient(dynamic patientId) async {
    try {
      int id = patientId is String ? int.parse(patientId) : patientId;

      print('🗑️ Deleting patient ID: $id');

      final response = await http.post(
        Uri.parse(ApiConfig.deletePatientEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patient_id': id}),
      );

      print('📥 Delete Patient Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Patient deleted: ${data['success']}');
        return data;
      }

      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      print('❌ Delete Patient error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ===== HEALTH READINGS =====

  static Future<Map<String, dynamic>> getReadings(String userEmail) async {
    try {
      final encodedEmail = Uri.encodeComponent(userEmail);
      final url = '${ApiConfig.getReadingsEndpoint}?email=$encodedEmail';

      print('📊 GET READINGS REQUEST:');
      print('   Email: $userEmail');
      print('   Full URL: $url');

      final response = await http.get(Uri.parse(url));

      print('📥 GET READINGS RESPONSE:');
      print('   Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          data['readings'] = data['readings'] ?? [];

          print('✅ Found ${data['readings'].length} readings');
          if (data['readings'].length > 0) {
            print('   First reading timestamp: ${data['readings'][0]['timestamp']}');
          }
        }

        return data;
      }

      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
        'readings': []
      };
    } catch (e) {
      print('❌ EXCEPTION in getReadings: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'readings': []
      };
    }
  }

  static Future<Map<String, dynamic>> saveReading(
      Map<String, dynamic> readingData) async {
    try {
      print('💾 SAVE READING REQUEST:');

      // ✅ FIX: Convert current PH time to UTC before sending to PHP
      // PHP will add +8 hours via CONVERT_TZ, so we need to send UTC time
      DateTime now = DateTime.now(); // This is PH time in your mobile
      String utcTimestamp = _convertToUTC(now);

      // Create a copy of readingData and add the UTC timestamp
      Map<String, dynamic> dataToSend = Map.from(readingData);
      dataToSend['timestamp'] = utcTimestamp;

      print('   Data: $dataToSend');

      final response = await http.post(
        Uri.parse(ApiConfig.saveReadingEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataToSend),
      );

      print('📥 Save Reading Response: ${response.statusCode}');
      print('📥 Save Reading Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Reading saved: ${data['success']}');
        return data;
      }

      return {'success': false, 'message': 'Failed to save reading'};
    } catch (e) {
      print('❌ Save Reading error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteReading(dynamic readingId) async {
    try {
      int id = readingId is String ? int.parse(readingId) : readingId;

      print('🗑️ Deleting reading ID: $id');

      final response = await http.post(
        Uri.parse(ApiConfig.deleteReadingEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reading_id': id}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Reading deleted: ${data['success']}');
        return data;
      }

      return {'success': false, 'message': 'Failed to delete reading'};
    } catch (e) {
      print('❌ Delete Reading error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateReading(
      dynamic readingId, Map<String, dynamic> readingData) async {
    try {
      int id = readingId is String ? int.parse(readingId) : readingId;

      print('✏️ UPDATE READING REQUEST:');
      print('   Reading ID: $id');

      final response = await http.post(
        Uri.parse(ApiConfig.updateReadingEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reading_id': id,
          'bmi': readingData['bmi'],
          'heart_rate': readingData['heart_rate'],
          'spo2': readingData['spo2'],
          'temperature': readingData['temperature'],
          'systolic': readingData['systolic'],
          'diastolic': readingData['diastolic'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Reading updated: ${data['success']}');
        return data;
      }

      return {'success': false, 'message': 'Failed to update reading'};
    } catch (e) {
      print('❌ Update Reading error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ===== 🆕 SENSOR CONTROL (START) =====

  static Future<Map<String, dynamic>> startWeightSensor() async {
    try {
      print('⚖️ Starting weight sensor...');

      final response = await http.post(
        Uri.parse(ApiConfig.esp32WeightStartEndpoint),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Weight sensor started: ${data['success']}');
        return data;
      }

      print('❌ Failed to start weight sensor');
      return {'success': false, 'message': 'Failed to start sensor'};
    } catch (e) {
      print('❌ Start weight sensor error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> startHeightSensor() async {
    try {
      print('📏 Starting height sensor...');

      final response = await http.post(
        Uri.parse(ApiConfig.esp32HeightStartEndpoint),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Height sensor started: ${data['success']}');
        return data;
      }

      print('❌ Failed to start height sensor');
      return {'success': false, 'message': 'Failed to start sensor'};
    } catch (e) {
      print('❌ Start height sensor error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> startHRSensor() async {
    try {
      print('💓 Starting HR sensor...');

      final response = await http.post(
        Uri.parse(ApiConfig.esp32HRStartEndpoint),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ HR sensor started: ${data['success']}');
        return data;
      }

      print('❌ Failed to start HR sensor');
      return {'success': false, 'message': 'Failed to start sensor'};
    } catch (e) {
      print('❌ Start HR sensor error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> startTempSensor() async {
    try {
      print('🌡️ Starting temperature sensor...');

      final response = await http.post(
        Uri.parse(ApiConfig.esp32TempStartEndpoint),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Temperature sensor started: ${data['success']}');
        return data;
      }

      print('❌ Failed to start temperature sensor');
      return {'success': false, 'message': 'Failed to start sensor'};
    } catch (e) {
      print('❌ Start temperature sensor error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> startBPSensor() async {
    try {
      print('🩺 Starting BP sensor...');

      final response = await http.post(
        Uri.parse(ApiConfig.esp32BPStartEndpoint),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ BP sensor started: ${data['success']}');
        return data;
      }

      print('❌ Failed to start BP sensor');
      return {'success': false, 'message': 'Failed to start sensor'};
    } catch (e) {
      print('❌ Start BP sensor error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ===== 🆕 SENSOR CONTROL (STOP) =====

  static Future<void> stopSensor() async {
    try {
      print('🛑 Stopping active sensor...');

      await http.post(
        Uri.parse(ApiConfig.esp32StopSensorEndpoint),
      ).timeout(Duration(seconds: 3));

      print('✅ Sensor stopped');
    } catch (e) {
      print('⚠️ Sensor stop failed: $e');
    }
  }

  static Future<void> stopAllSensors() async {
    try {
      print('🛑 Stopping all sensors...');

      await http.post(
        Uri.parse(ApiConfig.esp32StopSensorsEndpoint),
      ).timeout(Duration(seconds: 3));

      print('✅ All sensors stopped');
    } catch (e) {
      print('⚠️ Sensor stop failed: $e');
    }
  }

  // ===== ESP32 SENSOR DATA (READ-ONLY) =====

  static Future<Map<String, dynamic>> getEsp32HealthData() async {
    try {
      print('🔌 Fetching ESP32 health data...');

      final response = await http.get(
        Uri.parse(ApiConfig.esp32HealthEndpoint),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safe type conversion for irValue
        int irValue = 0;
        bool fingerDetected = false;

        if (data['heartRate'] != null && data['heartRate']['irValue'] != null) {
          var rawIrValue = data['heartRate']['irValue'];

          if (rawIrValue is int) {
            irValue = rawIrValue;
          } else if (rawIrValue is double) {
            irValue = rawIrValue.toInt();
          } else if (rawIrValue is String) {
            irValue = int.tryParse(rawIrValue) ?? 0;
          }

          fingerDetected = data['heartRate']['fingerDetected'] ?? (irValue > 50000);
        }

        data['success'] = true;
        data['fingerDetected'] = fingerDetected;
        data['irValue'] = irValue;

        print('✅ ESP32 health data received');
        return data;
      }

      print('❌ ESP32 health data failed');
      return {
        'success': false,
        'message': 'Failed to fetch ESP32 data',
        'fingerDetected': false,
        'irValue': 0,
      };
    } catch (e) {
      print('❌ ESP32 health data error: $e');
      return {
        'success': false,
        'message': 'ESP32 connection error: $e',
        'fingerDetected': false,
        'irValue': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> getEsp32Status() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.esp32StatusEndpoint),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  // ✅ FIXED: Weight with proper error handling
  static Future<Map<String, dynamic>> getWeight() async {
    try {
      print('⚖️ Fetching weight...');

      final response = await http.get(
        Uri.parse(ApiConfig.esp32WeightEndpoint),
      ).timeout(Duration(seconds: 5));

      print('📥 Weight Response Status: ${response.statusCode}');
      print('📥 Weight Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ FIXED: Handle weight value safely with explicit conversion
        double weight = 0.0;
        if (data['value'] != null) {
          if (data['value'] is num) {
            weight = (data['value'] as num).toDouble();
          } else if (data['value'] is String) {
            weight = double.tryParse(data['value']) ?? 0.0;
          }
        }

        // Make sure weight is positive
        weight = weight.abs();

        print('✅ Weight received: $weight kg');
        return {
          'success': true,
          'weight': weight,
          'unit': 'kg',
          'active': data['active'] ?? false,
          'ready': data['ready'] ?? false,
        };
      }

      print('❌ Weight fetch failed');
      return {'success': false, 'weight': 0.0};
    } catch (e) {
      print('❌ Weight error: $e');
      return {'success': false, 'weight': 0.0, 'message': '$e'};
    }
  }

  // ✅ FIXED: Height with proper error handling
  static Future<Map<String, dynamic>> getHeight() async {
    try {
      print('📏 Fetching height...');

      final response = await http.get(
        Uri.parse(ApiConfig.esp32HeightEndpoint),
      ).timeout(Duration(seconds: 5));

      print('📥 Height Response Status: ${response.statusCode}');
      print('📥 Height Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ FIXED: Handle height value safely
        double height = 0.0;
        if (data['value'] != null) {
          if (data['value'] is num) {
            height = (data['value'] as num).toDouble();
          } else if (data['value'] is String) {
            height = double.tryParse(data['value']) ?? 0.0;
          }
        }

        print('✅ Height received: $height cm');
        return {
          'success': true,
          'height': height,
          'unit': 'cm',
          'active': data['active'] ?? false,
          'ready': data['ready'] ?? false,
        };
      }

      print('❌ Height fetch failed');
      return {'success': false, 'height': 0.0};
    } catch (e) {
      print('❌ Height error: $e');
      return {'success': false, 'height': 0.0, 'message': '$e'};
    }
  }

  // ✅ FIXED: Heart rate with proper finger detection
  static Future<Map<String, dynamic>> getHeartRate() async {
    try {
      print('💓 Fetching heart rate...');

      final response = await http.get(
        Uri.parse(ApiConfig.esp32HeartRateEndpoint),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safe type conversion for irValue
        int irValue = 0;
        if (data['irValue'] != null) {
          var rawIrValue = data['irValue'];

          if (rawIrValue is int) {
            irValue = rawIrValue;
          } else if (rawIrValue is double) {
            irValue = rawIrValue.toInt();
          } else if (rawIrValue is String) {
            irValue = int.tryParse(rawIrValue) ?? 0;
          }
        }

        // Calculate finger detection
        bool fingerDetected = data['finger'] ?? (irValue > 50000);

        // Get heart rate value
        int heartRate = 0;
        if (data['bpm'] != null) {
          if (data['bpm'] is int) {
            heartRate = data['bpm'];
          } else if (data['bpm'] is double) {
            heartRate = (data['bpm'] as double).toInt();
          } else if (data['bpm'] is String) {
            heartRate = int.tryParse(data['bpm']) ?? 0;
          }
        }

        print('✅ Heart rate received: $heartRate bpm');
        print('   IR Value: $irValue');
        print('   Finger Detected: $fingerDetected');

        return {
          'success': true,
          'heartRate': heartRate,
          'irValue': irValue,
          'fingerDetected': fingerDetected,
          'unit': 'bpm',
          'valid': heartRate > 0 && heartRate >= 40 && heartRate <= 200,
          'active': data['active'] ?? false,
          'ready': data['ready'] ?? false,
        };
      }

      print('❌ Heart rate fetch failed');
      return {
        'success': false,
        'heartRate': 0,
        'irValue': 0,
        'fingerDetected': false,
      };
    } catch (e) {
      print('❌ Heart rate error: $e');
      return {
        'success': false,
        'heartRate': 0,
        'irValue': 0,
        'fingerDetected': false,
        'message': '$e',
      };
    }
  }

  static Future<Map<String, dynamic>> getSpO2() async {
    try {
      print('🫁 Fetching SpO2...');

      final response = await http.get(
        Uri.parse(ApiConfig.esp32SpO2Endpoint),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Get SpO2 value
        int spo2 = 0;
        if (data['value'] != null) {
          if (data['value'] is int) {
            spo2 = data['value'];
          } else if (data['value'] is double) {
            spo2 = (data['value'] as double).toInt();
          } else if (data['value'] is String) {
            spo2 = int.tryParse(data['value']) ?? 0;
          }
        }

        print('✅ SpO2 received: $spo2%');
        return {
          'success': true,
          'spo2': spo2,
          'unit': '%',
          'valid': data['valid'] ?? (spo2 > 0 && spo2 <= 100),
          'active': data['active'] ?? false,
        };
      }

      print('❌ SpO2 fetch failed');
      return {'success': false, 'spo2': 0};
    } catch (e) {
      print('❌ SpO2 error: $e');
      return {'success': false, 'spo2': 0, 'message': '$e'};
    }
  }

  static Future<Map<String, dynamic>> getTemperature() async {
    try {
      print('🌡️ Fetching temperature...');

      final response = await http.get(
        Uri.parse(ApiConfig.esp32TemperatureEndpoint),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Get temperature value
        double temperature = 0.0;
        if (data['value'] != null) {
          if (data['value'] is num) {
            temperature = (data['value'] as num).toDouble();
          } else if (data['value'] is String) {
            temperature = double.tryParse(data['value']) ?? 0.0;
          }
        }

        print('✅ Temperature received: $temperature°C');
        return {
          'success': true,
          'temperature': temperature,
          'raw': data['raw'] ?? 0.0,
          'ambient': data['ambient'] ?? 0.0,
          'unit': '°C',
          'fever': temperature >= 37.5,
          'active': data['active'] ?? false,
          'ready': data['ready'] ?? false,
        };
      }

      print('❌ Temperature fetch failed');
      return {'success': false, 'temperature': 0.0};
    } catch (e) {
      print('❌ Temperature error: $e');
      return {'success': false, 'temperature': 0.0, 'message': '$e'};
    }
  }

  static Future<Map<String, dynamic>> getBloodPressure() async {
    try {
      print('🩺 Fetching blood pressure...');

      final response = await http.get(
        Uri.parse(ApiConfig.esp32BloodPressureEndpoint),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Blood pressure received: ${data['systolic']}/${data['diastolic']} mmHg');
        return {
          'success': true,
          ...data,
        };
      }

      print('❌ Blood pressure fetch failed');
      return {'success': false};
    } catch (e) {
      print('❌ Blood pressure error: $e');
      return {'success': false, 'message': '$e'};
    }
  }

  // ===== BP MEASUREMENT TRIGGER =====

  static Future<void> startBPMeasurement() async {
    try {
      print('🩺 Starting BP measurement...');

      await http.post(Uri.parse(ApiConfig.esp32StartBPEndpoint))
          .timeout(Duration(seconds: 3));

      print('✅ BP measurement triggered');
    } catch (e) {
      print('⚠️ BP measurement trigger failed: $e');
    }
  }

  // ===== WEIGHT SCALE CALIBRATION & TARE =====

  static Future<Map<String, dynamic>> tareWeightScale() async {
    try {
      print('⚖️ Taring weight scale...');

      final response = await http.post(
        Uri.parse(ApiConfig.esp32TareEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Scale tared successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Scale tared successfully',
          'data': data,
        };
      }

      print('❌ Scale tare failed');
      return {
        'success': false,
        'message': 'Failed to tare scale',
        'error': 'Status code: ${response.statusCode}',
      };
    } catch (e) {
      print('❌ Scale tare error: $e');
      return {
        'success': false,
        'message': 'Error connecting to scale',
        'error': e.toString(),
      };
    }
  }
}