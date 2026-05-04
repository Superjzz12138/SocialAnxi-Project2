import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../queue/song_model.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<Song> recommendations = [];
  bool isLoading = false;

  Future<void> getRecommendations() async {
    setState(() => isLoading = true);

    // randomly recommen from all queues
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('queue')
        .get();

    final allSongs = snapshot.docs.map((doc) {
      return Song.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();

    allSongs.shuffle();
    recommendations = allSongs.take(5).toList();

    setState(() => isLoading = false);
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
              child: const Text('Get Recommendations'),
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
                        return ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          trailing: const Icon(Icons.play_arrow),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Playing ${song.title}')),
                            );
                          },
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