import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final eventRepositoryProvider = Provider((ref) => EventRepository());

// 參加事件 Provider（封裝參加事件邏輯）
final participateEventProvider = Provider((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.participateInEvent;
});

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 參加事件
  Future<void> participateInEvent(String eventId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final eventRef = _firestore.collection('events').doc(eventId);
    await eventRef.update({
      'participants': FieldValue.arrayUnion([userId])
    });
  }
}

