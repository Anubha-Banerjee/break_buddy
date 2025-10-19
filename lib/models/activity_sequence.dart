import 'package:flutter/material.dart';
import 'activity.dart';

class ActivitySequence {
  final String id;
  final String name;
  final List<Activity> activities;
  final DateTime createdAt;

  ActivitySequence({
    required this.id,
    required this.name,
    required List<Activity> activities,
    required this.createdAt,
  }) : activities = activities
          ..sort((a, b) => (a.selectionTime ?? DateTime.now())
              .compareTo(b.selectionTime ?? DateTime.now()));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'activities': activities
            .map((a) => {
                  'id': a.id,
                  'count': a.count,
                  'selectionTime': a.selectionTime?.toIso8601String(),
                })
            .toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ActivitySequence.fromJson(Map<String, dynamic> json) {
    return ActivitySequence(
      id: json['id'],
      name: json['name'],
      activities: (json['activities'] as List)
          .map((a) => Activity(
                id: a['id'],
                name: '', // These will be filled from predefined activities
                icon: Icons.fitness_center, // Default icon
                count: a['count'],
                selectionTime: a['selectionTime'] != null
                    ? DateTime.parse(a['selectionTime'])
                    : null,
              ))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
