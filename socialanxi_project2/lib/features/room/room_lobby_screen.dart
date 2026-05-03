import 'package:flutter/material.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomId;
  const RoomLobbyScreen({super.key, required this.roomId});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.roomId}'),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Room Lobby', style: TextStyle(fontSize: 24),),
            const SizedBox(height: 20,),
            Text('Room ID: ${widget.roomId}'),
            const SizedBox(height: 40,),
            const Text('Music Queue & Chat\nComing Soon', textAlign: TextAlign.center,),
          ],
        ),
      ),
    );
  }

}