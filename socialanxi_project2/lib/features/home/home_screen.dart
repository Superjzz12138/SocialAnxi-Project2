import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialanxi_project2/features/profile/profile_screen.dart';
import 'package:socialanxi_project2/features/recommendation/recommendation_screen.dart';
import 'package:socialanxi_project2/features/room/room_model.dart';
import 'package:socialanxi_project2/features/room/room_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController joinRoomIdController = TextEditingController();

  Future<void> createRoom() async {
    final TextEditingController roomNameController = TextEditingController();

    final String? roomName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Room'),
        content: TextField(
          controller: roomNameController,
          decoration: const InputDecoration(labelText: 'Room Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, roomNameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (roomName == null || roomName.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String roomId = DateTime.now().millisecondsSinceEpoch.toString();
    final newRoom = Room(
      roomId: roomId,
      roomName: roomName,
      hostId: user.uid,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set(newRoom.toMap());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Room "$roomName" created!')));

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RoomLobbyScreen(roomId: roomId)));
    }
  }

  void joinRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Room'),
        content: TextField(
          controller: joinRoomIdController,
          decoration: const InputDecoration(labelText: 'Enter Room ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final roomId = joinRoomIdController.text.trim();
              if (roomId.isEmpty) return;

              final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
              if (roomDoc.exists) {
                Navigator.pop(context);
                if (mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RoomLobbyScreen(roomId: roomId)));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room ID not found!')));
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibzcheck'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Welcome to Vibzcheck',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            Card(
              color: Colors.grey[900],
              child: ListTile(
                leading: const Icon(Icons.recommend, size: 40, color: Colors.purple),
                title: const Text('Music Recommendations'),
                subtitle: const Text('Discover popular songs from all rooms'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendationScreen())),
              ),
            ),

            const SizedBox(height: 60),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: createRoom,
                child: const Text('Create New Room', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: joinRoom,
                child: const Text('Join Room by ID', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 40),
            const Text('Available Rooms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final rooms = snapshot.data!.docs;
                  if (rooms.isEmpty) return const Center(child: Text('No rooms yet'));

                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final roomData = rooms[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(roomData['roomName'] ?? 'Unnamed Room'),
                        subtitle: Text('Host: ${roomData['hostId'].substring(0, 8)}...'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RoomLobbyScreen(roomId: roomData['roomId'])),
                        ),
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

  @override
  void dispose() {
    joinRoomIdController.dispose();
    super.dispose();
  }
}