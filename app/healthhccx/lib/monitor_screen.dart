import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'healthworker_dashboard.dart';
import 'api_service.dart';
import 'patient_monitoring_screen.dart';
import 'esp32_connection_service.dart';

class MonitorScreen extends StatefulWidget {
  final String workerName;
  final String workerEmail;

  const MonitorScreen({
    Key? key,
    required this.workerName,
    required this.workerEmail,
  }) : super(key: key);

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> with WidgetsBindingObserver {
  final Esp32ConnectionService _esp32Service = Esp32ConnectionService();
  Timer? _registrationTimer;
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  List<Map<String, dynamic>> newRegistrations = [];
  TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? selectedPatient;
  Set<String> seenEmails = {};
  bool _isLoading = true;
  bool _isCheckingRegistrations = false;
  DateTime? _lastCheckTime;

  // Static variable to persist across widget rebuilds
  static Set<String> _persistentSeenEmails = {};

  // Hive box name
  static const String _seenEmailsBoxName = 'seen_patient_emails';

  // ✅ Philippine Time DateFormat
  final DateFormat _phDateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');
  final DateFormat _phShortDate = DateFormat('MMM dd, yyyy • hh:mm a');

  // ✅ HELPER: Parse timestamp from API (already in PH time from backend)
  DateTime _parsePhilippineTimestamp(String timestamp) {
    try {
      // Backend returns timestamp already converted to PH time via CONVERT_TZ
      // Parse it as-is (it's already in UTC+8)
      final dt = DateTime.parse(timestamp);

      // If the string doesn't have timezone info, treat it as PH time
      if (!timestamp.contains('Z') && !timestamp.contains('+')) {
        // This is already Philippine Time from backend
        return dt;
      }

      return dt.toLocal(); // Convert to local device time
    } catch (e) {
      print('⚠️ Error parsing timestamp: $timestamp - $e');
      return DateTime.now();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load from static variable first (immediate)
    seenEmails = Set<String>.from(_persistentSeenEmails);
    print('📱 Restored ${seenEmails.length} emails from memory');

    _initializeScreen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check immediately
      print('📱 App resumed - checking for updates');
      _checkNewRegistrations();
    }
  }

  Future<void> _initializeScreen() async {
    print('🚀 Initializing Monitor Screen');
    await _initializeHiveBox();
    await _loadSeenEmailsFromStorage();
    await _fetchPatientsInitial();
    _startRegistrationCheck();
    setState(() => _isLoading = false);
  }

  // Initialize Hive box for seen emails
  Future<void> _initializeHiveBox() async {
    try {
      if (!Hive.isBoxOpen(_seenEmailsBoxName)) {
        await Hive.openBox(_seenEmailsBoxName);
        print('✅ Opened Hive box: $_seenEmailsBoxName');
      }
    } catch (e) {
      print('⚠️ Error opening Hive box: $e');
      print('✅ Will use in-memory storage');
    }
  }

  // Load seen emails from Hive
  Future<void> _loadSeenEmailsFromStorage() async {
    try {
      if (Hive.isBoxOpen(_seenEmailsBoxName)) {
        final box = Hive.box(_seenEmailsBoxName);
        final seenEmailsList = box.get('emails', defaultValue: <String>[]);

        if (mounted) {
          setState(() {
            seenEmails = (seenEmailsList as List).cast<String>().toSet();
            // Update static variable too
            _persistentSeenEmails = Set<String>.from(seenEmails);
          });
        }

        print('✅ Loaded ${seenEmails.length} seen emails from Hive');
        if (seenEmails.isNotEmpty) {
          print('📱 Seen emails: ${seenEmails.take(5).toList()}${seenEmails.length > 5 ? '...' : ''}');
        }
      } else {
        print('⚠️ Hive box not open, using memory (${_persistentSeenEmails.length} emails)');
        if (mounted) {
          setState(() {
            seenEmails = Set<String>.from(_persistentSeenEmails);
          });
        }
      }
    } catch (e) {
      print('❌ Error loading seen emails: $e');
      print('⚠️ Using in-memory storage instead (${_persistentSeenEmails.length} emails)');
      if (mounted) {
        setState(() {
          seenEmails = Set<String>.from(_persistentSeenEmails);
        });
      }
    }
  }

  // Save seen emails to Hive
  Future<void> _saveSeenEmailsToStorage() async {
    // Always update static variable first (instant backup)
    _persistentSeenEmails = Set<String>.from(seenEmails);

    try {
      if (Hive.isBoxOpen(_seenEmailsBoxName)) {
        final box = Hive.box(_seenEmailsBoxName);
        final emailList = seenEmails.toList();

        await box.put('emails', emailList);

        print('💾 ✅ Successfully saved ${seenEmails.length} seen emails to Hive');
        print('   📝 Emails: ${emailList.take(3).toList()}${emailList.length > 3 ? '...' : ''}');
      } else {
        print('⚠️ Hive box not open, using memory only');
        print('✅ In-memory storage active (${_persistentSeenEmails.length} emails persisted)');
      }
    } catch (e) {
      print('⚠️ Hive save error: $e');
      print('✅ Using in-memory storage (${_persistentSeenEmails.length} emails persisted)');
    }
  }

  Future<void> _fetchPatientsInitial() async {
    print('🔍 Initial patient fetch');
    final result = await ApiService.getPatients();

    if (result['success'] && mounted) {
      List<Map<String, dynamic>> fetchedPatients =
      List<Map<String, dynamic>>.from(result['patients']);

      setState(() {
        patients = fetchedPatients;
        filteredPatients = patients;
      });

      print('📊 Loaded ${patients.length} patients');

      // Check for new registrations immediately
      _performRegistrationCheck(fetchedPatients);
    }
  }

  // Faster registration check - every 2 seconds
  void _startRegistrationCheck() {
    print('🔄 Started real-time registration monitoring (2s interval)');

    _registrationTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (_isCheckingRegistrations) {
        print('⏭️ Skipping check - previous check still running');
        return;
      }

      final now = DateTime.now();
      print('⏰ Checking registrations at ${now.toString().substring(11, 19)}');
      await _checkNewRegistrations();
    });
  }

  Future<void> _checkNewRegistrations() async {
    if (_isCheckingRegistrations) return;

    _isCheckingRegistrations = true;
    _lastCheckTime = DateTime.now();

    try {
      final result = await ApiService.getPatients();

      if (result['success'] && mounted) {
        List<Map<String, dynamic>> allPatients =
        List<Map<String, dynamic>>.from(result['patients']);

        print('   📊 DB: ${allPatients.length} | Seen: ${seenEmails.length} | Notifs: ${newRegistrations.length}');

        _performRegistrationCheck(allPatients);

        // Update patient list
        setState(() {
          patients = allPatients;
          if (searchController.text.isEmpty) {
            filteredPatients = patients;
          } else {
            _filterPatients(searchController.text);
          }
        });
      }
    } catch (e) {
      print('❌ Error checking registrations: $e');
    } finally {
      _isCheckingRegistrations = false;
    }
  }

  void _performRegistrationCheck(List<Map<String, dynamic>> allPatients) {
    // Find truly new patients (not in seenEmails)
    List<Map<String, dynamic>> newPatients = allPatients.where((patient) {
      final email = patient['email']?.toString() ?? '';
      return email.isNotEmpty && !seenEmails.contains(email);
    }).toList();

    if (newPatients.isEmpty) {
      return;
    }

    print('🎉 FOUND ${newPatients.length} NEW PATIENT(S)!');

    bool hasNewNotification = false;
    List<Map<String, dynamic>> notificationsToAdd = [];

    for (var patient in newPatients) {
      final email = patient['email']?.toString() ?? '';
      if (email.isEmpty) continue;

      // Double-check: not in seenEmails AND not already in notifications
      final alreadySeen = seenEmails.contains(email);
      final alreadyInNotifications = newRegistrations.any(
              (notif) => notif['email'] == email
      );

      if (!alreadySeen && !alreadyInNotifications) {
        print('   ➕ NEW: ${patient['name']} (${email})');

        notificationsToAdd.add({
          'name': patient['name'],
          'email': email,
          'registeredAt': DateTime.now(),
          'created_at': patient['created_at'] ??
              patient['registration_date'] ??
              patient['registered_at'],
        });

        hasNewNotification = true;
      }
    }

    if (hasNewNotification && mounted) {
      setState(() {
        newRegistrations.addAll(notificationsToAdd);
      });
      print('🔔 BADGE COUNT: ${newRegistrations.length}');

      // Vibrate/haptic feedback if available
      _showNotificationFeedback();
    }
  }

  void _showNotificationFeedback() {
    // You can add haptic feedback here if needed
    // HapticFeedback.mediumImpact();
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPatients = patients;
      } else {
        filteredPatients = patients.where((patient) {
          final name = patient['name']?.toString().toLowerCase() ?? '';
          final email = patient['email']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || email.contains(searchLower);
        }).toList();
      }
    });
  }

  void _showInstructionsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstructionsScreen(),
      ),
    );
  }

  void _showNotificationsScreen() async {
    print('🔔 Opening notifications screen');
    print('   Current notifications: ${newRegistrations.length}');

    final notificationsCopy = List<Map<String, dynamic>>.from(newRegistrations);

    // Extract emails to mark as seen
    Set<String> emailsToMarkSeen = {};
    for (var notification in newRegistrations) {
      final email = notification['email']?.toString();
      if (email != null && email.isNotEmpty) {
        emailsToMarkSeen.add(email);
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          notifications: notificationsCopy,
          allPatients: patients,
          parsePhilippineTimestamp: _parsePhilippineTimestamp,
        ),
      ),
    );

    // Mark all as seen IMMEDIATELY after viewing
    print('✅ Marking ${emailsToMarkSeen.length} patients as seen');

    // Update seenEmails and clear notifications in ONE setState
    setState(() {
      // Add all notification emails to seenEmails
      seenEmails.addAll(emailsToMarkSeen);

      // Update static variable
      _persistentSeenEmails = Set<String>.from(seenEmails);

      // Clear notifications
      newRegistrations.clear();
    });

    // Save to storage IMMEDIATELY
    await _saveSeenEmailsToStorage();

    print('💾 Storage updated. Total seen: ${seenEmails.length}');
    print('📝 Persistent memory: ${_persistentSeenEmails.length}');
    print('🔕 Badge cleared: ${newRegistrations.length}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _registrationTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.local_hospital,
                  color: AppColors.primary,
                  size: 40,
                );
              },
            ),
            SizedBox(width: 12),
            Text(
              'HealthX Monitoring',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _esp32Service.isConnected,
            builder: (context, isConnected, child) {
              return Container(
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? AppColors.success : AppColors.error,
                  size: 24,
                ),
              );
            },
          ),

          // Notification Bell with Badge
          Container(
            margin: EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    newRegistrations.isNotEmpty
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    color: newRegistrations.isNotEmpty
                        ? AppColors.error
                        : AppColors.primary,
                    size: 28,
                  ),
                  onPressed: _showNotificationsScreen,
                ),

                // Animated Badge
                if (newRegistrations.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      child: Center(
                        child: Text(
                          '${newRegistrations.length}',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: selectedPatient == null
          ? _buildPatientSearch()
          : PatientMonitoringScreen(
        patient: selectedPatient!,
        workerEmail: widget.workerEmail,
        onBack: () => setState(() => selectedPatient = null),
      ),
    );
  }

  Widget _buildPatientSearch() {
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
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),

        // Instructions Button
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ElevatedButton.icon(
            onPressed: _showInstructionsScreen,
            icon: Icon(Icons.info_outline, color: AppColors.white),
            label: Text(
              'View Instructions',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 2,
            ),
          ),
        ),

        // Patient List
        Expanded(
          child: filteredPatients.isEmpty
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
                  searchController.text.isNotEmpty
                      ? 'No patients match your search'
                      : 'No patients found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        searchController.clear();
                        _filterPatients('');
                      },
                      child: Text('Clear search'),
                    ),
                  ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: () async {
              await _checkNewRegistrations();
            },
            color: AppColors.primary,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              physics: AlwaysScrollableScrollPhysics(),
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
    return GestureDetector(
      onTap: () => setState(() => selectedPatient = patient),
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
                (patient['name']?[0] ?? 'P').toUpperCase(),
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
                    patient['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    patient['email'] ?? 'No email',
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
    );
  }
}

// Instructions Screen (unchanged - no timestamp handling needed)
class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({Key? key}) : super(key: key);

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  int currentStep = 0;

  final List<InstructionStep> steps = [
    InstructionStep(
      title: 'Search and Select Patient',
      description: 'Use the search bar to find a patient from the list. Tap on their name to select them for monitoring.',
      icon: Icons.search,
      color: Color(0xFF1848A0),
    ),
    InstructionStep(
      title: 'Choose Parameter',
      description: 'Select the health parameter you want to measure (Heart Rate, Blood Pressure, Temperature, etc.).',
      icon: Icons.tune,
      color: Color(0xFF10B981),
    ),
    InstructionStep(
      title: 'Follow Instructions',
      description: 'Read and follow the on-screen instructions carefully for accurate measurements.',
      icon: Icons.playlist_add_check,
      color: Color(0xFFF59E0B),
    ),
    InstructionStep(
      title: 'Start Sensor',
      description: 'Make sure the ESP32 device is connected (check WiFi icon), then start the sensor when you\'re ready.',
      icon: Icons.play_circle_outline,
      color: Color(0xFF8B5CF6),
    ),
    InstructionStep(
      title: 'Save Data',
      description: 'After the measurement is complete, review the results and save the data to the patient\'s record.',
      icon: Icons.save_outlined,
      color: Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Instructions',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                    (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: currentStep == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: currentStep == index
                        ? AppColors.primary
                        : Colors.white,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // Step Number
          Text(
            'Step ${currentStep + 1} of ${steps.length}',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),

          // Content
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
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    steps[currentStep].description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textLight,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Navigation Buttons
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
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(
                          color: AppColors.primary,
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
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      currentStep < steps.length - 1 ? 'Next' : 'Got it!',
                      style: TextStyle(
                        color: AppColors.white,
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

// ✅ FIXED: Notifications Screen with Philippine Time support
class NotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> allPatients;
  final DateTime Function(String) parsePhilippineTimestamp;

  const NotificationsScreen({
    Key? key,
    required this.notifications,
    required this.allPatients,
    required this.parsePhilippineTimestamp,
  }) : super(key: key);

  // ✅ IMPROVED: Time ago calculation using device's current time
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // ✅ FIXED: Proper Philippine Time parsing
  String _formatRegistrationDate(dynamic dateField) {
    if (dateField == null) return 'Date not available';

    try {
      DateTime date;
      if (dateField is String) {
        // Use the proper Philippine timestamp parser
        date = parsePhilippineTimestamp(dateField);
      } else if (dateField is DateTime) {
        date = dateField;
      } else {
        return 'Invalid date';
      }

      return _getTimeAgo(date);
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort patients by registration date (newest first)
    final sortedPatients = List<Map<String, dynamic>>.from(allPatients);
    sortedPatients.sort((a, b) {
      try {
        final dateA = a['created_at'] ?? a['registration_date'] ?? a['registered_at'] ?? '';
        final dateB = b['created_at'] ?? b['registration_date'] ?? b['registered_at'] ?? '';
        return dateB.toString().compareTo(dateA.toString());
      } catch (e) {
        return 0;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Registrations',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Total Patients Header
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
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
                    '${allPatients.length} Total Patient${allPatients.length != 1 ? 's' : ''}',
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

          // All Patients List
          Expanded(
            child: sortedPatients.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 100,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No registered patients yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: sortedPatients.length,
              itemBuilder: (context, index) {
                final patient = sortedPatients[index];
                final registrationDate = patient['created_at'] ??
                    patient['registration_date'] ??
                    patient['registered_at'];

                return Container(
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
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (patient['name']?[0] ?? 'P').toUpperCase(),
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient['name'] ?? 'Unknown Patient',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              patient['email'] ?? 'No email',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textLight,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Registered ${_formatRegistrationDate(registrationDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}