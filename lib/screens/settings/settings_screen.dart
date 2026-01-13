import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.emergency),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.backgroundDark : Colors.white)
            .withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            _SectionHeader(title: 'Appearance', isDark: isDark),
            _buildAppearanceSection(context, ref, themeMode, isDark),

            const SizedBox(height: 24),

            // Language Section
            _SectionHeader(title: 'Language', isDark: isDark),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.translate,
                  iconBgColor: const Color(0xFFDBEAFE),
                  iconColor: AppColors.primaryBlue,
                  title: 'App Language',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'English',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        size: 18,
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Language picker
                  },
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notifications Section
            _SectionHeader(title: 'Notifications', isDark: isDark),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.groups,
                  iconBgColor: const Color(0xFFFED7AA),
                  iconColor: Colors.orange[700]!,
                  title: 'Crowd Level Alerts',
                  subtitle: 'Real-time Ghat updates',
                  trailing: _CustomSwitch(value: true, onChanged: (_) {}),
                  isDark: isDark,
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.event_available,
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconColor: AppColors.success,
                  title: 'Ritual Reminders',
                  trailing: _CustomSwitch(value: false, onChanged: (_) {}),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Accessibility Section
            _SectionHeader(title: 'Accessibility', isDark: isDark),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.format_size,
                  iconBgColor: const Color(0xFFE9D5FF),
                  iconColor: Colors.purple[600]!,
                  title: 'Large Text Size',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Standard',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        size: 18,
                      ),
                    ],
                  ),
                  onTap: () {},
                  isDark: isDark,
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.contrast,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: Colors.amber[700]!,
                  title: 'High Contrast Mode',
                  trailing: _CustomSwitch(value: false, onChanged: (_) {}),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Security & Privacy Section
            _SectionHeader(title: 'Security & Privacy', isDark: isDark),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  icon: Icons.privacy_tip,
                  iconBgColor: const Color(0xFFFECDD3),
                  iconColor: Colors.red[600]!,
                  title: 'Profile Privacy',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    size: 18,
                  ),
                  onTap: () {},
                  isDark: isDark,
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.cloud_upload,
                  iconBgColor: const Color(0xFFE0F2FE),
                  iconColor: Colors.lightBlue[600]!,
                  title: 'Data Backup',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Last: Today 10:45 AM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        size: 18,
                      ),
                    ],
                  ),
                  onTap: () {},
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Admin Section - Protected
            if (ref.watch(authProvider).isAdmin) ...[
              _SectionHeader(title: 'Admin Panel', isDark: isDark),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: Icons.dashboard,
                    iconBgColor: AppColors.primaryOrange.withValues(alpha: 0.2),
                    iconColor: AppColors.primaryOrange,
                    title: 'Admin Dashboard',
                    subtitle: 'Manage app content and settings',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      size: 18,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 48),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _logout(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Center(
                    child: Text(
                      'Logout from Device',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emergency,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'KumbhSaathi App v1.0.0 (Build 1)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NASHIK KUMBH 2025 • OFFICIAL ASSISTANCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardSecondaryDark : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _ThemeOption(
              icon: Icons.light_mode,
              label: 'Light',
              isSelected: themeMode == ThemeMode.light,
              onTap: () =>
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
              isDark: isDark,
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              label: 'Dark',
              isSelected: themeMode == ThemeMode.dark,
              onTap: () =>
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
              isDark: isDark,
            ),
            _ThemeOption(
              icon: Icons.settings_brightness,
              label: 'System',
              isSelected: themeMode == ThemeMode.system,
              onTap: () =>
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconColor.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.borderDark
          : const Color(0xFFF3F4F6),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.cardDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 51,
        height: 31,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.success : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
