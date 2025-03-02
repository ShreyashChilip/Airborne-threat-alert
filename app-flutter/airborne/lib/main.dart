import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'AeroSentinel',
      theme: themeProvider.themeData,
      home: VideoAnalyzerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VideoAnalyzerScreen extends StatefulWidget {
  @override
  _VideoAnalyzerScreenState createState() => _VideoAnalyzerScreenState();
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
  };


Map<String, int> _getUniqueObjectCounts(VideoJob job) {
  Map<String, int> counts = {
    'bird': 0,
    'drone': 0,
    'missile': 0,
  };
  
  if (job.result != null && job.result!.containsKey('detection_log')) {
    List<dynamic> detectionLog = job.result!['detection_log'];
    
    // Maps to track unique objects by their position across frames
    Map<String, Set<String>> uniqueObjects = {
      'bird': {},
      'drone': {},
      'missile': {},
    };
    
    // Track objects across frames to identify unique objects
    for (var frameData in detectionLog) {
      List<dynamic> detections = frameData['detections'] ?? [];
      
      for (var detection in detections) {
        String className = detection['class'].toString().toLowerCase();
        List<dynamic> bbox = detection['bounding_box'];
        
        // Create a signature based on object position to track it
        // This is a simplified approach - in production, you'd use a more sophisticated tracker
        String objectSignature = "${className}_${bbox[0].toStringAsFixed(0)}_${bbox[1].toStringAsFixed(0)}";
        
        if (className.contains('bird')) {
          uniqueObjects['bird']!.add(objectSignature);
        } else if (className.contains('drone')) {
          uniqueObjects['drone']!.add(objectSignature);
        } else if (className.contains('missile')) {
          uniqueObjects['missile']!.add(objectSignature);
        }
      }
    }
    
    // Count unique objects
    counts['bird'] = uniqueObjects['bird']!.length;
    counts['drone'] = uniqueObjects['drone']!.length;
    counts['missile'] = uniqueObjects['missile']!.length;
  }
  
  return counts;
}

// Replace the existing _getThreatCounts method with this new implementation
Map<String, int> _getThreatCounts(VideoJob job) {
  return _getUniqueObjectCounts(job);
}


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
    // Get threat count if available
    Map<String, int> threatCounts = _getThreatCounts(job);
    bool hasThreats = threatCounts['drone']! > 0 || threatCounts['missile']! > 0;
    
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              hasThreats ? Icons.warning : Icons.check_circle,
              color: hasThreats ? Colors.red : Colors.green,
            ),
            title: Text(job.fileName, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(job.status, style: TextStyle(color: Colors.grey[600])),
          ),
          if (job.status == 'Completed')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildThreatCounter('Birds', threatCounts['bird']!, Colors.green),
                  _buildThreatCounter('Drones', threatCounts['drone']!, Colors.orange),
                  _buildThreatCounter('Missiles', threatCounts['missile']!, Colors.red),
                ],
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

 
// Add these methods to the _VideoAnalyzerScreenState class

void _showResultDialog(VideoJob job) {
  String? downloadUrl = job.result?['download_url'];
  var detectionLog = job.result?['detection_log'];
  var metadata = job.result?['metadata'];
  
  // Get accurate threat counts
  Map<String, int> threatCounts = _getThreatCounts(job);
  bool hasThreats = threatCounts['drone']! > 0 || threatCounts['missile']! > 0;
  String threatLevel = hasThreats ? 
                      (threatCounts['missile']! > 0 ? 'CRITICAL' : 'HIGH') : 
                      'LOW';
  Color threatColor = hasThreats ? 
                     (threatCounts['missile']! > 0 ? Colors.red : Colors.orange) : 
                     Colors.green;
  
  // Extract object tracking information if available
  List<Map<String, dynamic>> objectTracking = [];
  if (metadata != null && metadata.containsKey('object_tracking')) {
    objectTracking = List<Map<String, dynamic>>.from(metadata['object_tracking']);
  }

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
              // Threat summary section
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
              
              // Risk Assessment
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
              
              // Object tracking details if available
              if (objectTracking.isNotEmpty) ...[
                Text('Object Tracking Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: objectTracking.length,
                      itemBuilder: (context, index) {
                        var object = objectTracking[index];
                        return _buildObjectCard(object);
                      },
                    ),
                  ),
                ),
              ] else ...[
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
  String assessmentText = 'No significant threats detected.';
  List<Widget> recommendations = [];
  
  if (threatCounts['missile']! > 0) {
    assessmentText = 'CRITICAL THREAT: Missile detected in surveillance area. Immediate action required.';
    recommendations = [
      _buildRecommendation('Activate emergency response protocols immediately', Icons.warning),
      _buildRecommendation('Notify security command center', Icons.call),
      _buildRecommendation('Initiate countermeasures if available', Icons.shield),
      _buildRecommendation('Begin evacuation procedures for affected areas', Icons.directions_run),
    ];
  } else if (threatCounts['drone']! > 0) {
    assessmentText = 'HIGH ALERT: Unauthorized drone activity detected. Potential security breach.';
    recommendations = [
      _buildRecommendation('Track drone movement patterns', Icons.gps_fixed),
      _buildRecommendation('Determine if airspace is restricted', Icons.not_listed_location),
      _buildRecommendation('Deploy anti-drone measures if necessary', Icons.block),
      _buildRecommendation('Investigate source/operator location', Icons.person_search),
    ];
  } else if (threatCounts['bird']! > 0) {
    assessmentText = 'LOW RISK: Only bird activity detected. No security concern.';
    recommendations = [
      _buildRecommendation('No action required', Icons.check_circle),
      _buildRecommendation('Log for wildlife monitoring if needed', Icons.pets),
    ];
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        assessmentText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: threatCounts['missile']! > 0 ? Colors.red : 
                 threatCounts['drone']! > 0 ? Colors.orange : Colors.green,
        ),
      ),
      SizedBox(height: 8),
      Text('Recommended Actions:', style: TextStyle(fontWeight: FontWeight.w500)),
      SizedBox(height: 4),
      ...recommendations,
    ],
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

Widget _buildObjectCard(Map<String, dynamic> object) {
  String objectClass = object['class'].toString();
  int frameCount = object['frame_count'] ?? 0;
  int firstSeen = object['first_seen'] ?? 0;
  int lastSeen = object['last_seen'] ?? 0;
  
  // Calculate duration based on frame numbers (assuming 30fps)
  double durationSeconds = (lastSeen - firstSeen) / 30.0;
  
  Color objectColor = _getThreatColor(objectClass);
  
  return Card(
    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getThreatIcon(objectClass), color: objectColor),
              SizedBox(width: 8),
              Text(
                objectClass,
                style: TextStyle(fontWeight: FontWeight.bold, color: objectColor),
              ),
            ],
          ),
          Divider(),
          Text('Visible for: ${durationSeconds.toStringAsFixed(1)} seconds'),
          Text('First seen at: ${(firstSeen / 30.0).toStringAsFixed(1)}s'),
          Text('Last seen at: ${(lastSeen / 30.0).toStringAsFixed(1)}s'),
          Text('Appeared in $frameCount frames'),
        ],
      ),
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
              Text('Frame $frameIndex:', 
                  style: TextStyle(fontWeight: FontWeight.w500)),
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
    String lowerClass = objectClass.toLowerCase();
    if (lowerClass.contains('bird')) return Icons.pets;
    if (lowerClass.contains('drone')) return Icons.airplanemode_active;
    if (lowerClass.contains('missile')) return Icons.crisis_alert;
    return Icons.help_outline;
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
        // Get the downloads directory path
        final downloadsDirectory = await getExternalStorageDirectory();
        final path = downloadsDirectory?.path ?? (await getApplicationDocumentsDirectory()).path;
        
        final fileName = 'aerosentinel_analysis_${DateTime.now().millisecondsSinceEpoch}.avi';
        
        // Download the file
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
        // For devices where the permissions aren't working correctly
        // Try direct download using Dio
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
}

class VideoJob {
  String fileName;
  File file;
  String status;
  Map<String, dynamic>? result;

  VideoJob({required this.fileName, required this.file, required this.status, this.result});
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode for security applications
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get themeData => _isDarkMode 
    ? ThemeData.dark().copyWith(
        primaryColor: Color(0xFF0D47A1),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF00ACC1),
        ),
      ) 
    : ThemeData.light().copyWith(
        primaryColor: Colors.blue[700],
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.lightBlue,
        ),
      );
      
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}