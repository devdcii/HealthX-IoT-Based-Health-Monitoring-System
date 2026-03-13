import 'package:flutter/material.dart';
import 'dart:async';
import 'healthworker_dashboard.dart';
import 'api_service.dart';

class ParameterMeasurementScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String paramKey;
  final String patientName;
  final Function(Map<String, dynamic>) onDataSaved;

  const ParameterMeasurementScreen({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.paramKey,
    required this.patientName,
    required this.onDataSaved,
  }) : super(key: key);

  @override
  State<ParameterMeasurementScreen> createState() =>
      _ParameterMeasurementScreenState();
}

class _ParameterMeasurementScreenState
    extends State<ParameterMeasurementScreen> with TickerProviderStateMixin {
  bool isStarted = false;
  bool isLoading = false;
  bool isSaved = false;
  bool showInstructions = true;
  Timer? _sensorTimer;
  Timer? _loadingTimer;
  Timer? _fingerCheckTimer;
  Map<String, dynamic> liveData = {};
  Map<String, dynamic> finalData = {};

  // ✅ NEW: Flag to track if we got final reading for non-live parameters
  bool hasFinalReading = false;

  // Loading progress variables
  double loadingProgress = 0.0;
  int loadingDuration = 3;
  bool isLoadingComplete = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Finger detection variables
  bool fingerDetected = false;
  String fingerStatusMessage = 'Checking...';

  Map<String, String> parameterImages = {
    'bmi': 'assets/images/body-mass-index.png',
    'height': 'assets/images/height.png',
    'weight': 'assets/images/weight.png',
    'temperature': 'assets/images/body-temperature.png',
    'heart_rate': 'assets/images/oxygen-saturation.png',
    'spo2': 'assets/images/oxygen-saturation.png',
    'bp': 'assets/images/blood-pressure.png',
    'vitals': 'assets/images/oxygen-saturation.png',
  };

  double _calculateBMI(double weight, double height) {
    if (weight <= 0 || height <= 0) return 0.0;
    return weight / ((height / 100.0) * (height / 100.0));
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog();
    });
  }

  @override
  void dispose() {
    _cleanupTimers();
    _progressController.dispose();
    ApiService.stopSensor();
    super.dispose();
  }

  void _cleanupTimers() {
    _sensorTimer?.cancel();
    _loadingTimer?.cancel();
    _fingerCheckTimer?.cancel();
    _sensorTimer = null;
    _loadingTimer = null;
    _fingerCheckTimer = null;
  }

  int _getLoadingDuration() {
    switch (widget.paramKey) {
      case 'bmi':
      case 'height':
      case 'weight':
      case 'temperature':
        return 3;
      case 'vitals':
      case 'heart_rate':
      case 'spo2':
        return 30;
      case 'bp':
        return 30;
      default:
        return 3;
    }
  }

  bool _shouldShowFingerDetection() {
    return widget.paramKey == 'vitals' ||
        widget.paramKey == 'heart_rate' ||
        widget.paramKey == 'spo2';
  }

  // ✅ NEW: Check if this parameter should have live reading
  bool _isLiveReadingParameter() {
    return widget.paramKey == 'bmi'; // Only BMI (height + weight) has live reading
  }

  void _showInstructionsDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _InstructionsDialog(
          paramKey: widget.paramKey,
          title: widget.title,
          color: widget.color,
          imagePath: parameterImages[widget.paramKey] ?? 'assets/images/oxygen-saturation.png',
          onComplete: () {
            Navigator.pop(context);
            setState(() => showInstructions = false);
          },
        ),
      ),
    );
  }

  void _startMeasurement() async {
    print('🚀 Starting measurement for ${widget.paramKey}');

    setState(() {
      isStarted = true;
      isLoading = true;
      loadingDuration = _getLoadingDuration();
      loadingProgress = 0.0;
      isLoadingComplete = false;
      fingerDetected = false;
      fingerStatusMessage = 'Checking...';
      hasFinalReading = false; // ✅ Reset final reading flag
      _initializeLiveData();
    });

    try {
      switch (widget.paramKey) {
        case 'bmi':
          print('⚖️ Starting WEIGHT sensor...');
          await ApiService.startWeightSensor();
          await Future.delayed(Duration(milliseconds: 800));
          print('📏 Starting HEIGHT sensor...');
          await ApiService.startHeightSensor();
          break;

        case 'temperature':
          print('🌡️ Starting TEMPERATURE sensor...');
          await ApiService.startTempSensor();
          break;

        case 'vitals':
          print('💓 Starting VITALS (HR/SpO2) sensor...');
          await ApiService.startHRSensor();
          break;

        case 'bp':
          print('🩺 Starting BLOOD PRESSURE sensor...');
          await ApiService.startBPSensor();
          await ApiService.startBPMeasurement();
          break;
      }

      await Future.delayed(Duration(milliseconds: 1000));
      _startLoadingProgress();

      if (_shouldShowFingerDetection()) {
        _startFingerDetectionCheck();
      }

      print('✅ All sensors started successfully');

    } catch (e) {
      print('❌ Error starting sensors: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start sensors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startFingerDetectionCheck() {
    _fingerCheckTimer?.cancel();

    _fingerCheckTimer = Timer.periodic(Duration(milliseconds: 800), (timer) async {
      if (!isLoading || !mounted) {
        timer.cancel();
        return;
      }

      try {
        final result = await ApiService.getHeartRate();

        if (result['success'] != false && mounted) {
          int irValue = result['irValue'] ?? 0;
          int hr = result['heartRate'] ?? 0;
          bool detected = false;
          String statusMsg = 'Checking...';

          if (irValue > 50000) {
            detected = true;
            if (hr > 0 && hr >= 40 && hr <= 180) {
              statusMsg = 'Finger detected - Reading...';
            } else {
              statusMsg = 'Finger detected - Stabilizing...';
            }
          } else {
            detected = false;
            statusMsg = 'No finger detected';
          }

          if (mounted && fingerDetected != detected) {
            setState(() {
              fingerDetected = detected;
              fingerStatusMessage = statusMsg;
            });
            print('🖐️ Finger detection: $detected (IR: $irValue, HR: $hr)');
          }
        }
      } catch (e) {
        print('⚠️ Finger detection error: $e');
      }
    });
  }

  void _initializeLiveData() {
    // ✅ CHANGED: Initialize with 0 instead of "--"
    switch (widget.paramKey) {
      case 'bmi':
        liveData = {
          'weight': 0.0,
          'height': 0.0,
          'bmi': 0.0,
        };
        break;
      case 'temperature':
        liveData = {
          'temperature': 0.0,
        };
        break;
      case 'vitals':
        liveData = {
          'heart_rate': 0,
          'spo2': 0,
        };
        break;
      case 'bp':
        liveData = {
          'systolic': 0,
          'diastolic': 0,
        };
        break;
    }
  }

  void _startLoadingProgress() {
    int elapsedSeconds = 0;
    loadingDuration = _getLoadingDuration();

    print('⏱️ Starting loading timer for $loadingDuration seconds');

    _loadingTimer?.cancel();

    _loadingTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      elapsedSeconds++;

      if (mounted) {
        setState(() {
          loadingProgress = elapsedSeconds / loadingDuration;
        });
      }

      print('⏱️ Loading: $elapsedSeconds / $loadingDuration seconds');

      if (elapsedSeconds >= loadingDuration) {
        timer.cancel();
        print('✅ Loading complete - starting realtime polling');

        if (mounted) {
          setState(() {
            isLoadingComplete = true;
            isLoading = false;
          });

          _startRealtimePolling();
        }
      }
    });
  }

  void _startRealtimePolling() {
    _sensorTimer?.cancel();

    _sensorTimer = Timer.periodic(Duration(milliseconds: 800), (timer) async {
      if (!mounted || !isStarted) {
        timer.cancel();
        return;
      }

      // ✅ NEW: Stop polling if we have final reading for non-live parameters
      if (!_isLiveReadingParameter() && hasFinalReading) {
        timer.cancel();
        print('✅ Final reading obtained, stopping polling for ${widget.paramKey}');
        return;
      }

      try {
        Map<String, dynamic> result;

        switch (widget.paramKey) {
          case 'bmi':
            final weightResult = await ApiService.getWeight();
            final heightResult = await ApiService.getHeight();

            result = {
              'success': true,
              'weight': weightResult,
              'height': heightResult,
            };
            break;

          case 'temperature':
            result = await ApiService.getTemperature();
            if (result['success'] != false) {
              result = {
                'success': true,
                'temperature': {
                  'value': result['temperature'] ?? 0.0,
                  'raw': result['raw'] ?? 0.0,
                  'ambient': result['ambient'] ?? 0.0,
                }
              };
            }
            break;

          case 'vitals':
            final hrResult = await ApiService.getHeartRate();
            final spo2Result = await ApiService.getSpO2();

            result = {
              'success': true,
              'heartRate': {
                'value': hrResult['heartRate'] ?? 0,
                'irValue': hrResult['irValue'] ?? 0,
                'fingerDetected': hrResult['fingerDetected'] ?? false,
              },
              'spo2': {
                'value': spo2Result['spo2'] ?? 0,
                'valid': spo2Result['valid'] ?? false,
              },
              'fingerDetected': hrResult['fingerDetected'] ?? false,
              'irValue': hrResult['irValue'] ?? 0,
            };
            break;

          case 'bp':
            result = await ApiService.getBloodPressure();
            if (result['success'] != false) {
              result = {
                'success': true,
                'bloodPressure': {
                  'systolic': result['systolic'] ?? 0,
                  'diastolic': result['diastolic'] ?? 0,
                }
              };
            }
            break;

          default:
            result = {'success': false};
        }

        if (result['success'] != false && mounted) {
          _updateLiveData(result);
        } else if (mounted) {
          print('⚠️ API call failed for ${widget.paramKey}');
        }
      } catch (e) {
        print('❌ Error in realtime polling: $e');
      }
    });
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  void _updateLiveData(Map<String, dynamic> espData) {
    print('📡 Updating live data for ${widget.paramKey}');
    print('📊 ESP Data received: $espData');

    switch (widget.paramKey) {
      case 'bmi':
      // ✅ SIMPLE LIVE READING (no anti-flicker)
        double weight = 0.0;
        double height = 0.0;
        double bmiValue = 0.0;

        // Extract weight
        if (espData['weight'] != null) {
          if (espData['weight'] is Map<String, dynamic>) {
            if (espData['weight']['weight'] != null) {
              weight = _parseDouble(espData['weight']['weight']);
            } else if (espData['weight']['value'] != null) {
              weight = _parseDouble(espData['weight']['value']);
            }
          } else if (espData['weight'] is num) {
            weight = espData['weight'].toDouble();
          }
        }

        // Extract height
        if (espData['height'] != null) {
          if (espData['height'] is Map<String, dynamic>) {
            height = _parseDouble(espData['height']['height'] ?? espData['height']['value']);
          } else {
            height = _parseDouble(espData['height']);
          }
        }

        // Calculate BMI if we have valid data
        if (weight > 0 && height > 0) {
          bmiValue = weight / ((height / 100.0) * (height / 100.0));
          print('📊 BMI Calculated: weight=$weight, height=$height, bmi=$bmiValue');
        }

        // Update display
        if (mounted) {
          setState(() {
            liveData = {
              'weight': weight,
              'height': height,
              'bmi': bmiValue,
            };
          });
        }
        break;

      case 'temperature':
      // ✅ SINGLE SHOT: Get one valid reading then stop
        double temp = 0.0;
        if (espData['temperature']?['value'] != null) {
          temp = _parseDouble(espData['temperature']['value']);
        }

        if (temp > 0 && !hasFinalReading) {
          if (mounted) {
            setState(() {
              liveData = {'temperature': temp};
              hasFinalReading = true; // ✅ Mark as final
            });
          }
          print('🌡️ Temperature Final Reading: $temp');
        }
        break;

      case 'vitals':
      // ✅ SINGLE SHOT: Get one valid reading then stop
        int hr = 0;
        int spo2Val = 0;
        int irVal = 0;
        bool fingerDet = false;

        if (espData['heartRate']?['value'] != null) {
          hr = _parseDouble(espData['heartRate']['value']).toInt();
        }

        if (espData['spo2']?['value'] != null) {
          spo2Val = _parseDouble(espData['spo2']['value']).toInt();
        }

        if (espData['heartRate']?['irValue'] != null) {
          irVal = _parseDouble(espData['heartRate']['irValue']).toInt();
        }

        fingerDet = espData['fingerDetected'] ?? (irVal > 50000);

        // Update finger detection regardless
        if (mounted) {
          setState(() {
            fingerDetected = fingerDet;
            if (fingerDet) {
              if (hr > 0 && hr >= 40 && hr <= 180) {
                fingerStatusMessage = 'Finger detected - Reading...';
              } else {
                fingerStatusMessage = 'Finger detected - Stabilizing...';
              }
            } else {
              fingerStatusMessage = 'No finger detected';
            }
          });
        }

        // Only update data if we have valid readings and haven't locked yet
        if (hr >= 40 && hr <= 180 && spo2Val >= 70 && spo2Val <= 100 && !hasFinalReading) {
          if (mounted) {
            setState(() {
              liveData = {
                'heart_rate': hr,
                'spo2': spo2Val,
              };
              hasFinalReading = true; // ✅ Mark as final
            });
          }
          print('💓 Vitals Final Reading: HR=$hr, SpO2=$spo2Val');
        }
        break;

      case 'bp':
      // ✅ SINGLE SHOT: Get one valid reading then stop
        int sys = 0;
        int dia = 0;

        if (espData['bloodPressure']?['systolic'] != null) {
          sys = _parseDouble(espData['bloodPressure']['systolic']).toInt();
        }

        if (espData['bloodPressure']?['diastolic'] != null) {
          dia = _parseDouble(espData['bloodPressure']['diastolic']).toInt();
        }

        if (sys > 0 && dia > 0 && !hasFinalReading) {
          if (mounted) {
            setState(() {
              liveData = {
                'systolic': sys,
                'diastolic': dia,
              };
              hasFinalReading = true; // ✅ Mark as final
            });
          }
          print('🩺 BP Final Reading: $sys/$dia');
        }
        break;
    }
  }

  Future<void> _resetMeasurement() async {
    print('🔄 Resetting measurement...');

    _cleanupTimers();

    try {
      await ApiService.stopSensor();
      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print('⚠️ Error stopping sensors: $e');
    }

    if (mounted) {
      setState(() {
        isStarted = false;
        isLoading = false;
        isSaved = false;
        liveData = {};
        finalData = {};
        loadingProgress = 0.0;
        isLoadingComplete = false;
        fingerDetected = false;
        fingerStatusMessage = 'Checking...';
        hasFinalReading = false; // ✅ Reset final reading flag
      });
    }

    _progressController.reset();
    print('✅ Measurement reset complete');
  }

  Future<void> _tareScale() async {
    try {
      await ApiService.tareWeightScale();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Scale tared successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to tare scale: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _saveData() {
    if (liveData.isEmpty) return;

    // Check if data is still placeholder (0)
    bool hasValidData = false;
    liveData.forEach((key, value) {
      if (value != 0 && value != 0.0) {
        hasValidData = true;
      }
    });

    if (!hasValidData) return;

    setState(() {
      finalData = Map.from(liveData);
      isSaved = true;
    });
    widget.onDataSaved(finalData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('${widget.title} data saved!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // BMI Category - Medical Standard
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal (Healthy Weight)';
    if (bmi < 30) return 'Overweight';
    if (bmi < 35) return 'Obesity Class I';
    if (bmi < 40) return 'Obesity Class II';
    return 'Obesity Class III (Severe / Morbid Obesity)';
  }

  Color _getBMICategoryColor(double bmi) {
    if (bmi < 18.5) return Color(0xFF3B82F6);
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Color(0xFFF59E0B);
    if (bmi < 40) return Colors.red;
    return Color(0xFF7C2D12);
  }

  // Temperature Status - Medical Standard
  String _getTemperatureStatus(double temp) {
    if (temp < 35.0) return 'Hypothermia (Medical Concern)';
    if (temp < 36.5) return 'Slightly Low';
    if (temp <= 37.5) return 'Normal';
    if (temp <= 38.0) return 'Low-grade Fever';
    if (temp <= 39.0) return 'Fever';
    return 'High Fever (Seek Medical Attention)';
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 35.0) return Color(0xFF3B82F6);
    if (temp < 36.5) return Color(0xFF60A5FA);
    if (temp <= 37.5) return Colors.green;
    if (temp <= 38.0) return Color(0xFFF59E0B);
    if (temp <= 39.0) return Colors.red;
    return Color(0xFF7C2D12);
  }

  // Heart Rate Status - Medical Standard
  String _getHeartRateStatus(int hr) {
    if (hr < 50) return 'Bradycardia (Low Heart Rate)';
    if (hr < 60) return 'Low (Can be Normal for Athletes)';
    if (hr <= 100) return 'Normal';
    if (hr <= 120) return 'Elevated';
    return 'Tachycardia (High Heart Rate)';
  }

  Color _getHeartRateColor(int hr) {
    if (hr < 50) return Color(0xFF3B82F6);
    if (hr < 60) return Color(0xFF60A5FA);
    if (hr <= 100) return Colors.green;
    if (hr <= 120) return Color(0xFFF59E0B);
    return Colors.red;
  }

  // SpO2 Status - Medical Standard
  String _getSpO2Status(int spo2) {
    if (spo2 < 90) return 'Hypoxemia (Medical Emergency)';
    if (spo2 <= 92) return 'Low (Seek Medical Advice)';
    if (spo2 <= 94) return 'Slightly Low (Monitor)';
    return 'Normal';
  }

  Color _getSpO2Color(int spo2) {
    if (spo2 < 90) return Color(0xFF7C2D12);
    if (spo2 <= 92) return Colors.red;
    if (spo2 <= 94) return Color(0xFFF59E0B);
    return Colors.green;
  }

  // Blood Pressure Status - Medical Standard
  String _getBloodPressureStatus(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) return 'Hypertensive Crisis';
    if (systolic >= 140 || diastolic >= 90) return 'Hypertension – Stage 2';
    if (systolic >= 130 || diastolic >= 80) return 'Hypertension – Stage 1';
    if (systolic >= 120 && diastolic < 80) return 'Elevated';
    return 'Normal';
  }

  Color _getBloodPressureColor(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) return Color(0xFF7C2D12);
    if (systolic >= 140 || diastolic >= 90) return Colors.red;
    if (systolic >= 130 || diastolic >= 80) return Color(0xFFF59E0B);
    if (systolic >= 120 && diastolic < 80) return Color(0xFF3B82F6);
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () async {
            try {
              _cleanupTimers();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1848A0)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Stopping sensors...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              await ApiService.stopAllSensors();
              await Future.delayed(Duration(milliseconds: 300));

              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            } catch (e) {
              print('⚠️ Failed to stop sensors: $e');
              if (mounted) {
                try {
                  Navigator.pop(context);
                } catch (_) {}
                Navigator.pop(context);
              }
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                parameterImages[widget.paramKey] ?? 'assets/images/oxygen-saturation.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(widget.icon, color: Colors.white, size: 24),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'View Instructions',
            onPressed: _showInstructionsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1848A0), Color(0xFF2563C9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF1848A0).withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patient',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                widget.patientName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  if (isStarted) _buildMeasurementDisplay(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildMeasurementDisplay() {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF1848A0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1848A0).withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sensors, color: Colors.green, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensor Connected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      // ✅ Show different text based on live vs final
                      _isLiveReadingParameter() ? 'Live Reading' : 'Final Reading',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (widget.paramKey == 'bmi') ..._buildBMIDisplay(),
          if (widget.paramKey == 'temperature') ..._buildTemperatureDisplay(),
          if (widget.paramKey == 'vitals') ..._buildVitalsDisplay(),
          if (widget.paramKey == 'bp') ..._buildBPDisplay(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF1848A0).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1848A0).withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 1500),
            builder: (context, double value, child) => Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1848A0).withOpacity(0.1),
                      Color(0xFF1848A0).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF1848A0).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  parameterImages[widget.paramKey] ?? 'assets/images/oxygen-saturation.png',
                  width: 90,
                  height: 90,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.sensors, size: 90, color: Color(0xFF1848A0)),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
          Text(
            'Measuring ${widget.title}',
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF1848A0),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please remain still...',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_shouldShowFingerDetection()) ...[
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: fingerDetected
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: fingerDetected
                      ? Colors.green
                      : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    fingerDetected ? Icons.fingerprint : Icons.touch_app,
                    color: fingerDetected
                        ? Colors.green
                        : Colors.red,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      fingerStatusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: fingerDetected
                            ? Colors.green
                            : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 32),
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0xFF1848A0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 100),
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.7 * loadingProgress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1848A0),
                          Color(0xFF2563C9),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF1848A0).withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(loadingProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1848A0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(loadingDuration * (1 - loadingProgress)).toInt()}s remaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
                  (index) => TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 600),
                builder: (context, double value, child) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(0xFF1848A0).withOpacity(
                        0.3 + ((loadingProgress * 10).toInt() % 3 == index ? 0.7 : 0),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBMIDisplay() {
    final weight = liveData['weight'];
    final height = liveData['height'];
    final bmi = liveData['bmi'];

    String weightDisplay = _parseDouble(weight).toStringAsFixed(2);
    String heightDisplay = _parseDouble(height).toStringAsFixed(1);
    String bmiDisplay = _parseDouble(bmi) > 0 ? _parseDouble(bmi).toStringAsFixed(2) : '0.00';

    return [
      _buildDataRow(
        'Weight',
        weightDisplay,
        'kg',
        'assets/images/weight.png',
      ),
      Container(
        margin: EdgeInsets.only(bottom: 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _tareScale,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFF1848A0), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: Color(0xFF1848A0), size: 20),
                SizedBox(width: 8),
                Text(
                  'Tare Scale',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1848A0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      _buildDataRow(
        'Height',
        heightDisplay,
        'cm',
        'assets/images/height.png',
      ),
      _buildDataRow(
        'BMI',
        bmiDisplay,
        '',
        'assets/images/body-mass-index.png',
      ),
      if (_parseDouble(bmi) > 0) ...[
        SizedBox(height: 8),
        _buildStatusIndicator(
          'BMI Category',
          _getBMICategory(_parseDouble(bmi)),
          _getBMICategoryColor(_parseDouble(bmi)),
          Icons.analytics,
        ),
      ],
    ];
  }

  List<Widget> _buildTemperatureDisplay() {
    final temp = liveData['temperature'];
    String tempDisplay = _parseDouble(temp).toStringAsFixed(2);

    return [
      _buildDataRow(
        'Temperature',
        tempDisplay,
        '°C',
        'assets/images/body-temperature.png',
      ),
      if (_parseDouble(temp) > 0) ...[
        SizedBox(height: 8),
        _buildStatusIndicator(
          'Temperature Status',
          _getTemperatureStatus(_parseDouble(temp)),
          _getTemperatureColor(_parseDouble(temp)),
          Icons.thermostat,
        ),
      ],
    ];
  }

  List<Widget> _buildVitalsDisplay() {
    final hr = liveData['heart_rate'];
    final spo2 = liveData['spo2'];

    String hrDisplay = _parseDouble(hr).toInt().toString();
    String spo2Display = _parseDouble(spo2).toInt().toString();

    return [
      _buildDataRow(
        'Heart Rate',
        hrDisplay,
        'bpm',
        'assets/images/oxygen-saturation.png',
      ),
      _buildDataRow(
        'SpO₂',
        spo2Display,
        '%',
        'assets/images/oxygen-saturation.png',
      ),
      if (_parseDouble(hr) > 0 || _parseDouble(spo2) > 0) ...[
        SizedBox(height: 8),
        if (_parseDouble(hr) > 0)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: _buildStatusIndicator(
              'Heart Rate Status',
              _getHeartRateStatus(_parseDouble(hr).toInt()),
              _getHeartRateColor(_parseDouble(hr).toInt()),
              Icons.favorite,
            ),
          ),
        if (_parseDouble(spo2) > 0)
          _buildStatusIndicator(
            'Oxygen Status',
            _getSpO2Status(_parseDouble(spo2).toInt()),
            _getSpO2Color(_parseDouble(spo2).toInt()),
            Icons.air,
          ),
      ],
    ];
  }

  List<Widget> _buildBPDisplay() {
    final systolic = liveData['systolic'];
    final diastolic = liveData['diastolic'];

    String sysDisplay = _parseDouble(systolic).toInt().toString();
    String diaDisplay = _parseDouble(diastolic).toInt().toString();

    return [
      _buildDataRow(
        'Systolic',
        sysDisplay,
        'mmHg',
        'assets/images/blood-pressure.png',
      ),
      _buildDataRow(
        'Diastolic',
        diaDisplay,
        'mmHg',
        'assets/images/blood-pressure.png',
      ),
      if (_parseDouble(systolic) > 0 && _parseDouble(diastolic) > 0) ...[
        SizedBox(height: 8),
        _buildStatusIndicator(
          'Blood Pressure Status',
          _getBloodPressureStatus(_parseDouble(systolic).toInt(), _parseDouble(diastolic).toInt()),
          _getBloodPressureColor(_parseDouble(systolic).toInt(), _parseDouble(diastolic).toInt()),
          Icons.monitor_heart,
        ),
      ],
    ];
  }

  Widget _buildDataRow(String label, String value, String unit, String imagePath) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5F7FA),
            Color(0xFF1848A0).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF1848A0).withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1848A0),
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF1848A0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              imagePath,
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.healing, color: Color(0xFF1848A0), size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String status, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isStarted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1848A0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Color(0xFF1848A0).withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Start Measurement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Container(
                    constraints: BoxConstraints(
                      minWidth: 0,
                      maxWidth: MediaQuery.of(context).size.width * 0.35,
                    ),
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : _resetMeasurement,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isLoading
                                ? Colors.grey[400]!
                                : Color(0xFF1848A0),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Icon(
                                Icons.refresh,
                                color: isLoading
                                    ? Colors.grey[400]
                                    : Color(0xFF1848A0),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isLoading
                                      ? Colors.grey[400]
                                      : Color(0xFF1848A0),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: !isLoading && liveData.isNotEmpty && !isSaved
                            ? _saveData
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSaved ? Colors.grey[400]! : Colors.green,
                          disabledBackgroundColor: Colors.grey[400]!,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: isSaved ? 0 : 4,
                          shadowColor: Colors.green.withOpacity(0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSaved ? Icons.check_circle : Icons.save,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isSaved ? 'Saved' : 'Save Data',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Instructions Dialog (no changes needed)
class _InstructionsDialog extends StatefulWidget {
  final String paramKey;
  final String title;
  final Color color;
  final String imagePath;
  final VoidCallback onComplete;

  const _InstructionsDialog({
    Key? key,
    required this.paramKey,
    required this.title,
    required this.color,
    required this.imagePath,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<_InstructionsDialog> createState() => _InstructionsDialogState();
}

class _InstructionsDialogState extends State<_InstructionsDialog> {
  int currentStep = 0;
  late List<InstructionStep> steps;

  @override
  void initState() {
    super.initState();
    steps = _getInstructions(widget.paramKey);
  }

  List<InstructionStep> _getInstructions(String paramKey) {
    Map<String, List<InstructionStep>> instructionsMap = {
      'bmi': [
        InstructionStep(
          title: 'Prepare the Scale',
          description: 'Ensure the scale is placed on a flat, stable surface.',
          icon: Icons.info_outline,
          color: Color(0xFF1848A0),
        ),
        InstructionStep(
          title: 'Remove Heavy Items',
          description: 'Ask the patient to remove shoes and heavy clothing for accurate weight measurement.',
          icon: Icons.accessibility_new,
          color: Colors.green,
        ),
        InstructionStep(
          title: 'Position Correctly',
          description: 'Patient should stand straight under the height sensor with feet together.',
          icon: Icons.straighten,
          color: Color(0xFFF59E0B),
        ),
        InstructionStep(
          title: 'Wait for Reading',
          description: 'Keep body still until you get a stable reading on the display.',
          icon: Icons.timer,
          color: Color(0xFF8B5CF6),
        ),
      ],
      'temperature': [
        InstructionStep(
          title: 'Clean the Sensor',
          description: 'Wipe the temperature sensor with a clean, dry cloth before use.',
          icon: Icons.cleaning_services,
          color: Color(0xFF1848A0),
        ),
        InstructionStep(
          title: 'Position Sensor',
          description: 'Hold the sensor 2-3 cm away from the center of the patient\'s forehead.',
          icon: Icons.location_on,
          color: Colors.green,
        ),
        InstructionStep(
          title: 'Keep Steady',
          description: 'Hold the sensor steady and press the measurement button.',
          icon: Icons.pan_tool,
          color: Color(0xFFF59E0B),
        ),
        InstructionStep(
          title: 'Wait for Beep',
          description: 'Wait for the device to beep indicating measurement is complete.',
          icon: Icons.notifications_active,
          color: Color(0xFF8B5CF6),
        ),
      ],
      'vitals': [
        InstructionStep(
          title: 'Patient Preparation',
          description: 'Ask the patient to sit comfortably and relax for a few minutes.',
          icon: Icons.event_seat,
          color: Color(0xFF1848A0),
        ),
        InstructionStep(
          title: 'Insert Finger',
          description: 'Have the patient place their index finger firmly into the pulse oximeter.',
          icon: Icons.touch_app,
          color: Colors.green,
        ),
        InstructionStep(
          title: 'Stay Still',
          description: 'Patient should keep their finger still and breathe normally during measurement.',
          icon: Icons.self_improvement,
          color: Color(0xFFF59E0B),
        ),
        InstructionStep(
          title: 'Wait for Results',
          description: 'The device will take about 30 seconds to display accurate heart rate and SpO2.',
          icon: Icons.favorite,
          color: Colors.red,
        ),
      ],
      'bp': [
        InstructionStep(
          title: 'Rest Period',
          description: 'Have the patient sit quietly and relax for 5 minutes before measurement.',
          icon: Icons.timer,
          color: Color(0xFF1848A0),
        ),
        InstructionStep(
          title: 'Apply Cuff',
          description: 'Wrap the cuff snugly around the patient\'s wrist, about 1 cm from the hand.',
          icon: Icons.watch,
          color: Colors.green,
        ),
        InstructionStep(
          title: 'Position Wrist',
          description: 'Keep the wrist at heart level, palm facing up.',
          icon: Icons.favorite,
          color: Color(0xFFF59E0B),
        ),
        InstructionStep(
          title: 'Start Measurement',
          description: 'Press start and remain still during inflation and deflation of the cuff.',
          icon: Icons.play_circle,
          color: Color(0xFF8B5CF6),
        ),
      ],
    };
    return instructionsMap[paramKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete();
      });
      return SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black87),
          onPressed: () => widget.onComplete(),
        ),
        title: Row(
          children: [
            Image.asset(
              widget.imagePath,
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.healing, color: Color(0xFF1848A0), size: 32);
              },
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    steps.length,
                        (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: currentStep == index ? 32 : 8,
                      decoration: BoxDecoration(
                        color: currentStep == index
                            ? Color(0xFF1848A0)
                            : Color(0xFF1848A0).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Step ${currentStep + 1} of ${steps.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: steps[currentStep].color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      steps[currentStep].icon,
                      size: 60,
                      color: steps[currentStep].color,
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    steps[currentStep].title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    steps[currentStep].description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Color(0xFF1848A0), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(
                          color: Color(0xFF1848A0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (currentStep > 0) SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentStep < steps.length - 1) {
                        setState(() {
                          currentStep++;
                        });
                      } else {
                        widget.onComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1848A0),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      currentStep < steps.length - 1 ? 'Next' : 'Start Measurement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class InstructionStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  InstructionStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}