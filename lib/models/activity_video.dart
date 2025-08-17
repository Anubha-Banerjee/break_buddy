import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/video_server.dart';

class ActivityVideo {
  final String taskName;
  final String videoPath;
  final String thumbnailPath;
  final int duration;

  ActivityVideo({
    required this.taskName,
    required this.videoPath,
    required this.thumbnailPath,
    required this.duration,
  });

  factory ActivityVideo.fromJson(Map<String, dynamic> json) {
    return ActivityVideo(
      taskName: json['taskName'] as String,
      videoPath: json['videoPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      duration: json['duration'] as int,
    );
  }
}

class VideoConfig {
  static Map<String, ActivityVideo> _videos = {};
  static VideoServer? _videoServer;

  static Future<void> initialize(VideoServer server) async {
    _videoServer = server;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/video_config.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _videos = {
        for (var item in jsonList)
          item['taskName'] as String: ActivityVideo(
            taskName: item['taskName'] as String,
            videoPath:
                _videoServer!.getUrlForAsset('videos/${item['taskName']}.mp4'),
            thumbnailPath: 'assets/thumbnails/${item['taskName']}.jpg',
            duration: item['duration'] as int,
          )
      };
      print('Loaded ${_videos.length} videos: ${_videos.keys.join(", ")}');
    } catch (e) {
      print('Error loading video config: $e');
      print('Stack trace: ${e is Error ? e.stackTrace : ""}');
      _videos = {};
    }
  }

  static ActivityVideo? getVideoForTask(String taskName) {
    final video = _videos[taskName];
    print(
        'Getting video for task $taskName: ${video?.videoPath ?? "not found"}');
    return video;
  }
}
