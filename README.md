# Vibzcheck 🎵

Hey! Welcome to **Vibzcheck** — A simple Flutter music room app.

This app is built for people who want to listen songs with friends.

---

### Features

- Create or join rooms with a simple Room ID
- Add songs to the queue
- Vote on songs — the most voted songs play queue first
- Real-time chat while listening
- Host controls which song to play and sync to all the room members
- Online users counter
- Music recommendations from all rooms
- Personal profile with listening history & favorite songs
- Dark theme

---

### Tech Overview

- Flutter & Dart
- Firebase (Auth + Firestore + Storage)
- just_audio (music playback)
- Simple setState

---

### Project Information

- Member: Justin Wu
- Responsible for: All features and development

---

### How to Run Locally

1. Clone the project:
   git clone https://github.com/yourusername/vibzcheck.git
   cd vibzcheck
   
2. Install Dependencies:
   flutter pub get
   
3. Setup Firebase:
- Go to Firebase Console
- Create a new project
- Run flutterfire configure or replace the firebase_options.dart file with your own

4. Run the app:
- flutter run
