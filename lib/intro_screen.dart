import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const IntroScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E21), // Deep navy
              const Color(0xFF240046), // Purple
              Colors.black87, // Black
            ],
          ),
        ),
        child: Stack(
          children: [
            // Hero image (placeholder for female model with braids)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/Photo/boxbraids.jpg'), // Placeholder image
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),
            
            // Content overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Floating text at top
                    const Text(
                      "Today's Best Braids",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0xFF8A2BE2), // Violet
                            blurRadius: 10,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Subtitle
                    const Text(
                      "Discover trending braid styles with AI accuracy",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Large rounded Continue button at the bottom
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8A2BE2).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.15),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}