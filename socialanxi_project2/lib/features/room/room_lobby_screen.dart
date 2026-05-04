import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../queue/song_model.dart';
import '../chat/message_model.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomId;
  const RoomLobbyScreen({super.key, required this.roomId});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  final TextEditingController songTitleController = TextEditingController();
  final TextEditingController artistController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  Future<void> addSong() async {
    final title = songTitleController.text.trim();
    final artist = artistController.text.trim();

    if (title.isEmpty || artist.isEmpty) return;

    final song = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      artist: artist,
      coverUrl: 'https://picsum.photos/200',
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

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      userId: user.uid, 
      userEmail: user.email ?? 'Anonymous', 
      text: text, 
      timestamp: DateTime.now(),);

      await FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.roomId)
      .collection('messages')
      .doc(message.id)
      .set(message.toMap());

      messageController.clear();
  }

  Future<void> voteForSong(String songId, int currentVotes) async {
    await FirebaseFirestore.instance
    .collection('rooms')
    .doc(widget.roomId)
    .collection('queue')
    .doc(songId)
    .update({'voteCount': currentVotes + 1});
  }

@override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.roomId}')),
      body: Column(
        children: [
          // Music Queue Section (Merged Add Song)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                      controller: songTitleController, 
                      decoration: const InputDecoration(labelText: 'Song Title'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: artistController, 
                        decoration: const InputDecoration(labelText: 'Artist'))),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: addSong, 
                  child: const Text('Add Song')),
              ],
            ),
          ),

          // Queue List Section
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[900],
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Queue (Vote for next song)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

                      if (songs.isEmpty) {
                        return const Center(child: Text('No songs yet'));
                      }

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
                                  onPressed: () => voteForSong(song.id, song.voteCount), 
                                  icon: const Icon(Icons.thumb_up, color: Colors.green),),
                              ],
                            )
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),


          // Chat Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                  }

                final messages = snapshot.data!.docs.map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>)).toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ListTile(
                      title: Text(msg.userEmail),
                      subtitle: Text(msg.text),
                      trailing: Text('${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}'),
                    );
                  },
                );
              },
            ),
          ),

          // Message Section
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message here',
                      border: OutlineInputBorder(),
                    ),
                  ),),
                  IconButton(
                    onPressed: sendMessage, 
                    icon: const Icon(Icons.send)),
              ],
            ),)
        ],
      ),
    );
  }

  @override
  void dispose() {
    songTitleController.dispose();
    artistController.dispose();
    messageController.dispose();
    super.dispose();
  }
}