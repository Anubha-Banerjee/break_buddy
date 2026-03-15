import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/custom_activity.dart';
import '../models/activity_video.dart';
import '../widgets/video_player_dialog.dart';

class ActivityTile extends StatefulWidget {
  final Activity activity;
  final Function(int) onCountChanged;
  final Function(int)? onVideoComplete; // New callback for video completion
  final Function(int count, int timeSpentSeconds)?
      onTimeTracked; // Track time spent
  final Function()? onDelete; // Callback for deleting custom activities

  const ActivityTile({
    super.key,
    required this.activity,
    required this.onCountChanged,
    this.onVideoComplete,
    this.onTimeTracked,
    this.onDelete,
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
            // Check if it's a custom activity
            if (widget.activity is CustomActivity) {
              final customActivity = widget.activity as CustomActivity;
              print('Playing custom video: ${customActivity.videoFilePath}');
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => VideoPlayerDialog(
                  videoPath: customActivity.videoFilePath,
                  durationInSeconds:
                      60, // Default duration; will be auto-detected by player
                  repeatCount: widget.activity.count,
                  activityName: widget.activity.name,
                  onTimeTracked: widget.onTimeTracked,
                  onComplete: (completedCount, {required bool isQuit}) {
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
              // Handle predefined activities from VideoConfig
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
                    onComplete: (completedCount, {required bool isQuit}) {
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
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Stack(
              children: [
                Column(
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
                    Expanded(
                      child: Container(
                        width: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: (widget.activity is CustomActivity)
                              ? null
                              : (VideoConfig.getVideoForTask(widget.activity.id)
                                          ?.thumbnailPath !=
                                      null
                                  ? DecorationImage(
                                      image: AssetImage(
                                        VideoConfig.getVideoForTask(
                                                widget.activity.id)!
                                            .thumbnailPath,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: (widget.activity is CustomActivity) ||
                                (VideoConfig.getVideoForTask(widget.activity.id)
                                        ?.thumbnailPath ==
                                    null)
                            ? Icon(
                                widget.activity.icon,
                                size: 24,
                                color: Colors.blue,
                              )
                            : null,
                      ),
                    ),
                    if (_isHovered)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: SizedBox(
                          height: 16,
                          child: Text(
                            widget.activity.name,
                            style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 32),
                          onPressed: widget.activity.count > 0
                              ? () => widget
                                  .onCountChanged(widget.activity.count - 1)
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
                // Delete button for custom activities on hover
                if (_isHovered &&
                    widget.activity is CustomActivity &&
                    widget.onDelete != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Activity'),
                            content: Text(
                                'Are you sure you want to delete "${widget.activity.name}"? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onDelete!();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(Icons.delete,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
