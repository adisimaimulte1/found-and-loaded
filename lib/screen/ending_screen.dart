import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:found_and_loading/globals.dart';
import 'start_screen.dart';

class EndingScreen extends StatelessWidget {
  const EndingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_rounded, size: 96, color: accentColor),
                const SizedBox(height: 20),
                const Text(
                  'All Ghosts Defeated!',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You Survived.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back, color: backgroundColor),
                  label: const Text(
                    'Return to Menu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: backgroundColor,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const StartScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
