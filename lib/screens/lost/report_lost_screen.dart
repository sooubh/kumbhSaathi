import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/lost_person.dart';
import '../../data/repositories/lost_person_repository.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/input_field.dart';

/// Report lost person form screen with optional pre-fill from voice assistant
class ReportLostScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  // Pre-fill data from voice assistant
  final String? preFillName;
  final int? preFillAge;
  final String? preFillGender;
  final String? preFillHeight;
  final String? preFillClothing;
  final String? preFillLocation;
  final String? preFillGuardianName;
  final String? preFillGuardianPhone;
  final String? preFillDescription;

  const ReportLostScreen({
    super.key,
    this.showBackButton = true,
    this.preFillName,
    this.preFillAge,
    this.preFillGender,
    this.preFillHeight,
    this.preFillClothing,
    this.preFillLocation,
    this.preFillGuardianName,
    this.preFillGuardianPhone,
    this.preFillDescription,
  });

  @override
  ConsumerState<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends ConsumerState<ReportLostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  String? _selectedGender;
  XFile? _selectedImage;
  bool _isLoading = false;

  final _repository = LostPersonRepository();
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    // Pre-fill form if data provided from voice assistant
    if (widget.preFillName != null) {
      _nameController.text = widget.preFillName!;
    }
    if (widget.preFillAge != null) {
      _ageController.text = widget.preFillAge.toString();
    }
    if (widget.preFillLocation != null) {
      _locationController.text = widget.preFillLocation!;
    }
    if (widget.preFillGuardianName != null) {
      _guardianNameController.text = widget.preFillGuardianName!;
    }
    if (widget.preFillGuardianPhone != null) {
      _guardianPhoneController.text = widget.preFillGuardianPhone!;
    }

    // Build description from height and clothing if provided
    final descriptionParts = <String>[];
    if (widget.preFillHeight != null) {
      descriptionParts.add('Height: ${widget.preFillHeight}');
    }
    if (widget.preFillClothing != null) {
      descriptionParts.add('Clothing: ${widget.preFillClothing}');
    }
    if (widget.preFillDescription != null) {
      descriptionParts.add(widget.preFillDescription!);
    }
    if (descriptionParts.isNotEmpty) {
      _descriptionController.text = descriptionParts.join('. ');
    }

    // Set gender if provided
    if (widget.preFillGender != null) {
      _selectedGender = widget.preFillGender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => _ImageSourceBottomSheet(),
    );

    if (source != null) {
      final image = await picker.pickImage(source: source, maxWidth: 1024);
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create lost person object
      final lostPerson = LostPerson(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender ?? 'Unknown',
        lastSeenLocation: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        reportedAt: DateTime.now(),
        reportedBy: FirebaseService.currentUserId ?? 'anonymous',
        status: LostPersonStatus.missing,
        guardianName: _guardianNameController.text.trim().isNotEmpty
            ? _guardianNameController.text.trim()
            : null,
        guardianPhone: _guardianPhoneController.text.trim().isNotEmpty
            ? _guardianPhoneController.text.trim()
            : null,
      );

      // Save to Firestore first
      final docId = await _repository.reportLostPerson(lostPerson);

      // Upload photo to Firebase Storage if selected
      if (_selectedImage != null) {
        final photoUrl = await _uploadPhoto(docId);
        await _repository.updatePhotoUrl(docId, photoUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Report submitted successfully! Authorities have been notified.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: ${e.toString()}'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _uploadPhoto(String reportId) async {
    if (_selectedImage == null) {
      throw Exception('No image selected');
    }

    try {
      _logger.d('📸 [UPLOAD] Starting photo upload for report: $reportId');
      _logger.d('📸 [UPLOAD] Image path: ${_selectedImage!.path}');

      final storageRef = FirebaseService.storage.ref();
      final photoRef = storageRef.child(
        'lost_persons/$reportId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final file = File(_selectedImage!.path);
      final fileSize = await file.length();
      _logger.d(
        '📸 [UPLOAD] File size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
      );

      // Upload file
      _logger.d('📸 [UPLOAD] Starting upload task...');
      final uploadTask = photoRef.putFile(file);

      // Monitor progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        _logger.d('📸 [UPLOAD] Progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      await uploadTask;
      _logger.i('✅ [UPLOAD] Upload completed successfully');

      // Get download URL
      final downloadUrl = await photoRef.getDownloadURL();
      _logger.d('✅ [UPLOAD] Download URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('❌ [UPLOAD] Firebase error code: ${e.code}');
      _logger.e('❌ [UPLOAD] Firebase error message: ${e.message}');
      _logger.e('❌ [UPLOAD] Full error: ${e.toString()}');

      // Provide user-friendly error messages
      String userMessage = 'Failed to upload photo';
      if (e.code == 'storage/unauthorized') {
        userMessage = 'Permission denied. Please check Firebase Storage rules.';
      } else if (e.code == 'storage/canceled') {
        userMessage = 'Upload was canceled.';
      } else if (e.code == 'storage/quota-exceeded') {
        userMessage = 'Storage quota exceeded.';
      } else if (e.code == 'storage/unauthenticated') {
        userMessage = 'Authentication required to upload photos.';
      } else if (e.message != null) {
        userMessage = e.message!;
      }

      throw Exception(userMessage);
    } catch (e) {
      _logger.e('❌ [UPLOAD] Unexpected error: ${e.toString()}');
      throw Exception('Failed to upload photo: $e');
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
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text('Report Lost Person'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Emergency Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This data is sent immediately to Kumbh Mela authorities for rapid response.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    InputField(
                      label: 'Name of Lost Person',
                      hint: 'Enter full name',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age & Gender Row
                    Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: 'Age',
                            hint: 'Years',
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: SelectField<String>(
                            label: 'Gender',
                            hint: 'Select',
                            items: _genderOptions
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedGender = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Last Seen Location
                    InputField(
                      label: 'Last Seen Place',
                      hint: 'e.g. Sangam Ghat, Sector 4',
                      controller: _locationController,
                      prefixIcon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),

                    // Guardian Info
                    InputField(
                      label: 'Guardian Name (Optional)',
                      hint: 'Your name or family member',
                      controller: _guardianNameController,
                      prefixIcon: Icons.person,
                    ),
                    const SizedBox(height: 16),

                    InputField(
                      label: 'Guardian Phone (Optional)',
                      hint: '+91 XXXXX XXXXX',
                      controller: _guardianPhoneController,
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Photo Upload
                    Text(
                      'Upload Recent Photo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFD1D5DB),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _selectedImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildUploadPlaceholder(isDark),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _buildUploadPlaceholder(isDark),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description field
                    InputField(
                      label: 'Description',
                      hint: 'Describe height, clothing, identifying marks...',
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Provide details like height, clothing color, and any identifying marks.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.backgroundDark : Colors.white).withValues(
            alpha: 0.95,
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: SafeArea(
          child: PrimaryButton(
            text: 'SUBMIT REPORT',
            onPressed: _submitReport,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 48, color: AppColors.primaryBlue),
        const SizedBox(height: 8),
        Text(
          'Click to capture or upload',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Maximum file size: 5MB',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}

class _ImageSourceBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
