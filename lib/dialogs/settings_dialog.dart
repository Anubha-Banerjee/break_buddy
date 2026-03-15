import 'package:flutter/material.dart';

class SettingsDialog extends StatefulWidget {
  final int defaultDuration;
  final Function(int newDuration) onDurationChanged;
  final VoidCallback? onAddCustomActivity;

  const SettingsDialog({
    Key? key,
    required this.defaultDuration,
    required this.onDurationChanged,
    this.onAddCustomActivity,
  }) : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _selectedDuration;
  late TextEditingController _customDurationController;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.defaultDuration;
    _customDurationController = TextEditingController();

    // Check if the current duration matches any preset option
    final timerOptions = {
      '30 minutes': 1800,
      '40 minutes': 2400,
      '45 minutes': 2700,
      '60 minutes': 3600,
    };

    _isCustom = !timerOptions.containsValue(_selectedDuration);
    if (_isCustom) {
      _customDurationController.text = (_selectedDuration ~/ 60).toString();
    }
  }

  @override
  void dispose() {
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerOptions = {
      '30 minutes': 1800,
      '40 minutes': 2400,
      '45 minutes': 2700,
      '60 minutes': 3600,
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settings',
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

            // Default Timer Duration Setting
            const Text(
              'Default Timer Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Radio buttons for timer duration
            Column(
              children: [
                ...timerOptions.entries.map((entry) {
                  return RadioListTile<int>(
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16),
                    ),
                    value: entry.value,
                    groupValue: _isCustom ? -1 : _selectedDuration,
                    onChanged: (value) {
                      setState(() {
                        _selectedDuration = value!;
                        _isCustom = false;
                        _customDurationController.clear();
                      });
                    },
                    activeColor: Colors.blue[600],
                  );
                }).toList(),
                // Custom option
                RadioListTile<bool>(
                  title: const Text(
                    'Custom',
                    style: TextStyle(fontSize: 16),
                  ),
                  value: true,
                  groupValue: _isCustom,
                  onChanged: (value) {
                    setState(() {
                      _isCustom = value ?? false;
                      if (_isCustom) {
                        _customDurationController.text =
                            (_selectedDuration ~/ 60).toString();
                      }
                    });
                  },
                  activeColor: Colors.blue[600],
                ),
              ],
            ),

            // Custom duration input
            if (_isCustom)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customDurationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter minutes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          final minutes = int.tryParse(value);
                          if (minutes != null && minutes > 0) {
                            setState(() {
                              _selectedDuration = minutes * 60;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'minutes',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const Divider(height: 24),

            // Custom Activities Section
            const Text(
              'Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onAddCustomActivity,
                icon: const Icon(Icons.upload_file),
                label: const Text('Add Custom Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Text(
                'Create your own activities by uploading custom videos. Each repetition will loop the entire video once.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),

            const Divider(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onDurationChanged(_selectedDuration);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Default duration set to ${_selectedDuration ~/ 60} minutes',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
