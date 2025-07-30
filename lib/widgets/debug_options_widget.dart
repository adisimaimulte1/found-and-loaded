import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:found_and_loading/entities/enemy_spawner.dart';
import 'package:found_and_loading/globals.dart';

class DebugOptionsWidget extends StatefulWidget {
  const DebugOptionsWidget({Key? key}) : super(key: key);

  @override
  State<DebugOptionsWidget> createState() => _DebugOptionsWidgetState();
}

class _DebugOptionsWidgetState extends State<DebugOptionsWidget> {
  late ARSessionManager _arSessionManager;
  late ARObjectManager _arObjectManager;

  int currentWave = 0;
  final int totalWaves = 5;
  final int enemiesPerWave = 1;
  bool isReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: accentColor,
        elevation: 0,
        title: const Text(
          'Back',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 22,
            color: accentColor,
          ),
        ),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (isReady && currentWave < totalWaves)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _waitForCameraPoseThenSpawn,
                  child: Text('Spawn Wave ${currentWave + 1} / $totalWaves'),
                ),
              ),
            ),
        ],
      ),
    );
  }



  void _onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager,
      ) {
    _arSessionManager = sessionManager;
    _arObjectManager = objectManager;

    _arSessionManager.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    enemySpawner ??= EnemySpawner(_arSessionManager, _arObjectManager);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isReady = true);
        _waitForCameraPoseThenSpawn();
      }
    });
  }

  Future<void> _waitForCameraPoseThenSpawn() async {
    for (int i = 0; i < 20; i++) {
      final camPos = await _arSessionManager.getCameraPose();
      if (camPos != null && mounted) {

        debugPrint("✅ Camera pose received.");
        setState(() => isReady = true);

        enemySpawner!.startEnemyLoop();
        _spawnNextWave(camPos);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    debugPrint("❌ Still no camera pose after waiting.");
  }

  void _spawnNextWave(Matrix4 camPos) async {
    if (currentWave >= totalWaves) return;

    enemySpawner?.spawnWave(
      count: enemiesPerWave,
      uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/refs/heads/main/2.0/Box/glTF-Binary/Box.glb",
      camPose: camPos,
    );

    setState(() => currentWave++);
  }
}
