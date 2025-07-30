import 'dart:io';
import 'package:flutter/material.dart';
import 'package:found_and_loading/globals.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';


class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({Key? key}) : super(key: key);

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File> _savedPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<String> _getPhotoDirPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/photos');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir.path;
  }

  Future<void> _loadPhotos() async {
    final path = await _getPhotoDirPath();
    final dir = Directory(path);
    final files = dir.listSync().whereType<File>().toList();
    setState(() => _savedPhotos = files);
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      final photoDir = await _getPhotoDirPath();
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.png';
      final newPath = '$photoDir/$fileName';
      final savedFile = await File(picked.path).copy(newPath);
      setState(() => _savedPhotos.add(savedFile));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('📷 Memory Vault'),
        backgroundColor: buttonColor,
        foregroundColor: buttonTextColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _takePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: backgroundColor,
              ),
              icon: const Icon(Icons.camera),
              label: const Text('Take Photo'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _savedPhotos.isEmpty
                  ? const Center(
                child: Text(
                  'No photos yet!',
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : GridView.builder(
                itemCount: _savedPhotos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final photo = _savedPhotos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(photo, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
