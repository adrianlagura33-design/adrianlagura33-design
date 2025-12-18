import 'package:flutter/material.dart';

class StyleDetailsScreen extends StatelessWidget {
  final String braidStyle;
  final String description;
  final String imagePath;
  final VoidCallback onSaveStyle;
  final VoidCallback onTryAnotherScan;

  const StyleDetailsScreen({
    super.key,
    required this.braidStyle,
    required this.description,
    required this.imagePath,
    required this.onSaveStyle,
    required this.onTryAnotherScan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // Deep navy
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Large circular preview image of the braid style
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular container for the image
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00FFFF), // Cyan
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.black26,
                            child: const Icon(
                              Icons.style,
                              size: 100,
                              color: Colors.white38,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Play button overlay (used as "View Style")
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8A2BE2), // Violet
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Title
            Text(
              "Selected Braid Style",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color(0xFF8A2BE2).withOpacity(0.7),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Braid style name
            Text(
              braidStyle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Description text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Switch perspective buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPerspectiveButton("Front View", true),
                  _buildPerspectiveButton("Side View", false),
                  _buildPerspectiveButton("Back View", false),
                ],
              ),
            ),

            const Spacer(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSaveStyle,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: const Color(0xFF00BFFF), // Electric blue
                        elevation: 5,
                        shadowColor: const Color(0xFF00BFFF).withOpacity(0.5),
                      ),
                      child: const Text(
                        "Save Style",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onTryAnotherScan,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: const BorderSide(
                          color: Color(0xFF8A2BE2), // Violet
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        "Try Another Scan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8A2BE2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerspectiveButton(String label, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF00FFFF) : Colors.white24,
          width: 2,
        ),
        color: isActive ? const Color(0xFF00FFFF).withOpacity(0.2) : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF00FFFF) : Colors.white70,
          ),
        ),
      ),
    );
  }
}