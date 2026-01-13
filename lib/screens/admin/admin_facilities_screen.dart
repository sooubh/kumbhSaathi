import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/facility.dart';
import '../../data/repositories/facility_repository.dart';

class AdminFacilitiesScreen extends ConsumerStatefulWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  ConsumerState<AdminFacilitiesScreen> createState() =>
      _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends ConsumerState<AdminFacilitiesScreen>
    with SingleTickerProviderStateMixin {
  final _repository = FacilityRepository();
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

  Future<void> _seedFacilities() async {
    try {
      await _repository.seedFacilities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facilities seeded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Manage Facilities'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          indicatorColor: AppColors.primaryOrange,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'Pending Requests'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Seed Data',
            onPressed: () => _showSeedDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFacilityList(active: true, isDark: isDark),
          _buildFacilityList(active: false, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildFacilityList({required bool active, required bool isDark}) {
    return StreamBuilder<List<Facility>>(
      stream: active
          ? _repository.getFacilities()
          : _repository.getPendingFacilities(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final facilities = snapshot.data!;

        if (facilities.isEmpty) {
          return Center(
            child: Text(
              active ? 'No active facilities found' : 'No pending requests',
              style: TextStyle(
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: facilities.length,
          itemBuilder: (context, index) {
            final facility = facilities[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    active ? Icons.place : Icons.pending,
                    color: AppColors.primaryBlue,
                  ),
                ),
                title: Text(
                  facility.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textDarkDark
                        : AppColors.textDarkLight,
                  ),
                ),
                subtitle: Text(
                  '${facility.type.name.toUpperCase()} • ${facility.address ?? "No address"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                trailing: active
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _repository.deleteFacility(facility.id),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () =>
                                _repository.approveFacility(facility.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                _repository.deleteFacility(facility.id),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Facilities?'),
        content: const Text(
          'This will check for existing data and add sample facilities if none exist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _seedFacilities();
            },
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );
  }
}
