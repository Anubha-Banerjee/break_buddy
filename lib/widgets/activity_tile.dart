import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/activity_video.dart';
import '../widgets/video_player_dialog.dart';

class ActivityTile extends StatefulWidget {
  final Activity activity;
  final Function(int) onCountChanged;
  final Function(int)? onVideoComplete; // New callback for video completion
  final Function(int count, int timeSpentSeconds)?
      onTimeTracked; // Track time spent

  const ActivityTile({
    super.key,
    required this.activity,
    required this.onCountChanged,
    this.onVideoComplete,
    this.onTimeTracked,
  });

  @override
  State<ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<ActivityTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final video = VideoConfig.getVideoForTask(widget.activity.id);
            if (video != null) {
              print(
                  'Playing video: ${video.videoPath} for ${video.duration} seconds');
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => VideoPlayerDialog(
                  videoPath: video.videoPath,
                  durationInSeconds: video.duration,
                  repeatCount: widget.activity.count,
                  activityName: widget.activity.name,
                  onTimeTracked: widget.onTimeTracked,
                  onComplete: (completedCount) {
                    // Use the video complete callback if provided, otherwise fall back to count change
                    if (widget.onVideoComplete != null) {
                      widget.onVideoComplete!(completedCount);
                    } else {
                      // For backward compatibility, pass absolute value to count change
                      final validCount =
                          completedCount < 0 ? 0 : completedCount;
                      widget.onCountChanged(validCount);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              );
            } else {
              print('No video found for activity: ${widget.activity.id}');
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.activity.count.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: VideoConfig.getVideoForTask(widget.activity.id)
                              ?.thumbnailPath !=
                          null
                      ? DecorationImage(
                          image: AssetImage(
                            VideoConfig.getVideoForTask(widget.activity.id)!
                                .thumbnailPath,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: VideoConfig.getVideoForTask(widget.activity.id)
                            ?.thumbnailPath ==
                        null
                    ? Icon(
                        widget.activity.icon,
                        size: 24,
                        color: Colors.blue,
                      )
                    : null,
              ),
              if (_isHovered) ...[
                const SizedBox(height: 4),
                Text(
                  widget.activity.name,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 32),
                    onPressed: widget.activity.count > 0
                        ? () => widget.onCountChanged(widget.activity.count - 1)
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 32),
                    onPressed: () =>
                        widget.onCountChanged(widget.activity.count + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
