import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/custom_path_service.dart';
import '../../data/models/custom_walking_path.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_helper.dart';

/// Screen showing available custom paths between two locations
class CustomPathsListScreen extends ConsumerStatefulWidget {
  final String startLocationId;
  final String endLocationId;
  final String startLocationName;
  final String endLocationName;

  const CustomPathsListScreen({
    super.key,
    required this.startLocationId,
    required this.endLocationId,
    required this.startLocationName,
    required this.endLocationName,
  });

  @override
  ConsumerState<CustomPathsListScreen> createState() =>
      _CustomPathsListScreenState();
}

class _CustomPathsListScreenState extends ConsumerState<CustomPathsListScreen> {
  List<CustomWalkingPath> _paths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    try {
      final paths = await CustomPathService().getPathsBetween(
        startLocationId: widget.startLocationId,
        endLocationId: widget.endLocationId,
      );

      if (mounted) {
        setState(() {
          _paths = paths;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _upvotePath(String pathId) async {
    final userId = AuthHelper.getUserIdOrDefault();

    try {
      await CustomPathService().upvotePath(pathId, userId);
      _loadPaths(); // Reload to get updated votes
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to vote: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Community Paths'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_road),
            onPressed: () {
              // Navigate to record path screen
              Navigator.pushNamed(
                context,
                '/record-path',
                arguments: {
                  'startLocationId': widget.startLocationId,
                  'endLocationId': widget.endLocationId,
                  'startLocationName': widget.startLocationName,
                  'endLocationName': widget.endLocationName,
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paths.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paths.length,
              itemBuilder: (context, index) {
                return _buildPathCard(_paths[index], isDark);
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No paths yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to record a path!',
            style: TextStyle(
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/record-path',
                arguments: {
                  'startLocationId': widget.startLocationId,
                  'endLocationId': widget.endLocationId,
                  'startLocationName': widget.startLocationName,
                  'endLocationName': widget.endLocationName,
                },
              );
            },
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Record Path'),
          ),
        ],
      ),
    );
  }

  Widget _buildPathCard(CustomWalkingPath path, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: path.isVerified
              ? AppColors.success.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
          width: path.isVerified ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            path.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textDarkDark
                                  : AppColors.textDarkLight,
                            ),
                          ),
                        ),
                        if (path.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${path.createdByName}',
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
            ],
          ),

          if (path.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              path.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Stats
          Row(
            children: [
              _buildStat(Icons.straighten, path.formattedDistance),
              const SizedBox(width: 16),
              _buildStat(Icons.access_time, path.formattedDuration),
              const SizedBox(width: 16),
              _buildStat(Icons.directions_walk, 'Walking'),
            ],
          ),

          // Tags
          if (path.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: path.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Voting
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up_outlined),
                    onPressed: () => _upvotePath(path.id),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    path.rating.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: path.isHighlyRated
                          ? AppColors.success
                          : AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),

              // Use path button
              ElevatedButton.icon(
                onPressed: () {
                  // Use this path for navigation
                  Navigator.pop(context, path);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.navigation,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Use This Path',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBlue),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
