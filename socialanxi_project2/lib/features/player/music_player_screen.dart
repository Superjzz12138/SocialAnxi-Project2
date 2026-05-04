import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialanxi_project2/features/queue/song_model.dart';

class MusicPlayerScreen extends StatefulWidget {
  final List<Song> queue;
  final String roomId;
  final bool isHost;

  const MusicPlayerScreen({
    super.key,
    required this.queue,
    required this.roomId,
    required this.isHost,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  int currentIndex = 0;
  bool isPlaying = false;
  String? errorMessage;

  late AnimationController _favoriteController;
  late Animation<double> _favoriteAnimation;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _listenToPlaybackState();
    _playCurrentSong();

    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.easeInOut),
    );
  }

  Future<void> _saveToHistory(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .add({
      'title': song.title,
      'artist': song.artist,
      'coverUrl': song.coverUrl,
      'playedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleFavorite(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _favoriteController.forward().then((_) => _favoriteController.reverse());

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .where('title', isEqualTo: song.title)
        .where('artist', isEqualTo: song.artist)
        .limit(1);

    final snapshot = await favRef.get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .add({
        'title': song.title,
        'artist': song.artist,
        'coverUrl': song.coverUrl,
        'addedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites ❤️')),
      );
    }
  }

  Future<void> _playCurrentSong() async {
    if (widget.queue.isEmpty) return;
    final song = widget.queue[currentIndex];

    _saveToHistory(song);

    try {
      await _audioPlayer.setUrl(song.audioUrl.isNotEmpty
          ? song.audioUrl
          : 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
      if (isPlaying) await _audioPlayer.play();
    } catch (e) {
      setState(() => errorMessage = 'Playback error');
    }
  }

  void _listenToPlaybackState() {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('playback')
        .doc('current')
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final newIndex = data['currentIndex'] ?? 0;
      final position = Duration(milliseconds: (data['position'] ?? 0) as int);
      final serverPlaying = data['isPlaying'] ?? false;

      if (newIndex != currentIndex) {
        setState(() => currentIndex = newIndex);
        await _playCurrentSong();
      }

      if (serverPlaying != isPlaying && !widget.isHost) {
        serverPlaying ? await _audioPlayer.play() : await _audioPlayer.pause();
        setState(() => isPlaying = serverPlaying);
      }

      await _audioPlayer.seek(position);
    });
  }

  void _updatePlaybackState() {
    if (!widget.isHost) return;
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('playback')
        .doc('current')
        .set({
      'currentIndex': currentIndex,
      'position': _audioPlayer.position.inMilliseconds,
      'isPlaying': isPlaying,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _togglePlayPause() async {
    if (widget.isHost) {
      setState(() => isPlaying = !isPlaying);
      isPlaying ? await _audioPlayer.play() : await _audioPlayer.pause();
      _updatePlaybackState();
    }
  }

  void _playNextSong() {
    if (currentIndex < widget.queue.length - 1 && widget.isHost) {
      setState(() => currentIndex++);
      _playCurrentSong();
      _updatePlaybackState();
    }
  }

  void _playPreviousSong() {
    if (currentIndex > 0 && widget.isHost) {
      setState(() => currentIndex--);
      _playCurrentSong();
      _updatePlaybackState();
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '00:00';
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.queue.isNotEmpty ? widget.queue[currentIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? 'Now Playing (Host)' : 'Now Playing (Sync)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                currentSong?.coverUrl ?? '',
                width: 280,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 120),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              currentSong?.title ?? 'No Song',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              currentSong?.artist ?? '',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            StreamBuilder<Duration?>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _audioPlayer.duration ?? Duration.zero;
                return Column(
                  children: [
                    Slider(
                      value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                      max: duration.inMilliseconds.toDouble(),
                      onChanged: widget.isHost
                          ? (value) {
                              _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                              _updatePlaybackState();
                            }
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 64,
                  onPressed: widget.isHost ? _playPreviousSong : null,
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  iconSize: 80,
                  onPressed: _togglePlayPause,
                  icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                ),
                IconButton(
                  iconSize: 64,
                  onPressed: widget.isHost ? _playNextSong : null,
                  icon: const Icon(Icons.skip_next),
                ),
                const SizedBox(width: 16),
                ScaleTransition(
                  scale: _favoriteAnimation,
                  child: IconButton(
                    iconSize: 48,
                    onPressed: () => _toggleFavorite(widget.queue[currentIndex]),
                    icon: const Icon(Icons.favorite, color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}