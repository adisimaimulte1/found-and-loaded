import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class EnemySpawner {
  int spawnIndex = 0;
  int total;

  final ARSessionManager arSessionManager;
  final ARObjectManager objectManager;

  void Function()? onJumpscare;
  final Map<String, ARNode> spawnedEnemies = {};
  final Map<String, vector.Vector3> spawnedEnemiesPos = {};

  Timer? _updateTimer;

  final double minDistance = 5;
  final double varDistance = 2;
  final Duration spawnDelay = const Duration(milliseconds: 800);

  int index = 0;



  EnemySpawner(this.arSessionManager, this.objectManager, this.total);



  void startEnemyLoop(
      {required VoidCallback onUpdate,
      Duration interval = const Duration(milliseconds: 32)}) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (_) => _updateEnemies(onUpdate));
  }

  void stopEnemyLoop() => _updateTimer?.cancel();

  var updateOnce = true;

  Future<void> _updateEnemies(VoidCallback onUpdate) async {
    final camTransform = await arSessionManager.getCameraPose();
    if (camTransform == null) return;


    for (final entry in spawnedEnemies.entries) {
      final id = entry.key;
      final node = entry.value;

      final lastRotation = await objectManager.getRotation(node);
      final lastPosition = await objectManager.getPosition(node);
      final playerPosition = _getCameraPosition(camTransform);

      final movementVector = computeMovementVector(playerPosition, lastPosition, 1, 0.016);

      objectManager.updateTranslation(node, movementVector.x, 0, movementVector.z);
      objectManager.updateRotation(node, 0, rotateToPlayer(playerPosition, lastPosition), 0);

      final dist = (playerPosition - lastPosition).length;
      if (dist <= 0.57) {
        _triggerJumpscare(id);
      }
    }

  }

  Future<String?> spawnEnemy({
    required String uri,
    required vector.Matrix4? camPose,
    vector.Vector3? scale,
  }) async {
    final position = _generateNonOverlappingPosition(camPose);
    final id = "enemy_$index";
    index++;

    final node = ARNode(
      name: id,
      type: NodeType.webGLB,
      uri: uri,
      scale: scale ?? vector.Vector3.all(0.35),
      position: position,
    );

    final added = await objectManager.addNode(node);
    objectManager.updateTranslation(node, position.x, 0, position.y);

    if (added == true) {
      spawnedEnemies[id] = node;
      spawnedEnemiesPos[id] = position;
      return id;
    }

    print("❌ Failed to add enemy: $id");
    return null;
  }

  void spawnWave({
    required int count,
    required String uri,
    required vector.Matrix4? camPose,
    vector.Vector3? scale,
  }) {
    for (int i = 0; i < count; i++) {
      Future.delayed(spawnDelay * i, () {
        spawnEnemy(uri: uri, camPose: camPose, scale: scale);
      });
    }
  }



  Future<void> clearAll() async {
    for (final node in spawnedEnemies.values) {
      await objectManager.removeNode(node);
    }
    spawnedEnemies.clear();
    spawnedEnemiesPos.clear();
  }



  void _triggerJumpscare(String id) async {
    final node = spawnedEnemies[id];
    if (node == null) return;

    // Remove the ghost instantly
    spawnedEnemies.remove(id);
    spawnedEnemiesPos.remove(id);
    await objectManager.removeNode(node);

    final player = AudioPlayer();
    player.play(AssetSource('music/asta_e_suficient_ca_sa_nu_te_scapi_pe_tine.mp3'));

    onJumpscare?.call();

  }





  vector.Vector3 _getCameraPosition(vector.Matrix4? transform) {
    if (transform == null) return vector.Vector3.zero();
    return vector.Vector3(
      transform.getColumn(3).x,
      transform.getColumn(3).y,
      transform.getColumn(3).z,
    );
  }

  vector.Vector3 computeMovementVector(
      vector.Vector3 playerPosition,
      vector.Vector3 enemyPosition,
      double speed,
      double dt, {
        double stopRadius = 0.7,
      }) {
    final dir = vector.Vector3(
      playerPosition.x - enemyPosition.x,
      0,
      playerPosition.z - enemyPosition.z,
    );

    final distance = dir.length;
    if (distance < 1e-6) return vector.Vector3.zero();

    dir.normalize();

    if (distance > stopRadius - 0.1 && distance < stopRadius) {
      return vector.Vector3.zero();
    } else if (distance < stopRadius - 0.1) {
      return -dir * (speed * dt);
    }

    return dir * (speed * dt);
  }

  vector.Vector3 _generateNonOverlappingPosition(vector.Matrix4? camTransform) {
    if (camTransform == null) return vector.Vector3.zero();

    final camPos = _getCameraPosition(camTransform);
    final radius = minDistance + varDistance * 0.5; // fixed radius

    final angle = (2 * pi / total) * spawnIndex;
    spawnIndex++;

    final dx = cos(angle) * radius;
    final dz = sin(angle) * radius;

    return vector.Vector3(camPos.x + dx, 0, camPos.z + dz);
  }



  double rotateToPlayer(vector.Vector3 playerPosition, vector.Vector3 enemyPosition) {
    final dx = playerPosition.x - enemyPosition.x;
    final dz = playerPosition.z - enemyPosition.z;
    double angle = -atan2(dz, dx) * 180 / pi;

    if (angle.abs() < 0.01) {
      angle = 0;
    }

    return angle;
  }

}
