import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/kumbh_update.dart';
import '../../data/repositories/kumbh_update_repository.dart';

/// Screen showing all Kumbh Mela updates and events
class KumbhUpdatesScreen extends ConsumerWidget {
  const KumbhUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final updatesAsync = ref.watch(kumbhUpdatesStreamProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('🕉️ Kumbh Mela Updates'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      ),
      body: updatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (updates) {
          if (updates.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(kumbhUpdatesStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: updates.length,
              itemBuilder: (context, index) {
                return _buildUpdateCard(updates[index], isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🕉️',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            'No Updates Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back for Kumbh Mela announcements',
            style: TextStyle(
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(KumbhUpdate update, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: update.isImportant
            ? Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.5),
                width: 2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${update.categoryEmoji} ${update.category.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const Spacer(),
              if (update.isImportant)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emergency.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: AppColors.emergency,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'IMPORTANT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emergency,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            update.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            update.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),

          const SizedBox(height: 12),

          // Event details
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                update.formattedDate,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
              if (update.formattedTime.isNotEmpty) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  update.formattedTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ],
          ),

          if (update.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.emergency,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    update.location!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Provider for Kumbh updates stream
final kumbhUpdatesStreamProvider = StreamProvider<List<KumbhUpdate>>((ref) {
  return KumbhUpdateRepository().getUpcomingEvents();
});
