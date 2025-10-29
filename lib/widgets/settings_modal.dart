import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../services/local_storage.dart';
import 'glass_card.dart';

class DesignTokens {
  static const accentColor = AppColors.emerald;
  static final darkGradient = AppColors.backgroundGradient;
}

class LocalStorage {
  static Future<void> clearAll() async {
    await LocalStorageService.clearAll();
  }
}

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  String _displayName = 'Future You';
  String _email = '';
  bool _briefsEnabled = true;
  bool _nudgesEnabled = true;
  bool _debriefsEnabled = true;
  String _tone = 'balanced';
  int _intensity = 2;
  bool _syncing = false;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load from local storage or user profile
    setState(() {
      _displayName = 'Future You';
      _email = 'user@example.com';
    });
  }

  Future<void> _saveSettings() async {
    // TODO: Save to local storage and sync to backend
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: DesignTokens.accentColor,
      ),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    
    try {
      // TODO: Implement actual sync
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _lastSyncTime = DateTime.now();
        _syncing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed'),
            backgroundColor: DesignTokens.accentColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _syncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export not implemented yet'),
      ),
    );
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Reset All Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete all habits, completions, and messages. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalStorage.clearAll();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        gradient: DesignTokens.darkGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.settings,
                  color: DesignTokens.accentColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _SectionHeader('Profile'),
                const SizedBox(height: 12),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.person_outline,
                          label: 'Display Name',
                          value: _displayName,
                          onTap: () {
                            // TODO: Edit name
                          },
                        ),
                        const Divider(color: Colors.white10),
                        _SettingRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _email,
                          onTap: () {
                            // TODO: Edit email
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader('Notifications'),
                const SizedBox(height: 12),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ToggleRow(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Morning Briefs',
                          value: _briefsEnabled,
                          onChanged: (val) => setState(() => _briefsEnabled = val),
                        ),
                        const Divider(color: Colors.white10),
                        _ToggleRow(
                          icon: Icons.notifications_active_outlined,
                          label: 'Nudges',
                          value: _nudgesEnabled,
                          onChanged: (val) => setState(() => _nudgesEnabled = val),
                        ),
                        const Divider(color: Colors.white10),
                        _ToggleRow(
                          icon: Icons.nightlight_outlined,
                          label: 'Evening Debriefs',
                          value: _debriefsEnabled,
                          onChanged: (val) => setState(() => _debriefsEnabled = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader('AI Preferences'),
                const SizedBox(height: 12),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _PickerRow(
                          icon: Icons.tune,
                          label: 'Tone',
                          value: _tone,
                          options: const ['light', 'balanced', 'strict'],
                          onChanged: (val) => setState(() => _tone = val),
                        ),
                        const Divider(color: Colors.white10),
                        _SliderRow(
                          icon: Icons.bolt_outlined,
                          label: 'Intensity',
                          value: _intensity,
                          min: 1,
                          max: 3,
                          onChanged: (val) => setState(() => _intensity = val.round()),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader('Sync & Data'),
                const SizedBox(height: 12),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ActionRow(
                          icon: Icons.sync,
                          label: 'Sync Now',
                          subtitle: _lastSyncTime != null
                              ? 'Last sync: ${_formatSyncTime(_lastSyncTime!)}'
                              : 'Never synced',
                          loading: _syncing,
                          onTap: _syncNow,
                        ),
                        const Divider(color: Colors.white10),
                        _ActionRow(
                          icon: Icons.download_outlined,
                          label: 'Export Data',
                          subtitle: 'Download JSON backup',
                          onTap: _exportData,
                        ),
                        const Divider(color: Colors.white10),
                        _ActionRow(
                          icon: Icons.delete_outline,
                          label: 'Reset All Data',
                          subtitle: 'Clear everything',
                          isDestructive: true,
                          onTap: _resetData,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader('About'),
                const SizedBox(height: 12),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.info_outline,
                          label: 'Version',
                          value: '1.0.0',
                        ),
                        const Divider(color: Colors.white10),
                        _SettingRow(
                          icon: Icons.help_outline,
                          label: 'Support',
                          value: 'support@futureyou.com',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: DesignTokens.accentColor,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: DesignTokens.accentColor,
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: (val) => onChanged(val!),
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            underline: Container(),
            items: options.map((opt) {
              return DropdownMenuItem(
                value: opt,
                child: Text(opt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  color: DesignTokens.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: DesignTokens.accentColor,
            inactiveColor: Colors.white.withOpacity(0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool loading;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDestructive ? Colors.red : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(DesignTokens.accentColor),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

