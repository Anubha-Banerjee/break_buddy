import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';

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
  // media_kit for non-web
  late final Player _player;
  late final VideoController _videoController;

  // video_player for web
  VideoPlayerController? _webVideoController;

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

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _player = Player();
      _videoController = VideoController(_player);
    }
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

      // Only check Platform.isAndroid on non-web platforms
      try {
        if (Platform.isAndroid) {
          // For Android, we need to add the asset:/// scheme
          if (!videoPath.startsWith('asset:///')) {
            // The video server gives us the raw path, we need to add the asset:/// scheme
            videoPath = 'asset:///$videoPath';
          }
          print('Android video path: $videoPath');
        }
      } catch (e) {
        // On web, Platform operations will throw - just use the path as-is
        print('Platform check not available on web, using path as-is');
      }

      await _player.open(Media(videoPath));
      await _player.setVolume(100);
      await _player.setPlaylistMode(PlaylistMode.single);
      print('Video opened successfully: $videoPath');
      print('Player state: ${_player.state}');

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

        print(
            'Position: ${currentPositionMs}ms / ${durationMs}ms, Last: ${lastPositionMs}ms');

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
      print('Player playing: ${_player.state.playing}');
      print('Player duration: ${_player.state.duration}');

      if (!mounted) return false;

      setState(() {
        _initialized = true;
      });
      return true;
    } catch (e) {
      print(
          'Error initializing video player (Attempt ${_initializeAttempts + 1}): $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<void> _initializePlayer() async {
    if (kIsWeb) {
      await _initializeWebVideoPlayer();
    } else {
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
  }

  Future<void> _initializeWebVideoPlayer() async {
    try {
      print('Initializing web video player for: ${widget.videoPath}');

      String videoUrl = widget.videoPath;

      // On web, use Flutter's asset serving directly
      // Convert any URL to an asset path
      if (videoUrl.startsWith('http')) {
        // Extract filename from URL
        String filename = videoUrl.split('/').last;
        videoUrl = 'assets/videos/$filename';
        print('Converted URL to asset path: $videoUrl');
      } else if (!videoUrl.startsWith('assets/')) {
        // If it's a relative path, prepend assets/
        videoUrl = 'assets/videos/${videoUrl.split('/').last}';
      }

      print('Loading web video from asset: $videoUrl');

      _webVideoController = VideoPlayerController.asset(videoUrl);

      await _webVideoController!.initialize();
      print(
          'Web video initialized, duration: ${_webVideoController!.value.duration}');

      await _webVideoController!.play();

      _webVideoController!.addListener(_webVideoListener);

      print('Web video initialized and playing successfully');

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('Error initializing web video: $e');
      print('Stack trace: $e');
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    }
  }

  void _webVideoListener() {
    if (_webVideoController == null) return;

    final position = _webVideoController!.value.position;
    final duration = _webVideoController!.value.duration;
    final durationMs = widget.durationInSeconds * 1000;

    if (position >= duration && duration > Duration.zero) {
      // Video ended
      if (_playCount < widget.repeatCount || widget.repeatCount == 0) {
        // Loop video
        _webVideoController!.seekTo(Duration.zero);
        _webVideoController!.play();

        if (widget.repeatCount > 0) {
          setState(() {
            _playCount++;
          });
        }
      } else if (widget.repeatCount > 0 && _playCount >= widget.repeatCount) {
        // Sequence complete
        _completeWithTime(_playCount);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playbackSubscription?.cancel();
    if (!kIsWeb) {
      _player.dispose();
    } else {
      _webVideoController?.removeListener(_webVideoListener);
      _webVideoController?.dispose();
    }
    super.dispose();
  }

  void _completeWithTime(int count) {
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    final actualCount =
        count.abs(); // Get absolute value (handles negative quit signal)
    print(
        '[VIDEO TIME] Activity: ${widget.activityName}, Count: $count (actual: $actualCount), Time: ${timeSpent}s');
    // Only track activities that lasted 4 seconds or more
    if (widget.onTimeTracked != null && actualCount > 0 && timeSpent >= 2) {
      print(
          '[VIDEO TIME] Tracking activity: ${widget.activityName} (time: ${timeSpent}s >= 4s threshold)');
      widget.onTimeTracked!(actualCount, timeSpent);
    } else if (actualCount > 0 && timeSpent < 4) {
      print(
          '[VIDEO TIME] Not tracking activity: ${widget.activityName} (time: ${timeSpent}s < 4s threshold)');
    }
    widget.onComplete(count);
  }

  void _handleWebVideoEnd() {
    if (_playCount < widget.repeatCount) {
      // Increment count and continue looping (video_player will auto-replay)
      setState(() {
        _playCount++;
      });
    } else {
      // Video sequence complete
      _completeWithTime(_playCount);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web platform uses video_player
    if (kIsWeb) {
      if (_error) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load video.'),
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
                const Text('Loading video...'),
              ],
            ),
          ),
        );
      }

      return Dialog(
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
                    child: AspectRatio(
                      aspectRatio:
                          _webVideoController?.value.aspectRatio ?? 16 / 9,
                      child: VideoPlayer(_webVideoController!),
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
                        'Rep $_playCount/${widget.repeatCount == 999999 ? '∞' : widget.repeatCount}',
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Quit'),
                ),
                const SizedBox(width: 16),
                if (!widget.isLastActivity)
                  ElevatedButton(
                    onPressed: () {
                      _completeWithTime(_playCount);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Next'),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    // Non-web platforms use media_kit
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
                        controls: MaterialVideoControls,
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
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.activityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                            Navigator.of(context).pop();
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
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.nextActivityName != null
                    ? 'Starting ${widget.nextActivityName}...'
                    : 'Starting next activity...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
