import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart' show Size;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:typed_data';

class PoseLandmarkData {
  final List<PoseLandmark> landmarks;
  final DateTime timestamp;

  PoseLandmarkData({
    required this.landmarks,
    required this.timestamp,
  });
}

class PoseDetectorService {
  late CameraController cameraController;
  late PoseDetector poseDetector;
  final StreamController<PoseLandmarkData> poseStream =
      StreamController<PoseLandmarkData>.broadcast();
  bool isProcessing = false;
  bool isDetecting = false;

  late List<CameraDescription> cameras;

  PoseDetectorService() {
    poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  Future<void> initializeCameras() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available');
        return;
      }

      // Use front camera for pose detection
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController.initialize();
      isDetecting = true;
      _startPoseDetection();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  void _startPoseDetection() {
    if (!cameraController.value.isInitialized) return;

    cameraController.startImageStream((image) async {
      if (isProcessing) return;
      isProcessing = true;

      try {
        final inputImage = _createInputImage(image);
        if (inputImage != null) {
          final poses = await poseDetector.processImage(inputImage);

          if (poses.isNotEmpty) {
            final pose = poses[0];
            // Convert landmarks map to list
            final landmarksList = pose.landmarks.values.toList();
            poseStream.add(PoseLandmarkData(
              landmarks: landmarksList,
              timestamp: DateTime.now(),
            ));
          }
        }
      } catch (e) {
        print('Error processing image: $e');
      } finally {
        isProcessing = false;
      }
    });
  }

  InputImage? _createInputImage(CameraImage image) {
    try {
      final allBytes = <int>[];
      for (final plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }

      final inputImageData = InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: InputImageRotation.rotation90deg,
        inputImageFormat: InputImageFormat.nv21,
        planeData: [
          InputImagePlaneMetadata(
            bytesPerRow: image.planes[0].bytesPerRow,
            height: image.height,
            width: image.width,
          ),
        ],
      );

      return InputImage.fromBytes(
        bytes: Uint8List.fromList(allBytes),
        inputImageData: inputImageData,
      );
    } catch (e) {
      print('Error creating input image: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    isDetecting = false;
    await cameraController.dispose();
    await poseDetector.close();
    await poseStream.close();
  }
}
