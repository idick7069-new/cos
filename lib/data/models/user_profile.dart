import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String? uid; // 使用者 ID
  final String? cn; // 名稱
  final String? gender; // 性別
  final List<String>? pits; // 坑單（興趣清單）
  final List<String>? regions; // 地區
  final String? bio; // 自我介紹
  final String? coverPhotoUrl; // 封面照片
  final String? profilePhotoUrl; // 個人頭像
  final List<String>? friends; // 好友列表
  final List<String>? receivedRequests; // 收到的好友邀請
  final List<String>? sentRequests; // 發出的好友邀請
  final DateTime? createdAt; // 帳號建立時間
  final DateTime? updatedAt; // 最近更新時間

  UserProfile({
    this.uid,
    this.cn,
    this.gender,
    this.pits,
    this.regions,
    this.bio,
    this.coverPhotoUrl,
    this.profilePhotoUrl,
    this.friends,
    this.receivedRequests,
    this.sentRequests,
    this.createdAt,
    this.updatedAt,
  });

  /// **從 Firestore 解析**
  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String?,
      cn: data['cn'] as String?,
      gender: data['gender'] as String?,
      pits: List<String>.from(data['pits'] ?? []),
      regions: List<String>.from(data['regions'] ?? []),
      bio: data['bio'] as String?,
      coverPhotoUrl: data['coverPhotoUrl'] as String?,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      friends: List<String>.from(data['friends'] ?? []),
      receivedRequests: List<String>.from(data['receivedRequests'] ?? []),
      sentRequests: List<String>.from(data['sentRequests'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// **轉換為 Firestore 可存儲的 Map**
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'cn': cn,
      'gender': gender,
      'pits': pits ?? [],
      'regions': regions ?? [],
      'bio': bio,
      'coverPhotoUrl': coverPhotoUrl,
      'profilePhotoUrl': profilePhotoUrl,
      'friends': friends ?? [],
      'receivedRequests': receivedRequests ?? [],
      'sentRequests': sentRequests ?? [],
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// **轉換為 Map**
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'cn': cn,
      'gender': gender,
      'pits': pits ?? [],
      'regions': regions ?? [],
      'bio': bio,
      'coverPhotoUrl': coverPhotoUrl,
      'profilePhotoUrl': profilePhotoUrl,
      'friends': friends ?? [],
      'receivedRequests': receivedRequests ?? [],
      'sentRequests': sentRequests ?? [],
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// **複製並修改**
  UserProfile copyWith({
    String? uid,
    String? cn,
    String? gender,
    List<String>? pits,
    List<String>? regions,
    String? bio,
    String? coverPhotoUrl,
    String? profilePhotoUrl,
    List<String>? friends,
    List<String>? receivedRequests,
    List<String>? sentRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      cn: cn ?? this.cn,
      gender: gender ?? this.gender,
      pits: pits ?? this.pits,
      regions: regions ?? this.regions,
      bio: bio ?? this.bio,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
