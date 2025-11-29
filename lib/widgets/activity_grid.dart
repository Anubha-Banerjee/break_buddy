import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_tile.dart';
import 'sequence_tile.dart';

class ActivityGrid extends StatelessWidget {
  final List<Activity> activities;
  final Function(String, int) onActivityCountChanged;
  final Function(Activity) onDeleteSequence;
  final Function(Activity) onPlaySequence;
  final Function(String, int)?
      onActivityVideoComplete; // New callback for video completion
  final Function(String, int, int)?
      onTimeTracked; // Track time: (activityId, count, timeSpent)

  const ActivityGrid({
    super.key,
    required this.activities,
    required this.onActivityCountChanged,
    required this.onDeleteSequence,
    required this.onPlaySequence,
    this.onActivityVideoComplete,
    this.onTimeTracked,
  });

  @override
  Widget build(BuildContext context) {
    // Sort activities to show sequences first, then regular activities
    final sortedActivities = List<Activity>.from(activities)
      ..sort((a, b) {
        // Sequences come first
        final aIsSequence = a.id.startsWith('seq_');
        final bIsSequence = b.id.startsWith('seq_');

        if (aIsSequence && !bIsSequence) return -1;
        if (!aIsSequence && bIsSequence) return 1;

        // If both are same type, maintain original order
        return activities.indexOf(a).compareTo(activities.indexOf(b));
      });

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, // Show 6 items per row
        childAspectRatio: 0.7, // Made tiles slightly taller
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sortedActivities.length,
      itemBuilder: (context, index) {
        final activity = sortedActivities[index];
        if (activity.id.startsWith('seq_')) {
          return SequenceTile(
            sequence: activity,
            firstActivityIcon: activity.icon,
            firstActivityThumbnail: activity.thumbnailPath,
            onPlay: () => onPlaySequence(activity),
            onDelete: () => onDeleteSequence(activity),
          );
        } else {
          return ActivityTile(
            activity: activity,
            onCountChanged: (newCount) {
              onActivityCountChanged(activity.id, newCount);
            },
            onVideoComplete: onActivityVideoComplete != null
                ? (completedCount) =>
                    onActivityVideoComplete!(activity.id, completedCount)
                : null,
            onTimeTracked: onTimeTracked != null
                ? (count, timeSpent) =>
                    onTimeTracked!(activity.id, count, timeSpent)
                : null,
          );
        }
      },
    );
  }
}
