import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'login.dart';
import 'api_config.dart';

// ============================================================================
// APP COLORS
// ============================================================================
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

// ============================================================================
// USER SETTINGS SCREEN
// ============================================================================
class UserSettingsScreen extends StatefulWidget {
  final String name;
  final String email;
  final int userId;
  final String userType;
  final Function(String, String)? onProfileUpdated;

  const UserSettingsScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.userId,
    this.userType = 'user',
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  late String currentName;
  late String currentEmail;

  @override
  void initState() {
    super.initState();
    currentName = widget.name;
    currentEmail = widget.email;
    print('🔧 UserSettingsScreen initialized: $currentName, $currentEmail');
  }

  // ✅ This ensures the widget updates when parent changes
  @override
  void didUpdateWidget(UserSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name || oldWidget.email != widget.email) {
      setState(() {
        currentName = widget.name;
        currentEmail = widget.email;
      });
      print('✅ UserSettingsScreen synced with new data: $currentName, $currentEmail');
    }
  }

  // Update profile callback
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
    // Debug logging to track rebuilds
    print('🏗️ UserSettingsScreen building:');
    print('   widget.name: ${widget.name}');
    print('   widget.email: ${widget.email}');
    print('   currentName: $currentName');
    print('   currentEmail: $currentEmail');

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildInformationSection(),
          const SizedBox(height: 12),
          _buildSupportSection(),
          const SizedBox(height: 12),
          _buildAboutSection(),
          const SizedBox(height: 12),
          _buildLogoutButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================================
  // UI COMPONENTS
  // ============================================================================

  Widget _buildProfileHeader() {
    return InkWell(
      onTap: _navigateToProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: AppColors.white,
        child: Row(
          children: [
            _buildProfileAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.white,
        size: 30,
      ),
    );
  }

  Widget _buildInformationSection() {
    return _buildSettingsSection('Information', [
      _buildSettingItem(
        Icons.info_outline,
        'About HealthX',
        'Learn more about HealthX',
        _navigateToAbout,
      ),
      _buildSettingItem(
        Icons.description_outlined,
        'Terms & Conditions',
        'Read our terms',
        _navigateToTerms,
      ),
      _buildSettingItem(
        Icons.privacy_tip_outlined,
        'Privacy Policy',
        'Read our privacy policy',
        _navigateToPrivacy,
      ),
    ]);
  }

  Widget _buildSupportSection() {
    return _buildSettingsSection('Support', [
      _buildSettingItem(
        Icons.help_outline,
        'Help & Support',
        'Get help and contact us',
        _navigateToHelp,
      ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection('About', [
      _buildSettingItem(
        Icons.people_outline,
        'Developers',
        'Meet the team',
        _navigateToDevelopers,
      ),
    ]);
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          color: AppColors.white,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.background, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
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

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      width: MediaQuery.of(context).size.width * 0.5,
      height: 50,
      child: ElevatedButton(
        onPressed: _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: AppColors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // NAVIGATION METHODS
  // ============================================================================

  Future<void> _navigateToProfile() async {
    print('📱 Navigating to profile screen');
    print('   Passing data: $currentName, $currentEmail');

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
        builder: (context) => UserProfileScreen(
          name: currentName,
          email: currentEmail,
          userId: widget.userId,
          userType: widget.userType,
          onProfileUpdated: handleUpdate, // ✅ Pass the callback
        ),
      ),
    );

    print('🔙 Returned from profile screen');
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  void _navigateToTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsScreen()),
    );
  }

  void _navigateToPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
    );
  }

  void _navigateToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }

  void _navigateToDevelopers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DevelopersScreen()),
    );
  }

  // ============================================================================
  // LOGOUT
  // ============================================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: const [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
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
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// USER PROFILE SCREEN
// ============================================================================
class UserProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final int userId;
  final String userType;
  final Function(String, String)? onProfileUpdated;

  const UserProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.userId,
    this.userType = 'user',
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late String currentName;
  late String currentEmail;

  @override
  void initState() {
    super.initState();
    currentName = widget.name;
    currentEmail = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Profile Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.white),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileAvatar(),
            const SizedBox(height: 24),
            _buildProfileInfoItem(Icons.person, 'Name', currentName),
            _buildProfileInfoItem(Icons.email, 'Email Address', currentEmail),
            _buildProfileInfoItem(
              Icons.verified_user,
              'Status',
              'Active User',
            ),
            const SizedBox(height: 24),
            _buildChangePasswordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.white,
        size: 60,
      ),
    );
  }

  Widget _buildProfileInfoItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
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
        icon: const Icon(Icons.lock_outline),
        label: const Text(
          'Change Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
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
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    bool isLoading = false;

    // ✅ CRITICAL: Store the screen context before showing dialog
    final screenContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.edit, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Edit Profile'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.userType != 'healthworker')
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (widget.userType != 'healthworker')
                  const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => _handleProfileUpdate(
                dialogContext, // Dialog context to close dialog
                screenContext, // Screen context to pop back to settings
                setDialogState,
                nameController,
                emailController,
                    () => setDialogState(() => isLoading = true),
                    () => setDialogState(() => isLoading = false),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
                  : const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProfileUpdate(
      BuildContext dialogContext,  // Context for closing dialog
      BuildContext screenContext,  // Context for returning to settings
      StateSetter setDialogState,
      TextEditingController nameController,
      TextEditingController emailController,
      VoidCallback setLoading,
      VoidCallback clearLoading,
      ) async {
    setLoading();

    final name = widget.userType == 'healthworker'
        ? currentName
        : nameController.text.trim();
    final email = emailController.text.trim();

    // Validation
    if (name.isEmpty || email.isEmpty) {
      clearLoading();
      _showMessage('Please fill all fields', isError: true);
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

      // 1. UPDATE DATABASE (with old_email for cascading update)
      final response = await http.post(
        Uri.parse(ApiConfig.updateProfileEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'update_profile',
          'user_id': widget.userId,
          'name': name,
          'email': email,
          'old_email': currentEmail, // ✅ Send old email for cascading update
          'user_type': widget.userType,
        }),
      );

      final data = jsonDecode(response.body);
      print('📥 Server response: $data');

      if (data['success']) {
        print('✅ Server confirmed profile update');

        // 2. UPDATE HIVE LOCAL STORAGE (wait for completion)
        print('💾 Updating Hive storage...');
        await _updateHiveProfile(data['name'], data['email']);
        print('✅ Hive storage updated');

        // 3. UPDATE UI STATE
        setState(() {
          currentName = data['name'];
          currentEmail = data['email'];
        });

        print('✅ Profile updated successfully');
        print('   New name: ${data['name']}');
        print('   New email: ${data['email']}');

        // ✅ Close dialog using dialog context
        Navigator.pop(dialogContext);

        // ✅ CRITICAL: Call the callback directly (not via Navigator)
        print('🔄 Calling onProfileUpdated callback directly...');
        widget.onProfileUpdated?.call(data['name'], data['email']);

        // Wait a moment to let the callback complete
        await Future.delayed(Duration(milliseconds: 100));

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(screenContext).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        // Return to settings (without data, callback already handled it)
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

  Future<void> _updateHiveProfile(String name, String email) async {
    try {
      final box = await Hive.openBox('userBox');

      // Update individual fields
      await box.put('name', name);
      await box.put('email', email);

      // Update entire user object (fix type casting issue)
      dynamic userDataRaw = box.get('userData', defaultValue: {});
      Map<String, dynamic> userData = Map<String, dynamic>.from(userDataRaw as Map);
      userData['name'] = name;
      userData['email'] = email;
      userData['lastUpdated'] = DateTime.now().toIso8601String();
      await box.put('userData', userData);

      print('💾 Hive updated successfully: $name, $email');
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.lock_outline, color: AppColors.primary),
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
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: newPasswordController,
                  label: 'New Password',
                  icon: Icons.lock_outline,
                  obscureText: !showNewPassword,
                  onToggleVisibility: () => setDialogState(
                        () => showNewPassword = !showNewPassword,
                  ),
                ),
                const SizedBox(height: 16),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textLight),
              ),
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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
                  : const Text(
                'Change Password',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
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
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill all fields', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showMessage(
        'New password must be at least 6 characters',
        isError: true,
      );
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
          'user_type': widget.userType,
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
      await box.put(
        'lastPasswordChange',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Hive timestamp update error: $e');
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
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ... (Keep all other screens: AboutScreen, TermsScreen, PrivacyScreen, HelpScreen, DevelopersScreen the same)

// ============================================================================
// ABOUT SCREEN
// ============================================================================
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'About HealthX',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildLogo()),
            const SizedBox(height: 24),
            _buildAboutText(),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                '© 2025 HealthX. All rights reserved.',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      width: 100,
      height: 100,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Icon(
            Icons.health_and_safety,
            color: AppColors.white,
            size: 60,
          ),
        );
      },
    );
  }

  Widget _buildAboutText() {
    const textStyle = TextStyle(
      fontSize: 15,
      color: AppColors.textDark,
      height: 1.6,
    );

    return Column(
      children: const [
        Text(
          'HealthX is a low-cost IoT-based health monitoring system developed to address critical gaps in healthcare accessibility for remote communities. Unlike existing solutions, our system emphasizes affordability, portability, and comprehensive real-time monitoring.',
          style: textStyle,
        ),
        SizedBox(height: 16),
        Text(
          'Utilizing an ESP32 microcontroller integrated with multiple precision sensors, HealthX monitors essential health parameters including oxygen saturation (SpO2), heart rate, body temperature, blood pressure, and body mass index (BMI). These parameters were specifically selected as they represent the most fundamental indicators of an individual\'s physiological condition.',
          style: textStyle,
        ),
        SizedBox(height: 16),
        Text(
          'Our system operates through an integrated workflow combining hardware and software components, featuring a Flutter-based mobile application for dual user roles and a PHP/MySQL web dashboard for healthcare professionals to review information and provide timely medical guidance.',
          style: textStyle,
        ),
      ],
    );
  }
}

// ============================================================================
// TERMS & CONDITIONS SCREEN
// ============================================================================
class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTermSection(
              '1. Acceptance of Terms',
              'By accessing and using HealthX, you accept and agree to be bound by the terms and provision of this agreement.',
            ),
            _buildTermSection(
              '2. Use License',
              'Permission is granted to temporarily use HealthX for personal, non-commercial health monitoring purposes only.',
            ),
            _buildTermSection(
              '3. Medical Disclaimer',
              'HealthX is designed to assist in health monitoring but should not replace professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider.',
            ),
            _buildTermSection(
              '4. Data Accuracy',
              'While we strive for accuracy, HealthX does not guarantee that the health data readings will be completely accurate or error-free. The system should be used as a supplementary tool.',
            ),
            _buildTermSection(
              '5. User Responsibilities',
              'Users are responsible for properly using the device, maintaining equipment, and reporting any technical issues or inaccuracies.',
            ),
            _buildTermSection(
              '6. Limitations',
              'HealthX and its operators shall not be liable for any damages arising from the use of or inability to use the system.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PRIVACY POLICY SCREEN
// ============================================================================
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTermSection(
              '1. Information We Collect',
              'We collect health data including SpO2, heart rate, body temperature, blood pressure, and BMI readings, along with user account information (name, email) for system access.',
            ),
            _buildTermSection(
              '2. How We Use Your Information',
              'Your health data is used to provide real-time monitoring, generate health reports, enable healthcare professional consultations, and improve system functionality.',
            ),
            _buildTermSection(
              '3. Data Storage and Security',
              'All data is stored securely in our encrypted database. We implement industry-standard security measures to protect your personal and health information.',
            ),
            _buildTermSection(
              '4. Data Sharing',
              'Your health data is only accessible to you and authorized healthcare professionals assigned to your care. We do not sell or share your data with third parties.',
            ),
            _buildTermSection(
              '5. Your Rights',
              'You have the right to access, correct, or delete your personal data. You may contact us to exercise these rights.',
            ),
            _buildTermSection(
              '6. Data Retention',
              'We retain your health data for as long as your account is active or as needed to provide services. You may request deletion at any time.',
            ),
            _buildTermSection(
              '7. Changes to Privacy Policy',
              'We may update this policy periodically. We will notify users of any significant changes.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELP & SUPPORT SCREEN
// ============================================================================
class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help? We\'re here to assist you!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.email,
              'Email',
              'healthxinnovation@gmail.com',
            ),
            _buildContactItem(
              Icons.phone,
              'Phone',
              '+63 999 392 1960\n+63 933 819 7734\n+63 908 968 8524\n+63 999 187 0384',
            ),
            _buildContactItem(
              Icons.access_time,
              'Support Hours',
              'Monday - Friday: 7:00 AM - 5:00 PM',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DEVELOPERS SCREEN
// ============================================================================
class DevelopersScreen extends StatelessWidget {
  const DevelopersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Developers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Meet the Team',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary,
                    child: Center(
                      child: Text(
                        name[0],
                        style: const TextStyle(
                          color: AppColors.white,
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}