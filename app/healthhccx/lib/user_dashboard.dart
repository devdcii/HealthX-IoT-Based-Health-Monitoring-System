import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'login.dart';
import 'api_service.dart';
import 'user_settings_screen.dart';

// App Colors
class AppColors {
  static const primary = Color(0xFF1848A0);
  static const white = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textLight = Color(0xFF64748B);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const background = Color(0xFFF8FAFC);
  static const warning = Color(0xFFF59E0B);
}

class UserDashboard extends StatefulWidget {
  final int userId;
  final String name;
  final String email;
  final String userType;

  const UserDashboard({
    Key? key,
    required this.userId,
    required this.name,
    required this.email,
    this.userType = 'user',
  }) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with WidgetsBindingObserver {
  List<Map<String, dynamic>> readings = [];
  bool isLoading = true;
  Map<String, dynamic>? latestReading;
  int _currentIndex = 0;
  List<Map<String, dynamic>> newReadings = [];
  Set<String> seenReadingIds = {};

  // ✅ CRITICAL: These will hold the CURRENT state
  late String currentName;
  late String currentEmail;

  static Set<String> _persistentSeenIds = {};
  static const String _seenReadingsBoxName = 'seen_reading_ids';

  // ✅ Philippine Time DateFormat - displays in PH timezone
  final DateFormat _phDateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');
  final DateFormat _phDateOnly = DateFormat('MMMM dd, yyyy');
  final DateFormat _phTimeOnly = DateFormat('hh:mm a');
  final DateFormat _phShortDate = DateFormat('MMM dd, yyyy • hh:mm a');
  final DateFormat _phMonthDay = DateFormat('MMM dd');

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

  // ✅ HELPER: Parse timestamp from API (already in PH time from backend)
  DateTime _parsePhilippineTimestamp(String timestamp) {
    try {
      // Backend returns timestamp already converted to PH time
      // Parse it as-is (it's already in UTC+8)
      final dt = DateTime.parse(timestamp);

      // If the string doesn't have timezone info, treat it as PH time
      if (!timestamp.contains('Z') && !timestamp.contains('+')) {
        // This is already Philippine Time from CONVERT_TZ
        return dt;
      }

      return dt.toLocal(); // Convert to local device time
    } catch (e) {
      print('⚠️ Error parsing timestamp: $timestamp - $e');
      return DateTime.now();
    }
  }

  // ✅ Health parameter categorization functions
  Map<String, dynamic> _categorizeBMI(double bmi) {
    if (bmi < 18.5) {
      return {'category': 'Underweight', 'color': Color(0xFFF59E0B), 'severity': 'warning'};
    } else if (bmi >= 18.5 && bmi < 25.0) {
      return {'category': 'Normal', 'color': Color(0xFF10B981), 'severity': 'normal'};
    } else if (bmi >= 25.0 && bmi < 30.0) {
      return {'category': 'Overweight', 'color': Color(0xFFF59E0B), 'severity': 'warning'};
    } else if (bmi >= 30.0 && bmi < 35.0) {
      return {'category': 'Obesity Class I', 'color': Color(0xFFEF4444), 'severity': 'alert'};
    } else if (bmi >= 35.0 && bmi < 40.0) {
      return {'category': 'Obesity Class II', 'color': Color(0xFFDC2626), 'severity': 'critical'};
    } else {
      return {'category': 'Obesity Class III', 'color': Color(0xFF991B1B), 'severity': 'critical'};
    }
  }

  Map<String, dynamic> _categorizeTemperature(double temp) {
    if (temp < 35.0) {
      return {'category': 'Hypothermia', 'color': Color(0xFF991B1B), 'severity': 'critical'};
    } else if (temp >= 35.5 && temp < 36.5) {
      return {'category': 'Slightly Low', 'color': Color(0xFF3B82F6), 'severity': 'info'};
    } else if (temp >= 36.5 && temp <= 37.5) {
      return {'category': 'Normal', 'color': Color(0xFF10B981), 'severity': 'normal'};
    } else if (temp > 37.5 && temp <= 38.0) {
      return {'category': 'Low-grade Fever', 'color': Color(0xFFF59E0B), 'severity': 'warning'};
    } else if (temp > 38.0 && temp <= 39.0) {
      return {'category': 'Fever', 'color': Color(0xFFEF4444), 'severity': 'alert'};
    } else {
      return {'category': 'High Fever', 'color': Color(0xFF991B1B), 'severity': 'critical'};
    }
  }

  Map<String, dynamic> _categorizeHeartRate(int hr) {
    if (hr < 50) {
      return {'category': 'Bradycardia', 'color': Color(0xFFEF4444), 'severity': 'alert'};
    } else if (hr >= 50 && hr < 60) {
      return {'category': 'Low', 'color': Color(0xFF3B82F6), 'severity': 'info'};
    } else if (hr >= 60 && hr <= 100) {
      return {'category': 'Normal', 'color': Color(0xFF10B981), 'severity': 'normal'};
    } else if (hr > 100 && hr <= 120) {
      return {'category': 'Elevated', 'color': Color(0xFFF59E0B), 'severity': 'warning'};
    } else {
      return {'category': 'Tachycardia', 'color': Color(0xFFEF4444), 'severity': 'alert'};
    }
  }

  Map<String, dynamic> _categorizeSpO2(int spo2) {
    if (spo2 < 90) {
      return {'category': 'Hypoxemia', 'color': Color(0xFF991B1B), 'severity': 'critical'};
    } else if (spo2 >= 90 && spo2 <= 92) {
      return {'category': 'Low', 'color': Color(0xFFEF4444), 'severity': 'alert'};
    } else if (spo2 >= 93 && spo2 <= 94) {
      return {'category': 'Slightly Low', 'color': Color(0xFFF59E0B), 'severity': 'warning'};
    } else {
      return {'category': 'Normal', 'color': Color(0xFF10B981), 'severity': 'normal'};
    }
  }

  Map<String, dynamic> _categorizeBloodPressure(int systolic, int diastolic) {
    if (systolic > 180 || diastolic > 120) {
      return {'category': 'Hypertensive Crisis', 'color': Color(0xFF991B1B), 'severity': 'critical'};
    } else if (systolic >= 140 || diastolic >= 90) {
      return {'category': 'Hypertension Stage 2', 'color': Color(0xFFEF4444), 'severity': 'alert'};
    } else if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) {
      return {'category': 'Hypertension Stage 1', 'color': Color(0xFFF59E0B), 'severity': 'warning'};
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      return {'category': 'Elevated', 'color': Color(0xFF3B82F6), 'severity': 'info'};
    } else {
      return {'category': 'Normal', 'color': Color(0xFF10B981), 'severity': 'normal'};
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    seenReadingIds = Set<String>.from(_persistentSeenIds);

    // ✅ Initialize current name and email from widget
    currentName = widget.name;
    currentEmail = widget.email;

    _initializeScreen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - checking for new readings');
      _checkHiveData();
      _fetchReadings();
    }
  }

  Future<void> _checkHiveData() async {
    try {
      final box = await Hive.openBox('userBox');
      final hiveName = box.get('name', defaultValue: 'Not found');
      final hiveEmail = box.get('email', defaultValue: 'Not found');
      print('💾 Hive data on resume:');
      print('   Hive name: $hiveName');
      print('   Hive email: $hiveEmail');
      print('   Current state name: $currentName');
      print('   Current state email: $currentEmail');
    } catch (e) {
      print('⚠️ Error checking Hive: $e');
    }
  }

  Future<void> _initializeScreen() async {
    print('🚀 Initializing User Dashboard');
    await _initializeHiveBox();
    await _loadSeenReadingsFromStorage();
    await _fetchReadings();
    setState(() => isLoading = false);
  }

  Future<void> _initializeHiveBox() async {
    try {
      if (!Hive.isBoxOpen(_seenReadingsBoxName)) {
        await Hive.openBox(_seenReadingsBoxName);
        print('✅ Opened Hive box: $_seenReadingsBoxName');
      }
    } catch (e) {
      print('⚠️ Error opening Hive box: $e');
    }
  }

  Future<void> _loadSeenReadingsFromStorage() async {
    try {
      if (Hive.isBoxOpen(_seenReadingsBoxName)) {
        final box = Hive.box(_seenReadingsBoxName);
        final seenIdsList = box.get('${currentEmail}_reading_ids', defaultValue: <String>[]);

        if (mounted) {
          setState(() {
            seenReadingIds = (seenIdsList as List).cast<String>().toSet();
            _persistentSeenIds = Set<String>.from(seenReadingIds);
          });
        }

        print('✅ Loaded ${seenReadingIds.length} seen reading IDs from Hive');
      } else {
        if (mounted) {
          setState(() {
            seenReadingIds = Set<String>.from(_persistentSeenIds);
          });
        }
      }
    } catch (e) {
      print('❌ Error loading seen readings: $e');
      if (mounted) {
        setState(() {
          seenReadingIds = Set<String>.from(_persistentSeenIds);
        });
      }
    }
  }

  Future<void> _saveSeenReadingsToStorage() async {
    _persistentSeenIds = Set<String>.from(seenReadingIds);

    try {
      if (Hive.isBoxOpen(_seenReadingsBoxName)) {
        final box = Hive.box(_seenReadingsBoxName);
        final idList = seenReadingIds.toList();
        await box.put('${currentEmail}_reading_ids', idList);
        print('💾 ✅ Successfully saved ${seenReadingIds.length} seen reading IDs');
      }
    } catch (e) {
      print('⚠️ Hive save error: $e');
    }
  }

  Future<void> _fetchReadings() async {
    setState(() => isLoading = true);

    final result = await ApiService.getReadings(currentEmail);

    if (result['success']) {
      List<Map<String, dynamic>> fetchedReadings = List<Map<String, dynamic>>.from(result['readings']);

      setState(() {
        readings = fetchedReadings;
        if (readings.isNotEmpty) {
          latestReading = readings[0];
        }
        isLoading = false;
      });

      _checkNewReadings(fetchedReadings);
    } else {
      setState(() => isLoading = false);
    }
  }

  void _checkNewReadings(List<Map<String, dynamic>> allReadings) {
    List<Map<String, dynamic>> newOnes = allReadings.where((reading) {
      final readingId = reading['id']?.toString() ?? reading['timestamp']?.toString() ?? '';
      return readingId.isNotEmpty && !seenReadingIds.contains(readingId);
    }).toList();

    if (newOnes.isEmpty) return;

    print('🎉 FOUND ${newOnes.length} NEW READING(S)!');

    List<Map<String, dynamic>> notificationsToAdd = [];

    for (var reading in newOnes) {
      final readingId = reading['id']?.toString() ?? reading['timestamp']?.toString() ?? '';
      if (readingId.isEmpty) continue;

      final alreadySeen = seenReadingIds.contains(readingId);
      final alreadyInNotifications = newReadings.any((notif) => notif['id'] == readingId);

      if (!alreadySeen && !alreadyInNotifications) {
        print('   ➕ NEW READING: ${reading['timestamp']}');
        notificationsToAdd.add(reading);
      }
    }

    if (notificationsToAdd.isNotEmpty && mounted) {
      setState(() {
        newReadings.addAll(notificationsToAdd);
      });
      print('🔔 BADGE COUNT: ${newReadings.length}');
    }
  }

  void _showNotificationsScreen() async {
    print('🔔 Opening notifications screen');
    print('   Current notifications: ${newReadings.length}');

    final notificationsCopy = List<Map<String, dynamic>>.from(newReadings);

    Set<String> idsToMarkSeen = {};
    for (var notification in newReadings) {
      final readingId = notification['id']?.toString() ?? notification['timestamp']?.toString();
      if (readingId != null && readingId.isNotEmpty) {
        idsToMarkSeen.add(readingId);
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingNotificationsScreen(
          notifications: notificationsCopy,
          allReadings: readings,
          parameterImages: parameterImages,
          categorizeBMI: _categorizeBMI,
          categorizeTemperature: _categorizeTemperature,
          categorizeHeartRate: _categorizeHeartRate,
          categorizeSpO2: _categorizeSpO2,
          categorizeBloodPressure: _categorizeBloodPressure,
          parsePhilippineTimestamp: _parsePhilippineTimestamp,
        ),
      ),
    );

    print('✅ Marking ${idsToMarkSeen.length} readings as seen');

    setState(() {
      seenReadingIds.addAll(idsToMarkSeen);
      _persistentSeenIds = Set<String>.from(seenReadingIds);
      newReadings.clear();
    });

    await _saveSeenReadingsToStorage();

    print('💾 Storage updated. Total seen: ${seenReadingIds.length}');
  }

  // ✅ FIXED: This callback now properly updates state AND refreshes readings
  void _handleProfileUpdate(String newName, String newEmail) async {
    print('🔄 Profile update received in dashboard');
    print('   Old: $currentName ($currentEmail)');
    print('   New: $newName ($newEmail)');

    if (currentName == newName && currentEmail == newEmail) {
      print('⚠️ No changes detected, skipping update');
      return;
    }

    setState(() {
      currentName = newName;
      currentEmail = newEmail;
    });

    print('✅ Dashboard state updated');
    print('🔄 Refreshing readings with new email: $newEmail');

    await _fetchReadings();

    print('✅ Profile update complete! Dashboard fully refreshed.');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildLatestReadingTab(),
      _buildHistoryTab(),
      UserSettingsScreen(
        key: ValueKey('settings-$currentName-$currentEmail'),
        name: currentName,
        email: currentEmail,
        userId: widget.userId,
        userType: widget.userType,
        onProfileUpdated: _handleProfileUpdate,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.health_and_safety, color: AppColors.primary, size: 32);
              },
            ),
            SizedBox(width: 12),
            Text(
              'My Health Records',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    newReadings.isNotEmpty
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    color: newReadings.isNotEmpty
                        ? AppColors.error
                        : AppColors.primary,
                    size: 28,
                  ),
                  onPressed: _showNotificationsScreen,
                ),
                if (newReadings.isNotEmpty)
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
                          '${newReadings.length}',
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
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.show_chart, 'Latest', 0),
                _buildNavItem(Icons.history, 'History', 1),
                _buildNavItem(Icons.settings_outlined, 'Settings', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.textLight,
              size: 24,
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLatestReadingTab() {
    return RefreshIndicator(
      onRefresh: _fetchReadings,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2563C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
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
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person, color: AppColors.white, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back,',
                              style: TextStyle(color: AppColors.white.withOpacity(0.9), fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              currentName,
                              style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatChip(Icons.assignment, '${readings.length}', 'Readings'),
                      SizedBox(width: 12),
                      _buildStatChip(
                        Icons.calendar_today,
                        latestReading != null
                            ? _phMonthDay.format(_parsePhilippineTimestamp(latestReading!['timestamp']))
                            : 'No data',
                        'Last Check',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            if (latestReading != null) ...[
              Row(
                children: [
                  Icon(Icons.show_chart, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Latest Reading',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                _phDateFormat.format(_parsePhilippineTimestamp(latestReading!['timestamp'])),
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              SizedBox(height: 16),
              _buildReadingCard(latestReading!),
            ] else
              Center(
                child: Container(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.medical_information_outlined, size: 64, color: AppColors.primary.withOpacity(0.5)),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No readings yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your health readings will appear here',
                        style: TextStyle(fontSize: 14, color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _fetchReadings,
      color: AppColors.primary,
      child: readings.isEmpty
          ? Center(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.history, size: 64, color: AppColors.primary.withOpacity(0.5)),
                ),
                SizedBox(height: 24),
                Text(
                  'No reading history',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                SizedBox(height: 8),
                Text(
                  'Your health reading history will appear here',
                  style: TextStyle(fontSize: 14, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: readings.length,
        itemBuilder: (context, index) {
          return _buildHistoryListItem(readings[index]);
        },
      ),
    );
  }

  Widget _buildHistoryListItem(Map<String, dynamic> reading) {
    final timestamp = _parsePhilippineTimestamp(reading['timestamp']);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showFullScreenReading(reading),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/healthreadings.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.medical_information,
                        color: AppColors.primary,
                        size: 24,
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _phDateOnly.format(timestamp),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _phTimeOnly.format(timestamp),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
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

  void _showFullScreenReading(Map<String, dynamic> reading) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenReadingView(
          reading: reading,
          parameterImages: parameterImages,
          categorizeBMI: _categorizeBMI,
          categorizeTemperature: _categorizeTemperature,
          categorizeHeartRate: _categorizeHeartRate,
          categorizeSpO2: _categorizeSpO2,
          categorizeBloodPressure: _categorizeBloodPressure,
          parsePhilippineTimestamp: _parsePhilippineTimestamp,
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (reading['height'] != null || reading['weight'] != null || reading['bmi'] != null)
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                if (reading['height'] != null)
                  _buildVitalCard('Height', '${reading['height']} cm', 'height', null),
                if (reading['weight'] != null)
                  _buildVitalCard('Weight', '${reading['weight']} kg', 'weight', null),
                if (reading['bmi'] != null)
                  _buildVitalCard(
                    'BMI',
                    reading['bmi'].toString(),
                    'bmi',
                    _categorizeBMI(double.parse(reading['bmi'].toString())),
                  ),
              ],
            ),

          if (reading['heart_rate'] != null || reading['spo2'] != null || reading['temperature'] != null) ...[
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
                  _buildVitalCard(
                    'Heart Rate',
                    '${reading['heart_rate']} bpm',
                    'heart_rate',
                    _categorizeHeartRate(int.parse(reading['heart_rate'].toString())),
                  ),
                if (reading['spo2'] != null)
                  _buildVitalCard(
                    'SpO2',
                    '${reading['spo2']}%',
                    'spo2',
                    _categorizeSpO2(int.parse(reading['spo2'].toString())),
                  ),
                if (reading['temperature'] != null)
                  _buildVitalCard(
                    'Temp',
                    '${reading['temperature']}°C',
                    'temperature',
                    _categorizeTemperature(double.parse(reading['temperature'].toString())),
                  ),
              ],
            ),
          ],

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

  Widget _buildVitalCard(String label, String value, String paramKey, Map<String, dynamic>? category) {
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
}

// ✅ Full Screen Reading View
class FullScreenReadingView extends StatelessWidget {
  final Map<String, dynamic> reading;
  final Map<String, String> parameterImages;
  final Function(double) categorizeBMI;
  final Function(double) categorizeTemperature;
  final Function(int) categorizeHeartRate;
  final Function(int) categorizeSpO2;
  final Function(int, int) categorizeBloodPressure;
  final DateTime Function(String) parsePhilippineTimestamp;

  const FullScreenReadingView({
    Key? key,
    required this.reading,
    required this.parameterImages,
    required this.categorizeBMI,
    required this.categorizeTemperature,
    required this.categorizeHeartRate,
    required this.categorizeSpO2,
    required this.categorizeBloodPressure,
    required this.parsePhilippineTimestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = parsePhilippineTimestamp(reading['timestamp']);

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
          'Reading Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2563C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.white,
                    size: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    DateFormat('MMMM dd, yyyy').format(timestamp),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.white.withOpacity(0.9),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        DateFormat('hh:mm a').format(timestamp),
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Health Parameters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 16),
            _buildFullReadingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullReadingCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (reading['height'] != null || reading['weight'] != null || reading['bmi'] != null)
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                if (reading['height'] != null)
                  _buildVitalCard('Height', '${reading['height']} cm', 'height', null),
                if (reading['weight'] != null)
                  _buildVitalCard('Weight', '${reading['weight']} kg', 'weight', null),
                if (reading['bmi'] != null)
                  _buildVitalCard(
                    'BMI',
                    reading['bmi'].toString(),
                    'bmi',
                    categorizeBMI(double.parse(reading['bmi'].toString())),
                  ),
              ],
            ),
          if (reading['heart_rate'] != null || reading['spo2'] != null || reading['temperature'] != null) ...[
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
                  _buildVitalCard(
                    'Heart Rate',
                    '${reading['heart_rate']} bpm',
                    'heart_rate',
                    categorizeHeartRate(int.parse(reading['heart_rate'].toString())),
                  ),
                if (reading['spo2'] != null)
                  _buildVitalCard(
                    'SpO2',
                    '${reading['spo2']}%',
                    'spo2',
                    categorizeSpO2(int.parse(reading['spo2'].toString())),
                  ),
                if (reading['temperature'] != null)
                  _buildVitalCard(
                    'Temp',
                    '${reading['temperature']}°C',
                    'temperature',
                    categorizeTemperature(double.parse(reading['temperature'].toString())),
                  ),
              ],
            ),
          ],
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

  Widget _buildVitalCard(String label, String value, String paramKey, Map<String, dynamic>? category) {
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
    final category = categorizeBloodPressure(systolic, diastolic);

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
}

// Reading Notifications Screen
class ReadingNotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> allReadings;
  final Map<String, String> parameterImages;
  final Function(double) categorizeBMI;
  final Function(double) categorizeTemperature;
  final Function(int) categorizeHeartRate;
  final Function(int) categorizeSpO2;
  final Function(int, int) categorizeBloodPressure;
  final DateTime Function(String) parsePhilippineTimestamp;

  const ReadingNotificationsScreen({
    Key? key,
    required this.notifications,
    required this.allReadings,
    required this.parameterImages,
    required this.categorizeBMI,
    required this.categorizeTemperature,
    required this.categorizeHeartRate,
    required this.categorizeSpO2,
    required this.categorizeBloodPressure,
    required this.parsePhilippineTimestamp,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final sortedReadings = List<Map<String, dynamic>>.from(allReadings);
    sortedReadings.sort((a, b) {
      try {
        final dateA = parsePhilippineTimestamp(a['timestamp'] ?? '');
        final dateB = parsePhilippineTimestamp(b['timestamp'] ?? '');
        return dateB.compareTo(dateA);
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
          'Health Readings',
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
                    Icons.assignment,
                    color: AppColors.white,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${allReadings.length} Total Result${allReadings.length != 1 ? 's' : ''}',
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
          Expanded(
            child: sortedReadings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 100,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No readings yet',
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
              itemCount: sortedReadings.length,
              itemBuilder: (context, index) {
                final reading = sortedReadings[index];
                final timestamp = parsePhilippineTimestamp(reading['timestamp']);

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
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/healthreadings.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.favorite,
                                color: AppColors.primary,
                                size: 28,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Reading',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp),
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
                                  'Recorded ${_getTimeAgo(timestamp)}',
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