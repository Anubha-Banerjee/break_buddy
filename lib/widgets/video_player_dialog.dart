import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerDialog extends StatefulWidget {
  final String videoPath;
  final int durationInSeconds;
  final VoidCallback onComplete;
  final int repeatCount;
  final String activityName;

  const VideoPlayerDialog({
    Key? key,
    required this.videoPath,
    required this.durationInSeconds,
    required this.onComplete,
    required this.activityName,
    this.repeatCount = 0, // 0 means continuous loop
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
  int _playCount = 0;
  bool _showingNextActivityPopup = false;
  bool _videoCompleted = false;
  StreamSubscription<bool>? _playbackSubscription;
  Duration? _lastPosition;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _playCount = 0; // Explicitly start at 0
    _lastPosition = null; // Reset position tracking
    _showingNextActivityPopup = false;
    print('Initializing video player for ${widget.activityName} with ${widget.repeatCount} repeats');
    _initializePlayer();
  }

  Future<bool> _initializeVideoController() async {
    try {
      print(
          'Initializing video player for: ${widget.videoPath} (Attempt ${_initializeAttempts + 1}/$maxAttempts)');

      await _player.open(Media(widget.videoPath));
      await _player.setVolume(100);
      
      // For counted repeats, use single mode and handle looping ourselves
      // For continuous play (count=0), use loop mode
      await _player.setPlaylistMode(PlaylistMode.single);
      
      // Reset all state variables
      _playCount = 0;
      _videoCompleted = false;
      _lastPosition = null;

      // Set up playback monitoring if we need to count repeats
      if (widget.repeatCount > 0) {
        print('Setting up playback monitoring for ${widget.repeatCount} repeats');
        
        // Monitor position changes to track progress
        bool hasReachedEnd = false;
        _player.stream.position.listen((position) async {
          final currentPositionMs = position.inMilliseconds;
          final lastPositionMs = _lastPosition?.inMilliseconds ?? 0;
          final durationMs = widget.durationInSeconds * 1000;
          
          // Print position updates for debugging
          print('Position: ${currentPositionMs}ms / ${durationMs}ms, Last: ${lastPositionMs}ms');
          
          // Detect completion when we reach near the end of the video
          if (!hasReachedEnd && currentPositionMs >= (durationMs - 200)) {
            print('Reached end of video');
            hasReachedEnd = true;
          }
          
          // Detect loop when we go back to start after reaching end
          if (hasReachedEnd && currentPositionMs < 200 && !_videoCompleted) {
            print('Loop detected: Video restarted from beginning');
            hasReachedEnd = false;
            
            if (mounted) {
              _videoCompleted = true;  // Mark this loop as completed
              setState(() {
                _playCount++;
              });
              print('Incremented play count to $_playCount/${widget.repeatCount}');
              
              if (_playCount >= widget.repeatCount) {
                print('Target count reached ($_playCount/${widget.repeatCount}), preparing to end');
                await _player.pause();
                
                if (mounted) {
                  setState(() {
                    _showingNextActivityPopup = true;
                  });
                  
                  await Future.delayed(const Duration(seconds: 2));
                  
                  if (mounted) {
                    widget.onComplete();
                  }
                }
              } else {
                // Reset for next loop
                _videoCompleted = false;
                // Ensure we continue playing
                if (mounted) {
                  await _player.play();
                }
              }
            }
          } else if (currentPositionMs > 200 && currentPositionMs < (durationMs - 200)) {
            // Reset flags when we're in the middle of the video
            _videoCompleted = false;
            hasReachedEnd = false;
          }
          
          _lastPosition = position;
        });

        // Backup monitoring through completed event for smoother looping
        _playbackSubscription = _player.stream.completed.listen((completed) async {
          print('Completed event received: completed=$completed, playCount=$_playCount/${widget.repeatCount}');
          if (completed && mounted && _playCount < widget.repeatCount) {
            await _player.seek(Duration.zero);
            if (mounted) {
              await _player.play();
            }
          }
        });

        // Monitor playback state for debugging
        _player.stream.playing.listen((playing) {
          print('Playback state changed: playing=$playing, count=$_playCount/${widget.repeatCount}');
        });
      }

      await _player.play();

      // Give the video controller time to initialize
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
                onPressed: () => Navigator.of(context).pop(),
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
                    constraints: const BoxConstraints(maxWidth: 480, maxHeight: 360),
                    child: Container(
                      color: Colors.black,
                      child: Video(
                        controller: _videoController,
                        controls: AdaptiveVideoControls,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (widget.repeatCount > 0) Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rep ${_playCount}/${widget.repeatCount}',
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
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: const BorderRadius.only(
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
                          onPressed: () => widget.onComplete(),
                          icon: const Icon(Icons.skip_next),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close video dialog
                            Navigator.of(context).pop(); // Close exercise dialog
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
              child: const Text(
                'Starting next activity...',
                style: TextStyle(
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
