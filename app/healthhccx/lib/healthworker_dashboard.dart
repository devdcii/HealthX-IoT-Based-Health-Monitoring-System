import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'monitor_screen.dart';
import 'patients_screen.dart';
import 'settings_screen.dart';

// App Colors
class AppColors {
  static const primary = Color(0xFF1848A0);
  static const white = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textLight = Color(0xFF64748B);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const background = Color(0xFFF8FAFC);
  static const warning = Color(0xFDF59E0B);
}

class HealthWorkerDashboard extends StatefulWidget {
  final String name;
  final String email;

  const HealthWorkerDashboard({
    Key? key,
    required this.name,
    required this.email,
  }) : super(key: key);

  @override
  State<HealthWorkerDashboard> createState() => _HealthWorkerDashboardState();
}

class _HealthWorkerDashboardState extends State<HealthWorkerDashboard> {
  int _currentIndex = 0;
  late String currentName;
  late String currentEmail;

  @override
  void initState() {
    super.initState();
    currentName = widget.name;
    currentEmail = widget.email;
    print('🏥 HealthWorkerDashboard initialized: $currentName, $currentEmail');
    _loadProfileFromHive();
  }

  Future<void> _loadProfileFromHive() async {
    try {
      final box = await Hive.openBox('userBox');
      final savedEmail = box.get('email');
      final savedName = box.get('name');

      if (savedEmail != null && mounted) {
        setState(() {
          currentEmail = savedEmail;
          currentName = savedName ?? currentEmail;
        });
        print('✅ Loaded from Hive: $currentName, $currentEmail');
      }
    } catch (e) {
      print('⚠️ Error loading profile from Hive: $e');
    }
  }

  // ✅ CRITICAL: This callback receives updates from SettingsScreen
  void _handleProfileUpdate(String newName, String newEmail) async {
    print('🔄 Profile update received in dashboard');
    print('   Old: $currentName ($currentEmail)');
    print('   New: $newName ($newEmail)');

    // Check if actually changed
    if (currentName == newName && currentEmail == newEmail) {
      print('⚠️ No changes detected, skipping update');
      return;
    }

    // Update state with new values
    setState(() {
      currentEmail = newEmail;
      currentName = newEmail; // For health workers, name = email
    });

    print('✅ Dashboard state updated');
    print('✅ Profile update complete! Dashboard refreshed.');
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ HealthWorkerDashboard building with: $currentName, $currentEmail');

    final pages = [
      MonitorScreen(workerName: currentName, workerEmail: currentEmail),
      PatientsScreen(workerEmail: currentEmail),
      // ✅ CRITICAL: Use a Key that changes when email changes to force rebuild
      SettingsScreen(
        key: ValueKey('settings-$currentEmail'), // This forces rebuild when email changes
        workerName: currentName,
        workerEmail: currentEmail,
        onProfileUpdated: _handleProfileUpdate,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
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
                _buildNavItem(Icons.monitor_heart_outlined, 'Monitor', 0),
                _buildNavItem(Icons.people_outline, 'Patients', 1),
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
}