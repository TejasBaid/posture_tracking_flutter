import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/camera_service.dart';
import '../services/sensor_service.dart';
import '../services/posture_analyzer.dart';

class PostureTrackerScreen extends StatefulWidget {
  const PostureTrackerScreen({Key? key}) : super(key: key);

  @override
  _PostureTrackerScreenState createState() => _PostureTrackerScreenState();
}

class _PostureTrackerScreenState extends State<PostureTrackerScreen> {
  final CameraService _cameraService = CameraService();
  final SensorService _sensorService = SensorService();
  final PostureAnalyzer _postureAnalyzer = PostureAnalyzer();

  bool _isInitialized = false;
  bool _hasPermission = true;
  bool _isGoodPosture = true;
  String _postureMessage = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _cameraService.initialize();
      _cameraService.onPoseDetected = (List<Pose> poses) {
        if (poses.isEmpty) {
          setState(() {
            _isGoodPosture = false;
            _postureMessage = "No pose detected";
          });
          return;
        }

        final sensorData = _sensorService.getSensorData();
        _postureAnalyzer.analyzePose(poses.first, sensorData);
        setState(() {
          _isGoodPosture = _postureAnalyzer.isGoodPosture;
          _postureMessage = _postureAnalyzer.postureMessage;
        });
      };

      _sensorService.initialize(() {
        // Handle significant motion if needed
      });

      setState(() {
        _isInitialized = true;
        _postureMessage = "Good posture";
      });
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _postureMessage = "Camera access denied";
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _sensorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posture Tracker'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildCameraPreview(),
          ),
          Expanded(
            flex: 1,
            child: _buildPostureIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || !_hasPermission) {
      return Center(
        child: Text(
          _hasPermission ? "Initializing camera..." : "Camera permission required",
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CameraPreview(_cameraService.cameraController!),
    );
  }

  Widget _buildPostureIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isGoodPosture ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isGoodPosture ? Icons.check_circle : Icons.warning,
            color: _isGoodPosture ? Colors.green : Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _postureMessage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isGoodPosture ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }
}