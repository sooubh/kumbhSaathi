import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/lost_person.dart';

/// Screen to display detailed information about a lost person
class LostPersonDetailScreen extends StatelessWidget {
  final String personId;

  const LostPersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lost Person Details'), elevation: 2),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lost_persons')
            .doc(personId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading data: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Lost person not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final lostPerson = LostPerson.fromJson({
            ...snapshot.data!.data() as Map<String, dynamic>,
            'id': personId,
          });

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                _buildStatusBanner(context, lostPerson),

                // Photo Section
                if (lostPerson.photoUrl != null)
                  _buildPhotoSection(lostPerson.photoUrl!),

                // Basic Information
                _buildSection(
                  context,
                  title: 'Basic Information',
                  child: Column(
                    children: [
                      _buildInfoRow('Name', lostPerson.name, Icons.person),
                      _buildInfoRow(
                        'Age',
                        '${lostPerson.age} years',
                        Icons.cake,
                      ),
                      _buildInfoRow('Gender', lostPerson.gender, Icons.wc),
                    ],
                  ),
                ),

                // Description Section
                if (lostPerson.description != null)
                  _buildSection(
                    context,
                    title: 'Description',
                    child: Text(
                      lostPerson.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),

                // Last Seen Information
                _buildSection(
                  context,
                  title: 'Last Seen',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Location',
                        lostPerson.lastSeenLocation,
                        Icons.location_on,
                      ),
                      _buildInfoRow(
                        'Reported At',
                        _formatDateTime(lostPerson.reportedAt),
                        Icons.access_time,
                      ),
                    ],
                  ),
                ),

                // Guardian Information
                if (lostPerson.guardianPhone != null)
                  _buildSection(
                    context,
                    title: 'Guardian Contact',
                    child: Column(
                      children: [
                        if (lostPerson.guardianName != null)
                          _buildInfoRow(
                            'Name',
                            lostPerson.guardianName!,
                            Icons.person_outline,
                          ),
                        _buildInfoRow(
                          'Phone',
                          lostPerson.guardianPhone!,
                          Icons.phone,
                        ),
                        if (lostPerson.guardianAddress != null)
                          _buildInfoRow(
                            'Address',
                            lostPerson.guardianAddress!,
                            Icons.home,
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(context, lostPerson),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, LostPerson person) {
    final Color color;
    final String text;
    final IconData icon;

    switch (person.status) {
      case LostPersonStatus.found:
        color = Colors.green;
        text = '✓ Person Found';
        icon = Icons.check_circle;
        break;
      case LostPersonStatus.searching:
        color = Colors.orange;
        text = 'Actively Searching';
        icon = Icons.search;
        break;
      case LostPersonStatus.missing:
        color = Colors.red;
        text = '⚠ Missing Person';
        icon = Icons.warning;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String photoUrl) {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.grey[200],
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Icon(Icons.person, size: 100, color: Colors.grey),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LostPerson person) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Call Guardian Button
          if (person.guardianPhone != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _callGuardian(person.guardianPhone!),
                icon: const Icon(Icons.phone),
                label: const Text('Call Guardian'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Found Person Button
          if (person.status != LostPersonStatus.found)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _reportFound(context, person.id),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('I Found This Person'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // View on Map Button
          if (person.lastSeenLat != null && person.lastSeenLng != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _viewOnMap(context, person),
                icon: const Icon(Icons.map),
                label: const Text('View Last Seen Location'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _callGuardian(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _reportFound(BuildContext context, String personId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Person Found'),
        content: const Text(
          'Are you sure you have found this person? This will notify the guardian.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('lost_persons')
                    .doc(personId)
                    .update({'status': LostPersonStatus.found.name});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you! Guardian will be notified.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _viewOnMap(BuildContext context, LostPerson person) {
    Navigator.pushNamed(
      context,
      '/ghat-navigation',
      arguments: {
        'latitude': person.lastSeenLat,
        'longitude': person.lastSeenLng,
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
