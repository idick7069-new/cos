import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reservation.dart';

class ReservationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReservation(Reservation reservation) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // 檢查是否已經預定過這個活動
    final reservationQuery = await _firestore
        .collection('reservations')
        .where('eventId', isEqualTo: reservation.eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    final eventRef = _firestore.collection('events').doc(reservation.eventId);

    if (reservationQuery.docs.isNotEmpty) {
      // 已有預定，更新資料
      final reservationDoc = reservationQuery.docs.first;
      final reservationId = reservationDoc.id;

      await _firestore.collection('reservations').doc(reservationId).update(
            reservation.toMap()..remove('id'), // 移除 id 欄位，因為不需要更新
          );

      // 確保 event 內有正確的 reservationId
      await eventRef.update({
        'participants': FieldValue.arrayUnion([reservationId])
      });
    } else {
      // 尚無預定，新增一筆
      final reservationRef = await _firestore.collection('reservations').add(
            reservation.toMap()..remove('id'), // 移除 id 欄位，因為 Firestore 會自動生成
          );

      // 把 reservationId 存到 event 裡
      await eventRef.update({
        'participants': FieldValue.arrayUnion([reservationRef.id])
      });
    }
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

    if (reservationQuery.docs.isNotEmpty) {
      final reservationDoc = reservationQuery.docs.first;
      final reservationId = reservationDoc.id;
      final reservation = Reservation.fromFirestore(reservationDoc);

      // 從 event 中移除 reservationId
      final eventRef = _firestore.collection('events').doc(eventId);
      await eventRef.update({
        'participants': FieldValue.arrayRemove([reservationId])
      });

      // 刪除預定
      await _firestore.collection('reservations').doc(reservationId).delete();
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

  // 取得使用者的所有預定
  Future<List<Reservation>> getUserReservations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
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

  // 取得使用者對特定活動的所有預定（包括多天活動的所有天數）
  Future<List<Reservation>> getUserReservationsForEvent(String eventId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final reservations = await _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .get();

    return reservations.docs
        .map((doc) => Reservation.fromFirestore(doc))
        .toList();
  }

  // 檢查使用者是否已經預定了某一天
  Future<bool> hasReservationForDay(String eventId, String userId) async {
    final reservations = await _firestore
        .collection('reservations')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return reservations.docs.isNotEmpty;
  }
}
