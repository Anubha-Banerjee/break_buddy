import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String name;
  final IconData icon;
  final String? videoPath;
  final String? thumbnailPath;
  int count;
  DateTime? selectionTime; // Track when the activity was first selected

  Activity({
    required this.id,
    required this.name,
    required this.icon,
    this.videoPath,
    this.thumbnailPath,
    this.count = 0,
    this.selectionTime,
  });

  Activity copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? count,
    DateTime? selectionTime,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      videoPath: videoPath,
      thumbnailPath: thumbnailPath,
      count: count ?? this.count,
      selectionTime: selectionTime ?? this.selectionTime,
    );
  }
}
