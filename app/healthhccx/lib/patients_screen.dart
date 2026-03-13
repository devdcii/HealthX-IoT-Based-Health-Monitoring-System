import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'healthworker_dashboard.dart';
import 'api_service.dart';
import 'parameter_measurement_screen.dart';
import 'esp32_connection_service.dart';

class PatientsScreen extends StatefulWidget {
  final String workerEmail;

  const PatientsScreen({Key? key, required this.workerEmail}) : super(key: key);

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final Esp32ConnectionService _esp32Service = Esp32ConnectionService();
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? selectedPatient;
  bool isLoading = true;

  // Image paths for parameters
  Map<String, String> parameterImages = {
    'bmi': 'assets/images/body-mass-index.png',
    'height': 'assets/images/height.png',
    'weight': 'assets/images/weight.png',
    'temperature': 'assets/images/body-temperature.png',
    'heart_rate': 'assets/images/oxygen-saturation.png',
    'spo2': 'assets/images/oxygen-saturation.png',
    'bp': 'assets/images/blood-pressure.png',
  };

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => isLoading = true);
    final result = await ApiService.getPatients();
    if (result['success']) {
      setState(() {
        patients = List<Map<String, dynamic>>.from(result['patients']);
        filteredPatients = patients;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPatients = patients;
      } else {
        filteredPatients = patients.where((patient) {
          final name = patient['name'].toString().toLowerCase();
          final email = patient['email'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || email.contains(searchLower);
        }).toList();
      }
    });
  }

  // Health parameter categorization functions
  Map<String, dynamic> _categorizeBMI(double bmi) {
    if (bmi < 18.5) {
      return {
        'category': 'Underweight',
        'color': Color(0xFFF59E0B),
        'severity': 'warning'
      };
    } else if (bmi >= 18.5 && bmi < 25.0) {
      return {
        'category': 'Normal',
        'color': Color(0xFF10B981),
        'severity': 'normal'
      };
    } else if (bmi >= 25.0 && bmi < 30.0) {
      return {
        'category': 'Overweight',
        'color': Color(0xFFF59E0B),
        'severity': 'warning'
      };
    } else if (bmi >= 30.0 && bmi < 35.0) {
      return {
        'category': 'Obesity Class I',
        'color': Color(0xFFEF4444),
        'severity': 'alert'
      };
    } else if (bmi >= 35.0 && bmi < 40.0) {
      return {
        'category': 'Obesity Class II',
        'color': Color(0xFFDC2626),
        'severity': 'critical'
      };
    } else {
      return {
        'category': 'Obesity Class III',
        'color': Color(0xFF991B1B),
        'severity': 'critical'
      };
    }
  }

  Map<String, dynamic> _categorizeTemperature(double temp) {
    if (temp < 35.0) {
      return {
        'category': 'Hypothermia',
        'color': Color(0xFF991B1B),
        'severity': 'critical'
      };
    } else if (temp >= 35.5 && temp < 36.5) {
      return {
        'category': 'Slightly Low',
        'color': Color(0xFF3B82F6),
        'severity': 'info'
      };
    } else if (temp >= 36.5 && temp <= 37.5) {
      return {
        'category': 'Normal',
        'color': Color(0xFF10B981),
        'severity': 'normal'
      };
    } else if (temp > 37.5 && temp <= 38.0) {
      return {
        'category': 'Low-grade Fever',
        'color': Color(0xFFF59E0B),
        'severity': 'warning'
      };
    } else if (temp > 38.0 && temp <= 39.0) {
      return {
        'category': 'Fever',
        'color': Color(0xFFEF4444),
        'severity': 'alert'
      };
    } else {
      return {
        'category': 'High Fever',
        'color': Color(0xFF991B1B),
        'severity': 'critical'
      };
    }
  }

  Map<String, dynamic> _categorizeHeartRate(int hr) {
    if (hr < 50) {
      return {
        'category': 'Bradycardia',
        'color': Color(0xFFEF4444),
        'severity': 'alert'
      };
    } else if (hr >= 50 && hr < 60) {
      return {
        'category': 'Low',
        'color': Color(0xFF3B82F6),
        'severity': 'info'
      };
    } else if (hr >= 60 && hr <= 100) {
      return {
        'category': 'Normal',
        'color': Color(0xFF10B981),
        'severity': 'normal'
      };
    } else if (hr > 100 && hr <= 120) {
      return {
        'category': 'Elevated',
        'color': Color(0xFFF59E0B),
        'severity': 'warning'
      };
    } else {
      return {
        'category': 'Tachycardia',
        'color': Color(0xFFEF4444),
        'severity': 'alert'
      };
    }
  }

  Map<String, dynamic> _categorizeSpO2(int spo2) {
    if (spo2 < 90) {
      return {
        'category': 'Hypoxemia',
        'color': Color(0xFF991B1B),
        'severity': 'critical'
      };
    } else if (spo2 >= 90 && spo2 <= 92) {
      return {
        'category': 'Low',
        'color': Color(0xFFEF4444),
        'severity': 'alert'
      };
    } else if (spo2 >= 93 && spo2 <= 94) {
      return {
        'category': 'Slightly Low',
        'color': Color(0xFFF59E0B),
        'severity': 'warning'
      };
    } else {
      return {
        'category': 'Normal',
        'color': Color(0xFF10B981),
        'severity': 'normal'
      };
    }
  }

  Map<String, dynamic> _categorizeBloodPressure(int systolic, int diastolic) {
    if (systolic > 180 || diastolic > 120) {
      return {
        'category': 'Hypertensive Crisis',
        'color': Color(0xFF991B1B),
        'severity': 'critical'
      };
    } else if (systolic >= 140 || diastolic >= 90) {
      return {
        'category': 'Hypertension Stage 2',
        'color': Color(0xFFEF4444),
        'severity': 'alert'
      };
    } else if ((systolic >= 130 && systolic < 140) ||
        (diastolic >= 80 && diastolic < 90)) {
      return {
        'category': 'Hypertension Stage 1',
        'color': Color(0xFFF59E0B),
        'severity': 'warning'
      };
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      return {
        'category': 'Elevated',
        'color': Color(0xFF3B82F6),
        'severity': 'info'
      };
    } else {
      return {
        'category': 'Normal',
        'color': Color(0xFF10B981),
        'severity': 'normal'
      };
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          selectedPatient == null ? 'Patients' : 'Patient Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: selectedPatient != null
            ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => selectedPatient = null);
          },
        )
            : null,
        // ✅ ADD THIS actions array:
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _esp32Service.isConnected,
            builder: (context, isConnected, child) {
              return Container(
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
              );
            },
          ),
        ],
      ),
      body: selectedPatient == null
          ? _buildPatientsList()
          : _buildPatientRecords(),
    );
  }

  Widget _buildPatientsList() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: EdgeInsets.all(20),
          color: AppColors.white,
          child: TextField(
            controller: searchController,
            onChanged: _filterPatients,
            decoration: InputDecoration(
              hintText: 'Search patients by name or email...',
              hintStyle: TextStyle(color: AppColors.textLight),
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: AppColors.textLight),
                onPressed: () {
                  searchController.clear();
                  _filterPatients('');
                },
              )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
        // Dashboard Header - Total Patients
        Center(
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width * 0.5,
            margin: EdgeInsets.only(top: 16, bottom: 16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  color: AppColors.white,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  '${patients.length} Patients',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Patient List
        Expanded(
          child: isLoading
              ? Center(
              child: CircularProgressIndicator(color: AppColors.primary))
              : filteredPatients.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: AppColors.textLight,
                ),
                SizedBox(height: 16),
                Text(
                  'No patients found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _fetchPatients,
            color: AppColors.primary,
            child: ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = filteredPatients[index];
                return _buildPatientCard(patient);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Dismissible(
      key: Key(patient['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) =>
              AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error),
                    SizedBox(width: 12),
                    Text(
                      'Delete Patient',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                content: Text(
                  'Are you sure you want to delete ${patient['name']}? This will remove all their health records permanently.',
                  style: TextStyle(color: Colors.black87),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                        'Cancel', style: TextStyle(color: AppColors.textLight)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                        'Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) async {
        final result = await ApiService.deletePatient(patient['id']);

        if (result['success']) {
          setState(() {
            patients.removeWhere((p) => p['id'] == patient['id']);
            filteredPatients.removeWhere((p) => p['id'] == patient['id']);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${patient['name']} deleted successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          await _fetchPatients();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${result['message']}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () {
          setState(() => selectedPatient = patient);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 28,
                child: Text(
                  patient['name'][0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      patient['email'],
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientRecords() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPatientReadings(selectedPatient!['email']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  size: 80,
                  color: AppColors.textLight,
                ),
                SizedBox(height: 16),
                Text(
                  'No health records found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'for ${selectedPatient!['name']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        final readings = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: readings.length,
          itemBuilder: (context, index) {
            return _buildReadingCard(readings[index]);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPatientReadings(
      String userEmail,) async {
    final result = await ApiService.getReadings(userEmail);
    if (result['success']) {
      return List<Map<String, dynamic>>.from(result['readings']);
    }
    return [];
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                      Icons.calendar_today, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(
                      DateTime.parse(reading['timestamp']),
                    ),
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                        Icons.refresh, color: AppColors.primary, size: 20),
                    onPressed: () => _showRetakeDialog(reading),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    tooltip: 'Retake measurements',
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.error, size: 20),
                    onPressed: () => _showDeleteDialog(reading),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          // First Row - Height, Weight, BMI
          if (reading['height'] != null || reading['weight'] != null ||
              reading['bmi'] != null)
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                if (reading['height'] != null)
                  _buildMetric(
                      'Height', '${reading['height']} cm', 'height', null),
                if (reading['weight'] != null)
                  _buildMetric(
                      'Weight', '${reading['weight']} kg', 'weight', null),
                if (reading['bmi'] != null)
                  _buildMetric(
                    'BMI',
                    reading['bmi'].toString(),
                    'bmi',
                    _categorizeBMI(double.parse(reading['bmi'].toString())),
                  ),
              ],
            ),

          // Second Row - Heart Rate, SpO2, Temperature
          if (reading['heart_rate'] != null || reading['spo2'] != null ||
              reading['temperature'] != null) ...[
            SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                if (reading['heart_rate'] != null)
                  _buildMetric(
                    'Heart Rate',
                    '${reading['heart_rate']} bpm',
                    'heart_rate',
                    _categorizeHeartRate(
                        int.parse(reading['heart_rate'].toString())),
                  ),
                if (reading['spo2'] != null)
                  _buildMetric(
                    'SpO2',
                    '${reading['spo2']}%',
                    'spo2',
                    _categorizeSpO2(int.parse(reading['spo2'].toString())),
                  ),
                if (reading['temperature'] != null)
                  _buildMetric(
                    'Temp',
                    '${reading['temperature']}°C',
                    'temperature',
                    _categorizeTemperature(
                        double.parse(reading['temperature'].toString())),
                  ),
              ],
            ),
          ],

          // Blood Pressure (if available)
          if (reading['systolic'] != null && reading['diastolic'] != null) ...[
            SizedBox(height: 12),
            _buildBloodPressureCard(
              int.parse(reading['systolic'].toString()),
              int.parse(reading['diastolic'].toString()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, String paramKey,
      Map<String, dynamic>? category) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category != null
              ? category['color'].withOpacity(0.3)
              : AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            parameterImages[paramKey] ?? 'assets/images/logo.png',
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.sensors, color: AppColors.primary, size: 20);
            },
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (category != null) ...[
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: category['color'].withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category['category'],
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: category['color'],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBloodPressureCard(int systolic, int diastolic) {
    final category = _categorizeBloodPressure(systolic, diastolic);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category['color'].withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                parameterImages['bp']!,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.monitor_heart_outlined,
                    color: AppColors.primary,
                    size: 24,
                  );
                },
              ),
              SizedBox(width: 12),
              Text(
                'Blood Pressure',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '$systolic/$diastolic mmHg',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: category['color'].withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category['category'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: category['color'],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showRetakeDialog(Map<String, dynamic> reading) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            _RetakeParametersScreen(
              reading: reading,
              patientName: selectedPatient!['name'],
              onComplete: () async {
                Navigator.pop(context);
                setState(() {}); // Refresh the readings
              },
            ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> reading) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.warning, color: AppColors.error),
                SizedBox(width: 12),
                Text(
                  'Delete Record',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete this health record? This action cannot be undone.',
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                    'Cancel', style: TextStyle(color: AppColors.textLight)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final result = await ApiService.deleteReading(reading['id']);

                  if (result['success']) {
                    setState(() {}); // Refresh the readings

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Health record deleted successfully!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete: ${result['message']}'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}

// Retake Parameters Screen
class _RetakeParametersScreen extends StatelessWidget {
  final Map<String, dynamic> reading;
  final String patientName;
  final VoidCallback onComplete;

  const _RetakeParametersScreen({
    Key? key,
    required this.reading,
    required this.patientName,
    required this.onComplete,
  }) : super(key: key);

  Map<String, String> get parameterImages => {
    'bmi': 'assets/images/body-mass-index.png',
    'temperature': 'assets/images/body-temperature.png',
    'vitals': 'assets/images/oxygen-saturation.png',
    'bp': 'assets/images/blood-pressure.png',
  };

  @override
  Widget build(BuildContext context) {
    // Determine which parameters are available in this reading
    List<RetakeOption> availableParameters = [];

    if (reading['bmi'] != null) {
      availableParameters.add(
        RetakeOption(
          title: 'Body Mass Index (BMI)',
          paramKey: 'bmi',
          icon: Icons.analytics,
          color: Color(0xFF8B5CF6),
          currentValue: 'BMI: ${reading['bmi']}',
          imagePath: parameterImages['bmi']!,
        ),
      );
    }

    if (reading['temperature'] != null) {
      availableParameters.add(
        RetakeOption(
          title: 'Body Temperature',
          paramKey: 'temperature',
          icon: Icons.thermostat,
          color: Color(0xFFEF4444),
          currentValue: 'Temp: ${reading['temperature']}°C',
          imagePath: parameterImages['temperature']!,
        ),
      );
    }

    if (reading['heart_rate'] != null || reading['spo2'] != null) {
      String currentValue = '';
      if (reading['heart_rate'] != null && reading['spo2'] != null) {
        currentValue = 'HR: ${reading['heart_rate']} bpm, SpO2: ${reading['spo2']}%';
      } else if (reading['heart_rate'] != null) {
        currentValue = 'HR: ${reading['heart_rate']} bpm';
      } else {
        currentValue = 'SpO2: ${reading['spo2']}%';
      }

      availableParameters.add(
        RetakeOption(
          title: 'Heart Rate & SpO2',
          paramKey: 'vitals',
          icon: Icons.favorite,
          color: Color(0xFFEC4899),
          currentValue: currentValue,
          imagePath: parameterImages['vitals']!,
        ),
      );
    }

    if (reading['systolic'] != null && reading['diastolic'] != null) {
      availableParameters.add(
        RetakeOption(
          title: 'Blood Pressure',
          paramKey: 'bp',
          icon: Icons.monitor_heart,
          color: Color(0xFF10B981),
          currentValue: 'BP: ${reading['systolic']}/${reading['diastolic']} mmHg',
          imagePath: parameterImages['bp']!,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Retake Measurements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Patient Info Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1848A0),
                  Color(0xFF2563C9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.white,
                  radius: 40,
                  child: Text(
                    patientName[0].toUpperCase(),
                    style: TextStyle(
                      color: Color(0xFF1848A0),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  patientName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select parameter to retake',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Parameters List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: availableParameters.length,
              itemBuilder: (context, index) {
                final option = availableParameters[index];
                return _buildRetakeOptionCard(context, option);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetakeOptionCard(BuildContext context, RetakeOption option) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: option.color.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ParameterMeasurementScreen(
                  title: option.title,
                  icon: option.icon,
                  color: option.color,
                  paramKey: option.paramKey,
                  patientName: patientName,
                  onDataSaved: (data) async {
                    // Update the reading with new data
                    reading.addAll(data);

                    // Call API to update
                    final result = await ApiService.updateReading(
                      reading['id'],
                      reading,
                    );

                    if (result['success']) {
                      Navigator.pop(context); // Close parameter screen
                      onComplete(); // Call completion callback

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${option.title} updated successfully!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon/Image container
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: option.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    option.imagePath,
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        option.icon,
                        color: option.color,
                        size: 32,
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                // Title and current value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        option.currentValue,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RetakeOption {
  final String title;
  final String paramKey;
  final IconData icon;
  final Color color;
  final String currentValue;
  final String imagePath;

  RetakeOption({
    required this.title,
    required this.paramKey,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.imagePath,
  });
}