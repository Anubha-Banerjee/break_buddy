import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerDialog extends StatefulWidget {
  final String videoPath;
  final int durationInSeconds;
  final VoidCallback onComplete;
  final int repeatCount;

  const VideoPlayerDialog({
    Key? key,
    required this.videoPath,
    required this.durationInSeconds,
    required this.onComplete,
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
  StreamSubscription<bool>? _playbackSubscription;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _initializePlayer();
  }

  Future<bool> _initializeVideoController() async {
    try {
      print(
          'Initializing video player for: ${widget.videoPath} (Attempt ${_initializeAttempts + 1}/$maxAttempts)');

      await _player.open(Media(widget.videoPath));
      await _player.setVolume(100);
      await _player.setPlaylistMode(
          widget.repeatCount == 0 ? PlaylistMode.loop : PlaylistMode.single);

      // Set up playback monitoring if we need to count repeats
      if (widget.repeatCount > 0) {
        _playbackSubscription = _player.stream.completed.listen((completed) {
          if (completed) {
            setState(() {
              _playCount++;
            });
            print('Video play count: $_playCount/${widget.repeatCount}');
            if (_playCount >= widget.repeatCount) {
              _player.pause();
              widget.onComplete(); // Close the dialog when done
            } else {
              _player.seek(Duration.zero);
              _player.play();
            }
          }
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

  void _stopPlaying() {
    _timer?.cancel();
    _player.pause();
    widget.onComplete();
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

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _stopPlaying,
            child: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
