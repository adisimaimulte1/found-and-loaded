import 'package:flutter/material.dart';
import 'package:found_and_loading/globals.dart';
import 'package:found_and_loading/widgets/background_music.dart';
import 'battle_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  double _volume = 0.1;

  @override
  void initState() {
    super.initState();
    _initMusic();
  }

  Future<void> _initMusic() async {
    await BackgroundMusic.init(volume: _volume);
    await BackgroundMusic.play();
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SizedBox(
          width: screenSize.width * 0.85,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', scale: 1.2),
              const SizedBox(height: 40),
              _StyledButton(
                icon: Icons.play_arrow,
                label: 'Start',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BattleScreen()),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Volume',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accentColor,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: accentColor,
                  overlayColor: accentColor.withOpacity(0.2),
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _volume,
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    setState(() => _volume = value);
                    BackgroundMusic.setVolume(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _StyledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _StyledButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: backgroundColor,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}

