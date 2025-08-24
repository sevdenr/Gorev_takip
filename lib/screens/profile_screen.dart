import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trello/models/user.dart';
import 'package:trello/provider/app_provider.dart';
import 'package:trello/provider/localization_provider.dart';
import 'package:trello/provider/theme_provider.dart';
import 'package:trello/services/auth_service.dart';
import 'package:trello/router.dart';
import 'package:trello/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool notificationsEnabled = true;
  UserModel? _userModel;
  bool _isLoading = true;

  // İstatistikler için
  int _totalBoards = 0;
  int _completedTasks = 0;
  int _activeTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await _firestoreService.getCurrentUserData();
      final user = await _firestoreService.getUserInfo(userId);
      setState(() {
        _userModel = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Kullanıcı verisi yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final userId = await _firestoreService.getCurrentUserData();
      
      // Board sayısını getir
      final boardsSnapshot = await FirebaseFirestore.instance
          .collection('Boards')
          .where('ownerID', isEqualTo: userId)
          .get();
      
      int completedCount = 0;
      int activeCount = 0;
      
      // Her board için task istatistiklerini hesapla
      for (var boardDoc in boardsSnapshot.docs) {
        final tasksSnapshot = await FirebaseFirestore.instance
            .collection('Boards')
            .doc(boardDoc.id)
            .collection('Tasks')
            .get();
        
        for (var taskDoc in tasksSnapshot.docs) {
          final taskData = taskDoc.data();
          if (taskData['status'] == 'done') {
            completedCount++;
          } else {
            activeCount++;
          }
        }
      }
      
      setState(() {
        _totalBoards = boardsSnapshot.docs.length;
        _completedTasks = completedCount;
        _activeTasks = activeCount;
      });
      
    } catch (e) {
      print('İstatistikler yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar:AppBar(title: Text(l10n.profile, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold ),)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userModel == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold ),)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.couldNotLoadUserData),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold ),),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(isDark, l10n),
            SizedBox(height: 32),
            _buildProfileStats(isDark, l10n),
            SizedBox(height: 32),
            _buildSettingsSection(isDark, l10n, themeProvider, localizationProvider),
            SizedBox(height: 32),
            _buildAccountSection(isDark, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF3B82F6).withOpacity(0.1),
              child: Text(
                _userModel!.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _userModel!.name.isNotEmpty ? _userModel!.name : l10n.noNameSpecified,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Color(0xFFF9FAFB) : Color(0xFF111827),
              ),
            ),
            SizedBox(height: 4),
            Text(
              _userModel!.email,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStats(bool isDark, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(l10n.totalBoards, '$_totalBoards', isDark),
            ),
            Container(
              width: 1,
              height: 40,
              color: isDark ? Color(0xFF374151) : Color(0xFFE5E7EB),
            ),
            Expanded(
              child: _buildStatItem(l10n.completedTasks, '$_completedTasks', isDark),
            ),
            Container(
              width: 1,
              height: 40,
              color: isDark ? Color(0xFF374151) : Color(0xFFE5E7EB),
            ),
            Expanded(
              child: _buildStatItem(l10n.activeTasks, '$_activeTasks', isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3B82F6),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(bool isDark, AppLocalizations l10n, ThemeProvider themeProvider, LocalizationProvider localizationProvider) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              l10n.settings,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Color(0xFFF9FAFB) : Color(0xFF111827),
              ),
            ),
          ),
          _buildSettingItem(
            Icons.notifications_outlined,
            l10n.notifications,
            l10n.notificationsDesc,
            Switch(
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
            isDark,
          ),
          _buildSettingItem(
            Icons.dark_mode_outlined,
            l10n.darkTheme,
            l10n.darkThemeDesc,
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            isDark,
          ),
          _buildSettingItem(
            Icons.language_outlined,
            l10n.language,
            localizationProvider.isEnglish ? l10n.english : l10n.turkish,
            Icon(
              Icons.chevron_right,
              color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
            ),
            isDark,
            onTap: () => _showLanguageDialog(l10n, localizationProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(bool isDark, AppLocalizations l10n) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              l10n.account,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Color(0xFFF9FAFB) : Color(0xFF111827),
              ),
            ),
          ),
          _buildSettingItem(
            Icons.security_outlined,
            l10n.security,
            l10n.securityDesc,
            Icon(
              Icons.chevron_right,
              color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
            ),
            isDark,
            onTap: () => _showSecurityDialog(l10n),
          ),
          _buildSettingItem(
            Icons.help_outline,
            l10n.helpAndSupport,
            l10n.helpAndSupportDesc,
            Icon(
              Icons.chevron_right,
              color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
            ),
            isDark,
            onTap: () => _showHelpAndSupportDialog(l10n),
          ),
          _buildSettingItem(
            Icons.info_outline,
            l10n.about,
            l10n.aboutDesc,
            Icon(
              Icons.chevron_right,
              color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
            ),
            isDark,
            onTap: () => _showAboutDialog(l10n),
          ),
          _buildSettingItem(
            Icons.logout,
            l10n.logout,
            l10n.logoutDesc,
            null,
            isDark,
            onTap: () => _showLogoutDialog(l10n),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    Widget? trailing,
    bool isDark, {
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Color(0xFFEF4444) : (isDark ? Color(0xFFF9FAFB) : Color(0xFF111827)),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Color(0xFFEF4444) : (isDark ? Color(0xFFF9FAFB) : Color(0xFF111827)),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showEditProfileDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: _userModel!.name);
    final emailController = TextEditingController(text: _userModel!.email);
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editProfile),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isUpdating ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.nameRequired),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (emailController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.emailRequired),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setDialogState(() {
                  isUpdating = true;
                });

                try {
                  await _firestoreService.updateCurrentUserData(
                    nameController.text.trim(),
                    emailController.text.trim(),
                  );

                  // Kullanıcı verilerini yeniden yükle
                  await _loadUserData();

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.profileUpdated),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${l10n.errorUpdatingProfile} $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  setDialogState(() {
                    isUpdating = false;
                  });
                }
              },
              child: isUpdating 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(AppLocalizations l10n, LocalizationProvider localizationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.turkish),
              value: 'tr',
              groupValue: localizationProvider.locale.languageCode,
              onChanged: (value) async {
                await localizationProvider.setLocale(Locale('tr', 'TR'));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.languageChanged} ${l10n.turkish}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.english),
              value: 'en',
              groupValue: localizationProvider.locale.languageCode,
              onChanged: (value) async {
                await localizationProvider.setLocale(Locale('en', 'US'));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.languageChanged} ${l10n.english}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(AppLocalizations l10n) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isUpdating = false;
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.changePassword),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isUpdating ? null : () async {
                if (currentPasswordController.text.trim().isEmpty ||
                    newPasswordController.text.trim().isEmpty ||
                    confirmPasswordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.fillAllFields),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.passwordsNotMatch),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.passwordTooShort),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setDialogState(() {
                  isUpdating = true;
                });

                try {
                  await _authService.changePassword(
                    currentPasswordController.text.trim(),
                    newPasswordController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.passwordChanged),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${l10n.errorChangingPassword} $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  setDialogState(() {
                    isUpdating = false;
                  });
                }
              },
              child: isUpdating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpAndSupportDialog(AppLocalizations l10n) {
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.helpAndSupport),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.feedbackForm,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  l10n.feedbackDesc,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: l10n.feedbackPlaceholder,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isSending ? null : () async {
                if (messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.writeMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setDialogState(() {
                  isSending = true;
                });

                try {
                  await FirebaseFirestore.instance.collection('SSS').add({
                    'userEmail': _userModel!.email,
                    'message': messageController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.feedbackSent),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${l10n.errorSendingFeedback} $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  setDialogState(() {
                    isSending = false;
                  });
                }
              },
              child: isSending
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.send),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Dialog'u kapat
              try {
                await _authService.signOut();
                // Çıkış başarılıysa login sayfasına yönlendir
                if (mounted) {
                  context.go(AppRouter.login);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.errorLoggingOut} $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.about),
        content: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.aboutText,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}