import 'package:flutter/material.dart';

class SettingsDialog extends StatefulWidget {
  final int defaultDuration;
  final Function(int newDuration) onDurationChanged;

  const SettingsDialog({
    Key? key,
    required this.defaultDuration,
    required this.onDurationChanged,
  }) : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.defaultDuration;
  }

  @override
  Widget build(BuildContext context) {
    final timerOptions = {
      '30 minutes': 1800,
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
              children: timerOptions.entries.map((entry) {
                return RadioListTile<int>(
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 16),
                  ),
                  value: entry.value,
                  groupValue: _selectedDuration,
                  onChanged: (value) {
                    setState(() {
                      _selectedDuration = value!;
                    });
                  },
                  activeColor: Colors.blue[600],
                );
              }).toList(),
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
