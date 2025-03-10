import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/views/model/event_view_model.dart';
import '../models/event.dart';


final eventsNotifierProvider = StateNotifierProvider<EventsNotifier, List<EventViewModel>>((ref) {
  return EventsNotifier(FirebaseFirestore.instance);
});


class EventsNotifier extends StateNotifier<List<EventViewModel>> {
  EventsNotifier(this._firestore) : super([]);

  final FirebaseFirestore _firestore;

  Future<void> loadEvents() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // 1. 取得所有活動
    final eventSnapshot = await _firestore.collection('events').get();
    final events = eventSnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    print('測試 events $events');
    // 2. 取得使用者的所有預定
    final reservationSnapshot = await _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .get();

    final userReservations = reservationSnapshot.docs.map((doc) {
      return {'reservationId': doc.id, 'eventId': doc['eventId'] as String};
    }).toList();
    print('測試 userReservations $userReservations');
    // 3. 建立 ViewModel
    final eventViewModels = events.map((event) {
      final reservation = userReservations.firstWhere(
            (r) => r['eventId'] == event.id,
            orElse: () => {},
      );

      return EventViewModel(
        event: event,
        isParticipating: reservation['reservationId'] != null,
        reservationId: reservation['reservationId'],
      );
    }).toList();
    print('測試 eventViewModels $eventViewModels');
    state = eventViewModels;
  }
}
