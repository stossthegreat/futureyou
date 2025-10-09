import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../services/local_storage.dart';
import '../logic/habit_engine.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _notifDaily = true;
  bool _notifChat = false;
  bool _darkGlass = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  void _loadSettings() {
    _displayNameController.text = LocalStorageService.getSetting<String>('displayName', defaultValue: 'Disciplined Builder') ?? '';
    _emailController.text = LocalStorageService.getSetting<String>('email', defaultValue: 'you@example.com') ?? '';
    _notifDaily = LocalStorageService.getSetting<bool>('notifDaily', defaultValue: true) ?? true;
    _notifChat = LocalStorageService.getSetting<bool>('notifChat', defaultValue: false) ?? false;
    _darkGlass = LocalStorageService.getSetting<bool>('darkGlass', defaultValue: true) ?? true;
  }
  
  Future<void> _saveSettings() async {
    await LocalStorageService.saveSetting('displayName', _displayNameController.text);
    await LocalStorageService.saveSetting('email', _emailController.text);
    await LocalStorageService.saveSetting('notifDaily', _notifDaily);
    await LocalStorageService.saveSetting('notifChat', _notifChat);
    await LocalStorageService.saveSetting('darkGlass', _darkGlass);
    
    _showSuccessSnackBar('Settings saved successfully');
  }
  
  Future<void> _syncNow() async {
    try {
      await ref.read(habitEngineProvider.notifier).syncAllHabits();
      _showSuccessSnackBar('Sync completed successfully');
    } catch (e) {
      _showErrorSnackBar('Sync failed: $e');
    }
  }
  
  Future<void> _exportData() async {
    try {
      // TODO: Implement actual file export
      // final habits = LocalStorageService.getAllHabits();
      // final data = {
      //   'habits': habits.map((h) => h.toJson()).toList(),
      //   'exportDate': DateTime.now().toIso8601String(),
      //   'version': '1.0.0',
      // };
      _showSuccessSnackBar('Export functionality coming soon');
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    }
  }
  
  Future<void> _resetLocalData() async {
    final confirmed = await _showConfirmationDialog(
      'Reset Local Data',
      'This will delete all your habits and settings. This action cannot be undone. Are you sure?',
    );
    
    if (confirmed) {
      await LocalStorageService.clearAllHabits();
      await LocalStorageService.clearAllSettings();
      
      // Reload habit engine
      ref.invalidate(habitEngineProvider);
      
      _showSuccessSnackBar('Local data reset successfully');
    }
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
      ),
    );
  }
  
  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.baseDark2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: Text(title, style: AppTextStyles.h3),
        content: Text(
          content,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          GlassButton(
            onPressed: () => Navigator.of(context).pop(true),
            backgroundColor: AppColors.error.withOpacity(0.2),
            borderColor: AppColors.error.withOpacity(0.3),
            child: Text(
              'Confirm',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final habitEngineState = ref.watch(habitEngineProvider);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Account section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                Column(
                  children: [
                    _buildInputField(
                      'Display Name',
                      _displayNameController,
                      LucideIcons.user,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInputField(
                      'Email',
                      _emailController,
                      LucideIcons.mail,
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: _saveSettings,
                    child: Text(
                      'Save Changes',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Notifications section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                _buildToggleSetting(
                  'Daily Brief',
                  'Morning summary of today\'s commitments',
                  _notifDaily,
                  (value) => setState(() => _notifDaily = value),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                _buildToggleSetting(
                  'Chat Mentions',
                  'Ping when Future You nudges you',
                  _notifChat,
                  (value) => setState(() => _notifChat = value),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Appearance section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                _buildToggleSetting(
                  'Dark Glass Theme',
                  'Glassy neon with emerald accents',
                  _darkGlass,
                  (value) => setState(() => _darkGlass = value),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Data & Privacy section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data & Privacy',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: _exportData,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.download,
                              size: 16,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Export Data (JSON)',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: _resetLocalData,
                        backgroundColor: AppColors.error.withOpacity(0.1),
                        borderColor: AppColors.error.withOpacity(0.3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reset Local Data',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Sync section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sync your habits and progress with the cloud',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: habitEngineState.isSyncing ? null : _syncNow,
                    gradient: AppColors.primaryGradient,
                    child: habitEngineState.isSyncing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Syncing...',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.refreshCw,
                                size: 16,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sync Now',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Subscription section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You\'re on Free. Unlock Pro for voice mentors, smart forecasts, and unlimited What-If.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: () {
                      // TODO: Implement subscription upgrade
                      _showSuccessSnackBar('Subscription upgrade coming soon');
                    },
                    gradient: AppColors.primaryGradient,
                    child: Text(
                      'Upgrade to Pro',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // About section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Future U OS — build integrity through daily commitments. v1.0.0 Flutter.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom padding for navigation
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
  
  Widget _buildToggleSetting(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textQuaternary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
