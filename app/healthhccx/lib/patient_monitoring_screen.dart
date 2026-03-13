import 'package:flutter/material.dart';
import 'healthworker_dashboard.dart';
import 'parameter_measurement_screen.dart';
import 'api_service.dart';

class PatientMonitoringScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final String workerEmail;
  final VoidCallback onBack;

  const PatientMonitoringScreen({
    Key? key,
    required this.patient,
    required this.workerEmail,
    required this.onBack,
  }) : super(key: key);

  @override
  State<PatientMonitoringScreen> createState() =>
      _PatientMonitoringScreenState();
}

class _PatientMonitoringScreenState extends State<PatientMonitoringScreen> {
  Map<String, bool> savedParameters = {
    'bmi': false,
    'temperature': false,
    'vitals': false,
    'bp': false,
  };

  Map<String, Map<String, dynamic>> summaryResults = {};

  Map<String, String> parameterImages = {
    'bmi': 'assets/images/body-mass-index.png',
    'temperature': 'assets/images/body-temperature.png',
    'vitals': 'assets/images/oxygen-saturation.png',
    'bp': 'assets/images/blood-pressure.png',
  };

  // Medical Category Helpers
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
    if (bmi < 25) return Color(0xFF10B981);
    if (bmi < 30) return Color(0xFFF59E0B);
    if (bmi < 40) return Color(0xFFEF4444);
    return Color(0xFF7C2D12);
  }

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
    if (temp <= 37.5) return Color(0xFF10B981);
    if (temp <= 38.0) return Color(0xFFF59E0B);
    if (temp <= 39.0) return Color(0xFFEF4444);
    return Color(0xFF7C2D12);
  }

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
    if (hr <= 100) return Color(0xFF10B981);
    if (hr <= 120) return Color(0xFFF59E0B);
    return Color(0xFFEF4444);
  }

  String _getSpO2Status(int spo2) {
    if (spo2 < 90) return 'Hypoxemia (Medical Emergency)';
    if (spo2 <= 92) return 'Low (Seek Medical Advice)';
    if (spo2 <= 94) return 'Slightly Low (Monitor)';
    return 'Normal';
  }

  Color _getSpO2Color(int spo2) {
    if (spo2 < 90) return Color(0xFF7C2D12);
    if (spo2 <= 92) return Color(0xFFEF4444);
    if (spo2 <= 94) return Color(0xFFF59E0B);
    return Color(0xFF10B981);
  }

  String _getBloodPressureStatus(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) return 'Hypertensive Crisis';
    if (systolic >= 140 || diastolic >= 90) return 'Hypertension – Stage 2';
    if (systolic >= 130 || diastolic >= 80) return 'Hypertension – Stage 1';
    if (systolic >= 120 && diastolic < 80) return 'Elevated';
    return 'Normal';
  }

  Color _getBloodPressureColor(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) return Color(0xFF7C2D12);
    if (systolic >= 140 || diastolic >= 90) return Color(0xFFEF4444);
    if (systolic >= 130 || diastolic >= 80) return Color(0xFFF59E0B);
    if (systolic >= 120 && diastolic < 80) return Color(0xFF3B82F6);
    return Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patient['name'],
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.patient['email'],
              style: TextStyle(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Parameters',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: [
                      _buildParameterCard('Body Mass Index', 'assets/images/body-mass-index.png', 'bmi', Color(0xFF1848A0)),
                      _buildParameterCard('Temperature', 'assets/images/body-temperature.png', 'temperature', Color(0xFF1848A0)),
                      _buildParameterCard('Heart Rate & Oxygen Saturation', 'assets/images/oxygen-saturation.png', 'vitals', Color(0xFF1848A0)),
                      _buildParameterCard('Blood Pressure', 'assets/images/blood-pressure.png', 'bp', Color(0xFF1848A0)),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildBottomActions(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(String title, String imagePath, String key, Color color) {
    bool isSaved = savedParameters[key] ?? false;

    return GestureDetector(
      onTap: () => _showParameterModal(title, imagePath, color, key),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSaved
              ? LinearGradient(
            colors: [Color(0xFF1848A0), Color(0xFF2563C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSaved ? null : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFF1848A0).withOpacity(isSaved ? 1.0 : 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF1848A0).withOpacity(isSaved ? 0.4 : 0.15),
              blurRadius: isSaved ? 16 : 12,
              offset: Offset(0, isSaved ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSaved
                    ? AppColors.white.withOpacity(0.25)
                    : Color(0xFF1848A0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                imagePath,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                    color: isSaved ? AppColors.white : Color(0xFF1848A0),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSaved ? AppColors.white : AppColors.textDark,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showParameterModal(String title, String imagePath, Color color, String key) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ParameterMeasurementScreen(
          title: title.replaceAll('\n', ' '),
          icon: Icons.healing,
          color: color,
          paramKey: key,
          patientName: widget.patient['name'],
          onDataSaved: (data) {
            setState(() {
              savedParameters[key] = true;
              summaryResults[key] = data;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    int savedCount = savedParameters.values.where((saved) => saved).length;
    int totalCount = savedParameters.length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF1848A0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Color(0xFF1848A0).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFF1848A0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    savedCount == totalCount ? Icons.check_circle : Icons.info_outline,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  '$savedCount of $totalCount parameters recorded',
                  style: TextStyle(
                    color: Color(0xFF1848A0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _showSummaryModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1848A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Color(0xFF1848A0).withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.summarize, color: AppColors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'View Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSummaryModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _SummaryModalScreen(
          patient: widget.patient,
          savedParameters: savedParameters,
          summaryResults: summaryResults,
          onNavigateToMeasurement: _navigateToMeasurement,
          onSaveToDatabase: _saveAllToDatabase,
          getBMICategory: _getBMICategory,
          getBMICategoryColor: _getBMICategoryColor,
          getTemperatureStatus: _getTemperatureStatus,
          getTemperatureColor: _getTemperatureColor,
          getHeartRateStatus: _getHeartRateStatus,
          getHeartRateColor: _getHeartRateColor,
          getSpO2Status: _getSpO2Status,
          getSpO2Color: _getSpO2Color,
          getBloodPressureStatus: _getBloodPressureStatus,
          getBloodPressureColor: _getBloodPressureColor,
          parameterImages: parameterImages,
        ),
      ),
    );
  }

  void _navigateToMeasurement(String key, String title, IconData icon) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ParameterMeasurementScreen(
          title: title,
          icon: icon,
          color: Color(0xFF1848A0),
          paramKey: key,
          patientName: widget.patient['name'],
          onDataSaved: (data) {
            setState(() {
              savedParameters[key] = true;
              summaryResults[key] = data;
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveAllToDatabase() async {
    if (summaryResults.isEmpty) return;

    Map<String, dynamic> allData = {
      'worker_email': widget.workerEmail,
      'user_email': widget.patient['email'],
      'patient_name': widget.patient['name'],
      'timestamp': DateTime.now().toIso8601String(),
    };

    summaryResults.forEach((key, value) {
      allData.addAll(value);
    });

    final result = await ApiService.saveReading(allData);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('All data saved to ${widget.patient['name']}\'s account!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      setState(() {
        savedParameters = {'bmi': false, 'temperature': false, 'vitals': false, 'bp': false};
        summaryResults = {};
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.white),
              SizedBox(width: 12),
              Text('Failed to save data. Please try again.'),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// Separate Summary Modal Screen for cleaner code
class _SummaryModalScreen extends StatelessWidget {
  final Map<String, dynamic> patient;
  final Map<String, bool> savedParameters;
  final Map<String, Map<String, dynamic>> summaryResults;
  final Function(String, String, IconData) onNavigateToMeasurement;
  final Function() onSaveToDatabase;
  final Function(double) getBMICategory;
  final Function(double) getBMICategoryColor;
  final Function(double) getTemperatureStatus;
  final Function(double) getTemperatureColor;
  final Function(int) getHeartRateStatus;
  final Function(int) getHeartRateColor;
  final Function(int) getSpO2Status;
  final Function(int) getSpO2Color;
  final Function(int, int) getBloodPressureStatus;
  final Function(int, int) getBloodPressureColor;
  final Map<String, String> parameterImages;

  const _SummaryModalScreen({
    Key? key,
    required this.patient,
    required this.savedParameters,
    required this.summaryResults,
    required this.onNavigateToMeasurement,
    required this.onSaveToDatabase,
    required this.getBMICategory,
    required this.getBMICategoryColor,
    required this.getTemperatureStatus,
    required this.getTemperatureColor,
    required this.getHeartRateStatus,
    required this.getHeartRateColor,
    required this.getSpO2Status,
    required this.getSpO2Color,
    required this.getBloodPressureStatus,
    required this.getBloodPressureColor,
    required this.parameterImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Measurement Summary',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              patient['name'],
              style: TextStyle(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress Card
          Container(
            margin: EdgeInsets.all(20),
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
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.assessment_outlined, color: AppColors.white, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Measurement Progress',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${savedParameters.values.where((v) => v).length} of ${savedParameters.length} Completed',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${((savedParameters.values.where((v) => v).length / savedParameters.length) * 100).toInt()}%',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Parameters List
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSummaryCard(context, 'bmi', 'Body Mass Index', Icons.monitor_weight_outlined),
                  SizedBox(height: 12),
                  _buildSummaryCard(context, 'temperature', 'Temperature', Icons.thermostat_outlined),
                  SizedBox(height: 12),
                  _buildSummaryCard(context, 'vitals', 'Vital Signs', Icons.favorite_outline),
                  SizedBox(height: 12),
                  _buildSummaryCard(context, 'bp', 'Blood Pressure', Icons.monitor_heart_outlined),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: summaryResults.isEmpty
                      ? null
                      : () {
                    Navigator.pop(context);
                    onSaveToDatabase();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: summaryResults.isEmpty ? Colors.grey : AppColors.success,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: summaryResults.isEmpty ? 0 : 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        summaryResults.isEmpty ? Icons.lock_outline : Icons.save_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        summaryResults.isEmpty ? 'No Data to Save' : 'Save to Database',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String key, String title, IconData icon) {
    bool isMeasured = savedParameters[key] ?? false;
    Map<String, dynamic>? data = summaryResults[key];
    String imagePath = parameterImages[key] ?? 'assets/images/logo.png';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMeasured ? Color(0xFF1848A0).withOpacity(0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF1848A0).withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF1848A0).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(icon, color: Color(0xFF1848A0), size: 24),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (!isMeasured)
                      Row(
                        children: [
                          Icon(Icons.error_outline_sharp, size: 14, color: AppColors.textLight),
                          SizedBox(width: 4),
                          Text(
                            'Not Measured',
                            style: TextStyle(fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (isMeasured)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Measured',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onNavigateToMeasurement(key, title, icon);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1848A0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Measure Now',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (isMeasured && data != null) ...[
            SizedBox(height: 16),
            Divider(color: Color(0xFF1848A0).withOpacity(0.2)),
            SizedBox(height: 12),
            ...() {
              if (key == 'bmi') return _buildBMIData(data);
              if (key == 'temperature') return _buildTemperatureData(data);
              if (key == 'vitals') return _buildVitalsData(data);
              if (key == 'bp') return _buildBPData(data);
              return <Widget>[];
            }(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBMIData(Map<String, dynamic> data) {
    double weight = data['weight'] ?? 0.0;
    double height = data['height'] ?? 0.0;
    double bmi = data['bmi'] ?? 0.0;
    String category = getBMICategory(bmi) as String;
    Color categoryColor = getBMICategoryColor(bmi) as Color;

    return [
      _buildDataRow('Weight', '${weight.toStringAsFixed(2)} kg'),
      SizedBox(height: 8),
      _buildDataRow('Height', '${height.toStringAsFixed(1)} cm'),
      SizedBox(height: 8),
      _buildDataRow('BMI', bmi.toStringAsFixed(2)),
      SizedBox(height: 12),
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: categoryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: categoryColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.analytics, color: categoryColor, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildTemperatureData(Map<String, dynamic> data) {
    double temp = data['temperature'] ?? 0.0;
    String status = getTemperatureStatus(temp) as String;
    Color statusColor = getTemperatureColor(temp) as Color;

    return [
      _buildDataRow('Temperature', '${temp.toStringAsFixed(2)} °C'),
      SizedBox(height: 12),
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.thermostat, color: statusColor, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildVitalsData(Map<String, dynamic> data) {
    int heartRate = data['heart_rate'] ?? 0;
    int spo2 = data['spo2'] ?? 0;
    String hrStatus = getHeartRateStatus(heartRate) as String;
    Color hrColor = getHeartRateColor(heartRate) as Color;
    String spo2Status = getSpO2Status(spo2) as String;
    Color spo2Color = getSpO2Color(spo2) as Color;

    return [
      _buildDataRow('Heart Rate', '$heartRate bpm'),
      SizedBox(height: 8),
      _buildDataRow('SpO₂', '$spo2 %'),
      SizedBox(height: 12),
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hrColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hrColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite, color: hrColor, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heart Rate Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    hrStatus,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hrColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 10),
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: spo2Color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: spo2Color, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.air, color: spo2Color, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oxygen Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    spo2Status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: spo2Color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildBPData(Map<String, dynamic> data) {
    int systolic = data['systolic'] ?? 0;
    int diastolic = data['diastolic'] ?? 0;
    String status = getBloodPressureStatus(systolic, diastolic) as String;
    Color statusColor = getBloodPressureColor(systolic, diastolic) as Color;

    return [
      _buildDataRow('Systolic', '$systolic mmHg'),
      SizedBox(height: 8),
      _buildDataRow('Diastolic', '$diastolic mmHg'),
      SizedBox(height: 12),
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.monitor_heart, color: statusColor, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blood Pressure Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}