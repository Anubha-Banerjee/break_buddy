import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../widgets/activity_grid.dart';
import '../data/activities.dart';

class ExerciseReminderDialog extends StatefulWidget {
  final int selectedInterval;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze1;
  final VoidCallback onSnooze5;
  final VoidCallback onSnooze10;
  final VoidCallback onSnooze15;

  const ExerciseReminderDialog({
    Key? key,
    required this.selectedInterval,
    required this.onDismiss,
    required this.onSnooze1,
    required this.onSnooze5,
    required this.onSnooze10,
    required this.onSnooze15,
  }) : super(key: key);

  @override
  _ExerciseReminderDialogState createState() => _ExerciseReminderDialogState();
}

class _ExerciseReminderDialogState extends State<ExerciseReminderDialog> {
  late List<Activity> activities;

  @override
  void initState() {
    super.initState();
    activities = List.from(predefinedActivities);
  }

  void _onActivityCountChanged(String id, int newCount) {
    setState(() {
      final index = activities.indexWhere((activity) => activity.id == id);
      if (index != -1) {
        activities[index] = activities[index].copyWith(count: newCount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 20,
      child: Container(
        width: 800, // Wider to show more items per row
        height: 700, // Taller to fit all content
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.white, Colors.green[50]!],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[700]!],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '🎉 Time for Exercise! 🎉',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You\'ve been working for ${(widget.selectedInterval / 60).toInt()} minutes!\nTime to give your body some love.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ActivityGrid(
                activities: activities,
                onActivityCountChanged: _onActivityCountChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSnoozeButton('1m', widget.onSnooze1),
                      _buildSnoozeButton('5m', widget.onSnooze5),
                      _buildSnoozeButton('10m', widget.onSnooze10),
                      _buildSnoozeButton('15m', widget.onSnooze15),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onDismiss,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Done! Reset timer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange[600],
            side: BorderSide(color: Colors.orange[400]!, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
