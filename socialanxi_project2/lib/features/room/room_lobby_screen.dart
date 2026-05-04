import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialanxi_project2/features/queue/song_model.dart';
import 'package:socialanxi_project2/features/chat/message_model.dart';
import 'package:socialanxi_project2/features/player/music_player_screen.dart';
import 'package:socialanxi_project2/features/home/home_screen.dart';

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

  List<Song> currentQueue = [];
  bool isAddingDemo = false;
  String? currentUserId;
  String? hostId;
  int participantCount = 0;

  final List<Song> demoSongs = [
    Song(id: 'demo1', title: 'Demo 1', artist: 'SoundHelix', coverUrl: 'https://picsum.photos/id/1015/300/300', audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', voteCount: 0),
    Song(id: 'demo2', title: 'Demo 2', artist: 'SoundHelix', coverUrl: 'https://picsum.photos/id/102/300/300', audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', voteCount: 0),
    Song(id: 'demo3', title: 'Demo 3', artist: 'SoundHelix', coverUrl: 'https://picsum.photos/id/106/300/300', audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', voteCount: 0),
    Song(id: 'demo4', title: 'Demo 4', artist: 'SoundHelix', coverUrl: 'https://picsum.photos/id/133/300/300', audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', voteCount: 0),
    Song(id: 'demo5', title: 'Demo 5', artist: 'SoundHelix', coverUrl: 'https://picsum.photos/id/201/300/300', audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', voteCount: 0),
  ];

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _joinRoom();
    _listenToRoomInfo();
  }

  Future<void> _joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('participants')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'email': user.email ?? 'Anonymous',
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _leaveRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('participants')
        .doc(user.uid)
        .delete();
  }

  void _listenToRoomInfo() {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          hostId = data['hostId'] as String?;
          participantCount = data['participantCount'] ?? 1;
        });
      }
    });
  }

  bool get isHost => currentUserId != null && hostId == currentUserId;

  Future<void> _copyRoomId() async {
    await Clipboard.setData(ClipboardData(text: widget.roomId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room ID copied to clipboard!')),
    );
  }

  Future<void> _deleteRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('Are you sure you want to delete this room? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final batch = FirebaseFirestore.instance.batch();
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    batch.delete(roomRef);

    final collections = ['queue', 'messages', 'participants', 'playback'];
    for (var col in collections) {
      final docs = await roomRef.collection(col).get();
      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> voteForSong(String songId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final voteRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('votes')
        .doc('${user.uid}_$songId');

    final voteDoc = await voteRef.get();
    if (voteDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already voted for this song')),
      );
      return;
    }

    await voteRef.set({
      'userId': user.uid,
      'songId': songId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('queue')
        .doc(songId)
        .update({'voteCount': FieldValue.increment(1)});
  }

  Future<void> addDemoSongs() async {
    setState(() => isAddingDemo = true);
    for (var song in demoSongs) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('queue')
          .doc(song.id)
          .set(song.toMap());
    }
    setState(() => isAddingDemo = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('5 Demo songs added!')));
  }

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
      voteCount: 0,
    );

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('queue')
        .doc(song.id)
        .set(song.toMap());

    songTitleController.clear();
    artistController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song added!')));
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      userEmail: user.email ?? 'Anonymous',
      text: text,
      timestamp: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    messageController.clear();
  }

  void openPlayer() {
    if (currentQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No songs in queue yet')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusicPlayerScreen(
          roomId: widget.roomId,
          queue: currentQueue,
          isHost: isHost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveRoom();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Room: ${widget.roomId}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyRoomId,
              tooltip: 'Copy Room ID',
            ),
            Chip(
              label: Text('$participantCount online'),
              backgroundColor: Colors.green[700],
            ),
            if (isHost)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteRoom,
              ),
            IconButton(onPressed: openPlayer, icon: const Icon(Icons.play_arrow)),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[850],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Online Users', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .collection('participants')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
                      }
                      final users = snapshot.data!.docs;
                      if (users.isEmpty) {
                        return const Text('No users online');
                      }
                      return SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userData = users[index].data() as Map<String, dynamic>;
                            final email = (userData['email'] as String?) ?? 'Anonymous';
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.deepPurple,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email.split('@')[0],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[900],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add to Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: songTitleController, decoration: const InputDecoration(labelText: 'Song Title'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: artistController, decoration: const InputDecoration(labelText: 'Artist'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: addSong, child: const Text('Add Custom Song'))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(onPressed: isAddingDemo ? null : addDemoSongs, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Add Demo Songs'))),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[900],
              height: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(widget.roomId)
                          .collection('queue')
                          .orderBy('voteCount', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final songs = snapshot.data!.docs.map((doc) => Song.fromMap(doc.data() as Map<String, dynamic>)).toList();
                        currentQueue = List.from(songs);
                        if (songs.isEmpty) return const Center(child: Text('No songs yet'));
                        return ListView.builder(
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            return ListTile(
                              leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(song.coverUrl, width: 50, height: 50, fit: BoxFit.cover)),
                              title: Text(song.title),
                              subtitle: Text(song.artist),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('${song.voteCount}'),
                                IconButton(
                                  onPressed: () => voteForSong(song.id),
                                  icon: const Icon(Icons.thumb_up, color: Colors.green),
                                ),
                              ]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!.docs.map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>)).toList();
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ListTile(title: Text(msg.userEmail), subtitle: Text(msg.text), trailing: Text('${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}'));
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: messageController, decoration: const InputDecoration(hintText: 'Type a message here', border: OutlineInputBorder()))),
                  IconButton(onPressed: sendMessage, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _leaveRoom();
    songTitleController.dispose();
    artistController.dispose();
    messageController.dispose();
    super.dispose();
  }
}