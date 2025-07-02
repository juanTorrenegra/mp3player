import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MusicListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MusicListScreen extends StatefulWidget {
  const MusicListScreen({super.key});

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  List<String> musicFiles = [];
  bool loading = true;

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    requestPermissionAndListFiles();
  }

  @override
  void dispose() {
    player.dispose(); // Liberar recursos
    super.dispose();
  }

  Future<void> requestPermissionAndListFiles() async {
    // Para Android 13 o superior (API 33), pedir READ_MEDIA_AUDIO
    final audioPermission = await Permission.audio.request();

    // Para Android 12 o inferior, pedir READ_EXTERNAL_STORAGE
    final storagePermission = await Permission.storage.request();

    print("Audio permission: $audioPermission");
    print("Storage permission: $storagePermission");

    if (audioPermission.isGranted || storagePermission.isGranted) {
      listMusicFiles();
    } else {
      print("Permisos denegados.");
      setState(() {
        loading = false;
      });
    }
  }

  void listMusicFiles() async {
    const musicPath = "/storage/emulated/0/Music";
    final dir = Directory(musicPath);

    if (await dir.exists()) {
      final files = dir.listSync();
      setState(() {
        musicFiles = files
            .whereType<File>()
            .where(
              (file) =>
                  file.path.endsWith(".mp3") || file.path.endsWith(".wav"),
            )
            .map((file) => file.path.split('/').last)
            .toList();
        loading = false;
      });
    } else {
      print("Directorio no existe: $musicPath");
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Archivos en /Music")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : musicFiles.isEmpty
          ? const Center(child: Text("No se encontraron archivos de música."))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: musicFiles
                    .map(
                      (file) => ListTile(
                        title: Text(
                          file,
                          style: const TextStyle(color: Colors.blue),
                        ),
                        onTap: () async {
                          final fullPath = "/storage/emulated/0/Music/$file";
                          try {
                            await player.setFilePath(fullPath);
                            player.play();
                          } catch (e) {
                            print("Error al reproducir: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "No se pudo reproducir el archivo",
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}
