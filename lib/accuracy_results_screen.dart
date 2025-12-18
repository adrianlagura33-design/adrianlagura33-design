import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
// Import shared preferences for local storage fallback
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccuracyResultsScreen extends StatefulWidget {
  final bool isDarkMode;

  const AccuracyResultsScreen({super.key, required this.isDarkMode});

  @override
  State<AccuracyResultsScreen> createState() => _AccuracyResultsScreenState();
}

class _AccuracyResultsScreenState extends State<AccuracyResultsScreen> {
  List<Map<String, dynamic>> _scanHistory = [];
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to load from Firebase first
        await _loadFromFirebase(user.uid);
      } else {
        // Fallback to local storage
        await _loadFromLocal();
      }
    } catch (e) {
      debugPrint("Error loading scan history: $e");
      // Fallback to local storage if Firebase fails
      await _loadFromLocal();
    }
  }

  Future<void> _loadFromFirebase(String userId) async {
    try {
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      final snapshot = await dbRef
          .child('users')
          .child(userId)
          .child('scans')
          .orderByChild('timestamp')
          .limitToLast(50) // Load last 50 scans for better analytics
          .get();

      if (snapshot.exists) {
        List<Map<String, dynamic>> scans = [];
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          scans.add({
            'id': key,
            'braid_type': value['braid_type'],
            'confidence': value['confidence'].toDouble(), // Ensure it's double
            'timestamp': value['timestamp'],
          });
        });

        // Sort by timestamp descending (newest first)
        scans.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        setState(() {
          _scanHistory = scans;
          _analyticsData = _calculateAnalytics(scans);
          _isLoading = false;
        });
      } else {
        // If no data in Firebase, try local storage
        await _loadFromLocal();
      }
    } catch (e) {
      debugPrint("Error loading from Firebase: $e");
      // Fallback to local storage if Firebase fails
      await _loadFromLocal();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? scanHistoryStrings = prefs.getStringList('scan_history');
      
      if (scanHistoryStrings != null && scanHistoryStrings.isNotEmpty) {
        List<Map<String, dynamic>> scans = [];
        for (String scanString in scanHistoryStrings) {
          try {
            Map<String, dynamic> scan = jsonDecode(scanString);
            // Ensure confidence is stored as double
            scan['confidence'] = (scan['confidence'] as num).toDouble();
            scans.add(scan);
          } catch (e) {
            debugPrint("Error decoding scan entry: $e");
          }
        }

        // Sort by timestamp descending (newest first)
        scans.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        setState(() {
          _scanHistory = scans;
          _analyticsData = _calculateAnalytics(scans);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading from local storage: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateAnalytics(List<Map<String, dynamic>> scans) {
    if (scans.isEmpty) {
      return {
        'totalScans': 0,
        'avgConfidence': 0.0,
        'mostScanned': 'None',
        'highestConfidence': 0.0,
        'lowestConfidence': 1.0,
      };
    }

    // Calculate total scans
    int totalScans = scans.length;

    // Calculate average confidence
    double totalConfidence = 0;
    double highestConfidence = 0;
    double lowestConfidence = 1.0;

    // Count braid types
    Map<String, int> braidCounts = {};

    for (var scan in scans) {
      final confidence = scan['confidence'] as double;
      totalConfidence += confidence;
      
      if (confidence > highestConfidence) {
        highestConfidence = confidence;
      }
      
      if (confidence < lowestConfidence) {
        lowestConfidence = confidence;
      }

      final braidType = scan['braid_type'];
      braidCounts[braidType] = (braidCounts[braidType] ?? 0) + 1;
    }

    double avgConfidence = totalConfidence / totalScans;

    // Find most scanned braid type
    String mostScanned = 'None';
    int maxCount = 0;
    braidCounts.forEach((braidType, count) {
      if (count > maxCount) {
        maxCount = count;
        mostScanned = braidType;
      }
    });

    // Format braid type name
    mostScanned = _formatLabel(mostScanned);

    return {
      'totalScans': totalScans,
      'avgConfidence': avgConfidence,
      'mostScanned': mostScanned,
      'highestConfidence': highestConfidence,
      'lowestConfidence': lowestConfidence,
    };
  }

  String _formatLabel(String label) {
    // Remove leading numbers and spaces
    final formatted = label.replaceAll(RegExp(r'^\d+\s*'), '');
    // Replace underscores with spaces and capitalize
    return formatted.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accuracy Results'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analytics Summary Cards
                    _buildAnalyticsSummary(),
                    const SizedBox(height: 30),
                    
                    // Recent Scans
                    Text(
                      'Recent Scans',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRecentScansList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.purple.withOpacity(0.3) : Colors.purple.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                ),
                const SizedBox(width: 10),
                Text(
                  "Scan Analytics",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildAnalyticsCard(
                  icon: Icons.check_circle,
                  title: "Total Scans",
                  value: _analyticsData['totalScans'].toString(),
                  color: Colors.blue,
                ),
                const SizedBox(height: 15),
                _buildAnalyticsCard(
                  icon: Icons.speed,
                  title: "Avg Confidence",
                  value: "${(_analyticsData['avgConfidence'] * 100).toStringAsFixed(1)}%",
                  color: Colors.green,
                ),
                const SizedBox(height: 15),
                _buildAnalyticsCard(
                  icon: Icons.star,
                  title: "Highest Confidence",
                  value: "${(_analyticsData['highestConfidence'] * 100).toStringAsFixed(1)}%",
                  color: Colors.orange,
                ),
                const SizedBox(height: 15),
                _buildAnalyticsCard(
                  icon: Icons.trending_down,
                  title: "Lowest Confidence",
                  value: "${(_analyticsData['lowestConfidence'] * 100).toStringAsFixed(1)}%",
                  color: Colors.red,
                ),
                const SizedBox(height: 15),
                _buildAnalyticsCard(
                  icon: Icons.favorite,
                  title: "Most Scanned",
                  value: _analyticsData['mostScanned'],
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScansList() {
    if (_scanHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No scan history available',
              style: TextStyle(
                fontSize: 18,
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Perform some scans to see your history',
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.purple.withOpacity(0.3) : Colors.purple.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                ),
                const SizedBox(width: 10),
                Text(
                  "Scan History (${_scanHistory.length})",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _scanHistory.length,
            itemBuilder: (context, index) {
              final scan = _scanHistory[index];
              final confidence = (scan['confidence'] as double) * 100;
              final braidType = _formatLabel(scan['braid_type']);
              final timestamp = DateTime.fromMillisecondsSinceEpoch(scan['timestamp']);

              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          braidType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          "${confidence.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getConfidenceColor(confidence),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearPercentIndicator(
                      lineHeight: 10.0,
                      percent: confidence / 100,
                      barRadius: const Radius.circular(5),
                      progressColor: _getConfidenceColor(confidence),
                      backgroundColor: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "#${_scanHistory.length - index}",
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          "${timestamp.day}/${timestamp.month}/${timestamp.year}",
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) {
      return Colors.green;
    } else if (confidence >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}