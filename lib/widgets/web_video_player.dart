import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WebVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final ValueChanged<Duration> onPositionChanged;
  final VoidCallback onVideoEnd;

  const WebVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.onPlay,
    required this.onPause,
    required this.onPositionChanged,
    required this.onVideoEnd,
  }) : super(key: key);

  @override
  State<WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // On web, construct the video URL properly
      String videoUrl = widget.videoUrl;

      // If it's a relative path (like from assets), convert it to a proper web URL
      if (!videoUrl.startsWith('http') && !videoUrl.startsWith('blob:')) {
        // For web, use the assets path directly
        videoUrl = 'assets/videos/${videoUrl.split('/').last}';
      }

      print('Web video URL: $videoUrl');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      await _controller.initialize();
      print('Web video initialized successfully: $videoUrl');
      print('Duration: ${_controller.value.duration}');

      _controller.addListener(_handleVideoEvent);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // Auto-play
      if (mounted) {
        await _controller.play();
        widget.onPlay();
      }
    } catch (e) {
      print('Error initializing web video: $e');
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    }
  }

  void _handleVideoEvent() {
    if (_controller.value.isPlaying) {
      widget.onPositionChanged(_controller.value.position);

      // Check if video ended
      if (_controller.value.position >= _controller.value.duration) {
        widget.onVideoEnd();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoEvent);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Failed to load video',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
