import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MonitorScreen extends StatefulWidget {
  @override
  _MonitorScreenState createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _alerts = [];
  Timer? _radarTimer;
  double _radarAngle = 0; // Angle for the rotating radar hand
  Timer? _pollingTimer;
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _radarAnimationController;
  late AudioPlayer _audioPlayer;
  bool _isAlarmActive = false;
  Timer? _blinkTimer;
  double _radarSweepAngle = 0;
  TwilioFlutter? _twilioFlutter;
  bool _hasNotified = false; // Flag to ensure actions occur only once

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _radarAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat();

    // Initialize Twilio
    _twilioFlutter = TwilioFlutter(
      accountSid: 'ACf50c53d912f76e9bd0d05fe0090488e1', // Replace with your Twilio Account SID
      authToken: '4e40a346d3746554cd146cd84c643d7e',   // Replace with your Twilio Auth Token
      twilioNumber: '+18157066809',    // Replace with your Twilio phone number
    );

    // Start both radar animation and alert polling
    _startPolling();
    _startRadarAnimation();
  }

  @override
  void dispose() {
    _radarAnimationController.dispose();
    _audioPlayer.dispose();
    _blinkTimer?.cancel();
    _radarTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Initial fetch
    _fetchAlerts();

    // Then fetch alerts every 2 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _fetchAlerts();
    });
  }

  void _startRadarAnimation() {
    _radarTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        _radarAngle += 0.05;
        if (_radarAngle >= 2 * pi) {
          _radarAngle = 0;
        }
      });
    });
  }

  Future<void> _fetchAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('https://orange-fiesta-rvgxwgwr6pq2wxq9-8000.app.github.dev/alerts'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(data['alerts']);
          _isLoading = false;
          _errorMessage = '';
        });

        // Check for critical threats after updating alerts
        _checkForCriticalThreats();
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch alerts: ${response.statusCode}';
          _isLoading = false;
        });
        print('Failed to fetch alerts: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching alerts: $e';
        _isLoading = false;
      });
      print('Error fetching alerts: $e');
    }
  }

void _checkForCriticalThreats() {
  bool hasCriticalThreats = _alerts.any((alert) => alert['threat_level'] == 'Critical');

  if (hasCriticalThreats && !_isAlarmActive && !_hasNotified) {
    // Use a post-frame callback to ensure the UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playAlarm();
      _sendNotifications();
    });
  } else if (!hasCriticalThreats) {
    // Reset the flag when no critical threats are detected
    setState(() {
      _hasNotified = false;
    });
  }
}

  void _sendNotifications() async {
    if (!_hasNotified) {
      _hasNotified = true; // Set the flag to true to prevent multiple notifications

      // Send emails
      await _sendEmails();

      // Place a call
      await _placeCall();
    }
  }

  Future<void> _sendEmails() async {
    final smtpServer = gmail('tester.720.lol@gmail.com', 'eggi fpqq yrbb hnqt'); // Replace with your email credentials

    final threatClass = _getLatestCriticalThreat();
    final currentDateTime = DateTime.now().toString();

    final message = Message()
      ..from = Address('tester.720.lol@gmail.com', 'AeroSentinel Monitor')
      ..recipients.add('shreyash06chilip@gmail.com') // Replace with the first hardcoded email
      ..recipients.add('ram.belitkar@gmail.com') // Replace with the second hardcoded email
      ..subject = 'Critical Threat Detected: $threatClass'
      ..text = 'A critical threat ($threatClass) was detected on $currentDateTime.';

    try {
      final sendReport = await send(message, smtpServer);
      print('Emails sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending emails: $e');
    }
  }

  Future<void> _placeCall() async {
  const accountSid = 'ACf50c53d912f76e9bd0d05fe0090488e1'; // Replace with your Twilio Account SID
  const authToken = '4e40a346d3746554cd146cd84c643d7e';   // Replace with your Twilio Auth Token
  const fromNumber = '+18157066809';      // Replace with your Twilio phone number
  const toNumber = '+918446872705';               // Replace with the hardcoded phone number

  final url = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Calls.json');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'To': toNumber,
      'From': fromNumber,
      'Url': 'https://handler.twilio.com/twiml/YOUR_TWIML_URL', // Replace with your TwiML URL
    },
  );

  if (response.statusCode == 201) {
    print('Call placed successfully');
  } else {
    print('Failed to place call: ${response.statusCode}');
    print('Response body: ${response.body}');
  }
}

  void _playAlarm() async {
    if (!_isAlarmActive) {
      setState(() {
        _isAlarmActive = true;
      });

      try {
        // Set the audio to loop
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        // Play the alarm sound
        await _audioPlayer.play(AssetSource('audio/alarm.mp3'));

        if (!mounted) return;

        // Show the alert dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.red[50],
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CRITICAL THREAT DETECTED',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Immediate action required!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Threat Type: ${_getLatestCriticalThreat()}'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _stopAlarm();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('ACKNOWLEDGE'),
              ),
            ],
          ),
        );
      } catch (e) {
        print('Error playing alarm: $e');
        setState(() {
          _isAlarmActive = false;
        });
      }
    }
  }

void _stopAlarm() {
  _audioPlayer.stop();
  setState(() {
    _isAlarmActive = false;
    // Do not reset _hasNotified here
  });
}

  String _getLatestCriticalThreat() {
    for (var alert in _alerts.reversed) {
      if (alert['threat_level'] == 'Critical') {
        return alert['object_class'] ?? 'Unknown';
      }
    }
    return 'Unknown';
  }

String _generateCSVReport() {
  String csv = 'Threat Level,Object Class,Confidence,Direction,Velocity\n';
  for (var alert in _alerts) {
    final threatLevel = alert['threat_level'] ?? 'Unknown';
    final objectClass = alert['object_class'] ?? 'Unknown';
    final confidence = alert['confidence'] ?? 0.0;
    final direction = alert['movement']?['direction'] ?? 'Unknown';
    final velocity = alert['movement']?['velocity'] ?? 'Unknown';
    csv += '$threatLevel,$objectClass,$confidence,$direction,$velocity\n';
  }
  return csv;
}

  // Download CSV report
  Future<void> _downloadReport() async {
    final csvContent = _generateCSVReport();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/alerts_report.csv');
    await file.writeAsString(csvContent);

    final taskId = await FlutterDownloader.enqueue(
      url: 'file://${file.path}',
      savedDir: directory.path,
      fileName: 'alerts_report.csv',
      showNotification: true,
      openFileFromNotification: true,
    );

    if (taskId != null) {
      print('Download started with taskId: $taskId');
    } else {
      print('Download failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AeroSentinel Monitor'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          if (_isAlarmActive)
            IconButton(
              icon: Icon(Icons.notifications_off, color: Colors.red),
              onPressed: _stopAlarm,
              tooltip: 'Stop Alarm',
            ),
        ],
      ),
      body: Container(
        color: Colors.black87,
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: _buildThreatDisplay(),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: RadarPainter(
                      alerts: _alerts,
                      angle: _radarAngle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatDisplay() {
    // Group alerts by threat level
    Map<String, List<Map<String, dynamic>>> threatGroups = {
      'Critical': [],
      'High': [],
      'Low': [],
    };

    for (var alert in _alerts) {
      String level = alert['threat_level'] ?? 'Unknown';
      if (threatGroups.containsKey(level)) {
        threatGroups[level]!.add(alert);
      }
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Threat Summary'),
              Tab(text: 'All Alerts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildThreatSummary(threatGroups),
                _buildAlertsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatSummary(Map<String, List<Map<String, dynamic>>> threatGroups) {
    return ListView(
      children: [
        _buildThreatLevelCard('Critical', threatGroups['Critical']!, Colors.red),
        _buildThreatLevelCard('High', threatGroups['High']!, Colors.orange),
        _buildThreatLevelCard('Low', threatGroups['Low']!, Colors.green),
      ],
    );
  }

  Widget _buildThreatLevelCard(String level, List<Map<String, dynamic>> threats, Color color) {
    if (threats.isEmpty) {
      return Card(
        margin: EdgeInsets.all(8),
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Colors.grey),
          title: Text('No $level Threats'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.all(8),
      child: ExpansionTile(
        leading: Icon(Icons.warning, color: color),
        title: Text('$level Threats (${threats.length})'),
        children: threats.map((threat) => _buildThreatDetail(threat, color)).toList(),
      ),
    );
  }

  Widget _buildThreatDetail(Map<String, dynamic> threat, Color color) {
    final direction = threat['movement']?['direction'] ?? 'Unknown';
    final velocity = threat['movement']?['velocity'] ?? 'Unknown';
    final confidence = threat['confidence'] ?? 0.0;
    
    return ListTile(
      leading: Icon(Icons.radio_button_checked, color: color, size: 16),
      title: Text(threat['object_class'] ?? 'Unknown Object'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Direction: $direction'),
          Text('Speed: $velocity'),
          Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
        ],
      ),
      dense: true,
    );
  }

  Widget _buildAlertsList() {
    if (_alerts.isEmpty) {
      return Center(child: Text('No threats detected'));
    }
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: _downloadReport,
          child: Text('Download CSV Report'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _alerts.length,
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              return _buildAlertCard(alert);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final threatLevel = alert['threat_level'];
    final color = threatLevel == 'Critical'
        ? Colors.red
        : threatLevel == 'High'
            ? Colors.orange
            : Colors.green;

    final objectClass = alert['object_class'] ?? 'Unknown';
    final confidence = alert['confidence'] ?? 0.0;
    final direction = alert['movement']?['direction'] ?? 'Unknown';
    final velocity = alert['movement']?['velocity'] ?? 'Unknown';

    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: Icon(Icons.warning, color: color),
        title: Text(objectClass),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
            Text('Movement: $direction, $velocity'),
          ],
        ),
        trailing: Chip(
          label: Text(threatLevel, style: TextStyle(color: Colors.white)),
          backgroundColor: color,
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final List<Map<String, dynamic>> alerts;
  final double angle;

  RadarPainter({
    required this.alerts,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Background
    final bgPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Grid circles
    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, gridPaint);
    }

    // Grid lines
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        center,
        Offset(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        ),
        gridPaint,
      );
    }

    // Sweep line
    final sweepPaint = Paint()
      ..color = Colors.green.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        angle - 0.2,
        0.4,
        false,
      )
      ..lineTo(center.dx, center.dy);

    canvas.drawPath(sweepPath, sweepPaint);

    // Draw blips for detected objects
    for (var alert in alerts) {
      if (alert['position'] != null) {
        final pos = alert['position'];
        final x = center.dx + (pos['x'] - 0.5) * radius * 2;
        final y = center.dy + (pos['y'] - 0.5) * radius * 2;

        final blipAngle = atan2(y - center.dy, x - center.dx);
        final normalizedBlipAngle = blipAngle < 0 ? blipAngle + 2 * pi : blipAngle;
        final angleDiff = (normalizedBlipAngle - angle).abs();
        
        final color = alert['threat_level'] == 'Critical' 
            ? Colors.red 
            : alert['threat_level'] == 'High' 
                ? Colors.orange 
                : Colors.green;

        final opacity = angleDiff < 0.5 || angleDiff > 2 * pi - 0.5 ? 1.0 : 0.3;

        final blipPaint = Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(Offset(x, y), 4, blipPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) => true;
}