import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class BackgroundMusic {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isInitialized = false;

  static Future<void> init({double volume = 0.5}) async {
    if (_isInitialized) return;

    final ByteData data = await rootBundle.load('assets/music/halloween.mp3');
    final Uint8List bytes = data.buffer.asUint8List();

    await _player.setSourceBytes(bytes);
    await _player.setReleaseMode(ReleaseMode.loop); // Infinite loop
    await _player.setVolume(volume);

    _isInitialized = true;
  }

  static Future<void> play({Duration? startPosition}) async {
    if (startPosition != null) {
      await _player.seek(startPosition);
    }
    await _player.resume();
  }

  static Future<void> stop() async {
    await _player.stop();
  }

  static Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  static Future<void> dispose() async {
    await _player.dispose();
    _isInitialized = false;
  }
}
