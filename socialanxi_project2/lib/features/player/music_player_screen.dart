import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../queue/song_model.dart';

class MusicPlayerScreen extends StatefulWidget {
  final List<Song> queue;
  final int initialIndex;

  const MusicPlayerScreen({
    super.key,
    required this.queue,
    this.initialIndex = 0,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late AudioPlayer _audioPlayer;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    currentIndex = widget.initialIndex;
    _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    if (widget.queue.isEmpty) return;

    final song = widget.queue[currentIndex];

    await _audioPlayer.setUrl(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    );
    _audioPlayer.play();
  }


  void _playNextSong() {
    if (currentIndex < widget.queue.length - 1) {
      setState(() {
        currentIndex++;
      });
      _playCurrentSong();
    }
  }

  void _playPreviousSong() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _playCurrentSong();
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.queue.isNotEmpty ? widget.queue[currentIndex]:null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Song Cover
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.music_note, size: 100,),
            ),
            const SizedBox(height: 30,),

            // Song Info
            Text(
              currentSong?.title ?? 'No Song',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              currentSong?.artist ?? '',
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 40,),

            // Play Control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  onPressed: _playPreviousSong, 
                  icon: const Icon(Icons.skip_previous)),
                  IconButton(
                    iconSize: 48,
                    onPressed: () => _audioPlayer.pause(), 
                    icon: const Icon(Icons.pause_circle_filled)),
                    IconButton(
                      iconSize: 48,
                      onPressed: _playNextSong, 
                      icon: const Icon(Icons.skip_next)),
              ],
            ),

            const SizedBox(height: 20,),
            const Text('Audio Playing', style: TextStyle(color: Colors.black),),
          ],
        ),

      ),
    );
  }




}