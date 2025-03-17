import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

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

  // 獲取所有活動
  Future<List<Event>> getEvents() async {
    final snapshot = await _firestore
        .collection('events')
        .orderBy('startDate', descending: false)
        .get();

    return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
  }

  // 添加活動
  Future<void> addEvent(Event event) async {
    await _firestore.collection('events').add(event.toFirestore());
  }

  // 更新活動
  Future<void> updateEvent(Event event) async {
    await _firestore
        .collection('events')
        .doc(event.id)
        .update(event.toFirestore());
  }

  // 刪除活動
  Future<void> deleteEvent(String id) async {
    await _firestore.collection('events').doc(id).delete();
  }

  // 獲取特定日期的活動
  Future<List<Event>> getEventsForDate(String date) async {
    final snapshot = await _firestore
        .collection('events')
        .where('date', isEqualTo: date)
        .get();

    return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
  }
}
