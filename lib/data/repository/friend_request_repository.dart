import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendRequestRepositoryProvider =
Provider<FriendRequestRepository>((ref) => FriendRequestRepository());

class FriendRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getReceivedFriendRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'fromUserId': data['fromUserId'],
        'timestamp': data['timestamp'],
      };
    }).toList());
  }

  Future<void> acceptFriendRequest(String requestId, String fromUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String currentUserId = currentUser.uid;

    await _firestore.runTransaction((transaction) async {
      final requestRef =
      _firestore.collection('friend_requests').doc(requestId);
      final userRef = _firestore.collection('users').doc(currentUserId);
      final fromUserRef = _firestore.collection('users').doc(fromUserId);

      // 刪除好友邀請
      transaction.delete(requestRef);

      // 雙方更新好友列表
      transaction.update(userRef, {
        'friends': FieldValue.arrayUnion([fromUserId])
      });
      transaction.update(fromUserRef, {
        'friends': FieldValue.arrayUnion([currentUserId])
      });

      // 從 receivedRequests & sentRequests 移除
      transaction.update(userRef, {
        'receivedRequests': FieldValue.arrayRemove([fromUserId])
      });
      transaction.update(fromUserRef, {
        'sentRequests': FieldValue.arrayRemove([currentUserId])
      });
    });
  }

  Future<void> declineFriendRequest(String requestId, String fromUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String currentUserId = currentUser.uid;

    await _firestore.runTransaction((transaction) async {
      final requestRef =
      _firestore.collection('friend_requests').doc(requestId);
      final userRef = _firestore.collection('users').doc(currentUserId);
      final fromUserRef = _firestore.collection('users').doc(fromUserId);

      // 刪除好友邀請
      transaction.delete(requestRef);

      // 從 receivedRequests & sentRequests 移除
      transaction.update(userRef, {
        'receivedRequests': FieldValue.arrayRemove([fromUserId])
      });
      transaction.update(fromUserRef, {
        'sentRequests': FieldValue.arrayRemove([currentUserId])
      });
    });
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String currentUserId = currentUser.uid;

    if (currentUserId == targetUserId) return; // 不能加自己為好友

    final docRef = _firestore
        .collection('friend_requests')
        .doc('${currentUserId}_$targetUserId');

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // 已經發送過邀請
      return;
    }

    // 開始寫入 Firestore
    await _firestore.runTransaction((transaction) async {
      // 建立好友請求
      transaction.set(docRef, {
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 更新當前用戶的 sentRequests
      final currentUserRef =
      _firestore.collection('users').doc(currentUserId);
      transaction.update(currentUserRef, {
        'sentRequests': FieldValue.arrayUnion([targetUserId])
      });

      // 更新目標用戶的 receivedRequests
      final targetUserRef =
      _firestore.collection('users').doc(targetUserId);
      transaction.update(targetUserRef, {
        'receivedRequests': FieldValue.arrayUnion([currentUserId])
      });
    });
  }
}
