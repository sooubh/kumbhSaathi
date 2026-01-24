import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../providers/location_provider.dart';
import '../../widgets/common/sos_button.dart';
import '../../widgets/common/primary_button.dart';
import '../../core/utils/auth_helper.dart';

/// Emergency SOS Screen
class SOSScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const SOSScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen> {
  bool _locationShared = false;
  bool _isLoading = false;
  String? _activeAlertId;
  final _repository = EmergencyRepository();

  String get _currentLocation {
    final locationAsync = ref.read(locationProvider);
    return locationAsync.when(
      loading: () => 'Fetching location...',
      error: (error, stackTrace) => 'Location unavailable',
      data: (pos) => pos != null
          ? 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}'
          : 'Near Sangam Gate 4',
    );
  }

  Future<void> _shareLocation() async {
    setState(() {
      _isLoading = true;
      _locationShared = true;
    });

    try {
      final locationAsync = ref.read(locationProvider);
      Position? position = locationAsync.valueOrNull;

      // Send SOS alert to Firestore
      final userName = await AuthHelper.getUserFullName();
      final alertId = await _repository.sendSOSAlert(
        userId: FirebaseService.currentUserId ?? 'anonymous',
        userName: userName,
        latitude: position?.latitude ?? 20.0063,
        longitude: position?.longitude ?? 73.7897,
        locationDescription: _currentLocation,
      );

      setState(() => _activeAlertId = alertId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Alert sent! Help is on the way.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: ${e.toString()}'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAlert() async {
    if (_activeAlertId == null) return;

    try {
      await _repository.cancelAlert(_activeAlertId!);
      setState(() {
        _activeAlertId = null;
        _locationShared = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('SOS Alert cancelled')));
      }
    } catch (e) {
      // Ignore errors on cancel
    }
  }

  Future<void> _callMelaHQ() async {
    final uri = Uri.parse('tel:${AppConstants.melaHqNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _onSOSPressed() {
    // Immediate tap action
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hold the button for 3 seconds to activate SOS'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onSOSLongPress() {
    // Long press action - emergency activated
    _shareLocation();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppColors.emergency),
            const SizedBox(width: 8),
            const Text('SOS Activated'),
          ],
        ),
        content: const Text(
          'Your location has been shared with emergency services and Mela authorities. Help is on the way.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAlert();
            },
            child: const Text('Cancel Alert'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text('Emergency Mode'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.emergency,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Location Header
                const SizedBox(height: 8),
                locationAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text(
                    'LOCATION UNAVAILABLE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emergency,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  data: (position) => Text(
                    position != null
                        ? 'YOUR LOCATION DETECTED'
                        : 'NEAR SANGAM AREA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nearest Help Desk: 250m (2 mins walk)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Map Preview
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Map placeholder
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your Location',
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
                      // Navigation button
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.emergency,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emergency.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -0.785, // -45 degrees
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // SOS Button
                if (_isLoading)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SOSButton(
                    onPressed: _onSOSPressed,
                    onLongPress: _onSOSLongPress,
                    holdDurationSeconds: AppConstants.sosHoldDuration,
                    size: 200,
                  ),
                const SizedBox(height: 24),

                // Status Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusBadge(
                      icon: Icons.signal_cellular_4_bar,
                      text: 'SIGNAL: STRONG',
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    locationAsync.when(
                      loading: () => _StatusBadge(
                        icon: Icons.location_searching,
                        text: 'GPS: SEARCHING',
                        color: AppColors.warning,
                        isDark: isDark,
                      ),
                      error: (error, stackTrace) => _StatusBadge(
                        icon: Icons.location_off,
                        text: 'GPS: UNAVAILABLE',
                        color: AppColors.emergency,
                        isDark: isDark,
                      ),
                      data: (pos) => _StatusBadge(
                        icon: Icons.location_on,
                        text: pos != null
                            ? 'GPS: ACCURATE'
                            : 'GPS: APPROXIMATE',
                        color: pos != null
                            ? AppColors.primaryBlue
                            : AppColors.warning,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nearby Help Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.emergency.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_police,
                          color: AppColors.emergency,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Police Station Sector 5',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textDarkDark
                                    : AppColors.textDarkLight,
                              ),
                            ),
                            Text(
                              'Head North-East along the main path',
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
                      Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Share Location',
                        icon: Icons.share_location,
                        onPressed: _shareLocation,
                        backgroundColor: AppColors.primaryBlue,
                        height: 56,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Call Mela HQ',
                        icon: Icons.call,
                        onPressed: _callMelaHQ,
                        backgroundColor: const Color(0xFF1A1A1A),
                        height: 56,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Confirmation Message
                if (_locationShared)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOS Alert Sent Successfully!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[800],
                                ),
                              ),
                              Text(
                                'Authorities have been notified. Stay calm.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _StatusBadge({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
