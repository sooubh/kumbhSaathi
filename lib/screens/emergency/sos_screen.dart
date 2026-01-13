import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/sos_button.dart';
import '../../widgets/common/primary_button.dart';

/// Emergency SOS Screen
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _locationShared = false;
  final String _currentLocation = 'Near Sangam Gate 4';
  final String _nearestHelp = '250m (2 mins walk)';

  Future<void> _shareLocation() async {
    setState(() => _locationShared = true);
    // TODO: Implement actual location sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location shared with family and authorities'),
        backgroundColor: AppColors.success,
      ),
    );
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
          'Your location has been shared with emergency services and your emergency contacts. Help is on the way.',
        ),
        actions: [
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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Location Header
            const SizedBox(height: 8),
            Text(
              _currentLocation.toUpperCase(),
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
            const SizedBox(height: 4),
            Text(
              'Nearest Help Desk: $_nearestHelp',
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
                color: isDark ? AppColors.cardDark : const Color(0xFFF3F4F6),
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
                            color: AppColors.emergency.withValues(alpha: 0.4),
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
                _StatusBadge(
                  icon: Icons.location_on,
                  text: 'GPS: ACCURATE',
                  color: AppColors.primaryBlue,
                  isDark: isDark,
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
                      child: Text(
                        'Location shared with family and authorities. Help is on the way.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
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
