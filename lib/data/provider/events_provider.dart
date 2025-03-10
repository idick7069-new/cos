import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

// Firestore 事件流 Provider
final eventsProvider = StreamProvider.autoDispose<List<Event>>((ref) {
  return FirebaseFirestore.instance.collection('events').snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList(),
  );
});
