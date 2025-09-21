import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_tile.dart';

class ActivityGrid extends StatelessWidget {
  final List<Activity> activities;
  final Function(String, int) onActivityCountChanged;

  const ActivityGrid({
    super.key,
    required this.activities,
    required this.onActivityCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, // Show 6 items per row
        childAspectRatio: 0.65, // Increased height to prevent overflow
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return ActivityTile(
          activity: activities[index],
          onCountChanged: (newCount) {
            onActivityCountChanged(activities[index].id, newCount);
          },
        );
      },
    );
  }
}
