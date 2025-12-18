import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;
  final Function(BuildContext) onNavigateToScanner;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onNavigateToScanner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Braids Scanner'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          // Using a solid color instead of an image to avoid asset loading issues
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? Colors.purple.shade900 : Colors.purple.shade400,
              isDarkMode ? Colors.deepPurple.shade900 : Colors.deepPurple.shade300,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon
                Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  child: Icon(
                    Icons.camera_alt,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                
                // App Title
                const Text(
                  'Braids Scanner',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // App Description
                const Text(
                  'Scan and identify different braid styles with AI-powered technology',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Scan Button
                ElevatedButton(
                  onPressed: () => onNavigateToScanner(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: isDarkMode ? Colors.purpleAccent : Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 28),
                      SizedBox(width: 10),
                      Text('Start Scanning'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Features List
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Features:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureItem(Icons.auto_fix_high, 'AI-powered braid recognition'),
                      _buildFeatureItem(Icons.image, 'Scan from gallery or camera'),
                      _buildFeatureItem(Icons.bar_chart, 'Detailed accuracy analysis'),
                      _buildFeatureItem(Icons.history, 'Scan history tracking'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}