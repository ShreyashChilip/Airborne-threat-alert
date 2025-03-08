import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import '../providers/theme_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';

class VideoAnalyzerScreen extends StatefulWidget {
  @override
  _VideoAnalyzerScreenState createState() => _VideoAnalyzerScreenState();
}

class VideoJob {
  String fileName;
  File file;
  String status;
  Map<String, dynamic>? result;

  VideoJob({required this.fileName, required this.file, required this.status, this.result});
}

class _VideoAnalyzerScreenState extends State<VideoAnalyzerScreen> with SingleTickerProviderStateMixin {
  List<VideoJob> _jobs = [];
  bool _isProcessing = false;
  late PageController _pageController;
  late AnimationController _animationController;

  // Map for threat level colors
  final Map<String, Color> _threatColors = {
    'bird': Colors.green,
    'drone': Colors.orange,
    'missile': Colors.red,
    'hot air balloon': Colors.orange,
    'paraglider': Colors.red,
    'airplane': Colors.red,
    'car': Colors.orange,
    'fighter jet': Colors.red,
    'helicopter': Colors.red,
    'landing deck': Colors.orange,
    'person': Colors.orange,
    'ship': Colors.orange,
  };

  // Define threat categories
  final Map<String, Color> threatColors = {
    'Critical': Colors.red,
    'High': Colors.orange,
    'Low': Colors.green,
  };

  final Map<String, List<String>> threatCategories = {
    'Critical': ['missile', 'paraglider', 'airplane', 'fighter jet', 'helicopter'],
    'High': ['drone', 'hot air balloon', 'car', 'landing deck', 'person', 'ship'],
    'Low': ['bird'],
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeProvider.isDarkMode
                ? [Color(0xFF1A2036), Color(0xFF121420)]
                : [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(themeProvider),
            _buildInfoBanner(),
            Expanded(child: _buildVideoList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickVideoFile,
        icon: Icon(Icons.upload_file),
        label: Text('Upload Surveillance Footage'),
        backgroundColor: themeProvider.isDarkMode ? Color(0xFF1E88E5) : Colors.blue,
        elevation: 4,
      ),
    );
  }

  Widget _buildAppBar(ThemeProvider themeProvider) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.radar, size: 28),
          SizedBox(width: 8),
          Text('AeroSentinel'),
        ],
      ),
      backgroundColor: themeProvider.isDarkMode ? Color(0xFF0D47A1) : Colors.blue[700],
      actions: [
        IconButton(
          icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: themeProvider.toggleTheme,
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(12),
      color: Colors.blue[800],
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Airborne Threat Detection System',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Upload surveillance footage to detect and classify airborne objects',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return _jobs.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            itemCount: _jobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(_jobs[index]);
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 80, color: Colors.blue[200]),
          SizedBox(height: 16),
          Text(
            'No surveillance footage analyzed yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload footage to detect birds, drones, and missiles',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(VideoJob job) {
    Map<String, int> threatCounts = _getThreatCounts(job);
    
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.radar,
              color: Colors.blue,
            ),
            title: Text(job.fileName, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(job.status, style: TextStyle(color: Colors.grey[600])),
          ),
          if (job.status == 'Completed')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceEvenly,
                children: threatCounts.entries.map((entry) {
                  return _buildThreatCounter(
                    entry.key.toUpperCase(),
                    entry.value,
                    _threatColors[entry.key] ?? Colors.grey,
                  );
                }).toList(),
              ),
            ),
          if (job.status == 'Completed')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showResultDialog(job),
                    icon: Icon(Icons.assessment),
                    label: Text('Threat Analysis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _downloadVideo(job.result?['download_url']),
                    icon: Icon(Icons.download),
                    label: Text('Download Footage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThreatStat(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        SizedBox(height: 4),
        Text(
          '$count $label',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildThreatCounter(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _pickVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      setState(() {
        _jobs.add(VideoJob(fileName: fileName, file: file, status: 'Queued'));
      });
      if (!_isProcessing) {
        _processNextJob();
      }
    }
  }

  void _processNextJob() async {
    if (_jobs.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    VideoJob? job = _jobs.firstWhere((job) => job.status == 'Queued', orElse: () => VideoJob(fileName: 'Unknown', file: File(''), status: 'Unknown'));

    if (job.status == 'Unknown') {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    setState(() {
      job.status = 'Processing';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://orange-fiesta-rvgxwgwr6pq2wxq9-8000.app.github.dev/process-video/'),
      );
      request.files.add(await http.MultipartFile.fromPath('video', job.file.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var result = jsonDecode(responseData);
        setState(() {
          job.status = 'Completed';
          job.result = result;
        });
      } else {
        setState(() {
          job.status = 'Failed';
        });
      }
    } catch (e) {
      setState(() {
        job.status = 'Failed';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _processNextJob();
    }
  }

  void _showResultDialog(VideoJob job) {
    String? downloadUrl = job.result?['download_url'];
    var detectionLog = job.result?['detection_log'];
    var metadata = job.result?['metadata'];

    Map<String, int> threatCounts = _getThreatCounts(job);
    bool hasThreats = threatCounts['drone']! > 0 || threatCounts['missile']! > 0;
    String threatLevel = hasThreats ? (threatCounts['missile']! > 0 ? 'CRITICAL' : 'HIGH') : 'LOW';
    Color threatColor = hasThreats ? (threatCounts['missile']! > 0 ? Colors.red : Colors.orange) : Colors.green;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: threatColor),
              SizedBox(width: 8),
              Text('Threat Analysis Report'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: threatColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: threatColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Threat Level: $threatLevel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: threatColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('File: ${job.fileName}'),
                      Text('Objects Detected:'),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildThreatStat('Birds', threatCounts['bird']!, Icons.pets, Colors.green),
                          _buildThreatStat('Drones', threatCounts['drone']!, Icons.airplanemode_active, Colors.orange),
                          _buildThreatStat('Missiles', threatCounts['missile']!, Icons.crisis_alert, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Risk Assessment:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRiskAssessment(threatCounts),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('Detection Timeline:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: detectionLog != null
                            ? _buildDetectionTimeline(detectionLog)
                            : Text('No detection data available'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (downloadUrl != null)
              ElevatedButton.icon(
                onPressed: () => _downloadVideo(downloadUrl),
                icon: Icon(Icons.download),
                label: Text('Download Marked Footage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRiskAssessment(Map<String, int> threatCounts) {
    List<String> criticalThreats = [];
    List<String> highThreats = [];
    List<String> lowThreats = [];

    threatCounts.forEach((key, value) {
      if (value > 0) {
        if (threatCategories['Critical']!.contains(key)) {
          criticalThreats.add('$key ($value detected)');
        } else if (threatCategories['High']!.contains(key)) {
          highThreats.add('$key ($value detected)');
        } else if (threatCategories['Low']!.contains(key)) {
          lowThreats.add('$key ($value detected)');
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (criticalThreats.isNotEmpty) ...[
          Text(
            'CRITICAL THREATS DETECTED',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          ...criticalThreats.map((threat) => _buildThreatLine(threat, Colors.red)),
          SizedBox(height: 8),
        ],
        if (highThreats.isNotEmpty) ...[
          Text(
            'HIGH-LEVEL THREATS DETECTED',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          ...highThreats.map((threat) => _buildThreatLine(threat, Colors.orange)),
          SizedBox(height: 8),
        ],
        if (lowThreats.isNotEmpty) ...[
          Text(
            'LOW-LEVEL ACTIVITIES',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          ...lowThreats.map((threat) => _buildThreatLine(threat, Colors.green)),
        ],
        SizedBox(height: 16),
        Text('Recommended Actions:', style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        if (criticalThreats.isNotEmpty)
          _buildRecommendation('Immediate response required for critical threats', Icons.warning),
        if (highThreats.isNotEmpty)
          _buildRecommendation('Monitor high-level threats closely', Icons.visibility),
        if (lowThreats.isNotEmpty)
          _buildRecommendation('Continue normal surveillance', Icons.check_circle),
      ],
    );
  }

  Widget _buildThreatLine(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: color, size: 20),
          SizedBox(width: 4),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionTimeline(List<dynamic> detectionLog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...detectionLog.asMap().entries.map((entry) {
          int frameIndex = entry.key;
          var frameData = entry.value;
          List<dynamic> detections = frameData['detections'] ?? [];

          if (detections.isEmpty) return SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frame $frameIndex:', style: TextStyle(fontWeight: FontWeight.w500)),
              ...detections.map((detection) {
                String objectClass = detection['class'].toString();
                double confidence = detection['confidence'] * 100;
                Color objectColor = _getThreatColor(objectClass);

                return Padding(
                  padding: const EdgeInsets.only(left: 15.0, top: 2.0),
                  child: Row(
                    children: [
                      Icon(
                        _getThreatIcon(objectClass),
                        color: objectColor,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$objectClass (${confidence.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 13,
                          color: objectColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              Divider(),
            ],
          );
        }).toList(),
      ],
    );
  }

  IconData _getThreatIcon(String objectClass) {
    switch (objectClass.toLowerCase()) {
      case 'bird':
        return Icons.pets;
      case 'drone':
        return Icons.airplanemode_active;
      case 'missile':
        return Icons.crisis_alert;
      case 'hot air balloon':
        return Icons.air_sharp;
      case 'paraglider':
        return Icons.paragliding;
      case 'airplane':
        return Icons.flight;
      case 'car':
        return Icons.directions_car;
      case 'fighter jet':
        return Icons.flight_takeoff;
      case 'helicopter':
        return Icons.airplanemode_active;
      case 'landing deck':
        return Icons.local_airport;
      case 'person':
        return Icons.person;
      case 'ship':
        return Icons.directions_boat;
      default:
        return Icons.help_outline;
    }
  }

  Color _getThreatColor(String objectClass) {
    String lowerClass = objectClass.toLowerCase();
    if (lowerClass.contains('bird')) return Colors.green;
    if (lowerClass.contains('drone')) return Colors.orange;
    if (lowerClass.contains('missile')) return Colors.red;
    return Colors.grey;
  }

  Future<void> _downloadVideo(String? url) async {
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download URL not available')),
      );
      return;
    }

    try {
      final status = await Permission.storage.request();

      if (status.isGranted) {
        final downloadsDirectory = await getExternalStorageDirectory();
        final path = downloadsDirectory?.path ?? (await getApplicationDocumentsDirectory()).path;
        final fileName = 'aerosentinel_analysis_${DateTime.now().millisecondsSinceEpoch}.avi';

        final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: path,
          fileName: fileName,
          showNotification: true,
          openFileFromNotification: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download started. Check your notification panel for progress.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'aerosentinel_analysis_${DateTime.now().millisecondsSinceEpoch}.avi';
          final filePath = '${appDir.path}/$fileName';

          await Dio().download(
            url,
            filePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                int progress = (received / total * 100).toInt();
                debugPrint('Download progress: $progress%');
              }
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved to app directory'),
              duration: Duration(seconds: 3),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not save video. Please check app permissions.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download: $e')),
      );
    }
  }

  Map<String, int> _getThreatCounts(VideoJob job) {
    Map<String, int> counts = {
      'bird': 0,
      'drone': 0,
      'missile': 0,
      'hot air balloon': 0,
      'paraglider': 0,
      'airplane': 0,
      'car': 0,
      'fighter jet': 0,
      'helicopter': 0,
      'landing deck': 0,
      'person': 0,
      'ship': 0,
    };

    if (job.result != null && job.result!.containsKey('detection_log')) {
      List<dynamic> detectionLog = job.result!['detection_log'];

      for (var frameData in detectionLog) {
        List<dynamic> detections = frameData['detections'] ?? [];

        for (var detection in detections) {
          String className = detection['class'].toString().toLowerCase();
          if (counts.containsKey(className)) {
            counts[className] = counts[className]! + 1;
          }
        }
      }
    }

    return counts;
  }
}


