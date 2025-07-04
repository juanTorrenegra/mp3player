import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

import "package:mp3player/app_themes.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF00FFCC),
        secondaryHeaderColor: Color(0xFF4444FF),
        fontFamily: 'Orbitron',

        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Orbitron'),
          bodyMedium: TextStyle(fontFamily: 'Orbitron'),
        ),
      ),
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

  String? currentlyPlaying;
  bool isPlaying = false;

  bool isRandomMode = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    requestPermissionAndListFiles();

    player.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
      });

      // Si terminó la canción y estamos en modo aleatorio
      if (state.processingState == ProcessingState.completed && isRandomMode) {
        playRandomSong();
      }
    });
  }

  void playRandomSong() {
    if (musicFiles.isEmpty) return;

    final randomIndex = _random.nextInt(musicFiles.length);
    final randomPath = musicFiles[randomIndex];
    playMusic(randomPath);
  }

  void startRandomMode() {
    isRandomMode = true;
    playRandomSong();
  }

  Future<void> requestPermissionAndListFiles() async {
    var status = await Permission.audio.request();
    if (status.isGranted) {
      listMusicFiles();
    } else {
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
      final mp3Files = files
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.mp3'))
          .map((file) => file.path)
          .toList();

      print("Archivos encontrados: ${mp3Files.length}");

      setState(() {
        musicFiles = mp3Files;
        loading = false;
      });
    } else {
      print("Directorio no existe");
      setState(() {
        loading = false;
      });
    }
  }

  void playMusic(String path) async {
    try {
      await player.setFilePath(path);
      await player.play();

      // Esperamos a que el audio realmente esté en estado playing
      player.playerStateStream.firstWhere((state) => state.playing).then((_) {
        setState(() {
          currentlyPlaying = path.split('/').last;
        });
      });
    } catch (e) {
      print("Error al reproducir el archivo: $e");
    }
  }

  void pauseMusic() async {
    isRandomMode = false;
    await player.pause();
    setState(() {
      isPlaying = false;
    });
  }

  void resumeMusic() async {
    await player.play();
    setState(() {
      isPlaying = true;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Archivos en /Music")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentlyPlaying != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "$currentlyPlaying",
                      style: TextStyle(
                        //fontFamily: 'Orbitron',
                        fontSize: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                if (currentlyPlaying != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: isPlaying ? pauseMusic : null,
                        child: const Text("Pausar"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: !isPlaying && currentlyPlaying != null
                            ? resumeMusic
                            : null,
                        child: const Text("Reanudar"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: startRandomMode,
                        child: const Text("Random"),
                      ),
                    ],
                  ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: musicFiles
                        .map(
                          (path) => ListTile(
                            title: Text(
                              path.split('/').last,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            onTap: () {
                              playMusic(path);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
