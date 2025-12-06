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
  final VoidCallback onRandomActivity; // Callback for random activity
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
    required this.onRandomActivity,
    this.dialogHeight = 850, // Default height
    this.sequenceService,
  });

  @override
  _ExerciseReminderDialogState createState() => _ExerciseReminderDialogState();
}

class _ExerciseReminderDialogState extends State<ExerciseReminderDialog> {
  late List<Activity> activities;
  late Map<String, int>
      completedActivityCounts; // Track activity ID -> completion count
  late Map<String, int>
      activityTimeSpent; // Track activity ID -> time spent in seconds
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
                  // Get the first activity's icon and thumbnail from the sequence
                  final firstActivityIcon = sequence.activities.isNotEmpty
                      ? sequence.activities.first.icon
                      : Icons.playlist_play;
                  final firstActivityThumbnail = sequence.activities.isNotEmpty
                      ? sequence.activities.first.thumbnailPath
                      : null;

                  activities.add(Activity(
                    id: 'seq_${sequence.id}',
                    name: sequence.name,
                    icon: firstActivityIcon,
                    thumbnailPath: firstActivityThumbnail,
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
    completedActivityCounts = {};
    activityTimeSpent = {};
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
          // Get the first activity's icon and thumbnail from the sequence
          final firstActivityIcon = seq.activities.isNotEmpty
              ? seq.activities.first.icon
              : Icons.playlist_play;
          final firstActivityThumbnail = seq.activities.isNotEmpty
              ? seq.activities.first.thumbnailPath
              : null;
          return Activity(
            id: 'seq_${seq.id}',
            name: seq.name,
            icon: firstActivityIcon,
            thumbnailPath: firstActivityThumbnail,
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

  // Handle video completion from direct tile clicks (not from "Start Activities" flow)
  void _onActivityVideoComplete(String activityId, int completedCount) {
    print(
        '[DEBUG] Direct tile video complete: $activityId, completedCount=$completedCount');

    bool userQuit = false;
    int actualCount = completedCount;

    // Check if quit signal was sent (negative value)
    if (completedCount < 0) {
      userQuit = true;
      actualCount = -completedCount;
    }

    print('[DEBUG] User quit: $userQuit, actual count: $actualCount');

    if (actualCount > 0) {
      // Find the activity and record it to stats
      final activityIndex = activities.indexWhere((a) => a.id == activityId);
      if (activityIndex != -1) {
        final activity = activities[activityIndex];
        print(
            '[DEBUG] Recording direct activity: ${activity.name}, count=$actualCount');

        // Record the activity in completedActivityCounts
        completedActivityCounts[activity.id] = actualCount;

        // Update the activity count in the list
        setState(() {
          activities[activityIndex] = activity.copyWith(count: 0);
        });
      }
    }
  }

  void _onActivityTimeTracked(
      String activityId, int count, int timeSpentSeconds) {
    print(
        '[DEBUG] Activity time tracked: $activityId, count=$count, time=${timeSpentSeconds}s');

    // Find the activity
    final activityIndex = activities.indexWhere((a) => a.id == activityId);
    if (activityIndex != -1) {
      final activity = activities[activityIndex];
      print('[DEBUG] Recording time for activity: ${activity.name}');

      // Store the time spent for this activity
      // If tracking multiple reps, store the total time
      activityTimeSpent[activity.id] =
          (activityTimeSpent[activity.id] ?? 0) + timeSpentSeconds;
      print(
          '[DEBUG] Total time for ${activity.name}: ${activityTimeSpent[activity.id]}s');
    }
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
                onTimeTracked: (count, timeSpent) {
                  print(
                      '[DEBUG] Sequence video time tracked: ${activity.name}, count=$count, time=${timeSpent}s');
                  activityTimeSpent[activity.id] =
                      (activityTimeSpent[activity.id] ?? 0) + timeSpent;
                  print(
                      '[DEBUG] Total time for ${activity.name}: ${activityTimeSpent[activity.id]}s');
                },
                onComplete: (int completedCount) async {
                  if (mounted) {
                    Navigator.of(context).pop();

                    // Check if user clicked quit (negative value signals quit)
                    bool userQuit = completedCount < 0;
                    int actualCount =
                        userQuit ? -completedCount : completedCount;

                    // Use the actual completed count from the video player
                    // This handles cases where user quits before completing all reps
                    final actualCompletedCount =
                        actualCount > 0 ? actualCount : 0;

                    print(
                        '[DEBUG] onComplete called: completedCount=$completedCount, userQuit=$userQuit, actualCount=$actualCount, actualCompletedCount=$actualCompletedCount');
                    print(
                        '[DEBUG] Activity: ${activity.name} (${activity.id})');

                    // Mark this activity as completed in our tracking map
                    setState(() {
                      completedActivityCounts[activity.id] =
                          actualCompletedCount;
                      print(
                          '[DEBUG] Stored in completedActivityCounts: ${activity.id} => $actualCompletedCount');
                      final index =
                          activities.indexWhere((a) => a.id == activity.id);
                      if (index != -1) {
                        activities[index] =
                            activities[index].copyWith(count: 0);
                      }
                    });

                    // If user quit, stop the sequence after recording this activity
                    if (userQuit) {
                      print('User quit the sequence');
                      setState(() {
                        _isPlayingSequence = false;
                        _currentActivityIndex = -1;
                      });
                      return;
                    }

                    // Check if there are any remaining activities with count > 0
                    final hasRemainingActivities = activities.any((a) {
                      if (a.id == activity.id) {
                        return false;
                      }
                      return a.count > 0 &&
                          !a.id.startsWith('seq_') &&
                          VideoConfig.getVideoForTask(a.id) != null;
                    });

                    if (!hasRemainingActivities) {
                      // If this was the last activity, show completion dialog
                      if (mounted) {
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
                      }
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
                onActivityVideoComplete: _onActivityVideoComplete,
                onTimeTracked: _onActivityTimeTracked,
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

                  // Keep the original index and a copy of the sequence activity to restore it later
                  final originalIndex =
                      activities.indexWhere((a) => a.id == sequence.id);
                  final sequenceActivityCopy = originalIndex != -1
                      ? activities[originalIndex].copyWith()
                      : null;

                  // Set count to 1 and start sequence
                  setState(() {
                    if (originalIndex != -1) {
                      activities[originalIndex] =
                          activities[originalIndex].copyWith(
                        count: 1,
                        selectionTime: DateTime.now(),
                      );
                    }
                  });

                  // Start the sequence
                  _startActivitySequence();

                  // After a delay to let the sequence start, restore the sequence activity
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted && sequenceActivityCopy != null) {
                      setState(() {
                        // Check if the sequence still exists in storage
                        final sequenceStillExists = widget.sequenceService!
                                .getSequenceById(sequence.id.substring(4)) !=
                            null;

                        if (sequenceStillExists) {
                          // Find the sequence in the current activities list
                          final currentIndex = activities.indexWhere(
                              (a) => a.id == sequenceActivityCopy.id);

                          if (currentIndex != -1) {
                            // Restore with count = 0
                            activities[currentIndex] =
                                sequenceActivityCopy.copyWith(count: 0);
                          } else {
                            // If not found, add it back at the original position
                            if (originalIndex <= activities.length) {
                              activities.insert(originalIndex,
                                  sequenceActivityCopy.copyWith(count: 0));
                            } else {
                              activities
                                  .add(sequenceActivityCopy.copyWith(count: 0));
                            }
                          }
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

                  // Reset activities and Random Activity buttons in a row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[600],
                          side:
                          BorderSide(color: Colors.red[400]!, width: 1.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onRandomActivity,
                        icon: const Icon(Icons.casino, size: 16),
                        label: const Text('Random'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo[600],
                          side: BorderSide(
                              color: Colors.indigo[400]!, width: 1.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
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
                            print('\n[DEBUG] Done button clicked');
                            print(
                                '[DEBUG] completedActivityCounts: $completedActivityCounts');
                            print(
                                '[DEBUG] activityTimeSpent: $activityTimeSpent');
                            print('[DEBUG] activities in dialog:');
                            for (var a in activities) {
                              print(
                                  '  - ${a.name} (${a.id}): count=${a.count}');
                            }

                            // Get completed activities and restore their counts from our tracking map
                            final completedActivities = activities
                                .where((a) =>
                                    completedActivityCounts.containsKey(a.id))
                                .map((a) => a.copyWith(
                                      count: completedActivityCounts[a.id] ?? 0,
                                      timeSpent: activityTimeSpent[a.id] ?? 0,
                                    ))
                                .toList();

                            print('\nCompleted activities for stats:');
                            for (var activity in completedActivities) {
                              print(
                                  '- ${activity.name} (${activity.id}): count=${activity.count}, time=${activity.timeSpent}s');
                            }

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
