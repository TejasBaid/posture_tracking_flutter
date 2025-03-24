import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  AccelerometerEvent? _accelerometerData;
  GyroscopeEvent? _gyroscopeData;

  Function? _onSignificantMotion;

  final double _motionThreshold = 1.5;

  void initialize(Function onSignificantMotion) {
    _onSignificantMotion = onSignificantMotion;

    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerData = event;
      _checkForSignificantMotion();
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      _gyroscopeData = event;
      _checkForSignificantMotion();
    });
  }

  void _checkForSignificantMotion() {
    if (_accelerometerData == null || _gyroscopeData == null) return;

    final double accelMagnitude = _calculateMagnitude(
      _accelerometerData!.x,
      _accelerometerData!.y,
      _accelerometerData!.z,
    );

    final double gyroMagnitude = _calculateMagnitude(
      _gyroscopeData!.x,
      _gyroscopeData!.y,
      _gyroscopeData!.z,
    );

    if (accelMagnitude > _motionThreshold || gyroMagnitude > _motionThreshold) {
      _onSignificantMotion?.call();
    }
  }

  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  Map<String, double> getSensorData() {
    return {
      'accelX': _accelerometerData?.x ?? 0.0,
      'accelY': _accelerometerData?.y ?? 0.0,
      'accelZ': _accelerometerData?.z ?? 0.0,
      'gyroX': _gyroscopeData?.x ?? 0.0,
      'gyroY': _gyroscopeData?.y ?? 0.0,
      'gyroZ': _gyroscopeData?.z ?? 0.0,
    };
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }
}