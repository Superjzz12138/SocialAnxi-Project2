import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialanxi_project2/features/queue/song_model.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<Song> recommendations = [];
  bool isLoading = false;

  final List<Song> demoRecommendations = [
    Song(
      id: 'rec1',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      coverUrl: 'https://picsum.photos/id/1015/300/300',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      voteCount: 245,
    ),
    Song(
      id: 'rec2',
      title: 'Levitating',
      artist: 'Dua Lipa',
      coverUrl: 'https://picsum.photos/id/102/300/300',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      voteCount: 189,
    ),
    Song(
      id: 'rec3',
      title: 'Save Your Tears',
      artist: 'The Weeknd',
      coverUrl: 'https://picsum.photos/id/106/300/300',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      voteCount: 156,
    ),
    Song(
      id: 'rec4',
      title: 'Watermelon Sugar',
      artist: 'Harry Styles',
      coverUrl: 'https://picsum.photos/id/133/300/300',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      voteCount: 132,
    ),
    Song(
      id: 'rec5',
      title: 'Stay',
      artist: 'The Kid LAROI',
      coverUrl: 'https://picsum.photos/id/201/300/300',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      voteCount: 98,
    ),
  ];

  Future<void> getRecommendations() async {
    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('queue')
          .get();

      final allSongs = snapshot.docs
          .map((doc) => Song.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      allSongs.sort((a, b) => b.voteCount.compareTo(a.voteCount));

      setState(() {
        recommendations = allSongs.isNotEmpty ? allSongs.take(10).toList() : demoRecommendations;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        recommendations = demoRecommendations;
        isLoading = false;
      });
    }
  }

  Future<void> addToQueue(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    final userRooms = await FirebaseFirestore.instance
        .collection('rooms')
        .where('hostId', isEqualTo: user.uid)
        .get();

    if (userRooms.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have no rooms. Create one first')));
      return;
    }

    final roomId = userRooms.docs.first.id;

    final songToAdd = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: song.title,
      artist: song.artist,
      coverUrl: song.coverUrl,
      audioUrl: song.audioUrl,
      voteCount: 0,
    );

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('queue')
        .doc(songToAdd.id)
        .set(songToAdd.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${song.title} added to your room')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: getRecommendations,
              child: const Text('Get Popular Recommendations'),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator()),

            Expanded(
              child: recommendations.isEmpty
                  ? const Center(child: Text('Press button to get recommendations'))
                  : ListView.builder(
                      itemCount: recommendations.length,
                      itemBuilder: (context, index) {
                        final song = recommendations[index];
                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.coverUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(song.title),
                            subtitle: Text('${song.artist} • ${song.voteCount} votes'),
                            trailing: IconButton(
                              icon: const Icon(Icons.playlist_add, color: Colors.green),
                              onPressed: () => addToQueue(song),
                            ),
                          ),
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