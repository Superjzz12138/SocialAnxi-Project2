import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibzcheck'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Vibzcheck',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 60),

            // Create Room Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Create room later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create Room coming soon...')),
                  );
                },
                child: const Text('Create New Room', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),

            // Join Room Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Join room later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Join Room coming soon...')),
                  );
                },
                child: const Text('Join Existing Room', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}