import 'dart:async';

import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:found_and_loading/entities/enemy_spawner.dart';
import 'package:found_and_loading/globals.dart';
import 'package:found_and_loading/player/player.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'ending_screen.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({Key? key}) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late ARSessionManager _arSessionManager;
  late ARObjectManager _arObjectManager;

  OverlayEntry? _jumpscareOverlay;




  void _showJumpscareOverlay() {
    debugPrint("😱 Jumpscare triggered!");
    _jumpscareOverlay?.remove();
    _jumpscareOverlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Container(
          color: backgroundColor,
          child: Center(
            child: Image.asset(
              'assets/enemies/ghost/ghost_2.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_jumpscareOverlay!);

    Future.delayed(const Duration(milliseconds: 800), () async {
      _jumpscareOverlay?.remove();
      _jumpscareOverlay = null;

      if (enemySpawner!.spawnedEnemies.isEmpty) {
        if (currentWave < totalWaves) {
          final nextCamPose = await _arSessionManager.getCameraPose();
          if (nextCamPose != null) {
            _spawnNextWave(nextCamPose);
          }
        } else {
          // All waves complete – go to ending screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EndingScreen()),
            );
          }
        }
      }
    });
  }


  @override
  void dispose() {
    _arSessionManager.dispose();
    playerGame?.onRemove();
    super.dispose();
  }


  int currentWave = 0;
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

          if (isReady)
            Center(
              child: IgnorePointer(
                child: Text(
                  '✖',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),


          if (isReady && currentWave <= totalWaves)
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // sharper corners
                    ),
                  ),
                  onPressed: () {}, // disables the button
                  child: Text('Wave $currentWave / $totalWaves'),
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

    enemySpawner ??= EnemySpawner(_arSessionManager, _arObjectManager, 2);
    enemySpawner?.onJumpscare = _showJumpscareOverlay;

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
          playerGame = PlayerGame(shootCallback: spawnBulletFromGun);
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

      enemySpawner?.total = (currentWave + 1) * 2;
      enemySpawner?.spawnIndex = 0;
      enemySpawner?.spawnWave(
        count: (currentWave + 1) * 2,
        uri: "https://github.com/adisimaimulte1/found-and-loaded/raw/refs/heads/main/assets/Ghost.glb",
        camPose: camPos,
      );
      setState(() => currentWave++);
  }

  Future<void> spawnBulletFromGun(Vector2 screenPosition) async {
    final pose = await _arSessionManager.getCameraPose();
    if (pose == null || !mounted) return;

    // Simulate hit delay based on distance
    final camPose = await _arSessionManager.getCameraPose();
    if (camPose == null) return;

    final camPos = camPose.getTranslation();
    final camForward = getCameraForward(camPose);

    String? hitEnemyId;
    double hitDistance = double.infinity;

    for (final entry in enemySpawner!.spawnedEnemies.entries) {
      final node = entry.value;
      final enemyPos = node.position;
      final toEnemy = enemyPos - camPos;

      final angle = vector.degrees(camForward.angleTo(toEnemy.normalized()));
      final dist = toEnemy.length;

      if (angle < 3 && dist < 20 && dist < hitDistance) {
        hitEnemyId = entry.key;
        hitDistance = dist;
      }
    }

    if (hitEnemyId != null) {
      final hitNode = enemySpawner!.spawnedEnemies[hitEnemyId]!;
      final delay = Duration(milliseconds: (hitDistance * 24).toInt());

      Future.delayed(delay, () async {
        final direction = (hitNode.position - camPos).normalized();
        final pushDistance = 0.5; // meters
        final offset = direction * pushDistance;

        final success = await _arObjectManager.updateTranslation(
          hitNode,
          offset.x,
          0,        // Optional: ignore Y for horizontal push
          offset.z,
        );

        if (success != false) {
          await _arObjectManager.removeNode(hitNode);
          enemySpawner!.spawnedEnemies.remove(hitEnemyId);
          enemySpawner!.spawnedEnemiesPos.remove(hitEnemyId);
          debugPrint("💥 Enemy $hitEnemyId pushed back and destroyed.");


          if (enemySpawner!.spawnedEnemies.isEmpty) {
            if (currentWave < totalWaves) {
              final nextCamPose = await _arSessionManager.getCameraPose();
              if (nextCamPose != null) {
                _spawnNextWave(nextCamPose);
              }
            } else {
              // All waves complete – go to ending screen
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EndingScreen()),
                );
              }
            }
          }

        }
      });

    }


  }







  vector.Vector3 getCameraForward(vector.Matrix4 pose) {
    final forward = vector.Vector3(0, 0, -1);
    final transformed = pose.transform3(forward);
    final position = pose.getTranslation();
    return (transformed - position).normalized();
  }

  vector.Quaternion eulerToQuaternion(double x, double y, double z) {
    final euler = vector.Vector3(x, y, z);
    return vector.Quaternion.euler(euler.x, euler.y, euler.z);
  }



  Future<void> checkCrosshairHit() async {
    final camPose = await _arSessionManager.getCameraPose();
    if (camPose == null) return;

    final camPos = camPose.getTranslation();
    final camForward = getCameraForward(camPose);

    for (final entry in enemySpawner!.spawnedEnemies.entries) {
      final node = entry.value;
      final enemyPos = node.position;

      // Vector from camera to enemy
      final toEnemy = (enemyPos - camPos);
      final distance = toEnemy.length;
      final angle = vector.degrees(camForward.angleTo(toEnemy.normalized()));

      // Check if enemy is in the center crosshair (within ~3° cone)
      if (angle < 3 && distance < 20) {
        debugPrint("🔥 Enemy ${entry.key} HIT at distance ${distance.toStringAsFixed(2)}");

        // Remove enemy
        await _arObjectManager.removeNode(node);
        enemySpawner!.spawnedEnemies.remove(entry.key);
        enemySpawner!.spawnedEnemiesPos.remove(entry.key);

        break; // Only hit one per tap
      }
    }
  }



}
