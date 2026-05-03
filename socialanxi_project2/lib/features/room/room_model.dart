class Room {
  final String roomId;
  final String roomName;
  final String hostId;
  final int participantCount;
  final DateTime createdAt;

  Room({
    required this.roomId,
    required this.roomName,
    required this.hostId,
    this.participantCount = 1,
    required this.createdAt
  });
  
  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'hostId': hostId,
      'participantCount': participantCount,
      'createdAt': createdAt
    };
  }
}