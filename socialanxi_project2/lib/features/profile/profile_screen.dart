import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40,),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              child: const Icon(Icons.person, size: 60,),
            ),

            const SizedBox(height: 20,),

            Text(
              user?.email ?? 'No Email',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10,),

            Text(
              'User ID: ${user?.uid.substring(0, 8)}...',
              style:  const TextStyle(color: Colors.black),
            ),

            const SizedBox(height: 50,),

            ListTile(
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black, width: 1), borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.black,
              leading: const Icon(Icons.history),
              title: const Text('Listening History'),
              subtitle: const Text('Coming soon'),
              onTap: () {},
            ),

            SizedBox(height: 10,),

            ListTile(
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black, width: 1), borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.black,
              leading: const Icon(Icons.favorite),
              title: const Text('Favorite Songs'),
              subtitle: const Text('Coming soon'),
              onTap: () {},
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: () => logout(context),
                child: const Text('Logout'),),
            )

          ],

        ),),
    );
  }



}