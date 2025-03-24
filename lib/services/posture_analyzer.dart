import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PostureAnalyzer {
  final double _neckAngleThreshold = 15.0; // Degrees
  final double _shoulderTiltThreshold = 10.0; // Degrees

  bool _isGoodPosture = true;
  String _postureMessage = "Good posture";

  void analyzePose(Pose pose, Map<String, double> sensorData) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    if (leftShoulder == null || rightShoulder == null || nose == null) {
      _isGoodPosture = false;
      _postureMessage = "Can't detect key points";
      return;
    }

    double neckAngle = _calculateNeckAngle(nose, leftShoulder, rightShoulder);

    double shoulderTilt = _calculateShoulderTilt(leftShoulder, rightShoulder);

    double forwardTilt = sensorData['accelY'] ?? 0.0;

    if (neckAngle > _neckAngleThreshold || forwardTilt > 2.0) {
      _isGoodPosture = false;
      _postureMessage = "Head tilting forward - sit up straight";
    } else if (shoulderTilt > _shoulderTiltThreshold) {
      _isGoodPosture = false;
      _postureMessage = "Shoulders uneven - level your shoulders";
    } else {
      _isGoodPosture = true;
      _postureMessage = "Good posture";
    }
  }


  double _calculateNeckAngle(
      PoseLandmark nose,
      PoseLandmark leftShoulder,
      PoseLandmark rightShoulder
      ) {

    double midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    double midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;


    double deltaX = nose.x - midShoulderX;
    double deltaY = nose.y - midShoulderY;

    return atan2(deltaX, deltaY) * (180 / pi).abs();
  }

  double _calculateShoulderTilt(
      PoseLandmark leftShoulder,
      PoseLandmark rightShoulder
      ) {
    double deltaY = (leftShoulder.y - rightShoulder.y).abs();
    double deltaX = (leftShoulder.x - rightShoulder.x).abs();
    return atan2(deltaY, deltaX) * (180 / pi);
  }

  bool get isGoodPosture => _isGoodPosture;
  String get postureMessage => _postureMessage;
}