import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'healthworker_dashboard.dart';
import 'login.dart';
import 'esp32_connection_service.dart';
import 'api_config.dart'; // ✅ Make sure this import exists

class SettingsScreen extends StatefulWidget {
  final String workerName;
  final String workerEmail;
  final Function(String, String)? onProfileUpdated;

  const SettingsScreen({
    Key? key,
    required this.workerName,
    required this.workerEmail,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Esp32ConnectionService _esp32Service = Esp32ConnectionService();
  late String currentName;
  late String currentEmail;

  @override
  void initState() {
    super.initState();
    currentName = widget.workerName;
    currentEmail = widget.workerEmail;
    print('🔧 SettingsScreen initialized: $currentName, $currentEmail');
  }

  // ✅ This ensures the widget updates when parent changes
  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workerName != widget.workerName || oldWidget.workerEmail != widget.workerEmail) {
      setState(() {
        currentName = widget.workerName;
        currentEmail = widget.workerEmail;
      });
      print('✅ SettingsScreen synced with new data: $currentName, $currentEmail');
    }
  }

  void _updateProfile(String newName, String newEmail) {
    print('📤 Sending profile update to parent: $newName, $newEmail');
    setState(() {
      currentName = newName;
      currentEmail = newEmail;
    });
    widget.onProfileUpdated?.call(newName, newEmail);
    print('✅ Profile update callback triggered');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Compact Profile Section
            InkWell(
              onTap: () => _navigateToProfile(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: Colors.white,
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF1848A0).withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Color(0xFF1848A0),
                              child: Icon(
                                Icons.local_hospital,
                                color: Colors.white,
                                size: 30,
                              ),
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
                            'Health Worker',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            currentEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F8C8D),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Settings Options
            _buildSettingsSection('Information', [
              _buildSettingItem(
                Icons.info_outline,
                'About HealthX',
                'Learn more about HealthX',
                    () => _navigateToAbout(),
              ),
              _buildSettingItem(
                Icons.description_outlined,
                'Terms & Conditions',
                'Read our terms',
                    () => _navigateToTerms(),
              ),
              _buildSettingItem(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                'Read our privacy policy',
                    () => _navigateToPrivacy(),
              ),
            ]),

            SizedBox(height: 12),

            _buildSettingsSection('Support', [
              _buildSettingItem(
                Icons.help_outline,
                'Help & Support',
                'Get help and contact us',
                    () => _navigateToHelp(),
              ),
            ]),

            SizedBox(height: 12),

            _buildSettingsSection('About', [
              _buildSettingItem(
                Icons.people_outline,
                'Developers',
                'Meet the team',
                    () => _navigateToDevelopers(),
              ),
            ]),

            SizedBox(height: 12),

            // Logout Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              width: MediaQuery.of(context).size.width * 0.5,
              height: 50,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE74C3C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F8C8D),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF5F6FA), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF1848A0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFF1848A0), size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  Future<void> _navigateToProfile() async {
    print('📱 Navigating to profile screen');
    print('   Passing data: $currentName, $currentEmail');

    // ✅ Get the user ID from Hive
    final box = await Hive.openBox('userBox');
    final userId = box.get('userId', defaultValue: 0);

    // Create a local function to handle the update
    void handleUpdate(String newName, String newEmail) {
      print('📥 Profile update received via callback: $newName, $newEmail');

      // Update local state
      if (mounted) {
        setState(() {
          currentName = newName;
          currentEmail = newEmail;
        });
        print('✅ Local state updated: $currentName, $currentEmail');
      }

      // Notify parent
      widget.onProfileUpdated?.call(newName, newEmail);
      print('✅ Parent notified');
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          workerName: currentName,
          workerEmail: currentEmail,
          userId: userId,
          onProfileUpdated: handleUpdate, // ✅ Pass the callback
        ),
      ),
    );

    print('🔙 Returned from profile screen');
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AboutScreen()),
    );
  }

  void _navigateToTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TermsScreen()),
    );
  }

  void _navigateToPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivacyScreen()),
    );
  }

  void _navigateToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HelpScreen()),
    );
  }

  void _navigateToDevelopers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DevelopersScreen()),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFE74C3C)),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF7F8C8D))),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear Hive data on logout
              final box = await Hive.openBox('userBox');
              await box.clear();

              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROFILE SCREEN - COMPLETE REWRITE WITH PROPER API INTEGRATION
// ============================================================================
class ProfileScreen extends StatefulWidget {
  final String workerName;
  final String workerEmail;
  final int userId;
  final Function(String, String)? onProfileUpdated;

  const ProfileScreen({
    Key? key,
    required this.workerName,
    required this.workerEmail,
    required this.userId,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String currentName;
  late String currentEmail;

  @override
  void initState() {
    super.initState();
    currentName = widget.workerEmail; // For health workers, name = email
    currentEmail = widget.workerEmail;
    print('👤 ProfileScreen initialized: $currentEmail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        title: Text(
          'Profile Information',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF1848A0).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Color(0xFF1848A0),
                      child: Icon(Icons.local_hospital, color: Colors.white, size: 60),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 24),
            _buildProfileInfoItem(Icons.badge, 'Role', 'Health Worker'),
            _buildProfileInfoItem(Icons.email, 'Email Address', currentEmail),
            _buildProfileInfoItem(Icons.verified_user, 'Status', 'Active'),
            SizedBox(height: 24),
            _buildChangePasswordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF1848A0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFF1848A0), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _showChangePasswordDialog,
        icon: Icon(Icons.lock_outline),
        label: Text(
          'Change Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1848A0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // EDIT PROFILE DIALOG
  // ============================================================================
  void _showEditProfileDialog() {
    final emailController = TextEditingController(text: currentEmail);
    bool isLoading = false;

    // ✅ Store the screen context before showing dialog
    final screenContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF1848A0)),
              SizedBox(width: 12),
              Text('Edit Profile'),
            ],
          ),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF7F8C8D))),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => _handleProfileUpdate(
                dialogContext,
                screenContext,
                setDialogState,
                emailController,
                    () => setDialogState(() => isLoading = true),
                    () => setDialogState(() => isLoading = false),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1848A0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProfileUpdate(
      BuildContext dialogContext,
      BuildContext screenContext,
      StateSetter setDialogState,
      TextEditingController emailController,
      VoidCallback setLoading,
      VoidCallback clearLoading,
      ) async {
    setLoading();

    final email = emailController.text.trim();

    // Validation
    if (email.isEmpty) {
      clearLoading();
      _showMessage('Please enter an email', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      clearLoading();
      _showMessage('Please enter a valid email', isError: true);
      return;
    }

    try {
      print('🌐 Sending profile update request to server');
      print('   Old email: $currentEmail');
      print('   New email: $email');
      print('   User ID: ${widget.userId}');

      // ✅ 1. UPDATE DATABASE (with old_email for cascading update)
      final response = await http.post(
        Uri.parse(ApiConfig.updateProfileEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'update_profile',
          'user_id': widget.userId,
          'name': email, // For health workers, name = email
          'email': email,
          'old_email': currentEmail, // ✅ Send old email for cascading update
          'user_type': 'healthworker',
        }),
      );

      final data = jsonDecode(response.body);
      print('📥 Server response: $data');

      if (data['success']) {
        print('✅ Server confirmed profile update');

        // ✅ 2. UPDATE HIVE LOCAL STORAGE
        print('💾 Updating Hive storage...');
        await _updateHiveProfile(data['email']);
        print('✅ Hive storage updated');

        // ✅ 3. UPDATE UI STATE
        setState(() {
          currentName = data['email'];
          currentEmail = data['email'];
        });

        print('✅ Profile updated successfully');
        print('   New email: ${data['email']}');

        // ✅ Close dialog
        Navigator.pop(dialogContext);

        // ✅ Call the callback directly
        print('🔄 Calling onProfileUpdated callback directly...');
        widget.onProfileUpdated?.call(data['email'], data['email']);

        // Wait a moment
        await Future.delayed(Duration(milliseconds: 100));

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(screenContext).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        // Return to settings
        print('🔙 Returning to settings...');
        if (Navigator.canPop(screenContext)) {
          Navigator.pop(screenContext);
        }
      } else {
        clearLoading();
        _showMessage(data['message'], isError: true);
      }
    } catch (e) {
      clearLoading();
      print('❌ Connection error: $e');
      _showMessage('Connection error: $e', isError: true);
    }
  }

  Future<void> _updateHiveProfile(String email) async {
    try {
      final box = await Hive.openBox('userBox');

      // Update individual fields
      await box.put('name', email);
      await box.put('email', email);

      // Update entire user object
      dynamic userDataRaw = box.get('userData', defaultValue: {});
      Map<String, dynamic> userData = Map<String, dynamic>.from(userDataRaw as Map);
      userData['name'] = email;
      userData['email'] = email;
      userData['lastUpdated'] = DateTime.now().toIso8601String();
      await box.put('userData', userData);

      print('💾 Hive updated successfully: $email');
    } catch (e) {
      print('⚠️ Hive update error: $e');
    }
  }

  // ============================================================================
  // CHANGE PASSWORD DIALOG
  // ============================================================================
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF1848A0)),
              SizedBox(width: 12),
              Text('Change Password'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPasswordField(
                  controller: currentPasswordController,
                  label: 'Current Password',
                  icon: Icons.lock,
                  obscureText: !showCurrentPassword,
                  onToggleVisibility: () => setDialogState(
                        () => showCurrentPassword = !showCurrentPassword,
                  ),
                ),
                SizedBox(height: 16),
                _buildPasswordField(
                  controller: newPasswordController,
                  label: 'New Password',
                  icon: Icons.lock_outline,
                  obscureText: !showNewPassword,
                  onToggleVisibility: () => setDialogState(
                        () => showNewPassword = !showNewPassword,
                  ),
                ),
                SizedBox(height: 16),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: 'Confirm New Password',
                  icon: Icons.lock_outline,
                  obscureText: !showConfirmPassword,
                  onToggleVisibility: () => setDialogState(
                        () => showConfirmPassword = !showConfirmPassword,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF7F8C8D))),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => _handlePasswordChange(
                context,
                setDialogState,
                currentPasswordController,
                newPasswordController,
                confirmPasswordController,
                    () => setDialogState(() => isLoading = true),
                    () => setDialogState(() => isLoading = false),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1848A0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handlePasswordChange(
      BuildContext context,
      StateSetter setDialogState,
      TextEditingController currentPasswordController,
      TextEditingController newPasswordController,
      TextEditingController confirmPasswordController,
      VoidCallback setLoading,
      VoidCallback clearLoading,
      ) async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please fill all fields', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showMessage('New password must be at least 6 characters', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('New passwords do not match', isError: true);
      return;
    }

    setLoading();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateProfileEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'change_password',
          'user_id': widget.userId,
          'current_password': currentPassword,
          'new_password': newPassword,
          'user_type': 'healthworker',
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        await _updatePasswordChangeTimestamp();

        if (!mounted) return;
        Navigator.pop(context);
        _showMessage(data['message']);
      } else {
        clearLoading();
        _showMessage(data['message'], isError: true);
      }
    } catch (e) {
      clearLoading();
      _showMessage('Connection error: $e', isError: true);
    }
  }

  Future<void> _updatePasswordChangeTimestamp() async {
    try {
      final box = await Hive.openBox('userBox');
      await box.put('lastPasswordChange', DateTime.now().toIso8601String());
    } catch (e) {
      print('Hive timestamp update error: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFEF4444) : Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// Keep all the other screens the same (AboutScreen, TermsScreen, etc.)
class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        title: Text(
          'About HealthX',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.local_hospital, color: Color(0xFF1848A0), size: 100);
                },
              ),
            ),
            SizedBox(height: 24),
            Text(
              'HealthX is a low-cost IoT-based health monitoring system developed to address critical gaps in healthcare accessibility for remote communities. Unlike existing solutions, our system emphasizes affordability, portability, and comprehensive real-time monitoring.',
              style: TextStyle(fontSize: 15, color: Color(0xFF2C3E50), height: 1.6),
            ),
            SizedBox(height: 16),
            Text(
              'Utilizing an ESP32 microcontroller integrated with multiple precision sensors, HealthX monitors essential health parameters including oxygen saturation (SpO2), heart rate, body temperature, blood pressure, and body mass index (BMI). These parameters were specifically selected as they represent the most fundamental indicators of an individual\'s physiological condition.',
              style: TextStyle(fontSize: 15, color: Color(0xFF2C3E50), height: 1.6),
            ),
            SizedBox(height: 16),
            Text(
              'Our system operates through an integrated workflow combining hardware and software components, featuring a Flutter-based mobile application for dual user roles and a PHP/MySQL web dashboard for healthcare professionals to review information and provide timely medical guidance.',
              style: TextStyle(fontSize: 15, color: Color(0xFF2C3E50), height: 1.6),
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                '© 2025 HealthX. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFDF5F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTermSection('1. Acceptance of Terms',
                'By accessing and using HealthX, you accept and agree to be bound by the terms and provision of this agreement.'),
            _buildTermSection('2. Use License',
                'Permission is granted to temporarily use HealthX for personal, non-commercial health monitoring purposes only.'),
            _buildTermSection('3. Medical Disclaimer',
                'HealthX is designed to assist in health monitoring but should not replace professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider.'),
            _buildTermSection('4. Data Accuracy',
                'While we strive for accuracy, HealthX does not guarantee that the health data readings will be completely accurate or error-free. The system should be used as a supplementary tool.'),
            _buildTermSection('5. User Responsibilities',
                'Users are responsible for properly using the device, maintaining equipment, and reporting any technical issues or inaccuracies.'),
            _buildTermSection('6. Limitations',
                'HealthX and its operators shall not be liable for any damages arising from the use of or inability to use the system.'),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        title: Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTermSection('1. Information We Collect',
                'We collect health data including SpO2, heart rate, body temperature, blood pressure, and BMI readings, along with user account information (name, email) for system access.'),
            _buildTermSection('2. How We Use Your Information',
                'Your health data is used to provide real-time monitoring, generate health reports, enable healthcare professional consultations, and improve system functionality.'),
            _buildTermSection('3. Data Storage and Security',
                'All data is stored securely in our encrypted database. We implement industry-standard security measures to protect your personal and health information.'),
            _buildTermSection('4. Data Sharing',
                'Your health data is only accessible to you and authorized healthcare professionals assigned to your care. We do not sell or share your data with third parties.'),
            _buildTermSection('5. Your Rights',
                'You have the right to access, correct, or delete your personal data. You may contact us to exercise these rights.'),
            _buildTermSection('6. Data Retention',
                'We retain your health data for as long as your account is active or as needed to provide services. You may request deletion at any time.'),
            _buildTermSection('7. Changes to Privacy Policy',
                'We may update this policy periodically. We will notify users of any significant changes.'),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        title: Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help? We\'re here to assist you!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 24),
            _buildHelpSection(
              Icons.question_answer,
              'Frequently Asked Questions',
              'Find answers to common questions about using HealthX.',
            ),
            _buildHelpSection(
              Icons.book,
              'User Guide',
              'Learn how to use all features of the HealthX system.',
            ),
            _buildHelpSection(
              Icons.bug_report,
              'Report an Issue',
              'Encountered a problem? Let us know so we can fix it.',
            ),
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 24),
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 16),
            _buildContactItem(Icons.email, 'Email', 'healthxinnovation@gmail.com'),
            _buildContactItem(Icons.phone, 'Phone', '+63 999 392 1960\n+63 933 819 7734\n+63 908 968 8524\n+63 999 187 0384'),
            _buildContactItem(Icons.access_time, 'Support Hours', 'Monday - Friday: 7:00 AM - 5:00 PM'),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(IconData icon, String title, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF1848A0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFF1848A0), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF1848A0), size: 20),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DevelopersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1848A0),
        title: Text(
          'Developers',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Meet the Team',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 24),
            _buildDeveloperCard('Cayabyab, Matt Julius M.', 'assets/images/cayabyab.jpg'),
            _buildDeveloperCard('Deang, Ronnel O.', 'assets/images/deang.jpg'),
            _buildDeveloperCard('Digman, Christian D.', 'assets/images/digman.jpg'),
            _buildDeveloperCard('Paragas, John Ian Joseph M.', 'assets/images/paragas.jpg'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(String name, String imagePath) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF1848A0).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFF1848A0).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Color(0xFF1848A0),
                    child: Center(
                      child: Text(
                        name[0],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}