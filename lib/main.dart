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
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Juanelo's Music",
          style: TextStyle(fontFamily: "cursive"),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).secondaryHeaderColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currentlyPlaying != null
                            ? currentlyPlaying!
                            : 'No hay canción en reproducción',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PixelBoom',
                          fontSize: 22,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: isPlaying ? pauseMusic : null,
                            style:
                                ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(24),
                                  backgroundColor: Colors.black,
                                  shadowColor: Colors.cyanAccent,
                                  elevation: 12,
                                ).copyWith(
                                  overlayColor: MaterialStateProperty.all(
                                    Colors.cyan.withOpacity(0.2),
                                  ),
                                ),
                            child: const Icon(
                              Icons.pause,
                              size: 36,
                              color: Colors.cyanAccent,
                              shadows: [
                                Shadow(
                                  color: Colors.cyan,
                                  blurRadius: 10,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: !isPlaying && currentlyPlaying != null
                                ? resumeMusic
                                : null,
                            style:
                                ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(24),
                                  backgroundColor: Colors.black,
                                  shadowColor: Colors.greenAccent,
                                  elevation: 12,
                                ).copyWith(
                                  overlayColor: MaterialStateProperty.all(
                                    Colors.green.withOpacity(0.2),
                                  ),
                                ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 36,
                              color: Colors.greenAccent,
                              shadows: [
                                Shadow(
                                  color: Colors.green,
                                  blurRadius: 10,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: startRandomMode,
                            style:
                                ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(24),
                                  backgroundColor: Colors.black,
                                  shadowColor: Colors.purpleAccent,
                                  elevation: 12,
                                ).copyWith(
                                  overlayColor: MaterialStateProperty.all(
                                    Colors.purple.withOpacity(0.2),
                                  ),
                                ),
                            child: const Icon(
                              Icons.shuffle,
                              size: 36,
                              color: Colors.purpleAccent,
                              shadows: [
                                Shadow(
                                  color: Colors.purple,
                                  blurRadius: 10,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: musicFiles.map((path) {
                      final fileName = path.split('/').last;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0A0F1C,
                          ), // fondo oscuro tipo sci-fi
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.cyanAccent, // borde neón
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: .3),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            fileName,
                            style: const TextStyle(
                              fontFamily: 'PixelBoom', // o 'Orbitron'
                              fontSize: 16,
                              color: Colors.cyanAccent,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.cyan,
                                  blurRadius: 4,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => playMusic(path),
                          trailing: const Icon(
                            Icons.play_arrow,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
