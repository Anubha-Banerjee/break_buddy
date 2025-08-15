import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_tile.dart';

class ActivityGrid extends StatelessWidget {
  final List<Activity> activities;
  final Function(String, int) onActivityCountChanged;

  const ActivityGrid({
    Key? key,
    required this.activities,
    required this.onActivityCountChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, // Show 6 items per row instead of 4
              childAspectRatio: 0.75,
              crossAxisSpacing: 12, // Slightly reduced spacing
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement start activities
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Activities'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
