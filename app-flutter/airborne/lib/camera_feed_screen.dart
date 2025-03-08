import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:typed_data';
import 'dart:async';

class CameraFeedScreen extends StatefulWidget {
  @override
  _CameraFeedScreenState createState() => _CameraFeedScreenState();
}

class _CameraFeedScreenState extends State<CameraFeedScreen> with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  bool _isStreaming = false;
  Timer? _frameTimer;
  late WebSocketChannel _channel;
  String _statusMessage = "Ready to stream";
  List<Map<String, dynamic>> _detectionResults = [];
  bool _showControls = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _connectToWebSocket();
    
    // Animation controller for pulsing effect
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Auto-hide controls after 5 seconds
    Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraController = CameraController(cameras[0], ResolutionPreset.high);
      await _cameraController.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      setState(() {
        _statusMessage = "Camera initialization failed: $e";
      });
    }
  }

  void _connectToWebSocket() {
    try {
      // Replace with your WebSocket URL
      final wsUrl = 'ws://orange-fiesta-rvgxwgwr6pq2wxq9-8000.app.github.dev/ws/video-stream';
      _channel = IOWebSocketChannel.connect(wsUrl);
      
      // Listen for detection results
      _channel.stream.listen((data) {
        final response = jsonDecode(data);
        setState(() {
          _detectionResults = List<Map<String, dynamic>>.from(response['detections'] ?? []);
        });
      }, onError: (error) {
        setState(() {
          _statusMessage = "Connection error: $error";
          _isStreaming = false;
        });
      });
    } catch (e) {
      setState(() {
        _statusMessage = "WebSocket connection failed: $e";
      });
    }
  }

  void _startStreaming() {
    setState(() {
      _isStreaming = true;
      _statusMessage = "Streaming...";
    });

    // Send frames every 500ms
    _frameTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (_isStreaming && _cameraController.value.isInitialized) {
        try {
          final frame = await _cameraController.takePicture();
          await _sendFrame(frame);
        } catch (e) {
          print('Error capturing frame: $e');
        }
      }
    });
  }

  void _stopStreaming() {
    setState(() {
      _isStreaming = false;
      _statusMessage = "Stream stopped";
    });
    _frameTimer?.cancel();
  }

  Future<void> _sendFrame(XFile imageFile) async {
    try {
      // Read the image file as bytes
      final bytes = await imageFile.readAsBytes();

      // Send the frame to the server via WebSocket
      _channel.sink.add(bytes);
    } catch (e) {
      print('Error sending frame: $e');
      setState(() {
        _statusMessage = "Error sending frame: $e";
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _frameTimer?.cancel();
    _channel.sink.close();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2036), Color(0xFF121420)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                Text(
                  "Initializing camera...",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _showControls ? AppBar(
        backgroundColor: Colors.black38,
        elevation: 0,
        title: Text('Camera Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ) : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          
          // Auto-hide controls again after 5 seconds
          if (_showControls) {
            Timer(Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _showControls = false;
                });
              }
            });
          }
        },
        child: Stack(
          children: [
            // Camera preview - full screen
            Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                ),
              ),
            ),
            
            // Detection overlays
            if (_detectionResults.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: DetectionBoxPainter(_detectionResults),
                ),
              ),
            
            // Status bar at the top
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.black54,
                  child: Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            
            // Detection results count
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_detectionResults.length} objects",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            
            // Streaming indicator
            if (_isStreaming)
              Positioned(
                top: 16,
                left: 16,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          Colors.red.withOpacity(0.6),
                          Colors.red,
                          _animationController.value,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Controls overlay at the bottom
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: _isStreaming ? Icons.stop_circle : Icons.play_circle,
                        label: _isStreaming ? "Stop" : "Start",
                        color: _isStreaming ? Colors.red : Colors.green,
                        onPressed: _isStreaming ? _stopStreaming : _startStreaming,
                      ),
                      SizedBox(width: 20),
                      _buildControlButton(
                        icon: Icons.flip_camera_android,
                        label: "Flip",
                        color: Colors.blue,
                        onPressed: () async {
                          final cameras = await availableCameras();
                          final newCameraIndex = _cameraController.description == cameras[0] ? 1 : 0;
                          
                          if (cameras.length > 1 && newCameraIndex < cameras.length) {
                            await _cameraController.dispose();
                            _cameraController = CameraController(
                              cameras[newCameraIndex],
                              ResolutionPreset.high,
                            );
                            await _cameraController.initialize();
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black45,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Painter for detection bounding boxes
class DetectionBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  
  DetectionBoxPainter(this.detections);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final textPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    
    for (final detection in detections) {
      // Extract normalized coordinates (assuming they're normalized between 0-1)
      final box = detection['box'] as Map<String, dynamic>;
      final x = box['x'] * size.width;
      final y = box['y'] * size.height;
      final w = box['width'] * size.width;
      final h = box['height'] * size.height;
      
      // Draw bounding box
      final rect = Rect.fromLTWH(x, y, w, h);
      canvas.drawRect(rect, paint);
      
      // Draw label with confidence
      final label = detection['class'] ?? 'Unknown';
      final confidence = detection['confidence'] ?? 0.0;
      final text = '$label ${(confidence * 100).toStringAsFixed(0)}%';
      
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Draw background for text
      canvas.drawRect(
        Rect.fromLTWH(x, y - textPainter.height, textPainter.width + 8, textPainter.height),
        Paint()..color = Colors.green,
      );
      
      // Draw text
      textPainter.paint(canvas, Offset(x + 4, y - textPainter.height));
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}