import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String senderId;
  final String receiverId;
  final String status; // "pending", "accepted", "rejected"
  final DateTime timestamp;

  FriendRequest({
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> data) {
    return FriendRequest(
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      status: data['status'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
