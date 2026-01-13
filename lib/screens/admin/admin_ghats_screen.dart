import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ghat.dart';
import '../../data/providers/data_providers.dart';
import '../../data/repositories/ghat_repository.dart';
import '../../widgets/common/primary_button.dart';

/// Admin screen for managing ghats
class AdminGhatsScreen extends ConsumerStatefulWidget {
  const AdminGhatsScreen({super.key});

  @override
  ConsumerState<AdminGhatsScreen> createState() => _AdminGhatsScreenState();
}

class _AdminGhatsScreenState extends ConsumerState<AdminGhatsScreen> {
  final _repository = GhatRepository();
  bool _isSeeding = false;

  Future<void> _seedGhats() async {
    setState(() => _isSeeding = true);
    try {
      await _repository.seedGhats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample ghats added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    } finally {
      setState(() => _isSeeding = false);
    }
  }

  void _showAddGhatDialog() {
    final nameController = TextEditingController();
    final nameHindiController = TextEditingController();
    final descController = TextEditingController();
    final latController = TextEditingController(text: '20.0063');
    final lngController = TextEditingController(text: '73.7897');
    CrowdLevel selectedLevel = CrowdLevel.low;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Ghat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (English)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameHindiController,
                  decoration: const InputDecoration(labelText: 'Name (Hindi)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CrowdLevel>(
                  initialValue: selectedLevel,
                  decoration: const InputDecoration(labelText: 'Crowd Level'),
                  items: CrowdLevel.values
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedLevel = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final ghat = Ghat(
                  id: '',
                  name: nameController.text.trim(),
                  nameHindi: nameHindiController.text.trim(),
                  description: descController.text.trim(),
                  latitude: double.tryParse(latController.text) ?? 20.0063,
                  longitude: double.tryParse(lngController.text) ?? 73.7897,
                  crowdLevel: selectedLevel,
                );

                // Add to Firestore
                await _repository.addGhat(ghat);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGhatDialog(Ghat ghat) {
    CrowdLevel selectedLevel = ghat.crowdLevel;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update: ${ghat.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Crowd Level'),
              const SizedBox(height: 16),
              DropdownButtonFormField<CrowdLevel>(
                initialValue: selectedLevel,
                items: CrowdLevel.values
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCrowdColor(l),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(l.name.toUpperCase()),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedLevel = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _repository.updateCrowdLevel(ghat.id, selectedLevel);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCrowdColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return AppColors.success;
      case CrowdLevel.medium:
        return AppColors.warning;
      case CrowdLevel.high:
        return AppColors.emergency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ghatsAsync = ref.watch(ghatsStreamProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Manage Ghats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGhatDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Seed button
          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              text: 'Seed Sample Ghats',
              icon: Icons.add_circle_outline,
              onPressed: _seedGhats,
              isLoading: _isSeeding,
              backgroundColor: AppColors.primaryBlue,
            ),
          ),
          // Ghats list
          Expanded(
            child: ghatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (ghats) {
                if (ghats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 64,
                          color: AppColors.textMutedLight,
                        ),
                        const SizedBox(height: 16),
                        const Text('No ghats in database'),
                        const SizedBox(height: 8),
                        const Text('Tap "Seed Sample Ghats" to add test data'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ghats.length,
                  itemBuilder: (context, index) {
                    final ghat = ghats[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getCrowdColor(
                              ghat.crowdLevel,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.water_drop,
                            color: _getCrowdColor(ghat.crowdLevel),
                          ),
                        ),
                        title: Text(
                          ghat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ghat.nameHindi != null) Text(ghat.nameHindi!),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCrowdColor(ghat.crowdLevel),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ghat.crowdLevel.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditGhatDialog(ghat),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
