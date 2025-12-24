import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
// import 'test_data_screen.dart'; // Temporarily disabled

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final appState = Provider.of<AppState>(context); // Get AppState

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
                      child: Text(
                        appState.userProfile?['fullNameEnglish']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.userProfile?['fullNameEnglish'] ?? 'User Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.userProfile?['email'] ?? 'No email',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security Section
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'SECURITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  iconColor: const Color(0xFF00E676),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ChangePasswordDialog(),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Login',
                  iconColor: const Color(0xFF00E676),
                  trailing: BiometricSwitch(),
                ),
                _SettingsTile(
                  icon: Icons.security,
                  title: 'Two-Factor Auth',
                  iconColor: const Color(0xFF00E676),
                  subtitle: 'Off',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Two-Factor Authentication'),
                        content: const Text(
                          'Enable two-factor authentication for extra security. You\'ll need to enter a code from your phone each time you log in.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('2FA enabled!'),
                                  backgroundColor: Color(0xFF00E676),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                            ),
                            child: const Text('Enable'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // General Section
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'GENERAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  iconColor: const Color(0xFF00E676),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const NotificationsDialog(),
                    );
                  },
                ),

                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  iconColor: const Color(0xFF00E676),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Help Center'),
                        content: const SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need help?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 12),
                              Text('📧 Email: support@bankingapp.com'),
                              SizedBox(height: 8),
                              Text('📞 Phone: +20 100 123 4567'),
                              SizedBox(height: 8),
                              Text('💬 Live Chat: Available 24/7'),
                              SizedBox(height: 16),
                              Text(
                                'Common Questions:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text('• How to add a card?'),
                              Text('• How to transfer money?'),
                              Text('• How to freeze my card?'),
                              Text('• How to change my password?'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About Section
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'ABOUT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Privacy Policy',
                  iconColor: const Color(0xFF00E676),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Your privacy is important to us. We collect and use your personal information to provide banking services.\n\n'
                            '• We protect your data with encryption\n'
                            '• We never share your info without consent\n'
                            '• You can request data deletion anytime\n\n'
                            'Last updated: December 2024',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  iconColor: const Color(0xFF00E676),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Terms of Service'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'By using this app, you agree to:\n\n'
                            '• Provide accurate information\n'
                            '• Keep your account secure\n'
                            '• Use the app responsibly\n'
                            '• Comply with local laws\n\n'
                            'We reserve the right to suspend accounts that violate these terms.\n\n'
                            'Last updated: December 2024',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.apps,
                  title: 'App Version',
                  iconColor: const Color(0xFF00E676),
                  subtitle: 'v2.4.0',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Developer Tools Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Developer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Test Data Generator temporarily disabled
                  /*
                  _SettingsTile(
                    icon: Icons.science,
                    title: 'Test Data Generator',
                    iconColor: Colors.purple,
                    subtitle: 'Create sample data for testing',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TestDataScreen(),
                        ),
                      );
                    },
                  ),
                  */
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await context.read<AppState>().logout();
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }
}

// Change Password Dialog
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_newPasswordController.text == _confirmPasswordController.text &&
                _newPasswordController.text.length >= 4) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
                  backgroundColor: Color(0xFF00E676),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Passwords don\'t match or too short'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
          ),
          child: const Text('Change Password'),
        ),
      ],
    );
  }
}

// Biometric Switch Widget
class BiometricSwitch extends StatefulWidget {
  const BiometricSwitch({super.key});

  @override
  State<BiometricSwitch> createState() => _BiometricSwitchState();
}

class _BiometricSwitchState extends State<BiometricSwitch> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _enabled,
      onChanged: (value) {
        setState(() => _enabled = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_enabled ? 'Biometric login enabled' : 'Biometric login disabled'),
            backgroundColor: const Color(0xFF00E676),
          ),
        );
      },
      activeColor: const Color(0xFF00E676),
    );
  }
}

// Notifications Dialog
class NotificationsDialog extends StatefulWidget {
  const NotificationsDialog({super.key});

  @override
  State<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<NotificationsDialog> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _transactionAlerts = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.userProfile?['notificationSettings'] as Map<String, dynamic>?;
    if (settings != null) {
      _pushNotifications = settings['pushNotifications'] ?? true;
      _emailNotifications = settings['emailNotifications'] ?? true;
      _smsNotifications = settings['smsNotifications'] ?? false;
      _transactionAlerts = settings['transactionAlerts'] ?? true;
      _promotions = settings['promotions'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
              activeColor: const Color(0xFF00E676),
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive updates via email'),
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
              activeColor: const Color(0xFF00E676),
            ),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Receive text messages'),
              value: _smsNotifications,
              onChanged: (value) => setState(() => _smsNotifications = value),
              activeColor: const Color(0xFF00E676),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Transaction Alerts'),
              subtitle: const Text('Get notified of all transactions'),
              value: _transactionAlerts,
              onChanged: (value) => setState(() => _transactionAlerts = value),
              activeColor: const Color(0xFF00E676),
            ),
            SwitchListTile(
              title: const Text('Promotions'),
              subtitle: const Text('Receive offers and promotions'),
              value: _promotions,
              onChanged: (value) => setState(() => _promotions = value),
              activeColor: const Color(0xFF00E676),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final appState = context.read<AppState>();
            await appState.updateUserProfile({
              'notificationSettings': {
                'pushNotifications': _pushNotifications,
                'emailNotifications': _emailNotifications,
                'smsNotifications': _smsNotifications,
                'transactionAlerts': _transactionAlerts,
                'promotions': _promotions,
              }
            });
            
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings saved!'),
                  backgroundColor: Color(0xFF00E676),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}


