import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:found_and_loading/entities/bullet.dart';
import 'package:found_and_loading/entities/enemy_spawner.dart';
import 'package:found_and_loading/globals.dart';
import 'package:found_and_loading/player/player.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class BattleScreen extends StatefulWidget {
  const BattleScreen({Key? key}) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late ARSessionManager _arSessionManager;
  late ARObjectManager _arObjectManager;


  @override
  void dispose() {
    _arSessionManager.dispose();
    playerGame?.onRemove();
    super.dispose();
  }


  int currentWave = -1;
  final int totalWaves = 5;
  final int enemiesPerWave = 1;
  bool isReady = false;

  bool isTilting = false;
  DateTime lastShot = DateTime.now();
  final Duration cooldown = Duration(milliseconds: 500);

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

          if (isReady)
            IgnorePointer(
              ignoring: false,
              child: GameWidget(
                game: playerGame!,
                backgroundBuilder: (context) => const SizedBox.shrink(),
              ),
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
      )

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
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
      handleTaps: true,
    );

    enemySpawner ??= EnemySpawner(_arSessionManager, _arObjectManager);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _waitForCameraPoseThenSpawn();
      }
    });
  }

  Future<void> _waitForCameraPoseThenSpawn() async {
    for (int i = 0; i < 20; i++) {
      final camPos = await _arSessionManager.getCameraPose();
      if (camPos != null && mounted) {

        // Calibration successful ✅
        setState(() {
          isReady = true;
          playerGame = PlayerGame(shootCallback: spawnBulletFromCamera);
        });

        enemySpawner!.startEnemyLoop(onUpdate: () { setState(() {}); });
        _spawnNextWave(camPos);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _spawnNextWave(vector.Matrix4 camPos) async {
    if (currentWave >= totalWaves) return;

    enemySpawner?.spawnWave(
      count: enemiesPerWave,
      uri: "https://github.com/adisimaimulte1/found-and-loaded/raw/refs/heads/main/assets/Ghost.glb",
      camPose: camPos,
    );
    setState(() => currentWave++);
  }

  void spawnBulletFromCamera() async {
    final pose = await _arSessionManager.getCameraPose();
    if (pose == null || !mounted) return;

    final direction = getCameraForward(pose);
    final position = pose.getTranslation();

    final velocity = Vector2(direction.x, direction.z) * 600; // pixels per second

    debugPrint('velocity: $velocity');
    playerGame!.add(
      Bullet(
        velocity: Vector2(0, -300), // shoots upward for testing
      )..position = Vector2(200, 600),
    );

  }

  vector.Vector3 getCameraForward(vector.Matrix4 pose) {
    final forward = vector.Vector3(0, 0, -1);
    final transformed = pose.transform3(forward);
    final position = pose.getTranslation();
    return (transformed - position).normalized();
  }

}
