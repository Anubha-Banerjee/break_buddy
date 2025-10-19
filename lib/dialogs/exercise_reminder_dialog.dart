import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/activity_video.dart';
import '../models/activity_sequence.dart';
import '../widgets/activity_grid.dart';
import '../widgets/video_player_dialog.dart';
import '../data/activities.dart';
import '../services/activity_sequence_service.dart';
import '../utils/sequence_expander.dart';

class ExerciseReminderDialog extends StatefulWidget {
  final int selectedInterval;
  final int totalWorkingTime; // Total time user has been working (in seconds)
  final void Function(List<Activity> completedActivities) onDismiss;
  final VoidCallback onSnooze1;
  final VoidCallback onSnooze5;
  final VoidCallback onSnooze10;
  final VoidCallback onSnooze15;
  final double dialogHeight; // Height of the dialog
  final ActivitySequenceService? sequenceService;

  const ExerciseReminderDialog({
    super.key,
    required this.selectedInterval,
    required this.totalWorkingTime,
    required this.onDismiss,
    required this.onSnooze1,
    required this.onSnooze5,
    required this.onSnooze10,
    required this.onSnooze15,
    this.dialogHeight = 850, // Default height
    this.sequenceService,
  });

  @override
  _ExerciseReminderDialogState createState() => _ExerciseReminderDialogState();
}

class _ExerciseReminderDialogState extends State<ExerciseReminderDialog> {
  late List<Activity> activities;
  int _currentActivityIndex = -1;
  bool _isPlayingSequence = false;
  final TextEditingController _sequenceNameController = TextEditingController();

  Future<void> _showSaveSequenceDialog(BuildContext context) async {
    _sequenceNameController.text =
        'Sequence ${DateTime.now().toString().substring(0, 16)}';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Activity Sequence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Name your sequence:'),
            TextField(
              controller: _sequenceNameController,
              decoration: const InputDecoration(
                hintText: 'Enter sequence name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_sequenceNameController.text.isNotEmpty &&
                  widget.sequenceService != null) {
                // Filter out any sequence activities and only save original activities
                final selectedActivities = activities
                    .where((a) => a.count > 0 && !a.id.startsWith('seq_'))
                    .map((a) {
                  print('Saving activity in sequence: ${a.name} (${a.id})');
                  print('Selection time: ${a.selectionTime}');
                  return Activity(
                    id: a.id,
                    name: a.name,
                    icon: a.icon,
                    count: a.count,
                    selectionTime: a.selectionTime,
                  );
                }).toList();

                if (selectedActivities.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select some activities to save'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final sequence = ActivitySequence(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _sequenceNameController.text,
                  activities: selectedActivities,
                  createdAt: DateTime.now(),
                );

                print('Saving sequence with activities:');
                for (var activity in selectedActivities) {
                  print(
                      '- ${activity.name} (ID: ${activity.id}) with count: ${activity.count}');
                }

                // Add sequence to predefined activities
                setState(() {
                  activities.add(Activity(
                    id: 'seq_${sequence.id}',
                    name: sequence.name,
                    icon: Icons.playlist_play,
                    count: 0,
                  ));
                });

                // Save the sequence
                await widget.sequenceService!.addSequenceAndNotify(sequence);

                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Sequence "${_sequenceNameController.text}" saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeActivities();
  }

  Future<void> _initializeActivities() async {
    print('\nInitializing activities...');
    // Start with predefined activities
    activities = List.from(predefinedActivities);

    // Load saved sequences
    if (widget.sequenceService != null) {
      // Clear any existing sequences first
      activities.removeWhere((a) => a.id.startsWith('seq_'));

      // Load fresh sequences from storage
      final loadedSequences = await widget.sequenceService!.loadSequences();
      print('Loaded ${loadedSequences.length} sequences');

      // Add sequence activities
      if (loadedSequences.isNotEmpty) {
        final sequenceActivities = loadedSequences.map((seq) {
          print('Adding sequence: ${seq.name} (${seq.id})');
          return Activity(
            id: 'seq_${seq.id}',
            name: seq.name,
            icon: Icons.playlist_play,
            count: 0,
          );
        }).toList();

        setState(() {
          activities.addAll(sequenceActivities);
        });
      }
    }
  }

  void _onActivityCountChanged(String id, int newCount) {
    setState(() {
      final index = activities.indexWhere((activity) => activity.id == id);
      if (index != -1) {
        // If count is changing from 0 to a positive number, record the selection time
        if (activities[index].count == 0 && newCount > 0) {
          final now = DateTime.now();
          print('\nActivity selected: ${activities[index].name} at $now');
          activities[index] = activities[index].copyWith(
            count: newCount,
            selectionTime: now,
          );

          // Debug: Print all selected activities in order
          print('\nCurrent selected activities in order:');
          final selectedActivities = activities
              .where((a) => a.count > 0 && !a.id.startsWith('seq_'))
              .toList();
          selectedActivities.sort((a, b) {
            final aTime = a.selectionTime;
            final bTime = b.selectionTime;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });
          for (var a in selectedActivities) {
            print('- ${a.name} selected at ${a.selectionTime}');
          }
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

    // First check if we have any sequences that need expansion
    bool hasSequences =
        activities.any((a) => a.count > 0 && a.id.startsWith('seq_'));
    if (hasSequences && widget.sequenceService != null) {
      print('\nExpanding sequences before playing videos');
      final expandedActivities = SequenceExpander.expandAllSequences(
        activities,
        widget.sequenceService!,
      );
      // Find all sequence activities that need to be replaced
      final sequenceActivities = activities
          .where((a) => a.count > 0 && a.id.startsWith('seq_'))
          .toList();

      setState(() {
        // Remove the sequence activities
        activities.removeWhere((a) => sequenceActivities.contains(a));
        // Add the expanded activities
        activities.addAll(expandedActivities);

        // Sort all activities by their selection time
        activities.sort((a, b) {
          final aTime = a.selectionTime;
          final bTime = b.selectionTime;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return aTime.compareTo(bTime);
        });
      });
      print('\nExpanded activities:');
      expandedActivities
          .forEach((a) => print('- ${a.name} (${a.id}): ${a.count}'));
    }

    // Get only activities that have videos and are not sequences
    var selectedActivities = activities
        .where((activity) =>
            activity.count > 0 &&
            !activity.id.startsWith('seq_') &&
            VideoConfig.getVideoForTask(activity.id) != null)
        .toList()
      ..sort((a, b) {
        final aTime = a.selectionTime;
        final bTime = b.selectionTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

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
      print('\nPlaying next activity...');
      print('Selected activities in playback order:');
      selectedActivities.forEach(
          (a) => print('- ${a.name} (selected at ${a.selectionTime})'));

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

              // Get next activity name if available
              String? nextActivityName;
              if (!isLastActivity &&
                  currentSortedIndex + 1 < sortedActivities.length) {
                nextActivityName =
                    sortedActivities[currentSortedIndex + 1].name;
              }

              return VideoPlayerDialog(
                videoPath: video.videoPath,
                durationInSeconds: video.duration,
                repeatCount: activity.count,
                activityName: activity.name,
                isLastActivity: isLastActivity,
                nextActivityName: nextActivityName,
                onComplete: (int completedCount) async {
                  // Update the activity count with actual completed reps
                  setState(() {
                    final index =
                        activities.indexWhere((a) => a.id == activity.id);
                    if (index != -1) {
                      activities[index] =
                          activities[index].copyWith(count: completedCount);
                    }
                  });
                  if (mounted) {
                    Navigator.of(context).pop();

                    setState(() {
                      // Mark this activity as completed by setting count to 0
                      final index =
                          activities.indexWhere((a) => a.id == activity.id);
                      if (index != -1) {
                        activities[index] =
                            activities[index].copyWith(count: 0);
                      }
                    });

                    // Check if there are any remaining activities with count > 0
                    final hasRemainingActivities = activities.any((a) =>
                        a.count > 0 &&
                        !a.id.startsWith('seq_') &&
                        VideoConfig.getVideoForTask(a.id) != null);

                    if (!hasRemainingActivities) {
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
                    } else if (_isPlayingSequence) {
                      // Move to next video after transition
                      Future.delayed(
                          const Duration(milliseconds: 500), _playNextVideo);
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
    print('\nStart Activities button clicked');
    print('Current activities with counts:');
    activities
        .where((a) => a.count > 0)
        .forEach((a) => print('- ${a.name} (${a.id}): ${a.count}'));

    if (widget.sequenceService == null) {
      print('ERROR: No sequence service available');
      return;
    }

    // Store original activities order
    final originalOrder = List<Activity>.from(activities);

    // Create a list to hold activities to be played
    List<Activity> activitiesToPlay = [];
    List<Activity> sequencesToRemove = [];

    // Process each selected activity
    for (var activity in originalOrder) {
      if (activity.count > 0) {
        if (activity.id.startsWith('seq_')) {
          print('\nExpanding sequence: ${activity.name}');
          sequencesToRemove.add(activity);
          // Expand sequence into its component activities
          final expandedActivities = SequenceExpander.expandSequence(
            activity,
            widget.sequenceService!,
          );
          // Keep original order within sequence
          activitiesToPlay.addAll(expandedActivities);
        } else {
          // Keep original activity
          activitiesToPlay.add(activity.copyWith(
            selectionTime: activity.selectionTime ?? DateTime.now(),
          ));
        }
      }
    }

    print('\nFinal activity list for playback:');
    activitiesToPlay.forEach((a) => print('- ${a.name} (${a.id}): ${a.count}'));

    // If there's a sequence in progress, stop it first
    if (_isPlayingSequence) {
      print('Stopping current sequence and starting new one');
      setState(() {
        _isPlayingSequence = false;
        _currentActivityIndex = -1;
      });
    }

    // Update activities list with expanded version and start playback
    setState(() {
      // Keep original activities but update with expanded ones
      activities = List<Activity>.from(originalOrder);

      // Remove sequence activities
      activities.removeWhere((a) => sequencesToRemove.contains(a));

      // Add expanded activities while maintaining original order
      for (var activity in activitiesToPlay) {
        // Find existing activity or add new one at the end
        final existingIndex = activities.indexWhere((a) => a.id == activity.id);
        if (existingIndex != -1) {
          activities[existingIndex] = activity;
        } else {
          activities.add(activity);
        }
      }

      _isPlayingSequence = true;
      _currentActivityIndex = -1;
    });

    // Start playback after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _playNextVideo();
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
        height: widget.dialogHeight, // Configurable height
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'You\'ve been working for '),
                        TextSpan(
                          text: _formatWorkingTime(widget.totalWorkingTime),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.totalWorkingTime >= 3600
                                ? Colors.red
                                : Colors.blue[700],
                          ),
                        ),
                        const TextSpan(
                            text: '!\nTime to give your body some love.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ActivityGrid(
                activities: activities,
                onActivityCountChanged: _onActivityCountChanged,
                onDeleteSequence: (sequence) async {
                  if (widget.sequenceService != null) {
                    final sequenceId =
                        sequence.id.substring(4); // Remove 'seq_' prefix
                    print('\nDeleting sequence: $sequenceId');

                    // First verify sequence exists
                    final existingSequence =
                        widget.sequenceService!.getSequenceById(sequenceId);
                    if (existingSequence == null) {
                      print(
                          'Sequence not found in storage, cleaning up UI only');
                      setState(() {
                        activities.removeWhere((a) => a.id == sequence.id);
                      });
                      return;
                    }

                    try {
                      // Remove from UI immediately
                      setState(() {
                        activities.removeWhere((a) => a.id == sequence.id);
                      });

                      // Delete from storage
                      final deleted = await widget.sequenceService!
                          .deleteSequence(sequenceId);

                      if (deleted) {
                        // Show success message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Sequence "${sequence.name}" deleted'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }

                        // Reload activities to ensure everything is in sync
                        await _initializeActivities();
                      } else {
                        print('Failed to delete sequence from storage');
                        // Show error message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to delete sequence'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error deleting sequence: $e');
                      // Show error message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting sequence: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
                onPlaySequence: (sequence) {
                  if (widget.sequenceService == null) return;

                  // Keep a copy of the sequence activity for later
                  final sequenceActivity =
                      activities.firstWhere((a) => a.id == sequence.id);

                  // Set count to 1 and start sequence
                  setState(() {
                    final index =
                        activities.indexWhere((a) => a.id == sequence.id);
                    if (index != -1) {
                      activities[index] = activities[index].copyWith(
                        count: 1,
                        selectionTime: DateTime.now(),
                      );
                    }
                  });

                  // Start the sequence
                  _startActivitySequence();

                  // After a delay to let the sequence start, restore the sequence activity
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        // First check if sequence still exists in storage
                        final sequenceStillExists = widget.sequenceService!
                                .getSequenceById(sequence.id.substring(4)) !=
                            null;

                        if (sequenceStillExists) {
                          // Remove any old instances of this sequence
                          activities.removeWhere((a) => a.id == sequence.id);
                          // Add the sequence back with count = 0
                          activities.add(sequenceActivity.copyWith(count: 0));
                        }
                      });
                    }
                  });
                },
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
                  const SizedBox(height: 10),
                  // Reset activities button
                  OutlinedButton.icon(
                    onPressed: activities.any((a) => a.count > 0)
                        ? () {
                            setState(() {
                              for (var activity in activities) {
                                _onActivityCountChanged(activity.id, 0);
                              }
                            });
                          }
                        : null,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset Activities'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[400]!, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.selectedInterval > 0 &&
                                  activities.any((a) => a.count > 0)
                              ? _startActivitySequence
                              : null,
                          icon: const Icon(Icons.play_circle, size: 18),
                          label: const Text('Start Activities'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (widget.selectedInterval > 0 &&
                                    activities.any((a) => a.count > 0))
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
                          onPressed: activities.any((a) => a.count > 0)
                              ? () => _showSaveSequenceDialog(context)
                              : null,
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save Activities'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activities.any((a) => a.count > 0)
                                ? Colors.green[600]
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
                          onPressed: () {
                            // Get completed activities
                            // Get activities that have been started or completed
                            final completedActivities = activities.where((a) {
                              if (a.count > 0) {
                                // If the activity was in progress but not completed, count only the actual reps
                                if (_currentActivityIndex != -1 &&
                                    activities[_currentActivityIndex].id ==
                                        a.id) {
                                  return true;
                                }
                                // Otherwise include if it was selected
                                return true;
                              }
                              return false;
                            }).toList();
                            widget.onDismiss(completedActivities);
                          },
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
