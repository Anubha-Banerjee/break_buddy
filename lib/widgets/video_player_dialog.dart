import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerDialog extends StatefulWidget {
  final String videoPath;
  final int durationInSeconds;
  final Function(int completedCount) onComplete;
  final String activityName;
  final int repeatCount;
  final bool isLastActivity;
  final String? nextActivityName;
  final Function(int count, int timeSpentSeconds)? onTimeTracked;

  const VideoPlayerDialog({
    Key? key,
    required this.videoPath,
    required this.durationInSeconds,
    required this.onComplete,
    required this.activityName,
    this.repeatCount = 0,
    this.isLastActivity = false,
    this.nextActivityName,
    this.onTimeTracked,
  }) : super(key: key);

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late final Player _player;
  late final VideoController _videoController;
  Timer? _timer;
  int _initializeAttempts = 0;
  static const int maxAttempts = 3;
  bool _initialized = false;
  bool _error = false;
  int _playCount = 1;
  bool _showingNextActivityPopup = false;
  bool _videoCompleted = false;
  StreamSubscription<bool>? _playbackSubscription;
  Duration? _lastPosition;
  late DateTime _startTime;
  bool _isMaximized = true; // Auto-maximize videos
  double _maxProgressPercentage = 0.0; // Track maximum progress reached

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _playCount = 1;
    _lastPosition = null;
    _showingNextActivityPopup = false;
    _startTime = DateTime.now();
    print(
        'Initializing video player for ${widget.activityName} with ${widget.repeatCount} repeats');
    _initializePlayer();
  }

  Future<bool> _initializeVideoController() async {
    try {
      print(
          'Initializing video player for: ${widget.videoPath} (Attempt ${_initializeAttempts + 1}/$maxAttempts)');

      String videoPath = widget.videoPath;
      if (Platform.isAndroid) {
        // For Android, we need to add the asset:/// scheme
        if (!videoPath.startsWith('asset:///')) {
          // The video server gives us the raw path, we need to add the asset:/// scheme
          videoPath = 'asset:///$videoPath';
        }
        print('Android video path: $videoPath');
      }

      await _player.open(Media(videoPath));
      await _player.setVolume(100);
      await _player.setPlaylistMode(PlaylistMode.single);

      _playCount = 1;
      _videoCompleted = false;
      _lastPosition = null;

      // Always set up playback monitoring for manual looping via Next/Quit buttons
      print('Setting up playback monitoring for manual looping');

      bool hasReachedEnd = false;
      _player.stream.position.listen((position) async {
        final currentPositionMs = position.inMilliseconds;
        final lastPositionMs = _lastPosition?.inMilliseconds ?? 0;
        final durationMs = widget.durationInSeconds * 1000;

        // Track maximum progress percentage reached
        final currentProgressPercentage =
            (currentPositionMs / durationMs) * 100;
        if (currentProgressPercentage > _maxProgressPercentage) {
          _maxProgressPercentage = currentProgressPercentage;
        }

        print(
            'Position: ${currentPositionMs}ms / ${durationMs}ms, Last: ${lastPositionMs}ms, Max Progress: ${_maxProgressPercentage.toStringAsFixed(1)}%');

        if (!hasReachedEnd && currentPositionMs >= (durationMs - 200)) {
          print('Reached end of video');
          hasReachedEnd = true;
        }

        if (hasReachedEnd && currentPositionMs < 200 && !_videoCompleted) {
          print('Loop detected: Video restarted from beginning');
          hasReachedEnd = false;

          if (mounted) {
            _videoCompleted = true;
            int unboundedPlayCount = 0;
            setState(() {
              unboundedPlayCount = _playCount + 1;
              // If repeatCount is set, respect it. Otherwise allow unlimited looping
              if (widget.repeatCount > 0) {
                _playCount = min(_playCount + 1, widget.repeatCount);
              } else {
                _playCount = unboundedPlayCount;
              }
            });
            print(
                'Incremented play count to $_playCount${widget.repeatCount > 0 ? '/${widget.repeatCount}' : ''}');

            // Only auto-complete if we have a repeatCount target and reached it
            if (widget.repeatCount > 0 &&
                unboundedPlayCount > widget.repeatCount) {
              print(
                  'Target count reached ($_playCount/${widget.repeatCount}), preparing to end');
              await _player.pause();

              if (mounted) {
                setState(() {
                  _showingNextActivityPopup = !widget.isLastActivity;
                });

                if (_showingNextActivityPopup) {
                  await Future.delayed(const Duration(seconds: 4));
                }

                if (mounted) {
                  _completeWithTime(_playCount);
                }
              }
            } else {
              _videoCompleted = false;
              if (mounted) {
                await _player.play();
              }
            }
          }
        } else if (currentPositionMs > 200 &&
            currentPositionMs < (durationMs - 200)) {
          _videoCompleted = false;
          hasReachedEnd = false;
        }

        _lastPosition = position;
      });

      _playbackSubscription =
          _player.stream.completed.listen((completed) async {
        print(
            'Completed event received: completed=$completed, playCount=$_playCount${widget.repeatCount > 0 ? '/${widget.repeatCount}' : ''}');
        if (completed &&
            mounted &&
            widget.repeatCount > 0 &&
            _playCount < widget.repeatCount) {
          await _player.seek(Duration.zero);
          if (mounted) {
            await _player.play();
          }
        }
      });

      _player.stream.playing.listen((playing) {
        print(
            'Playback state changed: playing=$playing, count=$_playCount${widget.repeatCount > 0 ? '/${widget.repeatCount}' : ''}');
      });

      await _player.play();
      await Future.delayed(const Duration(milliseconds: 100));
      print('Video initialized successfully');

      if (!mounted) return false;

      setState(() {
        _initialized = true;
      });
      return true;
    } catch (e) {
      print(
          'Error initializing video player (Attempt ${_initializeAttempts + 1}): $e');
      return false;
    }
  }

  Future<void> _initializePlayer() async {
    while (_initializeAttempts < maxAttempts) {
      if (await _initializeVideoController()) {
        return;
      }
      _initializeAttempts++;
      if (_initializeAttempts < maxAttempts) {
        await Future.delayed(Duration(seconds: 1));
      }
    }

    if (mounted) {
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playbackSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _completeWithTime(int count) {
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    final actualCount =
        count.abs(); // Get absolute value (handles negative quit signal)
    print(
        '[VIDEO TIME] Activity: ${widget.activityName}, Count: $count (actual: $actualCount), Time: ${timeSpent}s, Max Progress: ${_maxProgressPercentage.toStringAsFixed(1)}%');

    // Only track activities that:
    // 1. Lasted 2 seconds or more
    // 2. Were played at least 50% through
    if (widget.onTimeTracked != null &&
        actualCount > 0 &&
        timeSpent >= 2 &&
        _maxProgressPercentage >= 50.0) {
      print(
          '[VIDEO TIME] Tracking activity: ${widget.activityName} (time: ${timeSpent}s >= 2s, progress: ${_maxProgressPercentage.toStringAsFixed(1)}% >= 50%)');
      widget.onTimeTracked!(actualCount, timeSpent);
    } else if (actualCount > 0) {
      if (timeSpent < 2) {
        print(
            '[VIDEO TIME] Not tracking activity: ${widget.activityName} (time: ${timeSpent}s < 2s threshold)');
      } else if (_maxProgressPercentage < 50.0) {
        print(
            '[VIDEO TIME] Not tracking activity: ${widget.activityName} (progress: ${_maxProgressPercentage.toStringAsFixed(1)}% < 50% threshold)');
      }
    }
    widget.onComplete(count);
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load video after multiple attempts.'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (_playCount > 0) {
                    _completeWithTime(_playCount);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                  'Loading video... (Attempt ${_initializeAttempts + 1}/$maxAttempts)'),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_isMaximized)
          // Fullscreen mode
          Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black87,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isMaximized = false;
                  });
                },
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                widget.activityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        color: Colors.black,
                        width: double.infinity,
                        child: Video(
                          controller: _videoController,
                          controls: AdaptiveVideoControls,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (widget.repeatCount > 0)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Rep ${_playCount}/${widget.repeatCount == 999999 ? '∞' : widget.repeatCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _completeWithTime(_playCount),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _completeWithTime(-_playCount);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Quit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          // Normal dialog mode
          Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 480, maxHeight: 360),
                      child: Container(
                        color: Colors.black,
                        child: Video(
                          controller: _videoController,
                          controls: AdaptiveVideoControls,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (widget.repeatCount > 0)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Rep ${_playCount}/${widget.repeatCount == 999999 ? '∞' : widget.repeatCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          setState(() {
                            _isMaximized = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.activityName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _completeWithTime(_playCount),
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // When quitting, pass negative play count to signal quit
                              // negative = quit, positive = normal completion
                              _completeWithTime(-_playCount);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Quit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_showingNextActivityPopup)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.nextActivityName != null
                    ? 'Starting ${widget.nextActivityName}...'
                    : 'Starting next activity...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
