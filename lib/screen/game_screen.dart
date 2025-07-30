import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:found_and_loading/entities/enemy_spawner.dart';
import 'package:found_and_loading/globals.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ARSessionManager _arSessionManager;
  late ARObjectManager _arObjectManager;

  final ImagePicker _picker = ImagePicker();
  List<File> _savedPhotos = [];
  int _currentRound = 1;
  bool _hasTakenPhoto = false;
  bool _arReady = false;
  bool _waitingCameraPose = false;

  static const int totalRounds = 3;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final dir = await _getPhotoDirPath();
    final files = Directory(dir).listSync().whereType<File>().toList();
    setState(() => _savedPhotos = files);
  }

  Future<String> _getPhotoDirPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/photos');
    if (!await photoDir.exists()) await photoDir.create(recursive: true);
    return photoDir.path;
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      final dir = await _getPhotoDirPath();
      final file = await File(picked.path)
          .copy('$dir/round_$_currentRound${DateTime.now().millisecondsSinceEpoch}.png');
      setState(() {
        _savedPhotos.add(file);
        _hasTakenPhoto = true;
      });
    }
  }

  Future<void> _startEnemyWave() async {
    if (_waitingCameraPose || !_hasTakenPhoto) return;
    _waitingCameraPose = true;

    for (int i = 0; i < 20; i++) {
      final camPos = await _arSessionManager.getCameraPose();
      if (camPos != null && mounted) {
        setState(() => _arReady = true);

        enemySpawner?.spawnWave(
          count: _currentRound,
          uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/refs/heads/main/2.0/Box/glTF-Binary/Box.glb",
          camPose: camPos,
        );

        enemySpawner?.startEnemyLoop(onUpdate: () {
          setState(() {});
        });

        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _waitingCameraPose = false;
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
      showPlanes: true,
      showFeaturePoints: false,
      handlePans: true,
      handleTaps: true,
    );

    enemySpawner ??= EnemySpawner(_arSessionManager, _arObjectManager);
  }

  void _nextRound() {
    setState(() {
      _currentRound++;
      _hasTakenPhoto = false;
      _arReady = false;
    });

    if (_currentRound > totalRounds) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Round $_currentRound'),
        backgroundColor: buttonColor,
        foregroundColor: buttonTextColor,
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_hasTakenPhoto)
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: backgroundColor,
                      ),
                    )
                  else if (!_arReady)
                    ElevatedButton.icon(
                      onPressed: _startEnemyWave,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Start Enemy Wave'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: backgroundColor,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _nextRound,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        _currentRound == totalRounds ? 'Finish' : 'Next Round',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: backgroundColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
