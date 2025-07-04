import 'dart:math';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

late final AudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());

  final player = AudioPlayer();
  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(player),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.mp3player.channel.audio',
      androidNotificationChannelName: 'Juanelo Music',
      androidNotificationOngoing: true,
    ),
  );

  runApp(MyApp(player: player));
}

class MyApp extends StatelessWidget {
  final AudioPlayer player;
  const MyApp({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FFCC),
        secondaryHeaderColor: const Color(0xFF4444FF),
        fontFamily: 'Orbitron',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Orbitron'),
          bodyMedium: TextStyle(fontFamily: 'Orbitron'),
        ),
      ),
      home: MusicListScreen(player: player),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MusicListScreen extends StatefulWidget {
  final AudioPlayer player;
  const MusicListScreen({super.key, required this.player});

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<String> musicFiles = [];
  bool loading = true;

  String? currentlyPlaying;
  bool isPlaying = false;
  bool isRandomMode = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    requestPermissionAndListFiles();

    widget.player.playerStateStream.listen((state) {
      setState(() => isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed && isRandomMode) {
        playRandomSong();
      }
    });

    widget.player.positionStream.listen(
      (position) => setState(() => _currentPosition = position),
    );

    widget.player.durationStream.listen((duration) {
      if (duration != null) {
        setState(() => _totalDuration = duration);
      }
    });
  }

  Future<void> requestPermissionAndListFiles() async {
    var status = await Permission.audio.request();
    if (status.isGranted) {
      listMusicFiles();
    } else {
      setState(() => loading = false);
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

      setState(() {
        musicFiles = mp3Files;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  void playMusic(String path) async {
    try {
      await widget.player.setFilePath(path);
      await widget.player.play();

      _audioHandler.play();
      _audioHandler.updateMediaItem(
        MediaItem(
          id: path,
          album: "Juanelo Player",
          title: path.split("/").last,
        ),
      );

      setState(() => currentlyPlaying = path.split('/').last);
    } catch (e) {
      print("Error al reproducir el archivo: $e");
    }
  }

  void pauseMusic() async {
    isRandomMode = false;
    await widget.player.pause();
    _audioHandler.pause();
  }

  void resumeMusic() async {
    await widget.player.play();
    _audioHandler.play();
  }

  void playRandomSong() {
    if (musicFiles.isEmpty) return;
    final randomIndex = _random.nextInt(musicFiles.length);
    playMusic(musicFiles[randomIndex]);
  }

  void startRandomMode() {
    isRandomMode = true;
    playRandomSong();
  }

  @override
  void dispose() {
    widget.player.dispose();
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
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).secondaryHeaderColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currentlyPlaying ?? 'No hay canción en reproducción',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 22,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (currentlyPlaying != null)
                        Slider(
                          value: _currentPosition.inMilliseconds.toDouble(),
                          max: _totalDuration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            widget.player.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                          activeColor: Colors.cyanAccent,
                          inactiveColor: Colors.grey.shade700,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          controlButton(
                            Icons.pause,
                            pauseMusic,
                            Colors.cyanAccent,
                          ),
                          const SizedBox(width: 20),
                          controlButton(
                            Icons.play_arrow,
                            resumeMusic,
                            Colors.greenAccent,
                          ),
                          const SizedBox(width: 20),
                          controlButton(
                            Icons.shuffle,
                            startRandomMode,
                            Colors.purpleAccent,
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
                          color: const Color(0xFF0A0F1C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.cyanAccent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withAlpha(100),
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
                              fontFamily: 'PixelBoom',
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

  Widget controlButton(IconData icon, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style:
          ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
            backgroundColor: Colors.black,
            shadowColor: color,
            elevation: 12,
          ).copyWith(
            overlayColor: MaterialStateProperty.all(color.withOpacity(0.2)),
          ),
      child: Icon(
        icon,
        size: 36,
        color: color,
        shadows: [Shadow(color: color, blurRadius: 10)],
      ),
    );
  }
}

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player;

  MyAudioHandler(this._player) {
    _player.playerStateStream.listen((state) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: [MediaControl.pause, MediaControl.play, MediaControl.stop],
          playing: state.playing,
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.connecting,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[state.processingState]!,
        ),
      );
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    mediaItem.add(mediaItem);
  }
}
