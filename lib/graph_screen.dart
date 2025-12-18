import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import shared preferences for local storage fallback
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GraphScreen extends StatefulWidget {
  final bool isDarkMode;

  const GraphScreen({super.key, required this.isDarkMode});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  List<Map<String, dynamic>> _scanHistory = [];
  bool _isLoading = true;

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
          .limitToLast(20) // Load last 20 scans
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History Graph'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scanHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
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
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confidence Over Time',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: widget.isDarkMode
                                    ? Colors.black26
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _buildConfidenceOverTimeChart(),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Braid Type Distribution',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: widget.isDarkMode
                                    ? Colors.black26
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _buildBraidDistributionChart(),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildConfidenceOverTimeChart() {
    if (_scanHistory.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < _scanHistory.length; i++) {
      final confidence = (_scanHistory[i]['confidence'] as double) * 100;
      spots.add(FlSpot(i.toDouble(), confidence));
    }

    return LineChart(
      LineChartData(
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
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _scanHistory.length) {
                  // Show scan number
                  return Text(
                    '#${_scanHistory.length - index}',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  );
                }
                return const Text('');
              },
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
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        minX: 0,
        maxX: (_scanHistory.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.purple,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBraidDistributionChart() {
    if (_scanHistory.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Count occurrences of each braid type
    Map<String, int> braidCounts = {};
    for (var scan in _scanHistory) {
      final braidType = scan['braid_type'];
      braidCounts[braidType] = (braidCounts[braidType] ?? 0) + 1;
    }

    // Convert to list for chart
    List<BarChartGroupData> barGroups = [];
    List<String> labels = [];
    int index = 0;

    braidCounts.forEach((braidType, count) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: _getColorForIndex(index),
              width: 20,
              borderRadius: BorderRadius.zero,
              rodStackItems: [],
            ),
          ],
        ),
      );

      // Format label (take first word and capitalize)
      final formattedLabel = _formatLabel(braidType);
      labels.add(formattedLabel.split(' ').first);
      index++;
    });

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
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

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
  
  String _formatLabel(String label) {
    // Remove leading numbers and spaces
    final formatted = label.replaceAll(RegExp(r'^\d+\s*'), '');
    // Replace underscores with spaces and capitalize
    return formatted.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }
}