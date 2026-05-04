import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../queue/song_model.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomId;
  const RoomLobbyScreen({super.key, required this.roomId});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  final TextEditingController songTitleController = TextEditingController();
  final TextEditingController artistController = TextEditingController();

  Future<void> addSong() async {
    final title = songTitleController.text.trim();
    final artist = artistController.text.trim();

    if (title.isEmpty || artist.isEmpty) return;

    final song = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      artist: artist,
      coverUrl: 'https://www.google.com/url?sa=t&source=web&rct=j&url=https%3A%2F%2Fopen.spotify.com%2Falbum%2F5LMVFKJxV1UtS1uZL2tOan&ved=0CBYQjRxqFwoTCMCn5vylnpQDFQAAAAAdAAAAABAG&opi=89978449',
      audioUrl: '',
    );

    await FirebaseFirestore.instance
    .collection('rooms')
    .doc(widget.roomId)
    .collection('queue')
    .doc(song.id)
    .set(song.toMap());

    songTitleController.clear();
    artistController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Song added to queue!')),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.roomId}')),
      body: Column(
        children: [
          // Add Song
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: songTitleController,
                  decoration: const InputDecoration(labelText: 'Song Title'),
                ),
                TextField(
                  controller: artistController,
                  decoration: const InputDecoration(labelText: 'Artist'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: addSong,
                  child: const Text('Add to Queue'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Queue List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('queue')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final songs = snapshot.data!.docs.map((doc) {
                  return Song.fromMap(doc.data() as Map<String, dynamic>);
                }).toList();

                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${song.voteCount}'),
                          IconButton(
                            icon: const Icon(Icons.thumb_up),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomId)
                                  .collection('queue')
                                  .doc(song.id)
                                  .update({'voteCount': song.voteCount + 1});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    songTitleController.dispose();
    artistController.dispose();
    super.dispose();
  }
}