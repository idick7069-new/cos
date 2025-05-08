import 'package:cloud_firestore/cloud_firestore.dart';

enum IdentityType { manager, photographer, coser, original }

class Reservation {
  final String id;
  final String eventId;
  final String userId;
  final IdentityType identity;
  final String? character;
  final DateTime createdAt;
  final String day;

  Reservation({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.identity,
    this.character,
    required this.createdAt,
    required this.day,
  });

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      identity: IdentityType.values[data['identity'] ?? 0],
      character: data['character'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      day: data['day'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'identity': identity.index,
      'character': character,
      'createdAt': createdAt,
      'day': day,
    };
  }
}
