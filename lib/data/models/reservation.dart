import 'package:cloud_firestore/cloud_firestore.dart';

enum IdentityType { manager, photographer, coser, original } // 預設身份類別

enum ReservationStatus { pending, confirmed, cancelled } // 預定狀態

class Reservation {
  final String id;
  final String eventId; // 參加的事件 ID
  final String userId; // 預定的使用者 ID
  final IdentityType identity; // 身份
  final String? character; // 角色（可空）
  final ReservationStatus status; // 預定狀態
  final DateTime createdAt; // 創建時間
  final DateTime? updatedAt; // 更新時間

  Reservation({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.identity,
    required this.status,
    required this.createdAt,
    this.character,
    this.updatedAt,
  });

  // Firestore 轉換
  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      eventId: data['eventId'] as String,
      userId: data['userId'] as String,
      identity: IdentityType.values[data['identity'] as int],
      character: data['character'] as String?,
      status: ReservationStatus.values[data['status'] as int],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'identity': identity.index,
      'character': character,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
