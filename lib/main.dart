import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'intro_screen.dart';
import 'braid_scanner_home.dart';
import 'style_details_screen.dart';
import 'graph_screen.dart';
import 'accuracy_results_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Track current screen
  int _currentScreen = 0; // 0: Intro, 1: Scanner, 2: Style Details
  bool _isDarkMode = false;

  // Method to toggle dark mode
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    // Print a message
    print(_isDarkMode ? "Dark mode enabled" : "Light mode enabled");
  }

  // Method to navigate to scanner screen
  void _navigateToScanner() {
    setState(() {
      _currentScreen = 1;
    });
  }

  // Method to navigate to intro screen
  void _navigateToIntro() {
    setState(() {
      _currentScreen = 0;
    });
  }

  // Method to navigate to style details screen
  void _navigateToStyleDetails() {
    setState(() {
      _currentScreen = 2;
    });
  }

  // Method to navigate to graph screen
  void _navigateToGraph() {
    // For now, we'll just print a message
    print("Graph view would be shown here");
  }

  // Method to navigate to accuracy results screen
  void _navigateToAccuracyResults() {
    // For now, we'll just print a message
    print("Accuracy results would be shown here");
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 0:
        return IntroScreen(
          onContinue: _navigateToScanner,
        );
      case 1:
        return BraidScannerHome(
          isDarkMode: _isDarkMode,
          toggleDarkMode: _toggleDarkMode,
        );
      case 2:
        return StyleDetailsScreen(
          braidStyle: "Box Braids",
          description: "Classic box braids style with precision parting and uniform sizing.",
          imagePath: "assets/Photo/boxbraids.jpg",
          onSaveStyle: () {},
          onTryAnotherScan: _navigateToScanner,
        );
      default:
        return IntroScreen(
          onContinue: _navigateToScanner,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braids Scanner',
      // Set the theme based on _isDarkMode
      theme: ThemeData.dark(),
      home: _buildCurrentScreen(),
    );
  }
}