import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_detector.dart';

class PoseOverlayPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Size imageSize;

  // Define joint connections for the stick figure
  static const List<List<int>> jointConnections = [
    // Head
    [0, 1], // nose to left eye
    [0, 2], // nose to right eye
    [1, 3], // left eye to left ear
    [2, 4], // right eye to right ear
    // Torso
    [5, 6], // left shoulder to right shoulder
    [5, 7], // left shoulder to left elbow
    [7, 9], // left elbow to left wrist
    [6, 8], // right shoulder to right elbow
    [8, 10], // right elbow to right wrist
    [5, 11], // left shoulder to left hip
    [6, 12], // right shoulder to right hip
    [11, 12], // left hip to right hip
    // Left leg
    [11, 13], // left hip to left knee
    [13, 15], // left knee to left ankle
    // Right leg
    [12, 14], // right hip to right knee
    [14, 16], // right knee to right ankle
  ];

  PoseOverlayPainter({required this.landmarks, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scaling factors
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    // Draw connections between joints
    for (final connection in jointConnections) {
      final startIdx = connection[0];
      final endIdx = connection[1];

      if (startIdx < landmarks.length && endIdx < landmarks.length) {
        final startLandmark = landmarks[startIdx];
        final endLandmark = landmarks[endIdx];

        try {
          final startPoint = Offset(
            startLandmark.x * scaleX,
            startLandmark.y * scaleY,
          );
          final endPoint = Offset(
            endLandmark.x * scaleX,
            endLandmark.y * scaleY,
          );

          canvas.drawLine(startPoint, endPoint, paint);
        } catch (e) {
          // Skip if coordinates unavailable
        }
      }
    }

    // Draw landmarks as circles
    for (final landmark in landmarks) {
      try {
        final point = Offset(landmark.x * scaleX, landmark.y * scaleY);
        canvas.drawCircle(point, 5, jointPaint);
      } catch (e) {
        // Skip if coordinates unavailable
      }
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}

class PoseOverlay extends StatefulWidget {
  final Stream<PoseLandmarkData> poseStream;
  final Size imageSize;

  const PoseOverlay({
    super.key,
    required this.poseStream,
    required this.imageSize,
  });

  @override
  State<PoseOverlay> createState() => _PoseOverlayState();
}

class _PoseOverlayState extends State<PoseOverlay> {
  PoseLandmarkData? _currentPose;

  @override
  void initState() {
    super.initState();
    widget.poseStream.listen((pose) {
      if (mounted) {
        setState(() {
          _currentPose = pose;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _currentPose != null
          ? PoseOverlayPainter(
              landmarks: _currentPose!.landmarks,
              imageSize: widget.imageSize,
            )
          : null,
      size: Size.infinite,
    );
  }
}
