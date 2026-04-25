import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/custom_path_service.dart';
import '../../core/services/map_service.dart';
import '../../data/models/custom_walking_path.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_helper.dart';

/// Screen for recording a custom walking path
class RecordPathScreen extends ConsumerStatefulWidget {
  final String startLocationId;
  final String startLocationName;
  final String endLocationId;
  final String endLocationName;

  const RecordPathScreen({
    super.key,
    required this.startLocationId,
    required this.startLocationName,
    required this.endLocationId,
    required this.endLocationName,
  });

  @override
  ConsumerState<RecordPathScreen> createState() => _RecordPathScreenState();
}

class _RecordPathScreenState extends ConsumerState<RecordPathScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<LatLng> _recordedPoints = [];
  final List<String> _selectedTags = [];

  bool _isRecording = false;
  double _totalDistance = 0;
  DateTime? _startTime;
  Position? _lastPosition;

  final MapService _mapService = MapService();
  final CustomPathService _pathService = CustomPathService();

  final List<String> _availableTags = [
    'Shortcut',
    'Scenic',
    'Shaded',
    'Stairs',
    'Flat',
    'Crowded',
    'Quiet',
    'Well-lit',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text =
        '${widget.startLocationName} to ${widget.endLocationName}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _startTime = DateTime.now();
      _recordedPoints.clear();
      _totalDistance = 0;
    });

    // Start tracking location
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Record every 5 meters
      ),
    ).listen((position) {
      if (!_isRecording) return;

      final point = LatLng(position.latitude, position.longitude);

      setState(() {
        if (_lastPosition != null) {
          final lastPoint = LatLng(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
          );
          _totalDistance += _mapService.calculateDistance(lastPoint, point);
        }

        _recordedPoints.add(point);
        _lastPosition = position;
      });
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _savePath() async {
    if (_recordedPoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path too short! Walk at least 10m.')),
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a path name')));
      return;
    }

    final duration = DateTime.now().difference(_startTime!).inSeconds;

    // Get current user from Firebase Auth
    final userId = AuthHelper.getUserIdOrDefault();
    final userName = await AuthHelper.getUserFullName();

    final path = CustomWalkingPath(
      id: '',
      name: _nameController.text,
      description: _descriptionController.text,
      startLocationId: widget.startLocationId,
      endLocationId: widget.endLocationId,
      startLocationName: widget.startLocationName,
      endLocationName: widget.endLocationName,
      waypoints: _recordedPoints,
      distanceMeters: _totalDistance,
      durationSeconds: duration,
      createdBy: userId,
      createdByName: userName,
      createdAt: DateTime.now(),
      isWalkingOnly: true,
      tags: _selectedTags,
    );

    try {
      await _pathService.savePath(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Path saved! Thank you for contributing!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save path: $e')));
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
        title: const Text('Record Walking Path'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.startLocationName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(Icons.more_vert, color: AppColors.primaryBlue),
                  ),
                  Row(
                    children: [
                      Icon(Icons.flag, color: AppColors.emergency),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.endLocationName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recording stats
            if (_isRecording || _recordedPoints.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          'Distance',
                          '${(_totalDistance).toStringAsFixed(0)}m',
                        ),
                        _buildStat('Points', _recordedPoints.length.toString()),
                        _buildStat(
                          'Time',
                          _startTime != null
                              ? '${DateTime.now().difference(_startTime!).inMinutes}min'
                              : '0min',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recording button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording
                      ? AppColors.emergency
                      : AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                ),
                label: Text(
                  _isRecording ? 'Stop Recording' : 'Start Recording',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            if (!_isRecording && _recordedPoints.isNotEmpty) ...[
              const SizedBox(height: 24),

              // Path name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Path Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText:
                      'e.g., Go through the market, turn left at temple...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tags
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _savePath,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text(
                    'Save & Share Path',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
