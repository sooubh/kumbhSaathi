import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/panchavati_config.dart';

/// Widget showing a legend for Panchavati ghats
class PanchavatiGhatLegend extends StatelessWidget {
  final bool isDark;

  const PanchavatiGhatLegend({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Panchavati Ghats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...PanchavatiConfig.ghatPilgrimageOrder.map((ghatId) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildGhatItem(ghatId),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGhatItem(String ghatId) {
    final ghatNames = {
      'someshwar_ghat': '1. Someshwar Ghat',
      'ahilya_ghat': '2. Ahilya Ghat',
      'naroshankar_ghat': '3. Naroshankar Ghat',
      'ram_ghat': '4. Ram Ghat ⭐',
      'kala_ram_ghat': '5. Kala Ram Ghat',
      'ganga_ghat': '6. Ganga Ghat',
      'tapovan_ghat': '7. Tapovan Ghat',
    };

    final isMain = ghatId == 'ram_ghat';

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isMain ? AppColors.primaryBlue : AppColors.textMutedDark,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          ghatNames[ghatId] ?? ghatId,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isMain ? FontWeight.w700 : FontWeight.w500,
            color: isMain
                ? AppColors.primaryBlue
                : (isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
          ),
        ),
      ],
    );
  }
}

/// Floating "Focus Panchavati" button
class FocusPanchavatiButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const FocusPanchavatiButton({
    super.key,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_city,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Focus Panchavati',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
