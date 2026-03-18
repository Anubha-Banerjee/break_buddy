import 'package:flutter/material.dart';
import 'activity.dart';

class CustomActivity extends Activity {
  final String videoFilePath; // Local file path to the custom video
  final String? generatedThumbnailPath; // Path to generated thumbnail

  CustomActivity({
    required String id,
    required String name,
    required this.videoFilePath,
    this.generatedThumbnailPath,
    IconData icon = Icons.video_library,
  }) : super(
          id: id,
          name: name,
          icon: icon,
          videoPath: videoFilePath,
          thumbnailPath: generatedThumbnailPath,
          count: 0,
          countMatters: true,
        );

  factory CustomActivity.fromJson(Map<String, dynamic> json) {
    return CustomActivity(
      id: json['id'] as String,
      name: json['name'] as String,
      videoFilePath: json['videoFilePath'] as String,
      generatedThumbnailPath: json['generatedThumbnailPath'] as String?,
      icon: Icons.video_library,
    );
  }

  @override
  CustomActivity copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? count,
    DateTime? selectionTime,
    int? timeSpent,
    bool? countMatters,
  }) {
    return CustomActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      videoFilePath: videoFilePath,
      generatedThumbnailPath: generatedThumbnailPath,
      icon: icon ?? this.icon,
    )
      ..count = count ?? this.count
      ..selectionTime = selectionTime ?? this.selectionTime
      ..timeSpent = timeSpent ?? this.timeSpent;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'videoFilePath': videoFilePath,
      'generatedThumbnailPath': generatedThumbnailPath,
    };
  }
}
