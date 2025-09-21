import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/activity_video.dart';
import '../widgets/activity_grid.dart';
import '../widgets/video_player_dialog.dart';
import '../data/activities.dart';

class ExerciseReminderDialog extends StatefulWidget {
  final int selectedInterval;
  final int totalWorkingTime; // Total time user has been working (in seconds)
  final VoidCallback onDismiss;
  final VoidCallback onSnooze1;
  final VoidCallback onSnooze5;
  final VoidCallback onSnooze10;
  final VoidCallback onSnooze15;

  const ExerciseReminderDialog({
    super.key,
    required this.selectedInterval,
    required this.totalWorkingTime,
    required this.onDismiss,
    required this.onSnooze1,
    required this.onSnooze5,
    required this.onSnooze10,
    required this.onSnooze15,
  });

  @override
  _ExerciseReminderDialogState createState() => _ExerciseReminderDialogState();
}

class _ExerciseReminderDialogState extends State<ExerciseReminderDialog> {
  late List<Activity> activities;
  int _currentActivityIndex = -1;
  bool _isPlayingSequence = false;

  @override
  void initState() {
    super.initState();
    activities = List.from(predefinedActivities);
  }

  void _onActivityCountChanged(String id, int newCount) {
    setState(() {
      final index = activities.indexWhere((activity) => activity.id == id);
      if (index != -1) {
        // If count is changing from 0 to a positive number, record the selection time
        if (activities[index].count == 0 && newCount > 0) {
          activities[index] = activities[index].copyWith(
            count: newCount,
            selectionTime: DateTime.now(),
          );
        } else {
          // If count is being set to 0, clear the selection time
          activities[index] = activities[index].copyWith(
            count: newCount,
            selectionTime:
                newCount > 0 ? activities[index].selectionTime : null,
          );
        }
      }
    });
  }

  Future<void> _playNextVideo() async {
    if (!mounted || !_isPlayingSequence) {
      print(
          'Not playing next video: mounted=$mounted, isPlayingSequence=$_isPlayingSequence');
      return;
    }

    // Get activities with count > 0 and sort by selection time
    var selectedActivities = activities
        .where((activity) =>
            activity.count > 0 &&
            activity.selectionTime != null &&
            VideoConfig.getVideoForTask(activity.id) != null)
        .toList()
      ..sort((a, b) => a.selectionTime!.compareTo(b.selectionTime!));

    // Find the next activity after current index
    Activity? nextActivity;
    if (_currentActivityIndex == -1) {
      nextActivity =
          selectedActivities.isNotEmpty ? selectedActivities.first : null;
    } else {
      var currentActivity = activities[_currentActivityIndex];
      var currentIndex =
          selectedActivities.indexWhere((a) => a.id == currentActivity.id);
      if (currentIndex < selectedActivities.length - 1) {
        nextActivity = selectedActivities[currentIndex + 1];
      }
    }

    if (nextActivity != null) {
      _currentActivityIndex =
          activities.indexWhere((a) => a.id == nextActivity!.id);
      final activity = activities[_currentActivityIndex];
      final video = VideoConfig.getVideoForTask(activity.id);

      if (video != null) {
        print(
            'Playing video ${_currentActivityIndex + 1} of ${activities.length}: ${activity.name} (${activity.count} times)');

        try {
          BuildContext dialogContext = context;
          // Show the video dialog
          await showDialog(
            context: dialogContext,
            barrierDismissible: false,
            useSafeArea: false,
            builder: (BuildContext context) {
              // Get sorted activities to find next in sequence
              var sortedActivities = activities
                  .where((activity) =>
                      activity.count > 0 &&
                      activity.selectionTime != null &&
                      VideoConfig.getVideoForTask(activity.id) != null)
                  .toList()
                ..sort((a, b) => a.selectionTime!.compareTo(b.selectionTime!));

              int currentSortedIndex =
                  sortedActivities.indexWhere((a) => a.id == activity.id);
              bool hasMoreActivities =
                  currentSortedIndex < sortedActivities.length - 1;

              // Get all remaining activities to determine if this is the last one
              var remainingActivities = activities
                  .where((a) =>
                      a.count > 0 &&
                      a.selectionTime != null &&
                      VideoConfig.getVideoForTask(a.id) != null)
                  .toList()
                ..sort((a, b) => a.selectionTime!.compareTo(b.selectionTime!));

              var currentIndex =
                  remainingActivities.indexWhere((a) => a.id == activity.id);
              var isLastActivity =
                  currentIndex == remainingActivities.length - 1;

              return VideoPlayerDialog(
                videoPath: video.videoPath,
                durationInSeconds: video.duration,
                repeatCount: activity.count,
                activityName: activity.name,
                isLastActivity: isLastActivity,
                onComplete: () async {
                  if (mounted) {
                    Navigator.of(context).pop();

                    if (currentSortedIndex >= sortedActivities.length - 1) {
                      // If this was the last activity, show completion dialog
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text('All Activities Completed! 🎉'),
                          content: const Text(
                              'Great job! You\'ve completed all your activities.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(); // Close alert dialog
                                setState(() {
                                  _isPlayingSequence = false;
                                  _currentActivityIndex = -1;
                                });
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Move to next video after transition
                      if (_isPlayingSequence) {
                        Future.delayed(
                            const Duration(milliseconds: 500), _playNextVideo);
                      }
                    }
                  }
                },
              );
            },
          );
        } catch (e) {
          print('Error showing video dialog: $e');
        }
      } else {
        print('No video found for activity: ${activity.name}');
        // Skip activities without videos
        if (_isPlayingSequence) {
          _playNextVideo();
        }
      }
    } else {
      print('All videos have been played');
      // All videos have been played
      setState(() {
        _isPlayingSequence = false;
        _currentActivityIndex = -1;
      });
    }
  }

  void _startActivitySequence() {
    print('Start Activities button clicked');
    print('Current activities and their counts:');
    for (var activity in activities) {
      print('${activity.name}: ${activity.count}');
    }

    if (!_isPlayingSequence) {
      print('Starting activity sequence');
      setState(() {
        _isPlayingSequence = true;
        _currentActivityIndex = -1;
      });
      _playNextVideo();
    } else {
      print('Sequence already in progress');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 20,
      child: Container(
        width: 800, // Wider to show more items per row
        height: 800, // Taller to fit all content
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
                    '🎉 Time for a Break! 🎉',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You\'ve been working for ${_formatWorkingTime(widget.totalWorkingTime)}!\nTime to give your body some love.',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.totalWorkingTime >= 3600
                          ? Colors.red
                          : Colors.grey[700],
                      height: 1.4,
                      fontWeight: widget.totalWorkingTime >= 3600
                          ? FontWeight.bold
                          : FontWeight.normal,
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
                  const Text(
                    'Remind me again in:',
                    style: TextStyle(
                      fontSize: 16, // Adjust style as needed
                      fontWeight:
                          FontWeight.w600, // Optional: make it a bit bolder
                      color: Colors.black54, // Adjust color
                    ),
                  ),
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.selectedInterval > 0
                              ? _startActivitySequence
                              : null,
                          icon: const Icon(Icons.play_circle, size: 18),
                          label: const Text('Start Activities'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.selectedInterval > 0
                                ? Colors.blue[600]
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWorkingTime(int totalSeconds) {
    if (totalSeconds >= 3600) {
      int hours = totalSeconds ~/ 3600;
      int minutes = (totalSeconds % 3600) ~/ 60;
      return '$hours hour${hours > 1 ? 's' : ''} and $minutes minute${minutes != 1 ? 's' : ''}';
    } else {
      int minutes = totalSeconds ~/ 60;
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    }
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
