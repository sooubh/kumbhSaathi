import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

/// Permission service for handling all app permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request location permission with custom dialog
  Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final shouldRequest = await _showPermissionDialog(
        context,
        title: 'Location Permission Required',
        message:
            'KumbhSaathi needs location access to show nearby ghats, provide navigation, and help you during the Kumbh Mela.',
        icon: Icons.location_on,
        iconColor: AppColors.primaryBlue,
      );

      if (shouldRequest == true) {
        final newStatus = await Permission.location.request();
        return newStatus.isGranted;
      }
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        title: 'Location Permission Denied',
        message:
            'Please enable location permission in app settings to use navigation and nearby ghat features.',
      );
    }

    return false;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final shouldRequest = await _showPermissionDialog(
        context,
        title: 'Camera Permission Required',
        message:
            'Camera access is needed to scan QR codes, take photos for lost person reports, and capture moments.',
        icon: Icons.camera_alt,
        iconColor: Colors.purple,
      );

      if (shouldRequest == true) {
        final newStatus = await Permission.camera.request();
        return newStatus.isGranted;
      }
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        title: 'Camera Permission Denied',
        message: 'Please enable camera permission in app settings.',
      );
    }

    return false;
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final shouldRequest = await _showPermissionDialog(
        context,
        title: 'Notification Permission',
        message:
            'Enable notifications to receive crowd alerts, ritual reminders, and emergency updates during Kumbh Mela.',
        icon: Icons.notifications_active,
        iconColor: Colors.orange,
      );

      if (shouldRequest == true) {
        final newStatus = await Permission.notification.request();
        return newStatus.isGranted;
      }
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        title: 'Notification Permission Denied',
        message: 'Please enable notifications in app settings.',
      );
    }

    return false;
  }

  /// Request storage/photos permission
  Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.photos.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final shouldRequest = await _showPermissionDialog(
        context,
        title: 'Photo Access Required',
        message:
            'Access to photos is needed to upload images for lost person reports and profile pictures.',
        icon: Icons.photo_library,
        iconColor: Colors.green,
      );

      if (shouldRequest == true) {
        final newStatus = await Permission.photos.request();
        return newStatus.isGranted;
      }
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        title: 'Photo Permission Denied',
        message: 'Please enable photo access in app settings.',
      );
    }

    return false;
  }

  /// Request microphone permission (for voice assistant)
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final shouldRequest = await _showPermissionDialog(
        context,
        title: 'Microphone Permission',
        message:
            'Microphone access is needed for voice commands and the voice assistant feature.',
        icon: Icons.mic,
        iconColor: Colors.red,
      );

      if (shouldRequest == true) {
        final newStatus = await Permission.microphone.request();
        return newStatus.isGranted;
      }
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        title: 'Microphone Permission Denied',
        message: 'Please enable microphone permission in app settings.',
      );
    }

    return false;
  }

  /// Check if all essential permissions are granted
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'camera': await Permission.camera.isGranted,
      'notifications': await Permission.notification.isGranted,
      'photos': await Permission.photos.isGranted,
      'microphone': await Permission.microphone.isGranted,
    };
  }

  /// Show permission request dialog
  Future<bool?> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PermissionDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  /// Show settings dialog for permanently denied permissions
  Future<void> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.settings, color: AppColors.emergency),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom permission dialog widget
class _PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const _PermissionDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color: iconColor,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE5E7EB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Not Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Allow',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
