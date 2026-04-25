import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/facility.dart';
import '../../data/models/verification_request.dart';
import '../../data/repositories/facility_repository.dart';

class VerifyFacilityScreen extends StatefulWidget {
  final Facility facility;

  const VerifyFacilityScreen({super.key, required this.facility});

  @override
  State<VerifyFacilityScreen> createState() => _VerifyFacilityScreenState();
}

class _VerifyFacilityScreenState extends State<VerifyFacilityScreen> {
  File? _image;
  Position? _currentPosition;
  bool _isLoading = false;
  String _statusMessage = '';

  final _picker = ImagePicker();
  final _repository = FacilityRepository();

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching live location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      _showError(e.toString());
    }
  }

  Future<void> _submitVerification() async {
    if (_image == null || _currentPosition == null) {
      _showError('Please capture a photo and get your location first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Uploading data to admin queue...';
    });

    try {
      final userId = FirebaseService.currentUserId;
      if (userId == null) throw 'User not logged in';

      // 1. Upload Image
      final imageUrl = await _repository.uploadVerificationImage(
        _image!,
        widget.facility.id,
      );

      // 2. Create Request
      final request = VerificationRequest(
        id: '', // Firestore will generate
        facilityId: widget.facility.id,
        facilityName: widget.facility.name,
        submittedBy: userId,
        submittedAt: DateTime.now(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        imageUrl: imageUrl,
      );

      // 3. Submit
      await _repository.submitVerificationRequest(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification sent for admin review!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
      _showError('Submission failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.emergency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verify Place'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Text(
              'Complete Verification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To keep "${widget.facility.name}" active, please provide a live photo and your current GPS location.',
              style: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 32),

            // Photo Section
            _buildSectionHeader('Live Photo', Icons.camera_alt_rounded, isDark),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isLoading ? null : _capturePhoto,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardSecondaryDark : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                  ),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 40,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to take photo',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Location Section
            _buildSectionHeader('Live Location', Icons.location_on_rounded, isDark),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardSecondaryDark : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentPosition == null)
                          Text(
                            'Location not fetched',
                            style: TextStyle(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          )
                        else
                          Text(
                            'LAT: ${_currentPosition!.latitude.toStringAsFixed(6)}\nLNG: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    label: Text(_currentPosition == null ? 'Get GPS' : 'Retry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Submit Button
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_statusMessage),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_image != null && _currentPosition != null)
                      ? _submitVerification
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SEND FOR ADMIN REVIEW',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
