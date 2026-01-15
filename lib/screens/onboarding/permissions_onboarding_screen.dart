import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_colors.dart';

/// Onboarding screen for requesting all permissions at once
class PermissionsOnboardingScreen extends ConsumerStatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  ConsumerState<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends ConsumerState<PermissionsOnboardingScreen> {
  final PermissionService _permissionService = PermissionService();
  Map<String, bool> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = await _permissionService.checkAllPermissions();
    setState(() {
      _permissions = permissions;
      _isLoading = false;
    });
  }

  Future<void> _requestAllPermissions() async {
    // Request each permission one by one
    await _permissionService.requestLocationPermission(context);
    await _permissionService.requestNotificationPermission(context);
    await _permissionService.requestCameraPermission(context);
    await _permissionService.requestStoragePermission(context);

    // Refresh permission status
    await _checkPermissions();

    // Check if all granted
    if (_permissions.values.every((granted) => granted)) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Header
                    Text(
                      '🕉️',
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to KumbhSaathi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To serve you better during Kumbh Mela, we need a few permissions',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Permission cards
                    _buildPermissionCard(
                      icon: Icons.location_on,
                      iconColor: AppColors.primaryBlue,
                      title: 'Location',
                      description:
                          'Find nearby ghats, get navigation, and share location with family',
                      isGranted: _permissions['location'] ?? false,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    _buildPermissionCard(
                      icon: Icons.notifications_active,
                      iconColor: Colors.orange,
                      title: 'Notifications',
                      description:
                          'Receive crowd alerts, ritual reminders, and emergency updates',
                      isGranted: _permissions['notifications'] ?? false,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    _buildPermissionCard(
                      icon: Icons.camera_alt,
                      iconColor: Colors.purple,
                      title: 'Camera',
                      description:
                          'Scan QR codes and report lost persons with photos',
                      isGranted: _permissions['camera'] ?? false,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    _buildPermissionCard(
                      icon: Icons.photo_library,
                      iconColor: Colors.green,
                      title: 'Photos',
                      description: 'Upload images for reports and profile',
                      isGranted: _permissions['photos'] ?? false,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 48),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _requestAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Skip button
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Privacy note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your privacy is protected. We only use permissions for app features.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isGranted,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
          width: isGranted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                    if (isGranted) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
