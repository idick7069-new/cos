import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reservation.dart';

class ReservationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReservation(String eventId, IdentityType identity,
      {String? character}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final reservationQuery = await _firestore
        .collection('reservations')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    final eventRef = _firestore.collection('events').doc(eventId);

    if (reservationQuery.docs.isNotEmpty) {
      // 已有預定，更新資料
      final reservationDoc = reservationQuery.docs.first;
      final reservationId = reservationDoc.id;

      await _firestore.collection('reservations').doc(reservationId).update({
        'identity': identity.index,
        'character': character ?? '',
        'status': ReservationStatus.pending.index,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 確保 event 內有正確的 reservationId
      await eventRef.update({
        'participants': FieldValue.arrayUnion([reservationId])
      });
    } else {
      // 尚無預定，新增一筆
      final reservationRef = await _firestore.collection('reservations').add({
        'eventId': eventId,
        'userId': userId,
        'identity': identity.index,
        'character': character ?? '',
        'status': ReservationStatus.pending.index,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });

      // 把 reservationId 存到 event 裡
      await eventRef.update({
        'participants': FieldValue.arrayUnion([reservationRef.id])
      });
    }
  }

  Future<void> updateReservationStatus(
      String reservationId, ReservationStatus newStatus) async {
    await _firestore.collection('reservations').doc(reservationId).update({
      'status': newStatus.index,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeReservation(String eventId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final reservationQuery = await _firestore
        .collection('reservations')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    print('移除預定 $eventId, $userId');
    if (reservationQuery.docs.isNotEmpty) {
      final reservationId = reservationQuery.docs.first.id;

      // 更新狀態為已取消
      await updateReservationStatus(reservationId, ReservationStatus.cancelled);

      // 從 event 內移除 reservationId
      final eventRef = _firestore.collection('events').doc(eventId);
      await eventRef.update({
        'participants': FieldValue.arrayRemove([reservationId])
      });
    }
  }

  // 取得某個事件的所有預定
  Stream<List<Reservation>> getReservationsForEvent(String eventId) {
    return _firestore
        .collection('reservations')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reservation.fromFirestore(doc))
            .toList());
  }

  // 取消預定
  Future<void> cancelReservation(String reservationId) async {
    print('取消預定 $reservationId');
    await _firestore.collection('reservations').doc(reservationId).delete();
  }

  // 取得使用者的所有預定
  Future<List<Reservation>> getUserReservations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    print('取得使用者的所有預定 $userId');
    if (userId == null) return [];

    final reservations = await _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return reservations.docs
        .map((doc) => Reservation.fromFirestore(doc))
        .toList();
  }
}
