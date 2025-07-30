import 'dart:async';
import 'dart:math';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class EnemySpawner {
  final ARSessionManager arSessionManager;
  final ARObjectManager objectManager;

  final Map<String, ARNode> spawnedEnemies = {};
  final Map<String, vector.Vector3> spawnedEnemiesPos = {};

  Timer? _updateTimer;

  final double minDistance = 12;
  final double varDistance = 2;
  final Duration spawnDelay = const Duration(milliseconds: 800);

  int index = 0;

  EnemySpawner(this.arSessionManager, this.objectManager);

  void startEnemyLoop({Duration interval = const Duration(milliseconds: 50)}) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (_) => _updateEnemies());
  }

  void stopEnemyLoop() => _updateTimer?.cancel();



  vector.Vector3 _getCameraPosition(vector.Matrix4? transform) {
    if (transform == null) return vector.Vector3.zero();
    return vector.Vector3(
      transform.getColumn(3).x,
      transform.getColumn(3).y,
      transform.getColumn(3).z,
    );
  }

  Future<void> _updateEnemies() async {
    final camTransform = await arSessionManager.getCameraPose();
    if (camTransform == null) return;

    final camPos = _getCameraPosition(camTransform);

    for (final entry in spawnedEnemies.entries) {
      final id = entry.key;
      final node = entry.value;
      final currentPos = spawnedEnemiesPos[id];

      if (currentPos == null) continue;

      // Move slightly toward the player
      final direction = (camPos - currentPos).normalized();
      final newPos = currentPos + direction * 0.01;

      // Update the node position
      await objectManager.removeNode(node);

      final updatedNode = ARNode(
        name: id,
        type: node.type,
        uri: node.uri,
        scale: node.scale,
        position: newPos,
      );

      final added = await objectManager.addNode(updatedNode);
      if (added == true) {
        spawnedEnemies[id] = updatedNode;
        spawnedEnemiesPos[id] = newPos;
      } else {
        print("❌ Failed to update node: $id");
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
      scale: scale ?? vector.Vector3.all(0.2),
      position: position,
    );

    final added = await objectManager.addNode(node);
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

  vector.Vector3 _generateNonOverlappingPosition(vector.Matrix4? camTransform) {
    if (camTransform == null) return vector.Vector3.zero();

    final camPos = _getCameraPosition(camTransform);
    final rng = Random();
    const maxTries = 50;

    for (int i = 0; i < maxTries; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final radius = minDistance + rng.nextDouble() * varDistance;

      final dx = cos(angle) * radius;
      final dz = sin(angle) * radius;
      final pos = vector.Vector3(camPos.x + dx, 0, camPos.z + dz);

      final tooClose = spawnedEnemiesPos.values.any((existing) {
        return (existing - pos).length < 2.0;
      });

      if (!tooClose) return pos;
    }

    print("⚠️ Fallback spawn position used.");
    return vector.Vector3(camPos.x + minDistance, 0, camPos.z);
  }
}
