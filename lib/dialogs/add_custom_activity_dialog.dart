import 'package:flutter/material.dart';
import 'dart:io';import 'package:file_picker/file_picker.dart';import '../models/custom_activity.dart';
import '../services/custom_activity_service.dart';

class AddCustomActivityDialog extends StatefulWidget {
  final Function(CustomActivity) onActivityAdded;

  const AddCustomActivityDialog({
    Key? key,
    required this.onActivityAdded,
  }) : super(key: key);

  @override
  State<AddCustomActivityDialog> createState() =>
      _AddCustomActivityDialogState();
}

class _AddCustomActivityDialogState extends State<AddCustomActivityDialog> {
  late TextEditingController _nameController;
  late TextEditingController _videoPathController;
  bool _isLoading = false;
  String? _errorMessage;
  final CustomActivityService _customActivityService = CustomActivityService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _videoPathController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _videoPathController.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv', 'wmv', 'wav'],
        dialogTitle: 'Select Video File',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _videoPathController.text = result.files.single.path!;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _createActivity() async {
    final name = _nameController.text.trim();
    final videoPath = _videoPathController.text.trim();

    // Validation
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an activity name';
      });
      return;
    }

    if (videoPath.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a video file path';
      });
      return;
    }

    // Check if file exists
    if (!File(videoPath).existsSync()) {
      setState(() {
        _errorMessage = 'Video file not found at: $videoPath';
      });
      return;
    }

    // Check if file is a video
    final extension = videoPath.split('.').last.toLowerCase();
    if (!['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv', 'wmv', 'wav']
        .contains(extension)) {
      setState(() {
        _errorMessage =
            'Unsupported video format. Supported: mp4, avi, mov, mkv, webm, flv, wmv, wav';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Generate a unique audio/sound icon Color based on activity name
      // Create the custom activity
      final activityId = _customActivityService.generateActivityId();

      final customActivity = CustomActivity(
        id: activityId,
        name: name,
        videoFilePath: videoPath,
        generatedThumbnailPath:
            null, // Can be extended later with thumbnail generation
        icon: Icons.video_library,
      );

      // Save the activity
      await _customActivityService.saveCustomActivity(customActivity);

      // Close dialog and notify parent
      if (mounted) {
        widget.onActivityAdded(customActivity);
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity "$name" created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating activity: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Custom Activity',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Activity Name Input
              const Text(
                'Activity Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., My Custom Exercise',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Video File Selection
              const Text(
                'Video File',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (_videoPathController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.video_library, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _videoPathController.text.split(Platform.pathSeparator).last,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _videoPathController.clear();
                                    });
                                  },
                                  child: Icon(Icons.clear, color: Colors.red[600], size: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _videoPathController.text,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickVideoFile,
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Choose Different File'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _pickVideoFile,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Browse & Select Video File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supported formats:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'MP4, AVI, MOV, MKV, WebM, FLV, WMV, WAV',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 20),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Tips:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• One repetition = entire video looped once\n'
                      '• Video will be played with the set count\n'
                      '• Icon will be a generic video icon',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createActivity,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isLoading ? 'Creating...' : 'Create Activity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
