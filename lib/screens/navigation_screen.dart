import 'package:flutter/material.dart';
import 'dart:async';
import 'video_analyzer_screen.dart';
import 'camera_feed_screen.dart';
import 'monitor_screen.dart';

class NavigationScreen extends StatefulWidget {
  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  final int _totalPages = 3;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Set up animation for background pulse effect
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    // Start auto-scrolling timer
    _startAutoScroll();
    
    // Listen to page changes
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _totalPages - 1) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A2036),
                  Color.lerp(Color(0xFF121420), Color(0xFF2A3456), _animation.value)!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                _buildBackgroundParticles(),
                
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Video Analysis Suite',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          children: [
                            _buildFeatureCard(
                              context,
                              'Video Upload',
                              'Analyze pre-recorded videos with advanced algorithms for detailed insights.',
                              Icons.upload_file,
                              'assets/video_upload.png', // Add this asset or replace with your image
                              Colors.blue.shade700,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => VideoAnalyzerScreen()),
                              ),
                            ),
                            _buildFeatureCard(
                              context,
                              'Camera Feed',
                              'Process real-time camera input with instant feedback and analysis.',
                              Icons.camera_alt,
                              'assets/camera.png', // Add this asset or replace with your image
                              Colors.green.shade700,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CameraFeedScreen()),
                              ),
                            ),
                            _buildFeatureCard(
                              context,
                              'Monitor',
                              'Track metrics and receive alerts based on custom thresholds and conditions.',
                              Icons.monitor_heart,
                              'assets/monitor.png', // Add this asset or replace with your image
                              Colors.purple.shade700,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MonitorScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Page indicator
                      Container(
                        margin: EdgeInsets.only(bottom: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _totalPages,
                            (index) => _buildPageIndicator(index == _currentPage),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    String imagePath,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.8),
              accentColor.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feature image placeholder - replace with actual image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: Colors.black26,
                ),
                width: double.infinity,
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
                // Alternatively, use an actual image:
                // child: ClipRRect(
                //   borderRadius: BorderRadius.only(
                //     topLeft: Radius.circular(20),
                //     topRight: Radius.circular(20),
                //   ),
                //   child: Image.asset(
                //     imagePath,
                //     fit: BoxFit.cover,
                //   ),
                // ),
              ),
            ),
            
            // Feature details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildBackgroundParticles() {
    // Simple animated background particles
    return Positioned.fill(
      child: CustomPaint(
        painter: ParticlesPainter(_animation.value),
      ),
    );
  }
}

// Particle animation painter
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  ParticlesPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    // Create a shimmer effect with moving dots
    for (int i = 0; i < 50; i++) {
      double x = (i * size.width / 25) + (animationValue * 20);
      double offsetY = i % 2 == 0 ? 15 * animationValue : -15 * animationValue;
      double y = (i * size.height / 25) + offsetY;
      
      x = x % size.width;
      y = y % size.height;
      
      double radius = 1.5 + (animationValue * 1.5);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}