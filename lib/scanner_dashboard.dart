import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

class ScannerDashboard extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onScanFromCamera;
  final VoidCallback onScanFromGallery;
  final List<dynamic>? scanResults;
  final Function(String, String) onProcessSampleImage;
  final VoidCallback onNavigateToGraph;
  final VoidCallback onNavigateToAccuracyResults;
  final VoidCallback onToggleDarkMode;

  const ScannerDashboard({
    super.key,
    required this.isDarkMode,
    required this.onScanFromCamera,
    required this.onScanFromGallery,
    this.scanResults,
    required this.onProcessSampleImage,
    required this.onNavigateToGraph,
    required this.onNavigateToAccuracyResults,
    required this.onToggleDarkMode,
  });

  @override
  State<ScannerDashboard> createState() => _ScannerDashboardState();
}

class _ScannerDashboardState extends State<ScannerDashboard> {
  // Sample braid types to display with images from assets folder
  final List<Map<String, String>> sampleBraids = [
    {
      'name': 'Box Braids',
      'image': 'assets/Photo/boxbraids.jpg',
      'description': 'Classic box braids style'
    },
    {
      'name': 'Cornrows',
      'image': 'assets/Photo/cornrows.jpeg',
      'description': 'Traditional cornrows pattern'
    },
    {
      'name': 'Knotless Braids',
      'image': 'assets/Photo/knotlessbraids.jpeg',
      'description': 'Seamless knotless braids'
    },
    {
      'name': 'Twists',
      'image': 'assets/Photo/twist.jpeg',
      'description': 'Stylish two-strand twists'
    },
    {
      'name': 'Fishtail Braids',
      'image': 'assets/Photo/fishtail-braids.jpg',
      'description': 'Intricate fishtail pattern'
    },
    {
      'name': 'Stitch Braids',
      'image': 'assets/Photo/stitch-braids.jpg',
      'description': 'Micro stitch braids style'
    },
    {
      'name': 'Zig Zag Braids',
      'image': 'assets/Photo/zigzag_cornrow.jpg',
      'description': 'Distinctive zig zag pattern'
    },
    {
      'name': 'Braided Man Bun',
      'image': 'assets/Photo/man_bun_braids.jpg',
      'description': 'Stylish men\'s braided bun'
    },
    {
      'name': 'Feed In Braids',
      'image': 'assets/Photo/feed_in.jpeg',
      'description': 'Natural feed in technique'
    },
    {
      'name': 'Men Pop Smoke',
      'image': 'assets/Photo/pop_smoke.jpg',
      'description': 'Trendy men\'s hairstyle'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // Deep navy
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Braids Scanner'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0E21),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Live Scan",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A2BE2), // Violet
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8A2BE2).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_fix_high,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Central camera scan preview framed inside a rounded rectangle
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF00FFFF), // Cyan
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFFF).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Camera preview area (placeholder)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                    
                    // Floating AI indicators and scan effects
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00BFFF), // Electric blue
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          "AI Active",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    
                    // Scan animation effect
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF8A2BE2), // Violet
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section below titled "Detected Braids"
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detected Braids",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Small rounded cards showing braid type name and accuracy percentage
                  if (widget.scanResults != null && widget.scanResults!.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.scanResults!.length > 3 ? 3 : widget.scanResults!.length,
                        itemBuilder: (context, index) {
                          final result = widget.scanResults![index];
                          final label = _formatLabel(result['label']);
                          final confidence = double.parse(result['confidence'].toString());
                          
                          return Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8A2BE2).withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 8),
                                  LinearPercentIndicator(
                                    lineHeight: 10,
                                    percent: confidence,
                                    barRadius: const Radius.circular(5),
                                    progressColor: _getConfidenceColor(confidence * 100),
                                    backgroundColor: Colors.grey[800]!,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "${(confidence * 100).toStringAsFixed(1)}%",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "No detections yet",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Popular Braid Styles Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Popular Braid Styles:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sampleBraids.length,
                      itemBuilder: (context, index) {
                        final braid = sampleBraids[index];
                        return GestureDetector(
                          onTap: () {
                            // Process the sample image when tapped
                            widget.onProcessSampleImage(braid['image']!, braid['name']!);
                            
                            // Show a snackbar message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Processing sample image for ${braid['name']}..."),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8A2BE2).withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Display actual image from lib folder
                                Container(
                                  height: 75,
                                  width: 75,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF00BFFF), // Electric blue
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      braid['image']!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to icon if image not found
                                        return Icon(
                                          _getIconForBraidType(braid['name']!),
                                          size: 40,
                                          color: const Color(0xFF00BFFF),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8A2BE2).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "Scan Sample",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Control buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onPressed: widget.onScanFromCamera,
                    color: const Color(0xFF8A2BE2), // Violet
                  ),
                  _buildActionButton(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onPressed: widget.onScanFromGallery,
                    color: const Color(0xFF00BFFF), // Electric blue
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xFF8A2BE2), // Violet
            ),
            child: const Text(
              'Braids Scanner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              // Navigate back to home screen
              //Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Scanner'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Graph View'),
            onTap: () {
              Navigator.pop(context);
              widget.onNavigateToGraph();
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Accuracy Results'),
            onTap: () {
              Navigator.pop(context);
              widget.onNavigateToAccuracyResults();
            },
          ),
          ListTile(
            leading: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: Text(widget.isDarkMode ? 'Light Mode' : 'Dark Mode'),
            onTap: () {
              widget.onToggleDarkMode();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: color,
        elevation: 5,
        shadowColor: color.withOpacity(0.5),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper method to format labels
  String _formatLabel(String label) {
    // Remove leading numbers and spaces
    final formatted = label.replaceAll(RegExp(r'^\d+\s*'), '');
    // Replace underscores with spaces and capitalize
    return formatted.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  // Helper method to get color based on confidence level
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) {
      return const Color(0xFF00FF00); // Green
    } else if (confidence >= 60) {
      return const Color(0xFFFFFF00); // Yellow
    } else {
      return const Color(0xFFFF0000); // Red
    }
  }

  // Helper method to get appropriate icon for each braid type
  IconData _getIconForBraidType(String braidName) {
    switch (braidName) {
      case 'Box Braids':
        return Icons.grid_view;
      case 'Cornrows':
        return Icons.view_stream;
      case 'Knotless Braids':
        return Icons.link;
      case 'Twists':
        return Icons.sync_alt;
      case 'Fishtail Braids':
        return Icons.grain;
      case 'Stitch Braids':
        return Icons.linear_scale;
      case 'Zig Zag Braids':
        return Icons.show_chart;
      case 'Braided Man Bun':
        return Icons.account_circle;
      case 'Feed In Braids':
        return Icons.arrow_downward;
      case 'Men Pop Smoke':
        return Icons.person_pin;
      default:
        return Icons.style;
    }
  }
}