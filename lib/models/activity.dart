import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String name;
  final IconData icon;
  final String? videoPath;
  final String? thumbnailPath;
  int count;
  DateTime? selectionTime; // Track when the activity was first selected
  int? timeSpent; // Track actual time spent (in seconds) for direct video plays
  final bool
      countMatters; // Whether the count matters for this activity (false for activities like walking)

  Activity({
    required this.id,
    required this.name,
    required this.icon,
    this.videoPath,
    this.thumbnailPath,
    this.count = 0,
    this.selectionTime,
    this.timeSpent,
    this.countMatters = true,
  });

  Activity copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? count,
    DateTime? selectionTime,
    int? timeSpent,
    bool? countMatters,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      videoPath: videoPath,
      thumbnailPath: thumbnailPath,
      count: count ?? this.count,
      selectionTime: selectionTime ?? this.selectionTime,
      timeSpent: timeSpent ?? this.timeSpent,
      countMatters: countMatters ?? this.countMatters,
    );
  }
}
