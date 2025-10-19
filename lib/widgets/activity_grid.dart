import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_tile.dart';
import 'sequence_tile.dart';

class ActivityGrid extends StatelessWidget {
  final List<Activity> activities;
  final Function(String, int) onActivityCountChanged;
  final Function(Activity) onDeleteSequence;
  final Function(Activity) onPlaySequence;

  const ActivityGrid({
    super.key,
    required this.activities,
    required this.onActivityCountChanged,
    required this.onDeleteSequence,
    required this.onPlaySequence,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, // Show 6 items per row
        childAspectRatio: 0.7, // Made tiles slightly taller
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        if (activity.id.startsWith('seq_')) {
          return SequenceTile(
            sequence: activity,
            onPlay: () => onPlaySequence(activity),
            onDelete: () => onDeleteSequence(activity),
          );
        } else {
          return ActivityTile(
            activity: activity,
            onCountChanged: (newCount) {
              onActivityCountChanged(activity.id, newCount);
            },
          );
        }
      },
    );
  }
}
