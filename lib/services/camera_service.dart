import 'dart:developer';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  final double _neckAngleThreshold = 15.0; // Degrees
  final double _shoulderTiltThreshold = 10.0; // Degrees

  bool _isGoodPosture = true;
  String _postureMessage = "Good posture";
  Function(List<Pose>)? _onPoseDetected;

  Future<void> initialize() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    final inputImage = _convertCameraImageToInputImage(image);
    if (inputImage != null) {
      final poses = await _poseDetector!.processImage(inputImage);
      _onPoseDetected?.call(poses);
    }

    _isBusy = false;
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      InputImageRotation rotation;
      switch (_cameraController!.description.sensorOrientation) {
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      return inputImage;
    } catch (e) {
      print("Image conversion error: $e");
      return null;
    }
  }

  void dispose() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    await _poseDetector?.close();
  }

  CameraController? get cameraController => _cameraController;

  set onPoseDetected(Function(List<Pose>) callback) {
    _onPoseDetected = callback;
  }
}