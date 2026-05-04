import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String userId;
  final String userEmail;
  final String text;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'text': text,
      'timestamp': timestamp,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'], 
      userId: map['userId'], 
      userEmail: map['userEmail'], 
      text: map['text'], 
      timestamp: (map['timestamp'] as Timestamp).toDate(),);
  }
}