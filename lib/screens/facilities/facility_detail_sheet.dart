import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/facility.dart';
import 'route_recording_screen.dart';

/// Bottom sheet showing facility details with action buttons
class FacilityDetailSheet extends StatelessWidget {
  final Facility facility;

  const FacilityDetailSheet({super.key, required this.facility});

  static void show(BuildContext context, Facility facility) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FacilityDetailSheet(facility: facility),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                facility.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
              ),
              const SizedBox(height: 8),

              // Type Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  facility.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address
              if (facility.address != null && facility.address!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        facility.address!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Phone
              if (facility.phone != null && facility.phone!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      facility.phone!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Distance
              Row(
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${facility.distanceMeters}m away • ${facility.walkTimeMinutes} min walk',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RouteRecordingScreen(facility: facility),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_searching),
                      label: const Text('Record Route'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: BorderSide(color: AppColors.primaryOrange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Open navigation in default maps app
                        final lat = facility.latitude;
                        final lng = facility.longitude;
                        final name = Uri.encodeComponent(facility.name);

                        // Try Google Maps first, fallback to Apple Maps on iOS
                        final googleMapsUrl = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name',
                        );

                        try {
                          if (await canLaunchUrl(googleMapsUrl)) {
                            await launchUrl(
                              googleMapsUrl,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            // Fallback to universal geo: URL
                            final geoUrl = Uri.parse(
                              'geo:$lat,$lng?q=$lat,$lng($name)',
                            );
                            if (await canLaunchUrl(geoUrl)) {
                              await launchUrl(geoUrl);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No navigation app available',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navigation error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
