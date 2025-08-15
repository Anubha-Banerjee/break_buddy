import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String name;
  final IconData icon;
  int count;

  Activity({
    required this.id,
    required this.name,
    required this.icon,
    this.count = 0,
  });

  Activity copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? count,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      count: count ?? this.count,
    );
  }
}
