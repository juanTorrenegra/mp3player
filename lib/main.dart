import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'Vending_machine_frame.dart';

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
  final ScrollController _scrollController = ScrollController();
  late Timer _scrollTimer;
  bool _scrollingForward = true;
  Timer? _userInteractionTimer;
  bool _autoScrollEnabled = true;

  List<String> musicFiles = [];
  bool loading = true;
  final player = AudioPlayer();

  String? currentlyPlaying;
  String? previousSong;
  bool isPlaying = false;

  bool isRandomMode = false;
  final Random _random = Random();

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    requestPermissionAndListFiles();

    player.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
      });

      // Si la canción termina y no está en modo aleatorio, activarlo
      if (state.processingState == ProcessingState.completed) {
        if (!isRandomMode) {
          setState(() {
            isRandomMode = true; // Activa el modo aleatorio
          });
          playRandomSong(); // Reproduce una canción aleatoria
        } else {
          playRandomSong(); // Continúa en modo aleatorio
        }
      }
    });

    player.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    player.positionStream.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });

    startAutoScroll();
  }

  void startAutoScroll() {
    const duration = Duration(milliseconds: 100);
    const scrollAmount = 1.0;

    _scrollTimer = Timer.periodic(duration, (timer) {
      if (_scrollController.hasClients && _autoScrollEnabled) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final minScroll = _scrollController.position.minScrollExtent;
        final current = _scrollController.offset;

        double next =
            current + (_scrollingForward ? scrollAmount : -scrollAmount);

        if (next >= maxScroll) {
          next = maxScroll;
          _scrollingForward = false;
        } else if (next <= minScroll) {
          next = minScroll;
          _scrollingForward = true;
        }

        _scrollController.jumpTo(next);
      }
    });
  }

  void onUserInteraction() {
    setState(() {
      _autoScrollEnabled = false;
    });
    _userInteractionTimer?.cancel();
    _userInteractionTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _autoScrollEnabled = true;
      });
    });
  }

  void playRandomSong() {
    if (musicFiles.isEmpty) return;
    final randomIndex = _random.nextInt(musicFiles.length);
    final randomPath = musicFiles[randomIndex];
    playMusic(randomPath);
  }

  void playNextRandom() {
    playRandomSong();
  }

  void playPreviousSong() {
    if (previousSong != null) {
      final song = previousSong;
      previousSong = null;
      playMusic(song!);
    }
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

      print("Archivos encontrados: \${mp3Files.length}");

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
      if (currentlyPlaying != null &&
          currentlyPlaying != path.split('/').last) {
        previousSong = musicFiles.firstWhere(
          (p) => p.endsWith(currentlyPlaying!),
          orElse: () => '',
        );
      }

      await player.setFilePath(path);
      await player.play();
      player.playerStateStream.firstWhere((state) => state.playing).then((_) {
        setState(() {
          currentlyPlaying = path.split('/').last;
        });
      });
    } catch (e) {
      print("Error al reproducir el archivo: \$e");
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

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _scrollTimer.cancel();
    _userInteractionTimer?.cancel();
    _scrollController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUserInteraction,
      onPanDown: (_) => onUserInteraction(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Manzana",
            style: TextStyle(
              fontFamily: "cursive",
              color: Colors.pinkAccent,
              letterSpacing: 3,
              fontSize: 17,
              shadows: [
                Shadow(
                  color: Colors.cyan,
                  blurRadius: 30,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VendingMachineFrame(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).secondaryHeaderColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            currentlyPlaying != null
                                ? currentlyPlaying!
                                : 'Dale play ...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'PixelBoom',
                              fontSize: 15,
                              //fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              Text(
                                formatDuration(currentPosition),
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 10,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white,
                                      blurRadius: 6,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Slider(
                                  value: currentPosition.inSeconds.toDouble(),
                                  max: totalDuration.inSeconds.toDouble(),
                                  onChanged: (value) async {
                                    final position = Duration(
                                      seconds: value.toInt(),
                                    );
                                    await player.seek(position);
                                  },
                                  activeColor: Colors.purple,
                                  inactiveColor: Colors.purple.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 1),
                              Text(
                                formatDuration(totalDuration),
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 10,
                                  shadows: [
                                    Shadow(
                                      color: Colors.cyan,
                                      blurRadius: 6,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: isPlaying ? pauseMusic : null,
                                style: ElevatedButton.styleFrom(
                                  shape: const OvalBorder(),
                                  padding: const EdgeInsets.all(20),
                                  backgroundColor: Colors.black,
                                  shadowColor: Colors.cyanAccent,
                                  elevation: 12,
                                ),
                                child: const Icon(
                                  Icons.pause,
                                  size: 30,
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
                              const SizedBox(width: 40),
                              ElevatedButton(
                                onPressed:
                                    !isPlaying && currentlyPlaying != null
                                    ? resumeMusic
                                    : startRandomMode,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(20),
                                  backgroundColor: Colors.black,
                                  shadowColor: Colors.greenAccent,
                                  elevation: 12,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  size: 30,
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
                              const SizedBox(width: 40),
                              ElevatedButton(
                                onPressed: startRandomMode,
                                style:
                                    ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(20),
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
                                  size: 30,
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
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: playPreviousSong,
                                style:
                                    ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      backgroundColor: Colors.black,
                                      elevation: 6,
                                      shadowColor: Colors.blueAccent,
                                    ).copyWith(
                                      overlayColor: MaterialStateProperty.all(
                                        Colors.blue.withOpacity(0.2),
                                      ),
                                    ),
                                child: const Icon(
                                  Icons.fast_rewind,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: playNextRandom,
                                style:
                                    ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      backgroundColor: Colors.black,
                                      elevation: 6,
                                      shadowColor: Colors.orangeAccent,
                                    ).copyWith(
                                      overlayColor: MaterialStateProperty.all(
                                        Colors.orange.withOpacity(0.2),
                                      ),
                                    ),
                                child: const Icon(
                                  Icons.fast_forward,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      children: musicFiles.map((path) {
                        final fileName = path.split('/').last;
                        return GestureDetector(
                          onTap: onUserInteraction,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0F1C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.cyanAccent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.3),
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
                                  fontFamily: 'Orbitron',
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
                              onTap: () {
                                onUserInteraction();
                                playMusic(path);
                              },
                              trailing: const Icon(
                                Icons.apple_outlined,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
