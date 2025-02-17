class UserProfile {
  final String? gender;
  final String? cn;
  final List<String>? pits;
  final List<String>? regions;
  final String? bio;
  final String? coverPhotoUrl; // 加入封面照片欄位

  UserProfile({this.gender, this.cn, this.pits, this.regions, this.bio, this.coverPhotoUrl});

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      gender: data['gender'] as String?,
      cn: data['cn'] as String?,
      pits: List<String>.from(data['pits'] ?? []),
      regions: List<String>.from(data['regions'] ?? []),
      bio: data['bio'] as String?,
      coverPhotoUrl: data['coverPhotoUrl'] as String?, // 解析封面照片
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gender': gender,
      'cn': cn,
      'pits': pits ?? [],
      'regions': regions ?? [],
      'bio': bio,
      'coverPhotoUrl': coverPhotoUrl, // 加入封面照片
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'cn': cn,
      'pits': pits ?? [],
      'regions': regions ?? [],
      'bio': bio,
      'coverPhotoUrl': coverPhotoUrl, // 加入封面照片
    };
  }

  // **新增 copyWith 方法**
  UserProfile copyWith({
    String? gender,
    String? cn,
    String? bio,
    List<String>? pits,
    List<String>? regions,
    String? coverPhotoUrl,
  }) {
    return UserProfile(
      gender: gender ?? this.gender,
      cn: cn ?? this.cn,
      bio: bio ?? this.bio,
      pits: pits ?? this.pits,
      regions: regions ?? this.regions,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
    );
  }
}
