import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
// Import the fl_chart package for graph visualization
import 'package:fl_chart/fl_chart.dart';
// Import services for asset handling
import 'package:flutter/services.dart' show rootBundle;
// Import dart:ui for potential future use with image processing
import 'dart:ui' as ui; // ignore: unused_import
// Import shared preferences for local storage fallback
import 'package:shared_preferences/shared_preferences.dart';
import 'graph_screen.dart';
import 'accuracy_results_screen.dart';

class BraidScannerHome extends StatefulWidget {
  // Add parameters for dark mode
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;

  const BraidScannerHome({
    super.key,
    required this.isDarkMode,
    required this.toggleDarkMode,
  });

  @override
  State<BraidScannerHome> createState() => _BraidScannerHomeState();
}

class _BraidScannerHomeState extends State<BraidScannerHome> {
  // --- State Variables ---
  File? _image;
  Uint8List? _sampleImageData; // For displaying sample images
  List<dynamic>? _outputs; // Prediction results
  bool _loading = false; // For showing loading indicator
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loading = true;
    loadModel().then((_) {
      setState(() {
        _loading = false;
      });
    });
    _signInAnonymously();
  }

  // --- Reset Scan Function ---
  // This function clears the image and prediction results
  void _resetScan() {
    setState(() {
      _image = null; // Clear the selected image
      _sampleImageData = null; // Clear the sample image data
      _outputs = null; // Clear prediction results
      // Note: We keep _loading as false since we're not loading anything
    });
  }



  // --- Anonymous Firebase Auth ---
  Future<void> _signInAnonymously() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint("✅ Firebase Auth Success: ${userCredential.user?.uid}");
      
      // Also listen for auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
          debugPrint('🔴 User is currently signed out!');
        } else {
          debugPrint('🟢 User is signed in: ${user.uid}');
        }
      });
    } catch (e) {
      debugPrint("❌ Firebase Auth Error: $e");
      // Show a snackbar or dialog to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication failed. Some features may be limited.")),
        );
      }
      
      // Continue with the app even if auth fails
      // The saveScanToFirebase function will handle the case when user is null
    }
  }

  // --- Save Result to Firebase Realtime Database ---
  void saveScanToFirebase(dynamic bestPrediction) {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      debugPrint("🔍 Checking user authentication status...");
      
      // Check if user is authenticated
      if (user == null) {
        debugPrint("⚠️ No authenticated user found. Saving with anonymous identifier.");
        // Generate a temporary identifier for anonymous users
        final String tempUserId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
        
        // Save with temporary identifier
        _saveScanData(bestPrediction, tempUserId);
        return;
      }
      
      debugPrint("✅ User authenticated: ${user.uid}");
      debugPrint("💾 Saving scan data: ${bestPrediction['label']} with confidence: ${bestPrediction['confidence']}");
      
      _saveScanData(bestPrediction, user.uid);
    } on FirebaseException catch (e) {
      debugPrint("❌ Firebase Error in saveScanToFirebase: ${e.code} - ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Firebase service unavailable. Scan results will not be saved.")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error in saveScanToFirebase: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to save scan data. Please check your connection.")),
        );
      }
    }
  }
  
  // Helper method to save scan data
  void _saveScanData(dynamic bestPrediction, String userId) {
    try {
      // Get reference to the Realtime Database
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      
      // Create a new scan entry with a unique key
      final DatabaseReference newScanRef = dbRef
          .child('users')
          .child(userId)
          .child('scans')
          .push();
          
      // Save the scan data
      newScanRef.set({
        'braid_type': bestPrediction['label'],
        'confidence': bestPrediction['confidence'].toDouble(), // Ensure it's double
        'timestamp': ServerValue.timestamp,
      }).then((_) {
        debugPrint("✅ Scan saved successfully with key: ${newScanRef.key}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scan saved to Firebase Realtime Database")),
          );
        }
        
        // Also save to local storage as backup
        _saveToLocal(bestPrediction);
      }).catchError((Object error) {
        debugPrint("❌ Error saving scan: $error");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save scan: $error")),
          );
        }
        
        // Save to local storage as fallback
        _saveToLocal(bestPrediction);
      });
    } on FirebaseException catch (e) {
      debugPrint("❌ Firebase Error in _saveScanData: ${e.code} - ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Firebase service unavailable. Scan results will not be saved.")),
        );
      }
      
      // Save to local storage as fallback
      _saveToLocal(bestPrediction);
    } catch (e) {
      debugPrint("❌ Error in _saveScanData: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to save scan data. Please check your connection.")),
        );
      }
      
      // Save to local storage as fallback
      _saveToLocal(bestPrediction);
    }
  }
  
  // Helper method to save scan data to local storage as backup
  Future<void> _saveToLocal(dynamic bestPrediction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? existingScans = prefs.getStringList('scan_history');
      
      // Create new scan entry
      final newScan = {
        'braid_type': bestPrediction['label'],
        'confidence': bestPrediction['confidence'].toDouble(), // Ensure it's double
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Add to existing scans
      final updatedScans = existingScans != null ? List<String>.from(existingScans) : <String>[];
      updatedScans.add(jsonEncode(newScan));
      
      // Keep only the last 50 scans to prevent storage bloat
      if (updatedScans.length > 50) {
        updatedScans.removeRange(0, updatedScans.length - 50);
      }
      
      // Save back to preferences
      await prefs.setStringList('scan_history', updatedScans);
      
      debugPrint("✅ Scan saved to local storage");
    } catch (e) {
      debugPrint("❌ Error saving to local storage: $e");
    }
  }

  // --- Load TFLite Model ---
  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  // --- Pick Image ---
  Future<void> pickImage(ImageSource source) async {
    XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _loading = true;
      _image = File(image.path);
    });

    await classifyImage(_image!);
  }

  // --- Run Model Prediction ---
  Future<void> classifyImage(File image) async {
    debugPrint("🔍 Starting image classification...");
    
    List<dynamic>? output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 5,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    debugPrint("🧠 Model output received: ${output?.length} results");

    setState(() {
      _loading = false;
      _outputs = output;
    });

    // Save to Firebase only if we have results
    if (_outputs != null && _outputs!.isNotEmpty) {
      debugPrint("📤 Saving to Firebase: ${_outputs![0]}");
      saveScanToFirebase(_outputs![0]);
    } else {
      debugPrint("⚠️ No results to save to Firebase");
    }
  }

  // --- Method to navigate to graph screen ---
  void _navigateToGraph() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GraphScreen(isDarkMode: widget.isDarkMode),
      ),
    );
  }

  // --- Method to navigate to accuracy results screen ---
  void _navigateToAccuracyResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccuracyResultsScreen(isDarkMode: widget.isDarkMode),
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Braids Scanner'),
        centerTitle: true,
        // Add the X button to the AppBar if there's an image/result
        actions: [
          if (_image != null || _outputs != null || _sampleImageData != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _resetScan, // Call reset function when pressed
              tooltip: 'Clear scan',
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.purple : Colors.purpleAccent,
              ),
              child: Text(
                'Braids Scanner',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
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
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
                _navigateToGraph();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Accuracy Results'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAccuracyResults();
              },
            ),
            ListTile(
              leading: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              title: Text(widget.isDarkMode ? 'Light Mode' : 'Dark Mode'),
              onTap: () {
                widget.toggleDarkMode();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- Image Display Area ---
            Center(
              child: (_image == null && _sampleImageData == null)
                  ? Container(
                      height: 250,
                      width: 300,
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(Icons.image, size: 50, color: widget.isDarkMode ? Colors.grey[400] : Colors.grey),
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _sampleImageData != null
                              ? Image.memory(_sampleImageData!, height: 250, width: 300, fit: BoxFit.cover)
                              : Image.file(_image!, height: 250, width: 300, fit: BoxFit.cover),
                        ),
                        // Add the X button on top of the image
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _resetScan,
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // --- Loading Indicator ---
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),

            const SizedBox(height: 20),

            // --- Result Display Area ---
            _outputs != null
                ? _buildEnhancedResults()
                : _image == null
                    ? Text("Upload an image to scan", style: TextStyle(fontSize: 16, color: widget.isDarkMode ? Colors.white70 : Colors.black87))
                    : Text("Processing image...", style: TextStyle(fontSize: 16, color: widget.isDarkMode ? Colors.white70 : Colors.black87)),

            const SizedBox(height: 30),

            // --- Control Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton.extended(
                  onPressed: () => pickImage(ImageSource.camera),
                  label: const Text("Camera"),
                  icon: const Icon(Icons.camera_alt),
                  heroTag: "cam",
                  backgroundColor: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                  foregroundColor: Colors.white,
                ),
                FloatingActionButton.extended(
                  onPressed: () => pickImage(ImageSource.gallery),
                  label: const Text("Gallery"),
                  icon: const Icon(Icons.photo_library),
                  heroTag: "gal",
                  backgroundColor: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            
            // --- Sample Braid Types Section ---
            const SizedBox(height: 30),
            _buildSampleBraidsSection(),
          ],
        ),
      ),
    );
  }

  // --- Enhanced Results Display with All Requested Features ---
  Widget _buildEnhancedResults() {
    // Get analytics data
    final analyticsData = _getAnalyticsData();
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header for results section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.purple.withOpacity(0.3) : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights,
                  color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                ),
                const SizedBox(width: 10),
                Text(
                  "Scan Results",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 1. Accuracy Per Class (Only ONE Value per Class)
          Text(
            "Accuracy per Class:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          
          // Display each class with its accuracy percentage using LinearPercentIndicator
          ..._outputs!.map((dynamic res) {
            final label = _formatLabel(res['label']);
            final confidence = double.parse(res['confidence'].toString());
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        "${(confidence * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LinearPercentIndicator(
                    lineHeight: 14.0,
                    percent: confidence,
                    center: Text(
                      "${(confidence * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold),
                    ),
                    barRadius: const Radius.circular(10),
                    progressColor: _getConfidenceColor(confidence * 100),
                    backgroundColor: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 20),
          
          // 2. Graph Visualization (Bar Chart)
          Text(
            "Confidence Distribution:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: _buildBarChart(),
          ),
          
          const SizedBox(height: 20),
          
          // 3. Prediction Analytics Section
          Text(
            "Prediction Analytics:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalyticsRow("Top Prediction", analyticsData['topPrediction']),
                const SizedBox(height: 8),
                _buildAnalyticsRow("Total Scans", analyticsData['totalScans'].toString()),
                const SizedBox(height: 8),
                _buildAnalyticsRow("Average Confidence", "${analyticsData['avgConfidence']}%"),
                const SizedBox(height: 8),
                _buildAnalyticsRow("Most Scanned Style", analyticsData['mostScanned']),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get color based on confidence level
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) {
      return Colors.green;
    } else if (confidence >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Helper method to format labels (remove numbers and underscores)
  String _formatLabel(String label) {
    // Remove leading numbers and spaces
    final formatted = label.replaceAll(RegExp(r'^\d+\s*'), '');
    // Replace underscores with spaces and capitalize
    return formatted.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }
  
  // Helper method to build analytics rows
  Widget _buildAnalyticsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
          ),
        ),
      ],
    );
  }
  
  // Method to calculate analytics data (mock data for demonstration)
  Map<String, dynamic> _getAnalyticsData() {
    if (_outputs == null || _outputs!.isEmpty) {
      return {
        'topPrediction': 'N/A',
        'totalScans': 0,
        'avgConfidence': '0.0',
        'mostScanned': 'N/A'
      };
    }
    
    // Get top prediction
    final topPrediction = _formatLabel(_outputs![0]['label']);
    final topConfidence = (double.parse(_outputs![0]['confidence'].toString()) * 100).toStringAsFixed(1);
    
    // Mock data for demonstration (in a real app, this would come from Firebase)
    return {
      'topPrediction': '$topPrediction ($topConfidence%)',
      'totalScans': 58, // Mock data
      'avgConfidence': '87', // Mock data
      'mostScanned': topPrediction, // Mock data
    };
  }
  
  // 4. Bar Chart Visualization
  Widget _buildBarChart() {
    if (_outputs == null || _outputs!.isEmpty) {
      return const Center(child: Text("No data available"));
    }
    
    // Prepare data for the bar chart
    List<BarChartGroupData> barGroups = [];
    List<String> labels = [];
    
    for (int i = 0; i < _outputs!.length; i++) {
      final res = _outputs![i];
      final confidence = double.parse(res['confidence'].toString());
      final label = _formatLabel(res['label']);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: confidence * 100, // Convert to percentage
              color: _getColorForIndex(i),
              width: 15,
              borderRadius: BorderRadius.zero,
              rodStackItems: [],
            ),
          ],
        ),
      );
      
      labels.add(label.split(' ').first); // Use first word for x-axis
    }
    
    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = _formatLabel(_outputs![groupIndex]['label']);
              final confidence = (rod.toY).toStringAsFixed(1);
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$confidence%',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  // Helper method to get colors for bar chart
  Color _getColorForIndex(int index) {
    const List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.yellow,
      Colors.cyan,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
  
  // 5. Sample Braid Types Section (Horizontal Scroll)
  Widget _buildSampleBraidsSection() {
    // Sample braid types to display with images from assets folder
    final sampleBraids = [
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Popular Braid Styles:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sampleBraids.length,
            itemBuilder: (context, index) {
              final braid = sampleBraids[index];
              return GestureDetector(
                onTap: () {
                  // Process the sample image when tapped
                  _processSampleImage(braid['image'] as String, braid['name'] as String);
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(left: 15),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Display actual image from lib folder
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            braid['image'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to icon if image not found
                              return Icon(
                                _getIconForBraidType(braid['name'] as String),
                                size: 40,
                                color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.purple.withOpacity(0.3) : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Scan Sample",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
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
    );
  }

  // Method to process sample images
  Future<void> _processSampleImage(String imagePath, String braidName) async {
    setState(() {
      _loading = true;
    });
    
    try {
      // Show a message that we're processing the sample
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Processing sample image for $braidName..."),
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Load the sample image to display in the scanner area
      ByteData bytes = await rootBundle.load(imagePath);
      Uint8List imageData = bytes.buffer.asUint8List();
      
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate mock results for demonstration
      List<Map<String, dynamic>> mockResults = _generateMockResults(braidName);
      
      setState(() {
        _loading = false;
        _outputs = mockResults;
        _sampleImageData = imageData; // Set the sample image data for display
        _image = null; // Clear any file-based image
      });
      
      // Save to Firebase if we have results
      if (mockResults.isNotEmpty) {
        debugPrint("📤 Saving sample scan to Firebase: ${mockResults[0]}");
        saveScanToFirebase(mockResults[0]);
      } else {
        debugPrint("⚠️ No results to save to Firebase from sample scan");
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sample scan complete for $braidName!"),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error processing sample: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Helper method to generate mock results for demonstration
  List<Map<String, dynamic>> _generateMockResults(String braidName) {
    // Create mock results based on the selected braid type
    List<Map<String, dynamic>> results = [];
    
    // Define confidence values for different braid types
    Map<String, Map<String, double>> braidConfidences = {
      'Box Braids': {
        'box_braids': 0.92,
        'corn_braids': 0.03,
        'two_strand_twists': 0.02,
        'feed_in_braids': 0.02,
        'zig_zag_braids': 0.01,
        'fishtail_braids': 0.01,
        'stitch_braids': 0.01,
        'braided_man_bun': 0.01,
        'men_pop_smoke': 0.01,
      },
      'Cornrows': {
        'corn_braids': 0.88,
        'box_braids': 0.05,
        'feed_in_braids': 0.04,
        'two_strand_twists': 0.02,
        'zig_zag_braids': 0.01,
        'fishtail_braids': 0.01,
        'stitch_braids': 0.01,
        'braided_man_bun': 0.01,
        'men_pop_smoke': 0.01,
      },
      'Knotless Braids': {
        'knotless_braids': 0.85,
        'feed_in_braids': 0.10,
        'box_braids': 0.02,
        'corn_braids': 0.01,
        'two_strand_twists': 0.01,
        'zig_zag_braids': 0.01,
        'fishtail_braids': 0.01,
        'stitch_braids': 0.01,
        'braided_man_bun': 0.01,
        'men_pop_smoke': 0.01,
      },
      'Twists': {
        'two_strand_twists': 0.90,
        'box_braids': 0.04,
        'corn_braids': 0.03,
        'feed_in_braids': 0.02,
        'zig_zag_braids': 0.01,
        'fishtail_braids': 0.01,
        'stitch_braids': 0.01,
        'braided_man_bun': 0.01,
        'men_pop_smoke': 0.01,
      },
      'Fishtail Braids': {
        'fishtail_braids': 0.85,
        'box_braids': 0.05,
        'corn_braids': 0.03,
        'two_strand_twists': 0.02,
        'feed_in_braids': 0.02,
        'zig_zag_braids': 0.01,
        'stitch_braids': 0.01,
        'braided_man_bun': 0.01,
        'men_pop_smoke': 0.01,
      },
      'Stitch Braids': {
        'stitch_braids': 0.88,
        'box_braids': 0.04,
        'corn_braids': 0.03,
        'two_strand_twists': 0.02,
        'feed_in_braids': 0.02,
        'zig_zag_braids': 0.01,
        'fishtail_braids': 0.01,
        'braided_man_bun': 0.01,
        'men_pop_smoke': 0.01,
      },
      'Zig Zag Braids': {
        'zig_zag_braids': 0.90,
        'box_braids': 0.03,
        'corn_braids': 0.02,
        'two_strand_twists': 0.02,
        'feed_in_braids': 0.01,
        'fishtail_braids': 0.01,
        'stitch_braids': 0.01,
        'braided_man_bun': 0.01,
        'men_pop_smoke': 0.01,
      },
      'Braided Man Bun': {
        'braided_man_bun': 0.87,
        'men_pop_smoke': 0.05,
        'box_braids': 0.03,
        'corn_braids': 0.02,
        'two_strand_twists': 0.01,
        'feed_in_braids': 0.01,
        'zig_zag_braids': 0.01,
        'fishtail_braids': 0.01,
        'stitch_braids': 0.01,
      },
      'Feed In Braids': {
        'feed_in_braids': 0.90,
        'knotless_braids': 0.05,
        'box_braids': 0.02,
        'corn_braids': 0.01,
        'two_strand_twists': 0.01,
        'zig_zag_braids': 0.01,
        'fishtail_braids': 0.01,
        'stitch_braids': 0.01,
        'braided_man_bun': 0.01,
        'men_pop_smoke': 0.01,
      },
      'Men Pop Smoke': {
        'men_pop_smoke': 0.90,
        'braided_man_bun': 0.04,
        'box_braids': 0.02,
        'corn_braids': 0.01,
        'two_strand_twists': 0.01,
        'feed_in_braids': 0.01,
        'zig_zag_braids': 0.01,
        'fishtail_braids': 0.01,
        'stitch_braids': 0.01,
      },
    };
    
    // Get confidences for the selected braid type
    Map<String, double> confidences = braidConfidences[braidName] ?? braidConfidences['Box Braids']!;
    
    // Convert to the format expected by the app
    confidences.forEach((label, confidence) {
      results.add({
        'label': label,
        'confidence': confidence,
      });
    });
    
    // Sort by confidence (highest first)
    results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    
    return results;
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