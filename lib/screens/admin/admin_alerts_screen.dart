import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/system_alert.dart';

/// Admin screen for managing system-wide alerts
class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Alert Management'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: () => _showCreateAlertDialog(context, isDark),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('system_alerts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alerts created yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateAlertDialog(context, isDark),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final alerts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alertData = alerts[index].data() as Map<String, dynamic>;
              final alertId = alerts[index].id;
              final alert = SystemAlert.fromJson({...alertData, 'id': alertId});
              return _buildAlertCard(alert, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(SystemAlert alert, bool isDark) {
    final color = _getAlertColor(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Switch(
                value: alert.isActive,
                onChanged: (value) => _toggleAlert(alert.id, value),
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Created: ${_formatDate(alert.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete, color: AppColors.emergency),
                onPressed: () => _confirmDeleteAlert(alert.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.emergency;
      case 'warning':
        return AppColors.warning;
      case 'info':
        return AppColors.primaryBlue;
      default:
        return AppColors.success;
    }
  }

  void _showCreateAlertDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedSeverity = 'info';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create System Alert'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alert Message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Severity',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('Info')),
                    DropdownMenuItem(value: 'warning', child: Text('Warning')),
                    DropdownMenuItem(
                      value: 'critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => selectedSeverity = value!);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                _createAlert(
                  titleController.text.trim(),
                  messageController.text.trim(),
                  selectedSeverity,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAlert(
    String title,
    String message,
    String severity,
  ) async {
    try {
      final alert = SystemAlert(
        id: '',
        title: title,
        message: message,
        severity: severity,
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await _firestore.collection('system_alerts').add(alert.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert created successfully'),
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
    }
  }

  Future<void> _toggleAlert(String alertId, bool isActive) async {
    try {
      await _firestore.collection('system_alerts').doc(alertId).update({
        'isActive': isActive,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Alert activated' : 'Alert deactivated'),
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
    }
  }

  void _confirmDeleteAlert(String alertId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAlert(alertId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAlert(String alertId) async {
    try {
      await _firestore.collection('system_alerts').doc(alertId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert deleted successfully'),
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
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
