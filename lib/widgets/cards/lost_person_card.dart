import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/lost_person.dart';

/// Lost person card for listing
class LostPersonCard extends StatelessWidget {
  final LostPerson person;
  final VoidCallback? onTap;
  final VoidCallback? onContact;

  const LostPersonCard({
    super.key,
    required this.person,
    this.onTap,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark
                    ? AppColors.cardSecondaryDark
                    : const Color(0xFFF3F4F6),
              ),
              child: person.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        person.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textDarkDark
                                : AppColors.textDarkLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusBadge(status: person.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${person.age} years old • ${person.gender}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          person.lastSeenLocation,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Contact button
            if (onContact != null)
              IconButton(
                onPressed: onContact,
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.person, size: 40, color: Color(0xFF9CA3AF)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LostPersonStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String text;

    switch (status) {
      case LostPersonStatus.missing:
        color = AppColors.emergency;
        bgColor = AppColors.crowdHighBg;
        text = 'MISSING';
        break;
      case LostPersonStatus.searching:
        color = AppColors.warning;
        bgColor = AppColors.crowdMediumBg;
        text = 'SEARCHING';
        break;
      case LostPersonStatus.found:
        color = AppColors.success;
        bgColor = AppColors.crowdLowBg;
        text = 'FOUND';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
