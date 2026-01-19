import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/lost_person.dart';
import '../../data/repositories/lost_person_repository.dart';
import '../../widgets/common/chatbot_button.dart';

/// Public screen showing all lost person reports to all users
/// Public screen showing all lost person reports to all users
class LostPersonsPublicScreen extends ConsumerStatefulWidget {
  const LostPersonsPublicScreen({super.key});

  @override
  ConsumerState<LostPersonsPublicScreen> createState() =>
      _LostPersonsPublicScreenState();
}

class _LostPersonsPublicScreenState
    extends ConsumerState<LostPersonsPublicScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Lost Person Alerts'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: isDark
              ? AppColors.textMutedDark
              : AppColors.textMutedLight,
          indicatorColor: AppColors.primaryOrange,
          tabs: const [
            Tab(text: 'All Alerts'),
            Tab(text: 'My Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildAllAlertsList(isDark),
              _buildMyReportsList(isDark),
            ],
          ),
          // Chatbot Button (bottom-left to avoid FAB)
          const Positioned(left: 16, bottom: 16, child: ChatbotButton()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to report lost person screen
          Navigator.pushNamed(context, '/report-lost');
        },
        backgroundColor: AppColors.emergency,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text(
          'Report Lost Person',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildAllAlertsList(bool isDark) {
    final lostPersonsAsync = ref.watch(lostPersonsStreamProvider);

    return lostPersonsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (persons) {
        // Filter to show only missing/searching
        final activeReports = persons
            .where((p) => p.status != LostPersonStatus.found)
            .toList();

        if (activeReports.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No Lost Person Reports',
            'Good news! No one is currently reported missing.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(lostPersonsStreamProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeReports.length,
            itemBuilder: (context, index) {
              return _buildLostPersonCard(
                activeReports[index],
                isDark,
                context,
                isMyReport: false,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyReportsList(bool isDark) {
    // We need a provider for my reports.
    // For now, we reuse the list and filter client-side or we should create a new provider.
    // Let's create a temporary provider logic here or use the repository directly via a stream builder if provider isn't available globally yet.
    // BETTER: Use a new provider. But to avoid context switching, I'll filter the main list for now if the user ID matches,
    // OR deeper integration: use the method I just added to repo.
    // Let's use FutureBuilder/StreamBuilder with the new repo method for "My Reports".

    final currentUserId = FirebaseService.currentUserId;
    if (currentUserId == null) {
      return Center(child: Text('Please log in to see your reports'));
    }

    return StreamBuilder<List<LostPerson>>(
      stream: LostPersonRepository().getMyLostPersonsStream(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final myReports = snapshot.data ?? [];

        if (myReports.isEmpty) {
          return _buildEmptyState(
            isDark,
            'No Reports Filed',
            'You haven\'t reported any lost persons yet.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myReports.length,
          itemBuilder: (context, index) {
            return _buildLostPersonCard(
              myReports[index],
              isDark,
              context,
              isMyReport: true,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLostPersonCard(
    LostPerson person,
    bool isDark,
    BuildContext context, {
    required bool isMyReport,
  }) {
    final isFound = person.status == LostPersonStatus.found;
    final borderColor = isFound ? AppColors.success : AppColors.emergency;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with alert
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isFound ? Icons.check_circle : Icons.warning,
                  color: borderColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFound ? 'FOUND & REUNITED' : '⚠️ MISSING PERSON ALERT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: borderColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isFound)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'RESOLVED',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: person.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            person.photoUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: AppColors.primaryBlue.withValues(alpha: 0.5),
                          ),
                        ),
                ),

                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textDarkDark
                              : AppColors.textDarkLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.person,
                        '${person.gender}, ${person.age} years',
                        isDark,
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.location_on,
                        'Last seen: ${person.lastSeenLocation}',
                        isDark,
                      ),
                      if (person.description != null) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(Icons.info, person.description!, isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact info
          if (person.guardianPhone != null && !isFound) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.phone, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact: ${person.guardianName ?? "Guardian"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        Text(
                          person.guardianPhone!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMyReport)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final phoneNumber = person.guardianPhone!;
                        final uri = Uri.parse('tel:$phoneNumber');

                        try {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cannot make phone calls on this device',
                                  ),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppColors.emergency,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.call,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Call',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // My Repost Actions
          if (isMyReport && !isFound) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Mark as found
                    await LostPersonRepository().markAsFound(person.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Marked as Found! Great news!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'MARK AS FOUND / RECEIVED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Missing'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Searching'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Provider for lost persons stream
final lostPersonsStreamProvider = StreamProvider<List<LostPerson>>((ref) {
  return LostPersonRepository().getLostPersonsStream();
});
